import 'dart:async';
import 'dart:io' show Platform;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:local_auth/local_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models.dart';
import 'store.dart';

final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

/// A context that sits below the Navigator, so dialogs and snackbars work
/// even when triggered from a deep link or a home-screen shortcut.
BuildContext? get appContext => navKey.currentState?.overlay?.context;

void toast(String message) {
  final ctx = appContext;
  if (ctx == null) return;
  ScaffoldMessenger.maybeOf(ctx)?.showSnackBar(SnackBar(content: Text(message)));
}

Future<void> callNumber(String number) async {
  try {
    await launchUrl(Uri(scheme: 'tel', path: number));
  } catch (_) {
    toast('Could not open the dialer');
  }
}

// ---------------------------------------------------------------- location

class LocationService {
  static Future<bool> ensurePermission() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return false;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      return perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always;
    } catch (_) {
      return false;
    }
  }

  static Future<Position?> current() async {
    if (!await ensurePermission()) return null;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
    } catch (_) {
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
    }
  }
}

// --------------------------------------------------------------------- SMS

/// 0 = the alert is sent the moment the 2nd tap is registered.
/// Set to 5 to get a cancel window first (useful against accidental taps).
const int kAlertCountdownSeconds = 0;

/// Sends SMS in the background on Android through the phone's SmsManager.
/// This needs the SEND_SMS permission, which Google Play restricts, so this
/// only works in an APK you install yourself (see README). iPhone cannot do it.
class SmsSender {
  static const MethodChannel _ch = MethodChannel('metoo/sms');

  static Future<bool> ensurePermission() async {
    if (!Platform.isAndroid) return false;
    try {
      var status = await Permission.sms.status;
      if (!status.isGranted) status = await Permission.sms.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> sendSilently(List<Contact> contacts, String body) async {
    if (!Platform.isAndroid) return false;
    if (!await ensurePermission()) return false;
    try {
      final ok = await _ch.invokeMethod<bool>('send', {
        'numbers': contacts.map((c) => c.phone).toList(),
        'body': body,
      });
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }
}

class AlertService {
  static Future<String> buildMessage() async {
    final p = await LocationService.current();
    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    if (p == null) {
      return 'EMERGENCY: I need help. I could not get my location. '
          'Please call me now. (MeToo, $hh:$mm)';
    }
    final link = 'https://maps.google.com/?q='
        '${p.latitude.toStringAsFixed(6)},${p.longitude.toStringAsFixed(6)}';
    return 'EMERGENCY: I need help. My location: $link '
        '(accuracy about ${p.accuracy.round()} m). Sent via MeToo at $hh:$mm.';
  }

  /// Sends the alert by itself on Android. If that is not possible (iPhone, or
  /// SMS permission refused) it opens the SMS composer instead and the person
  /// has to tap Send.
  static Future<void> deliver(List<Contact> contacts, String body) async {
    if (await SmsSender.sendSilently(contacts, body)) {
      toast('Alert sent to ${contacts.length} contact'
          '${contacts.length == 1 ? '' : 's'}');
      return;
    }
    final ok = await compose(contacts, body);
    if (!ok) toast('Could not send the alert or open the messaging app');
  }

  /// Opens the phone's SMS composer with all contacts and the message filled.
  /// Fallback only: the person has to tap Send.
  static Future<bool> compose(List<Contact> contacts, String body) async {
    final numbers = contacts.map((c) => c.phone).join(',');
    final encodedBody = Uri.encodeComponent(body);
    final uri = Platform.isIOS
        ? Uri.parse('sms:/open?addresses=${Uri.encodeComponent(numbers)}'
            '&body=$encodedBody')
        : Uri.parse('sms:$numbers?body=$encodedBody');
    try {
      return await launchUrl(uri);
    } catch (_) {
      return false;
    }
  }
}

/// Two-tap action: sends the location alert to the trusted contacts.
Future<void> triggerAlert({bool countdown = kAlertCountdownSeconds > 0}) async {
  final ctx = appContext;
  if (ctx == null) return;
  final contacts = await Store.contacts();
  if (contacts.isEmpty) {
    toast('Add at least one trusted contact first');
    return;
  }
  if (countdown) {
    if (!ctx.mounted) return;
    final go = await showDialog<bool>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => const _CountdownDialog(),
    );
    if (go != true) return;
  }
  final message = await AlertService.buildMessage();
  await AlertService.deliver(contacts, message);
}

class _CountdownDialog extends StatefulWidget {
  const _CountdownDialog();

  @override
  State<_CountdownDialog> createState() => _CountdownDialogState();
}

class _CountdownDialogState extends State<_CountdownDialog> {
  int _left = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _left--);
      if (_left <= 0) {
        t.cancel();
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Alerting contacts in $_left s'),
      content: const Text(
        'Your location will be sent to your trusted contacts. '
        'Tap Cancel if this was a mistake.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Send now'),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------- siren

/// Triple-tap action: siren AND location alert to contacts, no cancel window
/// (the siren is already unmistakable).
Future<void> startEmergency() async {
  await SirenService.start();
  await triggerAlert(countdown: false);
}

/// Siren behaviour:
///  - starts at full volume and the volume buttons are locked at max
///  - loops until the person proves it is her phone: fingerprint, face or the
///    phone's own password (system prompt, nothing to set up inside the app)
///  - if the phone has no screen lock at all, tapping Stop is enough
class SirenService {
  static final AudioPlayer _player = AudioPlayer();
  static final ValueNotifier<bool> on = ValueNotifier<bool>(false);

  static StreamSubscription<double>? _volSub;
  static double? _volumeBefore;
  static bool _armed = false;
  static bool _authBusy = false;

  static Future<void> start() async {
    if (on.value) return;
    on.value = true;
    try {
      await FlutterVolumeController.updateShowSystemUI(false);
      _volumeBefore = await FlutterVolumeController.getVolume();
      await FlutterVolumeController.setVolume(1.0);
      _armed = false;

      // Plays even when the iPhone silent switch is on.
      await _player.setAudioContext(AudioContext(
        iOS: AudioContextIOS(category: AVAudioSessionCategory.playback),
        android: const AudioContextAndroid(
          usageType: AndroidUsageType.media,
          contentType: AndroidContentType.music,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ));
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
      await _player.play(AssetSource('siren.wav'));

      _volSub = FlutterVolumeController.addListener(
        _onVolume,
        emitOnStart: false,
      );
      // Ignore the volume change caused by our own setVolume(1.0) call.
      Future<void>.delayed(const Duration(milliseconds: 1200), () {
        _armed = true;
      });
    } catch (_) {
      on.value = false;
      toast('Could not play the siren');
    }
  }

  /// Volume-down (or anything that lowers the volume) is undone at once.
  static void _onVolume(double v) {
    if (!_armed || !on.value) return;
    if (v < 0.999) FlutterVolumeController.setVolume(1.0);
  }

  /// The only way to stop the siren from the UI.
  static Future<bool> stopWithAuth() async {
    if (!on.value || _authBusy) return false;
    _authBusy = true;
    var ok = false;
    try {
      final auth = LocalAuthentication();
      if (!await auth.isDeviceSupported()) {
        ok = true; // phone has no screen lock, nothing to ask
      } else {
        ok = await auth.authenticate(
          localizedReason: 'Unlock to stop the siren',
          options: const AuthenticationOptions(
            biometricOnly: false, // allows the phone password/PIN too
            stickyAuth: true,
          ),
        );
      }
    } on PlatformException catch (e) {
      final c = e.code.toLowerCase();
      if (c == 'notavailable' || c == 'passcodenotset' || c == 'notenrolled') {
        ok = true; // no screen lock set up on this phone
      } else {
        toast('Could not check your phone password. Try again.');
      }
    } catch (_) {
      toast('Could not check your phone password. Try again.');
    }
    if (ok) await stop();
    // Short pause so the lifecycle "resumed" event after the system prompt
    // does not immediately open another prompt.
    Future<void>.delayed(const Duration(seconds: 2), () => _authBusy = false);
    return ok;
  }

  /// Internal: stops without asking. Do not call from a button.
  static Future<void> stop() async {
    _armed = false;
    await _volSub?.cancel();
    _volSub = null;
    await _player.stop();
    on.value = false;
    try {
      final before = _volumeBefore;
      _volumeBefore = null;
      if (before != null) await FlutterVolumeController.setVolume(before);
      await FlutterVolumeController.updateShowSystemUI(true);
    } catch (_) {}
  }
}
