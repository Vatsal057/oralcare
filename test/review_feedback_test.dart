import 'package:flutter_test/flutter_test.dart';
import 'package:oralcare/core/theme.dart';
import 'package:oralcare/data/digilocker_file_store.dart';
import 'package:oralcare/data/image_document_store.dart';
import 'package:oralcare/data/photo_document_store.dart';
import 'package:oralcare/domain/records/digilocker_models.dart';
import 'package:oralcare/domain/risk_catalog.dart';
import 'package:oralcare/domain/risk_engine.dart';

/// Covers the four changes requested at clinical review:
///  1. illustrations were being cropped
///  2. the provisional score needed red / yellow / green flags
///  3. referral and follow-up reminders had to be reachable from a result
///  4. the DigiLocker had to actually store pictures
///
/// Items 1 and 3 are layout and navigation, verified by build and by hand. What
/// is pinned here is the logic underneath 2 and 4, where a wrong answer is
/// clinically misleading rather than merely ugly.
void main() {
  group('risk flags map to the right colour', () {
    test('bands get green, yellow and red in order', () {
      expect(RiskFlag.forCategory(RiskCategory.lower), RiskFlag.green);
      expect(RiskFlag.forCategory(RiskCategory.increased), RiskFlag.yellow);
      expect(RiskFlag.forCategory(RiskCategory.higher), RiskFlag.red);
    });

    test('an urgent output is a red flag', () {
      expect(
        RiskFlag.forState(PatientOutputState.professionalCheckRequired),
        RiskFlag.red,
      );
      expect(RiskFlag.forState(PatientOutputState.higherRisk), RiskFlag.red);
    });

    test('observe-and-review is yellow, not green', () {
      expect(
        RiskFlag.forState(PatientOutputState.observeAndReview),
        RiskFlag.yellow,
        reason: 'a finding was recorded, so it cannot read as all-clear',
      );
    });

    test('only a lower-risk output is green', () {
      final green = PatientOutputState.values
          .where((s) => RiskFlag.forState(s) == RiskFlag.green)
          .toList();
      expect(green, [PatientOutputState.lowerRisk]);
    });

    /// The override is the case where the band and the output disagree, and it
    /// is the one that matters: a red-flag finding on a score of 2 must not be
    /// presented to the patient as a green flag.
    test('an override outranks a low score band', () {
      final result = RiskEngine.evaluate(
        age: 25,
        answers: {
          for (final v in RiskCatalog.askedVariables) v.key: null,
          RiskKeys.suspiciousLesion: AnswerValues.yes,
          RiskKeys.lesionDuration: AnswerValues.twoWeeksOrMore,
        },
        redFlagKeys: const {'non_healing_ulcer'},
      );

      expect(result.category, RiskCategory.lower, reason: 'score is low');
      expect(result.professionalCheckRequired, isTrue);
      expect(
        RiskFlag.forCategory(result.category),
        RiskFlag.green,
        reason: 'the numerical band on its own is green',
      );
      expect(
        RiskFlag.forState(result.outputState),
        RiskFlag.red,
        reason: 'what the patient is shown must be red despite the green band',
      );
    });

    test('every flag carries a text label and an action', () {
      for (final flag in RiskFlag.values) {
        expect(flag.label, isNotEmpty);
        expect(
          flag.meaning,
          isNotEmpty,
          reason: 'colour alone cannot carry the meaning',
        );
      }
    });
  });

  group('band ranges are derived from the cut-offs', () {
    test('the ranges match the configured thresholds', () {
      expect(RiskCategory.lower.rangeLabel, '0 to 4');
      expect(RiskCategory.increased.rangeLabel, '5 to 9');
      expect(RiskCategory.higher.rangeLabel, '10 or more');
    });

    test('the ranges are contiguous and cover every score', () {
      expect(RiskCatalog.lowerRiskMaxScore + 1, 5);
      expect(RiskCatalog.increasedRiskMaxScore + 1, 10);
      for (var score = 0; score <= RiskCatalog.maxPossibleScore; score++) {
        expect(RiskEngine.categoryForScore(score), isNotNull);
      }
    });
  });

  group('DigiLocker stores pictures, not just paths', () {
    DigiLockerRecord record({
      String? localFilePath,
      bool hasStoredImage = false,
    }) => DigiLockerRecord(
      id: 'doc_1',
      patientId: 'OC-2026-ABC123',
      title: 'Incisional Biopsy Report',
      category: DigiLockerCategory.biopsyHistopathology,
      facilityOrDoctor: 'Coorg Dental College',
      documentDate: DateTime(2026, 9, 20),
      localFilePath: localFilePath,
      hasStoredImage: hasStoredImage,
      createdAt: DateTime(2026, 9, 20),
    );

    test('a device-local path is not a viewable image', () {
      final doc = record(localFilePath: '/data/user/0/app/report.jpg');
      expect(
        doc.hasViewableImage,
        isFalse,
        reason: 'the path resolves to nothing on any other device, which is '
            'what made stored documents appear empty',
      );
    });

    test('a stored image is viewable', () {
      expect(record(hasStoredImage: true).hasViewableImage, isTrue);
    });

    test('the stored-image flag round trips', () {
      final restored = DigiLockerRecord.fromJson(
        record(hasStoredImage: true).toJson(),
      );
      expect(restored.hasStoredImage, isTrue);
      expect(restored.hasViewableImage, isTrue);
    });

    test('records saved before image storage existed do not claim one', () {
      final json = record(localFilePath: '/data/local/x.jpg').toJson()
        ..remove('has_image');
      final restored = DigiLockerRecord.fromJson(json);

      expect(
        restored.hasStoredImage,
        isFalse,
        reason: 'a missing flag must not make a viewer fetch a document that '
            'was never written',
      );
    });

    test('copyWith can mark the image as stored', () {
      expect(record().copyWith(hasStoredImage: true).hasStoredImage, isTrue);
    });

    test('the clinical photograph category exists for filed pictures', () {
      expect(
        DigiLockerCategory.clinicalPhoto.label,
        'Clinical Photograph',
      );
    });
  });

  /// Both image stores share one limit. Letting them drift would mean an image
  /// accepted in one place and silently refused in the other.
  group('image size limit is shared', () {
    test('the ceiling is under the Firestore document limit', () {
      expect(ImageDocumentStore.maxBytes, lessThan(1048576));
    });

    test('lesion photographs and locker files use the same ceiling', () {
      expect(PhotoDocumentStore.maxBytes, ImageDocumentStore.maxBytes);
      expect(DigiLockerFileStore.maxBytes, ImageDocumentStore.maxBytes);
    });

    test('the limit check agrees across both stores', () {
      const oversize = ImageDocumentStore.maxBytes + 1;
      expect(PhotoDocumentStore.isWithinLimit(oversize), isFalse);
      expect(DigiLockerFileStore.isWithinLimit(oversize), isFalse);
      expect(PhotoDocumentStore.isWithinLimit(120 * 1024), isTrue);
      expect(DigiLockerFileStore.isWithinLimit(120 * 1024), isTrue);
    });

    test('an empty image is never stored', () {
      expect(ImageDocumentStore.isWithinLimit(0), isFalse);
    });
  });
}
