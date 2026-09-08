import 'dart:convert';

import '../../domain/risk_engine.dart';

/// Patient-side follow-up state (spec section 2: "Follow-up/Reminder").
enum FollowUpStatus { notRequired, pending, completed }

extension FollowUpStatusX on FollowUpStatus {
  String get storageValue => switch (this) {
    FollowUpStatus.notRequired => 'not_required',
    FollowUpStatus.pending => 'pending',
    FollowUpStatus.completed => 'completed',
  };

  String get label => switch (this) {
    FollowUpStatus.notRequired => 'No follow-up needed',
    FollowUpStatus.pending => 'Follow-up due',
    FollowUpStatus.completed => 'Follow-up completed',
  };

  static FollowUpStatus fromStorage(String? value) => switch (value) {
    'pending' => FollowUpStatus.pending,
    'completed' => FollowUpStatus.completed,
    _ => FollowUpStatus.notRequired,
  };
}

/// RISK_ASSESSMENT table row (spec Table 11) plus the engine's output.
///
/// This is the unit of work the doctor reviews: one assessment links to one
/// self-examination and zero or more lesion records.
class RiskAssessmentRecord {
  const RiskAssessmentRecord({
    this.id,
    required this.patientId,
    required this.createdAt,
    required this.answers,
    required this.result,
    this.sharedWithDoctor = false,
    this.sharedWithUid,
    this.followUpDue,
    this.followUpStatus = FollowUpStatus.notRequired,
  });

  final int? id;

  /// Primary linking key.
  final String patientId;

  final DateTime createdAt;

  /// Individual risk-factor values, as required by spec Table 11
  /// ("Risk factors, individual values, total score, category").
  final Map<String, String?> answers;

  /// Full engine output, persisted so a historical record always shows the
  /// score and category that were actually produced at the time. Re-running a
  /// changed algorithm over old data would corrupt validation.
  final RiskResult result;

  /// True only when the patient granted share-with-doctor consent.
  final bool sharedWithDoctor;

  /// The uid of the one clinician the patient chose to send this record to.
  ///
  /// Sharing is addressed, not broadcast: the security rules only let a
  /// clinician read an assessment when this matches their own uid, so no other
  /// clinician can see it. Null means the record has not been sent to anyone.
  final String? sharedWithUid;

  /// A record is only visible to a clinician when it is both switched on and
  /// addressed to someone.
  bool get isSharedWithSomeone =>
      sharedWithDoctor && (sharedWithUid?.isNotEmpty ?? false);

  final DateTime? followUpDue;
  final FollowUpStatus followUpStatus;

  bool get isFollowUpOverdue =>
      followUpStatus == FollowUpStatus.pending &&
      followUpDue != null &&
      DateTime.now().isAfter(followUpDue!);

  RiskAssessmentRecord copyWith({
    int? id,
    bool? sharedWithDoctor,
    String? sharedWithUid,
    bool clearSharedWithUid = false,
    DateTime? followUpDue,
    FollowUpStatus? followUpStatus,
  }) => RiskAssessmentRecord(
    id: id ?? this.id,
    patientId: patientId,
    createdAt: createdAt,
    answers: answers,
    result: result,
    sharedWithDoctor: sharedWithDoctor ?? this.sharedWithDoctor,
    // A null default cannot express "remove the recipient", so clearing is an
    // explicit flag rather than an ambiguous null.
    sharedWithUid: clearSharedWithUid
        ? null
        : (sharedWithUid ?? this.sharedWithUid),
    followUpDue: followUpDue ?? this.followUpDue,
    followUpStatus: followUpStatus ?? this.followUpStatus,
  );

  Map<String, Object?> toRow() => {
    if (id != null) 'id': id,
    'patient_id': patientId,
    'created_at': createdAt.toIso8601String(),
    'answers_json': jsonEncode(answers),
    'risk_score': result.totalScore,
    'risk_category': result.category.storageValue,
    'red_flag': result.redFlagPresent ? 1 : 0,
    'red_flags_json': jsonEncode(result.redFlagKeys),
    'lesion_persistent': result.lesionPersistent ? 1 : 0,
    'previous_oscc': result.previousOscc ? 1 : 0,
    'professional_check': result.professionalCheckRequired ? 1 : 0,
    'referral_alert': result.referralAlert ? 1 : 0,
    'output_state': result.outputState.storageValue,
    'unknown_keys_json': jsonEncode(result.unknownAnswerKeys),
    'breakdown_json': jsonEncode(result.scoreBreakdown),
    'reasons_json': jsonEncode(
      result.reasons.map((r) => {'code': r.code, 'detail': r.detail}).toList(),
    ),
    'shared_with_doctor': sharedWithDoctor ? 1 : 0,
    'shared_with_uid': sharedWithUid,
    'follow_up_due': followUpDue?.toIso8601String(),
    'follow_up_status': followUpStatus.storageValue,
  };

  factory RiskAssessmentRecord.fromRow(Map<String, Object?> row) {
    final answers = (jsonDecode(row['answers_json'] as String? ?? '{}') as Map)
        .map((k, v) => MapEntry(k as String, v as String?));
    final redFlags =
        (jsonDecode(row['red_flags_json'] as String? ?? '[]') as List)
            .cast<String>();
    final unknown =
        (jsonDecode(row['unknown_keys_json'] as String? ?? '[]') as List)
            .cast<String>();
    final breakdown =
        (jsonDecode(row['breakdown_json'] as String? ?? '{}') as Map).map(
          (k, v) => MapEntry(k as String, (v as num).toInt()),
        );
    final reasons = (jsonDecode(row['reasons_json'] as String? ?? '[]') as List)
        .map(
          (e) =>
              RiskReason((e as Map)['code'] as String, e['detail'] as String),
        )
        .toList();

    return RiskAssessmentRecord(
      id: row['id'] as int?,
      patientId: row['patient_id'] as String,
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
      answers: answers,
      result: RiskResult(
        totalScore: (row['risk_score'] as int?) ?? 0,
        category: RiskCategoryX.fromStorage(
          row['risk_category'] as String? ?? 'lower',
        ),
        outputState: PatientOutputStateX.fromStorage(
          row['output_state'] as String? ?? 'lower_risk',
        ),
        redFlagPresent: (row['red_flag'] as int? ?? 0) == 1,
        redFlagKeys: redFlags,
        lesionPersistent: (row['lesion_persistent'] as int? ?? 0) == 1,
        previousOscc: (row['previous_oscc'] as int? ?? 0) == 1,
        professionalCheckRequired:
            (row['professional_check'] as int? ?? 0) == 1,
        referralAlert: (row['referral_alert'] as int? ?? 0) == 1,
        unknownAnswerKeys: unknown,
        reasons: reasons,
        scoreBreakdown: breakdown,
      ),
      sharedWithDoctor: (row['shared_with_doctor'] as int? ?? 0) == 1,
      sharedWithUid: row['shared_with_uid'] as String?,
      followUpDue: DateTime.tryParse(row['follow_up_due'] as String? ?? ''),
      followUpStatus: FollowUpStatusX.fromStorage(
        row['follow_up_status'] as String?,
      ),
    );
  }
}

/// One site of the guided self-examination (spec Table 5).
class ExamSiteFinding {
  const ExamSiteFinding({
    required this.siteKey,
    this.examined = false,
    this.abnormality = false,
  });

  final String siteKey;

  /// "Examined? Yes/No"
  final bool examined;

  /// "Abnormality? Yes/No" — a Yes opens the lesion-recording module.
  final bool abnormality;

  ExamSiteFinding copyWith({bool? examined, bool? abnormality}) =>
      ExamSiteFinding(
        siteKey: siteKey,
        examined: examined ?? this.examined,
        // Clearing "examined" must also clear the finding, otherwise the record
        // could claim an abnormality at a site the patient never looked at.
        abnormality: (examined ?? this.examined)
            ? (abnormality ?? this.abnormality)
            : false,
      );

  Map<String, Object?> toJson() => {
    'site': siteKey,
    'examined': examined,
    'abnormality': abnormality,
  };

  factory ExamSiteFinding.fromJson(Map<String, Object?> json) =>
      ExamSiteFinding(
        siteKey: json['site'] as String,
        examined: json['examined'] as bool? ?? false,
        abnormality: json['abnormality'] as bool? ?? false,
      );
}

/// SELF_EXAMINATION table row (spec Table 11).
class SelfExaminationRecord {
  const SelfExaminationRecord({
    this.id,
    this.assessmentId,
    required this.patientId,
    required this.createdAt,
    required this.findings,
  });

  final int? id;
  final int? assessmentId;
  final String patientId;
  final DateTime createdAt;
  final List<ExamSiteFinding> findings;

  bool get anyAbnormality => findings.any((f) => f.abnormality);

  List<String> get abnormalSiteKeys => findings
      .where((f) => f.abnormality)
      .map((f) => f.siteKey)
      .toList(growable: false);

  int get examinedCount => findings.where((f) => f.examined).length;

  Map<String, Object?> toRow() => {
    if (id != null) 'id': id,
    'assessment_id': assessmentId,
    'patient_id': patientId,
    'created_at': createdAt.toIso8601String(),
    'sites_json': jsonEncode(findings.map((f) => f.toJson()).toList()),
    'any_abnormality': anyAbnormality ? 1 : 0,
  };

  factory SelfExaminationRecord.fromRow(Map<String, Object?> row) =>
      SelfExaminationRecord(
        id: row['id'] as int?,
        assessmentId: row['assessment_id'] as int?,
        patientId: row['patient_id'] as String,
        createdAt:
            DateTime.tryParse(row['created_at'] as String? ?? '') ??
            DateTime.now(),
        findings: (jsonDecode(row['sites_json'] as String? ?? '[]') as List)
            .map(
              (e) =>
                  ExamSiteFinding.fromJson((e as Map).cast<String, Object?>()),
            )
            .toList(),
      );
}

/// LESION table row (spec Table 6 / Table 11).
class LesionRecord {
  const LesionRecord({
    this.id,
    this.assessmentId,
    required this.patientId,
    required this.createdAt,
    this.site,
    this.dateFirstNoticed,
    this.durationDays,
    this.pain = false,
    this.bleeding = false,
    this.changeInSize = false,
    this.changeInColour = false,
    this.numbness = false,
    this.difficultySwallowing = false,
    this.restrictedMovement = false,
    this.photoPath,
    this.note,
  });

  final int? id;
  final int? assessmentId;
  final String patientId;
  final DateTime createdAt;

  final String? site;
  final DateTime? dateFirstNoticed;

  /// Duration in days. The UI collects days or weeks and normalises to days.
  final int? durationDays;

  final bool pain;
  final bool bleeding;
  final bool changeInSize;
  final bool changeInColour;
  final bool numbness;
  final bool difficultySwallowing;
  final bool restrictedMovement;

  /// Only ever set when photograph consent is granted.
  final String? photoPath;

  final String? note;

  bool get hasPhoto => photoPath != null && photoPath!.isNotEmpty;

  /// Symptom labels reported as present, for compact display to the doctor.
  List<String> get reportedSymptoms => [
    if (pain) 'Pain',
    if (bleeding) 'Bleeding',
    if (changeInSize) 'Change in size',
    if (changeInColour) 'Change in colour',
    if (numbness) 'Numbness',
    if (difficultySwallowing) 'Difficulty chewing or swallowing',
    if (restrictedMovement) 'Restricted tongue or jaw movement',
  ];

  LesionRecord copyWith({
    int? id,
    int? assessmentId,
    String? site,
    DateTime? dateFirstNoticed,
    int? durationDays,
    bool? pain,
    bool? bleeding,
    bool? changeInSize,
    bool? changeInColour,
    bool? numbness,
    bool? difficultySwallowing,
    bool? restrictedMovement,
    String? photoPath,
    String? note,
  }) => LesionRecord(
    id: id ?? this.id,
    assessmentId: assessmentId ?? this.assessmentId,
    patientId: patientId,
    createdAt: createdAt,
    site: site ?? this.site,
    dateFirstNoticed: dateFirstNoticed ?? this.dateFirstNoticed,
    durationDays: durationDays ?? this.durationDays,
    pain: pain ?? this.pain,
    bleeding: bleeding ?? this.bleeding,
    changeInSize: changeInSize ?? this.changeInSize,
    changeInColour: changeInColour ?? this.changeInColour,
    numbness: numbness ?? this.numbness,
    difficultySwallowing: difficultySwallowing ?? this.difficultySwallowing,
    restrictedMovement: restrictedMovement ?? this.restrictedMovement,
    photoPath: photoPath ?? this.photoPath,
    note: note ?? this.note,
  );

  Map<String, Object?> toRow() => {
    if (id != null) 'id': id,
    'assessment_id': assessmentId,
    'patient_id': patientId,
    'created_at': createdAt.toIso8601String(),
    'site': site,
    'date_first_noticed': dateFirstNoticed?.toIso8601String(),
    'duration_days': durationDays,
    'pain': pain ? 1 : 0,
    'bleeding': bleeding ? 1 : 0,
    'change_size': changeInSize ? 1 : 0,
    'change_colour': changeInColour ? 1 : 0,
    'numbness': numbness ? 1 : 0,
    'swallowing': difficultySwallowing ? 1 : 0,
    'restricted_movement': restrictedMovement ? 1 : 0,
    'photo_path': photoPath,
    'note': note,
  };

  factory LesionRecord.fromRow(Map<String, Object?> row) => LesionRecord(
    id: row['id'] as int?,
    assessmentId: row['assessment_id'] as int?,
    patientId: row['patient_id'] as String,
    createdAt:
        DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
    site: row['site'] as String?,
    dateFirstNoticed: DateTime.tryParse(
      row['date_first_noticed'] as String? ?? '',
    ),
    durationDays: row['duration_days'] as int?,
    pain: (row['pain'] as int? ?? 0) == 1,
    bleeding: (row['bleeding'] as int? ?? 0) == 1,
    changeInSize: (row['change_size'] as int? ?? 0) == 1,
    changeInColour: (row['change_colour'] as int? ?? 0) == 1,
    numbness: (row['numbness'] as int? ?? 0) == 1,
    difficultySwallowing: (row['swallowing'] as int? ?? 0) == 1,
    restrictedMovement: (row['restricted_movement'] as int? ?? 0) == 1,
    photoPath: row['photo_path'] as String?,
    note: row['note'] as String?,
  );
}
