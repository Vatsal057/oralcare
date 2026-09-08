import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralised Firestore collection and document paths (spec Table 11).
///
/// Structure:
///   users/{uid}
///   assessments/{assessmentId}
///     assessments/{assessmentId}/lesions/{lesionId}
///     assessments/{assessmentId}/clinical/current
///     assessments/{assessmentId}/outcome/current
///
/// The self-examination is 1:1 with an assessment, so it is stored inline on
/// the assessment document rather than as its own collection.
class FirestoreRefs {
  FirestoreRefs._();

  static FirebaseFirestore get db => FirebaseFirestore.instance;

  static const String usersCollection = 'users';
  static const String patientIdsCollection = 'patient_ids';
  static const String doctorsCollection = 'doctors';
  static const String assessmentsCollection = 'assessments';
  static const String lesionsCollection = 'lesions';
  static const String clinicalCollection = 'clinical';
  static const String outcomeCollection = 'outcome';

  /// Single fixed id for the 1:1 clinical and outcome sub-documents.
  static const String singletonDoc = 'current';

  /// Field name for the inline self-examination.
  static const String selfExamField = 'self_exam';

  static CollectionReference<Map<String, dynamic>> users() =>
      db.collection(usersCollection);

  static DocumentReference<Map<String, dynamic>> user(String uid) =>
      users().doc(uid);

  /// Public clinician directory, so a patient can choose who to send a record
  /// to. Written only by the Admin SDK provisioning script; it holds no patient
  /// data and never any contact detail beyond what a clinician agrees to list.
  static CollectionReference<Map<String, dynamic>> doctors() =>
      db.collection(doctorsCollection);

  /// Uniqueness reservation for a human-readable Patient_ID.
  ///
  /// A patient cannot query the whole `users` collection (that would expose
  /// other people's profiles), so uniqueness is enforced by a document whose id
  /// *is* the Patient_ID. Creating it succeeds only when it does not exist.
  static DocumentReference<Map<String, dynamic>> patientIdReservation(
    String patientId,
  ) => db.collection(patientIdsCollection).doc(patientId);

  static CollectionReference<Map<String, dynamic>> assessments() =>
      db.collection(assessmentsCollection);

  static DocumentReference<Map<String, dynamic>> assessment(int id) =>
      assessments().doc(id.toString());

  static CollectionReference<Map<String, dynamic>> lesions(int assessmentId) =>
      assessment(assessmentId).collection(lesionsCollection);

  static DocumentReference<Map<String, dynamic>> clinical(int assessmentId) =>
      assessment(assessmentId).collection(clinicalCollection).doc(singletonDoc);

  static DocumentReference<Map<String, dynamic>> outcome(int assessmentId) =>
      assessment(assessmentId).collection(outcomeCollection).doc(singletonDoc);
}
