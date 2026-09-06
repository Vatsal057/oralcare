import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/common.dart';
import '../../domain/risk_catalog.dart';
import '../../state/assessment_flow.dart';
import 'flow_route.dart';
import 'lesion_screen.dart';
import 'result_screen.dart';

/// Guided mouth self-examination (spec section 2.4, Table 5).
///
/// Seven sites, each capturing "Examined? Yes/No" and "Abnormality? Yes/No".
/// If any abnormality is reported the lesion-recording module opens next.
class SelfExamScreen extends StatelessWidget {
  const SelfExamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<AssessmentFlow>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 2 of 3 · Self-examination'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 0.33 + (flow.sitesExamined / ExamSiteCatalog.sites.length) * 0.33,
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
              title: 'Before you start',
              message:
                  'Find good light and a mirror. Wash your hands. Take out any '
                  'dentures. Work through the sites in order, and mark anything '
                  'that looks or feels different.',
            ),
            const SizedBox(height: 14),

            for (final site in ExamSiteCatalog.sites)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SiteCard(site: site),
              ),

            const SizedBox(height: 4),
            if (flow.anySiteAbnormal)
              const NoticeBanner(
                title: 'You marked a finding',
                message:
                    'The next screen records the details so a doctor can see '
                    'exactly what you found.',
                severity: NoticeSeverity.caution,
              )
            else if (flow.sitesExamined < ExamSiteCatalog.sites.length)
              NoticeBanner(
                message:
                    'You have examined ${flow.sitesExamined} of '
                    '${ExamSiteCatalog.sites.length} sites. You can continue, '
                    'but checking every site gives a better result.',
                severity: NoticeSeverity.info,
              )
            else
              const NoticeBanner(
                message: 'All sites examined, with nothing abnormal marked.',
                severity: NoticeSeverity.success,
              ),

            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                // Spec section 2.4: abnormality = Yes opens lesion recording.
                // A symptom reported on the risk form does the same, so a
                // finding is never left undocumented.
                final Widget next = flow.shouldRecordLesion
                    ? const LesionScreen()
                    : const ResultScreen();
                Navigator.of(context).push(flowRoute(flow, next));
              },
              child: Text(
                flow.shouldRecordLesion
                    ? 'Continue to record the finding'
                    : 'See my result',
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _SiteCard extends StatelessWidget {
  const _SiteCard({required this.site});

  final ExamSite site;

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<AssessmentFlow>();
    final theme = Theme.of(context);
    final finding = flow.findingFor(site.key);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  finding.abnormality
                      ? Icons.error_outline
                      : finding.examined
                          ? Icons.check_circle_outline
                          : Icons.radio_button_unchecked,
                  size: 20,
                  color: finding.abnormality
                      ? theme.colorScheme.error
                      : finding.examined
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  site.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              site.instruction,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('I examined this site'),
              value: finding.examined,
              onChanged: (value) => flow.setSiteExamined(site.key, value),
            ),
            if (finding.examined)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('I found something abnormal'),
                subtitle: const Text(
                  'A sore, patch, lump, swelling or anything that feels changed.',
                ),
                value: finding.abnormality,
                onChanged: (value) => flow.setSiteAbnormality(site.key, value),
              ),
          ],
        ),
      ),
    );
  }
}
