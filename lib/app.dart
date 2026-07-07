import 'package:flutter/material.dart';

import 'screens/auth_gate.dart';
import 'theme/app_theme.dart';
import 'widgets/update_checker.dart';

class VanDwellersApp extends StatelessWidget {
  const VanDwellersApp({super.key, this.enableVersionCheck = true});

  final bool enableVersionCheck;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Van Dwellers',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: UpdateChecker(
        enabled: enableVersionCheck,
        child: const AuthGate(),
      ),
    );
  }
}
