import "package:flutter/material.dart";

const Color _primaryYellow = Color(0xFFFFC107);
const Color _sunsetOrange = Color(0xFFFF8F00);
const Color _softBackground = Color(0xFFFEF9E6);

ThemeData buildAppTheme() {
  final base = ThemeData.light(useMaterial3: false);
  return base.copyWith(
    scaffoldBackgroundColor: _softBackground,
    colorScheme: base.colorScheme.copyWith(
      primary: _primaryYellow,
      secondary: _sunsetOrange,
      surface: Colors.white,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: const Color(0xFF212121),
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
        backgroundColor: _primaryYellow,
        foregroundColor: const Color(0xFF212121),
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
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
      bodyColor: const Color(0xFF3C3C3C),
      displayColor: const Color(0xFF3C3C3C),
    ),
  );
}

LinearGradient buildHeaderGradient() {
  return const LinearGradient(
    colors: [_primaryYellow, _sunsetOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

LinearGradient buildCardGradient() {
  return const LinearGradient(
    colors: [Color(0xFFFFF3CD), Colors.white],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
