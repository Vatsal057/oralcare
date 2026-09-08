/// A clinician as shown to a patient in the "send to" picker.
///
/// This comes from the `doctors/{uid}` directory, which is written only by the
/// Admin SDK provisioning script. It deliberately carries no patient data and no
/// private contact details.
class DoctorSummary {
  const DoctorSummary({
    required this.uid,
    required this.username,
    this.fullName,
    this.clinic,
  });

  /// Firebase Auth uid. This is the value stored on a shared assessment, and
  /// the value the security rules compare against the reader's uid.
  final String uid;

  final String username;
  final String? fullName;

  /// Practice or centre name, so a patient can tell two clinicians apart.
  final String? clinic;

  String get displayName {
    final name = fullName?.trim();
    return (name == null || name.isEmpty) ? username : name;
  }

  /// Secondary line for the picker: clinic when known, otherwise the username.
  String? get subtitle {
    final place = clinic?.trim();
    if (place != null && place.isNotEmpty) return place;
    return displayName == username ? null : username;
  }

  factory DoctorSummary.fromFirestore(String uid, Map<String, Object?> data) =>
      DoctorSummary(
        uid: uid,
        username: data['username'] as String? ?? uid,
        fullName: data['full_name'] as String?,
        clinic: data['clinic'] as String?,
      );
}
