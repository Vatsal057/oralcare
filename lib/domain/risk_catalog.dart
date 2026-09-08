/// Clinical catalogue for the oral-cancer application.
///
/// Every score, band and cut-off in this file is transcribed directly from the
/// approved specification (section 2.2 "Risk-Assessment Inputs", section 2.3
/// "Red-Flag Safety Check" and section 2.4 "Guided Mouth Self-Examination").
///
/// IMPORTANT (spec section 2.2): the scores and cut-offs are PROVISIONAL for
/// pilot development and must be validated before they are treated as final
/// clinical thresholds. Do not change a weight here without a documented
/// clinical decision, because the OUTCOME table is used to validate exactly
/// these numbers.
library;

/// A single selectable answer for a risk variable.
class RiskOption {
  const RiskOption(
    this.value,
    this.label, {
    this.score = 0,
    this.unknown = false,
    this.unweighted = false,
  });

  /// Stable machine value persisted in the database. Never localise this.
  final String value;

  /// Text shown to the patient.
  final String label;

  /// Provisional score contribution (spec Table 2).
  final int score;

  /// `true` for "Don't know" style answers. Spec says these are retained as
  /// unknown rather than scored as zero, so the record is auditable.
  final bool unknown;

  /// `true` where the spec says "capture exposure; final weight to be
  /// validated" — the answer is stored but deliberately contributes 0.
  final bool unweighted;
}

/// How a variable participates in the risk / safety engine.
enum RiskVariableRole {
  /// Contributes its option score to the provisional total.
  scored,

  /// Recorded for validation but contributes no score yet.
  exposureOnly,

  /// The gate question that opens the red-flag checklist.
  redFlagGate,

  /// Recorded and may raise a referral trigger, but is not scored.
  referralTrigger,
}

/// Definition of one risk-assessment question.
class RiskVariable {
  const RiskVariable({
    required this.key,
    required this.label,
    required this.options,
    this.role = RiskVariableRole.scored,
    this.note,
    this.requiresExposure = false,
    this.derived = false,
  });

  /// Database key. Persisted inside `risk_assessments.answers_json`.
  final String key;
  final String label;
  final List<RiskOption> options;
  final RiskVariableRole role;

  /// Clinical footnote surfaced in the UI so the clinician/pilot team can see
  /// which weights are still provisional.
  final String? note;

  /// Spec lists "Duration of tobacco/areca exposure" and "Frequency of use"
  /// as separate variables. They are only meaningful when the patient reports
  /// some tobacco/areca/gutkha exposure, so they are skipped (and scored 0)
  /// for never-users.
  final bool requiresExposure;

  /// `true` when the value is computed rather than asked (age band is derived
  /// from the registered age).
  final bool derived;

  RiskOption? optionFor(String? value) {
    if (value == null) return null;
    for (final option in options) {
      if (option.value == value) return option;
    }
    return null;
  }
}

/// Keys used across the engine, UI and database. Centralised to avoid typos.
class RiskKeys {
  static const ageBand = 'age_band';
  static const smoking = 'smoking';
  static const smokelessTobacco = 'smokeless_tobacco';
  static const areca = 'areca_betel';
  static const gutkha = 'gutkha_pan_masala';
  static const exposureDuration = 'exposure_duration';
  static const useFrequency = 'use_frequency';
  static const alcohol = 'alcohol';
  static const previousOpmd = 'previous_opmd';
  static const previousOscc = 'previous_oscc';
  static const suspiciousLesion = 'suspicious_lesion';
  static const lesionDuration = 'lesion_duration';
  static const neckLump = 'neck_lump';
}

/// Canonical yes/no/unknown option values.
class AnswerValues {
  static const yes = 'yes';
  static const no = 'no';
  static const dontKnow = 'dont_know';

  static const lessThanTwoWeeks = 'lt_2_weeks';
  static const twoWeeksOrMore = 'gte_2_weeks';
}

/// The risk-assessment catalogue, in the order the spec presents it.
class RiskCatalog {
  const RiskCatalog._();

  /// Spec Table 3 — patient-facing category cut-offs.
  static const int lowerRiskMaxScore = 4;
  static const int increasedRiskMaxScore = 9;

  /// Spec section 2.3 / Table 4 — a red flag lasting this long or longer
  /// triggers the professional-check override.
  static const int persistenceThresholdDays = 14;

  /// Age bands, spec Table 2: `<40 / 40–49 / 50–59 / >=60` scoring `0/1/2/3`.
  static const RiskVariable ageBand = RiskVariable(
    key: RiskKeys.ageBand,
    label: 'Age',
    derived: true,
    options: [
      RiskOption('lt_40', 'Under 40', score: 0),
      RiskOption('40_49', '40 to 49', score: 1),
      RiskOption('50_59', '50 to 59', score: 2),
      RiskOption('gte_60', '60 or above', score: 3),
    ],
  );

  /// Maps a registered age in years onto the spec's age band.
  static String ageBandForAge(int age) {
    if (age < 40) return 'lt_40';
    if (age <= 49) return '40_49';
    if (age <= 59) return '50_59';
    return 'gte_60';
  }

  static const List<RiskVariable> variables = [
    ageBand,
    RiskVariable(
      key: RiskKeys.smoking,
      label: 'Smoking',
      options: [
        RiskOption('never', 'Never', score: 0),
        RiskOption('former', 'Former', score: 1),
        RiskOption('current_occasional', 'Current, occasional', score: 2),
        RiskOption('current_regular', 'Current, regular', score: 3),
      ],
    ),
    RiskVariable(
      key: RiskKeys.smokelessTobacco,
      label: 'Smokeless tobacco',
      options: [
        RiskOption('never', 'Never', score: 0),
        RiskOption('former', 'Former', score: 1),
        RiskOption('current', 'Current', score: 3),
      ],
    ),
    RiskVariable(
      key: RiskKeys.areca,
      label: 'Areca / betel nut',
      options: [
        RiskOption('never', 'Never', score: 0),
        RiskOption('former', 'Former', score: 1),
        RiskOption('occasional_current', 'Occasional, current', score: 2),
        RiskOption('regular_current', 'Regular, current', score: 3),
      ],
    ),
    RiskVariable(
      key: RiskKeys.gutkha,
      label: 'Gutkha / pan masala',
      role: RiskVariableRole.exposureOnly,
      note:
          'Exposure is recorded. Final weight is still to be validated, so '
          'this answer does not change the score in this pilot build.',
      options: [
        RiskOption('no', 'No', unweighted: true),
        RiskOption('past', 'Past', unweighted: true),
        RiskOption('current', 'Current', unweighted: true),
      ],
    ),
    RiskVariable(
      key: RiskKeys.exposureDuration,
      label: 'Duration of tobacco / areca exposure',
      requiresExposure: true,
      options: [
        RiskOption('lt_5y', 'Less than 5 years', score: 0),
        RiskOption('5_10y', '5 to 10 years', score: 1),
        RiskOption('gt_10y', 'More than 10 years', score: 2),
      ],
    ),
    RiskVariable(
      key: RiskKeys.useFrequency,
      label: 'Frequency of use',
      requiresExposure: true,
      options: [
        RiskOption('occasional', 'Occasional', score: 0),
        RiskOption('once_daily', 'Once daily', score: 1),
        RiskOption('several_daily', 'Several times daily', score: 2),
      ],
    ),
    RiskVariable(
      key: RiskKeys.alcohol,
      label: 'Alcohol',
      options: [
        RiskOption('none', 'None', score: 0),
        RiskOption('occasional', 'Occasional', score: 1),
        RiskOption('regular', 'Regular', score: 2),
      ],
    ),
    RiskVariable(
      key: RiskKeys.previousOpmd,
      label: 'Previous oral potentially malignant disorder (OPMD)',
      note:
          'A "Don\'t know" answer is kept as unknown rather than scored as '
          'zero, so the record stays auditable.',
      options: [
        RiskOption(AnswerValues.no, 'No', score: 0),
        RiskOption(AnswerValues.yes, 'Yes', score: 4),
        RiskOption(AnswerValues.dontKnow, 'Don\'t know', unknown: true),
      ],
    ),
    RiskVariable(
      key: RiskKeys.previousOscc,
      label: 'Previous oral cancer (OSCC)',
      note:
          'A "Yes" answer means professional follow-up is advised '
          'irrespective of the score.',
      options: [
        RiskOption(AnswerValues.no, 'No', score: 0),
        RiskOption(AnswerValues.yes, 'Yes', score: 5),
      ],
    ),
    RiskVariable(
      key: RiskKeys.suspiciousLesion,
      label: 'Do you have a suspicious oral lesion or symptom right now?',
      role: RiskVariableRole.redFlagGate,
      note: 'A "Yes" answer opens the red-flag safety checklist.',
      options: [
        RiskOption(AnswerValues.no, 'No'),
        RiskOption(AnswerValues.yes, 'Yes'),
      ],
    ),
    RiskVariable(
      key: RiskKeys.lesionDuration,
      label: 'How long has it been present?',
      role: RiskVariableRole.referralTrigger,
      note: 'Two weeks or longer is a referral trigger.',
      options: [
        RiskOption(AnswerValues.lessThanTwoWeeks, 'Less than 2 weeks'),
        RiskOption(AnswerValues.twoWeeksOrMore, '2 weeks or longer'),
      ],
    ),
    RiskVariable(
      key: RiskKeys.neckLump,
      label: 'New or persistent lump in the neck',
      role: RiskVariableRole.referralTrigger,
      note: 'A referral trigger when persistent or suspicious.',
      options: [
        RiskOption(AnswerValues.no, 'No'),
        RiskOption(AnswerValues.yes, 'Yes'),
      ],
    ),
  ];

  /// Variables that carry tobacco / areca / gutkha exposure. Used to decide
  /// whether the duration and frequency questions apply.
  static const List<String> exposureVariableKeys = [
    RiskKeys.smoking,
    RiskKeys.smokelessTobacco,
    RiskKeys.areca,
    RiskKeys.gutkha,
  ];

  /// Option values that mean "no exposure at all" for the keys above.
  static const Set<String> noExposureValues = {'never', 'no'};

  static RiskVariable variableFor(String key) =>
      variables.firstWhere((v) => v.key == key);

  /// Questions the patient actually answers (age band is derived).
  static List<RiskVariable> get askedVariables =>
      variables.where((v) => !v.derived).toList(growable: false);

  /// Highest total reachable from the scored variables. Useful for progress
  /// display and for sanity-checking the cut-offs during validation.
  static int get maxPossibleScore {
    var total = 0;
    for (final variable in variables) {
      if (variable.role != RiskVariableRole.scored) continue;
      final best = variable.options
          .map((o) => o.unknown ? 0 : o.score)
          .fold<int>(0, (a, b) => a > b ? a : b);
      total += best;
    }
    return total;
  }
}

/// One item of the red-flag safety checklist (spec section 2.3).
class RedFlag {
  const RedFlag(this.key, this.label);
  final String key;
  final String label;
}

/// The ten red-flag questions, in spec order.
class RedFlagCatalog {
  const RedFlagCatalog._();

  static const List<RedFlag> items = [
    RedFlag('non_healing_ulcer', 'Non-healing ulcer or sore'),
    RedFlag('red_patch', 'Red patch'),
    RedFlag('white_patch', 'White patch'),
    RedFlag('red_and_white_patch', 'Red-and-white patch'),
    RedFlag('lump_thickening', 'Lump or thickening'),
    RedFlag('unexplained_bleeding', 'Unexplained bleeding'),
    RedFlag('persistent_numbness', 'Persistent numbness'),
    RedFlag('difficulty_swallowing', 'Difficulty swallowing'),
    RedFlag('restricted_movement', 'Restricted tongue or jaw movement'),
    RedFlag('persistent_neck_lump', 'Persistent neck lump'),
  ];

  static String labelFor(String key) => items
      .firstWhere((item) => item.key == key, orElse: () => RedFlag(key, key))
      .label;
}

/// One site of the guided mouth self-examination (spec Table 5).
class ExamSite {
  const ExamSite(this.key, this.label, this.instruction);
  final String key;
  final String label;
  final String instruction;
}

class ExamSiteCatalog {
  const ExamSiteCatalog._();

  static const List<ExamSite> sites = [
    ExamSite('lips', 'Lips', 'Look for a sore, patch or lump on both lips.'),
    ExamSite('inner_cheeks', 'Inner cheeks', 'Inspect both cheeks.'),
    ExamSite('gums', 'Gums', 'Look for any patch or swelling.'),
    ExamSite('tongue', 'Tongue', 'Inspect the top, both sides and underside.'),
    ExamSite('floor_of_mouth', 'Floor of mouth', 'Inspect under the tongue.'),
    ExamSite('palate', 'Palate', 'Inspect the roof of the mouth.'),
    ExamSite('neck', 'Neck', 'Feel for any new lump.'),
  ];

  static String labelFor(String key) => sites
      .firstWhere((s) => s.key == key, orElse: () => ExamSite(key, key, ''))
      .label;
}

/// Lesion sites offered in the lesion-recording dropdown (spec Table 6).
class LesionSites {
  const LesionSites._();

  static const List<String> values = [
    'Lip',
    'Inner cheek (buccal mucosa)',
    'Gum (gingiva)',
    'Tongue — top surface',
    'Tongue — lateral border',
    'Tongue — underside',
    'Floor of mouth',
    'Palate',
    'Retromolar area',
    'Neck',
    'Other',
  ];
}
