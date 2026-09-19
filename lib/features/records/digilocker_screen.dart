import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/common.dart';
import '../../data/repositories/digilocker_repository.dart';
import '../../domain/records/digilocker_models.dart';
import '../../state/session_controller.dart';

class DigiLockerScreen extends StatefulWidget {
  const DigiLockerScreen({super.key});

  @override
  State<DigiLockerScreen> createState() => _DigiLockerScreenState();
}

class _DigiLockerScreenState extends State<DigiLockerScreen> {
  List<DigiLockerRecord> _records = [];
  bool _loading = true;
  DigiLockerCategory? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final session = context.read<SessionController>();
    final repo = context.read<DigiLockerRepository>();
    final patientId = session.user?.patientId ?? 'guest';

    final records = await repo.getRecordsForPatient(patientId);
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  Future<void> _addRecordModal() async {
    final session = context.read<SessionController>();
    final patientId = session.user?.patientId ?? 'guest';
    final repo = context.read<DigiLockerRepository>();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddDocumentSheet(
        patientId: patientId,
        onSave: (newRecord) async {
          await repo.saveRecord(newRecord);
          if (mounted) {
            showSnack(context, 'Document saved to your Medical Locker.');
            await _load();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filtered = _records.where((r) {
      if (_selectedCategory != null && r.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = r.title.toLowerCase().contains(q);
        final matchFacility = r.facilityOrDoctor.toLowerCase().contains(q);
        final matchCategory = r.category.label.toLowerCase().contains(q);
        return matchTitle || matchFacility || matchCategory;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical Records Locker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload records',
            onPressed: _load,
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.folder_shared_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Securely store biopsies, scans, prescriptions, and reports. '
                        'You control which documents are shared with your doctor.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Search bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by title, doctor, hospital...',
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
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
              const SizedBox(height: 12),

              // Category filters
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: Text('All (${_records.length})'),
                      selected: _selectedCategory == null,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = null),
                    ),
                    const SizedBox(width: 8),
                    for (final cat in DigiLockerCategory.values) ...[
                      ChoiceChip(
                        label: Text(cat.label),
                        selected: _selectedCategory == cat,
                        onSelected: (sel) => setState(
                          () => _selectedCategory = sel ? cat : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (filtered.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 56,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty || _selectedCategory != null
                            ? 'No records match your search filter'
                            : 'Your Medical Locker is empty',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap "Add Document" below to upload your biopsy reports, '
                        'imaging scans, prescriptions, and surgery records.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              else
                for (final record in filtered)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RecordCard(
                      record: record,
                      onToggleShare: (val) async {
                        final repo = context.read<DigiLockerRepository>();
                        await repo.toggleSharing(
                          patientId: record.patientId,
                          recordId: record.id,
                          isShared: val,
                        );
                        await _load();
                      },
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Delete record?'),
                            content: Text(
                              'Are you sure you want to remove "${record.title}"?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await context
                              .read<DigiLockerRepository>()
                              .deleteRecord(
                                patientId: record.patientId,
                                recordId: record.id,
                              );
                          await _load();
                        }
                      },
                    ),
                  ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecordModal,
        icon: const Icon(Icons.add),
        label: const Text('Add Document'),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.onToggleShare,
    required this.onDelete,
  });

  final DigiLockerRecord record;
  final ValueChanged<bool> onToggleShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
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
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    record.category.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  AppFormats.d(record.documentDate),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              record.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (record.facilityOrDoctor.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.local_hospital_outlined,
                    size: 14,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    record.facilityOrDoctor,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
            if (record.notes != null && record.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                record.notes!,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
              ),
            ],
            const Divider(height: 20),
            Row(
              children: [
                Icon(
                  record.isSharedWithClinician
                      ? Icons.lock_open_outlined
                      : Icons.lock_outline,
                  size: 16,
                  color: record.isSharedWithClinician
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    record.isSharedWithClinician
                        ? 'Shared with authorized doctor'
                        : 'Private (Not shared)',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: record.isSharedWithClinician
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                    ),
                  ),
                ),
                Switch(
                  value: record.isSharedWithClinician,
                  onChanged: onToggleShare,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddDocumentSheet extends StatefulWidget {
  const _AddDocumentSheet({required this.patientId, required this.onSave});

  final String patientId;
  final Future<void> Function(DigiLockerRecord) onSave;

  @override
  State<_AddDocumentSheet> createState() => _AddDocumentSheetState();
}

class _AddDocumentSheetState extends State<_AddDocumentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _facilityController = TextEditingController();
  final _notesController = TextEditingController();

  DigiLockerCategory _category = DigiLockerCategory.biopsyHistopathology;
  DateTime _documentDate = DateTime.now();
  String? _pickedFilePath;
  bool _shareWithDoctor = false;
  bool _saving = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _facilityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source);
      if (file != null && mounted) {
        setState(() => _pickedFilePath = file.path);
      }
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    final id = 'doc_${DateTime.now().millisecondsSinceEpoch}';

    final record = DigiLockerRecord(
      id: id,
      patientId: widget.patientId,
      title: _titleController.text.trim(),
      category: _category,
      facilityOrDoctor: _facilityController.text.trim(),
      documentDate: _documentDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      localFilePath: _pickedFilePath,
      isSharedWithClinician: _shareWithDoctor,
      createdAt: DateTime.now(),
    );

    await widget.onSave(record);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Record to Medical Locker',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<DigiLockerCategory>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Document Type *',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: DigiLockerCategory.values
                    .map(
                      (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _category = v);
                },
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Document Title *',
                  hintText: 'e.g. Incisional Biopsy Report',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter document title'
                    : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _facilityController,
                decoration: const InputDecoration(
                  labelText: 'Doctor or Hospital / Lab',
                  hintText: 'e.g. Coorg Dental College / Tata Memorial',
                  prefixIcon: Icon(Icons.local_hospital_outlined),
                ),
              ),
              const SizedBox(height: 14),

              // Date Picker
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event_outlined),
                title: const Text('Date of Report / Procedure'),
                subtitle: Text(AppFormats.d(_documentDate)),
                trailing: const Icon(Icons.calendar_today_outlined),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _documentDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _documentDate = picked);
                  }
                },
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes or Summary (optional)',
                  hintText:
                      'e.g. Negative for dysplasia, follow-up in 3 months',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),
              const SizedBox(height: 14),

              // Photo capture
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                  const SizedBox(width: 12),
                  if (_pickedFilePath != null)
                    Expanded(
                      child: Text(
                        'File attached',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Share with authorized doctor'),
                subtitle: const Text(
                  'Allow clinician to view this document when reviewing your record',
                ),
                value: _shareWithDoctor,
                onChanged: (val) => setState(() => _shareWithDoctor = val),
              ),
              const SizedBox(height: 20),

              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save to Locker'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
