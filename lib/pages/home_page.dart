import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../sos_actions.dart';
import '../store.dart';
import '../theme.dart';
import '../widget_sync.dart';

/// Front page: how to use the app, with a way into every other screen.
class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onOpenTab});

  /// Switches the bottom tab (4 = Settings).
  final void Function(int index) onOpenTab;

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _contacts = 0;
  bool _permsOk = true;
  bool _siren = false;
  int _countdown = WidgetSync.defaultCountdown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) refresh();
  }

  Future<void> refresh() async {
    final contacts = await Store.contacts();
    final call = await WidgetSync.callPerms();
    final sms = await Permission.sms.isGranted;
    final loc = await Permission.location.isGranted;
    final siren = await WidgetSync.sirenEnabled();
    final secs = await WidgetSync.countdown();
    if (!mounted) return;
    setState(() {
      _contacts = contacts.length;
      _permsOk = (call['phone'] ?? false) && sms && loc;
      _siren = siren;
      _countdown = secs;
    });
  }

  void _openSettings() => widget.onOpenTab(4);

  Widget _step(int n, String title, String body) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: Text('$n'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tapRow(String label, String body) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(body)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final needsSetup = _contacts == 0 || !_permsOk;
    return Scaffold(
      appBar: AppBar(
        title: const Text('MeToo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Welcome', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          const Text(
            'MeToo helps you reach the people you trust, quickly and quietly. '
            'Here is how to set it up and use it.',
          ),
          const SizedBox(height: 16),
          if (needsSetup)
            Card(
              color: AppColors.warningBg,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Finish setup',
                        style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      _contacts == 0
                          ? 'You have not added a trusted contact yet. '
                              'Do that first (step 1 below).'
                          : 'Some permissions are missing, so calls, SMS or '
                              'location may not work.',
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _openSettings,
                      child: const Text('Open Settings'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text('Set up (once)', style: theme.textTheme.titleMedium),
          _step(
            1,
            'Add your trusted contacts',
            'Open the Contacts tab at the bottom and add the people to '
                'call. The first one in the list is called first.',
          ),
          _step(
            2,
            'Allow permissions',
            'Open the Settings tab at the bottom and tap "Allow permissions". '
                'Choose "Allow all the time" for location.',
          ),
          _step(
            3,
            'Add the widget to your home screen',
            'Press and hold an empty spot on the home screen > Widgets > '
                'MeToo > drag the small MeToo SOS button out.',
          ),
          const SizedBox(height: 16),
          Text('Using the widget', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Card(
            color: AppColors.infoBg,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _tapRow(
                    '1 tap',
                    'A $_countdown second countdown starts. Press Cancel in '
                        'the notification if it was a mistake. After that, '
                        'your first contact is called. If they do not pick '
                        'up, the next one is called.',
                  ),
                  _tapRow(
                    '2 taps',
                    'The same, with no waiting.',
                  ),
                  _tapRow(
                    '3 taps',
                    _siren
                        ? 'A loud siren plays until you unlock your phone.'
                        : 'Siren. It is switched off now; you can turn it on '
                            'in Settings.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'The moment the first call starts, your location is also texted '
            'to every contact on your list.',
          ),
          const SizedBox(height: 16),
          Card(
            color: AppColors.infoBg,
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'MeToo is a student prototype. Test it with your own numbers '
                'first. In real danger, call 112.',
              ),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => callNumber('112'),
            icon: const Icon(Icons.call),
            label: const Text('Call 112'),
          ),
        ],
      ),
    );
  }
}
