import 'package:flutter_test/flutter_test.dart';
import 'package:oralcare/data/models/assessment_models.dart';

/// A device-local path is meaningless to anyone else, so the record distinguishes
/// "there is a photo on the phone that took it" from "there is a photo a
/// clinician can actually open". Confusing the two is what made photographs
/// invisible to clinicians before.
void main() {
  LesionRecord lesion({String? photoPath, String? photoUrl}) => LesionRecord(
    patientId: 'OC-2026-ABC123',
    createdAt: DateTime(2026, 9, 19),
    photoPath: photoPath,
    photoUrl: photoUrl,
  );

  group('photo availability', () {
    test('no photo at all', () {
      final record = lesion();
      expect(record.hasPhoto, isFalse);
      expect(record.hasLocalPhoto, isFalse);
      expect(record.hasUploadedPhoto, isFalse);
    });

    test('a local photo is not readable by a clinician', () {
      final record = lesion(photoPath: '/data/user/0/app/lesion_1.jpg');
      expect(record.hasPhoto, isTrue);
      expect(record.hasLocalPhoto, isTrue);
      expect(
        record.hasUploadedPhoto,
        isFalse,
        reason: 'nothing has been uploaded, so no clinician can open it',
      );
    });

    test('an uploaded photo is readable off-device', () {
      final record = lesion(photoUrl: 'https://example.com/a.jpg');
      expect(record.hasUploadedPhoto, isTrue);
      expect(record.hasPhoto, isTrue);
    });

    test('empty strings do not count as a photo', () {
      final record = lesion(photoPath: '', photoUrl: '');
      expect(record.hasPhoto, isFalse);
      expect(record.hasLocalPhoto, isFalse);
      expect(record.hasUploadedPhoto, isFalse);
    });
  });

  group('persistence', () {
    test('both the local path and the upload URL round trip', () {
      final original = lesion(
        photoPath: '/data/local/x.jpg',
        photoUrl: 'https://example.com/x.jpg',
      );
      final restored = LesionRecord.fromRow(original.toRow());

      expect(restored.photoPath, '/data/local/x.jpg');
      expect(restored.photoUrl, 'https://example.com/x.jpg');
    });

    test('records written before uploads existed have no URL', () {
      final row = lesion(photoPath: '/data/local/x.jpg').toRow()
        ..remove('photo_url');
      final restored = LesionRecord.fromRow(row);

      expect(restored.photoUrl, isNull);
      expect(restored.hasUploadedPhoto, isFalse);
      expect(restored.hasLocalPhoto, isTrue);
    });

    test('copyWith can attach an upload URL to a saved lesion', () {
      final updated = lesion(
        photoPath: '/data/local/x.jpg',
      ).copyWith(photoUrl: 'https://example.com/new.jpg');

      expect(updated.photoUrl, 'https://example.com/new.jpg');
      expect(updated.photoPath, '/data/local/x.jpg');
    });
  });
}
