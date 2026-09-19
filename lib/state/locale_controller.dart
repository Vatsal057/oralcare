import 'package:flutter/foundation.dart';

import '../core/i18n/clinical_terms.dart';

/// Holds the language the patient chose for clinical questions.
///
/// Session-scoped on purpose: the choice is not yet written to the profile, so a
/// guest can use Kannada without an account. Persisting it is a small follow-up
/// once the clinical team confirms the Kannada wording in the field.
class LocaleController extends ChangeNotifier {
  LocaleController({AppLocale initial = AppLocale.english}) : _locale = initial;

  AppLocale _locale;
  AppLocale get locale => _locale;

  bool get isKannada => _locale == AppLocale.kannada;

  void setLocale(AppLocale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  void toggle() => setLocale(
    _locale == AppLocale.english ? AppLocale.kannada : AppLocale.english,
  );
}
