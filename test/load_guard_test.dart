import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oralcare/core/load_guard.dart';

/// Screens showed spinners that never stopped, from two different causes:
/// an unguarded await that threw, and a read that never completed at all.
///
/// The second is the one a `try`/`catch` cannot reach, so the deadline is the
/// load-bearing part of this class and is tested with a future that genuinely
/// never finishes.
void main() {
  group('a read that completes', () {
    test('passes the value straight through', () async {
      expect(await LoadGuard.run(Future.value(42)), 42);
    });

    test('rethrows so the caller can report it', () async {
      expect(
        () => LoadGuard.run(Future<int>.error(StateError('nope'))),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('a read that never completes', () {
    test('is turned into a TimeoutException instead of hanging', () async {
      // Never completes. Without the deadline this test would hang forever,
      // which is exactly what the spinner was doing.
      final never = Completer<int>().future;

      expect(
        () => LoadGuard.run(never, limit: const Duration(milliseconds: 40)),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('a slow read still succeeds inside the deadline', () async {
      final slow = Future.delayed(const Duration(milliseconds: 20), () => 7);
      expect(
        await LoadGuard.run(slow, limit: const Duration(milliseconds: 500)),
        7,
      );
    });
  });

  group('the default deadline is sane', () {
    test('long enough for a slow connection, short enough to not feel broken', () {
      expect(LoadGuard.timeout.inSeconds, greaterThanOrEqualTo(10));
      expect(LoadGuard.timeout.inSeconds, lessThanOrEqualTo(30));
    });
  });

  /// The distinction matters to the patient: a timeout is probably their
  /// connection and retrying will help, whereas a refused read will not fix
  /// itself and they should report it rather than keep tapping.
  group('failures are explained in plain language', () {
    test('a timeout blames the connection and invites a retry', () {
      final msg = LoadGuard.message(
        TimeoutException('x'),
        what: 'previous checks',
      );
      expect(msg, contains('previous checks'));
      expect(msg.toLowerCase(), contains('timed out'));
      expect(msg.toLowerCase(), contains('try again'));
    });

    test('a refused read tells them to report it, not to retry forever', () {
      final msg = LoadGuard.message(
        Exception('[cloud_firestore/permission-denied] Missing permissions'),
        what: 'documents',
      );
      expect(msg.toLowerCase(), contains('refused'));
      expect(msg.toLowerCase(), contains('sign out'));
    });

    test('an offline read names the connection', () {
      final msg = LoadGuard.message(
        Exception('unavailable: backend unreachable'),
        what: 'quit plan',
      );
      expect(msg.toLowerCase(), contains('no connection'));
    });

    test('an unrecognised failure still names what failed', () {
      final msg = LoadGuard.message(StateError('odd'), what: 'check');
      expect(msg, contains('check'));
      expect(msg, isNotEmpty);
    });

    test('never leaks a bare exception with no explanation', () {
      for (final error in <Object>[
        TimeoutException('x'),
        Exception('permission-denied'),
        Exception('unavailable'),
        StateError('y'),
      ]) {
        final msg = LoadGuard.message(error, what: 'records');
        expect(msg.startsWith('Could not load'), isTrue, reason: msg);
      }
    });
  });

  /// The regression itself: a loader whose await is unguarded leaves its loading
  /// flag set. These read the source, because the bug is structural — it lives in
  /// the absence of a catch, which nothing at runtime can observe.
  group('no loader can leave a spinner turning', () {
    test('every loader with an await both catches and sets a deadline', () {
      final pattern = RegExp(
        r'\n  (?:Future<[^>]*>|void)\s+'
        r'(_load\w*|_reload\w*|_commit|_loadDirectory|_loadCenters|'
        r'_loadAppointments|_loadLatestAssessment|_loadSharedDocuments)'
        r'\s*\([^)]*\)\s*(?:async\s*)?\{',
      );

      final offenders = <String>[];

      for (final file in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final src = file.readAsStringSync();

        for (final match in pattern.allMatches(src)) {
          // Brace-match the body so nested blocks are included.
          final open = src.indexOf('{', match.start);
          var depth = 0;
          var end = open;
          for (var i = open; i < src.length; i++) {
            if (src[i] == '{') depth++;
            if (src[i] == '}') {
              depth--;
              if (depth == 0) {
                end = i;
                break;
              }
            }
          }
          // Strip comments first. Prose explaining why an await is guarded
          // otherwise counts as an unguarded await, which is how this check
          // produced its first false positive.
          final body = src
              .substring(match.start, end + 1)
              .split('\n')
              .where((l) => !l.trimLeft().startsWith('//'))
              .join('\n');

          final awaits = 'await '.allMatches(body).length;
          if (awaits == 0) continue;

          // Counted, not merely "mentioned somewhere". An earlier version of
          // this test looked for the string `LoadGuard` in the body and passed
          // happily while the await was unguarded, because `LoadGuard.message`
          // in the catch block satisfied it.
          final guardedAwaits = 'await LoadGuard.run('.allMatches(body).length;
          final missing = awaits - guardedAwaits;

          if (!body.contains('catch')) {
            offenders.add('${file.path} :: ${match.group(1)} (no catch)');
          } else if (missing > 0) {
            offenders.add(
              '${file.path} :: ${match.group(1)} '
              '($missing of $awaits awaits have no deadline)',
            );
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'These loaders can leave a spinner on screen forever. Wrap the await '
            'in LoadGuard.run and catch the failure:\n${offenders.join('\n')}',
      );
    });
  });
}
