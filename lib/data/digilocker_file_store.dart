import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'image_document_store.dart';

/// Stores the image attached to a DigiLocker record.
///
/// WHY THIS EXISTS: the locker previously kept only `local_file_path`, a path on
/// the capturing device. That meant a stored biopsy report or clinical
/// photograph disappeared on any other device, was lost with the phone — the
/// exact scenario a records locker is meant to protect against — and showed the
/// clinician nothing at all when the patient marked the document as shared.
///
/// The bytes live in a sibling document, `digilocker_files/{recordId}`, rather
/// than on the record itself, so listing the locker does not download every
/// image. The id is deliberately the record's own id: it makes the pairing
/// unambiguous and lets the security rules find the parent record to check its
/// `is_shared` flag.
class DigiLockerFileStore {
  DigiLockerFileStore({FirebaseAuth? auth, FirebaseFirestore? db})
    : _auth = auth,
      _db = db;

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _db;

  static const String collectionName = 'digilocker_files';

  /// Same ceiling as a lesion photograph: one Firestore document each.
  static int get maxBytes => ImageDocumentStore.maxBytes;

  static bool isWithinLimit(int byteCount) =>
      ImageDocumentStore.isWithinLimit(byteCount);

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

  bool get isConfigured => _resolvedDb != null && _uid != null;

  String? get _uid => _resolvedAuth?.currentUser?.uid;

  DocumentReference<Map<String, dynamic>>? _ref({
    required String recordId,
    String? ownerUid,
  }) {
    final uid = ownerUid ?? _uid;
    final db = _resolvedDb;
    if (uid == null || db == null) return null;
    return db
        .collection('users')
        .doc(uid)
        .collection(collectionName)
        .doc(recordId);
  }

  /// Saves the image for a record. False when it was not stored, so the caller
  /// can avoid claiming the document was filed with its picture.
  Future<bool> save({
    required String recordId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) => ImageDocumentStore.write(
    ref: _ref(recordId: recordId),
    bytes: bytes,
    contentType: contentType,
  );

  /// Loads the image for a record.
  ///
  /// [ownerUid] lets a clinician read a shared document from the patient's own
  /// collection; it defaults to the signed-in user for the patient's own view.
  Future<Uint8List?> load({required String recordId, String? ownerUid}) =>
      ImageDocumentStore.read(_ref(recordId: recordId, ownerUid: ownerUid));

  Future<bool> delete({required String recordId}) =>
      ImageDocumentStore.remove(_ref(recordId: recordId));
}
