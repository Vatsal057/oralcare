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
    this.gender,
    this.phone,
    this.email,
    this.city,
    this.pincode,
    this.medicalHistory,
    this.allergies,
    this.currentMedications,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.isGuest = false,
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

  /// Gender, collected at registration. Required for new patient accounts; it
  /// stays nullable because guest profiles and legacy records may not carry it.
  final String? gender;

  // Additional fields from Section 1 of Final cHeck.docx
  final String? phone;
  final String? email;
  final String? city;
  final String? pincode;
  final String? medicalHistory;
  final String? allergies;
  final String? currentMedications;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final bool isGuest;

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
    String? gender,
    String? phone,
    String? email,
    String? city,
    String? pincode,
    String? medicalHistory,
    String? allergies,
    String? currentMedications,
    String? emergencyContactName,
    String? emergencyContactPhone,
    bool? isGuest,
    ConsentFlags? consent,
    DateTime? createdAt,
  }) => AppUser(
    uid: uid ?? this.uid,
    username: username ?? this.username,
    role: role ?? this.role,
    patientId: patientId ?? this.patientId,
    fullName: fullName ?? this.fullName,
    age: age ?? this.age,
    gender: gender ?? this.gender,
    phone: phone ?? this.phone,
    email: email ?? this.email,
    city: city ?? this.city,
    pincode: pincode ?? this.pincode,
    medicalHistory: medicalHistory ?? this.medicalHistory,
    allergies: allergies ?? this.allergies,
    currentMedications: currentMedications ?? this.currentMedications,
    emergencyContactName: emergencyContactName ?? this.emergencyContactName,
    emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
    isGuest: isGuest ?? this.isGuest,
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
    'gender': gender,
    'phone': phone,
    'email': email,
    'city': city,
    'pincode': pincode,
    'medical_history': medicalHistory,
    'allergies': allergies,
    'current_medications': currentMedications,
    'emergency_contact_name': emergencyContactName,
    'emergency_contact_phone': emergencyContactPhone,
    'is_guest': isGuest,
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
        // Accounts created before the rename stored this as `sex`, so fall back
        // to the old key rather than losing the value.
        gender: (data['gender'] ?? data['sex']) as String?,
        phone: data['phone'] as String?,
        email: data['email'] as String?,
        city: data['city'] as String?,
        pincode: data['pincode'] as String?,
        medicalHistory: data['medical_history'] as String?,
        allergies: data['allergies'] as String?,
        currentMedications: data['current_medications'] as String?,
        emergencyContactName: data['emergency_contact_name'] as String?,
        emergencyContactPhone: data['emergency_contact_phone'] as String?,
        isGuest: data['is_guest'] as bool? ?? false,
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
