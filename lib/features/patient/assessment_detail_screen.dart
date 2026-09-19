import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/clinical_notices.dart';
import '../../core/theme.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/local_photo.dart';
import '../../data/models/assessment_models.dart';
import '../../data/models/clinical_models.dart';
import '../../data/photo_store.dart';
import '../../data/repositories/assessment_repository.dart';
import '../../data/repositories/clinical_repository.dart';
import '../../domain/risk_catalog.dart';
import '../../domain/risk_engine.dart';
import 'share_with_doctor_card.dart';

/// Read-only patient view of one past assessment.
///
/// Deliberately does NOT show histopathology or final diagnosis. Communicating a
/// cancer or dysplasia diagnosis is a conversation a clinician must have with
/// the patient, not a field an app reveals. Referral logistics and follow-up
/// dates are shown, because the patient needs those to act.
class AssessmentDetailScreen extends StatefulWidget {
  const AssessmentDetailScreen({super.key, required this.record});

  final RiskAssessmentRecord record;

  @override
  State<AssessmentDetailScreen> createState() => _AssessmentDetailScreenState();
}

class _AssessmentDetailScreenState extends State<AssessmentDetailScreen> {
  SelfExaminationRecord? _selfExam;
  List<LesionRecord> _lesions = [];
  ClinicianAssessmentRecord? _clinician;
  bool _loading = true;
  late bool _shared;
  String? _sharedWithUid;

  @override
  void initState() {
    super.initState();
    _shared = widget.record.sharedWithDoctor;
    _sharedWithUid = widget.record.sharedWithUid;
    _load();
  }

  Future<void> _load() async {
    final id = widget.record.id;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }

    final assessments = context.read<AssessmentRepository>();
    final clinical = context.read<ClinicalRepository>();

    final selfExam = await assessments.selfExaminationFor(id);
    final lesions = await assessments.lesionsFor(id);
    final clinician = await clinical.clinicianAssessmentFor(id);

    if (!mounted) return;
    setState(() {
      _selfExam = selfExam;
      _lesions = lesions;
      _clinician = clinician;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final record = widget.record;
    final result = record.result;
    final visuals = RiskVisuals.forState(result.outputState, theme.brightness);

    return Scaffold(
      appBar: AppBar(title: Text('Check on ${AppFormats.d(record.createdAt)}')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: visuals.color,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(visuals.icon, color: visuals.onColor, size: 26),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                result.outputState.headline,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: visuals.onColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Score ${result.totalScore} · '
                                '${result.category.label}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: visuals.onColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  SectionCard(
                    title: 'Guidance given',
                    icon: Icons.help_outline,
                    children: [
                      Text(
                        result.outputState.guidance,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  SectionCard(
                    title: 'Your answers',
                    icon: Icons.fact_check_outlined,
                    children: [
                      for (final variable in RiskCatalog.variables)
                        if (record.answers[variable.key] != null)
                          DetailRow(
                            label: variable.label,
                            value:
                                variable
                                    .optionFor(record.answers[variable.key])
                                    ?.label ??
                                '—',
                          ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (result.redFlagKeys.isNotEmpty) ...[
                    SectionCard(
                      title: 'Safety-check findings',
                      icon: Icons.flag_outlined,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final key in result.redFlagKeys)
                              Chip(label: Text(RedFlagCatalog.labelFor(key))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  if (_selfExam != null) ...[
                    SectionCard(
                      title: 'Self-examination',
                      icon: Icons.search_outlined,
                      subtitle:
                          '${_selfExam!.examinedCount} of '
                          '${ExamSiteCatalog.sites.length} sites examined.',
                      children: [
                        for (final finding in _selfExam!.findings)
                          DetailRow(
                            label: ExamSiteCatalog.labelFor(finding.siteKey),
                            value: !finding.examined
                                ? 'Not examined'
                                : finding.abnormality
                                ? 'Abnormality reported'
                                : 'Nothing abnormal',
                            emphasise: finding.abnormality,
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  for (final lesion in _lesions) ...[
                    _LesionCard(lesion: lesion),
                    const SizedBox(height: 14),
                  ],

                  SectionCard(
                    title: 'Follow-up',
                    icon: Icons.event_repeat_outlined,
                    children: [
                      DetailRow(
                        label: 'Status',
                        value: record.followUpStatus.label,
                      ),
                      DetailRow(
                        label: 'Due',
                        value: AppFormats.d(record.followUpDue),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (_clinician != null)
                    _DoctorReviewCard(review: _clinician!),
                  if (_clinician != null) const SizedBox(height: 14),

                  ShareWithDoctorCard(
                    assessmentId: widget.record.id,
                    initialShared: _shared,
                    initialDoctorUid: _sharedWithUid,
                    onChanged: (shared, doctorUid) => setState(() {
                      _shared = shared;
                      _sharedWithUid = doctorUid;
                    }),
                  ),

                  const SizedBox(height: 16),
                  const NoticeBanner(
                    message: ClinicalNotices.provisionalScores,
                    severity: NoticeSeverity.caution,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
      ),
    );
  }
}

class _LesionCard extends StatelessWidget {
  const _LesionCard({required this.lesion});

  final LesionRecord lesion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final symptoms = lesion.reportedSymptoms;

    return SectionCard(
      title: 'Recorded finding',
      icon: Icons.healing_outlined,
      children: [
        DetailRow(label: 'Site', value: lesion.site ?? '—'),
        DetailRow(
          label: 'First noticed',
          value: AppFormats.d(lesion.dateFirstNoticed),
        ),
        DetailRow(
          label: 'Duration',
          value: AppFormats.duration(lesion.durationDays),
          emphasise:
              (lesion.durationDays ?? 0) >=
              RiskCatalog.persistenceThresholdDays,
        ),
        DetailRow(
          label: 'Symptoms',
          value: symptoms.isEmpty ? 'None reported' : symptoms.join(', '),
        ),
        if (lesion.note != null && lesion.note!.isNotEmpty)
          DetailRow(label: 'Note', value: lesion.note!),
        if (lesion.hasUploadedPhoto || PhotoStore.exists(lesion.photoPath)) ...[
          const SizedBox(height: 12),
          Text(
            'Photograph',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (lesion.hasUploadedPhoto)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                lesion.photoUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(
                  height: 180,
                  child: Center(child: Text('Could not load the photograph')),
                ),
              ),
            )
          else
            LocalPhoto(path: lesion.photoPath!, height: 180),
          if (!lesion.hasUploadedPhoto) ...[
            const SizedBox(height: 8),
            const NoticeBanner(
              message:
                  'This photograph is only on the device that took it, so a '
                  'clinician cannot see it.',
            ),
          ],
        ],
      ],
    );
  }
}

/// What the patient is allowed to see from the clinician's entry: whether they
/// were examined, and the referral / follow-up logistics they need to act on.
class _DoctorReviewCard extends StatelessWidget {
  const _DoctorReviewCard({required this.review});

  final ClinicianAssessmentRecord review;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Doctor review',
      icon: Icons.medical_information_outlined,
      subtitle: 'Reviewed ${AppFormats.d(review.updatedAt)}.',
      children: [
        DetailRow(
          label: 'Examined',
          value: AppFormats.yesNo(review.examinationPerformed),
        ),
        if (review.referralRequired == true) ...[
          const DetailRow(
            label: 'Referral',
            value: 'Referral arranged',
            emphasise: true,
          ),
          DetailRow(label: 'Centre', value: review.referralCentre ?? '—'),
          DetailRow(label: 'Date', value: AppFormats.d(review.referralDate)),
          if (review.patientArrived)
            DetailRow(
              label: 'You attended',
              value: AppFormats.d(review.patientArrivedDate),
            ),
        ],
        if (review.followUpDate != null)
          DetailRow(
            label: 'Next appointment',
            value: AppFormats.d(review.followUpDate),
            emphasise: true,
          ),
        if (review.patientInstructions != null &&
            review.patientInstructions!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          NoticeBanner(
            title: 'What your doctor asked you to do',
            message: review.patientInstructions!.trim(),
            severity: NoticeSeverity.caution,
          ),
        ],
        const SizedBox(height: 10),
        const NoticeBanner(
          message:
              'Clinical findings and any test results are discussed with you by '
              'your clinician, not shown in the app.',
        ),
      ],
    );
  }
}
