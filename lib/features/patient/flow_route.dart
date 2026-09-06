import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/assessment_flow.dart';

/// Pushes a patient-flow screen while keeping the same [AssessmentFlow]
/// instance available to it.
///
/// The flow screens push one another, so each new route has to re-expose the
/// draft. Using `.value` (not `create:`) is deliberate: the flow is owned by the
/// screen that started the assessment, and must not be disposed when an
/// intermediate route is popped.
Route<T> flowRoute<T>(AssessmentFlow flow, Widget child) {
  return MaterialPageRoute<T>(
    builder: (_) => ChangeNotifierProvider<AssessmentFlow>.value(
      value: flow,
      child: child,
    ),
  );
}
