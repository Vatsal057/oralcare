import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oralcare/core/app_images.dart';
import 'package:oralcare/domain/education/education_catalog.dart';
import 'package:oralcare/domain/rehabilitation/rehabilitation_catalog.dart';
import 'package:oralcare/domain/risk_catalog.dart';

/// Illustrations are content, and content that silently fails to appear is worse
/// than content that is obviously absent.
///
/// [OptionalAssetImage] collapses to nothing when an asset is missing, which is
/// what lets artwork land in batches without breaking the build. The cost is that
/// a typo in a path is invisible in the running app. These tests close that gap:
/// every declared path must be spelled consistently, and the report at the end
/// prints which files are still outstanding.
void main() {
  _sourceHygiene();

  group('asset paths are well formed', () {
    test('every declared image lives under assets/images', () {
      for (final path in AppImages.all) {
        expect(path, startsWith('assets/images/'), reason: path);
      }
    });

    /// JPEG, not PNG. As PNGs the 41 illustrations came to 83 MB, which is not
    /// installable over a rural connection; at quality 88 and 1200 px the same
    /// set is 11 MB, with the velvety texture of the erythroplakia image and the
    /// flat edges of the mouth diagram both verified to survive the conversion.
    test('every declared image is a jpg', () {
      for (final path in AppImages.all) {
        expect(path, endsWith('.jpg'), reason: path);
      }
    });

    test('no path is declared twice', () {
      expect(
        AppImages.all.toSet().length,
        AppImages.all.length,
        reason: 'a duplicated constant means two things share one picture',
      );
    });

    test('the inventory covers all 41 expected illustrations', () {
      expect(AppImages.all.length, 41);
    });
  });

  group('content catalogues point at declared assets', () {
    test('every education topic image is in the inventory', () {
      final withImages = EducationCatalog.topics
          .where((t) => t.imageAsset != null)
          .toList();
      expect(withImages.length, EducationCatalog.topics.length,
          reason: 'every topic should carry a header image');
      for (final topic in withImages) {
        expect(AppImages.all, contains(topic.imageAsset), reason: topic.id);
      }
    });

    test('every rehabilitation exercise image is in the inventory', () {
      final exercises = RehabilitationCatalog.protocols.values
          .expand((p) => p.exercises)
          .toList();
      expect(exercises, isNotEmpty);
      for (final exercise in exercises) {
        expect(
          exercise.imageAsset,
          isNotNull,
          reason: 'a physical exercise needs a demonstration: ${exercise.title}',
        );
        expect(AppImages.all, contains(exercise.imageAsset));
      }
    });

    test('the habit questions carry an illustration', () {
      const habitKeys = [
        RiskKeys.smoking,
        RiskKeys.smokelessTobacco,
        RiskKeys.areca,
        RiskKeys.gutkha,
        RiskKeys.alcohol,
      ];
      for (final key in habitKeys) {
        final variable = RiskCatalog.variableFor(key);
        expect(variable.imageAsset, isNotNull, reason: key);
        expect(AppImages.all, contains(variable.imageAsset), reason: key);
      }
    });

    test('non-habit questions deliberately have no illustration', () {
      // A picture next to "previous oral cancer" or a duration band would add
      // nothing and would only make the form longer to scroll.
      for (final key in [
        RiskKeys.previousOscc,
        RiskKeys.lesionDuration,
        RiskKeys.familyHistory,
      ]) {
        expect(RiskCatalog.variableFor(key).imageAsset, isNull, reason: key);
      }
    });
  });

  /// Not a failure when artwork is outstanding -- the app is built to run without
  /// it. This reports the gap so it stays visible instead of being forgotten.
  test('report which illustrations are still missing from the bundle', () {
    final missing = <String>[];
    for (final path in AppImages.all) {
      if (!File(path).existsSync()) missing.add(path);
    }

    final present = AppImages.all.length - missing.length;
    stdout.writeln(
      'Illustrations: $present of ${AppImages.all.length} present.',
    );
    if (missing.isNotEmpty) {
      stdout.writeln('Still to add:');
      for (final path in missing) {
        stdout.writeln('  - ${path.split('/').last}');
      }
    }

    // The eight self-examination sites are the one set that must be complete:
    // they are the guided examination itself, not supporting material.
    const sites = [
      AppImages.siteLips,
      AppImages.siteInnerCheeks,
      AppImages.siteGums,
      AppImages.siteTongue,
      AppImages.siteFloorOfMouth,
      AppImages.sitePalate,
      AppImages.siteNeck,
      AppImages.siteThroat,
    ];
    for (final site in sites) {
      expect(
        File(site).existsSync(),
        isTrue,
        reason: 'a guided self-examination step cannot ship without its '
            'illustration: $site',
      );
    }
  });
}

/// Every illustration broke at once because six gallery entries and the eight
/// self-examination sites held raw `'assets/images/X.png'` literals instead of
/// [AppImages] constants. Converting the set to JPEG updated the constants and
/// left the literals behind, and nothing failed at build time: Flutter resolves
/// an asset path at runtime, and the deployed site answers a missing file with
/// index.html, so the app received HTML where it expected an image and simply
/// drew a broken-image icon.
///
/// These tests read the source. That is unusual, but the bug lives in the
/// difference between what the inventory declares and what the widgets actually
/// ask for, which no amount of runtime assertion can see.
void _sourceHygiene() {
  const sourceDirs = ['lib'];

  List<File> dartFiles() => [
    for (final dir in sourceDirs)
      ...Directory(dir)
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart')),
  ];

  group('asset paths are never written as literals', () {
    test('no widget hard-codes an assets/images path', () {
      final offenders = <String>[];

      for (final file in dartFiles()) {
        // The inventory is the one place allowed to spell paths out.
        if (file.path.endsWith('core/app_images.dart')) continue;

        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].contains("'assets/images/") ||
              lines[i].contains('"assets/images/')) {
            offenders.add('${file.path}:${i + 1}');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'Use an AppImages constant instead. A literal path silently stops '
            'matching when the inventory changes, and a wrong asset path fails '
            'only at runtime:\n${offenders.join('\n')}',
      );
    });

    test('no source file still refers to a .png asset', () {
      final offenders = <String>[];

      for (final file in dartFiles()) {
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          if (lines[i].contains('assets/images') && lines[i].contains('.png')) {
            offenders.add('${file.path}:${i + 1}');
          }
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'The illustration set is JPEG. A leftover .png path resolves to '
            'nothing:\n${offenders.join('\n')}',
      );
    });
  });
}
