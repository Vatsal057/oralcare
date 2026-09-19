import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/common.dart';
import '../../domain/risk_catalog.dart';
import '../../state/assessment_flow.dart';
import 'flow_route.dart';
import 'lesion_reference_dialog.dart';
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
            value:
                0.33 +
                (flow.sitesExamined / ExamSiteCatalog.sites.length) * 0.33,
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
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LesionReferenceDialog(),
                  ),
                );
              },
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('View Real Clinical Reference Photos'),
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
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Image.asset(
                _imageForSite(site.key),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        finding.abnormality
                            ? Icons.error_outline
                            : finding.examined
                            ? Icons.check_circle_outline
                            : Icons.radio_button_unchecked,
                        size: 24,
                        color: finding.abnormality
                            ? Colors.redAccent
                            : finding.examined
                            ? Colors.greenAccent
                            : Colors.white70,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          site.label,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  site.instruction,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text(
                          'I examined this site',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        value: finding.examined,
                        onChanged: (value) =>
                            flow.setSiteExamined(site.key, value),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      if (finding.examined) ...[
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text(
                            'I found something abnormal',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            'A sore, patch, lump, swelling or anything that feels changed.',
                          ),
                          value: finding.abnormality,
                          onChanged: (value) =>
                              flow.setSiteAbnormality(site.key, value),
                          activeThumbColor: theme.colorScheme.error,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (finding.abnormality)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LesionReferenceDialog(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.compare_outlined),
                        label: const Text('Compare with clinical photos'),
                        style: FilledButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                          backgroundColor: theme.colorScheme.errorContainer
                              .withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _imageForSite(String key) => switch (key) {
  'lips' => 'assets/images/1.png',
  'inner_cheeks' => 'assets/images/2.png',
  'gums' => 'assets/images/3.png',
  'tongue' => 'assets/images/4.png',
  'floor_of_mouth' => 'assets/images/5.png',
  'palate' => 'assets/images/6.png',
  'neck' => 'assets/images/7.png',
  _ => 'assets/images/1.png',
};
