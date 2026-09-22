/// Patient-facing clinical vocabulary in English and Kannada.
///
/// SOURCE OF THE KANNADA WORDING: "Oral Cancer: Illustration Based
/// Questionnaire / ಬಾಯಿಯ ಕ್ಯಾನ್ಸರ್: ಸಚಿತ್ರ ಆಧಾರಿತ ಪ್ರಶ್ನಾವಳಿ ಸಮೀಕ್ಷೆ" supplied by the
/// clinical team. Every term below is taken from that document rather than
/// translated here, because an invented wording for a cancer symptom could make
/// a patient answer the wrong question.
///
/// Hindi is deliberately absent. The questionnaire is English/Kannada only, so
/// there is no verified Hindi source for these terms; the education module keeps
/// its existing Hindi content, and Hindi for clinical questions needs a native
/// clinical reviewer before it is shown to anyone.
library;

enum AppLocale { english, kannada }

extension AppLocaleX on AppLocale {
  /// Shown in the language switcher, in the language itself.
  String get label => switch (this) {
    AppLocale.english => 'English',
    AppLocale.kannada => 'ಕನ್ನಡ',
  };

  String get code => switch (this) {
    AppLocale.english => 'en',
    AppLocale.kannada => 'kn',
  };

  static AppLocale fromCode(String? code) =>
      code == 'kn' ? AppLocale.kannada : AppLocale.english;
}

/// A term with its verified Kannada equivalent.
class Term {
  const Term(this.en, this.kn);

  final String en;
  final String kn;

  String call(AppLocale locale) => locale == AppLocale.kannada ? kn : en;

  /// Both languages together, for a bilingual reading where showing one term
  /// alone could be ambiguous.
  String get bilingual => '$en / $kn';
}

class ClinicalTerms {
  const ClinicalTerms._();

  // ---- answers ------------------------------------------------------------
  static const yes = Term('Yes', 'ಹೌದು');
  static const no = Term('No', 'ಇಲ್ಲ');
  static const dontKnow = Term('Don\'t know', 'ಗೊತ್ತಿಲ್ಲ');
  static const agree = Term('Agree', 'ಒಪ್ಪುತ್ತೇನೆ');
  static const disagree = Term('Disagree', 'ಒಪ್ಪುವುದಿಲ್ಲ');

  // ---- demographics -------------------------------------------------------
  static const gender = Term('Gender', 'ಲಿಂಗ');
  static const age = Term('Age', 'ವಯಸ್ಸು');

  /// Gender options exactly as the questionnaire offers them.
  static const genderOptions = <Term>[
    Term('Male', 'ಪುರುಷ'),
    Term('Female', 'ಮಹಿಳೆ'),
    Term('Transgender', 'ನಪುಂಸಕ'),
  ];

  /// What the registration and profile forms offer.
  ///
  /// The questionnaire's three options, plus "Prefer not to say" so the field
  /// can be mandatory without forcing a disclosure.
  static const List<String> genderFormOptions = [
    'Male',
    'Female',
    'Transgender',
    'Prefer not to say',
  ];

  // ---- habits --------------------------------------------------------------
  static const smoking = Term('Smoking', 'ಧೂಮಪಾನ');
  static const smokelessTobacco = Term(
    'Smokeless tobacco / pan chewing',
    'ಹೊಗೆರಹಿತ ತಂಬಾಕು / ಪಾನ್ ಸೇವನೆ',
  );
  static const areca = Term('Betel leaf and areca nut', 'ಎಲೆ ಅಡಿಕೆ ಸೇವನೆ');
  static const alcohol = Term('Alcohol', 'ಮದ್ಯಪಾನ');
  static const familyHistory = Term(
    'Family history of cancer',
    'ಅನುವಂಶೀಯ ಖಾಯಿಲೆ',
  );

  // ---- sites ---------------------------------------------------------------
  static const mouth = Term('Mouth', 'ಬಾಯಿ');
  static const throat = Term('Throat', 'ಗಂಟಲು');

  /// Self-examination sites, keyed to [ExamSiteCatalog] keys.
  static const examSites = <String, Term>{
    'lips': Term('Lips', 'ತುಟಿಗಳು'),
    'inner_cheeks': Term('Inner cheeks', 'ಕೆನ್ನೆಯ ಒಳಭಾಗ'),
    'gums': Term('Gums', 'ಒಸಡುಗಳು'),
    'tongue': Term('Tongue', 'ನಾಲಿಗೆ'),
    'floor_of_mouth': Term('Floor of mouth', 'ನಾಲಿಗೆಯ ಕೆಳಭಾಗ'),
    'palate': Term('Palate', 'ಬಾಯಿಯ ಮೇಲ್ಭಾಗ'),
    'throat': Term('Back of the throat', 'ಗಂಟಲಿನ ಹಿಂಭಾಗ'),
    'neck': Term('Neck', 'ಕುತ್ತಿಗೆ'),
  };

  // ---- red flags -----------------------------------------------------------
  /// Keyed to [RedFlagCatalog] keys. The Kannada comes from section 3 of the
  /// questionnaire, which lists exactly these findings.
  static const redFlags = <String, Term>{
    'non_healing_ulcer': Term(
      'Non-healing ulcer or sore',
      'ವಾಸಿಯಾಗದ ಗಾಯ ಅಥವಾ ಹುಣ್ಣು',
    ),
    'red_patch': Term('Red patch', 'ಕೆಂಪು ಮಚ್ಚೆ'),
    'white_patch': Term('White patch', 'ಬಿಳಿ ಮಚ್ಚೆ'),
    'red_and_white_patch': Term(
      'Red-and-white patch',
      'ಕೆಂಪು ಮತ್ತು ಬಿಳಿ ಮಚ್ಚೆ',
    ),
    'lump_thickening': Term('Lump or thickening', 'ದುರ್ಮಾಂಸದ ಬೆಳವಣಿಗೆ'),
    'unexplained_bleeding': Term(
      'Unexplained bleeding',
      'ಒಸಡುಗಳಲ್ಲಿ ರಕ್ತಸ್ರಾವ',
    ),
    'persistent_numbness': Term('Persistent numbness', 'ನಿರಂತರ ಮರಗಟ್ಟುವಿಕೆ'),
    'difficulty_swallowing': Term('Difficulty swallowing', 'ನುಂಗಲು ತೊಂದರೆ'),
    'restricted_movement': Term(
      'Restricted tongue or jaw movement',
      'ಬಾಯಿಯ ಕಡಿಮೆ ತೆರೆಯುವಿಕೆ',
    ),
    'persistent_neck_lump': Term(
      'Persistent neck lump',
      'ಕುತ್ತಿಗೆಯಲ್ಲಿ ನಿರಂತರ ಗಂಟು',
    ),
    'loose_teeth': Term(
      'Teeth loosening without an obvious cause',
      'ಹಠಾತ್ ಸಡಿಲವಾದ ಹಲ್ಲುಗಳು',
    ),
    'difficulty_speaking': Term('Difficulty speaking', 'ಮಾತನಾಡಲು ತೊಂದರೆ'),
    'unexplained_weight_loss': Term(
      'Unexplained weight loss',
      'ಕಾರಣವಿಲ್ಲದ ತೂಕ ಇಳಿಕೆ',
    ),
  };

  // ---- advice --------------------------------------------------------------
  static const seeDentist = Term(
    'See a dentist if a mouth ulcer lasts more than three weeks',
    'ಬಾಯಿಯ ಹುಣ್ಣು ಮೂರು ವಾರಗಳಿಗಿಂತ ಹೆಚ್ಚು ಕಾಲ ಇದ್ದರೆ ದಂತವೈದ್ಯರನ್ನು ಕಾಣಬೇಕು',
  );
  static const dentist = Term('Dentist', 'ದಂತವೈದ್ಯರು');
  static const oncologist = Term('Cancer specialist', 'ಕ್ಯಾನ್ಸರ್ ತಜ್ಞರು');
  static const earlyDetection = Term(
    'Oral cancer can be found at an early stage',
    'ಬಾಯಿಯ ಕ್ಯಾನ್ಸರ್ ಅನ್ನು ಪ್ರಾಥಮಿಕ ಹಂತದಲ್ಲಿ ಕಂಡುಹಿಡಿಯಬಹುದು',
  );
  static const preventionPossible = Term(
    'Oral cancer can be prevented',
    'ಬಾಯಿಯ ಕ್ಯಾನ್ಸರ್ ರೋಗವನ್ನು ತಡೆಗಟ್ಟಲು ಸಾಧ್ಯ',
  );
  static const treatmentPossible = Term(
    'Oral cancer can be treated',
    'ಬಾಯಿಯ ಕ್ಯಾನ್ಸರ್ ರೋಗಕ್ಕೆ ಚಿಕಿತ್ಸೆ ಇದೆ',
  );
  static const delayWorsens = Term(
    'Delaying treatment makes oral cancer worse',
    'ಚಿಕಿತ್ಸೆಯಲ್ಲಿನ ವಿಳಂಬವು ಬಾಯಿಯ ಕ್ಯಾನ್ಸರ್ ಉಲ್ಬಣಗೊಳ್ಳಲು ಕಾರಣವಾಗುತ್ತದೆ',
  );
  static const notContagious = Term(
    'Cancer is not contagious',
    'ಕ್ಯಾನ್ಸರ್ ಸಾಂಕ್ರಾಮಿಕ ರೋಗವಲ್ಲ',
  );
  static const selfExamHelps = Term(
    'Self-examination helps find oral cancer early',
    'ಬಾಯಿಯ ಸ್ವಯಂ ಪರೀಕ್ಷೆಯಿಂದ ಬಾಯಿಯ ಕ್ಯಾನ್ಸರ್ ರೋಗವನ್ನು ಕಂಡುಹಿಡಿಯಲು ಸಾಧ್ಯ',
  );
  static const regularCheckUp = Term(
    'Regular check-ups are needed to find oral cancer',
    'ಬಾಯಿಯ ಕ್ಯಾನ್ಸರ್ ಪತ್ತೆಗೆ ನಿಯಮಿತ ತಪಾಸಣೆ ಅಗತ್ಯ',
  );

  /// Risk-assessment questions, keyed to [RiskKeys].
  ///
  /// Only the habit questions appear here, because those are the ones the
  /// questionnaire supplies Kannada for. The remaining questions — previous
  /// OPMD/OSCC, gutkha, exposure duration and frequency, the lesion gate — stay
  /// in English on purpose: inventing Kannada for them would risk a patient
  /// answering a different question from the one being scored.
  static const riskQuestions = <String, Term>{
    'smoking': smoking,
    'smokeless_tobacco': smokelessTobacco,
    'areca_betel': areca,
    'alcohol': alcohol,
    'family_history': familyHistory,
  };

  /// Answer values shared across questions, keyed to [AnswerValues].
  static const answers = <String, Term>{
    'yes': yes,
    'no': no,
    'dont_know': dontKnow,
  };

  /// Label for a red-flag key, falling back to English when a term is missing.
  static String redFlag(String key, AppLocale locale, String fallback) =>
      redFlags[key]?.call(locale) ?? fallback;

  /// Label for an exam-site key, falling back to English.
  static String examSite(String key, AppLocale locale, String fallback) =>
      examSites[key]?.call(locale) ?? fallback;

  /// Label for a risk-assessment question, falling back to English.
  static String riskQuestion(String key, AppLocale locale, String fallback) =>
      riskQuestions[key]?.call(locale) ?? fallback;

  /// Label for an answer option, falling back to English.
  ///
  /// Options with no verified Kannada — "Never", "Former", "Current, regular"
  /// and so on — fall through to the English label rather than being guessed at.
  static String answerOption(String value, AppLocale locale, String fallback) =>
      answers[value]?.call(locale) ?? fallback;

  /// True when a term exists in the given locale, so a caller can decide whether
  /// to show a second line rather than repeating the same English twice.
  static bool hasTranslation(String? translated, String original) =>
      translated != null && translated != original;
}
