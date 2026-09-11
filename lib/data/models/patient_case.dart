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

  /// Referred, but the two-week attendance window has passed with no arrival
  /// (spec section 5).
  bool failedToAttend({DateTime? now}) =>
      clinicianAssessment?.failedToArriveWithinTwoWeeks(now: now) ?? false;

  /// A non-attendance nobody has chased yet. This is the state that needs a
  /// human to act, so the queue surfaces it.
  bool needsAttendanceChase({DateTime? now}) =>
      clinicianAssessment?.needsAttendanceReminder(now: now) ?? false;

  /// Queue priority: unchased non-attendance first, because a referred patient
  /// who never arrived is the most likely to be lost to follow-up. Then app
  /// overrides, then referral alerts, then the rest.
  int get queuePriority {
    if (needsAttendanceChase()) return 0;
    if (assessment.result.professionalCheckRequired) return 1;
    if (assessment.result.referralAlert) return 2;
    return 3;
  }

  /// What the app recommended: did it flag this person for professional care?
  ///
  /// Used as the "test positive" arm when comparing app output against the
  /// clinical outcome (spec section 4).
  bool get appFlaggedForProfessionalCare =>
      assessment.result.professionalCheckRequired ||
      assessment.result.referralAlert;
}
