import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/clinical_notices.dart';
import '../../core/widgets/common.dart';
import '../../domain/risk_catalog.dart';
import '../../state/assessment_flow.dart';
import 'flow_route.dart';
import 'self_exam_screen.dart';

/// Red-flag safety check (spec section 2.3).
///
/// Ten Yes/No items. Red flags take precedence over the numerical score, so
/// this screen is reached whenever the patient reported a suspicious lesion or
/// symptom, and its answers can override the risk band entirely.
class RedFlagScreen extends StatelessWidget {
  const RedFlagScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<AssessmentFlow>();
    final theme = Theme.of(context);

    final selectedCount = flow.redFlags.length;
    final durationLabel = RiskCatalog.variableFor(
      RiskKeys.lesionDuration,
    ).optionFor(flow.answer(RiskKeys.lesionDuration))?.label;

    return Scaffold(
      appBar: AppBar(title: const Text('Safety check')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const NoticeBanner(
              title: 'Tick anything you have',
              message:
                  'These are the changes that matter most. Ticking one does not '
                  'mean you have cancer. It means a professional should look at '
                  'it.',
              severity: NoticeSeverity.info,
            ),
            const SizedBox(height: 14),
            if (durationLabel != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: NoticeBanner(
                  message: 'You said this has been present: $durationLabel.',
                  severity: NoticeSeverity.caution,
                ),
              ),

            Card(
              child: Column(
                children: [
                  for (var i = 0; i < RedFlagCatalog.items.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    SwitchListTile(
                      title: Text(RedFlagCatalog.items[i].label),
                      value: flow.isRedFlagSet(RedFlagCatalog.items[i].key),
                      onChanged: (value) =>
                          flow.setRedFlag(RedFlagCatalog.items[i].key, value),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),
            Text(
              selectedCount == 0
                  ? 'Nothing ticked yet.'
                  : '$selectedCount item${selectedCount == 1 ? '' : 's'} ticked.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),
            const NoticeBanner(
              message: ClinicalNotices.urgencyGuidance,
              severity: NoticeSeverity.alert,
            ),

            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).push(flowRoute(flow, const SelfExamScreen())),
              child: const Text('Continue to self-examination'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
