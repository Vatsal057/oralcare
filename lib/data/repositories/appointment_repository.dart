import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/referral/appointment_request.dart';

/// Stores the patient's appointment requests (Section F).
///
/// These are the patient's own records of an intention to attend. Nothing is
/// transmitted to a centre: there is no booking integration, so the UI must not
/// imply the centre has been told.
class AppointmentRepository {
  AppointmentRepository({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth,
      _db = db;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _db;

  FirebaseAuth? get _resolvedAuth {
    if (_auth != null) return _auth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseFirestore? get _resolvedDb {
    if (_db != null) return _db;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  /// Fallback for guest mode, where there is no account to save against.
  final Map<String, List<AppointmentRequest>> _inMemoryStore = {};

  String? get _uid => _resolvedAuth?.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? _col(String uid) =>
      _resolvedDb?.collection('users').doc(uid).collection('appointments');

  /// True when a request can actually be persisted to the account.
  bool get canPersist => _uid != null && _resolvedDb != null;

  Future<List<AppointmentRequest>> listForPatient(String patientId) async {
    final uid = _uid;
    if (uid != null) {
      try {
        final snap = await _col(uid)?.get();
        if (snap != null) {
          final list = snap.docs
              .map((d) => AppointmentRequest.fromJson(d.data()))
              .toList();
          list.sort((a, b) => a.requestedDate.compareTo(b.requestedDate));
          return List.unmodifiable(list);
        }
      } catch (_) {
        // Fall through to the local copy rather than losing the screen.
      }
    }
    final list = [...?_inMemoryStore[patientId]];
    list.sort((a, b) => a.requestedDate.compareTo(b.requestedDate));
    return List.unmodifiable(list);
  }

  Future<void> save(AppointmentRequest request) async {
    final uid = _uid;
    if (uid != null) {
      // Deliberately not swallowed: the caller must be able to tell the patient
      // the request was not saved, instead of showing a false confirmation.
      await _col(uid)?.doc(request.id).set(request.toJson());
      return;
    }
    _inMemoryStore.putIfAbsent(request.patientId, () => []).add(request);
  }

  Future<void> updateStatus(
    AppointmentRequest request,
    AppointmentStatus status,
  ) async {
    final uid = _uid;
    if (uid != null) {
      await _col(uid)?.doc(request.id).update({'status': status.storageValue});
      return;
    }
    final list = _inMemoryStore[request.patientId];
    if (list == null) return;
    final index = list.indexWhere((r) => r.id == request.id);
    if (index >= 0) list[index] = request.copyWith(status: status);
  }

  Future<void> delete(AppointmentRequest request) async {
    final uid = _uid;
    if (uid != null) {
      await _col(uid)?.doc(request.id).delete();
      return;
    }
    _inMemoryStore[request.patientId]?.removeWhere((r) => r.id == request.id);
  }
}
