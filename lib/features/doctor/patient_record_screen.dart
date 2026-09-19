import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/local_photo.dart';
import '../../data/models/assessment_models.dart';
import '../../data/models/patient_case.dart';
import '../../data/photo_store.dart';
import '../../data/repositories/clinical_repository.dart';
import '../../data/repositories/digilocker_repository.dart';
import '../../domain/records/digilocker_models.dart';
import '../../domain/risk_catalog.dart';
import '../../domain/risk_engine.dart';
import 'clinical_assessment_screen.dart';
import 'outcome_screen.dart';

/// Doctor's review of one consented patient record (spec Table 8, left column:
/// "Doctor sees from patient login").
class PatientRecordScreen extends StatefulWidget {
  const PatientRecordScreen({super.key, required this.patientCase});

  final PatientCase patientCase;

  @override
  State<PatientRecordScreen> createState() => _PatientRecordScreenState();
}

class _PatientRecordScreenState extends State<PatientRecordScreen> {
  late PatientCase _case;
  bool _loading = false;

  List<DigiLockerRecord> _sharedDocuments = const [];
  String? _documentsError;

  @override
  void initState() {
    super.initState();
    _case = widget.patientCase;
    _loadSharedDocuments();
  }

  /// Documents the patient chose to share. A failure here is surfaced rather
  /// than hidden: a clinician must be able to tell "nothing shared" apart from
  /// "could not load".
  Future<void> _loadSharedDocuments() async {
    try {
      final docs = await context
          .read<DigiLockerRepository>()
          .sharedRecordsForUid(_case.patient.uid);
      if (!mounted) return;
      setState(() {
        _sharedDocuments = docs;
        _documentsError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _documentsError = 'Could not load shared documents. $e');
    }
  }

  Future<void> _reload() async {
    final id = _case.assessment.id;
    if (id == null) return;
    setState(() => _loading = true);
    final fresh = await context.read<ClinicalRepository>().caseForAssessment(
      id,
    );
    if (!mounted) return;
    setState(() {
      if (fresh != null) _case = fresh;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final result = _case.assessment.result;
    final visuals = RiskVisuals.forState(result.outputState, theme.brightness);
    final patient = _case.patient;

    return Scaffold(
      appBar: AppBar(
        title: Text(_case.patientId),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ---- App output -------------------------------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: visuals.color,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(visuals.icon, color: visuals.onColor, size: 26),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'App output: ${result.outputState.headline}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: visuals.onColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Provisional score ${result.totalScore} · '
                    '${result.category.label}'
                    '${result.professionalCheckRequired ? ' · red-flag override applied' : ''}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: visuals.onColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ---- Demographics ----------------------------------------------
            SectionCard(
              title: 'Patient',
              icon: Icons.person_outline,
              children: [
                DetailRow(label: 'Patient ID', value: _case.patientId),
                DetailRow(label: 'Age', value: '${patient.age ?? '—'}'),
                DetailRow(
                  label: 'Gender',
                  value: patient.gender ?? 'Not recorded',
                ),
                DetailRow(
                  label: 'Assessment',
                  value: AppFormats.dt(_case.assessment.createdAt),
                ),
                DetailRow(
                  label: 'Photo consent',
                  value: AppFormats.yesNo(patient.consent.photograph),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ---- Engine reasoning ------------------------------------------
            SectionCard(
              title: 'How the app reached this output',
              icon: Icons.account_tree_outlined,
              children: [
                for (final reason in result.reasons)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      reason.detail,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // ---- Risk factors ----------------------------------------------
            SectionCard(
              title: 'Risk factors and score',
              icon: Icons.assessment_outlined,
              subtitle: ClinicalNoticesInline.provisional,
              children: [
                for (final variable in RiskCatalog.variables)
                  if (_case.assessment.answers[variable.key] != null)
                    DetailRow(
                      label: variable.label,
                      value: _formatAnswer(variable),
                    ),
                if (result.hasUnknownAnswers) ...[
                  const Divider(height: 20),
                  DetailRow(
                    label: 'Unknown answers',
                    value: result.unknownAnswerKeys
                        .map((k) => RiskCatalog.variableFor(k).label)
                        .join(', '),
                    emphasise: true,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 14),

            // ---- Red flags --------------------------------------------------
            if (result.redFlagPresent) ...[
              SectionCard(
                title: 'Red flags reported',
                icon: Icons.flag_outlined,
                subtitle: result.lesionPersistent
                    ? 'Present for two weeks or longer.'
                    : 'Present for less than two weeks.',
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final key in result.redFlagKeys)
                        Chip(
                          avatar: Icon(
                            Icons.warning_amber_rounded,
                            size: 16,
                            color: theme.colorScheme.error,
                          ),
                          label: Text(RedFlagCatalog.labelFor(key)),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // ---- Self-examination -------------------------------------------
            if (_case.selfExamination != null) ...[
              SectionCard(
                title: 'Patient self-examination',
                icon: Icons.search_outlined,
                subtitle:
                    '${_case.selfExamination!.examinedCount} of '
                    '${ExamSiteCatalog.sites.length} sites examined. '
                    'Patient-reported, not a clinical finding.',
                children: [
                  for (final finding in _case.selfExamination!.findings)
                    DetailRow(
                      label: ExamSiteCatalog.labelFor(finding.siteKey),
                      value: !finding.examined
                          ? 'Not examined'
                          : finding.abnormality
                          ? 'Abnormality reported'
                          : 'No abnormality',
                      emphasise: finding.abnormality,
                    ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // ---- Lesion records ---------------------------------------------
            for (final lesion in _case.viewableLesions) ...[
              _LesionCard(
                lesion: lesion,
                photoAllowed: _case.photoViewingAllowed,
              ),
              const SizedBox(height: 14),
            ],

            // ---- Patient-shared documents -----------------------------------
            SectionCard(
              title: 'Documents shared by the patient',
              icon: Icons.folder_shared_outlined,
              subtitle: _documentsError == null
                  ? 'Only items the patient marked as shared are listed.'
                  : null,
              children: [
                if (_documentsError != null)
                  NoticeBanner(
                    message: _documentsError!,
                    severity: NoticeSeverity.alert,
                  )
                else if (_sharedDocuments.isEmpty)
                  const NoticeBanner(
                    message: 'The patient has not shared any documents.',
                  )
                else
                  for (final doc in _sharedDocuments)
                    DetailRow(
                      label: doc.category.label,
                      value:
                          '${doc.title} · ${AppFormats.d(doc.documentDate)}'
                          '${doc.facilityOrDoctor.isEmpty ? '' : ' · ${doc.facilityOrDoctor}'}'
                          '${doc.notes == null || doc.notes!.isEmpty ? '' : '\n${doc.notes}'}',
                    ),
              ],
            ),
            const SizedBox(height: 14),

            // ---- Clinician entry --------------------------------------------
            _ClinicianSummaryCard(
              patientCase: _case,
              onEdit: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ClinicalAssessmentScreen(patientCase: _case),
                  ),
                );
                if (mounted) await _reload();
              },
            ),
            const SizedBox(height: 14),

            _OutcomeSummaryCard(
              patientCase: _case,
              onEdit: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => OutcomeScreen(patientCase: _case),
                  ),
                );
                if (mounted) await _reload();
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _formatAnswer(RiskVariable variable) {
    final value = _case.assessment.answers[variable.key];
    final option = variable.optionFor(value);
    final label = option?.label ?? value ?? '—';
    final contribution = _case.assessment.result.scoreBreakdown[variable.key];

    if (option?.unweighted == true) return '$label (recorded, not scored)';
    if (option?.unknown == true) return '$label (unknown)';
    if (contribution != null && contribution > 0) {
      return '$label (+$contribution)';
    }
    return label;
  }
}

/// Short inline notices, kept next to the doctor-facing score display.
class ClinicalNoticesInline {
  const ClinicalNoticesInline._();
  static const String provisional =
      'Provisional pilot weights. Not yet clinically validated.';
}

class _LesionCard extends StatelessWidget {
  const _LesionCard({required this.lesion, required this.photoAllowed});

  final LesionRecord lesion;
  final bool photoAllowed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final symptoms = lesion.reportedSymptoms;
    final persistent =
        (lesion.durationDays ?? 0) >= RiskCatalog.persistenceThresholdDays;

    return SectionCard(
      title: 'Lesion record',
      icon: Icons.healing_outlined,
      subtitle: 'Patient-recorded on ${AppFormats.d(lesion.createdAt)}.',
      children: [
        DetailRow(label: 'Site', value: lesion.site ?? '—'),
        DetailRow(
          label: 'First noticed',
          value: AppFormats.d(lesion.dateFirstNoticed),
        ),
        DetailRow(
          label: 'Duration',
          value: AppFormats.duration(lesion.durationDays),
          emphasise: persistent,
        ),
        DetailRow(
          label: 'Symptoms',
          value: symptoms.isEmpty ? 'None reported' : symptoms.join(', '),
        ),
        if (lesion.note != null && lesion.note!.isNotEmpty)
          DetailRow(label: 'Patient note', value: lesion.note!),

        const SizedBox(height: 10),
        if (!photoAllowed)
          const NoticeBanner(
            message:
                'The patient has not consented to share a photograph, so none '
                'is shown.',
          )
        // hasUploadedPhoto must come first: PhotoStore.exists is always false
        // off-device, so relying on it alone hid uploaded photographs from any
        // clinician who was not on the capturing phone.
        else if (lesion.hasUploadedPhoto ||
            PhotoStore.exists(lesion.photoPath)) ...[
          Text(
            'Patient photograph',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          // The uploaded copy is the only one visible from another device, so it
          // is preferred whenever it exists.
          if (lesion.hasUploadedPhoto)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                lesion.photoUrl!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 220,
                  child: Center(
                    child: Text('Could not load the uploaded photograph'),
                  ),
                ),
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const SizedBox(
                        height: 220,
                        child: Center(child: CircularProgressIndicator()),
                      ),
              ),
            )
          else
            LocalPhoto(
              path: lesion.photoPath!,
              height: 220,
              onTap: () => _openFullScreen(context, lesion.photoPath!),
            ),
          const SizedBox(height: 8),
          const NoticeBanner(
            message:
                'Patient-captured image. Lighting, focus and angle are '
                'uncontrolled, so it does not replace direct examination.',
            severity: NoticeSeverity.caution,
          ),
        ] else
          const NoticeBanner(message: 'No photograph attached.'),
      ],
    );
  }

  void _openFullScreen(BuildContext context, String path) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => LocalPhotoFullscreen(path: path)));
  }
}

class _ClinicianSummaryCard extends StatelessWidget {
  const _ClinicianSummaryCard({
    required this.patientCase,
    required this.onEdit,
  });

  final PatientCase patientCase;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final review = patientCase.clinicianAssessment;

    return SectionCard(
      title: 'Clinical assessment',
      icon: Icons.medical_services_outlined,
      subtitle: review == null
          ? 'Not started.'
          : 'Last updated ${AppFormats.dt(review.updatedAt)} by '
                '${review.doctorUsername}.',
      children: [
        if (review != null) ...[
          DetailRow(
            label: 'Examination performed',
            value: AppFormats.yesNo(review.examinationPerformed),
          ),
          DetailRow(
            label: 'Lesion present',
            value: AppFormats.yesNo(review.lesionPresent),
          ),
          if (review.lesionDescription != null &&
              review.lesionDescription!.isNotEmpty)
            DetailRow(label: 'Description', value: review.lesionDescription!),
          if (review.lesionSizeMm != null)
            DetailRow(
              label: 'Size',
              value: '${review.lesionSizeMm!.toStringAsFixed(1)} mm',
            ),
          if (review.clinicalImpression != null &&
              review.clinicalImpression!.isNotEmpty)
            DetailRow(
              label: 'Impression',
              value: review.clinicalImpression!,
              emphasise: true,
            ),
          DetailRow(
            label: 'Investigation',
            value: AppFormats.yesNo(review.investigationRequired),
          ),
          DetailRow(
            label: 'Biopsy required',
            value: AppFormats.yesNo(review.biopsyRequired),
          ),
          DetailRow(
            label: 'Referral required',
            value: AppFormats.yesNo(review.referralRequired),
          ),
          if (review.referralRequired == true) ...[
            DetailRow(label: 'Centre', value: review.referralCentre ?? '—'),
            DetailRow(label: 'Date', value: AppFormats.d(review.referralDate)),
          ],
          DetailRow(
            label: 'Informed by text',
            value: AppFormats.yesNo(review.patientInformedByText),
          ),
          if (review.patientInformedByText == true)
            DetailRow(
              label: 'Date informed',
              value: AppFormats.d(review.patientInformedDate),
            ),
          if (review.referralRequired == true) ...[
            DetailRow(
              label: 'Patient arrived',
              value: review.patientArrived
                  ? AppFormats.d(review.patientArrivedDate)
                  : 'Not recorded',
              emphasise: review.patientArrived,
            ),
            if (review.failedToArriveWithinTwoWeeks())
              const DetailRow(
                label: 'Attendance',
                value: 'Failed to arrive within two weeks',
                emphasise: true,
              ),
            DetailRow(
              label: 'Reminded by text',
              value: AppFormats.yesNo(review.patientRemindedByText),
            ),
            if (review.patientRemindedByText == true)
              DetailRow(
                label: 'Date reminded',
                value: AppFormats.d(review.patientReminderDate),
              ),
          ],
          if (review.relevantMedicalHistory != null &&
              review.relevantMedicalHistory!.isNotEmpty)
            DetailRow(
              label: 'Medical history',
              value: review.relevantMedicalHistory!,
            ),
          if (review.patientInstructions != null &&
              review.patientInstructions!.isNotEmpty)
            DetailRow(
              label: 'Patient instructions',
              value: review.patientInstructions!,
            ),
          DetailRow(
            label: 'Follow-up',
            value: AppFormats.d(review.followUpDate),
          ),
          if (review.followUpStatus != null &&
              review.followUpStatus!.isNotEmpty)
            DetailRow(label: 'Follow-up status', value: review.followUpStatus!),
          const SizedBox(height: 12),
        ] else
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: NoticeBanner(
              message:
                  'Record the clinical examination, impression, investigations '
                  'and referral for this assessment.',
            ),
          ),
        FilledButton.icon(
          onPressed: onEdit,
          icon: Icon(review == null ? Icons.add : Icons.edit_outlined),
          label: Text(
            review == null ? 'Record clinical assessment' : 'Edit assessment',
          ),
        ),
      ],
    );
  }
}

class _OutcomeSummaryCard extends StatelessWidget {
  const _OutcomeSummaryCard({required this.patientCase, required this.onEdit});

  final PatientCase patientCase;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final outcome = patientCase.outcome;

    return SectionCard(
      title: 'Clinical outcome',
      icon: Icons.science_outlined,
      subtitle: outcome == null
          ? 'Not started. This is the reference standard used to validate the '
                'algorithm.'
          : 'Last updated ${AppFormats.dt(outcome.updatedAt)}.',
      children: [
        if (outcome != null) ...[
          DetailRow(
            label: 'Professional exam',
            value: AppFormats.yesNo(outcome.professionalExamination),
          ),
          DetailRow(
            label: 'Clinical abnormality',
            value: AppFormats.yesNo(outcome.clinicalAbnormality),
          ),
          DetailRow(
            label: 'Biopsy performed',
            value: AppFormats.yesNo(outcome.biopsyPerformed),
          ),
          if (outcome.histopathologyResult != null &&
              outcome.histopathologyResult!.isNotEmpty)
            DetailRow(
              label: 'Histopathology',
              value: outcome.histopathologyResult!,
            ),
          if (outcome.finalDiagnosis != null &&
              outcome.finalDiagnosis!.isNotEmpty)
            DetailRow(
              label: 'Final diagnosis',
              value: outcome.finalDiagnosis!,
              emphasise: true,
            ),
          DetailRow(label: 'OPMD', value: AppFormats.yesNo(outcome.opmd)),
          DetailRow(label: 'OSCC', value: AppFormats.yesNo(outcome.oscc)),
          DetailRow(
            label: 'Referral completed',
            value: AppFormats.yesNo(outcome.referralCompleted),
          ),
          DetailRow(
            label: 'Follow-up completed',
            value: AppFormats.yesNo(outcome.followUpCompleted),
          ),
          const SizedBox(height: 12),
        ] else
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: NoticeBanner(
              message:
                  'Enter biopsy, histopathology, final diagnosis and follow-up '
                  'so app output can be compared against the clinical outcome.',
            ),
          ),
        OutlinedButton.icon(
          onPressed: onEdit,
          icon: Icon(outcome == null ? Icons.add : Icons.edit_outlined),
          label: Text(outcome == null ? 'Enter outcome' : 'Edit outcome'),
        ),
      ],
    );
  }
}
