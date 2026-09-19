import 'package:flutter_test/flutter_test.dart';
import 'package:oralcare/data/models/app_user.dart';
import 'package:oralcare/data/models/assessment_models.dart';
import 'package:oralcare/data/models/patient_case.dart';
import 'package:oralcare/data/photo_document_store.dart';
import 'package:oralcare/domain/risk_engine.dart';

/// A device-local path is meaningless to anyone else, so the record distinguishes
/// "there is a photo on the phone that took it" from "there is a photo a
/// clinician can actually open". Confusing the two is what made photographs
/// invisible to clinicians before.
void main() {
  LesionRecord lesion({
    String? photoPath,
    String? photoUrl,
    bool photoInDatabase = false,
  }) => LesionRecord(
    id: 1,
    assessmentId: 7,
    patientId: 'OC-2026-ABC123',
    createdAt: DateTime(2026, 9, 19),
    photoPath: photoPath,
    photoUrl: photoUrl,
    photoInDatabase: photoInDatabase,
  );

  group('photo availability', () {
    test('no photo at all', () {
      final record = lesion();
      expect(record.hasPhoto, isFalse);
      expect(record.hasLocalPhoto, isFalse);
      expect(record.hasUploadedPhoto, isFalse);
      expect(record.hasDatabasePhoto, isFalse);
      expect(record.hasRemotePhoto, isFalse);
    });

    test('a local photo is not readable by a clinician', () {
      final record = lesion(photoPath: '/data/user/0/app/lesion_1.jpg');
      expect(record.hasPhoto, isTrue);
      expect(record.hasLocalPhoto, isTrue);
      expect(
        record.hasRemotePhoto,
        isFalse,
        reason: 'it never left the phone, so no clinician can open it',
      );
    });

    test('a photo held in the database is readable off-device', () {
      final record = lesion(
        photoPath: '/data/local/x.jpg',
        photoInDatabase: true,
      );
      expect(record.hasDatabasePhoto, isTrue);
      expect(record.hasRemotePhoto, isTrue);
      expect(record.hasPhoto, isTrue);
    });

    test('a legacy Storage URL still counts as readable', () {
      final record = lesion(photoUrl: 'https://example.com/a.jpg');
      expect(record.hasUploadedPhoto, isTrue);
      expect(record.hasRemotePhoto, isTrue);
      expect(record.hasPhoto, isTrue);
    });

    test('empty strings do not count as a photo', () {
      final record = lesion(photoPath: '', photoUrl: '');
      expect(record.hasPhoto, isFalse);
      expect(record.hasLocalPhoto, isFalse);
      expect(record.hasUploadedPhoto, isFalse);
      expect(record.hasRemotePhoto, isFalse);
    });
  });

  group('persistence', () {
    test('every photo form round trips', () {
      final original = lesion(
        photoPath: '/data/local/x.jpg',
        photoUrl: 'https://example.com/x.jpg',
        photoInDatabase: true,
      );
      final restored = LesionRecord.fromRow(original.toRow());

      expect(restored.photoPath, '/data/local/x.jpg');
      expect(restored.photoUrl, 'https://example.com/x.jpg');
      expect(restored.photoInDatabase, isTrue);
    });

    test('records written before uploads existed have no URL', () {
      final row = lesion(photoPath: '/data/local/x.jpg').toRow()
        ..remove('photo_url');
      final restored = LesionRecord.fromRow(row);

      expect(restored.photoUrl, isNull);
      expect(restored.hasUploadedPhoto, isFalse);
      expect(restored.hasLocalPhoto, isTrue);
    });

    test('records written before database photos existed do not claim one', () {
      final row = lesion(photoPath: '/data/local/x.jpg').toRow()
        ..remove('photo_in_database');
      final restored = LesionRecord.fromRow(row);

      expect(
        restored.hasDatabasePhoto,
        isFalse,
        reason: 'a missing flag must not make a screen fetch a document that '
            'was never written',
      );
    });

    test('copyWith can mark a saved lesion as stored', () {
      final updated = lesion(
        photoPath: '/data/local/x.jpg',
      ).copyWith(photoInDatabase: true);

      expect(updated.photoInDatabase, isTrue);
      expect(updated.photoPath, '/data/local/x.jpg');
    });
  });

  /// Firestore caps a document at 1 MiB. An oversized image is refused up front
  /// so the patient is told, rather than the write failing opaquely.
  group('document size limit', () {
    test('the ceiling stays under the Firestore document limit', () {
      expect(PhotoDocumentStore.maxBytes, lessThan(1048576));
    });

    test('a typical downscaled photo fits', () {
      expect(PhotoDocumentStore.isWithinLimit(140 * 1024), isTrue);
    });

    test('an oversized photo is refused', () {
      expect(
        PhotoDocumentStore.isWithinLimit(PhotoDocumentStore.maxBytes + 1),
        isFalse,
      );
    });

    test('an empty image is not a photo', () {
      expect(PhotoDocumentStore.isWithinLimit(0), isFalse);
    });
  });

  /// Withdrawing photograph consent has to cut every route to the image, not
  /// just the device-local one.
  group('consent stripping', () {
    PatientCase caseWith({required bool photographConsent}) => PatientCase(
      patient: AppUser(
        uid: 'patient-uid',
        username: 'testpatient',
        role: UserRole.patient,
        patientId: 'OC-2026-ABC123',
        createdAt: DateTime(2026, 9, 1),
        consent: ConsentFlags(
          appAndSelfExam: true,
          photograph: photographConsent,
          shareWithDoctor: true,
        ),
      ),
      assessment: RiskAssessmentRecord(
        patientId: 'OC-2026-ABC123',
        createdAt: DateTime(2026, 9, 19),
        answers: const {},
        result: const RiskResult(
          totalScore: 0,
          category: RiskCategory.lower,
          outputState: PatientOutputState.lowerRisk,
          redFlagPresent: false,
          redFlagKeys: [],
          lesionPersistent: false,
          previousOscc: false,
          professionalCheckRequired: false,
          referralAlert: false,
          unknownAnswerKeys: [],
          reasons: [],
          scoreBreakdown: {},
        ),
      ),
      lesions: [
        lesion(
          photoPath: '/data/local/x.jpg',
          photoUrl: 'https://example.com/x.jpg',
          photoInDatabase: true,
        ),
      ],
    );

    test('with consent, the photograph is left intact', () {
      final viewable = caseWith(photographConsent: true).viewableLesions.single;
      expect(viewable.hasRemotePhoto, isTrue);
      expect(viewable.hasLocalPhoto, isTrue);
    });

    test('without consent, no route to the photograph survives', () {
      final viewable = caseWith(photographConsent: false).viewableLesions.single;
      expect(viewable.hasPhoto, isFalse);
      expect(viewable.hasLocalPhoto, isFalse);
      expect(viewable.hasUploadedPhoto, isFalse);
      expect(
        viewable.hasDatabasePhoto,
        isFalse,
        reason: 'the copy in the database is readable off-device, so clearing '
            'only the local path would leak it',
      );
    });
  });
}
