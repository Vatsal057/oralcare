import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Android implementation for lesion photos stored in app-private storage.
class PhotoStore {
  const PhotoStore._();

  static const String _folder = 'lesion_photos';

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

  static Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  static bool exists(String? path) =>
      path != null && path.isNotEmpty && File(path).existsSync();
}
