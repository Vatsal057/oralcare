import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oralcare/core/i18n/clinical_terms.dart';
import 'package:oralcare/core/widgets/language_toggle_button.dart';
import 'package:oralcare/domain/risk_catalog.dart';
import 'package:oralcare/state/locale_controller.dart';
import 'package:provider/provider.dart';

/// The language switch appeared broken because it worked perfectly and changed
/// nothing the patient could see: the button lived on the home screen, while the
/// only screens reading the locale were two steps into the assessment flow.
///
/// These tests hold the two halves of the fix in place — that the control
/// actually flips state and rebuilds, and that the terms it is supposed to
/// translate resolve to real Kannada rather than falling back to English.
void main() {
  group('the toggle changes state and rebuilds', () {
    testWidgets('tapping it flips English to Kannada and back', (tester) async {
      final controller = LocaleController();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: controller,
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(actions: const [LanguageToggleButton()]),
              body: Consumer<LocaleController>(
                builder: (context, c, _) => Text(
                  ClinicalTerms.smoking(c.locale),
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Smoking'), findsOneWidget);
      expect(find.text('ಧೂಮಪಾನ'), findsNothing);

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(
        find.text('ಧೂಮಪಾನ'),
        findsOneWidget,
        reason: 'a dependent widget must rebuild when the locale changes',
      );
      expect(find.text('Smoking'), findsNothing);

      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(find.text('Smoking'), findsOneWidget);
    });

    testWidgets('the indicator shows which language is active', (tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => LocaleController(),
          child: const MaterialApp(
            home: Scaffold(
              appBar: null,
              body: LanguageToggleButton(),
            ),
          ),
        ),
      );

      expect(find.text('EN'), findsOneWidget);
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();
      expect(find.text('ಕ'), findsOneWidget);
    });
  });

  group('the scope note appears only in Kannada', () {
    Widget harness(LocaleController controller) => ChangeNotifierProvider.value(
      value: controller,
      child: const MaterialApp(
        home: Scaffold(body: PartialTranslationNote()),
      ),
    );

    testWidgets('hidden in English', (tester) async {
      await tester.pumpWidget(harness(LocaleController()));
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('shown in Kannada, naming the limit', (tester) async {
      await tester.pumpWidget(
        harness(LocaleController(initial: AppLocale.kannada)),
      );
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.textContaining('stays in English'), findsOneWidget);
    });
  });

  /// A fallback that silently returns English is how a "translated" screen ends
  /// up entirely in English. Every key the lookups are pointed at must resolve.
  group('the terms being switched are really translated', () {
    test('every habit question resolves to Kannada', () {
      for (final key in ClinicalTerms.riskQuestions.keys) {
        final english = RiskCatalog.variableFor(key).label;
        final kannada = ClinicalTerms.riskQuestion(
          key,
          AppLocale.kannada,
          english,
        );
        expect(
          kannada,
          isNot(english),
          reason: '$key fell back to English, so switching does nothing',
        );
      }
    });

    test('the habit keys are real risk variables', () {
      final known = RiskCatalog.variables.map((v) => v.key).toSet();
      for (final key in ClinicalTerms.riskQuestions.keys) {
        expect(known, contains(key), reason: '$key is not a risk variable');
      }
    });

    test('yes / no / dont know resolve to Kannada', () {
      for (final value in [
        AnswerValues.yes,
        AnswerValues.no,
        AnswerValues.dontKnow,
      ]) {
        final kannada = ClinicalTerms.answerOption(
          value,
          AppLocale.kannada,
          value,
        );
        expect(kannada, isNot(value), reason: value);
      }
    });

    test('every red flag and exam site resolves to Kannada', () {
      for (final item in RedFlagCatalog.items) {
        expect(
          ClinicalTerms.redFlag(item.key, AppLocale.kannada, item.label),
          isNot(item.label),
          reason: item.key,
        );
      }
      for (final site in ExamSiteCatalog.sites) {
        expect(
          ClinicalTerms.examSite(site.key, AppLocale.kannada, site.label),
          isNot(site.label),
          reason: site.key,
        );
      }
    });

    /// Options such as "Never" and "Current, regular" have no verified Kannada.
    /// Falling back is correct there — inventing wording for a scored answer
    /// could change which option a patient picks.
    test('unverified options fall back to English rather than being guessed', () {
      expect(
        ClinicalTerms.answerOption('current_regular', AppLocale.kannada, 'Current, regular'),
        'Current, regular',
      );
    });
  });
}
