import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/clinical_notices.dart';
import '../../core/widgets/common.dart';
import '../../data/models/app_user.dart';
import '../../state/session_controller.dart';

/// Consent gate (spec section 2.1, Table 1).
///
/// Three independent gates:
///  - app / self-examination: nothing proceeds without it
///  - photograph: enables or disables image upload
///  - share with doctor: enables or disables doctor access
///
/// Presented as a screen the patient can return to, so consent can be withdrawn
/// as easily as it was given.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key, this.isEditing = false});

  /// `true` when reached from the profile rather than as the initial gate.
  final bool isEditing;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  late ConsentFlags _consent;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _consent = context.read<SessionController>().requireUser.consent;
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    final session = context.read<SessionController>();
    try {
      await session.updateConsent(_consent);
      if (!mounted) return;
      if (widget.isEditing) {
        Navigator.of(context).pop();
        showSnack(context, 'Consent choices saved.');
      }
      // When this is the initial gate, the root router swaps the screen as soon
      // as consent is granted, so no navigation is needed here.
    } catch (e) {
      if (mounted) {
        showSnack(context, 'Could not save consent. $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    context.read<SessionController>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<SessionController>().requireUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Consent choices' : 'Consent'),
        actions: [
          if (!widget.isEditing)
            TextButton(onPressed: _signOut, child: const Text('Sign out')),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Hello${user.fullName != null && user.fullName!.isNotEmpty ? ', ${user.fullName}' : ''}',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Patient ID: ${user.patientId ?? '—'}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            const NoticeBanner(message: ClinicalNotices.consentIntro),
            const SizedBox(height: 16),

            _ConsentTile(
              title: 'Use the app and examine my own mouth',
              detail: ClinicalNotices.consentAppDetail,
              required: true,
              value: _consent.appAndSelfExam,
              onChanged: (v) => setState(
                () => _consent = _consent.copyWith(appAndSelfExam: v),
              ),
            ),
            const SizedBox(height: 12),
            _ConsentTile(
              title: 'Store a photograph of a finding',
              detail: ClinicalNotices.consentPhotoDetail,
              value: _consent.photograph,
              onChanged: (v) =>
                  setState(() => _consent = _consent.copyWith(photograph: v)),
            ),
            const SizedBox(height: 12),
            _ConsentTile(
              title: 'Share my record with a doctor',
              detail: ClinicalNotices.consentShareDetail,
              value: _consent.shareWithDoctor,
              onChanged: (v) => setState(
                () => _consent = _consent.copyWith(shareWithDoctor: v),
              ),
            ),

            const SizedBox(height: 20),
            const NoticeBanner(
              message: ClinicalNotices.noDiagnosis,
              severity: NoticeSeverity.info,
            ),
            const SizedBox(height: 12),
            const NoticeBanner(
              message: ClinicalNotices.storageNotice,
              severity: NoticeSeverity.caution,
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: (_busy || !_consent.appAndSelfExam) ? null : _save,
              child: _busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(
                      widget.isEditing ? 'Save choices' : 'Agree and continue',
                    ),
            ),
            if (!_consent.appAndSelfExam)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'The first consent is required. Without it the app cannot '
                  'guide a self-examination or calculate a risk category.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.title,
    required this.detail,
    required this.value,
    required this.onChanged,
    this.required = false,
  });

  final String title;
  final String detail;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (required)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Required',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}
