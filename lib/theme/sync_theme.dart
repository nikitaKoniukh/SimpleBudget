import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SyncMonth visual tokens — calm sage, warm coral, soft mint wash.
abstract final class SyncColors {
  static const Color primary = Color(0xFF3D7A5F);
  static const Color accent = Color(0xFFE07A5F);
  static const Color surface = Color(0xFFF7F4EF);
  static const Color surfaceMint = Color(0xFFE8F0EB);
  static const Color text = Color(0xFF1C2A24);
  static const Color textMuted = Color(0xFF5A6B63);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color warning = Color(0xFFC97B3A);
  static const Color overspend = Color(0xFFE07A5F);
}

ThemeData buildSyncTheme() {
  final colorScheme = ColorScheme.light(
    primary: SyncColors.primary,
    onPrimary: SyncColors.onPrimary,
    secondary: SyncColors.accent,
    onSecondary: SyncColors.onPrimary,
    surface: SyncColors.surface,
    onSurface: SyncColors.text,
    error: SyncColors.overspend,
    onError: SyncColors.onPrimary,
    outline: SyncColors.textMuted.withValues(alpha: 0.35),
  );

  final display = GoogleFonts.frauncesTextTheme();
  final body = GoogleFonts.plusJakartaSansTextTheme();

  final textTheme = body.copyWith(
    displayLarge: display.displayLarge?.copyWith(
      color: SyncColors.text,
      fontWeight: FontWeight.w600,
    ),
    displayMedium: display.displayMedium?.copyWith(
      color: SyncColors.text,
      fontWeight: FontWeight.w600,
    ),
    displaySmall: display.displaySmall?.copyWith(
      color: SyncColors.text,
      fontWeight: FontWeight.w600,
    ),
    headlineLarge: display.headlineLarge?.copyWith(
      color: SyncColors.text,
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: display.headlineMedium?.copyWith(
      color: SyncColors.text,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: display.headlineSmall?.copyWith(
      color: SyncColors.text,
      fontWeight: FontWeight.w600,
      fontSize: 24,
    ),
    titleLarge: body.titleLarge?.copyWith(
      color: SyncColors.text,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: body.titleMedium?.copyWith(
      color: SyncColors.text,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: body.bodyLarge?.copyWith(color: SyncColors.text),
    bodyMedium: body.bodyMedium?.copyWith(color: SyncColors.text),
    bodySmall: body.bodySmall?.copyWith(color: SyncColors.textMuted),
    labelLarge: body.labelLarge?.copyWith(
      color: SyncColors.text,
      fontWeight: FontWeight.w600,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: SyncColors.surface,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: SyncColors.text,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: SyncColors.text.withValues(alpha: 0.08),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: SyncColors.primary,
        foregroundColor: SyncColors.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: SyncColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: SyncColors.primary,
      foregroundColor: SyncColors.onPrimary,
      elevation: 2,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white.withValues(alpha: 0.95),
      indicatorColor: SyncColors.surfaceMint,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelMedium?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? SyncColors.primary : SyncColors.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? SyncColors.primary : SyncColors.textMuted,
        );
      }),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: SyncColors.surfaceMint,
      selectedColor: SyncColors.primary.withValues(alpha: 0.2),
      labelStyle: textTheme.labelMedium!,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide.none,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: SyncColors.textMuted.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: SyncColors.textMuted.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: SyncColors.primary, width: 1.5),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

/// Soft mint wash behind screens.
class SyncBackground extends StatelessWidget {
  const SyncBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            SyncColors.surface,
            SyncColors.surfaceMint,
            SyncColors.surface,
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: child,
    );
  }
}
