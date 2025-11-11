import "package:flutter/material.dart";

// Brand colors: deep red + white
const Color _primaryRed = Color(0xFF9B0D0D); // dark red
const Color _accentRed = Color(0xFFB71C1C); // vivid accent
const Color _bgSoft = Color(0xFFF8F6F6); // soft near‑white background

ThemeData buildAppTheme() {
  // Modern Material 3 theme derived from a seed
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _primaryRed,
    brightness: Brightness.light,
  ).copyWith(
    primary: _primaryRed,
    secondary: _accentRed,
    surface: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
  );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: _bgSoft,
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      // allow gradient via flexibleSpace on pages
    ),
    cardTheme: CardTheme(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      surfaceTintColor: Colors.white,
      margin: EdgeInsets.zero,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      iconColor: Colors.black87,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary.withOpacity(0.35)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      hintStyle: TextStyle(color: Colors.grey.shade600),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    chipTheme: base.chipTheme.copyWith(
      selectedColor: colorScheme.primary.withOpacity(0.12),
      side: BorderSide(color: colorScheme.primary.withOpacity(0.35)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: const Color(0xFF1E1A1A),
      displayColor: const Color(0xFF1E1A1A),
    ),
  );
}

LinearGradient buildHeaderGradient() {
  return const LinearGradient(
    colors: [_primaryRed, _accentRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

LinearGradient buildCardGradient() {
  return const LinearGradient(
    colors: [Color(0xFFFFEAEA), Colors.white],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
