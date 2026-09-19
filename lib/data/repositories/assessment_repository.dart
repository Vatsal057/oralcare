import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firestore_refs.dart';
import '../models/assessment_models.dart';

/// Patient-side writes and reads: RISK_ASSESSMENT, SELF_EXAMINATION and LESION
/// (spec Table 11), backed by Firestore.
///
/// Every assessment document carries `owner_uid` so the security rules can
/// restrict a patient to their own records.
class AssessmentRepository {
  AssessmentRepository({FirebaseAuth? auth})
    : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  String? get _uid => _auth.currentUser?.uid;

  /// Generates a monotonic, collision-resistant integer id used as the
  /// Firestore document key. Microsecond precision keeps ids unique per device;
  /// a cross-device clash on the same microsecond is astronomically unlikely at
  /// pilot volumes.
  int _newId() => DateTime.now().microsecondsSinceEpoch;

  Future<int> saveAssessment(RiskAssessmentRecord record) async {
    final id = record.id ?? _newId();
    final data = record.toRow()
      ..remove('id')
      ..['owner_uid'] = _uid;
    await FirestoreRefs.assessment(id).set(data);
    return id;
  }

  Future<void> updateAssessment(RiskAssessmentRecord record) async {
    final id = record.id;
    if (id == null) return;
    final data = record.toRow()
      ..remove('id')
      ..['owner_uid'] = _uid;
    await FirestoreRefs.assessment(id).set(data);
  }

  /// Stores the self-examination inline on the assessment document (it is 1:1).
  Future<void> saveSelfExamination(SelfExaminationRecord record) async {
    final assessmentId = record.assessmentId;
    if (assessmentId == null) return;
    await FirestoreRefs.assessment(assessmentId).set({
      FirestoreRefs.selfExamField: (record.toRow()..remove('id')),
    }, SetOptions(merge: true));
  }

  Future<int> saveLesion(LesionRecord record) async {
    final assessmentId = record.assessmentId;
    final id = record.id ?? _newId();
    if (assessmentId == null) return id;
    await FirestoreRefs.lesions(
      assessmentId,
    ).doc(id.toString()).set(record.toRow()..remove('id'));
    return id;
  }

  /// Share-with-doctor consent gate (spec Table 1), addressed to one clinician.
  ///
  /// [doctorUid] is the clinician the patient chose. Sharing without a
  /// recipient is meaningless, so switching sharing off also clears the
  /// recipient: the record stops being readable by that clinician immediately.
  Future<void> setSharing({
    required int assessmentId,
    required bool shared,
    String? doctorUid,
  }) async {
    final addressed = shared && (doctorUid?.isNotEmpty ?? false);
    await FirestoreRefs.assessment(assessmentId).update({
      'shared_with_doctor': addressed ? 1 : 0,
      'shared_with_uid': addressed ? doctorUid : null,
    });
  }

  /// The signed-in patient's uid.
  String? get currentUid => _uid;

  /// Flags a saved lesion as having its photograph stored in Firestore.
  ///
  /// The flag is what the clinician's screens read to decide whether to fetch
  /// the image document at all, so it is written only after the bytes land.
  Future<void> markLesionPhotoStored({
    required int assessmentId,
    required int lesionId,
    bool stored = true,
  }) async {
    await FirestoreRefs.lesions(
      assessmentId,
    ).doc(lesionId.toString()).update({'photo_in_database': stored ? 1 : 0});
  }

  Future<void> setFollowUp({
    required int assessmentId,
    DateTime? due,
    required FollowUpStatus status,
  }) async {
    await FirestoreRefs.assessment(assessmentId).update({
      'follow_up_due': due?.toIso8601String(),
      'follow_up_status': status.storageValue,
    });
  }

  Future<List<RiskAssessmentRecord>> assessmentsForPatient(
    String patientId,
  ) async {
    final query = await FirestoreRefs.assessments()
        .where('patient_id', isEqualTo: patientId)
        .get();
    final records = query.docs.map(_recordFromDoc).toList();
    records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return records;
  }

  Future<RiskAssessmentRecord?> latestForPatient(String patientId) async {
    final all = await assessmentsForPatient(patientId);
    return all.isEmpty ? null : all.first;
  }

  Future<SelfExaminationRecord?> selfExaminationFor(int assessmentId) async {
    final snapshot = await FirestoreRefs.assessment(assessmentId).get();
    final data = snapshot.data();
    final raw = data?[FirestoreRefs.selfExamField];
    if (raw is! Map) return null;
    return SelfExaminationRecord.fromRow(Map<String, Object?>.from(raw));
  }

  Future<List<LesionRecord>> lesionsFor(int assessmentId) async {
    final query = await FirestoreRefs.lesions(assessmentId).get();
    final lesions = query.docs.map((doc) {
      final data = Map<String, Object?>.from(doc.data());
      data['id'] = int.tryParse(doc.id);
      return LesionRecord.fromRow(data);
    }).toList();
    lesions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return lesions;
  }

  /// Assessments where the patient still has an open follow-up, used to drive
  /// the reminder card on the patient home screen.
  Future<List<RiskAssessmentRecord>> pendingFollowUps(String patientId) async {
    final all = await assessmentsForPatient(patientId);
    return all
        .where((a) => a.followUpStatus == FollowUpStatus.pending)
        .toList(growable: false);
  }

  RiskAssessmentRecord _recordFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = Map<String, Object?>.from(doc.data());
    data['id'] = int.tryParse(doc.id);
    return RiskAssessmentRecord.fromRow(data);
  }
}
