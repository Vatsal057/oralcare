import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/clinical_notices.dart';
import '../../core/widgets/common.dart';
import '../../data/models/app_user.dart';
import '../../state/session_controller.dart';
import 'login_screen.dart';

/// Entry point. The two interfaces are kept visually and structurally separate
/// from the very first screen (spec section 7).
class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.health_and_safety_outlined,
                  size: 40,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'OralCare',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Awareness, early recognition and referral for oral cancer.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              _RoleCard(
                icon: Icons.person_outline,
                title: 'Patient',
                description:
                    'Check your risk, examine your own mouth with step-by-step '
                    'guidance, record anything you find, and get told when to '
                    'see a professional.',
                onTap: () => _open(context, UserRole.patient),
              ),
              const SizedBox(height: 14),
              _RoleCard(
                icon: Icons.medical_information_outlined,
                title: 'Doctor',
                description:
                    'Review consented patient records, record clinical '
                    'examination, investigations, biopsy and referral, and '
                    'enter diagnosis and follow-up outcomes.',
                onTap: () => _open(context, UserRole.doctor),
              ),
              const SizedBox(height: 14),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: InkWell(
                  onTap: () {
                    context.read<SessionController>().continueAsGuest();
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.explore_outlined,
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Explore as Guest',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Browse education, self-exam, habits, and screening '
                                'centres without creating an account.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              const NoticeBanner(
                message: ClinicalNotices.noDiagnosis,
                severity: NoticeSeverity.info,
              ),
              const SizedBox(height: 12),
              const NoticeBanner(
                message: ClinicalNotices.storageNotice,
                severity: NoticeSeverity.caution,
                title: 'Pilot build',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, UserRole role) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => LoginScreen(role: role)));
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$title login',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
