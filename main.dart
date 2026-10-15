import 'package:flutter/material.dart';

import 'pages/home_shell.dart';
import 'sos_actions.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MeTooApp());
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
