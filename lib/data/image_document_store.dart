import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

/// Reads and writes an image held as bytes inside a Firestore document.
///
/// WHY FIRESTORE AND NOT CLOUD STORAGE: Storage requires the paid Blaze plan,
/// and this pilot runs on the free one. It is also the better fit for clinical
/// images, because Storage rules cannot read a Firestore document and therefore
/// cannot check a consent flag or a sharing decision. Holding the bytes in
/// Firestore puts an image under the same rules as the record it belongs to.
///
/// THE COST: a Firestore document is capped at 1 MiB. Images are downscaled at
/// capture and refused here if they still exceed [maxBytes], so a caller can
/// tell the user the truth instead of surfacing an opaque write failure.
///
/// Shared by lesion photographs and DigiLocker attachments so the size rule and
/// the failure behaviour are defined once.
class ImageDocumentStore {
  const ImageDocumentStore._();

  /// Firestore's hard limit is 1,048,576 bytes for the whole document. This
  /// ceiling leaves room for the other fields and Firestore's own overhead.
  static const int maxBytes = 900 * 1024;

  /// True when an image is small enough to be stored in a document.
  static bool isWithinLimit(int byteCount) =>
      byteCount > 0 && byteCount <= maxBytes;

  /// Writes the image. Returns false when it was not stored, for any reason.
  static Future<bool> write({
    required DocumentReference<Map<String, dynamic>>? ref,
    required Uint8List bytes,
    String contentType = 'image/jpeg',
    Map<String, Object?> extraFields = const {},
  }) async {
    if (ref == null || !isWithinLimit(bytes.length)) return false;
    try {
      await ref.set({
        'bytes': Blob(bytes),
        'content_type': contentType,
        'byte_count': bytes.length,
        'created_at': DateTime.now().toIso8601String(),
        ...extraFields,
      });
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Reads the image, or null when there is none or it cannot be read.
  static Future<Uint8List?> read(
    DocumentReference<Map<String, dynamic>>? ref,
  ) async {
    if (ref == null) return null;
    try {
      final snapshot = await ref.get();
      final data = snapshot.data();
      if (!snapshot.exists || data == null) return null;
      final blob = data['bytes'];
      return blob is Blob ? blob.bytes : null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> remove(
    DocumentReference<Map<String, dynamic>>? ref,
  ) async {
    if (ref == null) return false;
    try {
      await ref.delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
