import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/common.dart';
import '../../core/widgets/load_failure.dart';
import '../../core/load_guard.dart';
import '../../data/repositories/cessation_repository.dart';
import '../../domain/cessation/cessation_models.dart';
import '../../state/session_controller.dart';

class CessationScreen extends StatefulWidget {
  const CessationScreen({super.key});

  @override
  State<CessationScreen> createState() => _CessationScreenState();
}

class _CessationScreenState extends State<CessationScreen> {
  QuitPlan? _plan;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final session = context.read<SessionController>();
    final repo = context.read<CessationRepository>();
    final patientId = session.user?.patientId ?? 'guest';

    try {
      final plan = await LoadGuard.run(repo.getQuitPlan(patientId));
      if (!mounted) return;
      setState(() {
        _plan = plan;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = LoadGuard.message(e, what: 'quit plan');
        _loading = false;
      });
    }
  }

  Future<void> _openSetupPlanDialog() async {
    final session = context.read<SessionController>();
    final patientId = session.user?.patientId ?? 'guest';
    final repo = context.read<CessationRepository>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SetupPlanSheet(
        initialPlan: _plan,
        onSave: (plan) async {
          await repo.saveQuitPlan(patientId: patientId, plan: plan);
          if (mounted) {
            showSnack(context, 'Quit plan updated successfully!');
            await _load();
          }
        },
      ),
    );
  }

  Future<void> _openLogCravingDialog() async {
    final session = context.read<SessionController>();
    final patientId = session.user?.patientId ?? 'guest';
    final repo = context.read<CessationRepository>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CravingAssistantSheet(
        onLogged: (entry) async {
          await repo.logCraving(patientId: patientId, entry: entry);
          if (mounted) {
            showSnack(context, 'Great job resisting the craving!');
            await _load();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Habit Cessation & Recovery')),
        body: LoadFailure(
          title: 'Could not load your quit plan',
          message: _error!,
          onRetry: () {
            setState(() => _loading = true);
            _load();
          },
        ),
      );
    }

    final plan = _plan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Cessation & Recovery'),
        actions: [
          if (plan != null)
            IconButton(
              icon: const Icon(Icons.edit_calendar_outlined),
              tooltip: 'Edit quit plan',
              onPressed: _openSetupPlanDialog,
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (plan == null) ...[
                _buildNoPlanHero(context),
              ] else ...[
                _buildActivePlanDashboard(context, plan),
              ],
              const SizedBox(height: 20),

              // National Quitline Banner
              _buildQuitlineCard(context),
              const SizedBox(height: 20),

              // Health Milestones
              Row(
                children: [
                  Icon(Icons.timeline, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Oral Health Recovery Milestones',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final milestone in CessationCatalog.milestones)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _MilestoneTile(
                    milestone: milestone,
                    isAchieved:
                        plan != null &&
                        milestone.isAchieved(plan.timeSinceQuit),
                  ),
                ),
              const SizedBox(height: 16),

              // Relapse Support Info
              _buildRelapseSupportCard(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoPlanHero(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smoke_free_rounded,
                size: 48,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Start Your Tobacco-Free Journey',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quitting tobacco, gutkha, and areca nut is the single most effective '
              'step to prevent oral cancer. Set a quit date, track your savings, '
              'and watch your oral mucosa regenerate.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _openSetupPlanDialog,
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Set My Quit Date'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePlanDashboard(BuildContext context, QuitPlan plan) {
    final theme = Theme.of(context);
    final days = plan.daysQuit;
    final hours = plan.hoursQuit;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                'TOBACCO-FREE STREAK',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$days',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'DAYS',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    '$hours',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'HRS',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Quit date: ${AppFormats.d(plan.quitDate)}',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Statistics row
        Row(
          children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.savings_outlined,
                        color: Colors.green.shade700,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${plan.moneySaved.toStringAsFixed(0)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: Colors.green.shade800,
                        ),
                      ),
                      Text(
                        'Money Saved',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.block, color: theme.colorScheme.primary),
                      const SizedBox(height: 6),
                      Text(
                        '${plan.unitsAvoided}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Pouches / Cigs Avoided',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Emergency Craving Button
        FilledButton.tonalIcon(
          onPressed: _openLogCravingDialog,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          icon: const Icon(Icons.self_improvement),
          label: const Text('I Have a Craving (Get 3-Min Help)'),
        ),
      ],
    );
  }

  Widget _buildQuitlineCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.phone_in_talk, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Free Professional Support',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'National Tobacco Quitline (India): Toll-free counselors guide '
              'you through withdrawal and cravings in English and regional Indian languages.',
              style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: () {
                    // Show phone number dialog
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Call National Quitline'),
                        content: const Text(
                          'Toll-Free Helpline Number:\n\n1800-11-2356\n\n'
                          'Free counseling is available from 8:00 AM to 8:00 PM.',
                        ),
                        actions: [
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.call, size: 18),
                  label: const Text('Call 1800-11-2356'),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('mCessation SMS Program'),
                        content: const Text(
                          'Give a missed call to:\n\n011-22901701\n\n'
                          'You will receive free motivational messages and '
                          'support SMS from the Ministry of Health and Family Welfare.',
                        ),
                        actions: [
                          FilledButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('SMS Support'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelapseSupportCard(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.shield_outlined, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Relapse is Part of the Journey',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'If you slip and chew or smoke, do not blame yourself or abandon your goal. '
              'A slip is not a failure; it is data on what trigger was challenging. '
              'Throw away the remaining supply, take a deep breath, and restart immediately.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({required this.milestone, required this.isAchieved});

  final HealthMilestone milestone;
  final bool isAchieved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: isAchieved ? 2 : 0,
      color: isAchieved
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isAchieved ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isAchieved
                  ? Colors.green.shade700
                  : theme.colorScheme.outline,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isAchieved ? theme.colorScheme.primary : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    milestone.description,
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
    );
  }
}

class _SetupPlanSheet extends StatefulWidget {
  const _SetupPlanSheet({this.initialPlan, required this.onSave});

  final QuitPlan? initialPlan;
  final Future<void> Function(QuitPlan) onSave;

  @override
  State<_SetupPlanSheet> createState() => _SetupPlanSheetState();
}

class _SetupPlanSheetState extends State<_SetupPlanSheet> {
  DateTime _quitDate = DateTime.now();
  final Set<String> _selectedHabits = {'Smokeless Tobacco / Gutkha'};
  final TextEditingController _unitsController = TextEditingController(
    text: '5',
  );
  final TextEditingController _costController = TextEditingController(
    text: '10',
  );

  final List<String> _availableHabits = [
    'Smokeless Tobacco / Gutkha',
    'Bidi / Cigarette Smoking',
    'Areca Nut / Paan / Supari',
    'Alcohol',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialPlan != null) {
      _quitDate = widget.initialPlan!.quitDate;
      _selectedHabits.clear();
      _selectedHabits.addAll(widget.initialPlan!.habitTypes);
      _unitsController.text = widget.initialPlan!.dailyUnits.toString();
      _costController.text = widget.initialPlan!.costPerUnit.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _unitsController.dispose();
    _costController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Set Your Quit Plan',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month),
              title: const Text('Quit Date'),
              subtitle: Text(AppFormats.d(_quitDate)),
              trailing: const Icon(Icons.edit_calendar),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _quitDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) setState(() => _quitDate = picked);
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Habits you are quitting:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final h in _availableHabits)
                  FilterChip(
                    label: Text(h),
                    selected: _selectedHabits.contains(h),
                    onSelected: (sel) {
                      setState(() {
                        if (sel) {
                          _selectedHabits.add(h);
                        } else {
                          _selectedHabits.remove(h);
                        }
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _unitsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Units per day',
                      helperText: 'Pouches or bidis/cigs',
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Cost per unit (₹)',
                      helperText: 'e.g. ₹10',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                final units = int.tryParse(_unitsController.text.trim()) ?? 5;
                final cost =
                    double.tryParse(_costController.text.trim()) ?? 10.0;
                final plan = QuitPlan(
                  quitDate: _quitDate,
                  habitTypes: _selectedHabits.toList(),
                  dailyUnits: units,
                  costPerUnit: cost,
                  cravingLogs: widget.initialPlan?.cravingLogs ?? [],
                );
                await widget.onSave(plan);
                if (mounted) nav.pop();
              },
              child: const Text('Save Plan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CravingAssistantSheet extends StatefulWidget {
  const _CravingAssistantSheet({required this.onLogged});

  final Future<void> Function(CravingEntry) onLogged;

  @override
  State<_CravingAssistantSheet> createState() => _CravingAssistantSheetState();
}

class _CravingAssistantSheetState extends State<_CravingAssistantSheet> {
  CravingTrigger _trigger = CravingTrigger.stress;
  int _intensity = 3;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.waves, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Ride the Craving Wave',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Cravings peak in 3 to 5 minutes and then fade. Use the 4-D strategy right now:',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '1. DELAY: Wait 5 minutes before acting.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('2. DEEP BREATH: Inhale for 4 secs, hold 4, exhale 6.'),
                Text('3. DRINK WATER: Slowly sip a glass of cold water.'),
                Text('4. DISTRACT: Walk, chew cloves/fennel, or call someone.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'What triggered this craving?',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<CravingTrigger>(
            initialValue: _trigger,
            items: CravingTrigger.values
                .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _trigger = v);
            },
          ),
          const SizedBox(height: 14),
          Text(
            'Intensity: $_intensity / 5',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Slider(
            value: _intensity.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: _intensity.toString(),
            onChanged: (v) => setState(() => _intensity = v.toInt()),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              final nav = Navigator.of(context);
              final entry = CravingEntry(
                id: 'crav_${DateTime.now().millisecondsSinceEpoch}',
                timestamp: DateTime.now(),
                trigger: _trigger,
                intensity: _intensity,
                resisted: true,
              );
              await widget.onLogged(entry);
              if (mounted) nav.pop();
            },
            icon: const Icon(Icons.check),
            label: const Text('I Resisted This Craving!'),
          ),
        ],
      ),
    );
  }
}
