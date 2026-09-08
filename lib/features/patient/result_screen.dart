import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/clinical_notices.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../data/repositories/assessment_repository.dart';
import '../../domain/follow_up_policy.dart';
import '../../domain/risk_catalog.dart';
import '../../domain/risk_engine.dart';
import '../../state/assessment_flow.dart';
import 'share_with_doctor_card.dart';

/// Patient output (spec section 2.6, Table 7).
///
/// This screen is where the whole assessment is committed: it runs the engine
/// once, saves RISK_ASSESSMENT, SELF_EXAMINATION and LESION, then shows the
/// state-specific guidance.
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  RiskResult? _result;
  FollowUpPlan? _plan;
  int? _assessmentId;
  bool _saving = true;
  bool _shared = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _commit();
  }

  Future<void> _commit() async {
    final flow = context.read<AssessmentFlow>();
    final repo = context.read<AssessmentRepository>();

    try {
      final result = flow.evaluate();
      final plan = FollowUpPolicy.plan(
        result: result,
        lesionFirstNoticed: flow.lesion.dateFirstNoticed,
      );

      // Nothing is shared on save. Sharing is addressed to a specific
      // clinician, so it only happens once the patient chooses one below.
      final assessment = flow
          .buildAssessment(result)
          .copyWith(followUpDue: plan.due, followUpStatus: plan.status);

      final id = await repo.saveAssessment(assessment);

      await repo.saveSelfExamination(
        flow.buildSelfExamination(assessmentId: id),
      );

      if (flow.lesion.hasAnyContent) {
        await repo.saveLesion(
          flow.lesion.toRecord(patientId: flow.patientId, assessmentId: id),
        );
      }

      if (!mounted) return;
      setState(() {
        _result = result;
        _plan = plan;
        _assessmentId = id;
        _shared = false;
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not save your assessment. $e';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_saving) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Result')),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: NoticeBanner(
            title: 'Something went wrong',
            message: _error ?? 'The assessment could not be completed.',
            severity: NoticeSeverity.alert,
          ),
        ),
      );
    }

    final result = _result!;
    final plan = _plan!;
    final theme = Theme.of(context);
    final visuals = RiskVisuals.forState(result.outputState, theme.brightness);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your result'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Headline(result: result, visuals: visuals),
            const SizedBox(height: 16),

            if (result.outputState.isUrgent)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: NoticeBanner(
                  message: ClinicalNotices.urgencyGuidance,
                  severity: NoticeSeverity.alert,
                ),
              ),

            SectionCard(
              title: 'What this means',
              icon: Icons.help_outline,
              children: [
                Text(
                  result.outputState.guidance,
                  style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _AdviceCard(state: result.outputState),
            const SizedBox(height: 14),

            _WhyCard(result: result),
            const SizedBox(height: 14),

            _ScoreCard(result: result),
            const SizedBox(height: 14),

            SectionCard(
              title: 'Follow-up',
              icon: Icons.event_repeat_outlined,
              children: [
                Text(plan.reason, style: theme.textTheme.bodyMedium),
                if (plan.due != null) ...[
                  const SizedBox(height: 10),
                  DetailRow(
                    label: 'Next check',
                    value: AppFormats.d(plan.due),
                    emphasise: true,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            ShareWithDoctorCard(
              assessmentId: _assessmentId,
              initialShared: _shared,
              initialDoctorUid: null,
            ),

            const SizedBox(height: 20),
            const NoticeBanner(
              message: ClinicalNotices.noDiagnosis,
              severity: NoticeSeverity.info,
            ),
            const SizedBox(height: 10),
            const NoticeBanner(
              message: ClinicalNotices.provisionalScores,
              severity: NoticeSeverity.caution,
            ),

            const SizedBox(height: 20),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Done'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.result, required this.visuals});

  final RiskResult result;
  final RiskVisuals visuals;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: visuals.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: visuals.onColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(visuals.icon, color: visuals.onColor, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result.outputState.headline,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: visuals.onColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (result.professionalCheckRequired) ...[
            const SizedBox(height: 10),
            Text(
              'This overrides your risk score. A red-flag finding takes '
              'priority over the numbers.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: visuals.onColor,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Prevention or cessation advice per spec Table 7.
class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.state});

  final PatientOutputState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (String title, List<String> items) = switch (state) {
      PatientOutputState.lowerRisk => (
        'Keep it that way',
        ClinicalNotices.preventionAdvice,
      ),
      PatientOutputState.increasedRisk => (
        'What lowers your risk',
        ClinicalNotices.cessationAdvice,
      ),
      PatientOutputState.higherRisk => (
        'What to do next',
        [
          'Arrange a professional oral examination.',
          ...ClinicalNotices.cessationAdvice,
        ],
      ),
      PatientOutputState.observeAndReview => (
        'While you watch it',
        [
          'Look at the same spot every few days in good light.',
          'Note if it grows, changes colour, bleeds or becomes painful.',
          'If it is still there after two weeks, get it checked.',
          'Stopping tobacco and areca nut helps healing.',
        ],
      ),
      PatientOutputState.professionalCheckRequired => (
        'What to do next',
        [
          'Book an appointment with a dentist or doctor.',
          'Show them this record and the photograph if you took one.',
          'Do not wait for it to clear up on its own.',
          'Stop tobacco and areca nut now.',
        ],
      ),
    };

    return SectionCard(
      title: title,
      icon: Icons.tips_and_updates_outlined,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 10),
                  child: Icon(
                    Icons.circle,
                    size: 6,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: Text(
                    item,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Shows the engine's reasoning, so the output is never a black box.
class _WhyCard extends StatelessWidget {
  const _WhyCard({required this.result});

  final RiskResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SectionCard(
      title: 'Why you got this result',
      icon: Icons.account_tree_outlined,
      children: [
        for (final reason in result.reasons)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              reason.detail,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
            ),
          ),
        if (result.redFlagKeys.isNotEmpty) ...[
          const Divider(height: 20),
          Text(
            'Findings you reported',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final key in result.redFlagKeys)
                Chip(
                  label: Text(RedFlagCatalog.labelFor(key)),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.result});

  final RiskResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visuals = RiskVisuals.forCategory(result.category, theme.brightness);

    return SectionCard(
      title: 'Your provisional score',
      icon: Icons.calculate_outlined,
      subtitle: 'Cut-offs: 0–4 lower, 5–9 increased, 10 or more higher.',
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: visuals.color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          '${result.totalScore}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: visuals.onColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      children: [
        DetailRow(label: 'Total score', value: '${result.totalScore}'),
        DetailRow(
          label: 'Score band',
          value: result.category.label,
          emphasise: true,
        ),
        if (result.professionalCheckRequired)
          const DetailRow(
            label: 'Override applied',
            value: 'Yes — red-flag safety override',
            emphasise: true,
          ),
        if (result.hasUnknownAnswers)
          DetailRow(
            label: 'Unknown answers',
            value: result.unknownAnswerKeys
                .map((k) => RiskCatalog.variableFor(k).label)
                .join(', '),
          ),
        const Divider(height: 24),
        Text(
          'How each answer contributed',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        for (final variable in RiskCatalog.variables)
          if ((result.scoreBreakdown[variable.key] ?? 0) > 0)
            DetailRow(
              label: variable.label,
              value: '+${result.scoreBreakdown[variable.key]}',
            ),
        if (result.scoreBreakdown.values.every((v) => v == 0))
          Text(
            'No answer added to the score.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
