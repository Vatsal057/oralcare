import 'package:flutter_test/flutter_test.dart';
import 'package:oralcare/data/models/clinical_models.dart';

/// Clinical module spec section 5: attendance at the referral centre.
///
/// "Failed to arrive within two weeks" is derived from the referral date, so
/// these tests pin the boundary and the states that must NOT raise it.
void main() {
  final referred = DateTime(2026, 9, 1);

  ClinicianAssessmentRecord record({
    bool? referralRequired = true,
    DateTime? referralDate,
    DateTime? arrived,
    bool? reminded,
  }) => ClinicianAssessmentRecord(
    assessmentId: 1,
    patientId: 'OC-2026-ABC123',
    doctorUsername: 'dr.smith',
    updatedAt: referred,
    referralRequired: referralRequired,
    referralDate: referralDate,
    patientArrivedDate: arrived,
    patientRemindedByText: reminded,
  );

  group('the two-week attendance window', () {
    test('the window is two weeks from the referral date', () {
      final r = record(referralDate: referred);
      expect(r.attendanceDueBy, DateTime(2026, 9, 15));
      expect(ClinicianAssessmentRecord.attendanceWindowDays, 14);
    });

    test('day 13 has not failed yet', () {
      final r = record(referralDate: referred);
      expect(
        r.failedToArriveWithinTwoWeeks(now: DateTime(2026, 9, 14)),
        isFalse,
      );
    });

    test('exactly two weeks counts as failed to arrive', () {
      final r = record(referralDate: referred);
      expect(
        r.failedToArriveWithinTwoWeeks(now: DateTime(2026, 9, 15)),
        isTrue,
      );
    });

    test('after the window it stays failed', () {
      final r = record(referralDate: referred);
      expect(
        r.failedToArriveWithinTwoWeeks(now: DateTime(2026, 10, 1)),
        isTrue,
      );
    });
  });

  group('states that must not raise a non-attendance', () {
    test('a patient who arrived has not failed, even late', () {
      final r = record(
        referralDate: referred,
        arrived: DateTime(2026, 9, 20),
      );
      expect(r.patientArrived, isTrue);
      expect(
        r.failedToArriveWithinTwoWeeks(now: DateTime(2026, 10, 1)),
        isFalse,
      );
    });

    test('no referral means the rule does not apply', () {
      final r = record(referralRequired: false, referralDate: referred);
      expect(
        r.failedToArriveWithinTwoWeeks(now: DateTime(2026, 10, 1)),
        isFalse,
      );
    });

    test('an unanswered referral question does not raise it', () {
      final r = record(referralRequired: null, referralDate: referred);
      expect(
        r.failedToArriveWithinTwoWeeks(now: DateTime(2026, 10, 1)),
        isFalse,
      );
    });

    test('a referral with no date cannot start the clock', () {
      final r = record(referralDate: null);
      expect(r.attendanceDueBy, isNull);
      expect(
        r.failedToArriveWithinTwoWeeks(now: DateTime(2026, 10, 1)),
        isFalse,
      );
    });
  });

  group('chasing a non-attendance', () {
    test('an unchased non-attendance needs a reminder', () {
      final r = record(referralDate: referred);
      expect(
        r.needsAttendanceReminder(now: DateTime(2026, 9, 20)),
        isTrue,
      );
    });

    test('recording the reminder clears the outstanding action', () {
      final r = record(referralDate: referred, reminded: true);
      expect(
        r.failedToArriveWithinTwoWeeks(now: DateTime(2026, 9, 20)),
        isTrue,
        reason: 'the non-attendance itself remains true',
      );
      expect(
        r.needsAttendanceReminder(now: DateTime(2026, 9, 20)),
        isFalse,
        reason: 'but it no longer needs chasing',
      );
    });

    test('a patient who attended never needs chasing', () {
      final r = record(
        referralDate: referred,
        arrived: DateTime(2026, 9, 3),
      );
      expect(r.needsAttendanceReminder(now: DateTime(2026, 9, 20)), isFalse);
    });
  });

  group('persistence of the new spec fields', () {
    test('every section 3, 5 and 8 field survives a round trip', () {
      final original = ClinicianAssessmentRecord(
        assessmentId: 7,
        patientId: 'OC-2026-XYZ',
        doctorUsername: 'dr.smith',
        updatedAt: DateTime(2026, 9, 10),
        relevantMedicalHistory: 'Type 2 diabetes, on metformin',
        patientInformedByText: true,
        patientInformedDate: DateTime(2026, 9, 2),
        referralRequired: true,
        referralCentre: 'City Dental',
        referralDate: referred,
        patientArrivedDate: DateTime(2026, 9, 9),
        patientRemindedByText: true,
        patientReminderDate: DateTime(2026, 9, 16),
        patientInstructions: 'Attend on 20 Sep and bring this record.',
      );

      final restored = ClinicianAssessmentRecord.fromRow(original.toRow());

      expect(restored.relevantMedicalHistory, 'Type 2 diabetes, on metformin');
      expect(restored.patientInformedByText, isTrue);
      expect(restored.patientInformedDate, DateTime(2026, 9, 2));
      expect(restored.patientArrivedDate, DateTime(2026, 9, 9));
      expect(restored.patientRemindedByText, isTrue);
      expect(restored.patientReminderDate, DateTime(2026, 9, 16));
      expect(
        restored.patientInstructions,
        'Attend on 20 Sep and bring this record.',
      );
    });

    test('unanswered fields stay unanswered rather than becoming No', () {
      final restored = ClinicianAssessmentRecord.fromRow(record().toRow());
      expect(restored.patientInformedByText, isNull);
      expect(restored.patientRemindedByText, isNull);
      expect(restored.patientArrivedDate, isNull);
      expect(restored.relevantMedicalHistory, isNull);
      expect(restored.patientInstructions, isNull);
    });

    test('investigation and imaging reports survive a round trip', () {
      final original = OutcomeRecord(
        assessmentId: 7,
        patientId: 'OC-2026-XYZ',
        doctorUsername: 'dr.smith',
        updatedAt: DateTime(2026, 9, 10),
        investigationReports: 'OPG: no bone involvement. USG neck: normal.',
      );

      final restored = OutcomeRecord.fromRow(original.toRow());
      expect(
        restored.investigationReports,
        'OPG: no bone involvement. USG neck: normal.',
      );
      // Reports alone are not a reference outcome for validation.
      expect(restored.hasReferenceOutcome, isFalse);
    });
  });
}
