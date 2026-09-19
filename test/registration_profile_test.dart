import 'package:flutter_test/flutter_test.dart';
import 'package:oralcare/data/models/app_user.dart';

/// Registration demographics: age and gender are mandatory for a patient
/// account, and the field is named gender rather than sex.
void main() {
  AppUser user({int? age, String? gender}) => AppUser(
    uid: 'u1',
    username: 'divya',
    role: UserRole.patient,
    patientId: 'OC-2026-ABC123',
    age: age,
    gender: gender,
    createdAt: DateTime(2026, 9, 19),
  );

  group('gender storage', () {
    test('gender is written under the gender key, not sex', () {
      final row = user(age: 47, gender: 'Female').toFirestore();

      expect(row['gender'], 'Female');
      expect(row.containsKey('sex'), isFalse);
    });

    test('gender survives a round trip', () {
      final restored = AppUser.fromFirestore(
        'u1',
        user(age: 47, gender: 'Female').toFirestore(),
      );

      expect(restored.gender, 'Female');
      expect(restored.age, 47);
    });

    test('accounts written before the rename still read their value', () {
      // Legacy documents stored this as `sex`; the value must not be lost.
      final restored = AppUser.fromFirestore('u1', {
        'username': 'legacy',
        'role': 'patient',
        'age': 52,
        'sex': 'Male',
        'created_at': '2026-09-01T00:00:00.000',
      });

      expect(restored.gender, 'Male');
    });

    test('the new key wins when both are present', () {
      final restored = AppUser.fromFirestore('u1', {
        'username': 'both',
        'role': 'patient',
        'gender': 'Other',
        'sex': 'Male',
        'created_at': '2026-09-01T00:00:00.000',
      });

      expect(restored.gender, 'Other');
    });

    test('a missing gender reads as null rather than a default', () {
      final restored = AppUser.fromFirestore('u1', {
        'username': 'nogender',
        'role': 'patient',
        'created_at': '2026-09-01T00:00:00.000',
      });

      expect(restored.gender, isNull);
    });
  });

  group('every offered gender option persists', () {
    for (final value in const [
      'Female',
      'Male',
      'Other',
      'Prefer not to say',
    ]) {
      test('"$value" round trips unchanged', () {
        final restored = AppUser.fromFirestore(
          'u1',
          user(age: 30, gender: value).toFirestore(),
        );
        expect(restored.gender, value);
      });
    }
  });
}
