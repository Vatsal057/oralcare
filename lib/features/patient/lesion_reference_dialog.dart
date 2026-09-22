import 'package:flutter/material.dart';

/// Clinical visual reference guide displaying realistic clinical photographs
/// of oral potentially malignant disorders (OPMD) and suspicious lesions,
/// enabling patients to visually compare their self-examination findings.
class LesionReferenceDialog extends StatelessWidget {
  const LesionReferenceDialog({super.key});

  static const List<_LesionExample> _examples = [
    _LesionExample(
      title: 'Homogeneous Leukoplakia (White Patch)',
      subtitle: 'Flat, uniform white plaque that cannot be scraped off',
      imagePath: 'assets/images/A.png',
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
      imagePath: 'assets/images/B.png',
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
      imagePath: 'assets/images/C.png',
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
      imagePath: 'assets/images/D.png',
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
      imagePath: 'assets/images/E.png',
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
      imagePath: 'assets/images/F.png',
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

class _LesionExample {
  const _LesionExample({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.keyCharacteristics,
    required this.clinicalSignificance,
  });

  final String title;
  final String subtitle;
  final String imagePath;
  final List<String> keyCharacteristics;
  final String clinicalSignificance;
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(
                      alpha: 0.4,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          example.clinicalSignificance,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onErrorContainer,
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
