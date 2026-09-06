import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/clinical_notices.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../data/models/patient_case.dart';
import '../../data/repositories/clinical_repository.dart';
import '../../domain/risk_engine.dart';
import '../../domain/validation_service.dart';
import 'patient_record_screen.dart';

/// Outcome / validation database view (spec section 4 and Table 10).
///
/// Compares app risk and referral output against the recorded clinical outcome,
/// so the risk-stratification and referral algorithm can be evaluated and
/// refined.
class ValidationScreen extends StatefulWidget {
  const ValidationScreen({super.key});

  @override
  State<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<ValidationScreen> {
  ValidationSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final cases = await context.read<ClinicalRepository>().allSharedCases();
    if (!mounted) return;
    setState(() {
      _summary = ValidationService.summarise(cases);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Algorithm validation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ],
      ),
      body: SafeArea(
        child: _loading || summary == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const NoticeBanner(
                    title: 'Read this first',
                    message: ClinicalNotices.validationCaveat,
                    severity: NoticeSeverity.caution,
                  ),
                  const SizedBox(height: 16),

                  SectionCard(
                    title: 'Data captured',
                    icon: Icons.storage_outlined,
                    children: [
                      DetailRow(
                        label: 'Shared assessments',
                        value: '${summary.totalSharedCases}',
                      ),
                      DetailRow(
                        label: 'Clinically reviewed',
                        value: '${summary.reviewedCases}',
                      ),
                      DetailRow(
                        label: 'With reference outcome',
                        value: '${summary.casesWithOutcome}',
                        emphasise: true,
                      ),
                      DetailRow(
                        label: 'Biopsy performed',
                        value: '${summary.biopsyPerformedCount}',
                      ),
                      DetailRow(
                        label: 'Referral completed',
                        value: '${summary.referralCompletedCount}',
                      ),
                      DetailRow(
                        label: 'Follow-up completed',
                        value: '${summary.followUpCompletedCount}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (!summary.hasEnoughDataForMetrics)
                    const NoticeBanner(
                      title: 'No metrics yet',
                      message:
                          'Metrics appear once at least one case has OPMD or '
                          'OSCC status recorded in the outcome form.',
                    )
                  else ...[
                    _MatrixCard(matrix: summary.matrix),
                    const SizedBox(height: 14),
                    _MetricsCard(matrix: summary.matrix),
                    const SizedBox(height: 14),
                  ],

                  SectionCard(
                    title: 'Outcome by risk band',
                    icon: Icons.bar_chart_outlined,
                    subtitle:
                        'A usable stratification should show the positive rate '
                        'rising from lower to higher.',
                    children: [
                      for (final breakdown in summary.categoryBreakdowns)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CategoryRow(breakdown: breakdown),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (summary.falseNegativeCases.isNotEmpty) ...[
                    SectionCard(
                      title: 'Cases the app did not flag',
                      icon: Icons.error_outline,
                      subtitle:
                          'Established OPMD or OSCC where the app produced no '
                          'referral alert. Review each of these.',
                      children: [
                        for (final c in summary.falseNegativeCases)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.warning_amber_rounded,
                              color: theme.colorScheme.error,
                            ),
                            title: Text(c.patientId),
                            subtitle: Text(
                              'Score ${c.assessment.result.totalScore} · '
                              '${c.assessment.result.category.label} · '
                              '${AppFormats.d(c.assessment.createdAt)}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _open(c),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  SectionCard(
                    title: 'How to read this',
                    icon: Icons.help_outline,
                    children: [
                      Text(
                        'A case counts as "flagged" when the app produced a '
                        'professional-check override or a referral alert. It '
                        'counts as disease-positive when OPMD or OSCC has been '
                        'established in the outcome form.\n\n'
                        'For a referral tool, missing disease is far worse than '
                        'over-referring, so sensitivity and the false-negative '
                        'list matter more than specificity. Use them to decide '
                        'whether the provisional weights and the 0-4 / 5-9 / 10+ '
                        'cut-offs need changing.',
                        style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
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

class _MatrixCard extends StatelessWidget {
  const _MatrixCard({required this.matrix});

  final ConfusionMatrix matrix;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'App output vs clinical outcome',
      icon: Icons.grid_on_outlined,
      subtitle: 'Based on ${matrix.total} case'
          '${matrix.total == 1 ? '' : 's'} with a recorded outcome.',
      children: [
        Row(
          children: [
            Expanded(
              child: _Cell(
                label: 'True positive',
                value: matrix.truePositive,
                detail: 'Flagged, disease established',
                tone: _CellTone.good,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Cell(
                label: 'False positive',
                value: matrix.falsePositive,
                detail: 'Flagged, no disease',
                tone: _CellTone.neutral,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _Cell(
                label: 'False negative',
                value: matrix.falseNegative,
                detail: 'Not flagged, disease established',
                tone: matrix.falseNegative > 0
                    ? _CellTone.bad
                    : _CellTone.neutral,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Cell(
                label: 'True negative',
                value: matrix.trueNegative,
                detail: 'Not flagged, no disease',
                tone: _CellTone.good,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _CellTone { good, neutral, bad }

class _Cell extends StatelessWidget {
  const _Cell({
    required this.label,
    required this.value,
    required this.detail,
    required this.tone,
  });

  final String label;
  final int value;
  final String detail;
  final _CellTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (Color bg, Color fg) = switch (tone) {
      _CellTone.good => (
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
      ),
      _CellTone.neutral => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurface,
      ),
      _CellTone.bad => (
        theme.colorScheme.errorContainer,
        theme.colorScheme.onErrorContainer,
      ),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            style: theme.textTheme.bodySmall?.copyWith(
              color: fg.withValues(alpha: 0.85),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({required this.matrix});

  final ConfusionMatrix matrix;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Operating characteristics',
      icon: Icons.speed_outlined,
      children: [
        DetailRow(
          label: 'Sensitivity',
          value: ValidationService.formatRate(matrix.sensitivity),
          emphasise: true,
        ),
        DetailRow(
          label: 'Specificity',
          value: ValidationService.formatRate(matrix.specificity),
        ),
        DetailRow(
          label: 'Positive predictive value',
          value: ValidationService.formatRate(matrix.positivePredictiveValue),
        ),
        DetailRow(
          label: 'Negative predictive value',
          value: ValidationService.formatRate(matrix.negativePredictiveValue),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.breakdown});

  final CategoryBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visuals = RiskVisuals.forCategory(breakdown.category, theme.brightness);
    final rate = breakdown.positiveRate;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: visuals.color,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                breakdown.category.label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: visuals.onColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            Text(
              ValidationService.formatRate(rate),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: rate ?? 0,
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${breakdown.assessments} assessment'
          '${breakdown.assessments == 1 ? '' : 's'} · '
          '${breakdown.withOutcome} with outcome · '
          '${breakdown.diseasePositive} disease-positive',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
