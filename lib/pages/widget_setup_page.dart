import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../sos_actions.dart';
import '../store.dart';
import '../widget_sync.dart';

/// Shown once on first launch, and can be opened again later.
/// Sets up the home-screen SOS widget: siren on/off, countdown, permissions.
class WidgetSetupPage extends StatefulWidget {
  const WidgetSetupPage({super.key});

  @override
  State<WidgetSetupPage> createState() => _WidgetSetupPageState();
}

class _WidgetSetupPageState extends State<WidgetSetupPage> {
  bool _loading = true;
  bool _siren = false;
  double _countdown = WidgetSync.defaultCountdown.toDouble();
  Map<String, bool> _perms = {};

  @override
  void initState() {
    super.initState();
    _load();
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
    final result = <String, bool>{
      'Phone (calls)': await Permission.phone.isGranted,
      'SMS': await Permission.sms.isGranted,
      'Location': await Permission.location.isGranted,
      'Location, all the time': await Permission.locationAlways.isGranted,
      'Notifications': await Permission.notification.isGranted,
    };
    if (!mounted) return;
    setState(() => _perms = result);
  }

  Future<void> _allowPermissions() async {
    await Permission.phone.request();
    await Permission.sms.request();
    final loc = await Permission.location.request();
    if (loc.isGranted) await Permission.locationAlways.request();
    await Permission.notification.request();
    await _refreshPerms();
  }

  Future<void> _save() async {
    await WidgetSync.save(siren: _siren, countdown: _countdown.round());
    await WidgetSync.push(await Store.contacts());
    if (!mounted) return;
    Navigator.of(context).pop();
    toast('Widget settings saved');
  }

  @override
  Widget build(BuildContext context) {
    final noContacts = Store.contactCount.value == 0;
    return Scaffold(
      appBar: AppBar(title: const Text('SOS widget setup')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Home-screen widget',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                const Text(
                  '1 tap: countdown, then calls your first trusted contact and '
                  'sends your location by SMS to all contacts.\n'
                  '2 taps: the same, right away.\n'
                  '3 taps: siren (only if you switch it on below).',
                ),
                if (noContacts) ...[
                  const SizedBox(height: 12),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'You have no trusted contacts yet. Add at least one in '
                        'the Contacts tab. The first one is the person who gets '
                        'called.',
                      ),
                    ),
                  ),
                ],
                const Divider(height: 32),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable siren (3 taps)'),
                  subtitle: const Text(
                      'Loud alarm at full volume. Stops only after you unlock '
                      'your phone.'),
                  value: _siren,
                  onChanged: (v) => setState(() => _siren = v),
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
                ),
                const Text(
                  'During the countdown you can press Cancel in the '
                  'notification. 0 means no countdown.',
                ),
                const Divider(height: 32),
                Text('Permissions',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final e in _perms.entries)
                  Row(
                    children: [
                      Icon(e.value ? Icons.check_circle : Icons.cancel,
                          size: 18, color: e.value ? Colors.green : Colors.red),
                      const SizedBox(width: 8),
                      Text(e.key),
                    ],
                  ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _allowPermissions,
                  child: const Text('Allow permissions'),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose "Allow all the time" for location, so your position '
                  'can be sent when the widget is tapped. If SMS is greyed out: '
                  'phone Settings > Apps > MeToo > menu > Allow restricted '
                  'settings.',
                ),
                const Divider(height: 32),
                const Text(
                  'Add the widget: press and hold an empty spot on the home '
                  'screen > Widgets > MeToo > drag the red SOS button out.',
                ),
                const SizedBox(height: 24),
                FilledButton(onPressed: _save, child: const Text('Save')),
              ],
            ),
    );
  }
}
