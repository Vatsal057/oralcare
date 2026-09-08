import '../data/models/assessment_models.dart';
import 'risk_catalog.dart';
import 'risk_engine.dart';

/// A scheduled follow-up prompt for the patient.
class FollowUpPlan {
  const FollowUpPlan({required this.status, this.due, required this.reason});

  final FollowUpStatus status;
  final DateTime? due;

  /// Plain-language explanation shown on the reminder card.
  final String reason;

  bool get isRequired => status == FollowUpStatus.pending;
}

/// Decides when the patient should be prompted to come back
/// (spec section 2: "Follow-up/Reminder").
///
/// The intervals below are a pilot default, not a validated recall schedule.
/// They exist so the "monitor / review if persistent" branch of the decision
/// logic actually produces a prompt rather than relying on the patient to
/// remember.
class FollowUpPolicy {
  const FollowUpPolicy._();

  static const int professionalCheckDays = 7;
  static const int observeReviewDays = RiskCatalog.persistenceThresholdDays;
  static const int higherRiskDays = 14;
  static const int increasedRiskDays = 30;

  static FollowUpPlan plan({
    required RiskResult result,
    DateTime? lesionFirstNoticed,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();

    switch (result.outputState) {
      case PatientOutputState.professionalCheckRequired:
        return FollowUpPlan(
          status: FollowUpStatus.pending,
          due: reference.add(const Duration(days: professionalCheckDays)),
          reason:
              'We will check back in a week to see whether you have been seen '
              'by a dentist or doctor.',
        );

      case PatientOutputState.observeAndReview:
        // Count the two weeks from when the patient first noticed it, not from
        // today, otherwise a finding that is already 10 days old gets a
        // 24-day review.
        final anchor = lesionFirstNoticed ?? reference;
        var due = anchor.add(const Duration(days: observeReviewDays));
        if (due.isBefore(reference)) {
          due = reference.add(const Duration(days: 1));
        }
        return FollowUpPlan(
          status: FollowUpStatus.pending,
          due: due,
          reason:
              'We will remind you to check whether this is still there. If it '
              'is, it needs a professional check.',
        );

      case PatientOutputState.higherRisk:
        return FollowUpPlan(
          status: FollowUpStatus.pending,
          due: reference.add(const Duration(days: higherRiskDays)),
          reason:
              'We will remind you to arrange a professional oral examination.',
        );

      case PatientOutputState.increasedRisk:
        return FollowUpPlan(
          status: FollowUpStatus.pending,
          due: reference.add(const Duration(days: increasedRiskDays)),
          reason:
              'We will remind you in a month to repeat the self-examination '
              'and to book a professional oral examination.',
        );

      case PatientOutputState.lowerRisk:
        return const FollowUpPlan(
          status: FollowUpStatus.notRequired,
          reason:
              'No specific follow-up needed. Repeat the self-examination once '
              'a month and attend routine dental check-ups.',
        );
    }
  }
}
