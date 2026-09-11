import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/clinical_notices.dart';
import '../../core/widgets/common.dart';
import '../../data/models/clinical_models.dart';
import '../../data/models/patient_case.dart';
import '../../data/repositories/clinical_repository.dart';
import '../../domain/risk_engine.dart';
import '../../state/session_controller.dart';

/// Clinical assessment entry (spec Table 8, right column: "Doctor enters /
/// confirms").
///
/// Every field is optional to submit, because a clinician may record an
/// examination before investigations are decided. Yes/No fields keep an explicit
/// "Not recorded" state so a blank is never silently read as "No".
class ClinicalAssessmentScreen extends StatefulWidget {
  const ClinicalAssessmentScreen({super.key, required this.patientCase});

  final PatientCase patientCase;

  @override
  State<ClinicalAssessmentScreen> createState() =>
      _ClinicalAssessmentScreenState();
}

class _ClinicalAssessmentScreenState extends State<ClinicalAssessmentScreen> {
  final _medicalHistory = TextEditingController();
  final _description = TextEditingController();
  final _size = TextEditingController();
  final _impression = TextEditingController();
  final _referralCentre = TextEditingController();
  final _instructions = TextEditingController();
  final _followUpStatus = TextEditingController();

  bool? _examinationPerformed;
  bool? _lesionPresent;
  bool? _investigationRequired;
  bool? _biopsyRequired;
  bool? _patientInformedByText;
  DateTime? _patientInformedDate;
  bool? _referralRequired;
  DateTime? _referralDate;
  DateTime? _patientArrivedDate;
  bool? _patientRemindedByText;
  DateTime? _patientReminderDate;
  DateTime? _followUpDate;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.patientCase.clinicianAssessment;
    if (existing == null) return;

    _medicalHistory.text = existing.relevantMedicalHistory ?? '';
    _examinationPerformed = existing.examinationPerformed;
    _lesionPresent = existing.lesionPresent;
    _description.text = existing.lesionDescription ?? '';
    _size.text = existing.lesionSizeMm?.toString() ?? '';
    _impression.text = existing.clinicalImpression ?? '';
    _investigationRequired = existing.investigationRequired;
    _biopsyRequired = existing.biopsyRequired;
    _patientInformedByText = existing.patientInformedByText;
    _patientInformedDate = existing.patientInformedDate;
    _referralRequired = existing.referralRequired;
    _referralCentre.text = existing.referralCentre ?? '';
    _referralDate = existing.referralDate;
    _patientArrivedDate = existing.patientArrivedDate;
    _patientRemindedByText = existing.patientRemindedByText;
    _patientReminderDate = existing.patientReminderDate;
    _instructions.text = existing.patientInstructions ?? '';
    _followUpDate = existing.followUpDate;
    _followUpStatus.text = existing.followUpStatus ?? '';
  }

  @override
  void dispose() {
    _medicalHistory.dispose();
    _description.dispose();
    _size.dispose();
    _impression.dispose();
    _referralCentre.dispose();
    _instructions.dispose();
    _followUpStatus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final assessmentId = widget.patientCase.assessment.id;
    if (assessmentId == null) {
      showSnack(
        context,
        'This record has no id and cannot be saved.',
        isError: true,
      );
      return;
    }

    final sizeText = _size.text.trim();
    final size = sizeText.isEmpty ? null : double.tryParse(sizeText);
    if (sizeText.isNotEmpty && size == null) {
      showSnack(
        context,
        'Lesion size must be a number in millimetres.',
        isError: true,
      );
      return;
    }

    if (_referralRequired == true && _referralCentre.text.trim().isEmpty) {
      showSnack(
        context,
        'Enter the referral centre when a referral is required.',
        isError: true,
      );
      return;
    }

    setState(() => _saving = true);

    final doctor = context.read<SessionController>().requireUser;
    final record = ClinicianAssessmentRecord(
      assessmentId: assessmentId,
      patientId: widget.patientCase.patientId,
      doctorUsername: doctor.username,
      updatedAt: DateTime.now(),
      relevantMedicalHistory: _nullIfEmpty(_medicalHistory.text),
      examinationPerformed: _examinationPerformed,
      lesionPresent: _lesionPresent,
      lesionDescription: _nullIfEmpty(_description.text),
      lesionSizeMm: size,
      clinicalImpression: _nullIfEmpty(_impression.text),
      investigationRequired: _investigationRequired,
      biopsyRequired: _biopsyRequired,
      patientInformedByText: _patientInformedByText,
      patientInformedDate: _patientInformedDate,
      referralRequired: _referralRequired,
      referralCentre: _nullIfEmpty(_referralCentre.text),
      referralDate: _referralDate,
      patientArrivedDate: _patientArrivedDate,
      patientRemindedByText: _patientRemindedByText,
      patientReminderDate: _patientReminderDate,
      patientInstructions: _nullIfEmpty(_instructions.text),
      followUpDate: _followUpDate,
      followUpStatus: _nullIfEmpty(_followUpStatus.text),
    );

    try {
      await context.read<ClinicalRepository>().saveClinicianAssessment(record);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSnack(context, 'Clinical assessment saved.');
    } catch (e) {
      if (mounted) {
        showSnack(context, 'Could not save. $e', isError: true);
        setState(() => _saving = false);
      }
    }
  }

  String? _nullIfEmpty(String value) =>
      value.trim().isEmpty ? null : value.trim();

  Future<void> _pickDate({
    required DateTime? current,
    required ValueChanged<DateTime> onPicked,
    required String helpText,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? now,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 3),
      helpText: helpText,
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.patientCase.assessment.result;

    return Scaffold(
      appBar: AppBar(title: const Text('Clinical assessment')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            NoticeBanner(
              title: 'Reviewing ${widget.patientCase.patientId}',
              message:
                  'App output: ${result.outputState.headline}. '
                  '${ClinicalNotices.doctorResponsibility}',
              severity: result.professionalCheckRequired
                  ? NoticeSeverity.alert
                  : NoticeSeverity.info,
            ),
            const SizedBox(height: 16),

            SectionCard(
              title: 'Relevant medical history',
              icon: Icons.history_outlined,
              subtitle:
                  'Comorbidity, medication, or anything the structured risk '
                  'factors do not capture.',
              children: [
                TextField(
                  controller: _medicalHistory,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Medical history',
                    hintText:
                        'e.g. diabetes, immunosuppression, anticoagulants, '
                        'previous radiotherapy',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            SectionCard(
              title: 'Examination',
              icon: Icons.medical_services_outlined,
              children: [
                YesNoField(
                  label: 'Clinical examination performed',
                  value: _examinationPerformed,
                  onChanged: (v) => setState(() => _examinationPerformed = v),
                ),
                YesNoField(
                  label: 'Lesion present',
                  value: _lesionPresent,
                  onChanged: (v) => setState(() => _lesionPresent = v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _description,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Lesion description',
                    hintText:
                        'Site, appearance, margins, texture, induration, '
                        'ulceration',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _size,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Greatest dimension (mm)',
                    suffixText: 'mm',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            SectionCard(
              title: 'Provisional clinical impression',
              icon: Icons.psychology_outlined,
              subtitle:
                  'Free text. The app deliberately does not generate or suggest '
                  'a diagnosis.',
              children: [
                TextField(
                  controller: _impression,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Impression',
                    hintText:
                        'e.g. traumatic ulcer, lichenoid reaction, leukoplakia, '
                        'suspicious for malignancy',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            SectionCard(
              title: 'Investigation, biopsy and referral',
              icon: Icons.biotech_outlined,
              children: [
                YesNoField(
                  label: 'Further investigation required',
                  value: _investigationRequired,
                  onChanged: (v) => setState(() => _investigationRequired = v),
                ),
                YesNoField(
                  label: 'Biopsy required',
                  value: _biopsyRequired,
                  onChanged: (v) => setState(() => _biopsyRequired = v),
                ),
                YesNoField(
                  label: 'Referral required',
                  value: _referralRequired,
                  onChanged: (v) => setState(() => _referralRequired = v),
                ),
                if (_referralRequired == true) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _referralCentre,
                    decoration: const InputDecoration(
                      labelText: 'Referral centre',
                    ),
                  ),
                  const SizedBox(height: 14),
                  _DateField(
                    label: 'Referral date',
                    value: _referralDate,
                    onTap: () => _pickDate(
                      current: _referralDate,
                      helpText: 'Referral date',
                      onPicked: (d) => setState(() => _referralDate = d),
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                YesNoField(
                  label: 'Patient informed by text to attend a centre',
                  value: _patientInformedByText,
                  onChanged: (v) => setState(() {
                    _patientInformedByText = v;
                    // Stamp the date on first confirmation, so the record shows
                    // when the instruction actually went out.
                    if (v == true) _patientInformedDate ??= DateTime.now();
                  }),
                ),
                if (_patientInformedByText == true) ...[
                  const SizedBox(height: 10),
                  _DateField(
                    label: 'Date informed',
                    value: _patientInformedDate,
                    onTap: () => _pickDate(
                      current: _patientInformedDate,
                      helpText: 'Date the patient was informed',
                      onPicked: (d) => setState(() => _patientInformedDate = d),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            _AttendanceCard(
              referralRequired: _referralRequired,
              referralDate: _referralDate,
              arrivedDate: _patientArrivedDate,
              remindedByText: _patientRemindedByText,
              reminderDate: _patientReminderDate,
              onPickArrived: () => _pickDate(
                current: _patientArrivedDate,
                helpText: 'Date the patient arrived',
                onPicked: (d) => setState(() => _patientArrivedDate = d),
              ),
              onClearArrived: () => setState(() => _patientArrivedDate = null),
              onRemindedChanged: (v) => setState(() {
                _patientRemindedByText = v;
                if (v == true) _patientReminderDate ??= DateTime.now();
              }),
              onPickReminder: () => _pickDate(
                current: _patientReminderDate,
                helpText: 'Date the reminder was sent',
                onPicked: (d) => setState(() => _patientReminderDate = d),
              ),
            ),
            const SizedBox(height: 14),

            SectionCard(
              title: 'Instructions for the patient',
              icon: Icons.mark_email_read_outlined,
              subtitle:
                  'Shown to the patient in their own record. Keep it plain and '
                  'actionable.',
              children: [
                TextField(
                  controller: _instructions,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Referral and follow-up instructions',
                    hintText:
                        'e.g. Attend City Dental on 20 Sep, bring this record, '
                        'do not use tobacco before the appointment.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            SectionCard(
              title: 'Follow-up',
              icon: Icons.event_repeat_outlined,
              children: [
                _DateField(
                  label: 'Follow-up date',
                  value: _followUpDate,
                  onTap: () => _pickDate(
                    current: _followUpDate,
                    helpText: 'Follow-up date',
                    onPicked: (d) => setState(() => _followUpDate = d),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _followUpStatus,
                  decoration: const InputDecoration(
                    labelText: 'Follow-up status',
                    hintText: 'e.g. scheduled, attended, did not attend',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Text('Save clinical assessment'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Attendance at the referral centre (clinical module spec section 5).
///
/// "Failed to arrive within two weeks" is computed from the referral date rather
/// than typed, so it cannot contradict the dates on the record.
class _AttendanceCard extends StatelessWidget {
  const _AttendanceCard({
    required this.referralRequired,
    required this.referralDate,
    required this.arrivedDate,
    required this.remindedByText,
    required this.reminderDate,
    required this.onPickArrived,
    required this.onClearArrived,
    required this.onRemindedChanged,
    required this.onPickReminder,
  });

  final bool? referralRequired;
  final DateTime? referralDate;
  final DateTime? arrivedDate;
  final bool? remindedByText;
  final DateTime? reminderDate;
  final VoidCallback onPickArrived;
  final VoidCallback onClearArrived;
  final ValueChanged<bool?> onRemindedChanged;
  final VoidCallback onPickReminder;

  @override
  Widget build(BuildContext context) {
    // Mirror the model's rule so the clinician sees the same conclusion the
    // record will store.
    final due = referralDate?.add(
      const Duration(days: ClinicianAssessmentRecord.attendanceWindowDays),
    );
    final overdue =
        referralRequired == true &&
        due != null &&
        arrivedDate == null &&
        !DateTime.now().isBefore(due);

    return SectionCard(
      title: 'Attendance at the centre',
      icon: Icons.how_to_reg_outlined,
      subtitle: referralRequired == true
          ? (due == null
                ? 'Record a referral date to track the two-week window.'
                : 'Expected by ${AppFormats.d(due)}.')
          : 'Only applies once a referral has been made.',
      children: [
        _DateField(
          label: 'Patient arrived (date)',
          value: arrivedDate,
          onTap: onPickArrived,
        ),
        if (arrivedDate != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onClearArrived,
              icon: const Icon(Icons.undo, size: 18),
              label: const Text('Clear arrival'),
            ),
          ),
        if (overdue) ...[
          const SizedBox(height: 10),
          const NoticeBanner(
            title: 'Failed to arrive within two weeks',
            message:
                'The two-week window has passed with no recorded arrival. '
                'Send a reminder and record it below.',
            severity: NoticeSeverity.alert,
          ),
        ],
        const SizedBox(height: 6),
        YesNoField(
          label: 'Patient reminded by text',
          value: remindedByText,
          onChanged: onRemindedChanged,
        ),
        if (remindedByText == true) ...[
          const SizedBox(height: 10),
          _DateField(
            label: 'Date reminded',
            value: reminderDate,
            onTap: onPickReminder,
          ),
        ],
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.event_outlined),
        ),
        child: Text(AppFormats.d(value)),
      ),
    );
  }
}
