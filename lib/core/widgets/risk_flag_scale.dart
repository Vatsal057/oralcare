import 'package:flutter/material.dart';

import '../../domain/risk_engine.dart';
import '../theme.dart';

/// The green / yellow / red flag scale for a provisional score.
///
/// Shows all three bands rather than only the one reached, so the patient can
/// see where their score sits on the scale instead of being handed a number
/// with no frame of reference.
///
/// Every row carries the flag, the band name and the score range as text. The
/// colour is a reinforcement, never the only carrier of meaning.
class RiskFlagScale extends StatelessWidget {
  const RiskFlagScale({
    super.key,
    required this.category,
    required this.outputState,
    this.overrideApplied = false,
  });

  /// The numerical band the score fell into.
  final RiskCategory category;

  /// What the patient was actually told, which can outrank the band.
  final PatientOutputState outputState;

  /// True when a red-flag or previous-OSCC override fired.
  final bool overrideApplied;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final band in RiskCategory.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _FlagRow(
              flag: RiskFlag.forCategory(band),
              title: band.label,
              detail: 'Score ${band.rangeLabel}',
              isCurrent: band == category,
            ),
          ),

        // The override has to be stated here, not just on the headline. A red
        // flag on a score of 2 looks like a mistake unless the reason sits next
        // to it, and a patient who reads "green" and stops there has been
        // actively misled by this card.
        if (overrideApplied) ...[
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: RiskFlag.red.tint,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: RiskFlag.red.color.withValues(alpha: 0.45),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.flag, size: 20, color: RiskFlag.red.color),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Red flag — this overrides your score band',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: RiskFlag.red.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'A finding you reported, or your past history, means a '
                        'professional needs to look at this whatever the number '
                        'says.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _FlagRow extends StatelessWidget {
  const _FlagRow({
    required this.flag,
    required this.title,
    required this.detail,
    required this.isCurrent,
  });

  final RiskFlag flag;
  final String title;
  final String detail;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrent ? flag.tint : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent
              ? flag.color.withValues(alpha: 0.5)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: isCurrent ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Filled for the band reached, outlined for the others: the shape
          // difference carries the "you are here" signal without relying on
          // colour or on the background tint.
          Icon(
            isCurrent ? Icons.flag : Icons.flag_outlined,
            size: 21,
            color: isCurrent
                ? flag.color
                : flag.color.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${flag.label} · $title',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                    color: isCurrent
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  isCurrent ? '$detail · ${flag.meaning}' : detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (isCurrent)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                'YOU',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: flag.color,
                  letterSpacing: 0.5,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
