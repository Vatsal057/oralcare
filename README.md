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
- Profile and medical background: contact details, location, medical history,
  allergies, current medications, and an emergency contact, editable under
  **My profile**
- Education, habit-change support, personal records, screening-centre directory,
  rehabilitation guidance, and emergency guidance
- Saved visits to a centre, with the phone number kept to hand

### Clinician experience

- Separate clinician account, with a queue containing only records addressed to
  that clinician
- Referral-alert prioritisation
- Review of risk, symptoms, self-examination, and lesion entries
- Relevant medical history, clinical assessment, investigation, biopsy,
  referral, and follow-up entry
- Attendance tracking: arrival date, an automatic **failed to arrive within two
  weeks** flag derived from the referral date, and text-reminder records
- Referral and follow-up instructions written for the patient to read
- Outcome capture for OPMD/OSCC, histopathology, investigation and imaging
  reports, and final diagnosis
- Documents the patient chose to share, listed on the record
- Pilot validation view: confusion matrix, sensitivity, specificity, predictive
  values, outcome rates by risk band, and false-negative case review

> Validation figures cover **only** the records addressed to the signed-in
> clinician, not the whole pilot cohort. With more than one clinician enrolled,
> each sees a partial picture.

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
3. On **Phone B**, create a doctor account with the enrolment code in
   `AuthRepository`, or provision one with
   [`tools/grant_doctor.mjs`](tools/grant_doctor.mjs) (see
   [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)), then open the queue.
4. Record a clinical assessment and outcome; the validation screen updates from
   those entries.
5. Turn share consent off on Phone A, or switch sharing off. The record should no
   longer be visible in the doctor queue.
6. Provision a second clinician and re-address the record to them. It should
   appear in the second queue and disappear from the first.

7. Attach a photograph on Phone A with photograph consent granted. It should open
   on Phone B in the doctor's view of that record. Withdraw photograph consent and
   it should disappear there.

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

> **Known pilot limitation — the clinician role is self-assignable.**
> `isDoctor()` accepts either a server-set custom claim or the `role` field on
> the user's own profile, which the app writes after checking the in-app
> enrolment code. That code ships inside the app bundle, so a determined user can
> read it, register as a clinician, and list themselves in the directory. This is
> deliberate for pilot convenience, so a clinician account can be created without
> Admin SDK credentials.
>
> Addressed sharing limits the impact: a self-assigned clinician still cannot
> read anyone's record unless that patient specifically chose to send it to them.
>
> Before a real deployment, drop the profile-field branch from `isDoctor()`,
> forbid client writes of `role: "doctor"`, make the directory admin-only again,
> and provision clinicians with
> [`tools/grant_doctor.mjs`](tools/grant_doctor.mjs), which sets the claim.

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
- 14 tests cover the two-week attendance rule and the clinician-module fields,
  including the day-13/day-14 boundary and the states that must not raise a
  non-attendance.
- 11 tests cover gender storage and the Section 1 profile fields, including the
  fallback that keeps the value of accounts written before `sex` was renamed.
- 7 tests cover the screening-centre directory, including the offline fallback
  that must never leave a patient with an empty list.
- 11 tests cover the CareConnect modules: education catalogue, personal records,
  cessation maths, referral letter, rehabilitation protocols, and guest mode.

- 10 tests cover the Kannada terminology, including that every red flag and
  self-examination site has a non-placeholder term, so the translation cannot
  silently fall out of step with the catalogues.
- 10 tests cover reminders, proving no scheduling path throws where the platform
  cannot deliver them.
- 7 tests cover lesion photographs, separating "on the capturing device" from
  "a clinician can open it".
- 4 tests cover the enrolment-code switch. Run them both ways:

```bash
flutter test
flutter test --dart-define=ALLOW_ENROLMENT_CODE=false
```

`flutter test` currently runs **136** tests.
- A widget smoke test confirms that the entry screen renders both account paths.
- GitHub Actions runs analysis and tests on every pull request and push to
  `main`.

## Clinician module coverage

The clinician module follows the clinical team's specification: patient
information, patient assessment, clinical findings, referral, attendance at a
centre, reports, follow-up, and addressed sharing.

Two items are recorded rather than automated, because the pilot has no messaging
gateway: "patient informed by text" and "patient reminded by text" capture that
the clinician sent the instruction and when. Instructions written for the patient
appear in the patient's own record instead of being sent as SMS. Sending real
messages needs an SMS provider, stored phone numbers, and consent to hold them —
a separate decision for the clinical team.

## Reminders, language, roles and photographs

**Reminders (Android only).** The bell icon opens Reminders: a monthly
self-check, plus follow-ups and saved visits two days ahead. Notifications are
optional and are requested, not assumed. The browser cannot deliver them and
says so. Exact alarms are deliberately not requested, so no special permission
is needed.

**Kannada for clinical questions.** The translate icon switches the red-flag
checklist and self-examination between English and Kannada. Every Kannada term
is taken from the clinical team's illustrated questionnaire rather than
translated in code; in Kannada mode the English term stays visible underneath,
because that is what a clinician will ask about. Hindi is intentionally not
offered for clinical questions: those documents contain no verified Hindi, and
the education module keeps its own Hindi content.

**Pilot coordinator.** `node grant_doctor.mjs --coordinator --username …` grants
a claim that makes the validation screen cover every shared record in the pilot
instead of one clinician's patients. A coordinator cannot write clinical
findings, is not offered to patients as a recipient, and still cannot see a
record the patient never shared. The validation screen states which scope it is
showing.

**Photographs across devices.** A consented lesion photograph is stored in
Firestore as bytes, at `assessments/{id}/lesion_photos/{lesionId}`, and is read
by the reviewing clinician from there. No console step and no paid plan is
needed.

Cloud Storage is deliberately not used. It requires the Blaze plan, and its rules
cannot read a Firestore document, so they could not check photograph consent or
which clinician a record was addressed to. Holding the image in Firestore puts it
under exactly the same consent-and-recipient rules as the rest of the record, and
withdrawing photograph consent removes every route to it.

The cost is a size limit: a Firestore document is capped at 1 MiB. Photographs
are captured at 1024px and quality 55, which lands well inside it. An image that
still does not fit is refused rather than half-saved, and the patient is told —
at capture, and again on the result screen — that it stayed on the phone and a
doctor will not be able to open it. Records that predate this carry a Storage URL
instead; those are still displayed.

**Turning off clinician self-registration.** Build with
`--dart-define=ALLOW_ENROLMENT_CODE=false` to remove the enrolment-code path
entirely — the Doctor login stops offering account creation and the repository
refuses it. Use `--dart-define=ENROLMENT_CODE=…` to change the code without
editing source. Both are covered by tests that run under either build.

## Known limits of this build

Read these before demonstrating the app:

- **The app cannot book appointments.** Saving a visit stores a reminder in the
  patient's own record and shows the centre's number. Nothing is sent to the
  centre, and the wording says so.
- **Screening-centre details must be verified.** The app prefers the
  `screening_centers` Firestore collection and falls back to the copy built into
  the binary, warning the patient when it does. Publish verified entries with
  [`tools/seed_centers.mjs`](tools/seed_centers.mjs).
- **Reminders are Android-only** and only fire while the app is installed on that
  device. The browser cannot schedule them.
- **Translation is partial.** Clinical questions and the education module carry
  Kannada; the surrounding interface is still English.
- **Photographs are capped at roughly 900 KB** because they are held inside a
  Firestore document. They are downscaled to 1024px at capture to fit; one that
  still does not fit is refused, and the patient is told it stayed on the phone.
- **Family history and immunosuppression are recorded but unscored.** The
  CareConnect specification lists them without weights, and a test enforces that
  they do not move a patient's score until the clinical team agrees one.
- **`assets/images/8.png` is missing**, so the new throat site shows a labelled
  placeholder instead of an illustration.
- **Guest mode is not persisted.** Nothing a guest enters is saved.

## Roadmap

- Clinician-approved multilingual education content and illustrations
- Config-driven questionnaire content approved by the clinical team
- Secure document storage and cross-device photo sharing
- Server-verified clinician identity only, plus audit events for clinician reads
- Firebase Emulator integration tests for access-control rules
- Clinical validation and pilot usability evaluation

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Do not commit Firebase configuration for
a live project, patient records, photos, credentials, recordings, transcripts,
or other clinical/personal data.

## License

[MIT](LICENSE)
