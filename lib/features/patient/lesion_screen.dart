import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/common.dart';
import '../../core/widgets/local_photo.dart';
import '../../data/photo_document_store.dart';
import '../../data/photo_store.dart';
import '../../domain/risk_catalog.dart';
import '../../state/assessment_flow.dart';
import 'flow_route.dart';
import 'result_screen.dart';

/// Lesion recording (spec section 2.5, Table 6).
///
/// Opened when the guided self-examination reports an abnormality, or when the
/// patient reported a suspicious lesion or symptom on the risk form.
class LesionScreen extends StatefulWidget {
  const LesionScreen({super.key});

  @override
  State<LesionScreen> createState() => _LesionScreenState();
}

class _LesionScreenState extends State<LesionScreen> {
  final _duration = TextEditingController();
  final _note = TextEditingController();
  bool _pickingPhoto = false;

  @override
  void initState() {
    super.initState();
    final draft = context.read<AssessmentFlow>().lesion;
    if (draft.durationValue != null) {
      _duration.text = draft.durationValue.toString();
    }
    _note.text = draft.note;
  }

  @override
  void dispose() {
    _duration.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final flow = context.read<AssessmentFlow>();

    // Defence in depth: the button is hidden without consent, and consent is
    // re-checked here so no future refactor can bypass the gate.
    if (!flow.photographAllowed) {
      showSnack(
        context,
        'Photograph consent has not been given. You can change this in your '
        'consent choices.',
        isError: true,
      );
      return;
    }

    setState(() => _pickingPhoto = true);
    try {
      final picker = ImagePicker();
      // Downscaled hard at capture. The photograph is stored inside a Firestore
      // document, and Firestore caps a document at 1 MiB, so an image that is
      // too big is an image no clinician ever sees. 1024px at quality 55 lands
      // well inside the limit on the phone cameras this pilot runs on.
      //
      // The same file is kept locally rather than keeping a sharper second copy:
      // one image means the clinician sees exactly what the patient sees.
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 55,
      );
      if (picked == null) return;

      final stored = await PhotoStore.store(picked.path, flow.patientId);
      await PhotoStore.delete(flow.lesion.photoPath);
      flow.lesion.photoPath = stored;
      // Held until the lesion has an id to store it against, so a clinician on
      // another device can see it. Read now, because the picked file is
      // temporary.
      final bytes = await picked.readAsBytes();
      flow.lesion.photoBytes = bytes;
      flow.touchLesion();

      // Told now, while the patient can still retake it, instead of only at the
      // end of the assessment.
      if (!PhotoDocumentStore.isWithinLimit(bytes.length) && mounted) {
        showSnack(
          context,
          'This photograph is too large to send to a doctor. Try taking it '
          'again, a little further back.',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showSnack(context, 'Could not add the photograph. $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    final flow = context.read<AssessmentFlow>();
    await PhotoStore.delete(flow.lesion.photoPath);
    flow.lesion.photoPath = null;
    flow.lesion.photoBytes = null;
    flow.touchLesion();
  }

  Future<void> _pickDate() async {
    final flow = context.read<AssessmentFlow>();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: flow.lesion.dateFirstNoticed ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      helpText: 'When did you first notice it?',
    );
    if (picked == null) return;

    flow.lesion.dateFirstNoticed = picked;
    // Keep duration consistent with the date, unless the patient already typed
    // a duration themselves.
    if (flow.lesion.durationValue == null) {
      final days = now.difference(picked).inDays;
      flow.lesion.durationValue = days;
      flow.lesion.durationUnit = 'days';
      _duration.text = days.toString();
    }
    flow.touchLesion();
  }

  @override
  Widget build(BuildContext context) {
    final flow = context.watch<AssessmentFlow>();
    final draft = flow.lesion;
    final theme = Theme.of(context);

    final abnormalSites = flow.findings
        .where((f) => f.abnormality)
        .map((f) => ExamSiteCatalog.labelFor(f.siteKey))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Step 3 of 3 · Record the finding'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: 0.8,
            minHeight: 4,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (abnormalSites.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: NoticeBanner(
                  title: 'From your self-examination',
                  message:
                      'You marked a finding at: ${abnormalSites.join(', ')}.',
                  severity: NoticeSeverity.caution,
                ),
              ),

            SectionCard(
              title: 'Where and how long',
              icon: Icons.place_outlined,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: draft.site,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Lesion site'),
                  items: LesionSites.values
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (value) {
                    draft.site = value;
                    flow.touchLesion();
                  },
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Date first noticed',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    child: Text(AppFormats.d(draft.dateFirstNoticed)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _duration,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duration',
                        ),
                        onChanged: (value) {
                          draft.durationValue = int.tryParse(value.trim());
                          flow.touchLesion();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: draft.durationUnit,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        items: const [
                          DropdownMenuItem(value: 'days', child: Text('days')),
                          DropdownMenuItem(
                            value: 'weeks',
                            child: Text('weeks'),
                          ),
                        ],
                        onChanged: (value) {
                          draft.durationUnit = value ?? 'days';
                          flow.touchLesion();
                        },
                      ),
                    ),
                  ],
                ),
                if (draft.durationDays != null) ...[
                  const SizedBox(height: 10),
                  _DurationHint(days: draft.durationDays!),
                ],
              ],
            ),
            const SizedBox(height: 14),

            SectionCard(
              title: 'Symptoms',
              icon: Icons.checklist_outlined,
              subtitle: 'Tick everything that applies.',
              children: [
                _symptom(flow, 'Pain', draft.pain, (v) => draft.pain = v),
                _symptom(
                  flow,
                  'Bleeding',
                  draft.bleeding,
                  (v) => draft.bleeding = v,
                ),
                _symptom(
                  flow,
                  'Change in size',
                  draft.changeInSize,
                  (v) => draft.changeInSize = v,
                ),
                _symptom(
                  flow,
                  'Change in colour',
                  draft.changeInColour,
                  (v) => draft.changeInColour = v,
                ),
                _symptom(
                  flow,
                  'Numbness',
                  draft.numbness,
                  (v) => draft.numbness = v,
                ),
                _symptom(
                  flow,
                  'Difficulty chewing or swallowing',
                  draft.difficultySwallowing,
                  (v) => draft.difficultySwallowing = v,
                ),
                _symptom(
                  flow,
                  'Restricted tongue or jaw movement',
                  draft.restrictedMovement,
                  (v) => draft.restrictedMovement = v,
                ),
              ],
            ),
            const SizedBox(height: 14),

            SectionCard(
              title: 'Photograph',
              icon: Icons.photo_camera_outlined,
              subtitle: flow.photographAllowed
                  // Matches ClinicalNotices.consentPhotoDetail: the photograph
                  // is saved to the patient's account, not kept on the phone.
                  ? 'Optional. Saved to your account. No doctor can see it '
                        'unless you share this record with one.'
                  : 'You have not given photograph consent, so this is turned '
                        'off.',
              children: [
                if (kIsWeb)
                  const NoticeBanner(
                    message:
                        'Photographs and camera capture are unavailable in the '
                        'web pilot. You can still record the finding details.',
                    severity: NoticeSeverity.info,
                  )
                else if (!flow.photographAllowed)
                  const NoticeBanner(
                    message:
                        'To add a photograph, turn on photograph consent in '
                        'your consent choices.',
                    severity: NoticeSeverity.info,
                  )
                else if (PhotoStore.exists(draft.photoPath)) ...[
                  LocalPhoto(path: draft.photoPath!, height: 200),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _removePhoto,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Remove photograph'),
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickingPhoto
                              ? null
                              : () => _pickPhoto(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickingPhoto
                              ? null
                              : () => _pickPhoto(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),

            SectionCard(
              title: 'Anything else',
              icon: Icons.notes_outlined,
              children: [
                TextField(
                  controller: _note,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: const InputDecoration(
                    labelText: 'Additional note',
                    hintText: 'In your own words, what have you noticed?',
                  ),
                  onChanged: (value) {
                    draft.note = value;
                    flow.touchLesion();
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.of(
                context,
              ).push(flowRoute(flow, const ResultScreen())),
              child: const Text('See my result'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _symptom(
    AssessmentFlow flow,
    String label,
    bool value,
    ValueChanged<bool> setter,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(label),
      value: value,
      onChanged: (v) {
        setter(v);
        flow.touchLesion();
      },
    );
  }
}

/// Makes the two-week rule visible while the patient is still typing.
class _DurationHint extends StatelessWidget {
  const _DurationHint({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final persistent = days >= RiskCatalog.persistenceThresholdDays;
    return NoticeBanner(
      message: persistent
          ? 'That is ${AppFormats.duration(days)}. Anything lasting two weeks '
                'or longer needs a professional check.'
          : 'That is ${AppFormats.duration(days)}. Keep watching it. If it '
                'lasts two weeks or longer, it needs a professional check.',
      severity: persistent ? NoticeSeverity.alert : NoticeSeverity.caution,
    );
  }
}
