import 'risk_catalog.dart';

/// Patient-facing risk band derived from the provisional numerical score
/// (spec Table 3).
enum RiskCategory { lower, increased, higher }

extension RiskCategoryX on RiskCategory {
  String get storageValue => switch (this) {
    RiskCategory.lower => 'lower',
    RiskCategory.increased => 'increased',
    RiskCategory.higher => 'higher',
  };

  /// The band's score range, as shown to the patient.
  ///
  /// Derived from the cut-off constants rather than written out, so moving a
  /// threshold cannot leave the displayed range contradicting the engine.
  String get rangeLabel => switch (this) {
    RiskCategory.lower => '0 to ${RiskCatalog.lowerRiskMaxScore}',
    RiskCategory.increased =>
      '${RiskCatalog.lowerRiskMaxScore + 1} to '
          '${RiskCatalog.increasedRiskMaxScore}',
    RiskCategory.higher => '${RiskCatalog.increasedRiskMaxScore + 1} or more',
  };

  String get label => switch (this) {
    RiskCategory.lower => 'Lower risk',
    RiskCategory.increased => 'Increased risk',
    RiskCategory.higher => 'Higher risk',
  };

  static RiskCategory fromStorage(String value) => switch (value) {
    'lower' => RiskCategory.lower,
    'increased' => RiskCategory.increased,
    'higher' => RiskCategory.higher,
    _ => RiskCategory.lower,
  };
}

/// What the patient is actually shown (spec Table 7). The red-flag override is
/// a distinct state because it takes precedence over the numerical band.
enum PatientOutputState {
  lowerRisk,
  increasedRisk,
  higherRisk,

  /// Red flag reported but present for less than two weeks. Spec Table 4:
  /// "Record finding; advise observation and review if persistent".
  observeAndReview,

  /// Spec Table 4: red flag persisting two weeks or more, or a previous OSCC.
  professionalCheckRequired,
}

extension PatientOutputStateX on PatientOutputState {
  String get storageValue => switch (this) {
    PatientOutputState.lowerRisk => 'lower_risk',
    PatientOutputState.increasedRisk => 'increased_risk',
    PatientOutputState.higherRisk => 'higher_risk',
    PatientOutputState.observeAndReview => 'observe_and_review',
    PatientOutputState.professionalCheckRequired => 'professional_check',
  };

  static PatientOutputState fromStorage(String value) => switch (value) {
    'lower_risk' => PatientOutputState.lowerRisk,
    'increased_risk' => PatientOutputState.increasedRisk,
    'higher_risk' => PatientOutputState.higherRisk,
    'observe_and_review' => PatientOutputState.observeAndReview,
    'professional_check' => PatientOutputState.professionalCheckRequired,
    _ => PatientOutputState.lowerRisk,
  };

  /// Headline shown on the patient result screen.
  String get headline => switch (this) {
    PatientOutputState.lowerRisk => 'Lower risk',
    PatientOutputState.increasedRisk => 'Increased risk',
    PatientOutputState.higherRisk => 'Higher risk',
    PatientOutputState.observeAndReview =>
      'Finding recorded — review if it persists',
    PatientOutputState.professionalCheckRequired =>
      'PROFESSIONAL CHECK REQUIRED',
  };

  /// Guidance text, transcribed from spec Table 7.
  String get guidance => switch (this) {
    PatientOutputState.lowerRisk =>
      'Your answers suggest lower risk at this time. Keep up prevention: avoid '
          'tobacco, areca nut and heavy alcohol, and attend a routine dental '
          'or oral examination.',
    PatientOutputState.increasedRisk =>
      'Your answers suggest increased risk. Stopping tobacco, areca nut and '
          'reducing alcohol will lower your risk. A professional oral '
          'examination is recommended.',
    PatientOutputState.higherRisk =>
      'Your answers suggest higher risk. Please arrange a professional oral '
          'examination.',
    PatientOutputState.observeAndReview =>
      'Your finding has been recorded. Watch it closely. If it is still there '
          'after two weeks, a professional check is required. Come back to the '
          'app to update the duration.',
    PatientOutputState.professionalCheckRequired =>
      'Please arrange to be seen by a dentist or doctor. This app cannot '
          'diagnose cancer — it is telling you that a professional needs to '
          'look at this.',
  };

  /// `true` where the app is escalating rather than reassuring.
  bool get isUrgent => this == PatientOutputState.professionalCheckRequired;
}

/// Why the engine reached its conclusion. Stored and shown to both the patient
/// and the reviewing clinician so the decision is never a black box.
class RiskReason {
  const RiskReason(this.code, this.detail);
  final String code;
  final String detail;

  @override
  String toString() => detail;
}

/// Immutable result of one evaluation.
class RiskResult {
  const RiskResult({
    required this.totalScore,
    required this.category,
    required this.outputState,
    required this.redFlagPresent,
    required this.redFlagKeys,
    required this.lesionPersistent,
    required this.previousOscc,
    required this.professionalCheckRequired,
    required this.referralAlert,
    required this.unknownAnswerKeys,
    required this.reasons,
    required this.scoreBreakdown,
  });

  final int totalScore;

  /// Numerical band. Retained even when the red-flag override fires, because
  /// the validation database compares band against clinical outcome.
  final RiskCategory category;

  /// What the patient is shown.
  final PatientOutputState outputState;

  final bool redFlagPresent;
  final List<String> redFlagKeys;

  /// Red flag reported as present for two weeks or longer.
  final bool lesionPersistent;

  final bool previousOscc;

  /// Spec Table 4 override.
  final bool professionalCheckRequired;

  /// Drives the doctor's queue alert.
  final bool referralAlert;

  /// Variables answered "Don't know" — retained as unknown, not scored as 0.
  final List<String> unknownAnswerKeys;

  final List<RiskReason> reasons;

  /// Per-variable contribution, for transparency and pilot validation.
  final Map<String, int> scoreBreakdown;

  bool get hasUnknownAnswers => unknownAnswerKeys.isNotEmpty;
}

/// The risk and safety engine.
///
/// Spec section 1: "Calculates the provisional risk score and applies the
/// red-flag override. Red flags take precedence over the numerical score."
///
/// Clinical safety principle (spec section 7): the application supports
/// awareness, early recognition and referral. It does not diagnose or stage
/// OSCC automatically. Nothing in this class may output a diagnosis.
class RiskEngine {
  const RiskEngine._();

  /// Maps a provisional total onto the patient-facing band (spec Table 3).
  static RiskCategory categoryForScore(int score) {
    if (score <= RiskCatalog.lowerRiskMaxScore) return RiskCategory.lower;
    if (score <= RiskCatalog.increasedRiskMaxScore) {
      return RiskCategory.increased;
    }
    return RiskCategory.higher;
  }

  /// `true` when the patient reports any tobacco / areca / gutkha exposure.
  /// Controls whether the duration and frequency questions apply.
  static bool hasExposure(Map<String, String?> answers) {
    for (final key in RiskCatalog.exposureVariableKeys) {
      final value = answers[key];
      if (value == null) continue;
      if (!RiskCatalog.noExposureValues.contains(value)) return true;
    }
    return false;
  }

  /// Evaluates one assessment.
  ///
  /// [answers] maps a [RiskKeys] key to the selected [RiskOption.value].
  /// [redFlagKeys] are the red-flag items answered "Yes" (spec section 2.3).
  /// [lesionDurationDays] is the duration from the lesion record, when present;
  /// it is combined with the two-week band so either source can establish
  /// persistence.
  /// [selfExamAbnormality] is `true` when the guided self-examination reported
  /// an abnormality at any site.
  static RiskResult evaluate({
    required int age,
    required Map<String, String?> answers,
    Set<String> redFlagKeys = const {},
    int? lesionDurationDays,
    bool selfExamAbnormality = false,
  }) {
    final breakdown = <String, int>{};
    final unknown = <String>[];
    final reasons = <RiskReason>[];

    final resolved = Map<String, String?>.from(answers);
    // Age band is derived from the registered age, never asked twice.
    resolved[RiskKeys.ageBand] = RiskCatalog.ageBandForAge(age);

    final exposurePresent = hasExposure(resolved);

    var total = 0;
    for (final variable in RiskCatalog.variables) {
      final value = resolved[variable.key];

      if (variable.requiresExposure && !exposurePresent) {
        // Not applicable for a never-user. Recorded as 0 so the breakdown is
        // complete rather than silently missing.
        breakdown[variable.key] = 0;
        continue;
      }

      final option = variable.optionFor(value);
      if (option == null) {
        breakdown[variable.key] = 0;
        continue;
      }

      if (option.unknown) {
        unknown.add(variable.key);
        breakdown[variable.key] = 0;
        continue;
      }

      if (variable.role != RiskVariableRole.scored) {
        // Exposure-only, gate and trigger variables are recorded, not scored.
        breakdown[variable.key] = 0;
        continue;
      }

      breakdown[variable.key] = option.score;
      total += option.score;
    }

    final category = categoryForScore(total);

    // ---- Red flags and duration -------------------------------------------
    final gateSaysYes = resolved[RiskKeys.suspiciousLesion] == AnswerValues.yes;
    final neckLump = resolved[RiskKeys.neckLump] == AnswerValues.yes;

    final flags = <String>{...redFlagKeys};
    // Spec Table 2 lists the neck lump as its own referral trigger, and
    // section 2.3 also lists "persistent neck lump" in the checklist. Keep the
    // two consistent so a neck lump can never be silently dropped.
    if (neckLump) flags.add('persistent_neck_lump');

    final redFlagPresent = flags.isNotEmpty || gateSaysYes;

    final durationBand = resolved[RiskKeys.lesionDuration];
    final persistentByBand = durationBand == AnswerValues.twoWeeksOrMore;
    final persistentByDays =
        lesionDurationDays != null &&
        lesionDurationDays >= RiskCatalog.persistenceThresholdDays;
    final lesionPersistent =
        redFlagPresent && (persistentByBand || persistentByDays);

    final previousOscc = resolved[RiskKeys.previousOscc] == AnswerValues.yes;

    // ---- Override logic, spec Table 4 -------------------------------------
    // Precedence: red flags take precedence over the numerical score, and a
    // previous OSCC warrants professional follow-up irrespective of score.
    var professionalCheck = false;
    PatientOutputState state;

    if (redFlagPresent && lesionPersistent) {
      professionalCheck = true;
      state = PatientOutputState.professionalCheckRequired;
      reasons.add(
        const RiskReason(
          'red_flag_persistent',
          'A red-flag finding has been present for two weeks or longer, so the '
              'red-flag override applies and a professional check is required.',
        ),
      );
    } else if (previousOscc) {
      professionalCheck = true;
      state = PatientOutputState.professionalCheckRequired;
      reasons.add(
        const RiskReason(
          'previous_oscc',
          'Previous oral cancer reported, so professional follow-up is advised '
              'irrespective of the score.',
        ),
      );
    } else if (redFlagPresent) {
      state = PatientOutputState.observeAndReview;
      reasons.add(
        const RiskReason(
          'red_flag_short_duration',
          'A red-flag finding is present but has lasted less than two weeks. '
              'The finding is recorded; observation and review are advised if it '
              'persists.',
        ),
      );
    } else {
      state = switch (category) {
        RiskCategory.lower => PatientOutputState.lowerRisk,
        RiskCategory.increased => PatientOutputState.increasedRisk,
        RiskCategory.higher => PatientOutputState.higherRisk,
      };
      reasons.add(
        RiskReason(
          'numerical_category',
          'No red flag reported, so the provisional numerical score of $total '
              'places this assessment in the ${category.label.toLowerCase()} '
              'band.',
        ),
      );
    }

    if (previousOscc &&
        state == PatientOutputState.professionalCheckRequired &&
        !reasons.any((r) => r.code == 'previous_oscc')) {
      reasons.add(
        const RiskReason(
          'previous_oscc',
          'Previous oral cancer reported, so professional follow-up is advised '
              'irrespective of the score.',
        ),
      );
    }

    if (selfExamAbnormality) {
      reasons.add(
        const RiskReason(
          'self_exam_abnormality',
          'The guided self-examination reported an abnormality, so the '
              'lesion-recording module was opened.',
        ),
      );
    }

    if (unknown.isNotEmpty) {
      reasons.add(
        RiskReason(
          'unknown_answers',
          'Retained as unknown rather than scored as zero: '
              '${unknown.map((k) => RiskCatalog.variableFor(k).label).join(', ')}.',
        ),
      );
    }

    // A higher band also warrants a professional oral examination (Table 7),
    // so it raises a queue alert without being an override.
    final referralAlert =
        professionalCheck ||
        category == RiskCategory.higher ||
        (redFlagPresent && selfExamAbnormality);

    return RiskResult(
      totalScore: total,
      category: category,
      outputState: state,
      redFlagPresent: redFlagPresent,
      redFlagKeys: flags.toList(growable: false),
      lesionPersistent: lesionPersistent,
      previousOscc: previousOscc,
      professionalCheckRequired: professionalCheck,
      referralAlert: referralAlert,
      unknownAnswerKeys: unknown,
      reasons: reasons,
      scoreBreakdown: breakdown,
    );
  }
}
