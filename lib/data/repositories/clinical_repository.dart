import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firestore_refs.dart';
import '../models/app_user.dart';
import '../models/assessment_models.dart';
import '../models/clinical_models.dart';
import '../models/patient_case.dart';

/// Doctor-side reads and writes, backed by Firestore.
///
/// Every read is restricted to assessments the patient addressed to *this*
/// clinician (`shared_with_uid == my uid`) AND re-checks the patient's live
/// share consent. A record sent to a different clinician, never shared, or
/// withdrawn is never returned (spec Table 1: "Consent to share with doctor —
/// enable/disable doctor access").
///
/// The Firestore security rules enforce the same gate on the server; this class
/// is the client-side counterpart.
class ClinicalRepository {
  ClinicalRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  /// This clinician's queue: records addressed to them, referral alerts first,
  /// then most recent.
  Future<List<PatientCase>> queue({bool onlyUnreviewed = false}) async {
    final uid = _uid;
    if (uid == null) return const [];

    // Both filters are required, not just the recipient. Firestore rules are
    // not filters: a query is rejected outright unless it provably returns only
    // documents the rules allow, and the read rule requires
    // shared_with_doctor == 1 as well as shared_with_uid == my uid.
    final query = await FirestoreRefs.assessments()
        .where('shared_with_doctor', isEqualTo: 1)
        .where('shared_with_uid', isEqualTo: uid)
        .get();

    final cases = <PatientCase>[];
    for (final doc in query.docs) {
      final assessment = _assessmentFromDoc(doc);
      final built = await _buildCase(
        assessment,
        ownerUid: doc.data()['owner_uid'] as String?,
      );
      if (built == null) continue;
      if (onlyUnreviewed && built.isReviewed) continue;
      cases.add(built);
    }

    // Sort in memory to avoid requiring a composite Firestore index.
    cases.sort((a, b) {
      final priority = a.queuePriority.compareTo(b.queuePriority);
      if (priority != 0) return priority;
      return b.assessment.createdAt.compareTo(a.assessment.createdAt);
    });

    return cases;
  }

  Future<PatientCase?> caseForAssessment(int assessmentId) async {
    final snapshot = await FirestoreRefs.assessment(assessmentId).get();
    if (!snapshot.exists) return null;
    final assessment = _assessmentFromSnapshot(snapshot);
    // Only the clinician the patient addressed the record to may open it.
    if (!assessment.isSharedWithSomeone) return null;
    if (assessment.sharedWithUid != _uid) return null;
    return _buildCase(
      assessment,
      ownerUid: snapshot.data()?['owner_uid'] as String?,
    );
  }

  /// Every consented case, for the validation screen (spec section 4).
  Future<List<PatientCase>> allSharedCases() => queue();

  /// Every shared record in the pilot, for cohort-wide validation.
  ///
  /// Only a coordinator can read this: the rules allow it on the coordinator
  /// claim alone, and the `shared_with_doctor` filter is required both because
  /// rules are not filters and because a record the patient never shared must
  /// stay out of the statistics entirely.
  Future<List<PatientCase>> cohortCases() async {
    final query = await FirestoreRefs.assessments()
        .where('shared_with_doctor', isEqualTo: 1)
        .get();

    final cases = <PatientCase>[];
    for (final doc in query.docs) {
      final assessment = _assessmentFromDoc(doc);
      final built = await _buildCase(
        assessment,
        ownerUid: doc.data()['owner_uid'] as String?,
      );
      if (built == null) continue;
      cases.add(built);
    }

    cases.sort(
      (a, b) => b.assessment.createdAt.compareTo(a.assessment.createdAt),
    );
    return cases;
  }

  Future<void> saveClinicianAssessment(ClinicianAssessmentRecord record) async {
    await FirestoreRefs.clinical(
      record.assessmentId,
    ).set(record.toRow()..remove('id'));
  }

  Future<void> saveOutcome(OutcomeRecord record) async {
    await FirestoreRefs.outcome(
      record.assessmentId,
    ).set(record.toRow()..remove('id'));
  }

  Future<ClinicianAssessmentRecord?> clinicianAssessmentFor(
    int assessmentId,
  ) async {
    final snapshot = await FirestoreRefs.clinical(assessmentId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return ClinicianAssessmentRecord.fromRow(Map<String, Object?>.from(data));
  }

  Future<OutcomeRecord?> outcomeFor(int assessmentId) async {
    final snapshot = await FirestoreRefs.outcome(assessmentId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return OutcomeRecord.fromRow(Map<String, Object?>.from(data));
  }

  // ---------------------------------------------------------------------------

  Future<PatientCase?> _buildCase(
    RiskAssessmentRecord assessment, {
    String? ownerUid,
  }) async {
    final id = assessment.id;
    if (id == null) return null;

    final patient = await _patientFor(assessment.patientId, ownerUid: ownerUid);
    if (patient == null) return null;

    // Re-check share consent against the live user record, so a withdrawn
    // consent removes the case even if an older assessment still carries the
    // shared flag.
    if (!patient.consent.shareWithDoctor) return null;

    final assessmentSnapshot = await FirestoreRefs.assessment(id).get();
    SelfExaminationRecord? selfExam;
    final selfExamRaw = assessmentSnapshot.data()?[FirestoreRefs.selfExamField];
    if (selfExamRaw is Map) {
      selfExam = SelfExaminationRecord.fromRow(
        Map<String, Object?>.from(selfExamRaw),
      );
    }

    final lesionsSnapshot = await FirestoreRefs.lesions(id).get();
    final lesions = lesionsSnapshot.docs.map((doc) {
      final data = Map<String, Object?>.from(doc.data());
      data['id'] = int.tryParse(doc.id);
      return LesionRecord.fromRow(data);
    }).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return PatientCase(
      patient: patient,
      assessment: assessment,
      selfExamination: selfExam,
      lesions: lesions,
      clinicianAssessment: await clinicianAssessmentFor(id),
      outcome: await outcomeFor(id),
    );
  }

  /// Loads the patient's profile.
  ///
  /// Prefers a direct document read by [ownerUid], which the assessment already
  /// carries: a single-document read is unambiguously permitted by the rules and
  /// avoids a collection query over `users`. Falls back to the Patient_ID query
  /// for records written before `owner_uid` was stored.
  Future<AppUser?> _patientFor(String patientId, {String? ownerUid}) async {
    if (ownerUid != null && ownerUid.isNotEmpty) {
      final snapshot = await FirestoreRefs.user(ownerUid).get();
      final data = snapshot.data();
      if (snapshot.exists && data != null) {
        return AppUser.fromFirestore(snapshot.id, data);
      }
    }

    final query = await FirestoreRefs.users()
        .where('patient_id', isEqualTo: patientId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return AppUser.fromFirestore(doc.id, doc.data());
  }

  RiskAssessmentRecord _assessmentFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = Map<String, Object?>.from(doc.data());
    data['id'] = int.tryParse(doc.id);
    return RiskAssessmentRecord.fromRow(data);
  }

  RiskAssessmentRecord _assessmentFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = Map<String, Object?>.from(snapshot.data() ?? {});
    data['id'] = int.tryParse(snapshot.id);
    return RiskAssessmentRecord.fromRow(data);
  }
}
