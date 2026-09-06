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
  final _description = TextEditingController();
  final _size = TextEditingController();
  final _impression = TextEditingController();
  final _referralCentre = TextEditingController();
  final _followUpStatus = TextEditingController();

  bool? _examinationPerformed;
  bool? _lesionPresent;
  bool? _investigationRequired;
  bool? _biopsyRequired;
  bool? _referralRequired;
  DateTime? _referralDate;
  DateTime? _followUpDate;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.patientCase.clinicianAssessment;
    if (existing == null) return;

    _examinationPerformed = existing.examinationPerformed;
    _lesionPresent = existing.lesionPresent;
    _description.text = existing.lesionDescription ?? '';
    _size.text = existing.lesionSizeMm?.toString() ?? '';
    _impression.text = existing.clinicalImpression ?? '';
    _investigationRequired = existing.investigationRequired;
    _biopsyRequired = existing.biopsyRequired;
    _referralRequired = existing.referralRequired;
    _referralCentre.text = existing.referralCentre ?? '';
    _referralDate = existing.referralDate;
    _followUpDate = existing.followUpDate;
    _followUpStatus.text = existing.followUpStatus ?? '';
  }

  @override
  void dispose() {
    _description.dispose();
    _size.dispose();
    _impression.dispose();
    _referralCentre.dispose();
    _followUpStatus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final assessmentId = widget.patientCase.assessment.id;
    if (assessmentId == null) {
      showSnack(context, 'This record has no id and cannot be saved.',
          isError: true);
      return;
    }

    final sizeText = _size.text.trim();
    final size = sizeText.isEmpty ? null : double.tryParse(sizeText);
    if (sizeText.isNotEmpty && size == null) {
      showSnack(context, 'Lesion size must be a number in millimetres.',
          isError: true);
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
      examinationPerformed: _examinationPerformed,
      lesionPresent: _lesionPresent,
      lesionDescription: _nullIfEmpty(_description.text),
      lesionSizeMm: size,
      clinicalImpression: _nullIfEmpty(_impression.text),
      investigationRequired: _investigationRequired,
      biopsyRequired: _biopsyRequired,
      referralRequired: _referralRequired,
      referralCentre: _nullIfEmpty(_referralCentre.text),
      referralDate: _referralDate,
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
      appBar: AppBar(
        title: const Text('Clinical assessment'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            NoticeBanner(
              title: 'Reviewing ${widget.patientCase.patientId}',
              message: 'App output: ${result.outputState.headline}. '
                  '${ClinicalNotices.doctorResponsibility}',
              severity: result.professionalCheckRequired
                  ? NoticeSeverity.alert
                  : NoticeSeverity.info,
            ),
            const SizedBox(height: 16),

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
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
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
