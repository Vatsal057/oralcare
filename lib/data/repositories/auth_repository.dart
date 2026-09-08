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

  /// Custom-claim key and value that grant clinician access.
  ///
  /// The claim is set only by `tools/grant_doctor.mjs` using Admin SDK
  /// credentials, and the Firestore rules authorise clinician reads on the claim
  /// alone. The app therefore cannot create a doctor account, and a user cannot
  /// promote themselves.
  static const String _roleClaim = 'role';
  static const String _doctorClaimValue = 'doctor';

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

    // Reserve the Patient_ID first. The rules only allow creating a reservation
    // that does not already exist, so this both proves uniqueness and claims
    // the id in one write, without reading anyone else's profile.
    await _runOrRollBack(credential, () async {
      try {
        await FirestoreRefs.patientIdReservation(patientId).set({
          'owner_uid': uid,
          'created_at': DateTime.now().toIso8601String(),
        });
      } on FirebaseException catch (e) {
        if (e.code == 'permission-denied' && patientIdOverride != null) {
          throw const AuthException('That Patient ID is already registered.');
        }
        rethrow;
      }

      await FirestoreRefs.user(uid).set(user.toFirestore());
    });

    return user;
  }

  /// Runs post-sign-up work, deleting the new auth user if it fails.
  ///
  /// Without this, a failed profile write leaves an account that can neither
  /// sign in (no profile) nor be registered again (username taken).
  Future<void> _runOrRollBack(
    UserCredential credential,
    Future<void> Function() work,
  ) async {
    try {
      await work();
    } catch (_) {
      try {
        await credential.user?.delete();
      } catch (_) {
        // Ignore cleanup failures; the original error is the useful one.
      }
      rethrow;
    }
  }

  /// True when the signed-in account carries the server-set clinician claim.
  ///
  /// [forceRefresh] fetches a new ID token, which is required immediately after
  /// provisioning because the claim is embedded in the token.
  Future<bool> hasDoctorClaim({bool forceRefresh = false}) async {
    final current = _auth.currentUser;
    if (current == null) return false;
    try {
      final token = await current.getIdTokenResult(forceRefresh);
      return token.claims?[_roleClaim] == _doctorClaimValue;
    } catch (_) {
      // Fail closed: without a verifiable token, treat access as not granted.
      return false;
    }
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

    if (expectedRole == UserRole.doctor &&
        !await hasDoctorClaim(forceRefresh: true)) {
      // The profile says doctor but the server has not granted the claim, so
      // every clinician read would be denied. Refuse the session outright
      // instead of opening an interface that cannot load anything.
      await _auth.signOut();
      throw const AuthException(
        'This account is not approved for clinician access. The pilot '
        'coordinator must provision it before you can sign in.',
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

  /// Doctor-only lookup: querying the `users` collection is permitted by the
  /// rules for the doctor role, not for patients.
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
      if (e.code == 'email-already-in-use') {
        // An earlier registration may have created the credential but failed
        // before writing the profile. Adopt that account when the same person
        // supplies the correct password, so the username is not stranded.
        final adopted = await _adoptProfilelessAccount(username, password);
        if (adopted != null) return adopted;
      }
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

  /// Returns the credential for an existing account that has no profile
  /// document, or null when the account is genuinely in use.
  Future<UserCredential?> _adoptProfilelessAccount(
    String username,
    String password,
  ) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: _emailForUsername(username),
        password: password,
      );
      if (await findByUid(credential.user!.uid) == null) return credential;
      await _auth.signOut();
    } catch (_) {
      // Wrong password, or the profile could not be read: treat the username as
      // taken rather than leaking whether the account exists.
    }
    return null;
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
