import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/clinical_notices.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/optional_asset_image.dart';
import '../../domain/risk_catalog.dart';
import '../../state/assessment_flow.dart';
import 'flow_route.dart';
import 'red_flag_screen.dart';
import 'self_exam_screen.dart';

/// Risk-assessment inputs (spec section 2.2, Table 2).
///
/// Grouped into short sections rather than one long list, and the duration /
/// frequency questions only appear once some tobacco or areca exposure is
/// reported.
class RiskAssessmentScreen extends StatefulWidget {
  const RiskAssessmentScreen({super.key});

  @override
  State<RiskAssessmentScreen> createState() => _RiskAssessmentScreenState();
}

class _RiskAssessmentScreenState extends State<RiskAssessmentScreen> {
  bool _showErrors = false;

  void _continue() {
    final flow = context.read<AssessmentFlow>();

    if (!flow.isRiskFormComplete) {
      setState(() => _showErrors = true);
      final missing = flow.unansweredVariables.length;
      showSnack(
        context,
        'Please answer $missing more question${missing == 1 ? '' : 's'}.',
        isError: true,
      );
      return;
    }

    // Spec section 2.2: a reported suspicious lesion or symptom triggers the
    // red-flag module. Otherwise go straight to the guided self-examination.
    final Widget next = flow.reportsSuspiciousLesion
        ? const RedFlagScreen()
        : const SelfExamScreen();

    Navigator.of(context).push(flowRoute(flow, next));
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<AssessmentFlow>();
    final theme = Theme.of(context);

    final ageBandOption = RiskCatalog.ageBand.optionFor(
      RiskCatalog.ageBandForAge(flow.age),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 1 of 3 · Risk factors'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: _completionFraction(flow),
            minHeight: 4,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const NoticeBanner(
              message: ClinicalNotices.provisionalScores,
              severity: NoticeSeverity.caution,
            ),
            const SizedBox(height: 16),

            SectionCard(
              title: 'Age',
              icon: Icons.cake_outlined,
              subtitle: 'Taken from your profile and used as a risk factor.',
              children: [
                DetailRow(label: 'Your age', value: '${flow.age} years'),
                DetailRow(
                  label: 'Age band',
                  value: ageBandOption?.label ?? '—',
                  emphasise: true,
                ),
              ],
            ),
            const SizedBox(height: 14),

            SectionCard(
              title: 'Tobacco and areca nut',
              icon: Icons.smoke_free_outlined,
              subtitle:
                  'These are the strongest changeable risk factors for oral '
                  'cancer.',
              children: [
                _question(flow, RiskKeys.smoking),
                _question(flow, RiskKeys.smokelessTobacco),
                _question(flow, RiskKeys.areca),
                _question(flow, RiskKeys.gutkha),
                _question(flow, RiskKeys.familyHistory),
                _question(flow, RiskKeys.immunosuppression),
                if (flow.hasExposure) ...[
                  _question(flow, RiskKeys.exposureDuration),
                  _question(flow, RiskKeys.useFrequency),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Duration and frequency questions appear only if you '
                      'report some tobacco or areca use.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            SectionCard(
              title: 'Alcohol',
              icon: Icons.no_drinks_outlined,
              children: [_question(flow, RiskKeys.alcohol)],
            ),
            const SizedBox(height: 14),

            SectionCard(
              title: 'Past oral history',
              icon: Icons.history_outlined,
              children: [
                _question(flow, RiskKeys.previousOpmd),
                _question(flow, RiskKeys.previousOscc),
              ],
            ),
            const SizedBox(height: 14),

            SectionCard(
              title: 'Right now',
              icon: Icons.report_problem_outlined,
              subtitle:
                  'Answer for how your mouth is today, not how it was in the '
                  'past.',
              children: [
                _question(flow, RiskKeys.suspiciousLesion),
                if (flow.reportsSuspiciousLesion)
                  _question(flow, RiskKeys.lesionDuration),
                _question(flow, RiskKeys.neckLump),
              ],
            ),

            const SizedBox(height: 24),
            FilledButton(
              onPressed: _continue,
              child: Text(
                flow.reportsSuspiciousLesion
                    ? 'Continue to safety check'
                    : 'Continue to self-examination',
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _question(AssessmentFlow flow, String key) {
    final variable = RiskCatalog.variableFor(key);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Illustration for the habit questions, so a patient who cannot read
          // the label can still see what is being asked. Renders nothing when
          // the variable has no image, which is most of them.
          if (variable.imageAsset != null) ...[
            OptionalAssetImage(
              assetPath: variable.imageAsset,
              height: 130,
              title: variable.label,
            ),
            const SizedBox(height: 10),
          ],
          SingleChoiceField<String>(
            label: variable.label,
            note: variable.note,
            options: variable.options.map((o) => o.value).toList(),
            labelBuilder: (value) => variable.optionFor(value)?.label ?? value,
            value: flow.answer(key),
            showError: _showErrors,
            onChanged: (value) => flow.setAnswer(key, value),
          ),
        ],
      ),
    );
  }

  double _completionFraction(AssessmentFlow flow) {
    final applicable = flow.applicableVariables.length;
    if (applicable == 0) return 0;
    final answered = applicable - flow.unansweredVariables.length;
    // Step 1 of 3, so cap the bar at one third when the form is complete.
    return (answered / applicable) / 3;
  }
}
