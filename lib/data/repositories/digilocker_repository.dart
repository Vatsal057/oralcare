import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/records/digilocker_models.dart';

/// Repository for the patient's personal oral-cancer digital locker
/// (spec Section G / WHATS-GOING-ON Part 2).
class DigiLockerRepository {
  DigiLockerRepository({FirebaseAuth? auth, FirebaseFirestore? db})
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

  // Local fallback storage for offline/guest mode or when Firestore is unconfigured.
  final Map<String, List<DigiLockerRecord>> _inMemoryStore = {};

  String? get _uid => _resolvedAuth?.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? _userRecordsCol(String uid) {
    final db = _resolvedDb;
    if (db == null) return null;
    return db.collection('users').doc(uid).collection('digilocker_records');
  }

  Future<List<DigiLockerRecord>> getRecordsForPatient(String patientId) async {
    final uid = _uid;
    if (uid != null) {
      try {
        final snap = await _userRecordsCol(
          uid,
        )?.orderBy('document_date', descending: true).get();
        if (snap != null && snap.docs.isNotEmpty) {
          return snap.docs
              .map((d) => DigiLockerRecord.fromJson(d.data()))
              .toList();
        }
      } catch (_) {
        // Fall back to memory store on network or rules failure
      }
    }

    final list = _inMemoryStore[patientId] ?? [];
    list.sort((a, b) => b.documentDate.compareTo(a.documentDate));
    return List.unmodifiable(list);
  }

  Future<void> saveRecord(DigiLockerRecord record) async {
    final uid = _uid;
    if (uid != null) {
      try {
        await _userRecordsCol(uid)?.doc(record.id).set(record.toJson());
      } catch (_) {
        // Fallback to memory
      }
    }

    final list = _inMemoryStore.putIfAbsent(record.patientId, () => []);
    final idx = list.indexWhere((r) => r.id == record.id);
    if (idx >= 0) {
      list[idx] = record;
    } else {
      list.add(record);
    }
  }

  Future<void> deleteRecord({
    required String patientId,
    required String recordId,
  }) async {
    final uid = _uid;
    if (uid != null) {
      try {
        await _userRecordsCol(uid)?.doc(recordId).delete();
      } catch (_) {}
    }

    final list = _inMemoryStore[patientId];
    if (list != null) {
      list.removeWhere((r) => r.id == recordId);
    }
  }

  /// Records the patient has explicitly shared, read by the clinician reviewing
  /// their case.
  ///
  /// The `is_shared` filter is required, not an optimisation: the security rules
  /// only permit a clinician to read shared documents, and Firestore rejects any
  /// query it cannot prove stays inside that permission.
  Future<List<DigiLockerRecord>> sharedRecordsForUid(String patientUid) async {
    final col = _userRecordsCol(patientUid);
    if (col == null) return const [];

    final snap = await col.where('is_shared', isEqualTo: 1).get();
    final list = snap.docs
        .map((d) => DigiLockerRecord.fromJson(d.data()))
        .toList();
    list.sort((a, b) => b.documentDate.compareTo(a.documentDate));
    return List.unmodifiable(list);
  }

  Future<void> toggleSharing({
    required String patientId,
    required String recordId,
    required bool isShared,
  }) async {
    final uid = _uid;
    if (uid != null) {
      try {
        await _userRecordsCol(
          uid,
        )?.doc(recordId).update({'is_shared': isShared ? 1 : 0});
      } catch (_) {}
    }

    final list = _inMemoryStore[patientId];
    if (list != null) {
      final idx = list.indexWhere((r) => r.id == recordId);
      if (idx >= 0) {
        list[idx] = list[idx].copyWith(isSharedWithClinician: isShared);
      }
    }
  }
}
