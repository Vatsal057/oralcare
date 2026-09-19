import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../domain/risk_engine.dart';

/// Visual language for the app.
///
/// Risk colours are deliberately not the only signal: every risk state also
/// carries an icon and explicit text, so the interface does not rely on colour
/// alone to convey meaning.
class AppTheme {
  const AppTheme._();

  static const Color seed = Color(
    0xFF00695C,
  ); // Keeping the clinical teal but softening the theme around it

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return _base(scheme, Brightness.light);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return _base(scheme, Brightness.dark);
  }

  static ThemeData _base(ColorScheme scheme, Brightness brightness) {
    final baseTextTheme = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: GoogleFonts.interTextTheme(baseTextTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLowest,
        shadowColor: scheme.shadow.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(color: scheme.outlineVariant),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        space: 1,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: scheme.surfaceContainerLowest,
        indicatorColor: scheme.primaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        labelTextStyle: WidgetStateProperty.all(
          GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

/// Colour + icon pairing for each patient output state.
class RiskVisuals {
  const RiskVisuals(this.color, this.onColor, this.icon, this.label);

  final Color color;
  final Color onColor;
  final IconData icon;
  final String label;

  static RiskVisuals forState(PatientOutputState state, Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    switch (state) {
      case PatientOutputState.lowerRisk:
        return RiskVisuals(
          isDark ? const Color(0xFF1B5E20) : const Color(0xFFE8F5E9),
          isDark ? Colors.white : const Color(0xFF1B5E20),
          Icons.check_circle_outline,
          'Lower risk',
        );
      case PatientOutputState.increasedRisk:
        return RiskVisuals(
          isDark ? const Color(0xFF8D6E00) : const Color(0xFFFFF8E1),
          isDark ? Colors.white : const Color(0xFF6D4C00),
          Icons.info_outline,
          'Increased risk',
        );
      case PatientOutputState.higherRisk:
        return RiskVisuals(
          isDark ? const Color(0xFFA84300) : const Color(0xFFFFF0E6),
          isDark ? Colors.white : const Color(0xFF8F3A00),
          Icons.priority_high,
          'Higher risk',
        );
      case PatientOutputState.observeAndReview:
        return RiskVisuals(
          isDark ? const Color(0xFF0D47A1) : const Color(0xFFE3F2FD),
          isDark ? Colors.white : const Color(0xFF0D47A1),
          Icons.visibility_outlined,
          'Recorded — review if persistent',
        );
      case PatientOutputState.professionalCheckRequired:
        return RiskVisuals(
          isDark ? const Color(0xFF8E0000) : const Color(0xFFFFEBEE),
          isDark ? Colors.white : const Color(0xFFB3261E),
          Icons.medical_services_outlined,
          'Professional check required',
        );
    }
  }

  static RiskVisuals forCategory(
    RiskCategory category,
    Brightness brightness,
  ) => forState(switch (category) {
    RiskCategory.lower => PatientOutputState.lowerRisk,
    RiskCategory.increased => PatientOutputState.increasedRisk,
    RiskCategory.higher => PatientOutputState.higherRisk,
  }, brightness);
}
