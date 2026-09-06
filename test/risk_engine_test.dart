import 'package:flutter_test/flutter_test.dart';
import 'package:oralcare/domain/risk_catalog.dart';
import 'package:oralcare/domain/risk_engine.dart';

/// Verifies the engine against the specification tables.
///
/// These tests are the guard on the provisional weights: if someone changes a
/// score in [RiskCatalog] without a documented clinical decision, the expected
/// totals here will fail.
void main() {
  /// Answers with every scored variable at its zero option.
  Map<String, String?> baseline() => {
        RiskKeys.smoking: 'never',
        RiskKeys.smokelessTobacco: 'never',
        RiskKeys.areca: 'never',
        RiskKeys.gutkha: 'no',
        RiskKeys.alcohol: 'none',
        RiskKeys.previousOpmd: AnswerValues.no,
        RiskKeys.previousOscc: AnswerValues.no,
        RiskKeys.suspiciousLesion: AnswerValues.no,
        RiskKeys.neckLump: AnswerValues.no,
      };

  group('Age bands (spec Table 2: 0/1/2/3)', () {
    test('map ages onto the correct band', () {
      expect(RiskCatalog.ageBandForAge(18), 'lt_40');
      expect(RiskCatalog.ageBandForAge(39), 'lt_40');
      expect(RiskCatalog.ageBandForAge(40), '40_49');
      expect(RiskCatalog.ageBandForAge(49), '40_49');
      expect(RiskCatalog.ageBandForAge(50), '50_59');
      expect(RiskCatalog.ageBandForAge(59), '50_59');
      expect(RiskCatalog.ageBandForAge(60), 'gte_60');
      expect(RiskCatalog.ageBandForAge(91), 'gte_60');
    });

    test('contribute 0, 1, 2 and 3 to the total', () {
      for (final (age, expected) in [(30, 0), (45, 1), (55, 2), (70, 3)]) {
        final result = RiskEngine.evaluate(age: age, answers: baseline());
        expect(
          result.totalScore,
          expected,
          reason: 'age $age should contribute $expected',
        );
      }
    });
  });

  group('Category cut-offs (spec Table 3)', () {
    test('0 to 4 is lower risk', () {
      expect(RiskEngine.categoryForScore(0), RiskCategory.lower);
      expect(RiskEngine.categoryForScore(4), RiskCategory.lower);
    });

    test('5 to 9 is increased risk', () {
      expect(RiskEngine.categoryForScore(5), RiskCategory.increased);
      expect(RiskEngine.categoryForScore(9), RiskCategory.increased);
    });

    test('10 or more is higher risk', () {
      expect(RiskEngine.categoryForScore(10), RiskCategory.higher);
      expect(RiskEngine.categoryForScore(25), RiskCategory.higher);
    });
  });

  group('Individual variable weights (spec Table 2)', () {
    test('smoking scores 0/1/2/3', () {
      final expected = {
        'never': 0,
        'former': 1,
        'current_occasional': 2,
        'current_regular': 3,
      };
      expected.forEach((value, score) {
        final result = RiskEngine.evaluate(
          age: 30,
          answers: baseline()..[RiskKeys.smoking] = value,
        );
        expect(result.scoreBreakdown[RiskKeys.smoking], score);
      });
    });

    test('smokeless tobacco scores 0/1/3, skipping 2', () {
      final expected = {'never': 0, 'former': 1, 'current': 3};
      expected.forEach((value, score) {
        final result = RiskEngine.evaluate(
          age: 30,
          answers: baseline()..[RiskKeys.smokelessTobacco] = value,
        );
        expect(result.scoreBreakdown[RiskKeys.smokelessTobacco], score);
      });
    });

    test('areca / betel nut scores 0/1/2/3', () {
      final expected = {
        'never': 0,
        'former': 1,
        'occasional_current': 2,
        'regular_current': 3,
      };
      expected.forEach((value, score) {
        final result = RiskEngine.evaluate(
          age: 30,
          answers: baseline()..[RiskKeys.areca] = value,
        );
        expect(result.scoreBreakdown[RiskKeys.areca], score);
      });
    });

    test('alcohol scores 0/1/2', () {
      final expected = {'none': 0, 'occasional': 1, 'regular': 2};
      expected.forEach((value, score) {
        final result = RiskEngine.evaluate(
          age: 30,
          answers: baseline()..[RiskKeys.alcohol] = value,
        );
        expect(result.scoreBreakdown[RiskKeys.alcohol], score);
      });
    });

    test('previous OPMD scores 4 when reported', () {
      final result = RiskEngine.evaluate(
        age: 30,
        answers: baseline()..[RiskKeys.previousOpmd] = AnswerValues.yes,
      );
      expect(result.scoreBreakdown[RiskKeys.previousOpmd], 4);
      expect(result.totalScore, 4);
      expect(result.category, RiskCategory.lower);
    });

    test('previous OSCC scores 5 when reported', () {
      final result = RiskEngine.evaluate(
        age: 30,
        answers: baseline()..[RiskKeys.previousOscc] = AnswerValues.yes,
      );
      expect(result.scoreBreakdown[RiskKeys.previousOscc], 5);
      expect(result.totalScore, 5);
    });
  });

  group('Gutkha / pan masala is recorded but not yet weighted', () {
    test('current use does not change the score', () {
      final without = RiskEngine.evaluate(age: 30, answers: baseline());
      final with_ = RiskEngine.evaluate(
        age: 30,
        answers: baseline()..[RiskKeys.gutkha] = 'current',
      );
      expect(with_.totalScore, without.totalScore);
      expect(with_.scoreBreakdown[RiskKeys.gutkha], 0);
    });

    test('but it still counts as exposure for duration and frequency', () {
      final answers = baseline()
        ..[RiskKeys.gutkha] = 'current'
        ..[RiskKeys.exposureDuration] = 'gt_10y'
        ..[RiskKeys.useFrequency] = 'several_daily';
      final result = RiskEngine.evaluate(age: 30, answers: answers);
      expect(result.scoreBreakdown[RiskKeys.exposureDuration], 2);
      expect(result.scoreBreakdown[RiskKeys.useFrequency], 2);
      expect(result.totalScore, 4);
    });
  });

  group('Duration and frequency only apply with exposure', () {
    test('a never-user scores 0 even if stale answers are present', () {
      // Simulates a patient who answered these, then changed every habit to
      // "never". The stale answers must not leak into the score.
      final answers = baseline()
        ..[RiskKeys.exposureDuration] = 'gt_10y'
        ..[RiskKeys.useFrequency] = 'several_daily';
      final result = RiskEngine.evaluate(age: 30, answers: answers);
      expect(result.scoreBreakdown[RiskKeys.exposureDuration], 0);
      expect(result.scoreBreakdown[RiskKeys.useFrequency], 0);
      expect(result.totalScore, 0);
    });

    test('duration scores 0/1/2 once exposure exists', () {
      final expected = {'lt_5y': 0, '5_10y': 1, 'gt_10y': 2};
      expected.forEach((value, score) {
        final result = RiskEngine.evaluate(
          age: 30,
          answers: baseline()
            ..[RiskKeys.smoking] = 'current_regular'
            ..[RiskKeys.exposureDuration] = value,
        );
        expect(result.scoreBreakdown[RiskKeys.exposureDuration], score);
      });
    });

    test('hasExposure detects each exposure variable', () {
      expect(RiskEngine.hasExposure(baseline()), isFalse);
      expect(
        RiskEngine.hasExposure(baseline()..[RiskKeys.smoking] = 'former'),
        isTrue,
      );
      expect(
        RiskEngine.hasExposure(
          baseline()..[RiskKeys.smokelessTobacco] = 'current',
        ),
        isTrue,
      );
      expect(
        RiskEngine.hasExposure(baseline()..[RiskKeys.areca] = 'former'),
        isTrue,
      );
      expect(
        RiskEngine.hasExposure(baseline()..[RiskKeys.gutkha] = 'past'),
        isTrue,
      );
    });
  });

  group('Unknown answers are retained, not scored as zero', () {
    test('"Don\'t know" for previous OPMD is flagged as unknown', () {
      final result = RiskEngine.evaluate(
        age: 30,
        answers: baseline()..[RiskKeys.previousOpmd] = AnswerValues.dontKnow,
      );
      expect(result.hasUnknownAnswers, isTrue);
      expect(result.unknownAnswerKeys, contains(RiskKeys.previousOpmd));
      expect(result.scoreBreakdown[RiskKeys.previousOpmd], 0);
      expect(
        result.reasons.any((r) => r.code == 'unknown_answers'),
        isTrue,
      );
    });
  });

  group('Cumulative scoring', () {
    test('a heavy-exposure case reaches the higher band', () {
      final answers = baseline()
        ..[RiskKeys.smoking] = 'current_regular' // 3
        ..[RiskKeys.smokelessTobacco] = 'current' // 3
        ..[RiskKeys.areca] = 'regular_current' // 3
        ..[RiskKeys.gutkha] = 'current' // 0, unweighted
        ..[RiskKeys.exposureDuration] = 'gt_10y' // 2
        ..[RiskKeys.useFrequency] = 'several_daily' // 2
        ..[RiskKeys.alcohol] = 'regular' // 2
        ..[RiskKeys.previousOpmd] = AnswerValues.yes; // 4

      // age 65 contributes 3 => 3+3+3+3+2+2+2+4 = 22
      final result = RiskEngine.evaluate(age: 65, answers: answers);
      expect(result.totalScore, 22);
      expect(result.category, RiskCategory.higher);
      expect(result.outputState, PatientOutputState.higherRisk);
      expect(result.referralAlert, isTrue,
          reason: 'higher risk warrants a professional examination');
    });

    test('a boundary case of exactly 5 is increased risk', () {
      // age 50 => 2, smoking former => 1, alcohol regular => 2. Total 5.
      final answers = baseline()
        ..[RiskKeys.smoking] = 'former'
        ..[RiskKeys.alcohol] = 'regular'
        ..[RiskKeys.exposureDuration] = 'lt_5y'
        ..[RiskKeys.useFrequency] = 'occasional';
      final result = RiskEngine.evaluate(age: 50, answers: answers);
      expect(result.totalScore, 5);
      expect(result.category, RiskCategory.increased);
      expect(result.outputState, PatientOutputState.increasedRisk);
    });

    test('maxPossibleScore matches the sum of the highest scored options', () {
      // age 3 + smoking 3 + smokeless 3 + areca 3 + duration 2 + frequency 2
      // + alcohol 2 + OPMD 4 + OSCC 5 = 27
      expect(RiskCatalog.maxPossibleScore, 27);
    });
  });

  group('Red-flag override (spec Table 4)', () {
    Map<String, String?> withRedFlag(String durationBand) => baseline()
      ..[RiskKeys.suspiciousLesion] = AnswerValues.yes
      ..[RiskKeys.lesionDuration] = durationBand;

    test('no red flag falls through to the numerical category', () {
      final result = RiskEngine.evaluate(age: 30, answers: baseline());
      expect(result.redFlagPresent, isFalse);
      expect(result.professionalCheckRequired, isFalse);
      expect(result.outputState, PatientOutputState.lowerRisk);
      expect(
        result.reasons.any((r) => r.code == 'numerical_category'),
        isTrue,
      );
    });

    test('red flag under two weeks records the finding and advises review', () {
      final result = RiskEngine.evaluate(
        age: 30,
        answers: withRedFlag(AnswerValues.lessThanTwoWeeks),
        redFlagKeys: {'non_healing_ulcer'},
      );
      expect(result.redFlagPresent, isTrue);
      expect(result.lesionPersistent, isFalse);
      expect(result.professionalCheckRequired, isFalse);
      expect(result.outputState, PatientOutputState.observeAndReview);
      expect(
        result.reasons.any((r) => r.code == 'red_flag_short_duration'),
        isTrue,
      );
    });

    test('red flag of two weeks or more forces a professional check', () {
      final result = RiskEngine.evaluate(
        age: 30,
        answers: withRedFlag(AnswerValues.twoWeeksOrMore),
        redFlagKeys: {'non_healing_ulcer'},
      );
      expect(result.lesionPersistent, isTrue);
      expect(result.professionalCheckRequired, isTrue);
      expect(
        result.outputState,
        PatientOutputState.professionalCheckRequired,
      );
      expect(result.referralAlert, isTrue);
      expect(
        result.reasons.any((r) => r.code == 'red_flag_persistent'),
        isTrue,
      );
    });

    test('red flags take precedence over a low numerical score', () {
      final result = RiskEngine.evaluate(
        age: 25, // score 0
        answers: withRedFlag(AnswerValues.twoWeeksOrMore),
        redFlagKeys: {'red_and_white_patch'},
      );
      expect(result.totalScore, 0);
      expect(result.category, RiskCategory.lower,
          reason: 'the numerical band is still recorded for validation');
      expect(
        result.outputState,
        PatientOutputState.professionalCheckRequired,
        reason: 'but the patient-facing output is overridden',
      );
    });

    test('a lesion record of 14 days or more establishes persistence', () {
      // The band says under two weeks, but the lesion record says 20 days.
      // The engine escalates rather than trusting the softer answer.
      final result = RiskEngine.evaluate(
        age: 30,
        answers: withRedFlag(AnswerValues.lessThanTwoWeeks),
        redFlagKeys: {'white_patch'},
        lesionDurationDays: 20,
      );
      expect(result.lesionPersistent, isTrue);
      expect(result.professionalCheckRequired, isTrue);
    });

    test('13 days does not reach the two-week threshold', () {
      final result = RiskEngine.evaluate(
        age: 30,
        answers: withRedFlag(AnswerValues.lessThanTwoWeeks),
        redFlagKeys: {'white_patch'},
        lesionDurationDays: 13,
      );
      expect(result.lesionPersistent, isFalse);
      expect(result.outputState, PatientOutputState.observeAndReview);
    });

    test('exactly 14 days does reach it', () {
      final result = RiskEngine.evaluate(
        age: 30,
        answers: withRedFlag(AnswerValues.lessThanTwoWeeks),
        redFlagKeys: {'white_patch'},
        lesionDurationDays: RiskCatalog.persistenceThresholdDays,
      );
      expect(result.lesionPersistent, isTrue);
      expect(result.professionalCheckRequired, isTrue);
    });

    test('persistence requires a red flag to be present at all', () {
      // A long-standing but non-red-flag history must not trip the override.
      final result = RiskEngine.evaluate(
        age: 30,
        answers: baseline(),
        lesionDurationDays: 90,
      );
      expect(result.redFlagPresent, isFalse);
      expect(result.lesionPersistent, isFalse);
      expect(result.professionalCheckRequired, isFalse);
    });
  });

  group('Previous OSCC warrants follow-up irrespective of score', () {
    test('overrides a lower-risk output', () {
      final result = RiskEngine.evaluate(
        age: 25,
        answers: baseline()..[RiskKeys.previousOscc] = AnswerValues.yes,
      );
      expect(result.totalScore, 5, reason: 'OSCC contributes 5');
      expect(result.previousOscc, isTrue);
      expect(result.professionalCheckRequired, isTrue);
      expect(
        result.outputState,
        PatientOutputState.professionalCheckRequired,
      );
      expect(result.reasons.any((r) => r.code == 'previous_oscc'), isTrue);
    });

    test('does not double-report its reason when a red flag also persists', () {
      final result = RiskEngine.evaluate(
        age: 25,
        answers: baseline()
          ..[RiskKeys.previousOscc] = AnswerValues.yes
          ..[RiskKeys.suspiciousLesion] = AnswerValues.yes
          ..[RiskKeys.lesionDuration] = AnswerValues.twoWeeksOrMore,
        redFlagKeys: {'lump_thickening'},
      );
      expect(result.professionalCheckRequired, isTrue);
      expect(
        result.reasons.where((r) => r.code == 'previous_oscc').length,
        1,
      );
    });
  });

  group('Neck lump handling', () {
    test('a reported neck lump is added to the red-flag list', () {
      final result = RiskEngine.evaluate(
        age: 30,
        answers: baseline()..[RiskKeys.neckLump] = AnswerValues.yes,
      );
      expect(result.redFlagPresent, isTrue);
      expect(result.redFlagKeys, contains('persistent_neck_lump'));
    });

    test('a neck lump alone without duration advises observation', () {
      final result = RiskEngine.evaluate(
        age: 30,
        answers: baseline()..[RiskKeys.neckLump] = AnswerValues.yes,
      );
      expect(result.outputState, PatientOutputState.observeAndReview);
    });

    test('is not duplicated when also ticked in the checklist', () {
      final result = RiskEngine.evaluate(
        age: 30,
        answers: baseline()..[RiskKeys.neckLump] = AnswerValues.yes,
        redFlagKeys: {'persistent_neck_lump'},
      );
      expect(
        result.redFlagKeys.where((k) => k == 'persistent_neck_lump').length,
        1,
      );
    });
  });

  group('Self-examination interaction', () {
    test('a reported abnormality is recorded in the reasoning', () {
      final result = RiskEngine.evaluate(
        age: 30,
        answers: baseline(),
        selfExamAbnormality: true,
      );
      expect(
        result.reasons.any((r) => r.code == 'self_exam_abnormality'),
        isTrue,
      );
    });

    test('a red flag plus a self-exam abnormality raises a referral alert', () {
      final result = RiskEngine.evaluate(
        age: 30,
        answers: baseline()
          ..[RiskKeys.suspiciousLesion] = AnswerValues.yes
          ..[RiskKeys.lesionDuration] = AnswerValues.lessThanTwoWeeks,
        redFlagKeys: {'red_patch'},
        selfExamAbnormality: true,
      );
      expect(result.professionalCheckRequired, isFalse,
          reason: 'under two weeks, so no override');
      expect(result.referralAlert, isTrue,
          reason: 'but the doctor queue should still surface it');
    });
  });

  group('Catalogue integrity', () {
    test('all ten red flags from the spec are present', () {
      expect(RedFlagCatalog.items.length, 10);
      expect(
        RedFlagCatalog.items.map((i) => i.key).toSet().length,
        10,
        reason: 'keys must be unique',
      );
    });

    test('all seven self-examination sites from the spec are present', () {
      expect(ExamSiteCatalog.sites.length, 7);
      expect(
        ExamSiteCatalog.sites.map((s) => s.key).toSet().length,
        7,
        reason: 'keys must be unique',
      );
    });

    test('all thirteen risk variables from Table 2 are present', () {
      expect(RiskCatalog.variables.length, 13);
    });

    test('variable keys are unique', () {
      final keys = RiskCatalog.variables.map((v) => v.key).toList();
      expect(keys.toSet().length, keys.length);
    });

    test('option values are unique within each variable', () {
      for (final variable in RiskCatalog.variables) {
        final values = variable.options.map((o) => o.value).toList();
        expect(
          values.toSet().length,
          values.length,
          reason: 'duplicate option value in ${variable.key}',
        );
      }
    });

    test('only the age band is derived', () {
      expect(RiskCatalog.askedVariables.length, 12);
      expect(
        RiskCatalog.askedVariables.any((v) => v.key == RiskKeys.ageBand),
        isFalse,
      );
    });
  });

  group('Output guidance never claims a diagnosis', () {
    test('no patient-facing text asserts that the user has cancer', () {
      for (final state in PatientOutputState.values) {
        final text = '${state.headline} ${state.guidance}'.toLowerCase();
        expect(
          text.contains('you have cancer'),
          isFalse,
          reason: '$state must not assert a diagnosis',
        );
        expect(
          text.contains('diagnos'),
          // The urgent state explicitly says it *cannot* diagnose, which is
          // the only permitted use of the word.
          state == PatientOutputState.professionalCheckRequired,
        );
      }
    });

    test('the urgent state is marked urgent and others are not', () {
      expect(PatientOutputState.professionalCheckRequired.isUrgent, isTrue);
      expect(PatientOutputState.lowerRisk.isUrgent, isFalse);
      expect(PatientOutputState.increasedRisk.isUrgent, isFalse);
      expect(PatientOutputState.higherRisk.isUrgent, isFalse);
      expect(PatientOutputState.observeAndReview.isUrgent, isFalse);
    });
  });

  group('Storage round-trip of enums', () {
    test('risk categories survive a round trip', () {
      for (final category in RiskCategory.values) {
        expect(
          RiskCategoryX.fromStorage(category.storageValue),
          category,
        );
      }
    });

    test('output states survive a round trip', () {
      for (final state in PatientOutputState.values) {
        expect(
          PatientOutputStateX.fromStorage(state.storageValue),
          state,
        );
      }
    });
  });
}
