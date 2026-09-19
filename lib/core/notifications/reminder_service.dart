import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// The kinds of reminder the specification asks for (Section I).
///
/// Each carries a stable numeric id range so a reminder can be replaced or
/// cancelled without touching the others.
enum ReminderKind {
  selfExamination,
  dentalCheckUp,
  followUpVisit,
  biopsyAppointment,
  medication,
  investigation,
  treatmentSession,
  cessationMilestone,
}

extension ReminderKindX on ReminderKind {
  String get title => switch (this) {
    ReminderKind.selfExamination => 'Time for your mouth self-check',
    ReminderKind.dentalCheckUp => 'Dental check-up due',
    ReminderKind.followUpVisit => 'Follow-up visit due',
    ReminderKind.biopsyAppointment => 'Biopsy appointment',
    ReminderKind.medication => 'Medication reminder',
    ReminderKind.investigation => 'Investigation due',
    ReminderKind.treatmentSession => 'Treatment session',
    ReminderKind.cessationMilestone => 'Quit-plan milestone',
  };

  /// Base id, so ids stay stable and collision-free across kinds.
  int get idBase => (index + 1) * 1000;
}

/// Schedules local reminders on Android.
///
/// Deliberately does nothing anywhere else. The plugin has no web
/// implementation, so an unguarded call throws MissingPluginException in the
/// browser; iOS is untested for this pilot. Every method reports whether it
/// actually did anything, so the UI can tell the patient the truth instead of
/// implying a reminder was set.
class ReminderService {
  ReminderService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialised = false;
  bool _permissionGranted = false;

  /// True only where scheduling can work at all.
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get isReady => _initialised && _permissionGranted;
  bool get permissionGranted => _permissionGranted;

  static const _channel = AndroidNotificationChannel(
    'oralcare_reminders',
    'OralCare reminders',
    description:
        'Self-examination, check-up, follow-up and medication reminders.',
    importance: Importance.defaultImportance,
  );

  /// Prepares the plugin and asks for permission. Safe to call more than once.
  Future<bool> initialise() async {
    if (!isSupported) return false;
    if (_initialised) return _permissionGranted;

    try {
      tzdata.initializeTimeZones();
      // The pilot runs in India. A general release should read the device zone
      // (for example with flutter_timezone) instead of assuming one.
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );

      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(_channel);
      // Android 13+ requires explicit consent. Refusal is a valid answer.
      _permissionGranted =
          await android?.requestNotificationsPermission() ?? false;
      _initialised = true;
      return _permissionGranted;
    } catch (_) {
      // A missing plugin or unavailable timezone must never break app start-up.
      _initialised = false;
      _permissionGranted = false;
      return false;
    }
  }

  /// Schedules a one-off reminder. Returns false when nothing was scheduled.
  Future<bool> scheduleOnce({
    required ReminderKind kind,
    required DateTime when,
    String? body,
    int offset = 0,
  }) async {
    if (!isSupported) return false;
    if (!_initialised) await initialise();
    if (!_permissionGranted) return false;

    // A reminder in the past would either fire immediately or be dropped.
    if (!when.isAfter(DateTime.now())) return false;

    try {
      await _plugin.zonedSchedule(
        kind.idBase + offset,
        kind.title,
        body ?? 'Open OralCare when you have a moment.',
        tz.TZDateTime.from(when, tz.local),
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
          ),
        ),
        // Inexact on purpose: exact alarms need a special permission on
        // Android 13+ and are not warranted for a check-up reminder.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Monthly self-examination reminder (Section I).
  Future<bool> scheduleMonthlySelfExam({DateTime? from}) async {
    final start = from ?? DateTime.now();
    return scheduleOnce(
      kind: ReminderKind.selfExamination,
      when: DateTime(start.year, start.month + 1, start.day, 9),
      body:
          'Check your lips, cheeks, gums, tongue and neck. It takes 2 minutes.',
    );
  }

  /// Reminder a few days before a dated appointment or follow-up.
  Future<bool> scheduleAhead({
    required ReminderKind kind,
    required DateTime date,
    int daysBefore = 2,
    String? body,
    int offset = 0,
  }) async {
    final when = DateTime(
      date.year,
      date.month,
      date.day,
      9,
    ).subtract(Duration(days: daysBefore));
    return scheduleOnce(
      kind: kind,
      when: when.isAfter(DateTime.now()) ? when : date,
      body: body,
      offset: offset,
    );
  }

  Future<void> cancel(ReminderKind kind, {int offset = 0}) async {
    if (!isSupported) return;
    try {
      await _plugin.cancel(kind.idBase + offset);
    } catch (_) {
      // Nothing to cancel is not an error worth surfacing.
    }
  }

  Future<void> cancelAll() async {
    if (!isSupported) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// What is currently scheduled, for the reminders screen.
  Future<List<PendingNotificationRequest>> pending() async {
    if (!isSupported) return const [];
    try {
      return await _plugin.pendingNotificationRequests();
    } catch (_) {
      return const [];
    }
  }
}
