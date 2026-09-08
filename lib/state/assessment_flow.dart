import 'package:flutter/foundation.dart';

import '../data/models/app_user.dart';
import '../data/models/assessment_models.dart';
import '../domain/risk_catalog.dart';
import '../domain/risk_engine.dart';

/// Mutable draft of the lesion-recording form (spec Table 6).
class LesionDraft {
  String? site;
  DateTime? dateFirstNoticed;

  /// Raw number the patient typed, paired with [durationUnit].
  int? durationValue;
  String durationUnit = 'days';

  bool pain = false;
  bool bleeding = false;
  bool changeInSize = false;
  bool changeInColour = false;
  bool numbness = false;
  bool difficultySwallowing = false;
  bool restrictedMovement = false;

  String? photoPath;
  String note = '';

  /// Normalised duration in days, used by the engine's two-week rule.
  int? get durationDays {
    final value = durationValue;
    if (value == null) return null;
    return durationUnit == 'weeks' ? value * 7 : value;
  }

  bool get hasAnyContent =>
      site != null ||
      durationValue != null ||
      dateFirstNoticed != null ||
      pain ||
      bleeding ||
      changeInSize ||
      changeInColour ||
      numbness ||
      difficultySwallowing ||
      restrictedMovement ||
      (photoPath != null && photoPath!.isNotEmpty) ||
      note.trim().isNotEmpty;

  LesionRecord toRecord({required String patientId, int? assessmentId}) =>
      LesionRecord(
        assessmentId: assessmentId,
        patientId: patientId,
        createdAt: DateTime.now(),
        site: site,
        dateFirstNoticed: dateFirstNoticed,
        durationDays: durationDays,
        pain: pain,
        bleeding: bleeding,
        changeInSize: changeInSize,
        changeInColour: changeInColour,
        numbness: numbness,
        difficultySwallowing: difficultySwallowing,
        restrictedMovement: restrictedMovement,
        photoPath: photoPath,
        note: note.trim().isEmpty ? null : note.trim(),
      );
}

/// Carries one in-progress assessment across the patient screens.
///
/// The engine is deliberately run only from [evaluate], at the end of the flow,
/// so the risk score, the red-flag override and the self-examination finding are
/// all decided from the complete picture rather than screen by screen.
class AssessmentFlow extends ChangeNotifier {
  AssessmentFlow({required this.patient})
    : findings = ExamSiteCatalog.sites
          .map((s) => ExamSiteFinding(siteKey: s.key))
          .toList();

  final AppUser patient;

  /// Risk variable key to selected option value.
  final Map<String, String?> answers = {};

  /// Red-flag keys answered "Yes" (spec section 2.3).
  final Set<String> redFlags = {};

  /// One entry per site of the guided self-examination (spec Table 5).
  List<ExamSiteFinding> findings;

  final LesionDraft lesion = LesionDraft();

  String get patientId => patient.patientId ?? 'unknown';

  int get age => patient.age ?? 0;

  // ---- risk answers ---------------------------------------------------------

  void setAnswer(String key, String? value) {
    answers[key] = value;

    // Clear dependent answers so a stale value can never reach the engine.
    if (key == RiskKeys.suspiciousLesion && value != AnswerValues.yes) {
      answers.remove(RiskKeys.lesionDuration);
      redFlags.clear();
    }
    notifyListeners();
  }

  String? answer(String key) => answers[key];

  bool get reportsSuspiciousLesion =>
      answers[RiskKeys.suspiciousLesion] == AnswerValues.yes;

  bool get hasExposure => RiskEngine.hasExposure(answers);

  /// Variables the patient must answer, given the conditional rules.
  List<RiskVariable> get applicableVariables => RiskCatalog.askedVariables
      .where((v) {
        if (v.requiresExposure && !hasExposure) return false;
        if (v.key == RiskKeys.lesionDuration && !reportsSuspiciousLesion) {
          return false;
        }
        return true;
      })
      .toList(growable: false);

  List<RiskVariable> get unansweredVariables => applicableVariables
      .where((v) => answers[v.key] == null)
      .toList(growable: false);

  bool get isRiskFormComplete => unansweredVariables.isEmpty;

  // ---- red flags ------------------------------------------------------------

  void setRedFlag(String key, bool selected) {
    if (selected) {
      redFlags.add(key);
    } else {
      redFlags.remove(key);
    }
    notifyListeners();
  }

  bool isRedFlagSet(String key) => redFlags.contains(key);

  // ---- self-examination -----------------------------------------------------

  void setSiteExamined(String siteKey, bool examined) {
    findings = findings
        .map((f) => f.siteKey == siteKey ? f.copyWith(examined: examined) : f)
        .toList();
    notifyListeners();
  }

  void setSiteAbnormality(String siteKey, bool abnormality) {
    findings = findings
        .map(
          (f) => f.siteKey == siteKey
              ? f.copyWith(examined: true, abnormality: abnormality)
              : f,
        )
        .toList();
    notifyListeners();
  }

  ExamSiteFinding findingFor(String siteKey) =>
      findings.firstWhere((f) => f.siteKey == siteKey);

  bool get anySiteAbnormal => findings.any((f) => f.abnormality);

  int get sitesExamined => findings.where((f) => f.examined).length;

  /// Spec section 2.4: "If abnormality = Yes, the app opens the lesion-recording
  /// module." A reported symptom from the risk form also opens it, so a finding
  /// is never left undocumented.
  bool get shouldRecordLesion => anySiteAbnormal || reportsSuspiciousLesion;

  // ---- lesion ---------------------------------------------------------------

  void touchLesion() => notifyListeners();

  /// Photograph capture is only ever offered when consent was granted.
  bool get photographAllowed => patient.consent.photograph;

  // ---- engine ---------------------------------------------------------------

  /// Runs the risk and safety engine over everything collected so far.
  RiskResult evaluate() => RiskEngine.evaluate(
    age: age,
    answers: answers,
    redFlagKeys: redFlags,
    lesionDurationDays: lesion.durationDays,
    selfExamAbnormality: anySiteAbnormal,
  );

  SelfExaminationRecord buildSelfExamination({int? assessmentId}) =>
      SelfExaminationRecord(
        assessmentId: assessmentId,
        patientId: patientId,
        createdAt: DateTime.now(),
        findings: findings,
      );

  RiskAssessmentRecord buildAssessment(RiskResult result) =>
      RiskAssessmentRecord(
        patientId: patientId,
        createdAt: DateTime.now(),
        answers: Map<String, String?>.from(answers)
          ..[RiskKeys.ageBand] = RiskCatalog.ageBandForAge(age),
        result: result,
        // Follow-up is set on the result screen once the output is known.
        followUpStatus: FollowUpStatus.notRequired,
      );
}
