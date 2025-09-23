import "package:flutter/material.dart";

import "core/auth_session.dart";
import "core/session_store.dart";
import "features/auth/sign_in_page.dart";
import "features/home/home_page.dart";
import "theme.dart";

class JustStockAdminApp extends StatelessWidget {
  const JustStockAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JustStock Admin',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _BootstrapScreen(),
    );
  }
}

class _BootstrapScreen extends StatefulWidget {
  const _BootstrapScreen();

  @override
  State<_BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<_BootstrapScreen> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final token = await SessionStore.loadToken();
    final lastActivityMs = await SessionStore.loadLastActivityMs();

    if (!mounted) return;

    if (token == null || token.isEmpty) {
      _goTo(const SignInPage());
      return;
    }

    final inactivityLimitMs = const Duration(days: 15).inMilliseconds;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final hasTimedOut = lastActivityMs == null
        ? false
        : (nowMs - lastActivityMs) > inactivityLimitMs;

    if (hasTimedOut) {
      try {
        await SessionStore.clear();
      } catch (_) {}
      AuthSession.clear();
      _goTo(const SignInPage());
      return;
    }

    AuthSession.adminToken = token;
    try {
      await SessionStore.touchLastActivityNow();
    } catch (_) {}

    final savedName = (await SessionStore.loadAdminName()) ?? '';
    final savedMobile = (await SessionStore.loadAdminMobile()) ?? '';

    if (!mounted) return;
    _goTo(HomePage(adminName: savedName, adminMobile: savedMobile));
  }

  void _goTo(Widget page) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}