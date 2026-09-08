import '../firestore_refs.dart';
import '../models/doctor_summary.dart';

/// Reads the clinician directory a patient chooses from.
///
/// The directory is a separate collection from `users` on purpose: patients must
/// be able to list clinicians without being able to read clinician or patient
/// profile documents.
class DoctorDirectoryRepository {
  const DoctorDirectoryRepository();

  Future<List<DoctorSummary>> all() async {
    final query = await FirestoreRefs.doctors().get();
    final doctors = query.docs
        .map((doc) => DoctorSummary.fromFirestore(doc.id, doc.data()))
        .toList();
    doctors.sort(
      (a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );
    return doctors;
  }

  Future<DoctorSummary?> byUid(String uid) async {
    final snapshot = await FirestoreRefs.doctors().doc(uid).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return DoctorSummary.fromFirestore(snapshot.id, data);
  }
}
