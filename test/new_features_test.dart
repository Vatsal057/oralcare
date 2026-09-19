import 'package:flutter_test/flutter_test.dart';
import 'package:oralcare/data/models/app_user.dart';
import 'package:oralcare/data/repositories/cessation_repository.dart';
import 'package:oralcare/data/repositories/digilocker_repository.dart';
import 'package:oralcare/domain/cessation/cessation_models.dart';
import 'package:oralcare/domain/education/education_catalog.dart';
import 'package:oralcare/domain/education/education_models.dart';
import 'package:oralcare/domain/records/digilocker_models.dart';
import 'package:oralcare/domain/referral/screening_centers_catalog.dart';
import 'package:oralcare/domain/rehabilitation/rehabilitation_catalog.dart';
import 'package:oralcare/state/session_controller.dart';

void main() {
  group('Education Module (Section 2)', () {
    test('catalog contains all core educational topics', () {
      expect(EducationCatalog.topics.length, greaterThanOrEqualTo(7));
      expect(EducationCatalog.mythsAndFacts.length, greaterThanOrEqualTo(5));
      expect(EducationCatalog.faqs.length, greaterThanOrEqualTo(5));
    });

    test('supports English, Hindi, and Kannada without nulls', () {
      for (final topic in EducationCatalog.topics) {
        for (final lang in EducationLanguage.values) {
          final title = topic.title(lang);
          final summary = topic.summary(lang);
          final sections = topic.sections(lang);

          expect(title.isNotEmpty, isTrue);
          expect(summary.isNotEmpty, isTrue);
          expect(sections.isNotEmpty, isTrue);
        }
      }
    });
  });

  group('Medical Records DigiLocker (Section 7 & Part 2)', () {
    test('supports all 13 categories and survives serialization', () {
      expect(DigiLockerCategory.values.length, 13);

      for (final cat in DigiLockerCategory.values) {
        final record = DigiLockerRecord(
          id: 'test_${cat.name}',
          patientId: 'P123',
          title: 'Test ${cat.label}',
          category: cat,
          facilityOrDoctor: 'Test Hospital',
          documentDate: DateTime(2026, 9, 15),
          notes: 'Test note',
          isSharedWithClinician: true,
          createdAt: DateTime(2026, 9, 15),
        );

        final json = record.toJson();
        final roundTrip = DigiLockerRecord.fromJson(json);

        expect(roundTrip.category, cat);
        expect(roundTrip.title, record.title);
        expect(roundTrip.isSharedWithClinician, isTrue);
      }
    });

    test(
      'DigiLockerRepository handles add, list, toggle sharing, and delete',
      () async {
        final repo = DigiLockerRepository();
        const patientId = 'P_TEST_REPO';

        final doc1 = DigiLockerRecord(
          id: 'doc1',
          patientId: patientId,
          title: 'Biopsy Report',
          category: DigiLockerCategory.biopsyHistopathology,
          facilityOrDoctor: 'CIDS Coorg',
          documentDate: DateTime(2026, 9, 10),
          isSharedWithClinician: false,
          createdAt: DateTime(2026, 9, 10),
        );

        await repo.saveRecord(doc1);
        var records = await repo.getRecordsForPatient(patientId);
        expect(records.length, 1);
        expect(records.first.title, 'Biopsy Report');
        expect(records.first.isSharedWithClinician, isFalse);

        // Toggle sharing
        await repo.toggleSharing(
          patientId: patientId,
          recordId: 'doc1',
          isShared: true,
        );
        records = await repo.getRecordsForPatient(patientId);
        expect(records.first.isSharedWithClinician, isTrue);

        // Delete
        await repo.deleteRecord(patientId: patientId, recordId: 'doc1');
        records = await repo.getRecordsForPatient(patientId);
        expect(records.isEmpty, isTrue);
      },
    );
  });

  group('Cessation & Habit-Change Hub (Section 8)', () {
    test('calculates streak, units avoided, and money saved accurately', () {
      final quitDate = DateTime.now().subtract(
        const Duration(days: 10, hours: 4),
      );
      final plan = QuitPlan(
        quitDate: quitDate,
        habitTypes: ['Smokeless Tobacco / Gutkha'],
        dailyUnits: 6,
        costPerUnit: 15.0,
      );

      expect(plan.daysQuit, 10);
      expect(plan.hoursQuit, 4);
      expect(plan.unitsAvoided, 61); // ~10.16 days * 6
      expect(plan.moneySaved, 61 * 15.0);
    });

    test('health milestones detect achieved status based on quit duration', () {
      const ms20Min = Duration(minutes: 20);
      const ms1Year = Duration(days: 365);

      final m1 = CessationCatalog.milestones.first;
      final mFinal = CessationCatalog.milestones.last;

      expect(m1.isAchieved(ms20Min), isTrue);
      expect(m1.isAchieved(const Duration(minutes: 10)), isFalse);

      expect(mFinal.isAchieved(ms1Year), isTrue);
      expect(mFinal.isAchieved(const Duration(days: 300)), isFalse);
    });

    test('CessationRepository stores quit plan and logs cravings', () async {
      final repo = CessationRepository();
      const patientId = 'P_CESS_TEST';

      final plan = QuitPlan(
        quitDate: DateTime.now().subtract(const Duration(days: 3)),
        habitTypes: ['Bidi'],
        dailyUnits: 10,
        costPerUnit: 5.0,
      );

      await repo.saveQuitPlan(patientId: patientId, plan: plan);
      final retrieved = await repo.getQuitPlan(patientId);
      expect(retrieved, isNotNull);
      expect(retrieved!.dailyUnits, 10);

      // Log craving
      final craving = CravingEntry(
        id: 'c1',
        timestamp: DateTime.now(),
        trigger: CravingTrigger.stress,
        intensity: 4,
        resisted: true,
      );
      await repo.logCraving(patientId: patientId, entry: craving);

      final withCraving = await repo.getQuitPlan(patientId);
      expect(withCraving!.cravingLogs.length, 1);
      expect(withCraving.cravingLogs.first.trigger, CravingTrigger.stress);
    });
  });

  group('Referral Directory & Referral Letter (Section 6)', () {
    test(
      'screening centers catalog contains verified dental & oncology institutes',
      () {
        expect(ScreeningCentersCatalog.centers.length, greaterThanOrEqualTo(4));
        final names = ScreeningCentersCatalog.centers
            .map((c) => c.name)
            .toList();
        expect(
          names.any((n) => n.contains('Coorg Institute of Dental Sciences')),
          isTrue,
        );
        expect(names.any((n) => n.contains('Kidwai')), isTrue);
      },
    );

    test('referral letter generator formats clinical referral slip', () {
      final letter = ScreeningCentersCatalog.generateReferralLetter(
        patientName: 'Ramesh Kumar',
        patientId: 'PAT-9942',
        age: 52,
        gender: 'Male',
        result: null,
        lesionSite: 'Lateral tongue',
        lesionDurationDays: 21,
        reportedSymptoms: ['Non-healing ulcer', 'Persistent pain'],
      );

      expect(
        letter.contains('ORAL CANCER CARECONNECT — CLINICAL REFERRAL SLIP'),
        isTrue,
      );
      expect(letter.contains('Ramesh Kumar'), isTrue);
      expect(letter.contains('PAT-9942'), isTrue);
      expect(letter.contains('Lateral tongue'), isTrue);
      expect(letter.contains('21 days'), isTrue);
      expect(letter.contains('CLINICAL SAFETY DISCLAIMER'), isTrue);
    });
  });

  group('Rehabilitation Protocols (WHATS-GOING-ON Part 3)', () {
    test(
      'contains tailored protocols for Surgery, Radiotherapy, and Chemo',
      () {
        expect(
          RehabilitationCatalog.protocols.containsKey(
            TreatmentModality.surgeryOnly,
          ),
          isTrue,
        );
        expect(
          RehabilitationCatalog.protocols.containsKey(
            TreatmentModality.surgeryRadiotherapy,
          ),
          isTrue,
        );
        expect(
          RehabilitationCatalog.protocols.containsKey(
            TreatmentModality.surgeryChemoRadiotherapy,
          ),
          isTrue,
        );

        final rtProtocol = RehabilitationCatalog
            .protocols[TreatmentModality.surgeryRadiotherapy]!;
        expect(rtProtocol.hydrationReminderHours, inInclusiveRange(2, 3));
        expect(
          rtProtocol.specialInstructions.any((s) => s.contains('XEROSTOMIA')),
          isTrue,
        );

        final chemoProtocol = RehabilitationCatalog
            .protocols[TreatmentModality.surgeryChemoRadiotherapy]!;
        expect(
          chemoProtocol.specialInstructions.any(
            (s) => s.contains('INFECTION ALERT'),
          ),
          isTrue,
        );
      },
    );
  });

  group('Guest-Information Mode (Section 1)', () {
    test('SessionController continueAsGuest creates guest user profile', () {
      final controller = SessionController();
      expect(controller.user, isNull);

      controller.continueAsGuest();
      expect(controller.user, isNotNull);
      expect(controller.user!.isGuest, isTrue);
      expect(controller.user!.role, UserRole.patient);
      expect(controller.user!.canProceed, isTrue);
    });
  });
}
