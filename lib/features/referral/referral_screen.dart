import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/common.dart';
import '../../core/load_guard.dart';
import '../../data/models/assessment_models.dart';
import '../../data/repositories/appointment_repository.dart';
import '../../data/repositories/assessment_repository.dart';
import '../../data/repositories/screening_center_repository.dart';
import '../../domain/referral/appointment_request.dart';
import '../../domain/referral/screening_centers_catalog.dart';
import '../../state/session_controller.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  CenterType? _selectedType;
  String _selectedCity = 'All';
  List<AppointmentRequest> _appointments = const [];
  List<ScreeningCenter> _centers = ScreeningCentersCatalog.centers;
  bool _centersAreBundled = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  RiskAssessmentRecord? _latestAssessment;

  @override
  void initState() {
    super.initState();
    _loadLatestAssessment();
    _loadAppointments();
    _loadCenters();
  }

  Future<void> _loadCenters() async {
    try {
      final result = await LoadGuard.run(
        context.read<ScreeningCenterRepository>().load(),
      );
      if (!mounted) return;
      setState(() {
        _centers = result.centers;
        _centersAreBundled = result.isBundled;
      });
    } catch (_) {
      // The repository already falls back to the bundled catalogue, so the
      // directory is never empty. Mark it bundled so the screen tells the
      // patient the details may be out of date and to phone ahead.
      if (!mounted) return;
      setState(() => _centersAreBundled = true);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAppointments() async {
    final user = context.read<SessionController>().user;
    try {
      final list = await LoadGuard.run(
        context.read<AppointmentRepository>().listForPatient(
          user?.patientId ?? 'GUEST',
        ),
      );
      if (!mounted) return;
      setState(() => _appointments = list);
    } catch (_) {
      // A failure here must not blank the directory, which is the main content.
      if (!mounted) return;
      setState(() => _appointments = const []);
    }
  }

  Future<void> _setAppointmentStatus(
    AppointmentRequest request,
    AppointmentStatus status,
  ) async {
    try {
      await context.read<AppointmentRepository>().updateStatus(request, status);
      await _loadAppointments();
    } catch (e) {
      if (mounted) showSnack(context, 'Could not update. $e', isError: true);
    }
  }

  Future<void> _deleteAppointment(AppointmentRequest request) async {
    try {
      await context.read<AppointmentRepository>().delete(request);
      await _loadAppointments();
    } catch (e) {
      if (mounted) showSnack(context, 'Could not remove. $e', isError: true);
    }
  }

  Future<void> _loadLatestAssessment() async {
    final session = context.read<SessionController>();
    final repo = context.read<AssessmentRepository>();
    final patientId = session.user?.patientId;
    if (patientId != null) {
      try {
        final list = await LoadGuard.run(
          repo.assessmentsForPatient(patientId),
        );
        if (list.isNotEmpty && mounted) {
          setState(() => _latestAssessment = list.first);
        }
      } catch (_) {
        // Only feeds the referral slip. Failing quietly is right here: the slip
        // simply reports no assessment rather than blocking the centre list,
        // which is what the patient actually came to this screen for.
      }
    }
  }

  void _showReferralLetter() {
    final session = context.read<SessionController>();
    final user = session.user;
    final assessment = _latestAssessment;

    final letterText = ScreeningCentersCatalog.generateReferralLetter(
      patientName: user?.fullName ?? user?.username ?? 'Patient',
      patientId: user?.patientId ?? 'GUEST',
      age: user?.age,
      gender: user?.gender,
      result: assessment?.result,
      lesionSite: assessment?.answers['lesion_site'],
      lesionDurationDays: assessment?.result.lesionPersistent == true
          ? 14
          : null,
      reportedSymptoms: assessment?.result.redFlagKeys ?? [],
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clinical Referral Slip'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText(
                    letterText,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: letterText));
              showSnack(ctx, 'Referral letter copied to clipboard!');
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copy Slip'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Saves the patient's intention to attend, then tells them plainly that they
  /// still have to ring the centre. The app has no booking integration, so any
  /// wording implying the centre was notified would be false and could lead
  /// someone to wait for a call that never comes.
  Future<void> _saveAppointment(
    ScreeningCenter center,
    DateTime date,
    String slot,
  ) async {
    final session = context.read<SessionController>();
    final repo = context.read<AppointmentRepository>();
    final user = session.user;

    final request = AppointmentRequest(
      id: 'apt_${DateTime.now().microsecondsSinceEpoch}',
      patientId: user?.patientId ?? 'GUEST',
      centerId: center.id,
      centerName: center.name,
      centerPhone: center.phone,
      centerCity: center.city,
      requestedDate: date,
      slot: slot,
      createdAt: DateTime.now(),
    );

    try {
      await repo.save(request);
      if (!mounted) return;
      await _loadAppointments();
      if (!mounted) return;
      showSnack(
        context,
        repo.canPersist
            ? 'Saved to your record for ${AppFormats.d(date)}. '
                  'Now call ${center.phone} to confirm — the centre has not '
                  'been contacted automatically.'
            : 'Saved for this session only. Create an account to keep it, and '
                  'call ${center.phone} to confirm.',
      );
    } catch (e) {
      if (!mounted) return;
      showSnack(context, 'Could not save the request. $e', isError: true);
    }
  }

  void _bookAppointmentModal(ScreeningCenter center) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 2));
    String slot = 'Morning (9:00 AM – 12:00 PM)';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Plan a visit to ${center.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Department: Oral Medicine & Head-Neck Oncology',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 10),
              const NoticeBanner(
                message:
                    'This saves a reminder for you. The app cannot book for '
                    'you — you still need to phone the centre.',
                severity: NoticeSeverity.caution,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Preferred Date'),
                subtitle: Text(AppFormats.d(selectedDate)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime.now().add(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 60)),
                  );
                  if (picked != null) {
                    setDialogState(() => selectedDate = picked);
                  }
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: slot,
                decoration: const InputDecoration(labelText: 'Time Slot'),
                items: const [
                  DropdownMenuItem(
                    value: 'Morning (9:00 AM – 12:00 PM)',
                    child: Text('Morning (9:00 AM – 12:00 PM)'),
                  ),
                  DropdownMenuItem(
                    value: 'Afternoon (1:00 PM – 4:00 PM)',
                    child: Text('Afternoon (1:00 PM – 4:00 PM)'),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => slot = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                _saveAppointment(center, selectedDate, slot);
              },
              child: const Text('Save request'),
            ),
          ],
        ),
      ),
    );
  }

  /// The patient's saved visits, with the phone number kept in front of them and
  /// an explicit prompt while a visit is still unconfirmed.
  Widget _plannedVisitsCard(ThemeData theme) {
    return SectionCard(
      title: 'Your planned visits',
      icon: Icons.event_available_outlined,
      subtitle: 'Saved by you. The app does not contact centres for you.',
      children: [
        for (final request in _appointments) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.centerName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppFormats.d(request.requestedDate)} · ${request.slot}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      request.status.needsPatientAction
                          ? Icons.phone_in_talk_outlined
                          : Icons.check_circle_outline,
                      size: 16,
                      color: request.status.needsPatientAction
                          ? theme.colorScheme.error
                          : theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        request.status.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: request.status.needsPatientAction
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        request.centerPhone,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copy the phone number',
                      icon: const Icon(Icons.copy, size: 18),
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: request.centerPhone),
                        );
                        showSnack(context, 'Phone number copied.');
                      },
                    ),
                  ],
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    if (request.status == AppointmentStatus.recorded)
                      TextButton(
                        onPressed: () => _setAppointmentStatus(
                          request,
                          AppointmentStatus.confirmedWithCentre,
                        ),
                        child: const Text('I have confirmed it'),
                      ),
                    if (request.status == AppointmentStatus.confirmedWithCentre)
                      TextButton(
                        onPressed: () => _setAppointmentStatus(
                          request,
                          AppointmentStatus.attended,
                        ),
                        child: const Text('I attended'),
                      ),
                    if (request.isOpen)
                      TextButton(
                        onPressed: () => _deleteAppointment(request),
                        child: const Text('Remove'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (request != _appointments.last) const Divider(height: 18),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final cities = [
      'All',
      ...{for (final c in _centers) c.city},
    ];

    final filtered = _centers.where((c) {
      if (_selectedType != null && c.type != _selectedType) return false;
      if (_selectedCity != 'All' && c.city != _selectedCity) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return c.name.toLowerCase().contains(q) ||
            c.city.toLowerCase().contains(q) ||
            c.services.any((s) => s.toLowerCase().contains(q));
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Screening Centres & Referrals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.description_outlined),
            tooltip: 'View Referral Letter',
            onPressed: _showReferralLetter,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            NoticeBanner(
              title: 'Check before you travel',
              message: _centersAreBundled
                  ? 'These details are the copy built into the app and may be '
                        'out of date. Phone the centre to confirm timings and '
                        'whether the clinic is running before you go.'
                  : 'Phone the centre to confirm timings and availability '
                        'before you travel.',
              severity: NoticeSeverity.caution,
            ),
            const SizedBox(height: 14),

            if (_appointments.isNotEmpty) ...[
              _plannedVisitsCard(theme),
              const SizedBox(height: 14),
            ],

            // Referral Letter Quick Action Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.6,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Visiting an OPD or Specialist?',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Generate a formatted Clinical Referral Slip with your latest '
                    'symptoms, red flags, and risk score to hand to your dentist or doctor.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _showReferralLetter,
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: const Text('Generate Clinical Referral Slip'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Search input
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search centers, hospitals, cities...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.trim()),
            ),
            const SizedBox(height: 12),

            // City Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final city in cities) ...[
                    ChoiceChip(
                      label: Text(city),
                      selected: _selectedCity == city,
                      onSelected: (sel) {
                        if (sel) setState(() => _selectedCity = city);
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Type Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All Types'),
                    selected: _selectedType == null,
                    onSelected: (_) => setState(() => _selectedType = null),
                  ),
                  const SizedBox(width: 8),
                  for (final t in CenterType.values) ...[
                    FilterChip(
                      label: Text(t.label),
                      selected: _selectedType == t,
                      onSelected: (sel) =>
                          setState(() => _selectedType = sel ? t : null),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Center Cards
            for (final center in filtered)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                center.type.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSecondaryContainer,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              center.city,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          center.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                center.address,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              center.timings,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final s in center.services)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  s,
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text('Call ${center.name}'),
                                    content: Text(
                                      'Contact Number:\n\n${center.phone}',
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
                              label: const Text('Call'),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => _bookAppointmentModal(center),
                                icon: const Icon(
                                  Icons.calendar_month,
                                  size: 18,
                                ),
                                label: const Text('Request Appointment'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
