import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/i18n/clinical_terms.dart';
import '../../core/app_images.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/language_toggle_button.dart';
import '../../core/widgets/fullscreen_image.dart';
import '../../domain/risk_catalog.dart';
import '../../state/assessment_flow.dart';
import '../../state/locale_controller.dart';
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
        actions: const [LanguageToggleButton()],
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
    final locale = context.watch<LocaleController>().locale;
    final finding = flow.findingFor(site.key);
    final siteLabel = ClinicalTerms.examSite(site.key, locale, site.label);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 3,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SiteIllustration(
            assetPath: _imageForSite(site.key),
            label: siteLabel,
          ),

          // The site name sits BELOW the illustration, not layered over it. It
          // used to be a dark gradient band across the bottom of the image,
          // which hid the lower part of the anatomy on every card -- the second
          // half of the "pictures are cut" problem, after BoxFit.cover.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
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
                      ? theme.colorScheme.error
                      : finding.examined
                      ? const Color(0xFF2E7D32)
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    siteLabel,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
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

/// Shows the site illustration, or a labelled placeholder when the drawing is
/// missing. It never substitutes a different site's picture, because that would
/// tell the patient to examine the wrong place.
class _SiteIllustration extends StatelessWidget {
  const _SiteIllustration({required this.assetPath, required this.label});

  final String? assetPath;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final path = assetPath;

    Widget placeholder() => Container(
      height: 200,
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'No illustration for $label yet. Follow the written instruction '
              'below.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );

    if (path == null) return placeholder();

    // BoxFit.contain, never cover. These illustrations range from 1.09:1 to
    // 1.50:1, so filling a fixed 200px-tall box cropped between 17% and 39% of
    // every one of them -- including the edges of the anatomy the instruction
    // tells the patient to inspect. A letterboxed image that is whole beats a
    // flush one that is cut.
    return GestureDetector(
      onTap: () => FullscreenImageView.open(
        context,
        image: AssetImage(path),
        title: label,
      ),
      child: Container(
        width: double.infinity,
        color: theme.colorScheme.surfaceContainerHighest,
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: Image.asset(
                path,
                width: double.infinity,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => placeholder(),
              ),
            ),
            const Positioned(top: 10, right: 10, child: ZoomHint()),
          ],
        ),
      ),
    );
  }
}

/// Illustration for a site, or null when none has been drawn yet.
///
/// Returning null rather than a default matters: the previous fallback showed
/// the lips illustration for any unrecognised site, so a new site would quietly
/// display the wrong anatomy.
///
/// Paths come from [AppImages] rather than string literals. Literals here were
/// the reason every illustration broke once the set was converted to JPEG: they
/// still said `.png`, and the deployed site answers a missing asset with
/// index.html, so the app received HTML where it expected an image.
String? _imageForSite(String key) => switch (key) {
  'lips' => AppImages.siteLips,
  'inner_cheeks' => AppImages.siteInnerCheeks,
  'gums' => AppImages.siteGums,
  'tongue' => AppImages.siteTongue,
  'floor_of_mouth' => AppImages.siteFloorOfMouth,
  'palate' => AppImages.sitePalate,
  'neck' => AppImages.siteNeck,
  'throat' => AppImages.siteThroat,
  _ => null,
};
