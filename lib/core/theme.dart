import 'package:flutter/material.dart';

import '../domain/risk_engine.dart';

/// Visual language for the app.
///
/// Risk colours are deliberately not the only signal: every risk state also
/// carries an icon and explicit text, so the interface does not rely on colour
/// alone to convey meaning.
class AppTheme {
  const AppTheme._();

  static const Color seed = Color(0xFF00695C);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        space: 1,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
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

  static RiskVisuals forCategory(RiskCategory category, Brightness brightness) =>
      forState(
        switch (category) {
          RiskCategory.lower => PatientOutputState.lowerRisk,
          RiskCategory.increased => PatientOutputState.increasedRisk,
          RiskCategory.higher => PatientOutputState.higherRisk,
        },
        brightness,
      );
}
