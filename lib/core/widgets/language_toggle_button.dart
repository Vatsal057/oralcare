import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/locale_controller.dart';

/// English / Kannada switch for clinical wording.
///
/// WHY THIS IS A SHARED WIDGET: the toggle used to exist only on the home
/// screen, while the only screens that actually translate anything are inside
/// the assessment flow. Tapping it therefore changed nothing the patient could
/// see, which read as the feature being broken. A control has to live on the
/// screens it affects.
class LanguageToggleButton extends StatelessWidget {
  const LanguageToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LocaleController>();

    return IconButton(
      // The tooltip is written in the language being offered, not the current
      // one, so a Kannada reader can find it without reading English.
      tooltip: controller.isKannada ? 'Switch to English' : 'ಕನ್ನಡಕ್ಕೆ ಬದಲಿಸಿ',
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.translate, size: 20),
          const SizedBox(width: 4),
          Text(
            controller.isKannada ? 'ಕ' : 'EN',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      onPressed: context.read<LocaleController>().toggle,
    );
  }
}

/// States what the language switch does and does not cover.
///
/// Shown only in Kannada, where the mixed-language screen would otherwise look
/// like a half-finished translation rather than a deliberate limit. The English
/// terms are not leftovers: they are the questions the clinical questionnaire
/// supplies no Kannada for, and guessing at them could change what is being
/// asked.
class PartialTranslationNote extends StatelessWidget {
  const PartialTranslationNote({super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.watch<LocaleController>().isKannada) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'ವೈದ್ಯಕೀಯ ಪದಗಳು ಕನ್ನಡದಲ್ಲಿವೆ. ಉಳಿದ ಭಾಗ ಇಂಗ್ಲಿಷ್‌ನಲ್ಲಿದೆ.\n'
              'Clinical terms are shown in Kannada. The rest of the screen '
              'stays in English.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
