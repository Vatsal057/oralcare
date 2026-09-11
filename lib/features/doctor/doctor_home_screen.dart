import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/clinical_notices.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../data/models/patient_case.dart';
import '../../data/repositories/clinical_repository.dart';
import '../../domain/risk_engine.dart';
import '../../state/session_controller.dart';
import 'patient_record_screen.dart';
import 'validation_screen.dart';

/// Doctor home (spec section 3).
///
/// Flow: Secure Login → Patient Queue / Referral Alert → Review Patient Record
/// → Clinical Examination → Clinical Impression → Investigation / Biopsy /
/// Referral → Final Diagnosis / Histopathology → Follow-up → Outcome captured
/// for algorithm validation.
class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  List<PatientCase> _cases = [];
  bool _loading = true;
  bool _onlyUnreviewed = false;
  bool _onlyAlerts = false;
  bool _onlyMissedAttendance = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cases = await context.read<ClinicalRepository>().queue();
    if (!mounted) return;
    setState(() {
      _cases = cases;
      _loading = false;
    });
  }

  List<PatientCase> get _filtered => _cases
      .where((c) {
        if (_onlyUnreviewed && c.isReviewed) return false;
        if (_onlyAlerts && !c.assessment.result.referralAlert) return false;
        if (_onlyMissedAttendance && !c.failedToAttend()) return false;
        return true;
      })
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final session = context.watch<SessionController>();
    final user = session.requireUser;

    final alertCount = _cases
        .where((c) => c.assessment.result.referralAlert)
        .length;
    final unreviewedCount = _cases.where((c) => !c.isReviewed).length;
    final missedCount = _cases.where((c) => c.needsAttendanceChase()).length;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_outlined),
            tooltip: 'Algorithm validation',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ValidationScreen()),
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
                'Signed in as ${user.displayName}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              const NoticeBanner(
                message: ClinicalNotices.doctorResponsibility,
                severity: NoticeSeverity.info,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Referral alerts',
                      value: '$alertCount',
                      icon: Icons.notification_important_outlined,
                      emphasise: alertCount > 0,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      label: 'Awaiting review',
                      value: '$unreviewedCount',
                      icon: Icons.pending_actions_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatTile(
                      label: 'Did not attend',
                      value: '$missedCount',
                      icon: Icons.person_off_outlined,
                      emphasise: missedCount > 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Referral alerts only'),
                    selected: _onlyAlerts,
                    onSelected: (v) => setState(() => _onlyAlerts = v),
                  ),
                  FilterChip(
                    label: const Text('Not yet reviewed'),
                    selected: _onlyUnreviewed,
                    onSelected: (v) => setState(() => _onlyUnreviewed = v),
                  ),
                  FilterChip(
                    label: const Text('Did not attend'),
                    selected: _onlyMissedAttendance,
                    onSelected: (v) =>
                        setState(() => _onlyMissedAttendance = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: EmptyState(
                    icon: Icons.inbox_outlined,
                    title: _cases.isEmpty
                        ? 'No shared records yet'
                        : 'Nothing matches these filters',
                    message: _cases.isEmpty
                        ? 'Records appear here only after a patient consents to '
                              'share them.'
                        : 'Clear the filters to see the full queue.',
                  ),
                )
              else
                for (final patientCase in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _QueueCard(
                      patientCase: patientCase,
                      onTap: () => _open(patientCase),
                    ),
                  ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(PatientCase patientCase) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PatientRecordScreen(patientCase: patientCase),
      ),
    );
    if (mounted) await _load();
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    this.emphasise = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: emphasise
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: emphasise
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: emphasise ? theme.colorScheme.onErrorContainer : null,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: emphasise
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueCard extends StatelessWidget {
  const _QueueCard({required this.patientCase, required this.onTap});

  final PatientCase patientCase;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = patientCase.assessment.result;
    final visuals = RiskVisuals.forState(result.outputState, theme.brightness);
    final patient = patientCase.patient;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      patientCase.patientId,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  // A referred patient who never arrived is the easiest to lose,
                  // so it outranks the risk badges.
                  if (patientCase.failedToAttend())
                    _Badge(
                      label: 'DID NOT ATTEND',
                      background: theme.colorScheme.error,
                      foreground: theme.colorScheme.onError,
                    )
                  else if (result.professionalCheckRequired)
                    _Badge(
                      label: 'OVERRIDE',
                      background: theme.colorScheme.error,
                      foreground: theme.colorScheme.onError,
                    )
                  else if (result.referralAlert)
                    _Badge(
                      label: 'ALERT',
                      background: theme.colorScheme.tertiary,
                      foreground: theme.colorScheme.onTertiary,
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Age ${patient.age ?? '—'}'
                '${patient.sex != null ? ' · ${patient.sex}' : ''} · '
                '${AppFormats.dt(patientCase.assessment.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Pill(
                    label:
                        '${result.outputState.headline} · score '
                        '${result.totalScore}',
                    background: visuals.color,
                    foreground: visuals.onColor,
                    icon: visuals.icon,
                  ),
                  if (result.redFlagPresent)
                    _Pill(
                      label:
                          '${result.redFlagKeys.length} red flag'
                          '${result.redFlagKeys.length == 1 ? '' : 's'}',
                      background: theme.colorScheme.surfaceContainerHighest,
                      foreground: theme.colorScheme.onSurface,
                      icon: Icons.flag_outlined,
                    ),
                  if (result.lesionPersistent)
                    _Pill(
                      label: '2 weeks or longer',
                      background: theme.colorScheme.errorContainer,
                      foreground: theme.colorScheme.onErrorContainer,
                      icon: Icons.schedule,
                    ),
                  if (result.previousOscc)
                    _Pill(
                      label: 'Previous OSCC',
                      background: theme.colorScheme.errorContainer,
                      foreground: theme.colorScheme.onErrorContainer,
                      icon: Icons.history,
                    ),
                  if (patientCase.lesions.isNotEmpty)
                    _Pill(
                      label:
                          '${patientCase.lesions.length} lesion record'
                          '${patientCase.lesions.length == 1 ? '' : 's'}',
                      background: theme.colorScheme.surfaceContainerHighest,
                      foreground: theme.colorScheme.onSurface,
                      icon: Icons.healing_outlined,
                    ),
                  if (patientCase.photoViewingAllowed &&
                      patientCase.lesions.any((l) => l.hasPhoto))
                    _Pill(
                      label: 'Photograph',
                      background: theme.colorScheme.surfaceContainerHighest,
                      foreground: theme.colorScheme.onSurface,
                      icon: Icons.photo_outlined,
                    ),
                ],
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    patientCase.isReviewed
                        ? Icons.check_circle_outline
                        : Icons.radio_button_unchecked,
                    size: 16,
                    color: patientCase.isReviewed
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    patientCase.isReviewed ? 'Reviewed' : 'Awaiting review',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (patientCase.hasReferenceOutcome) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.science_outlined,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Outcome recorded',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(Icons.chevron_right, color: theme.colorScheme.outline),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
