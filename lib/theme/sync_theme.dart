import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// SyncMonth brand values — calm sage, warm coral, soft mint wash.
///
/// These are the light-theme constants. Widgets read the active theme's
/// colors through `context.sync` ([SyncPalette]) so dark mode works.
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

  /// Darker coral / amber that pass WCAG AA (4.5:1) as small text on light
  /// surfaces. Fills, bars and icons keep the brand values above.
  static const Color overspendText = Color(0xFFB4513A);
  static const Color warningText = Color(0xFF94591E);

  /// Backdrop blur sigma for glass action buttons.
  static const double frostedBlur = 12;
}

/// Theme-aware SyncMonth colors. Read with `context.sync`.
@immutable
class SyncPalette extends ThemeExtension<SyncPalette> {
  const SyncPalette({
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.surface,
    required this.surfaceMint,
    required this.text,
    required this.textMuted,
    required this.warning,
    required this.overspend,
    required this.accentText,
    required this.warningText,
    required this.overspendText,
    required this.panelBase,
    required this.glassButton,
    required this.glassStroke,
    required this.selectionRing,
  });

  final Color primary;
  final Color onPrimary;
  final Color accent;
  final Color surface;
  final Color surfaceMint;
  final Color text;
  final Color textMuted;

  /// Fills, bars and icons.
  final Color warning;
  final Color overspend;

  /// Same meaning as [accent] / [warning] / [overspend], tuned to pass AA when
  /// used as text color.
  final Color accentText;
  final Color warningText;
  final Color overspendText;

  /// Opaque base of the translucent panels and cards (white in light);
  /// apply the panel alpha at the call site.
  final Color panelBase;

  /// Glass action button tint and its 1px ring.
  final Color glassButton;
  final Color glassStroke;

  /// Ring around the selected swatch in color pickers.
  final Color selectionRing;

  /// Frosted panel / top-bar surface.
  Color get frostedSurface => panelBase.withValues(alpha: 0.88);

  static const light = SyncPalette(
    primary: SyncColors.primary,
    onPrimary: SyncColors.onPrimary,
    accent: SyncColors.accent,
    surface: SyncColors.surface,
    surfaceMint: SyncColors.surfaceMint,
    text: SyncColors.text,
    textMuted: SyncColors.textMuted,
    warning: SyncColors.warning,
    overspend: SyncColors.overspend,
    accentText: SyncColors.overspendText,
    warningText: SyncColors.warningText,
    overspendText: SyncColors.overspendText,
    panelBase: Color(0xFFFFFFFF),
    glassButton: Color(0x9EFFFFFF), // white 62%
    glassStroke: Color(0x8CFFFFFF), // white 55%
    selectionRing: Color(0xDD000000), // black87
  );

  static const dark = SyncPalette(
    primary: Color(0xFF6DB592),
    onPrimary: Color(0xFF0E1F17),
    accent: Color(0xFFF2957D),
    surface: Color(0xFF141A17),
    surfaceMint: Color(0xFF1E2A24),
    text: Color(0xFFE8EEE9),
    textMuted: Color(0xFFA2B2AA),
    warning: Color(0xFFE2A764),
    overspend: Color(0xFFF2957D),
    accentText: Color(0xFFF2957D),
    warningText: Color(0xFFE2A764),
    overspendText: Color(0xFFF2957D),
    panelBase: Color(0xFF26312C),
    glassButton: Color(0x1AFFFFFF), // white 10%
    glassStroke: Color(0x29FFFFFF), // white 16%
    selectionRing: Color(0xFFE8EEE9),
  );

  @override
  SyncPalette copyWith({
    Color? primary,
    Color? onPrimary,
    Color? accent,
    Color? surface,
    Color? surfaceMint,
    Color? text,
    Color? textMuted,
    Color? warning,
    Color? overspend,
    Color? accentText,
    Color? warningText,
    Color? overspendText,
    Color? panelBase,
    Color? glassButton,
    Color? glassStroke,
    Color? selectionRing,
  }) {
    return SyncPalette(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      accent: accent ?? this.accent,
      surface: surface ?? this.surface,
      surfaceMint: surfaceMint ?? this.surfaceMint,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      warning: warning ?? this.warning,
      overspend: overspend ?? this.overspend,
      accentText: accentText ?? this.accentText,
      warningText: warningText ?? this.warningText,
      overspendText: overspendText ?? this.overspendText,
      panelBase: panelBase ?? this.panelBase,
      glassButton: glassButton ?? this.glassButton,
      glassStroke: glassStroke ?? this.glassStroke,
      selectionRing: selectionRing ?? this.selectionRing,
    );
  }

  @override
  SyncPalette lerp(ThemeExtension<SyncPalette>? other, double t) {
    if (other is! SyncPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return SyncPalette(
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      accent: l(accent, other.accent),
      surface: l(surface, other.surface),
      surfaceMint: l(surfaceMint, other.surfaceMint),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      warning: l(warning, other.warning),
      overspend: l(overspend, other.overspend),
      accentText: l(accentText, other.accentText),
      warningText: l(warningText, other.warningText),
      overspendText: l(overspendText, other.overspendText),
      panelBase: l(panelBase, other.panelBase),
      glassButton: l(glassButton, other.glassButton),
      glassStroke: l(glassStroke, other.glassStroke),
      selectionRing: l(selectionRing, other.selectionRing),
    );
  }
}

extension SyncPaletteContext on BuildContext {
  /// Active SyncMonth palette (light or dark).
  SyncPalette get sync =>
      Theme.of(this).extension<SyncPalette>() ?? SyncPalette.light;
}

ThemeData buildSyncTheme() => _buildTheme(SyncPalette.light, Brightness.light);

ThemeData buildSyncDarkTheme() =>
    _buildTheme(SyncPalette.dark, Brightness.dark);

ThemeData _buildTheme(SyncPalette p, Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: p.primary,
    onPrimary: p.onPrimary,
    secondary: p.accent,
    onSecondary: isDark ? p.onPrimary : SyncColors.onPrimary,
    surface: p.surface,
    onSurface: p.text,
    // Light keeps Material's fallback (onSurface) as before.
    onSurfaceVariant: isDark ? p.textMuted : null,
    error: p.overspend,
    onError: isDark ? p.onPrimary : SyncColors.onPrimary,
    outline: p.textMuted.withValues(alpha: 0.35),
  );

  // Literata: soft bookish display for month titles (less “landing-page serif”
  // than Fraunces). Figtree: friendly geometric UI that stays clear on ₪ amounts.
  final baseText = isDark
      ? ThemeData.dark()
          .textTheme
          .apply(bodyColor: p.text, displayColor: p.text)
      : null;
  final display = GoogleFonts.literataTextTheme(baseText);
  final body = GoogleFonts.figtreeTextTheme(baseText);

  final textTheme = body.copyWith(
    displayLarge: display.displayLarge?.copyWith(
      color: p.text,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.5,
    ),
    displayMedium: display.displayMedium?.copyWith(
      color: p.text,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.4,
    ),
    displaySmall: display.displaySmall?.copyWith(
      color: p.text,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
    ),
    headlineLarge: display.headlineLarge?.copyWith(
      color: p.text,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.3,
    ),
    headlineMedium: display.headlineMedium?.copyWith(
      color: p.text,
      fontWeight: FontWeight.w600,
    ),
    headlineSmall: display.headlineSmall?.copyWith(
      color: p.text,
      fontWeight: FontWeight.w600,
      fontSize: 24,
    ),
    titleLarge: body.titleLarge?.copyWith(
      color: p.text,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: body.titleMedium?.copyWith(
      color: p.text,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: body.bodyLarge?.copyWith(
      color: p.text,
      height: 1.4,
    ),
    bodyMedium: body.bodyMedium?.copyWith(
      color: p.text,
      height: 1.4,
    ),
    bodySmall: body.bodySmall?.copyWith(color: p.textMuted),
    labelLarge: body.labelLarge?.copyWith(
      color: p.text,
      fontWeight: FontWeight.w600,
    ),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: p.surface,
    textTheme: textTheme,
    extensions: [p],
    // SyncAppBar owns frosted visuals; keep AppBarTheme transparent for fallback.
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      foregroundColor: p.text,
      titleTextStyle: textTheme.titleLarge,
      // Transparent AppBar luminance is 0, so Flutter would pick light content.
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: p.panelBase.withValues(alpha: 0.92),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      shadowColor: SyncColors.text.withValues(alpha: 0.08),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.primary,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.primary,
      foregroundColor: p.onPrimary,
      elevation: 2,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.panelBase.withValues(alpha: 0.95),
      indicatorColor: p.surfaceMint,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return textTheme.labelMedium?.copyWith(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? p.primary : p.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? p.primary : p.textMuted,
        );
      }),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.surfaceMint,
      selectedColor: p.primary.withValues(alpha: 0.2),
      labelStyle: textTheme.labelMedium!,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      side: BorderSide.none,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF1C2420) : Colors.white,
      isDense: false,
      hintStyle: textTheme.bodyMedium?.copyWith(color: p.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.textMuted.withValues(alpha: 0.25)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.textMuted.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: p.primary, width: 1.5),
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
    final p = context.sync;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [p.surface, p.surfaceMint, p.surface],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: child,
    );
  }
}
