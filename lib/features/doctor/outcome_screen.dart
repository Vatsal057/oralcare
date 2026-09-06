import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/common.dart';
import '../../data/models/clinical_models.dart';
import '../../data/models/patient_case.dart';
import '../../data/repositories/clinical_repository.dart';
import '../../domain/risk_engine.dart';
import '../../state/session_controller.dart';

/// Clinical outcome entry (spec section 3.2, Table 9).
///
/// This is the reference standard for validation. The OPMD and OSCC fields
/// decide whether a case counts as disease-positive when app output is compared
/// against the clinical outcome, so they are labelled as "where established"
/// rather than as a guess.
class OutcomeScreen extends StatefulWidget {
  const OutcomeScreen({super.key, required this.patientCase});

  final PatientCase patientCase;

  @override
  State<OutcomeScreen> createState() => _OutcomeScreenState();
}

class _OutcomeScreenState extends State<OutcomeScreen> {
  final _histopathology = TextEditingController();
  final _finalDiagnosis = TextEditingController();

  bool? _professionalExamination;
  bool? _clinicalAbnormality;
  bool? _biopsyPerformed;
  bool? _opmd;
  bool? _oscc;
  bool? _referralCompleted;
  bool? _followUpCompleted;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.patientCase.outcome;
    if (existing == null) {
      // Sensible default: if a clinical assessment recorded that an examination
      // was performed, carry that across rather than asking twice.
      _professionalExamination =
          widget.patientCase.clinicianAssessment?.examinationPerformed;
      _clinicalAbnormality =
          widget.patientCase.clinicianAssessment?.lesionPresent;
      return;
    }

    _professionalExamination = existing.professionalExamination;
    _clinicalAbnormality = existing.clinicalAbnormality;
    _biopsyPerformed = existing.biopsyPerformed;
    _histopathology.text = existing.histopathologyResult ?? '';
    _finalDiagnosis.text = existing.finalDiagnosis ?? '';
    _opmd = existing.opmd;
    _oscc = existing.oscc;
    _referralCompleted = existing.referralCompleted;
    _followUpCompleted = existing.followUpCompleted;
  }

  @override
  void dispose() {
    _histopathology.dispose();
    _finalDiagnosis.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final assessmentId = widget.patientCase.assessment.id;
    if (assessmentId == null) {
      showSnack(context, 'This record has no id and cannot be saved.',
          isError: true);
      return;
    }

    setState(() => _saving = true);

    final doctor = context.read<SessionController>().requireUser;
    final record = OutcomeRecord(
      assessmentId: assessmentId,
      patientId: widget.patientCase.patientId,
      doctorUsername: doctor.username,
      updatedAt: DateTime.now(),
      professionalExamination: _professionalExamination,
      clinicalAbnormality: _clinicalAbnormality,
      biopsyPerformed: _biopsyPerformed,
      histopathologyResult: _nullIfEmpty(_histopathology.text),
      finalDiagnosis: _nullIfEmpty(_finalDiagnosis.text),
      opmd: _opmd,
      oscc: _oscc,
      referralCompleted: _referralCompleted,
      followUpCompleted: _followUpCompleted,
    );

    try {
      await context.read<ClinicalRepository>().saveOutcome(record);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSnack(context, 'Outcome saved to the validation database.');
    } catch (e) {
      if (mounted) {
        showSnack(context, 'Could not save. $e', isError: true);
        setState(() => _saving = false);
      }
    }
  }

  String? _nullIfEmpty(String value) =>
      value.trim().isEmpty ? null : value.trim();

  /// Live preview of how this case will be classified in the validation table.
  String get _agreementPreview {
    final flagged = widget.patientCase.appFlaggedForProfessionalCare;
    if (_opmd == null && _oscc == null) {
      return 'Record OPMD or OSCC to include this case in validation metrics.';
    }
    final positive = (_opmd ?? false) || (_oscc ?? false);

    if (flagged && positive) {
      return 'True positive: the app flagged this patient and disease was '
          'established.';
    }
    if (flagged && !positive) {
      return 'False positive: the app flagged this patient but no OPMD or OSCC '
          'was established.';
    }
    if (!flagged && positive) {
      return 'FALSE NEGATIVE: the app did not flag this patient but disease was '
          'established. This is the case type that matters most for safety.';
    }
    return 'True negative: the app did not flag this patient and no disease was '
        'established.';
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.patientCase.assessment.result;
    final isFalseNegative =
        !widget.patientCase.appFlaggedForProfessionalCare &&
            ((_opmd ?? false) || (_oscc ?? false));

    return Scaffold(
      appBar: AppBar(title: const Text('Clinical outcome')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            NoticeBanner(
              title: widget.patientCase.patientId,
              message:
                  'App output was: ${result.outputState.headline} '
                  '(score ${result.totalScore}, '
                  '${result.category.label.toLowerCase()}). '
                  'What you enter here is the reference standard it is measured '
                  'against.',
            ),
            const SizedBox(height: 16),

            SectionCard(
              title: 'Examination and investigation',
              icon: Icons.fact_check_outlined,
              children: [
                YesNoField(
                  label: 'Professional examination performed',
                  value: _professionalExamination,
                  onChanged: (v) =>
                      setState(() => _professionalExamination = v),
                ),
                YesNoField(
                  label: 'Clinical abnormality found',
                  value: _clinicalAbnormality,
                  onChanged: (v) => setState(() => _clinicalAbnormality = v),
                ),
                YesNoField(
                  label: 'Biopsy performed',
                  value: _biopsyPerformed,
                  onChanged: (v) => setState(() => _biopsyPerformed = v),
                ),
              ],
            ),
            const SizedBox(height: 14),

            SectionCard(
              title: 'Histopathology and diagnosis',
              icon: Icons.biotech_outlined,
              subtitle: 'Enter the reference outcome where available.',
              children: [
                TextField(
                  controller: _histopathology,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Histopathology result',
                    hintText:
                        'e.g. hyperkeratosis, mild/moderate/severe dysplasia, '
                        'carcinoma in situ, squamous cell carcinoma',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _finalDiagnosis,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Final diagnosis',
                    hintText: 'Clinical endpoint',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            SectionCard(
              title: 'Established disease status',
              icon: Icons.rule_outlined,
              subtitle:
                  'These two fields determine how this case counts in the '
                  'validation metrics. Leave as "Not recorded" until '
                  'established.',
              children: [
                YesNoField(
                  label: 'OPMD established',
                  helper: 'Oral potentially malignant disorder.',
                  value: _opmd,
                  onChanged: (v) => setState(() => _opmd = v),
                ),
                YesNoField(
                  label: 'OSCC established',
                  helper: 'Oral squamous cell carcinoma.',
                  value: _oscc,
                  onChanged: (v) => setState(() => _oscc = v),
                ),
                const SizedBox(height: 12),
                NoticeBanner(
                  message: _agreementPreview,
                  severity: isFalseNegative
                      ? NoticeSeverity.alert
                      : NoticeSeverity.info,
                ),
              ],
            ),
            const SizedBox(height: 14),

            SectionCard(
              title: 'Pathway completion',
              icon: Icons.route_outlined,
              children: [
                YesNoField(
                  label: 'Referral completed',
                  value: _referralCompleted,
                  onChanged: (v) => setState(() => _referralCompleted = v),
                ),
                YesNoField(
                  label: 'Follow-up completed',
                  value: _followUpCompleted,
                  onChanged: (v) => setState(() => _followUpCompleted = v),
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
                  : const Text('Save outcome'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
