import 'package:flutter/material.dart';

import 'pages/home_shell.dart';
import 'pages/widget_setup_page.dart';
import 'sos_actions.dart';
import 'store.dart';
import 'theme.dart';
import 'widget_sync.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MeTooApp());
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // Keep the home-screen widget in step with the saved contacts.
    await WidgetSync.push(await Store.contacts());
    // First launch: ask about the siren, countdown and permissions.
    if (!await WidgetSync.setupDone()) {
      navKey.currentState?.push(
        MaterialPageRoute<void>(builder: (_) => const WidgetSetupPage()),
      );
    }
  });
}

class MeTooApp extends StatelessWidget {
  const MeTooApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navKey,
      title: 'MeToo',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomeShell(),
    );
  }
}
