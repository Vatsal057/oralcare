/// Which authenticated interface a user belongs to.
///
/// Spec section 7: "two clearly separated authenticated interfaces".
enum UserRole { patient, doctor }

extension UserRoleX on UserRole {
  String get storageValue => this == UserRole.patient ? 'patient' : 'doctor';

  String get label => this == UserRole.patient ? 'Patient' : 'Doctor';

  static UserRole fromStorage(String? value) =>
      value == 'doctor' ? UserRole.doctor : UserRole.patient;
}

/// Consent gates from spec Table 1 (section 2.1). Each is a hard gate:
/// nothing downstream may proceed without the matching consent.
class ConsentFlags {
  const ConsentFlags({
    this.appAndSelfExam = false,
    this.photograph = false,
    this.shareWithDoctor = false,
  });

  /// "Consent for app/self-examination" — proceed only when true.
  final bool appAndSelfExam;

  /// "Consent for photograph" — enables/disables image upload.
  final bool photograph;

  /// "Consent to share with doctor" — enables/disables doctor access.
  final bool shareWithDoctor;

  ConsentFlags copyWith({
    bool? appAndSelfExam,
    bool? photograph,
    bool? shareWithDoctor,
  }) => ConsentFlags(
    appAndSelfExam: appAndSelfExam ?? this.appAndSelfExam,
    photograph: photograph ?? this.photograph,
    shareWithDoctor: shareWithDoctor ?? this.shareWithDoctor,
  );
}

/// A `users/{uid}` document (spec Table 11, USER).
///
/// Identity is the Firebase Authentication `uid`. Passwords are held by Firebase
/// Auth and never stored here.
class AppUser {
  const AppUser({
    required this.uid,
    required this.username,
    required this.role,
    this.patientId,
    this.fullName,
    this.age,
    this.sex,
    this.consent = const ConsentFlags(),
    required this.createdAt,
  });

  /// Firebase Auth uid — the account identity.
  final String uid;

  /// Login identifier chosen by the user.
  final String username;

  final UserRole role;

  /// Patient_ID — the primary linking key across every collection
  /// (spec section 6). `null` for doctor accounts.
  final String? patientId;

  final String? fullName;

  /// Demographic and risk variable (spec Table 1).
  final int? age;

  /// "Sex, where used" — optional by design.
  final String? sex;

  final ConsentFlags consent;
  final DateTime createdAt;

  bool get isPatient => role == UserRole.patient;
  bool get isDoctor => role == UserRole.doctor;

  /// Nothing in the patient flow may run without this.
  bool get canProceed => consent.appAndSelfExam;

  String get displayName =>
      (fullName != null && fullName!.trim().isNotEmpty) ? fullName! : username;

  AppUser copyWith({
    String? uid,
    String? username,
    UserRole? role,
    String? patientId,
    String? fullName,
    int? age,
    String? sex,
    ConsentFlags? consent,
    DateTime? createdAt,
  }) => AppUser(
    uid: uid ?? this.uid,
    username: username ?? this.username,
    role: role ?? this.role,
    patientId: patientId ?? this.patientId,
    fullName: fullName ?? this.fullName,
    age: age ?? this.age,
    sex: sex ?? this.sex,
    consent: consent ?? this.consent,
    createdAt: createdAt ?? this.createdAt,
  );

  /// Serialises to a Firestore document. The uid is the document key and is
  /// therefore not duplicated inside the document body.
  Map<String, Object?> toFirestore() => {
    'username': username,
    'username_lower': username.toLowerCase(),
    'role': role.storageValue,
    'patient_id': patientId,
    'full_name': fullName,
    'age': age,
    'sex': sex,
    'consent_app': consent.appAndSelfExam,
    'consent_photo': consent.photograph,
    'consent_share': consent.shareWithDoctor,
    'created_at': createdAt.toIso8601String(),
  };

  factory AppUser.fromFirestore(String uid, Map<String, Object?> data) =>
      AppUser(
        uid: uid,
        username: data['username'] as String? ?? uid,
        role: UserRoleX.fromStorage(data['role'] as String?),
        patientId: data['patient_id'] as String?,
        fullName: data['full_name'] as String?,
        age: (data['age'] as num?)?.toInt(),
        sex: data['sex'] as String?,
        consent: ConsentFlags(
          appAndSelfExam: data['consent_app'] as bool? ?? false,
          photograph: data['consent_photo'] as bool? ?? false,
          shareWithDoctor: data['consent_share'] as bool? ?? false,
        ),
        createdAt:
            DateTime.tryParse(data['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}
