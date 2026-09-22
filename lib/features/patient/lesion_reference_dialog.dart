import 'package:flutter/material.dart';

import '../../core/app_images.dart';

/// Clinical visual reference guide displaying realistic clinical photographs
/// of oral potentially malignant disorders (OPMD) and suspicious lesions,
/// enabling patients to visually compare their self-examination findings.
class LesionReferenceDialog extends StatelessWidget {
  const LesionReferenceDialog({super.key});

  static const List<_LesionExample> _examples = [
    // Deliberately first. Patients judge their own mouth against a baseline far
    // more reliably than against a catalogue of pathology, and without one every
    // normal variation starts to look suspicious.
    _LesionExample(
      title: 'A Normal, Healthy Mouth',
      subtitle: 'What healthy tissue looks like, for comparison',
      imagePath: AppImages.signNormalMouth,
      keyCharacteristics: [
        'Even, uniform pink colour throughout',
        'Moist surface with no patches, sores or rough areas',
        'Gums sit snugly against the teeth without bleeding',
        'Both sides of the mouth look the same as each other',
      ],
      clinicalSignificance:
          'Compare your own mouth against this first. Most differences are '
          'harmless, but anything that persists beyond two weeks should be '
          'looked at by a dentist or doctor.',
      isBaseline: true,
    ),
    _LesionExample(
      title: 'Homogeneous Leukoplakia (White Patch)',
      subtitle: 'Flat, uniform white plaque that cannot be scraped off',
      imagePath: AppImages.signLeukoplakia,
      keyCharacteristics: [
        'Well-demarcated white patch on inner cheek or gums',
        'Cannot be rubbed or scraped off with gauze',
        'Usually painless in early stages',
        'Common in chronic tobacco, areca nut, and bidi users',
      ],
      clinicalSignificance:
          'Considered an Oral Potentially Malignant Disorder (OPMD). '
          'Requires clinical examination and biopsy to assess for dysplasia.',
    ),
    _LesionExample(
      title: 'Erythroleukoplakia (Mixed Red & White Patch)',
      subtitle: 'Speckled red velvety areas interspersed with white plaques',
      imagePath: AppImages.signErythroleukoplakia,
      keyCharacteristics: [
        'Mixed velvety red and irregular white patches',
        'Often located on lateral borders of tongue or floor of mouth',
        'May cause mild burning sensation with spicy food',
        'Significantly higher risk of malignant transformation than pure white patches',
      ],
      clinicalSignificance:
          'High-risk lesion requiring urgent specialist evaluation and '
          'prompt incisional biopsy.',
    ),
    _LesionExample(
      title: 'Verrucous Leukoplakia (Thickened White Lesion)',
      subtitle: 'Thickened, corrugated or wart-like white surface',
      imagePath: AppImages.signVerrucous,
      keyCharacteristics: [
        'Rough, corrugated, or papillary white surface',
        'Slow progressive extension across mucosal sites',
        'Fibers and folds feel firm on palpation',
      ],
      clinicalSignificance:
          'Needs specialist surgical or oral medicine evaluation to rule '
          'out verrucous carcinoma or proliferative verrucous leukoplakia.',
    ),
    _LesionExample(
      title: 'Chronic Non-Healing Oral Ulcer',
      subtitle: 'Sore persisting for longer than two weeks',
      imagePath: AppImages.signUlcer,
      keyCharacteristics: [
        'Ulcer persisting >2 weeks without healing',
        'Raised, rolled, or indurated (firm) borders',
        'Central crater with slough or bleeding on touch',
        'Unlike common canker sores, does not heal in 7–10 days',
      ],
      clinicalSignificance:
          'Red flag symptom. Any mouth ulcer lasting 14 days or more '
          'mandates urgent professional clinical examination.',
    ),
    _LesionExample(
      title: 'Exophytic Lump / Oral Carcinoma',
      subtitle: 'Abnormal firm thickening or outward tissue growth',
      imagePath: AppImages.signExophytic,
      keyCharacteristics: [
        'Firm nodular swelling or proliferative growth',
        'May have surface ulceration, bleeding, or induration',
        'May cause restricted tongue mobility or pain radiating to ear',
      ],
      clinicalSignificance:
          'Critical red flag requiring immediate oncology/OMFS referral '
          'for tissue biopsy and diagnostic staging.',
    ),
    _LesionExample(
      title: 'Oral Submucous Fibrosis (OSMF)',
      subtitle:
          'Paleness, stiffness, and fibrous bands restricting mouth opening',
      imagePath: AppImages.signOsmf,
      keyCharacteristics: [
        'Blanched, pale, marble-like inner cheek mucosa',
        'Palpable vertical fibrous bands inside cheeks',
        'Progressive difficulty opening mouth wide (trismus)',
        'Burning sensation when eating hot or spicy food',
      ],
      clinicalSignificance:
          'High-risk OPMD strongly associated with areca nut/betel quid and gutkha use. '
          'Requires immediate habit cessation and clinical monitoring.',
    ),

    // Added after clinical review. These are the signs the red-flag checklist
    // asks about that previously had no picture, so a patient was being asked to
    // recognise something they had never been shown.
    _LesionExample(
      title: 'Erythroplakia (Red Patch)',
      subtitle: 'Flat, velvety red patch that does not heal',
      imagePath: AppImages.signRedPatch,
      keyCharacteristics: [
        'Smooth, velvety bright red area, level with the surface',
        'Clearly outlined against the normal pink tissue around it',
        'Does not bleed on its own and is often painless',
        'Frequently on the floor of the mouth or soft palate',
      ],
      clinicalSignificance:
          'Carries the highest risk of dysplasia of any OPMD, higher than a '
          'white patch. A persistent red patch needs prompt clinical assessment '
          'and biopsy.',
    ),
    _LesionExample(
      title: 'Unexplained Bleeding from the Gums',
      subtitle: 'Bleeding with no obvious cause such as injury',
      imagePath: AppImages.signBleedingGums,
      keyCharacteristics: [
        'Blood at the gum margin without brushing or injury',
        'Gums look red, swollen and tender',
        'May recur over days or weeks in the same place',
        'Can occur alongside a patch, lump or ulcer nearby',
      ],
      clinicalSignificance:
          'Most gum bleeding is gum disease rather than cancer, but bleeding '
          'that keeps returning in one spot, or sits next to a patch or lump, '
          'needs examination.',
    ),
    _LesionExample(
      title: 'Persistent Lump in the Neck',
      subtitle: 'A visible swelling that makes the neck look uneven',
      imagePath: AppImages.signNeckLump,
      keyCharacteristics: [
        'One side of the neck visibly fuller than the other',
        'Firm, and often painless to press',
        'Does not settle after two or three weeks',
        'Skin over it looks normal and unbroken',
      ],
      clinicalSignificance:
          'A firm, painless neck lump lasting more than two weeks can be the '
          'first sign of spread and warrants urgent assessment, even when the '
          'mouth itself looks normal.',
    ),
    _LesionExample(
      title: 'Teeth Loosening Without an Obvious Cause',
      subtitle: 'A tooth shifting or tilting with no decay or injury',
      imagePath: AppImages.signLooseTeeth,
      keyCharacteristics: [
        'A tooth visibly tilted or out of line with its neighbours',
        'Gum pulled away from it, exposing more of the root',
        'No decay, injury or long-standing gum disease to explain it',
        'May feel like a change in bite or in how dentures fit',
      ],
      clinicalSignificance:
          'Sudden loosening of a healthy tooth can indicate underlying bone '
          'destruction. It needs dental assessment with imaging rather than '
          'simple extraction.',
    ),
    _LesionExample(
      title: 'Swelling of the Mouth or Jaw',
      subtitle: 'A firm swelling making the face look uneven',
      imagePath: AppImages.signJawSwelling,
      keyCharacteristics: [
        'One side of the jaw or cheek clearly larger than the other',
        'Firm rather than soft, and often painless',
        'Present for weeks and slowly getting bigger',
        'Skin over it normal in colour and unbroken',
      ],
      clinicalSignificance:
          'A firm, slowly enlarging, painless swelling of the jaw is different '
          'from a dental abscess, which is painful and comes on quickly. It '
          'needs imaging and clinical assessment.',
    ),
    _LesionExample(
      title: 'Pus or a Boil in the Mouth',
      subtitle: 'A raised swelling on the gum with pus collecting',
      imagePath: AppImages.signPusBoil,
      keyCharacteristics: [
        'Rounded swelling on the gum with a yellowish point',
        'Surrounding gum red and inflamed',
        'Usually painful, and may discharge a bad taste',
        'Often near a decayed or heavily filled tooth',
      ],
      clinicalSignificance:
          'Usually a dental abscess needing prompt dental treatment rather than '
          'cancer. See a dentist quickly: it will not settle on its own, and '
          'spreading infection in the mouth can become an emergency.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Clinical Reference Photos')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.5,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Realistic Educational Photographs',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Compare your mouth findings with these real clinical '
                          'photographs from public health archives. Remember: '
                          'photographs cannot diagnose cancer. Only a clinician '
                          'and biopsy can provide an accurate diagnosis.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            for (final example in _examples) ...[
              _ExampleCard(example: example),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

/// Fixed greens for the healthy-baseline card. Not taken from the colour scheme
/// because "this is normal" must read as reassuring in both light and dark mode,
/// and the scheme has no semantic success colour.
const Color _baselineGreen = Color(0xFF2E7D32);
const Color _baselineGreenText = Color(0xFF1B5E20);

class _LesionExample {
  const _LesionExample({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.keyCharacteristics,
    required this.clinicalSignificance,
    this.isBaseline = false,
  });

  final String title;
  final String subtitle;
  final String imagePath;
  final List<String> keyCharacteristics;
  final String clinicalSignificance;

  /// True for the healthy-mouth reference, which is styled as a baseline rather
  /// than as another condition to worry about.
  final bool isBaseline;
}

class _ExampleCard extends StatelessWidget {
  const _ExampleCard({required this.example});

  final _LesionExample example;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 4,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.2),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 260,
            child: Stack(
              fit: StackFit.expand,
              children: [
                InteractiveViewer(
                  maxScale: 4.0,
                  child: Image.asset(
                    example.imagePath,
                    // contain, not cover: a reference photograph exists to be
                    // compared against, and cover cropped away the margins of
                    // the lesion that define its appearance.
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 48,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.zoom_in, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Pinch to zoom',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  example.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  example.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Key Signs to Notice:',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                for (final point in example.keyCharacteristics)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            point,
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                // The baseline card is reassurance, not a finding. Rendering the
                // healthy mouth in the same red warning treatment as the
                // pathology cards made normal tissue look abnormal, which is the
                // opposite of what a baseline is for.
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: example.isBaseline
                        ? _baselineGreen.withValues(alpha: 0.13)
                        : theme.colorScheme.errorContainer.withValues(
                            alpha: 0.4,
                          ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        example.isBaseline
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                        size: 18,
                        color: example.isBaseline
                            ? _baselineGreen
                            : theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          example.clinicalSignificance,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: example.isBaseline
                                ? _baselineGreenText
                                : theme.colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w500,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
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
