import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/referral/screening_centers_catalog.dart';

/// Where the centre list shown to a patient came from.
enum CenterSource {
  /// Published to Firestore and therefore correctable without an app release.
  directory,

  /// Compiled into the app. Details may be out of date.
  bundled,
}

class ScreeningCenterResult {
  const ScreeningCenterResult(this.centers, this.source);

  final List<ScreeningCenter> centers;
  final CenterSource source;

  bool get isBundled => source == CenterSource.bundled;
}

/// Loads screening centres, preferring the maintained Firestore directory.
///
/// Clinic phone numbers and timings change, and the specification requires them
/// to be verified and kept updated. A hardcoded list cannot be corrected without
/// shipping a release, so Firestore is the source of truth and the bundled
/// catalogue is only a fallback for offline use or an unseeded project.
class ScreeningCenterRepository {
  ScreeningCenterRepository({FirebaseFirestore? db}) : _db = db;

  final FirebaseFirestore? _db;

  static const String collectionName = 'screening_centers';

  FirebaseFirestore? get _resolvedDb {
    if (_db != null) return _db;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  Future<ScreeningCenterResult> load() async {
    final db = _resolvedDb;
    if (db != null) {
      try {
        final snap = await db.collection(collectionName).get();
        if (snap.docs.isNotEmpty) {
          final centers = snap.docs
              .map((d) => ScreeningCenter.fromJson(d.data()))
              .toList();
          centers.sort((a, b) => a.name.compareTo(b.name));
          return ScreeningCenterResult(
            List.unmodifiable(centers),
            CenterSource.directory,
          );
        }
      } catch (_) {
        // Offline or not readable: fall back rather than showing no centres at
        // all, since this screen is how a patient finds care.
      }
    }
    return ScreeningCenterResult(
      ScreeningCentersCatalog.centers,
      CenterSource.bundled,
    );
  }
}
