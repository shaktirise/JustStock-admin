import "package:flutter/material.dart";

import "features/auth/sign_in_page.dart";
import "theme.dart";

class JustStockAdminApp extends StatelessWidget {
  const JustStockAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JustStock Admin',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const SignInPage(),
    );
  }
}
