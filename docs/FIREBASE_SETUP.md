# Firebase setup

OralCare uses Firebase Authentication and Cloud Firestore so a patient and a
clinician on separate devices can access the same consented record.

This repository intentionally excludes the live Firebase configuration files:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Firebase API keys identify a project but are not secret credentials. They are
still excluded here so a fork cannot accidentally connect to the development
Firebase project.

## Create a Firebase project

1. Create a project in the [Firebase console](https://console.firebase.google.com/).
2. Create a **Cloud Firestore** database in **Production mode**. Choose a region
   appropriate for the jurisdiction and data-governance requirements.
3. Enable **Authentication → Sign-in method → Email/Password**.
4. Register the Android app. Its existing application ID is
   `com.oralhealth.oral_cancer_app`.
5. Install the FlutterFire CLI if needed:

   ```bash
   dart pub global activate flutterfire_cli
   ```

6. From the repository root, generate local config:

   ```bash
   flutterfire configure --platforms=android
   ```

   Add `ios` only after configuring an iOS bundle identifier and Apple project.

## Deploy the rules

Review `firestore.rules` before deployment. Then install and authenticate the
Firebase CLI, choose your project, and deploy:

```bash
npm install -g firebase-tools
firebase login
firebase use YOUR_PROJECT_ID
firebase deploy --only firestore:rules
```

## Production prerequisites

The included rules document the pilot's main limitation: a doctor role is
currently client-set after an enrolment-code check. That is not adequate for a
real deployment. Before storing real patient data, replace it with a
server-set custom claim after verified professional identity checks; update
`isDoctor()` in `firestore.rules` to rely on that claim; add audited server-side
access controls; and complete institutional ethical, legal, privacy, retention,
and incident-response reviews.
