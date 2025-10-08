import "package:flutter/material.dart";

const Color _primaryMaroon = Color(0xFF8B0000);
const Color _deepCrimson = Color(0xFFB22222);
const Color _softBackground = Color(0xFFF9F4F4);

ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: false);
  return base.copyWith(
    scaffoldBackgroundColor: _softBackground,
    colorScheme: base.colorScheme.copyWith(
      primary: _primaryMaroon,
      secondary: _deepCrimson,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFF1F1B1B),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.white,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryMaroon,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _deepCrimson,
        foregroundColor: Colors.white,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: const Color(0xFF312A2A),
      displayColor: const Color(0xFF312A2A),
    ),
  );
}

LinearGradient buildHeaderGradient() {
  return const LinearGradient(
    colors: [_primaryMaroon, _deepCrimson],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

LinearGradient buildCardGradient() {
  return const LinearGradient(
    colors: [Color(0xFFFFEBEB), Colors.white],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
