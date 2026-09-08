import '../data/models/patient_case.dart';
import 'risk_engine.dart';

/// A 2x2 agreement table plus the derived operating characteristics.
class ConfusionMatrix {
  const ConfusionMatrix({
    required this.truePositive,
    required this.falsePositive,
    required this.falseNegative,
    required this.trueNegative,
  });

  /// App flagged for professional care, and OPMD/OSCC was established.
  final int truePositive;

  /// App flagged, but no OPMD/OSCC was established.
  final int falsePositive;

  /// App did not flag, but OPMD/OSCC was established. The safety-critical cell.
  final int falseNegative;

  /// App did not flag, and no OPMD/OSCC was established.
  final int trueNegative;

  int get total => truePositive + falsePositive + falseNegative + trueNegative;

  /// Proportion of established disease the app flagged. `null` when there are
  /// no disease-positive cases yet.
  double? get sensitivity {
    final denominator = truePositive + falseNegative;
    return denominator == 0 ? null : truePositive / denominator;
  }

  double? get specificity {
    final denominator = trueNegative + falsePositive;
    return denominator == 0 ? null : trueNegative / denominator;
  }

  double? get positivePredictiveValue {
    final denominator = truePositive + falsePositive;
    return denominator == 0 ? null : truePositive / denominator;
  }

  double? get negativePredictiveValue {
    final denominator = trueNegative + falseNegative;
    return denominator == 0 ? null : trueNegative / denominator;
  }
}

/// Outcome counts for one risk band.
class CategoryBreakdown {
  const CategoryBreakdown({
    required this.category,
    required this.assessments,
    required this.withOutcome,
    required this.diseasePositive,
  });

  final RiskCategory category;

  /// All assessments that landed in this band.
  final int assessments;

  /// Of those, how many have a reference outcome recorded.
  final int withOutcome;

  /// Of those with an outcome, how many were OPMD or OSCC positive.
  final int diseasePositive;

  double? get positiveRate =>
      withOutcome == 0 ? null : diseasePositive / withOutcome;
}

/// Aggregate view of the OUTCOME database.
class ValidationSummary {
  const ValidationSummary({
    required this.totalSharedCases,
    required this.reviewedCases,
    required this.casesWithOutcome,
    required this.matrix,
    required this.categoryBreakdowns,
    required this.professionalCheckCount,
    required this.referralCompletedCount,
    required this.followUpCompletedCount,
    required this.biopsyPerformedCount,
    required this.falseNegativeCases,
  });

  final int totalSharedCases;
  final int reviewedCases;

  /// Denominator for every metric on this screen.
  final int casesWithOutcome;

  final ConfusionMatrix matrix;
  final List<CategoryBreakdown> categoryBreakdowns;

  final int professionalCheckCount;
  final int referralCompletedCount;
  final int followUpCompletedCount;
  final int biopsyPerformedCount;

  /// The cases the app failed to flag. Surfaced explicitly because these are
  /// what a pilot must act on.
  final List<PatientCase> falseNegativeCases;

  bool get hasEnoughDataForMetrics => casesWithOutcome > 0;
}

/// Compares app risk/referral output against the recorded clinical outcome.
///
/// Spec section 4: "Compare app risk/referral output with clinical outcome →
/// Validate and refine risk-stratification and referral algorithm."
///
/// STATISTICAL CAVEAT: these are raw counts from whatever data the pilot has
/// entered so far. They carry no confidence intervals, no adjustment for
/// verification bias (only referred patients tend to get a biopsy, so
/// specificity will look better than it is) and no correction for repeated
/// assessments on the same patient. Treat them as a monitoring aid, not as
/// validation evidence.
class ValidationService {
  const ValidationService._();

  static ValidationSummary summarise(List<PatientCase> cases) {
    var tp = 0, fp = 0, fn = 0, tn = 0;
    var reviewed = 0;
    var withOutcome = 0;
    var professionalCheck = 0;
    var referralCompleted = 0;
    var followUpCompleted = 0;
    var biopsyPerformed = 0;
    final falseNegatives = <PatientCase>[];

    final perCategory = <RiskCategory, List<PatientCase>>{
      RiskCategory.lower: [],
      RiskCategory.increased: [],
      RiskCategory.higher: [],
    };

    for (final c in cases) {
      perCategory[c.assessment.result.category]!.add(c);

      if (c.isReviewed) reviewed++;
      if (c.assessment.result.professionalCheckRequired) professionalCheck++;
      if (c.outcome?.referralCompleted == true) referralCompleted++;
      if (c.outcome?.followUpCompleted == true) followUpCompleted++;
      if (c.outcome?.biopsyPerformed == true) biopsyPerformed++;

      final diseasePositive = c.outcome?.isDiseasePositive;
      if (diseasePositive == null) continue;

      withOutcome++;
      final flagged = c.appFlaggedForProfessionalCare;

      if (flagged && diseasePositive) {
        tp++;
      } else if (flagged && !diseasePositive) {
        fp++;
      } else if (!flagged && diseasePositive) {
        fn++;
        falseNegatives.add(c);
      } else {
        tn++;
      }
    }

    final breakdowns = perCategory.entries
        .map((entry) {
          final withOutcomeCount = entry.value
              .where((c) => c.outcome?.isDiseasePositive != null)
              .length;
          final positives = entry.value
              .where((c) => c.outcome?.isDiseasePositive == true)
              .length;
          return CategoryBreakdown(
            category: entry.key,
            assessments: entry.value.length,
            withOutcome: withOutcomeCount,
            diseasePositive: positives,
          );
        })
        .toList(growable: false);

    return ValidationSummary(
      totalSharedCases: cases.length,
      reviewedCases: reviewed,
      casesWithOutcome: withOutcome,
      matrix: ConfusionMatrix(
        truePositive: tp,
        falsePositive: fp,
        falseNegative: fn,
        trueNegative: tn,
      ),
      categoryBreakdowns: breakdowns,
      professionalCheckCount: professionalCheck,
      referralCompletedCount: referralCompleted,
      followUpCompletedCount: followUpCompleted,
      biopsyPerformedCount: biopsyPerformed,
      falseNegativeCases: falseNegatives,
    );
  }

  /// Formats a proportion as a percentage, or an em dash when undefined.
  static String formatRate(double? value) =>
      value == null ? '—' : '${(value * 100).toStringAsFixed(1)}%';
}
