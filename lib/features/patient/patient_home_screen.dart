import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/clinical_notices.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../data/models/assessment_models.dart';
import '../../data/repositories/assessment_repository.dart';
import '../../domain/risk_engine.dart';
import '../../state/assessment_flow.dart';
import '../../state/session_controller.dart';
import 'assessment_detail_screen.dart';
import 'consent_screen.dart';
import 'flow_route.dart';
import 'risk_assessment_screen.dart';

/// Patient home. Entry point for the flow in spec section 2:
/// Login/Register → Consent → Risk Assessment → Guided Self-Examination →
/// Lesion Recording → Risk/Red-Flag Output → Share with Doctor → Follow-up.
class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  List<RiskAssessmentRecord> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = context.read<SessionController>();
    final repo = context.read<AssessmentRepository>();
    final patientId = session.requireUser.patientId;
    if (patientId == null) {
      setState(() => _loading = false);
      return;
    }

    final history = await repo.assessmentsForPatient(patientId);
    if (!mounted) return;
    setState(() {
      _history = history;
      _loading = false;
    });
  }

  Future<void> _startAssessment() async {
    final session = context.read<SessionController>();
    final flow = AssessmentFlow(patient: session.requireUser);

    await Navigator.of(
      context,
    ).push(flowRoute(flow, const RiskAssessmentScreen()));

    flow.dispose();
    if (mounted) await _load();
  }

  Future<void> _markFollowUpDone(RiskAssessmentRecord record) async {
    final repo = context.read<AssessmentRepository>();
    if (record.id == null) return;
    await repo.setFollowUp(
      assessmentId: record.id!,
      due: record.followUpDue,
      status: FollowUpStatus.completed,
    );
    if (!mounted) return;
    showSnack(context, 'Follow-up marked as done.');
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = context.watch<SessionController>();
    final user = session.requireUser;

    final pending = _history
        .where((a) => a.followUpStatus == FollowUpStatus.pending)
        .toList();
    final latest = _history.isEmpty ? null : _history.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OralCare'),
        actions: [
          IconButton(
            icon: const Icon(Icons.privacy_tip_outlined),
            tooltip: 'Consent choices',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ConsentScreen(isEditing: true),
                ),
              );
              if (mounted) await _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: session.signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Hello${user.fullName != null && user.fullName!.isNotEmpty ? ', ${user.fullName}' : ''}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Patient ID ${user.patientId ?? '—'} · Age ${user.age ?? '—'}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),

              for (final record in pending)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FollowUpCard(
                    record: record,
                    onDone: () => _markFollowUpDone(record),
                    onRecheck: _startAssessment,
                  ),
                ),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Check your mouth',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Three steps: your risk factors, a guided look inside '
                        'your mouth, and recording anything you find. Takes '
                        'about five minutes.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _startAssessment,
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(
                          _history.isEmpty
                              ? 'Start my first check'
                              : 'Start a new check',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (latest != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Your last result',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _AssessmentTile(
                  record: latest,
                  onTap: () => _openDetail(latest),
                ),
              ],

              if (_history.length > 1) ...[
                const SizedBox(height: 20),
                Text(
                  'Earlier checks',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                for (final record in _history.skip(1))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AssessmentTile(
                      record: record,
                      onTap: () => _openDetail(record),
                    ),
                  ),
              ],

              if (_loading) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],

              if (!_loading && _history.isEmpty) ...[
                const SizedBox(height: 24),
                const NoticeBanner(
                  message:
                      'You have not completed a check yet. Your results will '
                      'appear here.',
                ),
              ],

              const SizedBox(height: 20),
              const NoticeBanner(
                message: ClinicalNotices.noDiagnosis,
                severity: NoticeSeverity.info,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDetail(RiskAssessmentRecord record) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AssessmentDetailScreen(record: record)),
    );
    if (mounted) await _load();
  }
}

class _FollowUpCard extends StatelessWidget {
  const _FollowUpCard({
    required this.record,
    required this.onDone,
    required this.onRecheck,
  });

  final RiskAssessmentRecord record;
  final VoidCallback onDone;
  final VoidCallback onRecheck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = record.isFollowUpOverdue;
    final urgent = record.result.professionalCheckRequired;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: overdue || urgent
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                overdue ? Icons.alarm : Icons.event_available_outlined,
                color: overdue || urgent
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  overdue ? 'Follow-up overdue' : 'Follow-up due',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: overdue || urgent
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            urgent
                ? 'Your last check said a professional check was required. '
                      'Have you been seen?'
                : 'Time to look again and see whether anything has changed.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: overdue || urgent
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onSecondaryContainer,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Due ${AppFormats.d(record.followUpDue)} · from your check on '
            '${AppFormats.d(record.createdAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  (overdue || urgent
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.onSecondaryContainer)
                      .withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onRecheck,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text('Check again'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDone,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text('Mark done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssessmentTile extends StatelessWidget {
  const _AssessmentTile({required this.record, required this.onTap});

  final RiskAssessmentRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visuals = RiskVisuals.forState(
      record.result.outputState,
      theme.brightness,
    );

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: visuals.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(visuals.icon, color: visuals.onColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.result.outputState.headline,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${AppFormats.dt(record.createdAt)} · score '
                      '${record.result.totalScore} · '
                      '${record.result.category.label.toLowerCase()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (record.sharedWithDoctor)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.share_outlined,
                              size: 13,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Shared with doctor',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
