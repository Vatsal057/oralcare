import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'data/models/app_user.dart';
import 'data/repositories/assessment_repository.dart';
import 'data/repositories/cessation_repository.dart';
import 'data/repositories/clinical_repository.dart';
import 'data/repositories/digilocker_repository.dart';
import 'data/repositories/doctor_directory_repository.dart';
import 'features/auth/role_select_screen.dart';
import 'features/doctor/doctor_home_screen.dart';
import 'features/patient/consent_screen.dart';
import 'features/patient/patient_home_screen.dart';
import 'state/session_controller.dart';

class OralCancerApp extends StatelessWidget {
  const OralCancerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SessionController()..initialise(),
        ),
        Provider(create: (_) => AssessmentRepository()),
        Provider(create: (_) => ClinicalRepository()),
        Provider(create: (_) => const DoctorDirectoryRepository()),
        Provider(create: (_) => DigiLockerRepository()),
        Provider(create: (_) => CessationRepository()),
      ],
      child: MaterialApp(
        title: 'OralCare',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const _RootRouter(),
      ),
    );
  }
}

/// Decides which interface to show.
///
/// The consent gate lives here rather than inside the patient home screen, so
/// there is no code path that reaches the risk assessment without consent
/// (spec Table 1: "Proceed only when consent = Yes").
class _RootRouter extends StatelessWidget {
  const _RootRouter();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();

    // While restoring a persisted Firebase session, show a splash rather than
    // flashing the login screen.
    if (session.isInitialising) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = session.user;
    if (user == null) return const RoleSelectScreen();

    if (user.role == UserRole.doctor) return const DoctorHomeScreen();

    if (!user.consent.appAndSelfExam) return const ConsentScreen();

    return const PatientHomeScreen();
  }
}
