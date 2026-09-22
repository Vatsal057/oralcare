import 'dart:async';

/// Bounds a network read and turns any failure into wording a patient can act on.
///
/// WHY THIS EXISTS: several screens showed a spinner that never stopped. There
/// were two separate causes and a `try`/`catch` alone only fixes one of them.
///
///  1. An unguarded `await` that throws. The exception escapes the loader, the
///     `_loading = false` line never runs, and the spinner turns forever.
///  2. A read that never completes at all. A Firestore `get()` against an
///     unreachable backend can sit retrying instead of reporting an error, so
///     even a correctly wrapped `try`/`catch` is never reached.
///
/// [run] closes both: the deadline converts a hang into a throw, and callers
/// catch that throw. A spinner must always resolve into either content or a
/// stated reason — never into silence.
class LoadGuard {
  const LoadGuard._();

  /// Long enough for a slow rural connection to finish, short enough that a
  /// patient does not sit watching an animation wondering if the app is broken.
  static const Duration timeout = Duration(seconds: 20);

  static Future<T> run<T>(Future<T> future, {Duration? limit}) => future.timeout(
    limit ?? timeout,
    onTimeout: () => throw TimeoutException('Load exceeded the deadline'),
  );

  /// Plain-language reason, given to the patient rather than a raw exception.
  ///
  /// The distinction is worth drawing: a timeout is very likely their connection
  /// and retrying will help, whereas a permission error will not fix itself and
  /// they should stop retrying and report it.
  static String message(Object error, {required String what}) {
    if (error is TimeoutException) {
      return 'Could not load your $what — the connection timed out. '
          'Check your internet and try again.';
    }
    final text = error.toString();
    if (text.contains('permission-denied') || text.contains('PERMISSION_DENIED')) {
      return 'Could not load your $what because access was refused. '
          'Please sign out and sign in again, and tell the pilot team if it '
          'keeps happening.';
    }
    if (text.contains('unavailable') || text.contains('network')) {
      return 'Could not load your $what — no connection. '
          'Check your internet and try again.';
    }
    return 'Could not load your $what. $error';
  }
}
