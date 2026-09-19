import 'package:flutter_test/flutter_test.dart';
import 'package:oralcare/core/i18n/clinical_terms.dart';
import 'package:oralcare/domain/risk_catalog.dart';
import 'package:oralcare/state/locale_controller.dart';

/// Kannada wording comes from the clinical team's illustrated questionnaire.
/// These tests stop the translation silently drifting out of step with the
/// catalogues: a missing term would show a patient English they cannot read, or
/// worse, nothing at all.
void main() {
  group('coverage', () {
    test('every red flag has a Kannada term', () {
      for (final item in RedFlagCatalog.items) {
        final term = ClinicalTerms.redFlags[item.key];
        expect(term, isNotNull, reason: 'no Kannada for ${item.key}');
        expect(term!.kn.trim(), isNotEmpty, reason: item.key);
        expect(term.kn, isNot(term.en), reason: '${item.key} is untranslated');
      }
    });

    test('every self-examination site has a Kannada term', () {
      for (final site in ExamSiteCatalog.sites) {
        final term = ClinicalTerms.examSites[site.key];
        expect(term, isNotNull, reason: 'no Kannada for ${site.key}');
        expect(term!.kn.trim(), isNotEmpty, reason: site.key);
      }
    });

    test('no term is left as a placeholder', () {
      final all = [
        ...ClinicalTerms.redFlags.values,
        ...ClinicalTerms.examSites.values,
        ...ClinicalTerms.genderOptions,
      ];
      for (final term in all) {
        expect(term.en.trim(), isNotEmpty);
        expect(term.kn.trim(), isNotEmpty);
        expect(term.kn.toLowerCase(), isNot(contains('todo')));
        expect(term.kn.toLowerCase(), isNot(contains('tbd')));
      }
    });
  });

  group('selection', () {
    test('a term returns the language asked for', () {
      const term = Term('White patch', 'ಬಿಳಿ ಮಚ್ಚೆ');

      expect(term(AppLocale.english), 'White patch');
      expect(term(AppLocale.kannada), 'ಬಿಳಿ ಮಚ್ಚೆ');
      expect(term.bilingual, 'White patch / ಬಿಳಿ ಮಚ್ಚೆ');
    });

    test('an unknown key falls back to the supplied English label', () {
      expect(
        ClinicalTerms.redFlag('not_a_key', AppLocale.kannada, 'Fallback'),
        'Fallback',
      );
      expect(
        ClinicalTerms.examSite('not_a_key', AppLocale.kannada, 'Fallback'),
        'Fallback',
      );
    });

    test('known keys resolve to Kannada from the questionnaire', () {
      expect(
        ClinicalTerms.redFlag('white_patch', AppLocale.kannada, 'x'),
        'ಬಿಳಿ ಮಚ್ಚೆ',
      );
      expect(
        ClinicalTerms.redFlag('red_patch', AppLocale.kannada, 'x'),
        'ಕೆಂಪು ಮಚ್ಚೆ',
      );
      expect(
        ClinicalTerms.redFlag('loose_teeth', AppLocale.kannada, 'x'),
        'ಹಠಾತ್ ಸಡಿಲವಾದ ಹಲ್ಲುಗಳು',
      );
    });

    test('locale codes round trip', () {
      expect(AppLocaleX.fromCode('kn'), AppLocale.kannada);
      expect(AppLocaleX.fromCode('en'), AppLocale.english);
      expect(AppLocaleX.fromCode(null), AppLocale.english);
      expect(AppLocale.kannada.code, 'kn');
    });
  });

  group('locale controller', () {
    test('starts in English and toggles', () {
      final controller = LocaleController();
      expect(controller.locale, AppLocale.english);
      expect(controller.isKannada, isFalse);

      controller.toggle();
      expect(controller.isKannada, isTrue);

      controller.toggle();
      expect(controller.locale, AppLocale.english);
    });

    test('notifies only on a real change', () {
      final controller = LocaleController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setLocale(AppLocale.english);
      expect(notifications, 0, reason: 'same locale must not notify');

      controller.setLocale(AppLocale.kannada);
      expect(notifications, 1);
    });
  });

  group('gender options match the questionnaire', () {
    test('male, female and transgender are offered', () {
      expect(ClinicalTerms.genderOptions.map((t) => t.en), [
        'Male',
        'Female',
        'Transgender',
      ]);
      expect(ClinicalTerms.genderOptions.map((t) => t.kn), [
        'ಪುರುಷ',
        'ಮಹಿಳೆ',
        'ನಪುಂಸಕ',
      ]);
    });
  });
}
