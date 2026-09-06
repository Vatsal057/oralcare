import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/common.dart';
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
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 2000,
        imageQuality: 88,
      );
      if (picked == null) return;

      final stored = await PhotoStore.store(picked.path, flow.patientId);
      await PhotoStore.delete(flow.lesion.photoPath);
      flow.lesion.photoPath = stored;
      flow.touchLesion();
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
                  message: 'You marked a finding at: ${abnormalSites.join(', ')}.',
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
                          DropdownMenuItem(value: 'weeks', child: Text('weeks')),
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
                _symptom(flow, 'Bleeding', draft.bleeding,
                    (v) => draft.bleeding = v),
                _symptom(flow, 'Change in size', draft.changeInSize,
                    (v) => draft.changeInSize = v),
                _symptom(flow, 'Change in colour', draft.changeInColour,
                    (v) => draft.changeInColour = v),
                _symptom(flow, 'Numbness', draft.numbness,
                    (v) => draft.numbness = v),
                _symptom(
                    flow,
                    'Difficulty chewing or swallowing',
                    draft.difficultySwallowing,
                    (v) => draft.difficultySwallowing = v),
                _symptom(
                    flow,
                    'Restricted tongue or jaw movement',
                    draft.restrictedMovement,
                    (v) => draft.restrictedMovement = v),
              ],
            ),
            const SizedBox(height: 14),

            SectionCard(
              title: 'Photograph',
              icon: Icons.photo_camera_outlined,
              subtitle: flow.photographAllowed
                  ? 'Optional. Stays on this device unless you share your '
                      'record with a doctor.'
                  : 'You have not given photograph consent, so this is turned '
                      'off.',
              children: [
                if (!flow.photographAllowed)
                  const NoticeBanner(
                    message:
                        'To add a photograph, turn on photograph consent in '
                        'your consent choices.',
                    severity: NoticeSeverity.info,
                  )
                else if (PhotoStore.exists(draft.photoPath)) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(draft.photoPath!),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox(
                        height: 200,
                        child: Center(child: Text('Could not display image')),
                      ),
                    ),
                  ),
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
              onPressed: () => Navigator.of(context).push(
                flowRoute(flow, const ResultScreen()),
              ),
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
