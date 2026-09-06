import 'package:firebase_auth/firebase_auth.dart';

import '../firestore_refs.dart';
import '../models/app_user.dart';

/// Raised for expected, user-facing authentication problems.
class AuthException implements Exception {
  const AuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Account creation and sign-in for the two separated interfaces
/// (spec section 7), backed by Firebase Authentication and a `users`
/// collection in Firestore.
///
/// Usernames are mapped to a synthetic e-mail (`<username>@<domain>`) so the
/// UI can keep using usernames while Firebase Auth handles the credential and
/// its uniqueness. Passwords never touch Firestore.
class AuthRepository {
  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  /// Synthetic e-mail domain for the username-to-email mapping. Not a real
  /// mailbox; it only has to be a syntactically valid, consistent domain.
  static const String _emailDomain = 'oralpilot.app';

  /// Enrolment code required to create a Doctor account.
  ///
  /// PILOT ONLY. This is checked on the client, so a determined user could
  /// bypass it and self-assign the doctor role. Before deployment, doctor
  /// accounts must be provisioned server-side (e.g. a Cloud Function that sets
  /// a custom claim after verifying a real professional register), and the
  /// security rules must key doctor access off that claim rather than a
  /// client-written field.
  static const String doctorEnrolmentCode = 'ORAL-PILOT-2026';

  String _emailForUsername(String username) =>
      '${username.trim().toLowerCase()}@$_emailDomain';

  Future<AppUser> registerPatient({
    required String username,
    required String password,
    String? preferredPatientId,
    String? fullName,
    required int age,
    String? sex,
  }) async {
    _validateCredentials(username, password);
    if (age < 0 || age > 120) {
      throw const AuthException('Please enter an age between 0 and 120.');
    }
    final patientIdOverride = _validatePreferredPatientId(preferredPatientId);

    final credential = await _createAuthUser(username, password);
    final uid = credential.user!.uid;

    final patientId = patientIdOverride ?? _derivePatientId(uid);
    if (patientIdOverride != null &&
        await _patientIdTaken(patientIdOverride, uid)) {
      // Roll back the auth user so a failed registration leaves nothing behind.
      await credential.user?.delete();
      throw const AuthException('That Patient ID is already registered.');
    }

    final user = AppUser(
      uid: uid,
      username: username.trim(),
      role: UserRole.patient,
      patientId: patientId,
      fullName: fullName?.trim(),
      age: age,
      sex: sex,
      createdAt: DateTime.now(),
    );

    await FirestoreRefs.user(uid).set(user.toFirestore());
    return user;
  }

  Future<AppUser> registerDoctor({
    required String username,
    required String password,
    required String enrolmentCode,
    String? fullName,
  }) async {
    _validateCredentials(username, password);

    if (enrolmentCode.trim() != doctorEnrolmentCode) {
      throw const AuthException(
        'That clinic enrolment code is not valid. Contact the pilot '
        'coordinator to obtain one.',
      );
    }

    final credential = await _createAuthUser(username, password);
    final uid = credential.user!.uid;

    final user = AppUser(
      uid: uid,
      username: username.trim(),
      role: UserRole.doctor,
      fullName: fullName?.trim(),
      createdAt: DateTime.now(),
    );

    await FirestoreRefs.user(uid).set(user.toFirestore());
    return user;
  }

  /// Signs in and enforces that the account matches the interface the user
  /// chose. A patient credential can never open the doctor interface.
  Future<AppUser> login({
    required String username,
    required String password,
    required UserRole expectedRole,
  }) async {
    late final UserCredential credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: _emailForUsername(username),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      // Collapse all failure modes into one message so the response does not
      // reveal whether an account exists.
      if (e.code == 'network-request-failed') {
        throw const AuthException(
          'No connection. Check your internet and try again.',
        );
      }
      throw const AuthException('Incorrect username or password.');
    }

    final uid = credential.user!.uid;
    final user = await findByUid(uid);
    if (user == null) {
      await _auth.signOut();
      throw const AuthException(
        'This account has no profile record. Please register again.',
      );
    }

    if (user.role != expectedRole) {
      // Do not leave a doctor signed in on the patient interface or vice versa.
      await _auth.signOut();
      throw AuthException(
        'This account is registered as a ${user.role.label.toLowerCase()}. '
        'Please use the ${user.role.label} login.',
      );
    }

    return user;
  }

  /// Persists the consent gates from spec Table 1.
  Future<AppUser> updateConsent(AppUser user, ConsentFlags consent) async {
    await FirestoreRefs.user(user.uid).update({
      'consent_app': consent.appAndSelfExam,
      'consent_photo': consent.photograph,
      'consent_share': consent.shareWithDoctor,
    });
    return user.copyWith(consent: consent);
  }

  Future<AppUser?> findByUid(String uid) async {
    final snapshot = await FirestoreRefs.user(uid).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) return null;
    return AppUser.fromFirestore(uid, data);
  }

  Future<AppUser?> findByPatientId(String patientId) async {
    final query = await FirestoreRefs.users()
        .where('patient_id', isEqualTo: patientId)
        .limit(1)
        .get();
    if (query.docs.isEmpty) return null;
    final doc = query.docs.first;
    return AppUser.fromFirestore(doc.id, doc.data());
  }

  /// The uid of the currently signed-in Firebase user, if any.
  String? get currentUid => _auth.currentUser?.uid;

  Future<void> signOut() => _auth.signOut();

  // ---------------------------------------------------------------------------

  Future<UserCredential> _createAuthUser(
    String username,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: _emailForUsername(username),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(switch (e.code) {
        'email-already-in-use' => 'That username is already taken.',
        'weak-password' => 'That password is too weak.',
        'operation-not-allowed' =>
          'Email/password sign-in is not enabled for this project yet.',
        'network-request-failed' =>
          'No connection. Check your internet and try again.',
        _ => 'Could not create the account (${e.code}).',
      });
    }
  }

  void _validateCredentials(String username, String password) {
    final name = username.trim();
    if (name.length < 3) {
      throw const AuthException('Username must be at least 3 characters.');
    }
    if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(name)) {
      throw const AuthException(
        'Username can use letters, numbers, dot, dash and underscore only.',
      );
    }
    if (password.length < 8) {
      throw const AuthException('Password must be at least 8 characters.');
    }
    if (!RegExp(r'[A-Za-z]').hasMatch(password) ||
        !RegExp(r'\d').hasMatch(password)) {
      throw const AuthException(
        'Password must include at least one letter and one number.',
      );
    }
  }

  String? _validatePreferredPatientId(String? preferred) {
    final trimmed = preferred?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    if (!RegExp(r'^[A-Za-z0-9/_-]{3,32}$').hasMatch(trimmed)) {
      throw const AuthException(
        'Patient ID can use 3 to 32 letters, numbers, dash, slash or '
        'underscore.',
      );
    }
    return trimmed;
  }

  Future<bool> _patientIdTaken(String patientId, String selfUid) async {
    final existing = await findByPatientId(patientId);
    return existing != null && existing.uid != selfUid;
  }

  /// A readable, unique Patient_ID derived from the uid, e.g. OC-2026-4F9A2C.
  String _derivePatientId(String uid) {
    final year = DateTime.now().year;
    final suffix = uid
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase()
        .padRight(6, '0')
        .substring(0, 6);
    return 'OC-$year-$suffix';
  }
}
