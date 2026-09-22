import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_refs.dart';
import 'image_document_store.dart';

/// Stores a consented lesion photograph inside Firestore, as bytes.
///
/// WHY NOT FIREBASE STORAGE: Cloud Storage now requires the paid Blaze plan, and
/// this pilot runs on the free plan. Firestore is available, and it turns out to
/// be the better fit for clinical images anyway: Storage rules cannot read a
/// Firestore document, so they could not check the patient's consent flag or
/// which clinician a record was addressed to. Holding the image in Firestore puts
/// it under exactly the same consent-and-recipient rules as the rest of the
/// record.
///
/// THE COST: a Firestore document is capped at 1 MiB, so photographs must be
/// small. Images are downscaled at capture and refused here if they still exceed
/// [maxBytes], rather than failing with an opaque write error.
class PhotoDocumentStore {
  PhotoDocumentStore({FirebaseFirestore? db}) : _db = db;

  final FirebaseFirestore? _db;

  /// Firestore's hard limit is 1,048,576 bytes for the whole document. The
  /// ceiling leaves room for the other fields and Firestore's own overhead.
  ///
  /// Delegated to [ImageDocumentStore] so lesion photographs and DigiLocker
  /// attachments cannot end up with different limits.
  static int get maxBytes => ImageDocumentStore.maxBytes;

  static const String collectionName = 'lesion_photos';

  FirebaseFirestore? get _resolved {
    if (_db != null) return _db;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  bool get isConfigured => _resolved != null;

  /// True when an image is small enough to be stored in a document.
  static bool isWithinLimit(int byteCount) =>
      ImageDocumentStore.isWithinLimit(byteCount);

  DocumentReference<Map<String, dynamic>>? _ref({
    required int assessmentId,
    required int lesionId,
  }) => _resolved
      ?.collection(FirestoreRefs.assessmentsCollection)
      .doc(assessmentId.toString())
      .collection(collectionName)
      .doc(lesionId.toString());

  /// Saves the photograph. Returns false when it was not stored, so the caller
  /// can tell the patient the truth rather than implying a clinician can see it.
  Future<bool> save({
    required int assessmentId,
    required int lesionId,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
  }) => ImageDocumentStore.write(
    ref: _ref(assessmentId: assessmentId, lesionId: lesionId),
    bytes: bytes,
    contentType: contentType,
  );

  /// Loads the photograph, or null when there is none or it cannot be read.
  ///
  /// Kept in its own document so the doctor's queue does not carry image bytes
  /// on every list read; it is fetched only when a record is opened.
  Future<Uint8List?> load({
    required int assessmentId,
    required int lesionId,
  }) => ImageDocumentStore.read(
    _ref(assessmentId: assessmentId, lesionId: lesionId),
  );

  /// Removes the stored photograph when the patient withdraws it.
  Future<bool> delete({required int assessmentId, required int lesionId}) =>
      ImageDocumentStore.remove(
        _ref(assessmentId: assessmentId, lesionId: lesionId),
      );
}
