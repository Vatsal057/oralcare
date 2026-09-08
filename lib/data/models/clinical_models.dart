/// CLINICIAN_ASSESSMENT table row (spec Table 8 / Table 11).
///
/// Every Yes/No field is `bool?` so that "not yet answered" is distinct from
/// "No". A validation database that cannot tell those apart is not usable.
class ClinicianAssessmentRecord {
  const ClinicianAssessmentRecord({
    this.id,
    required this.assessmentId,
    required this.patientId,
    required this.doctorUsername,
    required this.updatedAt,
    this.examinationPerformed,
    this.lesionPresent,
    this.lesionDescription,
    this.lesionSizeMm,
    this.clinicalImpression,
    this.investigationRequired,
    this.biopsyRequired,
    this.referralRequired,
    this.referralCentre,
    this.referralDate,
    this.followUpDate,
    this.followUpStatus,
  });

  final int? id;

  /// Links to the patient's RISK_ASSESSMENT record.
  final int assessmentId;

  /// Primary linking key (spec section 6).
  final String patientId;

  final String doctorUsername;
  final DateTime updatedAt;

  /// "Clinical examination performed Yes/No"
  final bool? examinationPerformed;

  /// "Lesion present Yes/No"
  final bool? lesionPresent;

  /// "Lesion description and size"
  final String? lesionDescription;
  final double? lesionSizeMm;

  /// "Provisional clinical impression" — free text by design. The app must not
  /// auto-generate a diagnosis (spec section 7 clinical safety principle).
  final String? clinicalImpression;

  /// "Further investigation required Yes/No"
  final bool? investigationRequired;

  /// "Biopsy required Yes/No"
  final bool? biopsyRequired;

  /// "Referral required, centre and date"
  final bool? referralRequired;
  final String? referralCentre;
  final DateTime? referralDate;

  /// "Follow-up date/status"
  final DateTime? followUpDate;
  final String? followUpStatus;

  /// A record counts as reviewed once the clinician has stated whether an
  /// examination was performed.
  bool get isReviewed => examinationPerformed != null;

  ClinicianAssessmentRecord copyWith({
    int? id,
    DateTime? updatedAt,
    bool? examinationPerformed,
    bool? lesionPresent,
    String? lesionDescription,
    double? lesionSizeMm,
    String? clinicalImpression,
    bool? investigationRequired,
    bool? biopsyRequired,
    bool? referralRequired,
    String? referralCentre,
    DateTime? referralDate,
    DateTime? followUpDate,
    String? followUpStatus,
  }) => ClinicianAssessmentRecord(
    id: id ?? this.id,
    assessmentId: assessmentId,
    patientId: patientId,
    doctorUsername: doctorUsername,
    updatedAt: updatedAt ?? this.updatedAt,
    examinationPerformed: examinationPerformed ?? this.examinationPerformed,
    lesionPresent: lesionPresent ?? this.lesionPresent,
    lesionDescription: lesionDescription ?? this.lesionDescription,
    lesionSizeMm: lesionSizeMm ?? this.lesionSizeMm,
    clinicalImpression: clinicalImpression ?? this.clinicalImpression,
    investigationRequired: investigationRequired ?? this.investigationRequired,
    biopsyRequired: biopsyRequired ?? this.biopsyRequired,
    referralRequired: referralRequired ?? this.referralRequired,
    referralCentre: referralCentre ?? this.referralCentre,
    referralDate: referralDate ?? this.referralDate,
    followUpDate: followUpDate ?? this.followUpDate,
    followUpStatus: followUpStatus ?? this.followUpStatus,
  );

  Map<String, Object?> toRow() => {
    if (id != null) 'id': id,
    'assessment_id': assessmentId,
    'patient_id': patientId,
    'doctor_username': doctorUsername,
    'updated_at': updatedAt.toIso8601String(),
    'examination_performed': _b(examinationPerformed),
    'lesion_present': _b(lesionPresent),
    'lesion_description': lesionDescription,
    'lesion_size_mm': lesionSizeMm,
    'clinical_impression': clinicalImpression,
    'investigation_required': _b(investigationRequired),
    'biopsy_required': _b(biopsyRequired),
    'referral_required': _b(referralRequired),
    'referral_centre': referralCentre,
    'referral_date': referralDate?.toIso8601String(),
    'follow_up_date': followUpDate?.toIso8601String(),
    'follow_up_status': followUpStatus,
  };

  factory ClinicianAssessmentRecord.fromRow(Map<String, Object?> row) =>
      ClinicianAssessmentRecord(
        id: row['id'] as int?,
        assessmentId: row['assessment_id'] as int,
        patientId: row['patient_id'] as String,
        doctorUsername: row['doctor_username'] as String? ?? '',
        updatedAt:
            DateTime.tryParse(row['updated_at'] as String? ?? '') ??
            DateTime.now(),
        examinationPerformed: _nb(row['examination_performed']),
        lesionPresent: _nb(row['lesion_present']),
        lesionDescription: row['lesion_description'] as String?,
        lesionSizeMm: (row['lesion_size_mm'] as num?)?.toDouble(),
        clinicalImpression: row['clinical_impression'] as String?,
        investigationRequired: _nb(row['investigation_required']),
        biopsyRequired: _nb(row['biopsy_required']),
        referralRequired: _nb(row['referral_required']),
        referralCentre: row['referral_centre'] as String?,
        referralDate: DateTime.tryParse(row['referral_date'] as String? ?? ''),
        followUpDate: DateTime.tryParse(row['follow_up_date'] as String? ?? ''),
        followUpStatus: row['follow_up_status'] as String?,
      );
}

/// OUTCOME table row (spec Table 9 / Table 11).
///
/// This is the reference standard used to validate the risk-stratification and
/// referral algorithm (spec section 4).
class OutcomeRecord {
  const OutcomeRecord({
    this.id,
    required this.assessmentId,
    required this.patientId,
    required this.doctorUsername,
    required this.updatedAt,
    this.professionalExamination,
    this.clinicalAbnormality,
    this.biopsyPerformed,
    this.histopathologyResult,
    this.finalDiagnosis,
    this.opmd,
    this.oscc,
    this.referralCompleted,
    this.followUpCompleted,
  });

  final int? id;
  final int assessmentId;
  final String patientId;
  final String doctorUsername;
  final DateTime updatedAt;

  /// Professional_examination
  final bool? professionalExamination;

  /// Clinical_abnormality
  final bool? clinicalAbnormality;

  /// Biopsy_performed
  final bool? biopsyPerformed;

  /// Histopathology_result — reference outcome where available.
  final String? histopathologyResult;

  /// Final_diagnosis — the clinical endpoint.
  final String? finalDiagnosis;

  /// OPMD, where established.
  final bool? opmd;

  /// OSCC, where established.
  final bool? oscc;

  final bool? referralCompleted;
  final bool? followUpCompleted;

  /// True once a reference outcome exists that validation can use.
  bool get hasReferenceOutcome =>
      opmd != null ||
      oscc != null ||
      (finalDiagnosis != null && finalDiagnosis!.trim().isNotEmpty) ||
      (histopathologyResult != null && histopathologyResult!.trim().isNotEmpty);

  /// The binary reference standard for validation: a disease-positive case is
  /// an established OPMD or OSCC.
  bool? get isDiseasePositive {
    if (oscc == null && opmd == null) return null;
    return (oscc ?? false) || (opmd ?? false);
  }

  OutcomeRecord copyWith({
    int? id,
    DateTime? updatedAt,
    bool? professionalExamination,
    bool? clinicalAbnormality,
    bool? biopsyPerformed,
    String? histopathologyResult,
    String? finalDiagnosis,
    bool? opmd,
    bool? oscc,
    bool? referralCompleted,
    bool? followUpCompleted,
  }) => OutcomeRecord(
    id: id ?? this.id,
    assessmentId: assessmentId,
    patientId: patientId,
    doctorUsername: doctorUsername,
    updatedAt: updatedAt ?? this.updatedAt,
    professionalExamination:
        professionalExamination ?? this.professionalExamination,
    clinicalAbnormality: clinicalAbnormality ?? this.clinicalAbnormality,
    biopsyPerformed: biopsyPerformed ?? this.biopsyPerformed,
    histopathologyResult: histopathologyResult ?? this.histopathologyResult,
    finalDiagnosis: finalDiagnosis ?? this.finalDiagnosis,
    opmd: opmd ?? this.opmd,
    oscc: oscc ?? this.oscc,
    referralCompleted: referralCompleted ?? this.referralCompleted,
    followUpCompleted: followUpCompleted ?? this.followUpCompleted,
  );

  Map<String, Object?> toRow() => {
    if (id != null) 'id': id,
    'assessment_id': assessmentId,
    'patient_id': patientId,
    'doctor_username': doctorUsername,
    'updated_at': updatedAt.toIso8601String(),
    'professional_examination': _b(professionalExamination),
    'clinical_abnormality': _b(clinicalAbnormality),
    'biopsy_performed': _b(biopsyPerformed),
    'histopathology_result': histopathologyResult,
    'final_diagnosis': finalDiagnosis,
    'opmd': _b(opmd),
    'oscc': _b(oscc),
    'referral_completed': _b(referralCompleted),
    'follow_up_completed': _b(followUpCompleted),
  };

  factory OutcomeRecord.fromRow(Map<String, Object?> row) => OutcomeRecord(
    id: row['id'] as int?,
    assessmentId: row['assessment_id'] as int,
    patientId: row['patient_id'] as String,
    doctorUsername: row['doctor_username'] as String? ?? '',
    updatedAt:
        DateTime.tryParse(row['updated_at'] as String? ?? '') ?? DateTime.now(),
    professionalExamination: _nb(row['professional_examination']),
    clinicalAbnormality: _nb(row['clinical_abnormality']),
    biopsyPerformed: _nb(row['biopsy_performed']),
    histopathologyResult: row['histopathology_result'] as String?,
    finalDiagnosis: row['final_diagnosis'] as String?,
    opmd: _nb(row['opmd']),
    oscc: _nb(row['oscc']),
    referralCompleted: _nb(row['referral_completed']),
    followUpCompleted: _nb(row['follow_up_completed']),
  );
}

/// Nullable bool to SQLite integer.
Object? _b(bool? value) => value == null ? null : (value ? 1 : 0);

/// SQLite integer to nullable bool.
bool? _nb(Object? value) => value == null ? null : (value as int) == 1;
