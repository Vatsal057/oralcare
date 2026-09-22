import 'package:flutter/material.dart';

import 'common.dart';

/// Shown in place of a spinner when a load fails.
///
/// Exists so every screen reports a failed load the same way and always offers a
/// way out. The alternative that shipped was a spinner with no end state: the
/// patient could not tell whether the app was working, broken, or waiting on
/// them, and had no action available either way.
class LoadFailure extends StatelessWidget {
  const LoadFailure({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Could not load this',
    this.compact = false,
  });

  final String message;
  final VoidCallback onRetry;
  final String title;

  /// Inline variant, for a failure inside a list that still has other content
  /// around it rather than one filling the whole screen.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        NoticeBanner(
          title: title,
          message: message,
          severity: NoticeSeverity.alert,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ),
      ],
    );

    if (compact) return content;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: content,
      ),
    );
  }
}
