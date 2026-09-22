import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import '../../core/notifications/reminder_service.dart';
import '../../core/load_guard.dart';
import '../../core/widgets/common.dart';
import '../../data/models/assessment_models.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/assessment_repository.dart';
import '../../domain/referral/appointment_request.dart';
import '../../domain/risk_engine.dart';
import '../../state/session_controller.dart';

/// Reminders (Section I).
///
/// Notifications are optional and must be asked for. Where the platform cannot
/// deliver them — the browser, or a device where the user declined — the screen
/// says so plainly rather than pretending a reminder was set.
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  bool _loading = true;
  bool _granted = false;
  int _scheduledCount = 0;
  List<RiskAssessmentRecord> _followUps = const [];
  List<AppointmentRequest> _visits = const [];
  String? _message;

  ReminderService get _service => context.read<ReminderService>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final user = context.read<SessionController>().requireUser;
    final patientId = user.patientId ?? 'GUEST';

    // Resolved before any await: reading a provider off a stale context after an
    // async gap is unsafe if the screen has been popped meanwhile.
    final assessments = context.read<AssessmentRepository>();
    final appointments = context.read<AppointmentRepository>();

    // Every await here is guarded independently, and each has a safe default.
    // The notification plugin calls sat outside the try before, so a plugin that
    // threw or never answered left the spinner turning on a screen whose whole
    // job is to tell the patient plainly whether reminders are on.
    var granted = false;
    try {
      granted = _service.isReady
          ? true
          : await LoadGuard.run(
              _service.initialise(),
              limit: const Duration(seconds: 8),
            );
    } catch (_) {
      // Treated as "not permitted", which is what the screen already explains
      // how to fix.
    }

    List<RiskAssessmentRecord> followUps = const [];
    List<AppointmentRequest> visits = const [];
    try {
      followUps = await LoadGuard.run(
        assessments.pendingFollowUps(patientId),
      );
      visits = await LoadGuard.run(appointments.listForPatient(patientId));
    } catch (_) {
      // The reminder controls still work without the lists.
    }

    var pending = const <PendingNotificationRequest>[];
    try {
      pending = await LoadGuard.run(
        _service.pending(),
        limit: const Duration(seconds: 8),
      );
    } catch (_) {
      // Count shows as zero rather than blocking the screen.
    }

    if (!mounted) return;
    setState(() {
      _granted = granted;
      _scheduledCount = pending.length;
      _followUps = followUps;
      _visits = visits.where((v) => v.isOpen).toList(growable: false);
      _loading = false;
    });
  }

  Future<void> _scheduleAll() async {
    var scheduled = 0;

    if (await _service.scheduleMonthlySelfExam()) scheduled++;

    for (var i = 0; i < _followUps.length; i++) {
      final due = _followUps[i].followUpDue;
      if (due == null) continue;
      final ok = await _service.scheduleAhead(
        kind: ReminderKind.followUpVisit,
        date: due,
        body: 'Your follow-up check is due. Book it if you have not already.',
        offset: i,
      );
      if (ok) scheduled++;
    }

    for (var i = 0; i < _visits.length; i++) {
      final visit = _visits[i];
      final ok = await _service.scheduleAhead(
        kind: ReminderKind.dentalCheckUp,
        date: visit.requestedDate,
        body:
            'Visit to ${visit.centerName}. Ring ${visit.centerPhone} to '
            'confirm if you have not yet.',
        offset: i,
      );
      if (ok) scheduled++;
    }

    await _load();
    if (!mounted) return;
    setState(
      () => _message = scheduled == 0
          ? 'Nothing could be scheduled. Check that notifications are allowed '
                'for OralCare in your device settings.'
          : '$scheduled reminder(s) set.',
    );
  }

  Future<void> _cancelAll() async {
    await _service.cancelAll();
    await _load();
    if (!mounted) return;
    setState(() => _message = 'All reminders cleared.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final supported = _service.isSupported;

    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (!supported)
                    const NoticeBanner(
                      title: 'Reminders need the Android app',
                      message:
                          'This browser cannot show scheduled reminders. '
                          'Install the Android app to receive them. Your due '
                          'dates are still listed below.',
                      severity: NoticeSeverity.caution,
                    )
                  else if (!_granted)
                    const NoticeBanner(
                      title: 'Notifications are turned off',
                      message:
                          'Allow notifications for OralCare in your device '
                          'settings, then return here and tap Set reminders.',
                      severity: NoticeSeverity.caution,
                    )
                  else
                    NoticeBanner(
                      title: 'Reminders are on',
                      message:
                          '$_scheduledCount reminder(s) are currently '
                          'scheduled on this device.',
                      severity: NoticeSeverity.info,
                    ),

                  if (_message != null) ...[
                    const SizedBox(height: 12),
                    NoticeBanner(message: _message!),
                  ],
                  const SizedBox(height: 14),

                  SectionCard(
                    title: 'What you will be reminded about',
                    icon: Icons.alarm_outlined,
                    subtitle:
                        'Reminders stay on this device. Nothing is sent to '
                        'anyone else.',
                    children: [
                      const DetailRow(
                        label: 'Monthly self-check',
                        value: 'Once a month, 9:00 AM',
                      ),
                      DetailRow(
                        label: 'Follow-up visits',
                        value: _followUps.isEmpty
                            ? 'None due'
                            : '${_followUps.length} due · 2 days before',
                      ),
                      DetailRow(
                        label: 'Planned centre visits',
                        value: _visits.isEmpty
                            ? 'None saved'
                            : '${_visits.length} saved · 2 days before',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_followUps.isNotEmpty)
                    SectionCard(
                      title: 'Follow-ups due',
                      icon: Icons.event_repeat_outlined,
                      children: [
                        for (final record in _followUps)
                          DetailRow(
                            label: AppFormats.d(record.followUpDue),
                            value: record.result.outputState.headline,
                            emphasise: record.isFollowUpOverdue,
                          ),
                      ],
                    ),
                  if (_followUps.isNotEmpty) const SizedBox(height: 14),

                  if (supported) ...[
                    FilledButton.icon(
                      onPressed: _scheduleAll,
                      icon: const Icon(Icons.notifications_active_outlined),
                      label: const Text('Set reminders'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _scheduledCount == 0 ? null : _cancelAll,
                      icon: const Icon(Icons.notifications_off_outlined),
                      label: const Text('Turn all reminders off'),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Text(
                    'Reminders are optional. Turning them off does not change '
                    'your record or your follow-up dates.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }
}
