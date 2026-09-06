import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Stores lesion photographs inside the app's private documents directory.
///
/// Images from the camera or gallery live in temporary or shared locations, so
/// they are copied into app-private storage. They are deliberately NOT written
/// to the device gallery: an intra-oral clinical photograph should not end up in
/// the user's camera roll or any cloud photo backup by default.
class PhotoStore {
  const PhotoStore._();

  static const String _folder = 'lesion_photos';

  /// Copies [sourcePath] into private storage and returns the stored path.
  static Future<String> store(String sourcePath, String patientId) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _folder));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final extension = p.extension(sourcePath).isEmpty
        ? '.jpg'
        : p.extension(sourcePath);
    final safePatientId = patientId.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final fileName =
        '${safePatientId}_${DateTime.now().millisecondsSinceEpoch}$extension';
    final destination = p.join(dir.path, fileName);

    await File(sourcePath).copy(destination);
    return destination;
  }

  /// Removes a stored photograph. Used when the patient withdraws a photo from
  /// the draft before saving.
  static Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static bool exists(String? path) {
    if (path == null || path.isEmpty) return false;
    return File(path).existsSync();
  }
}
