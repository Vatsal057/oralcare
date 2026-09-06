import 'package:flutter/foundation.dart';

import '../data/models/app_user.dart';
import '../data/repositories/auth_repository.dart';

/// Holds the signed-in user for the current session.
///
/// Firebase Authentication persists the credential across app restarts, so on
/// launch [initialise] restores the session from the current Firebase user and
/// loads their profile document.
class SessionController extends ChangeNotifier {
  SessionController({AuthRepository? auth}) : _auth = auth ?? AuthRepository();

  final AuthRepository _auth;

  AppUser? _user;
  AppUser? get user => _user;

  bool _initialising = true;

  /// True until the initial session restore completes. The root widget shows a
  /// splash while this is true so it does not flash the login screen.
  bool get isInitialising => _initialising;

  bool get isSignedIn => _user != null;

  /// Convenience accessor for screens that are only reachable when signed in.
  AppUser get requireUser {
    final current = _user;
    if (current == null) {
      throw StateError('No signed-in user. This screen requires a session.');
    }
    return current;
  }

  AuthRepository get auth => _auth;

  /// Restores a persisted Firebase session, if any, on app launch.
  Future<void> initialise() async {
    try {
      final uid = _auth.currentUid;
      if (uid != null) {
        _user = await _auth.findByUid(uid);
        // A Firebase user with no profile document is unusable; sign it out so
        // the app lands cleanly on the login screen.
        if (_user == null) await _auth.signOut();
      }
    } catch (_) {
      _user = null;
    } finally {
      _initialising = false;
      notifyListeners();
    }
  }

  Future<AppUser> signIn({
    required String username,
    required String password,
    required UserRole role,
  }) async {
    final user = await _auth.login(
      username: username,
      password: password,
      expectedRole: role,
    );
    _user = user;
    notifyListeners();
    return user;
  }

  /// Called immediately after registration so the user lands in the app.
  void adopt(AppUser user) {
    _user = user;
    notifyListeners();
  }

  Future<void> updateConsent(ConsentFlags consent) async {
    final current = requireUser;
    _user = await _auth.updateConsent(current, consent);
    notifyListeners();
  }

  /// Reloads from Firestore, so consent changes made elsewhere are picked up.
  Future<void> refresh() async {
    final current = _user;
    if (current == null) return;
    final fresh = await _auth.findByUid(current.uid);
    if (fresh != null) {
      _user = fresh;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }
}
