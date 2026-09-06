# OralCare

[![Flutter CI](https://github.com/Vatsal057/oralcare/actions/workflows/ci.yml/badge.svg)](https://github.com/Vatsal057/oralcare/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A Flutter pilot for oral-cancer awareness, structured risk assessment, guided
mouth self-examination, consented clinician review, and follow-up.

> **Not a diagnostic tool.** OralCare supports awareness, early recognition,
> and referral. It does not diagnose or stage oral cancer. Its risk weights and
> thresholds are provisional pilot values that require clinical validation before
> use in care decisions.

## What is implemented

### Patient experience

- Separate patient account, consent, and sharing choices
- Risk assessment across 13 variables, including tobacco, areca nut, alcohol,
  clinical history, symptoms, and lesion duration
- Ten-item red-flag safety check and a 14-day escalation rule
- Seven-site guided mouth self-examination
- Lesion record with site, duration, symptoms, notes, and optional local photo
- Action-focused results: lower risk, increased risk, higher risk, monitor and
  review, or **professional check required**
- Follow-up reminders and a patient view of referral/follow-up logistics

### Clinician experience

- Separate clinician account and consent-filtered patient queue
- Referral-alert prioritisation
- Review of risk, symptoms, self-examination, and lesion entries
- Clinical assessment, investigation, biopsy, referral, and follow-up entry
- Outcome capture for OPMD/OSCC, histopathology, and final diagnosis
- Pilot validation view: confusion matrix, sensitivity, specificity, predictive
  values, outcome rates by risk band, and false-negative case review

## Safety model

The risk engine in `lib/domain/risk_engine.dart` follows the current pilot
specification:

1. It totals provisional risk weights into three bands: **0–4 lower**,
   **5–9 increased**, and **10 or more higher**.
2. Red flags take priority over numerical score. A red-flag finding persisting
   for two weeks or more, or prior OSCC, results in **professional check
   required**.
3. “Don't know” remains explicitly unknown rather than being scored as zero.
4. The app stores the reasons behind each result so the output is reviewable,
   not a black box.

No output claims that a user has cancer.

## Architecture

```text
lib/
  core/          theme, clinical safety notices, reusable widgets
  data/          Firebase Auth + Firestore repositories and models
  domain/        risk catalogue, safety engine, follow-up and validation logic
  features/      patient and clinician Flutter screens
  state/         signed-in session and in-progress assessment state
```

Firestore holds user profiles and assessments; each assessment has lesion,
clinical-assessment, and outcome data. The patient and clinician interfaces are
linked through `Patient_ID`.

## Quick start

### Prerequisites

- Flutter **3.41.5** or later on the stable channel
- Android SDK / Android device or emulator
- A Firebase project with Cloud Firestore and Email/Password Authentication

### Run locally

```bash
git clone https://github.com/Vatsal057/oralcare.git
cd oralcare
flutter pub get

# Generate your local Firebase configuration before building or running.
dart pub global activate flutterfire_cli
flutterfire configure --platforms=android

flutter run
```

Detailed Firebase setup and production hardening requirements are in
[docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md).

### Verify and build

```bash
flutter analyze lib test
flutter test
flutter build apk --debug
```

The debug APK is written to:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

## Test two-device sharing

1. Install the same APK on two Android phones.
2. On **Phone A**, register a patient, grant app/self-examination and
   share-with-doctor consent, complete a check, and enable **Send this record to
   the doctor queue**.
3. On **Phone B**, register a doctor account using the pilot enrolment code
   configured in `AuthRepository`, then open the patient queue.
4. Record a clinical assessment and outcome; the validation screen updates from
   those entries.
5. Turn share consent off on Phone A. The record should no longer be visible in
   the doctor queue.

Photographs currently remain on the capturing device. They are intentionally not
synced because Firebase Storage is not configured in this pilot.

## Firebase and security

The repository does not include a live Firebase project configuration. Generate
your own with FlutterFire as part of setup. Firestore rules live in
[`firestore.rules`](firestore.rules); deploy them only after review:

```bash
firebase use YOUR_PROJECT_ID
firebase deploy --only firestore:rules
```

The rules restrict patients to their records and limit clinician reads to
patient-shared assessments. However, the current clinician role is client-set
following a pilot enrolment-code check. That is **not sufficient for production
health-data access control**. Before a real deployment, use a verified,
server-set clinician role (for example, Firebase custom claims), audit logging,
validated clinical content, data-retention controls, applicable ethical approval,
and a full security/privacy review.

## Quality checks

- 45 unit tests cover all provisional risk weights, category boundaries,
  red-flag overrides, unknown answers, catalogue integrity, and safety wording.
- A widget smoke test confirms that the entry screen renders both account paths.
- GitHub Actions runs analysis and tests on every pull request and push to
  `main`.

## Roadmap

- Clinician-approved multilingual education content and illustrations
- Config-driven questionnaire content approved by the clinical team
- Secure document storage and cross-device photo sharing
- Server-verified clinician identity and audit events
- Firebase Emulator integration tests for access-control rules
- Clinical validation and pilot usability evaluation

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Do not commit Firebase configuration for
a live project, patient records, photos, credentials, recordings, transcripts,
or other clinical/personal data.

## License

[MIT](LICENSE)
