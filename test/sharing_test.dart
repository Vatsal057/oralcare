import 'package:flutter_test/flutter_test.dart';
import 'package:oralcare/data/models/assessment_models.dart';
import 'package:oralcare/data/models/doctor_summary.dart';
import 'package:oralcare/domain/risk_engine.dart';

/// Sharing is addressed to one clinician. These tests pin the invariants the
/// Firestore rules depend on: a record is only visible when it is both switched
/// on and names a recipient.
void main() {
  RiskAssessmentRecord record({bool shared = false, String? sharedWithUid}) =>
      RiskAssessmentRecord(
        patientId: 'OC-2026-ABC123',
        createdAt: DateTime(2026, 9, 8),
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
        sharedWithDoctor: shared,
        sharedWithUid: sharedWithUid,
      );

  group('addressed sharing', () {
    test('a new assessment is not shared with anyone', () {
      final fresh = record();
      expect(fresh.sharedWithDoctor, isFalse);
      expect(fresh.sharedWithUid, isNull);
      expect(fresh.isSharedWithSomeone, isFalse);
    });

    test('the flag alone does not expose a record', () {
      expect(record(shared: true).isSharedWithSomeone, isFalse);
    });

    test('a recipient alone does not expose a record', () {
      expect(
        record(sharedWithUid: 'doctor-uid-1').isSharedWithSomeone,
        isFalse,
      );
    });

    test('both flag and recipient make it visible to that clinician', () {
      final sent = record(shared: true, sharedWithUid: 'doctor-uid-1');
      expect(sent.isSharedWithSomeone, isTrue);
      expect(sent.sharedWithUid, 'doctor-uid-1');
    });

    test('an empty recipient string is not a recipient', () {
      expect(
        record(shared: true, sharedWithUid: '').isSharedWithSomeone,
        isFalse,
      );
    });
  });

  group('persistence', () {
    test('the recipient survives a storage round trip', () {
      final original = record(shared: true, sharedWithUid: 'doctor-uid-9');
      final restored = RiskAssessmentRecord.fromRow(original.toRow());

      expect(restored.sharedWithUid, 'doctor-uid-9');
      expect(restored.sharedWithDoctor, isTrue);
      expect(restored.isSharedWithSomeone, isTrue);
    });

    test('a record with no recipient round trips as unshared', () {
      final restored = RiskAssessmentRecord.fromRow(record().toRow());
      expect(restored.sharedWithUid, isNull);
      expect(restored.isSharedWithSomeone, isFalse);
    });

    test('legacy rows without the field are not visible to any clinician', () {
      // Records written before addressed sharing carry shared_with_doctor == 1
      // but no recipient. They must not appear in anyone's queue.
      final row = record(shared: true).toRow()..remove('shared_with_uid');
      final restored = RiskAssessmentRecord.fromRow(row);

      expect(restored.sharedWithDoctor, isTrue);
      expect(restored.sharedWithUid, isNull);
      expect(restored.isSharedWithSomeone, isFalse);
    });
  });

  group('changing the recipient', () {
    test('copyWith can re-address a record to a different clinician', () {
      final sent = record(shared: true, sharedWithUid: 'doctor-a');
      final moved = sent.copyWith(sharedWithUid: 'doctor-b');

      expect(moved.sharedWithUid, 'doctor-b');
      expect(moved.isSharedWithSomeone, isTrue);
    });

    test('clearing the recipient withdraws the record', () {
      final sent = record(shared: true, sharedWithUid: 'doctor-a');
      final withdrawn = sent.copyWith(
        sharedWithDoctor: false,
        clearSharedWithUid: true,
      );

      expect(withdrawn.sharedWithUid, isNull);
      expect(withdrawn.isSharedWithSomeone, isFalse);
    });

    test('an unrelated copyWith keeps the recipient', () {
      final sent = record(shared: true, sharedWithUid: 'doctor-a');
      expect(sent.copyWith(id: 42).sharedWithUid, 'doctor-a');
    });
  });

  group('directory entries', () {
    test('the full name is preferred over the username', () {
      const doctor = DoctorSummary(
        uid: 'u1',
        username: 'dr.smith',
        fullName: 'Dr A Smith',
        clinic: 'City Dental',
      );
      expect(doctor.displayName, 'Dr A Smith');
      expect(doctor.subtitle, 'City Dental');
    });

    test('the username is used when no name is listed', () {
      const doctor = DoctorSummary(uid: 'u1', username: 'dr.smith');
      expect(doctor.displayName, 'dr.smith');
      // No clinic and no distinct name leaves nothing useful to add.
      expect(doctor.subtitle, isNull);
    });

    test('a blank name falls back to the username', () {
      const doctor = DoctorSummary(
        uid: 'u1',
        username: 'dr.smith',
        fullName: '   ',
      );
      expect(doctor.displayName, 'dr.smith');
    });
  });
}
