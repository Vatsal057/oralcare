/// Fixed clinical-safety wording used across the app.
///
/// These strings encode the clinical safety principle from spec section 7:
/// "The application supports awareness, early recognition and referral. It does
/// not diagnose or stage OSCC automatically."
///
/// Do not soften or remove these notices. They are the boundary between a
/// screening-awareness tool and an unregulated diagnostic claim.
class ClinicalNotices {
  const ClinicalNotices._();

  /// Shown on the patient result screen and the consent screen.
  static const String noDiagnosis =
      'This app does not diagnose cancer. It helps you notice changes early '
      'and tells you when to get checked by a dentist or doctor.';

  /// Shown wherever a score or category is displayed.
  static const String provisionalScores =
      'Scores and thresholds in this build are provisional for pilot '
      'development and have not yet been clinically validated.';

  /// Shown on the consent screen before anything else runs.
  static const String consentIntro =
      'Before you start, please read and agree to the following. You can '
      'change these choices at any time from your profile.';

  static const String consentAppDetail =
      'I agree to use this app for oral-health awareness and to carry out a '
      'guided self-examination of my own mouth.';

  static const String consentPhotoDetail =
      'I agree that I may take and store a photograph of a finding inside my '
      'mouth. Photographs stay on this device unless I also agree to share my '
      'record with a doctor.';

  static const String consentShareDetail =
      'I agree that a doctor using this app may see my record, including my '
      'answers, my self-examination findings and any photograph I have added.';

  /// Shown at the top of the doctor interface.
  static const String doctorResponsibility =
      'App output is decision support only. Clinical assessment, diagnosis and '
      'referral remain your professional responsibility.';

  /// Shown on the red-flag / professional-check output.
  static const String urgencyGuidance =
      'If you have heavy bleeding, cannot swallow, or cannot breathe properly, '
      'seek urgent medical care now rather than waiting for an appointment.';

  /// Shown on the validation screen.
  static const String validationCaveat =
      'These are raw counts from pilot data. They have no confidence '
      'intervals, no adjustment for verification bias, and no correction for '
      'repeated assessments on the same patient. Use them to monitor the '
      'pilot, not as validation evidence.';

  /// Shown where data storage is explained.
  static const String storageNotice =
      'Records are stored on this device only. Nothing is uploaded. Before any '
      'real-world deployment this must move to an authenticated, encrypted '
      'server with audit logging.';

  /// Prevention advice for the lower-risk output (spec Table 7).
  static const List<String> preventionAdvice = [
    'Avoid all forms of tobacco, including smokeless tobacco.',
    'Avoid areca nut, betel quid, gutkha and pan masala.',
    'Keep alcohol low, or avoid it.',
    'Check your own mouth once a month using the guided self-examination.',
    'Attend a routine dental or oral examination.',
  ];

  /// Cessation advice for the increased-risk output (spec Table 7).
  static const List<String> cessationAdvice = [
    'Stopping tobacco and areca nut is the single biggest thing that lowers '
        'your risk.',
    'Ask a dentist, doctor or a cessation service for help to stop.',
    'Reduce alcohol.',
    'Have a professional oral examination rather than relying on '
        'self-examination alone.',
  ];
}
