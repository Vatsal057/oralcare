import 'dart:convert';

/// The 13 clinical document categories defined in Section G of the specification
/// ("Personal oral-cancer records like Digi locker").
enum DigiLockerCategory {
  consultation,
  clinicalPhoto,
  biopsyHistopathology,
  bloodInvestigation,
  radiologyImaging,
  diagnosisStaging,
  treatmentPlan,
  prescription,
  surgeryRadiotherapy,
  chemotherapy,
  dischargeSummary,
  followUpNote,
  billsInsurance,
}

extension DigiLockerCategoryX on DigiLockerCategory {
  String get label => switch (this) {
    DigiLockerCategory.consultation => 'Consultation Record',
    DigiLockerCategory.clinicalPhoto => 'Clinical Photograph',
    DigiLockerCategory.biopsyHistopathology => 'Biopsy & Histopathology',
    DigiLockerCategory.bloodInvestigation => 'Blood Investigation',
    DigiLockerCategory.radiologyImaging => 'Imaging (CT/MRI/OPG)',
    DigiLockerCategory.diagnosisStaging => 'Diagnosis & Staging',
    DigiLockerCategory.treatmentPlan => 'Treatment Plan',
    DigiLockerCategory.prescription => 'Prescription',
    DigiLockerCategory.surgeryRadiotherapy => 'Surgery / Radiotherapy',
    DigiLockerCategory.chemotherapy => 'Chemotherapy Record',
    DigiLockerCategory.dischargeSummary => 'Discharge Summary',
    DigiLockerCategory.followUpNote => 'Follow-up Note',
    DigiLockerCategory.billsInsurance => 'Bills & Insurance',
  };

  String get storageValue => name;

  static DigiLockerCategory fromStorage(String? val) {
    return DigiLockerCategory.values.firstWhere(
      (c) => c.name == val,
      orElse: () => DigiLockerCategory.consultation,
    );
  }
}

class DigiLockerRecord {
  const DigiLockerRecord({
    required this.id,
    required this.patientId,
    required this.title,
    required this.category,
    required this.facilityOrDoctor,
    required this.documentDate,
    this.notes,
    this.localFilePath,
    this.hasStoredImage = false,
    this.isSharedWithClinician = false,
    required this.createdAt,
  });

  final String id;
  final String patientId;
  final String title;
  final DigiLockerCategory category;
  final String facilityOrDoctor;
  final DateTime documentDate;
  final String? notes;

  /// A path on the capturing device. Meaningless anywhere else, which is why it
  /// is not what any viewer reads.
  final String? localFilePath;

  /// True when the image is held in Firestore at
  /// `users/{uid}/digilocker_files/{id}` and can therefore be opened on another
  /// device, and by a clinician if the document is shared.
  final bool hasStoredImage;

  final bool isSharedWithClinician;
  final DateTime createdAt;

  /// Whether there is an image a clinician or another device could actually
  /// open. A local path alone is not one.
  bool get hasViewableImage => hasStoredImage;

  DigiLockerRecord copyWith({
    String? title,
    DigiLockerCategory? category,
    String? facilityOrDoctor,
    DateTime? documentDate,
    String? notes,
    String? localFilePath,
    bool? hasStoredImage,
    bool? isSharedWithClinician,
  }) => DigiLockerRecord(
    id: id,
    patientId: patientId,
    title: title ?? this.title,
    category: category ?? this.category,
    facilityOrDoctor: facilityOrDoctor ?? this.facilityOrDoctor,
    documentDate: documentDate ?? this.documentDate,
    notes: notes ?? this.notes,
    localFilePath: localFilePath ?? this.localFilePath,
    hasStoredImage: hasStoredImage ?? this.hasStoredImage,
    isSharedWithClinician: isSharedWithClinician ?? this.isSharedWithClinician,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'patient_id': patientId,
    'title': title,
    'category': category.storageValue,
    'facility_or_doctor': facilityOrDoctor,
    'document_date': documentDate.toIso8601String(),
    'notes': notes,
    'local_file_path': localFilePath,
    'has_image': hasStoredImage ? 1 : 0,
    'is_shared': isSharedWithClinician ? 1 : 0,
    'created_at': createdAt.toIso8601String(),
  };

  factory DigiLockerRecord.fromJson(Map<String, dynamic> json) =>
      DigiLockerRecord(
        id: json['id'] as String,
        patientId: json['patient_id'] as String? ?? '',
        title: json['title'] as String? ?? 'Untitled Document',
        category: DigiLockerCategoryX.fromStorage(json['category'] as String?),
        facilityOrDoctor: json['facility_or_doctor'] as String? ?? '',
        documentDate:
            DateTime.tryParse(json['document_date'] as String? ?? '') ??
            DateTime.now(),
        notes: json['notes'] as String?,
        localFilePath: json['local_file_path'] as String?,
        // Absent on records saved before images were stored server-side, which
        // must not make a viewer fetch a document that was never written.
        hasStoredImage: (json['has_image'] as int? ?? 0) == 1,
        isSharedWithClinician: (json['is_shared'] as int? ?? 0) == 1,
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  String serialize() => jsonEncode(toJson());
  static DigiLockerRecord deserialize(String str) =>
      DigiLockerRecord.fromJson(jsonDecode(str) as Map<String, dynamic>);
}
