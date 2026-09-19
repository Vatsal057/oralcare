import 'dart:async';
import 'package:flutter/material.dart';

import '../../core/widgets/common.dart';
import '../../domain/rehabilitation/rehabilitation_catalog.dart';

class RehabilitationScreen extends StatefulWidget {
  const RehabilitationScreen({super.key});

  @override
  State<RehabilitationScreen> createState() => _RehabilitationScreenState();
}

class _RehabilitationScreenState extends State<RehabilitationScreen> {
  TreatmentModality _selectedModality = TreatmentModality.surgeryRadiotherapy;
  DateTime _lastHydrationTime = DateTime.now();
  final Set<String> _completedExercises = {};
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _logHydration() {
    setState(() => _lastHydrationTime = DateTime.now());
    showSnack(
      context,
      'Hydration logged! Saliva and water timer reset for '
      '${RehabilitationCatalog.protocols[_selectedModality]?.hydrationReminderHours ?? 2} hours.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final protocol = RehabilitationCatalog.protocols[_selectedModality]!;

    final nextHydration = _lastHydrationTime.add(
      Duration(hours: protocol.hydrationReminderHours),
    );
    final isHydrationDue = DateTime.now().isAfter(nextHydration);

    return Scaffold(
      appBar: AppBar(title: const Text('Post-Treatment Rehabilitation')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Treatment Selector Header
            Text(
              'Select Your Cancer Treatment Received:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final modality in TreatmentModality.values) ...[
                    ChoiceChip(
                      label: Text(modality.label),
                      selected: _selectedModality == modality,
                      onSelected: (sel) {
                        if (sel) setState(() => _selectedModality = modality);
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Modality Description
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.health_and_safety,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedModality.shortDescription,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Hydration & Dry Mouth Reminder Widget
            Card(
              color: isHydrationDue
                  ? theme.colorScheme.errorContainer.withValues(alpha: 0.6)
                  : theme.colorScheme.secondaryContainer.withValues(alpha: 0.5),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isHydrationDue ? Icons.alarm : Icons.water_drop,
                          color: isHydrationDue
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isHydrationDue
                                ? 'Hydration & Dry Mouth Prompt: DUE NOW'
                                : 'Dry Mouth Hydration Schedule',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isHydrationDue
                                  ? theme.colorScheme.onErrorContainer
                                  : theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sip water or artificial saliva every '
                      '${protocol.hydrationReminderHours} hours to lubricate oral mucosa, '
                      'swallow comfortably, and protect teeth from radiation caries.',
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Last sip: ${AppFormats.t(_lastHydrationTime)} · Next due: ${AppFormats.t(nextHydration)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonalIcon(
                      onPressed: _logHydration,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('I Just Had Water / Saliva Spray'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Recovery Priorities
            Text(
              'Key Clinical Priorities',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            for (final priority in protocol.keyPriorities)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        priority,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Physical & Speech Therapy Exercises
            Text(
              'Daily Physical & Speech Exercises',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            for (final ex in protocol.exercises)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ExerciseCard(
                  exercise: ex,
                  isDone: _completedExercises.contains(ex.title),
                  onToggleDone: () {
                    setState(() {
                      if (_completedExercises.contains(ex.title)) {
                        _completedExercises.remove(ex.title);
                      } else {
                        _completedExercises.add(ex.title);
                      }
                    });
                  },
                ),
              ),
            const SizedBox(height: 16),

            // Special Care Instructions
            Text(
              'Special Precautions & Nursing Advice',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            for (final inst in protocol.specialInstructions)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.medical_information_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            inst,
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.isDone,
    required this.onToggleDone,
  });

  final RehabExercise exercise;
  final bool isDone;
  final VoidCallback onToggleDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Target: ${exercise.targetArea}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isDone ? Icons.check_circle : Icons.check_circle_outline,
                    color: isDone
                        ? Colors.green.shade700
                        : theme.colorScheme.outline,
                  ),
                  tooltip: isDone ? 'Completed' : 'Mark done',
                  onPressed: onToggleDone,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              exercise.instruction,
              style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.repeat, size: 14, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  exercise.frequency,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Clinical rationale: ${exercise.clinicalBenefit}',
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
