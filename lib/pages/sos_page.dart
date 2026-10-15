import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../sos_actions.dart';
import '../theme.dart';
import '../store.dart';

class SosPage extends StatefulWidget {
  const SosPage({super.key});

  @override
  State<SosPage> createState() => _SosPageState();
}

class _SosPageState extends State<SosPage> with WidgetsBindingObserver {
  static const _idleHint =
      'Tap the app icon 2 times: your contacts get your location.\n'
      'Tap 3 times: siren, until you unlock with your phone password.';

  int _taps = 0;
  Timer? _timer;
  String _hint = _idleHint;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _armLaunch(initial: true);
  }

  /// Opening the app by tapping its icon counts as the FIRST tap. The next
  /// taps (anywhere on this screen) must follow within 2.5 seconds.
  void _armLaunch({bool initial = false}) {
    if (SirenService.on.value) return;
    _timer?.cancel();
    _taps = 1;
    _hint = 'Tap again: 1 more tap = alert, 2 more = siren';
    if (!initial) setState(() {});
    _timer = Timer(const Duration(milliseconds: 2500), () {
      _taps = 0;
      if (mounted) setState(() => _hint = _idleHint);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  /// When she unlocks the phone and comes back to the app while the siren is
  /// on, the system password/fingerprint prompt opens straight away.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (SirenService.on.value) {
      SirenService.stopWithAuth();
    } else {
      _armLaunch(); // came back by tapping the icon
    }
  }

  void _onTap() {
    HapticFeedback.mediumImpact();
    _timer?.cancel();
    _taps++;

    if (_taps >= 3) {
      _taps = 0;
      setState(() => _hint = _idleHint);
      startEmergency();
      return;
    }

    setState(() => _hint = 'Tap $_taps... keep tapping');
    _timer = Timer(const Duration(milliseconds: 700), () {
      final n = _taps;
      _taps = 0;
      if (!mounted) return;
      setState(() => _hint = _idleHint);
      if (n == 2) triggerAlert();
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    // Listener: every touch anywhere on this screen counts as a tap.
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _onTap(),
      child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            ValueListenableBuilder<int>(
              valueListenable: Store.contactCount,
              builder: (_, n, __) => n == 0
                  ? Card(
                      color: AppColors.warningBg,
                      child: const ListTile(
                        leading: Icon(Icons.warning_amber),
                        title: Text('Add trusted contacts first'),
                        subtitle: Text('Open the Contacts tab.'),
                      ),
                    )
                  : Text(
                      '$n trusted contact${n == 1 ? '' : 's'} ready',
                      style: text.titleMedium,
                    ),
            ),
            const Spacer(),
            ValueListenableBuilder<bool>(
              valueListenable: SirenService.on,
              builder: (_, sirenOn, __) =>
                  sirenOn ? _stopSirenButton() : _sosButton(),
            ),
            const SizedBox(height: 24),
            Text(_hint, textAlign: TextAlign.center, style: text.bodyLarge),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => callNumber('112'),
                    icon: const Icon(Icons.call),
                    label: const Text('Call 112'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: triggerAlert,
                    icon: const Icon(Icons.share_location),
                    label: const Text('Share location'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _sosButton() {
    return Material(
      color: AppColors.sosButton,
      elevation: 8,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () {}, // taps are counted by the Listener above
        child: const SizedBox(
          width: 220,
          height: 220,
          child: Center(
            child: Text(
              'SOS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 56,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stopSirenButton() {
    return SizedBox(
      width: 220,
      height: 220,
      child: FilledButton(
        style: FilledButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Colors.black87,
        ),
        onPressed: SirenService.stopWithAuth,
        child: const Text(
          'SIREN ON\nTap to stop\n(phone password)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
