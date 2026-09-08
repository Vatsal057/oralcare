/// Browser implementation: this pilot does not capture or persist photos on
/// the web. Keeping these no-op methods prevents old local file paths from
/// being exposed or dereferenced by browser code.
class PhotoStore {
  const PhotoStore._();

  static Future<String> store(String sourcePath, String patientId) =>
      Future.error(
        UnsupportedError('Photographs are unavailable in the web pilot.'),
      );

  static Future<void> delete(String? path) async {}

  static bool exists(String? path) => false;
}
