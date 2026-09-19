import 'package:flutter_test/flutter_test.dart';
import 'package:oralcare/data/repositories/auth_repository.dart';

/// The enrolment-code path is the weakest link in the pilot: the code ships
/// inside the app bundle, so anyone who reads it can self-assign the clinician
/// role. It can therefore be compiled out.
///
/// This file asserts whichever branch the build selected, so it is meaningful
/// under both:
///   flutter test
///   flutter test --dart-define=ALLOW_ENROLMENT_CODE=false
void main() {
  test('the enrolment code is configurable and never blank', () {
    expect(AuthRepository.doctorEnrolmentCode.trim(), isNotEmpty);
  });

  group('when self-registration is compiled out', () {
    test(
      'registerDoctor refuses before touching the network',
      () async {
        // No Firebase is initialised here. The guard must reject the call before
        // any credential work, so reaching an AuthException proves the switch is
        // enforced in the repository and not only hidden in the UI.
        await expectLater(
          AuthRepository().registerDoctor(
            username: 'dr.smith',
            password: 'Str0ngPass1',
            enrolmentCode: AuthRepository.doctorEnrolmentCode,
          ),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              contains('issued by the pilot coordinator'),
            ),
          ),
        );
      },
      skip: AuthRepository.allowEnrolmentCodeRegistration
          ? 'build allows enrolment-code registration'
          : false,
    );
  });

  group('when self-registration is allowed (pilot default)', () {
    test(
      'a wrong enrolment code is rejected with a clear message',
      () async {
        await expectLater(
          AuthRepository().registerDoctor(
            username: 'dr.smith',
            password: 'Str0ngPass1',
            enrolmentCode: 'WRONG-CODE',
          ),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              contains('not valid'),
            ),
          ),
        );
      },
      skip: AuthRepository.allowEnrolmentCodeRegistration
          ? false
          : 'build has enrolment-code registration disabled',
    );

    test(
      'credentials are validated before the code is checked',
      () async {
        await expectLater(
          AuthRepository().registerDoctor(
            username: 'ab',
            password: 'short',
            enrolmentCode: AuthRepository.doctorEnrolmentCode,
          ),
          throwsA(isA<AuthException>()),
        );
      },
      skip: AuthRepository.allowEnrolmentCodeRegistration
          ? false
          : 'build has enrolment-code registration disabled',
    );
  });
}
