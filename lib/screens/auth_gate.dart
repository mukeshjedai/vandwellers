import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/van_dwellers_api.dart';
import '../widgets/van_dwellers_logo.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = true;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final hasToken = await AuthService.instance.isLoggedIn();
    if (!hasToken) {
      if (mounted) setState(() { _checking = false; _loggedIn = false; });
      return;
    }
    try {
      await VanDwellersApi.instance.getMe();
      if (mounted) setState(() { _checking = false; _loggedIn = true; });
    } catch (_) {
      await AuthService.instance.clearToken();
      if (mounted) setState(() { _checking = false; _loggedIn = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              VanDwellersLogo(size: 96),
              SizedBox(height: 24),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }
    return _loggedIn ? const HomeScreen() : const LoginScreen();
  }
}
