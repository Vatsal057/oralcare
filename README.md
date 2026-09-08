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
- The patient chooses **which clinician** receives a record; no one else can
  open it, and the choice can be changed or withdrawn at any time
- Risk assessment across 13 variables, including tobacco, areca nut, alcohol,
  clinical history, symptoms, and lesion duration
- Ten-item red-flag safety check and a 14-day escalation rule
- Seven-site guided mouth self-examination
- Lesion record with site, duration, symptoms, notes, and optional local photo
- Action-focused results: lower risk, increased risk, higher risk, monitor and
  review, or **professional check required**
- Follow-up reminders and a patient view of referral/follow-up logistics

### Clinician experience

- Separate clinician account, with a queue containing only records addressed to
  that clinician
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

## Web app

The full OralCare app also runs in the browser using the same Firebase project.
It supports account, consent, assessment, patient, and clinician-review flows.
For privacy and browser compatibility, the web version does **not** offer
camera/gallery capture, device-local photo storage, or photo viewing.

```bash
flutterfire configure --platforms=android,web
flutter run -d chrome
# or create deployable static files
flutter build web
```

Firebase Hosting serves the full app from `build/web`.

The separate [`website/`](website) package remains a static, data-free project
information site if it is needed for a different Hosting target.

## Test two-device sharing

1. Install the same APK on two Android phones.
2. On **Phone A**, register a patient, grant app/self-examination and
   share-with-doctor consent, complete a check, then pick the clinician under
   **Send to a doctor** and switch sharing on.
3. Provision a clinician account with
   [`tools/grant_doctor.mjs`](tools/grant_doctor.mjs) (see
   [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)), then sign in with it on
   **Phone B** and open the patient queue.
4. Record a clinical assessment and outcome; the validation screen updates from
   those entries.
5. Turn share consent off on Phone A, or switch sharing off. The record should no
   longer be visible in the doctor queue.
6. Provision a second clinician and re-address the record to them. It should
   appear in the second queue and disappear from the first.

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

The rules restrict patients to their own records. Sharing is **addressed, not
broadcast**: a patient picks one clinician from the directory, and the rules only
allow a read when `shared_with_doctor == 1` and `shared_with_uid` equals the
reader's own uid. Clinical findings and outcomes can likewise only be written by
the clinician the record was sent to.

The clinician directory (`doctors/{uid}`) is readable by any signed-in user so
patients can choose a recipient, but every client write to it is refused: entries
are created only by the provisioning script, alongside the custom claim.

Clinician access is a **server-set custom claim**, not a client-written field.
`isDoctor()` in the rules checks `request.auth.token.role == 'doctor'`, which can
only be set with Admin SDK credentials via
[`tools/grant_doctor.mjs`](tools/grant_doctor.mjs). The rules also refuse any
client write that puts `role: "doctor"` on a profile without the claim, so
self-promotion is not possible. There is no enrolment code in the app, and no
route to create a clinician account from the client.

Still required before handling real patient data: verification against a
professional register, audit logging of clinician reads, clinically validated
content, data-retention controls, ethical approval, and a full security and
privacy review.

## Quality checks

- 45 unit tests cover all provisional risk weights, category boundaries,
  red-flag overrides, unknown answers, catalogue integrity, and safety wording.
- 14 tests cover addressed sharing: a record is visible only when it is both
  switched on and names a recipient, including legacy rows written before
  recipients existed.
- A widget smoke test confirms that the entry screen renders both account paths.
- GitHub Actions runs analysis and tests on every pull request and push to
  `main`.

## Roadmap

- Clinician-approved multilingual education content and illustrations
- Config-driven questionnaire content approved by the clinical team
- Secure document storage and cross-device photo sharing
- Audit events for clinician reads (server-verified clinician identity is done)
- Firebase Emulator integration tests for access-control rules
- Clinical validation and pilot usability evaluation

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Do not commit Firebase configuration for
a live project, patient records, photos, credentials, recordings, transcripts,
or other clinical/personal data.

## License

[MIT](LICENSE)
