import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../domain/risk_engine.dart';
import '../referral/referral_screen.dart';
import 'reminders_screen.dart';

/// Referral and follow-up actions, placed on the result itself.
///
/// These two screens already existed, but only from the Care & Rehab tab and an
/// app-bar icon on the home screen — two or three taps away from the moment the
/// app tells someone to see a professional, and in a part of the app a patient
/// finishing an assessment has no reason to open. Being told "arrange a
/// professional oral examination" and then having to go hunting for the centre
/// list is how a referral quietly fails.
///
/// Shown on the result screen and on any past assessment, so the route to a
/// centre is reachable from the record that prompted it.
class NextStepsCard extends StatelessWidget {
  const NextStepsCard({
    super.key,
    required this.outputState,
    this.followUpDue,
  });

  final PatientOutputState outputState;

  /// Drives the reminder row's wording, so it names the date the patient will
  /// actually be reminded about instead of describing the feature.
  final DateTime? followUpDue;

  @override
  Widget build(BuildContext context) {
    final flag = RiskFlag.forState(outputState);

    // A red flag makes finding a centre the primary action, not an option
    // sitting alongside "set a reminder".
    final urgent = flag == RiskFlag.red;

    return SectionCard(
      title: 'Next steps',
      icon: Icons.assistant_direction_outlined,
      subtitle: urgent
          ? 'Find somewhere to be seen, and set a reminder so it does not slip.'
          : 'Where to be seen, and a reminder when your next check is due.',
      children: [
        _ActionRow(
          icon: Icons.local_hospital_outlined,
          title: 'Find a screening centre',
          detail:
              'Dental institutes, oral medicine and oncology centres. You can '
              'also generate a referral slip to hand to a clinician.',
          emphasise: urgent,
          accent: urgent ? flag.color : null,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ReferralScreen()),
          ),
        ),
        const SizedBox(height: 10),
        _ActionRow(
          icon: Icons.notifications_active_outlined,
          title: 'Set a follow-up reminder',
          detail: followUpDue != null
              ? 'Be reminded two days before ${AppFormats.d(followUpDue)}, so '
                    'you do not have to remember the date yourself.'
              : 'Get a monthly reminder to check your own mouth again.',
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RemindersScreen()),
          ),
        ),
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
    this.emphasise = false,
    this.accent,
  });

  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;
  final bool emphasise;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = accent ?? theme.colorScheme.primary;

    return Material(
      color: emphasise
          ? tone.withValues(alpha: 0.08)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: tone),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 4, top: 2),
                child: Icon(Icons.chevron_right, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
