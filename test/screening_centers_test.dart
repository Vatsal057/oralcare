import 'package:flutter_test/flutter_test.dart';
import 'package:oralcare/data/repositories/screening_center_repository.dart';
import 'package:oralcare/domain/referral/screening_centers_catalog.dart';

/// The centre directory is safety-relevant: a patient uses these details to find
/// care. It must survive a round trip through Firestore, and it must never leave
/// the screen empty.
void main() {
  group('centre serialisation', () {
    test('a published centre round trips unchanged', () {
      final original = ScreeningCentersCatalog.centers.first;
      final restored = ScreeningCenter.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.type, original.type);
      expect(restored.city, original.city);
      expect(restored.state, original.state);
      expect(restored.address, original.address);
      expect(restored.phone, original.phone);
      expect(restored.timings, original.timings);
      expect(restored.services, original.services);
    });

    test('every bundled centre survives a round trip', () {
      for (final center in ScreeningCentersCatalog.centers) {
        final restored = ScreeningCenter.fromJson(center.toJson());
        expect(restored.phone, center.phone, reason: center.name);
        expect(restored.type, center.type, reason: center.name);
      }
    });

    test('an unknown type falls back instead of throwing', () {
      final restored = ScreeningCenter.fromJson({
        'id': 'x',
        'name': 'New Centre',
        'type': 'somethingAdded Later',
      });

      expect(restored.type, CenterType.dentalInstitute);
      expect(restored.name, 'New Centre');
      expect(restored.services, isEmpty);
    });

    test('a malformed entry still yields a usable object', () {
      final restored = ScreeningCenter.fromJson(const {});

      expect(restored.name, 'Unnamed centre');
      expect(restored.phone, isEmpty);
    });
  });

  group('loading', () {
    test(
      'falls back to the bundled copy when Firestore is unavailable',
      () async {
        // No Firebase is initialised in a unit test, so this exercises the exact
        // path a patient hits offline: centres must still be listed.
        final result = await ScreeningCenterRepository().load();

        expect(result.centers, isNotEmpty);
        expect(result.source, CenterSource.bundled);
        expect(result.isBundled, isTrue);
      },
    );

    test('the bundled copy covers the required centre types', () {
      final types = ScreeningCentersCatalog.centers.map((c) => c.type).toSet();

      expect(types, contains(CenterType.dentalInstitute));
      expect(types, contains(CenterType.oncologyCentre));
    });
  });
}
