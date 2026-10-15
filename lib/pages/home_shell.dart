import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';

import '../sos_actions.dart';
import '../store.dart';
import 'complaint_page.dart';
import 'contacts_page.dart';
import 'rights_page.dart';
import 'sos_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  int _index = 0;
  DateTime? _pausedAt;
  final AppLinks _links = AppLinks();
  StreamSubscription<Uri>? _sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Store.contacts(); // fills the contact counter
    // Ask one permission at a time: location first, then SMS.
    LocationService.ensurePermission().then((_) => SmsSender.ensurePermission());
    _initQuickActions();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLinks());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    super.dispose();
  }

  /// Coming back to the app after a few seconds away: show the SOS screen so
  /// that the icon taps are counted there.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final p = _pausedAt;
      _pausedAt = null;
      if (p != null &&
          DateTime.now().difference(p) > const Duration(seconds: 3) &&
          _index != 0) {
        setState(() => _index = 0);
      }
    }
  }

  /// Deep links: metoo://alert , metoo://siren , metoo://sos
  /// These are what an iPhone Back Tap shortcut calls.
  Future<void> _initLinks() async {
    try {
      final initial = await _links.getInitialLink();
      if (initial != null) _handleAction(initial.host);
    } catch (_) {}
    _sub = _links.uriLinkStream.listen((uri) => _handleAction(uri.host));
  }

  /// Long-press the app icon: works on Android and iPhone.
  void _initQuickActions() {
    final quick = QuickActions();
    quick.initialize((type) => _handleAction(type));
    quick.setShortcutItems(const [
      ShortcutItem(type: 'alert', localizedTitle: 'Alert my contacts'),
      ShortcutItem(type: 'siren', localizedTitle: 'Siren + alert contacts'),
    ]);
  }

  void _handleAction(String action) {
    if (!mounted) return;
    setState(() => _index = 0);
    switch (action) {
      case 'alert':
        triggerAlert();
        break;
      case 'siren':
        startEmergency();
        break;
      default:
        break; // 'sos' just opens the SOS screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          SosPage(),
          ContactsPage(),
          ComplaintPage(),
          RightsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.sos), label: 'SOS'),
          NavigationDestination(icon: Icon(Icons.contacts), label: 'Contacts'),
          NavigationDestination(
              icon: Icon(Icons.edit_note), label: 'Complaint'),
          NavigationDestination(icon: Icon(Icons.gavel), label: 'Rights'),
        ],
      ),
    );
  }
}
