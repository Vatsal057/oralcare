import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/cessation/cessation_models.dart';

class CessationRepository {
  CessationRepository({FirebaseAuth? auth, FirebaseFirestore? db})
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

  // Local fallback storage
  final Map<String, QuitPlan> _inMemoryPlans = {};

  String? get _uid => _resolvedAuth?.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? _planDoc(String uid) {
    final db = _resolvedDb;
    if (db == null) return null;
    return db.collection('users').doc(uid).collection('cessation').doc('plan');
  }

  Future<QuitPlan?> getQuitPlan(String patientId) async {
    final uid = _uid;
    if (uid != null) {
      try {
        final snap = await _planDoc(uid)?.get();
        if (snap != null && snap.exists && snap.data() != null) {
          return QuitPlan.fromJson(snap.data()!);
        }
      } catch (_) {}
    }

    return _inMemoryPlans[patientId];
  }

  Future<void> saveQuitPlan({
    required String patientId,
    required QuitPlan plan,
  }) async {
    final uid = _uid;
    if (uid != null) {
      try {
        await _planDoc(uid)?.set(plan.toJson());
      } catch (_) {}
    }

    _inMemoryPlans[patientId] = plan;
  }

  Future<void> logCraving({
    required String patientId,
    required CravingEntry entry,
  }) async {
    final current = await getQuitPlan(patientId);
    if (current == null) return;

    final updated = current.copyWith(
      cravingLogs: [entry, ...current.cravingLogs],
    );
    await saveQuitPlan(patientId: patientId, plan: updated);
  }
}
