import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/clinical_notices.dart';
import '../../core/load_guard.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../data/models/assessment_models.dart';
import '../../data/repositories/assessment_repository.dart';
import '../../domain/risk_engine.dart';
import '../../state/assessment_flow.dart';
import '../../state/session_controller.dart';
import '../cessation/cessation_screen.dart';
import '../education/education_screen.dart';
import '../emergency/emergency_screen.dart';
import '../records/digilocker_screen.dart';
import '../referral/referral_screen.dart';
import '../rehabilitation/rehabilitation_screen.dart';
import 'assessment_detail_screen.dart';
import 'consent_screen.dart';
import 'flow_route.dart';
import '../../state/locale_controller.dart';
import 'lesion_reference_dialog.dart';
import 'profile_screen.dart';
import 'reminders_screen.dart';
import 'risk_assessment_screen.dart';

/// Patient experience hub integrating:
/// 1. Self-Check & Risk Assessment
/// 2. Education & Awareness (Multilingual)
/// 3. Medical Records Locker (DigiLocker)
/// 4. Habit Cessation & Recovery Tracker
/// 5. Care, Rehabilitation & Screening Directory
class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _currentTab = 0;
  List<RiskAssessmentRecord> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Loads the assessment history.
  ///
  /// Guarded because the unguarded version was the cause of a spinner that never
  /// stopped: the read threw, the exception escaped, `_loading` stayed true and
  /// the patient was left watching an animation. A spinner must always end in
  /// content or a stated reason.
  Future<void> _load() async {
    final session = context.read<SessionController>();
    final repo = context.read<AssessmentRepository>();
    final patientId = session.user?.patientId;
    if (patientId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (mounted) setState(() => _error = null);

    try {
      final history = await LoadGuard.run(
        repo.assessmentsForPatient(patientId),
      );
      if (!mounted) return;
      setState(() {
        _history = history;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = LoadGuard.message(e, what: 'previous checks');
        _loading = false;
      });
    }
  }

  Future<void> _startAssessment() async {
    final session = context.read<SessionController>();
    final flow = AssessmentFlow(patient: session.requireUser);

    await Navigator.of(
      context,
    ).push(flowRoute(flow, const RiskAssessmentScreen()));

    flow.dispose();
    if (mounted) await _load();
  }

  Future<void> _markFollowUpDone(RiskAssessmentRecord record) async {
    final repo = context.read<AssessmentRepository>();
    if (record.id == null) return;
    await repo.setFollowUp(
      assessmentId: record.id!,
      due: record.followUpDue,
      status: FollowUpStatus.completed,
    );
    if (!mounted) return;
    showSnack(context, 'Follow-up marked as done.');
    await _load();
  }

  Future<void> _openDetail(RiskAssessmentRecord record) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AssessmentDetailScreen(record: record)),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildCheckHub(context),
          const EducationScreen(),
          const DigiLockerScreen(),
          const CessationScreen(),
          const _CareAndRehabHub(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (idx) => setState(() => _currentTab = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.health_and_safety_outlined),
            selectedIcon: Icon(Icons.health_and_safety),
            label: 'Check Hub',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Education',
          ),
          NavigationDestination(
            icon: Icon(Icons.folder_shared_outlined),
            selectedIcon: Icon(Icons.folder_shared),
            label: 'DigiLocker',
          ),
          NavigationDestination(
            icon: Icon(Icons.smoke_free_outlined),
            selectedIcon: Icon(Icons.smoke_free),
            label: 'Cessation',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_hospital_outlined),
            selectedIcon: Icon(Icons.local_hospital),
            label: 'Care & Rehab',
          ),
        ],
      ),
    );
  }

  Widget _buildCheckHub(BuildContext context) {
    final theme = Theme.of(context);
    final session = context.watch<SessionController>();
    final user = session.requireUser;

    final pending = _history
        .where((a) => a.followUpStatus == FollowUpStatus.pending)
        .toList();
    final latest = _history.isEmpty ? null : _history.first;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OralCare'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Real Clinical Photos',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const LesionReferenceDialog(),
                ),
              );
            },
          ),
          // Language switcher. Clinical questions carry verified Kannada
          // wording; the rest of the interface stays English for now.
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Reminders',
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const RemindersScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.translate),
            tooltip: context.watch<LocaleController>().isKannada
                ? 'Switch to English'
                : 'ಕನ್ನಡಕ್ಕೆ ಬದಲಿಸಿ',
            onPressed: context.read<LocaleController>().toggle,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            tooltip: 'My profile',
            onPressed: () async {
              await Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
              if (mounted) await _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.privacy_tip_outlined),
            tooltip: 'Consent choices',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ConsentScreen(isEditing: true),
                ),
              );
              if (mounted) await _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: user.isGuest ? 'Exit guest mode' : 'Sign out',
            onPressed: session.signOut,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Guest Mode Banner if active
              if (user.isGuest) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.onTertiaryContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'You are exploring in Guest Mode. Data is kept for this '
                          'session. Create an account to save records or share with clinicians.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Emergency Alert Banner
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EmergencyScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(
                      alpha: 0.7,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emergency,
                        color: theme.colorScheme.error,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emergency Symptoms & 24/7 Helpline',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                            Text(
                              'Bleeding, breathing difficulty, sudden swelling, or high fever',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.error,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Personalized Hero Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hello${user.fullName != null && user.fullName!.isNotEmpty ? ', ${user.fullName!.split(' ')[0]}' : ''} 👋',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ready to check your oral health?',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.person, color: theme.colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              for (final record in pending)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _FollowUpCard(
                    record: record,
                    onDone: () => _markFollowUpDone(record),
                    onRecheck: _startAssessment,
                  ),
                ),

              // Prominent CTA Card
              Card(
                elevation: 4,
                shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.1),
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.health_and_safety,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Start Self-Check',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'A 3-step guided examination to detect early signs of oral cancer. Takes about 5 minutes.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.8),
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: _startAssessment,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: Text(
                          _history.isEmpty
                              ? 'Begin your first check'
                              : 'Start a new check',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                        ),
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
                        label: const Text('View Clinical Photo Gallery'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: theme.colorScheme.primary,
                          side: BorderSide(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (latest != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Your last result',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _AssessmentTile(
                  record: latest,
                  onTap: () => _openDetail(latest),
                ),
              ],

              if (_history.length > 1) ...[
                const SizedBox(height: 20),
                Text(
                  'Earlier checks',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                for (final record in _history.skip(1))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _AssessmentTile(
                      record: record,
                      onTap: () => _openDetail(record),
                    ),
                  ),
              ],

              if (_loading) ...[
                const SizedBox(height: 24),
                const Center(child: CircularProgressIndicator()),
              ],

              // Stated, with a way out. An error here used to be indistinguishable
              // from an endless spinner.
              if (!_loading && _error != null) ...[
                const SizedBox(height: 24),
                NoticeBanner(
                  title: 'Could not load your previous checks',
                  message: _error!,
                  severity: NoticeSeverity.alert,
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _loading = true);
                      _load();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try again'),
                  ),
                ),
              ],

              if (!_loading && _error == null && _history.isEmpty) ...[
                const SizedBox(height: 24),
                const NoticeBanner(
                  message:
                      'You have not completed a check yet. Your results will '
                      'appear here.',
                ),
              ],

              const SizedBox(height: 20),
              const NoticeBanner(
                message: ClinicalNotices.noDiagnosis,
                severity: NoticeSeverity.info,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _CareAndRehabHub extends StatelessWidget {
  const _CareAndRehabHub();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Care, Centers & Recovery')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Clinical Care & Support Services',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Find certified dental institutions, request clinical appointments, '
              'or access post-treatment side-effect recovery.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Card 1: Screening Centres & Referral Directory
            _HubActionCard(
              title: 'Screening Centres & Dental Colleges',
              subtitle:
                  'Search participating Dental Institutes, OMFS, and Oncology OPDs across Karnataka and India.',
              icon: Icons.local_hospital_outlined,
              badge: 'CENTRES DIRECTORY',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReferralScreen()),
                );
              },
            ),
            const SizedBox(height: 14),

            // Card 2: Post-Treatment Rehabilitation & Side-Effect Recovery
            _HubActionCard(
              title: 'Post-Treatment Rehabilitation & Exercises',
              subtitle:
                  'Tailored physiotherapy for surgery, dry mouth (xerostomia) hydration schedule, and radiation recovery.',
              icon: Icons.fitness_center_outlined,
              badge: 'REHAB & HYDRATION',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const RehabilitationScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // Card 3: Clinical Photo Reference Gallery
            _HubActionCard(
              title: 'Real Clinical Reference Photographs',
              subtitle:
                  'High-clarity photographs of leukoplakia, erythroplakia, ulcers, and oral carcinoma from health archives.',
              icon: Icons.photo_library_outlined,
              badge: 'EDUCATIONAL PHOTOS',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LesionReferenceDialog(),
                  ),
                );
              },
            ),
            const SizedBox(height: 14),

            // Card 4: Emergency Protocols
            _HubActionCard(
              title: 'Emergency Guidance & Action Protocols',
              subtitle:
                  'First-aid protocols for severe bleeding, breathing distress, sudden swelling, and chemotherapy fever.',
              icon: Icons.emergency_outlined,
              badge: '24/7 HELPLINE',
              isUrgent: true,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EmergencyScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HubActionCard extends StatelessWidget {
  const _HubActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badge,
    required this.onTap,
    this.isUrgent = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String badge;
  final VoidCallback onTap;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isUrgent
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isUrgent
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isUrgent
                            ? theme.colorScheme.error.withValues(alpha: 0.15)
                            : theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: isUrgent
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _FollowUpCard extends StatelessWidget {
  const _FollowUpCard({
    required this.record,
    required this.onDone,
    required this.onRecheck,
  });

  final RiskAssessmentRecord record;
  final VoidCallback onDone;
  final VoidCallback onRecheck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overdue = record.isFollowUpOverdue;
    final urgent = record.result.professionalCheckRequired;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: overdue || urgent
            ? theme.colorScheme.errorContainer
            : theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                overdue ? Icons.alarm : Icons.event_available_outlined,
                color: overdue || urgent
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  overdue ? 'Follow-up overdue' : 'Follow-up due',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: overdue || urgent
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            urgent
                ? 'Your last check said a professional check was required. '
                      'Have you been seen?'
                : 'Time to look again and see whether anything has changed.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: overdue || urgent
                  ? theme.colorScheme.onErrorContainer
                  : theme.colorScheme.onSecondaryContainer,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Due ${AppFormats.d(record.followUpDue)} · from your check on '
            '${AppFormats.d(record.createdAt)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color:
                  (overdue || urgent
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.onSecondaryContainer)
                      .withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onRecheck,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text('Check again'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDone,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                  ),
                  child: const Text('Mark done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssessmentTile extends StatelessWidget {
  const _AssessmentTile({required this.record, required this.onTap});

  final RiskAssessmentRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visuals = RiskVisuals.forState(
      record.result.outputState,
      theme.brightness,
    );

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: visuals.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(visuals.icon, color: visuals.onColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.result.outputState.headline,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${AppFormats.dt(record.createdAt)} · score '
                      '${record.result.totalScore} · '
                      '${record.result.category.label.toLowerCase()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (record.sharedWithDoctor)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.share_outlined,
                              size: 13,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Shared with doctor',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
