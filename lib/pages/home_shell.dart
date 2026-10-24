import 'package:flutter/material.dart';
import 'package:quick_actions/quick_actions.dart';

import '../store.dart';
import 'complaint_page.dart';
import 'contacts_page.dart';
import 'home_page.dart';
import 'rights_page.dart';
import 'settings_page.dart';

/// Main screen with the bottom tabs: Home, Contacts, Complaint, Rights, Settings.
/// The emergency alert itself lives only in the home-screen widget.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final GlobalKey<HomePageState> _homeKey = GlobalKey<HomePageState>();

  @override
  void initState() {
    super.initState();
    Store.contacts();
    _clearOldShortcuts();
  }

  /// Older versions added "Alert my contacts" shortcuts to the app icon.
  Future<void> _clearOldShortcuts() async {
    try {
      await QuickActions().clearShortcutItems();
    } catch (_) {}
  }

  void _select(int i) {
    setState(() => _index = i);
    if (i == 0) _homeKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomePage(key: _homeKey, onOpenTab: _select),
          const ContactsPage(),
          const ComplaintPage(),
          const RightsPage(),
          const SettingsPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.contacts_outlined), label: 'Contacts'),
          NavigationDestination(icon: Icon(Icons.edit_note), label: 'Complaint'),
          NavigationDestination(icon: Icon(Icons.gavel), label: 'Rights'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
    );
  }
}
