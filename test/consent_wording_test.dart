import 'package:flutter_test/flutter_test.dart';
import 'package:oralcare/core/clinical_notices.dart';

/// Consent wording is a correctness surface, not copy.
///
/// Three of these strings sit on or above the consent form, and all three went
/// stale when records moved from device-local storage into Firestore: they told
/// the patient nothing was uploaded and that photographs stayed on the phone,
/// while the app was in fact writing both to the database. A patient cannot
/// consent to something the form misdescribes, so these tests pin the claims
/// that must never reappear and the facts that must stay stated.
void main() {
  /// Claims that were true before the Firestore migration and are now false.
  /// Any of them reappearing means the consent form is lying again.
  const forbidden = <String>[
    'stored on this device only',
    'Nothing is uploaded',
    'stay on this device',
    'stays on this device',
  ];

  group('storage notice describes what actually happens', () {
    test('does not claim records stay on the device', () {
      for (final claim in forbidden) {
        expect(
          ClinicalNotices.storageNotice.toLowerCase(),
          isNot(contains(claim.toLowerCase())),
          reason: 'records are written to Firestore, so "$claim" is untrue',
        );
      }
    });

    test('says records are saved to the account and encrypted', () {
      final notice = ClinicalNotices.storageNotice.toLowerCase();
      expect(notice, contains('account'));
      expect(notice, contains('encrypted'));
    });

    test('still discloses the protections this pilot lacks', () {
      final notice = ClinicalNotices.storageNotice.toLowerCase();
      expect(
        notice,
        contains('audit'),
        reason: 'someone sharing a clinical record must be told there is no '
            'record of who opened it',
      );
      expect(notice, contains('backup'));
    });
  });

  group('photograph consent describes where the photograph goes', () {
    test('does not promise the photograph stays on the phone', () {
      for (final claim in forbidden) {
        expect(
          ClinicalNotices.consentPhotoDetail.toLowerCase(),
          isNot(contains(claim.toLowerCase())),
          reason: 'the photograph is written to Firestore as soon as this '
              'consent is granted, regardless of sharing',
        );
      }
    });

    test('says it is saved to the account', () {
      expect(
        ClinicalNotices.consentPhotoDetail.toLowerCase(),
        contains('account'),
      );
    });

    test('keeps the assurance that sharing is a separate decision', () {
      expect(
        ClinicalNotices.consentPhotoDetail.toLowerCase(),
        contains('unless'),
        reason: 'granting photograph consent must not read as granting a '
            'clinician access to the photograph',
      );
    });
  });

  group('sharing consent describes who can read the record', () {
    test('does not imply any doctor using the app can see it', () {
      expect(
        ClinicalNotices.consentShareDetail,
        isNot(contains('a doctor using this app')),
        reason: 'sharing is addressed to one chosen clinician, not broadcast',
      );
    });

    test('says the chosen doctor only', () {
      final detail = ClinicalNotices.consentShareDetail.toLowerCase();
      expect(detail, contains('choose'));
      expect(detail, contains('only the doctor'));
    });

    test('discloses the coordinator', () {
      expect(
        ClinicalNotices.consentShareDetail.toLowerCase(),
        contains('coordinator'),
        reason: 'a shared record is readable cohort-wide by the pilot '
            'coordinator, which the patient has to be told about',
      );
    });

    test('states that it can be withdrawn', () {
      expect(
        ClinicalNotices.consentShareDetail.toLowerCase(),
        contains('withdraw'),
      );
    });
  });

  /// The no-diagnosis boundary is the one piece of wording the class doc calls
  /// out as not removable. Guard it too while we are here.
  group('safety boundary wording survives', () {
    test('the no-diagnosis notice still says it does not diagnose', () {
      expect(
        ClinicalNotices.noDiagnosis.toLowerCase(),
        contains('does not diagnose'),
      );
    });

    test('scores are still declared provisional', () {
      expect(
        ClinicalNotices.provisionalScores.toLowerCase(),
        contains('provisional'),
      );
    });
  });
}
