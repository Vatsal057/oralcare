import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/common.dart';
import '../../core/load_guard.dart';
import '../../data/models/doctor_summary.dart';
import '../../data/repositories/assessment_repository.dart';
import '../../data/repositories/doctor_directory_repository.dart';
import '../../state/session_controller.dart';

/// Lets the patient choose which clinician receives this record.
///
/// Sharing is addressed to one clinician rather than broadcast to every doctor
/// using the app, so the patient decides who sees their record. Used by both the
/// result screen and the past-assessment detail screen so the two cannot drift.
class ShareWithDoctorCard extends StatefulWidget {
  const ShareWithDoctorCard({
    super.key,
    required this.assessmentId,
    required this.initialShared,
    required this.initialDoctorUid,
    this.onChanged,
  });

  final int? assessmentId;
  final bool initialShared;
  final String? initialDoctorUid;

  /// Reports the committed state so the parent can update its own copy.
  final void Function(bool shared, String? doctorUid)? onChanged;

  @override
  State<ShareWithDoctorCard> createState() => _ShareWithDoctorCardState();
}

class _ShareWithDoctorCardState extends State<ShareWithDoctorCard> {
  List<DoctorSummary>? _doctors;
  String? _selectedUid;
  bool _shared = false;
  bool _busy = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _shared = widget.initialShared;
    _selectedUid = widget.initialDoctorUid;
    _loadDirectory(initial: true);
  }

  /// [initial] skips the reset, because the first load runs from initState where
  /// there is no built frame to invalidate yet.
  Future<void> _loadDirectory({bool initial = false}) async {
    if (!initial) {
      setState(() {
        _doctors = null;
        _loadError = null;
      });
    }
    try {
      final doctors = await LoadGuard.run(
        context.read<DoctorDirectoryRepository>().all(),
      );
      if (!mounted) return;
      setState(() {
        _doctors = doctors;
        // Drop a stale selection so the dropdown cannot hold a value that is no
        // longer in the directory.
        if (_selectedUid != null &&
            !doctors.any((d) => d.uid == _selectedUid)) {
          _selectedUid = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadError = 'Could not load the clinician list. $e');
    }
  }

  bool get _hasConsent =>
      context.read<SessionController>().requireUser.consent.shareWithDoctor;

  Future<void> _commit({required bool shared, String? doctorUid}) async {
    final id = widget.assessmentId;
    if (id == null) return;

    if (shared && !_hasConsent) {
      showSnack(
        context,
        'Turn on "Share my record with a doctor" in your consent choices first.',
        isError: true,
      );
      return;
    }

    if (shared && (doctorUid == null || doctorUid.isEmpty)) {
      showSnack(
        context,
        'Choose a doctor to send this record to.',
        isError: true,
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await context.read<AssessmentRepository>().setSharing(
        assessmentId: id,
        shared: shared,
        doctorUid: doctorUid,
      );
      if (!mounted) return;
      setState(() {
        _shared = shared;
        _selectedUid = shared ? doctorUid : _selectedUid;
      });
      widget.onChanged?.call(shared, shared ? doctorUid : null);

      final name = _doctors
          ?.firstWhere(
            (d) => d.uid == doctorUid,
            orElse: () => const DoctorSummary(uid: '', username: 'the doctor'),
          )
          .displayName;
      showSnack(
        context,
        shared
            ? 'Sent to ${name ?? 'the doctor'}. Only they can see this record.'
            : 'Withdrawn. No doctor can see this record now.',
      );
    } catch (e) {
      if (mounted) {
        showSnack(context, 'Could not update sharing. $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final consent = context
        .watch<SessionController>()
        .requireUser
        .consent
        .shareWithDoctor;
    final doctors = _doctors;

    return SectionCard(
      title: 'Send to a doctor',
      icon: Icons.share_outlined,
      subtitle: consent
          ? 'You choose who sees this record. Only the doctor you pick can open it.'
          : 'You have not consented to share your record.',
      trailing: consent
          ? IconButton(
              tooltip: 'Refresh the doctor list',
              onPressed: doctors == null || _busy ? null : _loadDirectory,
              icon: const Icon(Icons.refresh),
            )
          : null,
      children: [
        if (!consent)
          const NoticeBanner(
            message:
                'Turn on share consent in your consent choices to send this '
                'record to a doctor.',
            severity: NoticeSeverity.info,
          )
        else if (_loadError != null)
          NoticeBanner(message: _loadError!, severity: NoticeSeverity.alert)
        else if (doctors == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (doctors.isEmpty) ...[
          const NoticeBanner(
            message:
                'No doctors are registered in this pilot yet. Once a clinician '
                'signs in, use refresh to see them here.',
            severity: NoticeSeverity.caution,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _loadDirectory,
              icon: const Icon(Icons.refresh),
              label: const Text('Check again'),
            ),
          ),
        ] else ...[
          DropdownButtonFormField<String>(
            initialValue: _selectedUid,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Doctor',
              prefixIcon: Icon(Icons.medical_information_outlined),
            ),
            items: [
              for (final doctor in doctors)
                DropdownMenuItem(
                  value: doctor.uid,
                  child: Text(
                    doctor.subtitle == null
                        ? doctor.displayName
                        : '${doctor.displayName} · ${doctor.subtitle}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _busy
                ? null
                : (value) {
                    setState(() => _selectedUid = value);
                    // Re-address an already-shared record straight away, so the
                    // previous clinician loses access at the same moment.
                    if (_shared && value != null) {
                      _commit(shared: true, doctorUid: value);
                    }
                  },
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Send this record to the chosen doctor'),
            subtitle: Text(
              _shared
                  ? 'Includes your answers and self-examination findings. You '
                        'can withdraw it at any time.'
                  : 'Nothing is sent until you turn this on.',
            ),
            value: _shared,
            onChanged: _busy
                ? null
                : (value) => _commit(shared: value, doctorUid: _selectedUid),
          ),
          if (_shared && _selectedUid != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Only this doctor can open your record. Other doctors using the '
                'app cannot see it.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
