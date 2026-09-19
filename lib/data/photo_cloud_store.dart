import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

/// Uploads consented lesion photographs so a clinician on another device can see
/// them (spec 3.1, "Patient photograph, if consented").
///
/// Firebase Storage may not be provisioned on a given project. Every method
/// therefore reports failure instead of throwing, and the caller must keep the
/// device-local copy so the patient never loses their photo. A null result means
/// "not uploaded", which the UI states plainly rather than implying the clinician
/// can see it.
class PhotoCloudStore {
  PhotoCloudStore({FirebaseStorage? storage}) : _storage = storage;

  final FirebaseStorage? _storage;

  FirebaseStorage? get _resolved {
    if (_storage != null) return _storage;
    try {
      return FirebaseStorage.instance;
    } catch (_) {
      return null;
    }
  }

  /// True when an upload could at least be attempted.
  bool get isConfigured => _resolved != null;

  /// Path layout mirrors the security rules: the owner's uid is the first
  /// segment, so a patient can only ever write beneath their own folder.
  String _path({
    required String ownerUid,
    required int assessmentId,
    required int lesionId,
  }) => 'patient_photos/$ownerUid/$assessmentId/$lesionId.jpg';

  /// Returns the download URL, or null when the upload did not happen.
  Future<String?> upload({
    required String ownerUid,
    required int assessmentId,
    required int lesionId,
    required Uint8List bytes,
  }) async {
    final storage = _resolved;
    if (storage == null) return null;

    try {
      final ref = storage.ref(
        _path(
          ownerUid: ownerUid,
          assessmentId: assessmentId,
          lesionId: lesionId,
        ),
      );
      await ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'image/jpeg',
          // Marks the clinical purpose on the object itself, so an audit of the
          // bucket shows what these files are.
          customMetadata: {'purpose': 'oral-lesion-photograph'},
        ),
      );
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  /// Removes an uploaded photograph, used when the patient withdraws it.
  Future<bool> deleteByUrl(String? url) async {
    if (url == null || url.isEmpty) return false;
    final storage = _resolved;
    if (storage == null) return false;
    try {
      await storage.refFromURL(url).delete();
      return true;
    } catch (_) {
      return false;
    }
  }
}
