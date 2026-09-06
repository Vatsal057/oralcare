import 'app_user.dart';
import 'assessment_models.dart';
import 'clinical_models.dart';

/// The joined view of one assessment across every table, linked by Patient_ID
/// (spec section 6: "Primary linking key: Patient_ID").
///
/// This is what the doctor reviews and what the validation screen consumes.
class PatientCase {
  const PatientCase({
    required this.patient,
    required this.assessment,
    this.selfExamination,
    this.lesions = const [],
    this.clinicianAssessment,
    this.outcome,
  });

  final AppUser patient;
  final RiskAssessmentRecord assessment;
  final SelfExaminationRecord? selfExamination;
  final List<LesionRecord> lesions;
  final ClinicianAssessmentRecord? clinicianAssessment;
  final OutcomeRecord? outcome;

  String get patientId => assessment.patientId;

  /// The doctor may only see a photograph when photograph consent was granted.
  /// Consent is re-checked here rather than trusted from the record alone.
  bool get photoViewingAllowed => patient.consent.photograph;

  List<LesionRecord> get viewableLesions => lesions
      .map((l) => photoViewingAllowed ? l : l.copyWith(photoPath: ''))
      .toList(growable: false);

  bool get isReviewed => clinicianAssessment?.isReviewed ?? false;

  bool get hasReferenceOutcome => outcome?.hasReferenceOutcome ?? false;

  /// Queue priority: overrides first, then higher risk, then the rest.
  int get queuePriority {
    if (assessment.result.professionalCheckRequired) return 0;
    if (assessment.result.referralAlert) return 1;
    return 2;
  }

  /// What the app recommended: did it flag this person for professional care?
  ///
  /// Used as the "test positive" arm when comparing app output against the
  /// clinical outcome (spec section 4).
  bool get appFlaggedForProfessionalCare =>
      assessment.result.professionalCheckRequired ||
      assessment.result.referralAlert;
}
