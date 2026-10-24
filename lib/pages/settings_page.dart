import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../store.dart';
import '../widget_sync.dart';

/// Settings: siren on/off, countdown, permissions. Everything saves by itself.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _siren = false;
  double _countdown = WidgetSync.defaultCountdown.toDouble();
  Map<String, bool> _perms = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the phone's own settings screen: show the new state.
    if (state == AppLifecycleState.resumed) _refreshPerms();
  }

  Future<void> _load() async {
    final siren = await WidgetSync.sirenEnabled();
    final secs = await WidgetSync.countdown();
    if (!mounted) return;
    setState(() {
      _siren = siren;
      _countdown = secs.toDouble();
      _loading = false;
    });
    await _refreshPerms();
  }

  Future<void> _refreshPerms() async {
    final call = await WidgetSync.callPerms();
    final result = <String, bool>{
      'Phone (place calls)': call['phone'] ?? false,
      'Call log (to see if a call was answered)': call['calllog'] ?? false,
      'SMS': await Permission.sms.isGranted,
      'Location': await Permission.location.isGranted,
      'Location, all the time': await Permission.locationAlways.isGranted,
      'Notifications': await Permission.notification.isGranted,
    };
    if (!mounted) return;
    setState(() => _perms = result);
  }

  Future<void> _allowPermissions() async {
    await WidgetSync.requestCallPerms();
    await Permission.sms.request();
    final loc = await Permission.location.request();
    if (loc.isGranted) await Permission.locationAlways.request();
    await Permission.notification.request();
    await _refreshPerms();
  }

  Future<void> _persist() async {
    await WidgetSync.save(siren: _siren, countdown: _countdown.round());
    await WidgetSync.push(await Store.contacts());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Alerts', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Siren (3 taps on the widget)'),
                  subtitle: const Text(
                      'Loud alarm at full volume. Stops only after you unlock '
                      'your phone.'),
                  value: _siren,
                  onChanged: (v) {
                    setState(() => _siren = v);
                    _persist();
                  },
                ),
                const SizedBox(height: 8),
                Text('Countdown after 1 tap: ${_countdown.round()} s'),
                Slider(
                  value: _countdown,
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: '${_countdown.round()} s',
                  onChanged: (v) => setState(() => _countdown = v),
                  onChangeEnd: (_) => _persist(),
                ),
                const Text(
                  'During the countdown you can press Cancel in the '
                  'notification. 0 means no countdown.',
                ),
                const SizedBox(height: 8),
                const Text(
                  'Calling order: your first trusted contact is called first. '
                  'If they do not pick up, the next one is called, and so on. '
                  'Your location is texted to all contacts at once.',
                ),
                const Divider(height: 32),
                Text('Permissions', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final e in _perms.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          e.value ? Icons.check_circle : Icons.cancel,
                          size: 18,
                          color: e.value ? Colors.green : Colors.redAccent,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(e.key)),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _allowPermissions,
                  child: const Text('Allow permissions'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: openAppSettings,
                  child: const Text('Open phone settings for MeToo'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'For location choose "Allow all the time", so your position '
                  'can be sent when the widget is tapped. If SMS or Call log '
                  'is greyed out: phone Settings > Apps > MeToo > menu > Allow '
                  'restricted settings, then allow the permission again.',
                ),
                const SizedBox(height: 16),
                const Text('Changes are saved automatically.'),
              ],
            ),
    );
  }
}
