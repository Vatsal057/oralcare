import 'package:flutter_test/flutter_test.dart';
import 'package:oralcare/core/notifications/reminder_service.dart';

/// Reminders are optional and best-effort. The property that matters is that no
/// scheduling call can ever throw into the UI or silently claim success: there is
/// no notification plugin in a unit test, which is the same situation as a
/// browser or a device where the user refused permission.
void main() {
  group('reminder identity', () {
    test('every kind has a distinct id base', () {
      final bases = ReminderKind.values.map((k) => k.idBase).toList();
      expect(bases.toSet().length, bases.length);
    });

    test('id bases leave room for multiple reminders of one kind', () {
      final sorted = ReminderKind.values.map((k) => k.idBase).toList()..sort();
      for (var i = 1; i < sorted.length; i++) {
        expect(
          sorted[i] - sorted[i - 1],
          greaterThanOrEqualTo(1000),
          reason: 'offsets would collide with the next kind',
        );
      }
    });

    test('every kind has a title a patient can understand', () {
      for (final kind in ReminderKind.values) {
        expect(kind.title.trim(), isNotEmpty, reason: kind.name);
        expect(kind.title, isNot(contains('_')), reason: kind.name);
      }
    });

    test('the spec reminder types are all represented', () {
      final names = ReminderKind.values.map((k) => k.name);
      expect(
        names,
        containsAll([
          'selfExamination',
          'dentalCheckUp',
          'followUpVisit',
          'biopsyAppointment',
          'medication',
          'investigation',
          'treatmentSession',
          'cessationMilestone',
        ]),
      );
    });
  });

  group('failing safely without a platform', () {
    test('scheduling reports false instead of throwing', () async {
      final service = ReminderService();

      await expectLater(
        service.scheduleOnce(
          kind: ReminderKind.followUpVisit,
          when: DateTime.now().add(const Duration(days: 3)),
        ),
        completion(isFalse),
      );
    });

    test('a reminder in the past is refused', () async {
      final service = ReminderService();

      expect(
        await service.scheduleOnce(
          kind: ReminderKind.medication,
          when: DateTime.now().subtract(const Duration(days: 1)),
        ),
        isFalse,
      );
    });

    test('the monthly self-check schedule call is safe', () async {
      expect(await ReminderService().scheduleMonthlySelfExam(), isFalse);
    });

    test('scheduleAhead is safe and never throws', () async {
      expect(
        await ReminderService().scheduleAhead(
          kind: ReminderKind.biopsyAppointment,
          date: DateTime.now().add(const Duration(days: 10)),
        ),
        isFalse,
      );
    });

    test('cancelling and listing never throw', () async {
      final service = ReminderService();

      await expectLater(service.cancel(ReminderKind.medication), completes);
      await expectLater(service.cancelAll(), completes);
      expect(await service.pending(), isEmpty);
    });

    test('an unprepared service is not reported as ready', () {
      final service = ReminderService();
      expect(service.isReady, isFalse);
      expect(service.permissionGranted, isFalse);
    });
  });
}
