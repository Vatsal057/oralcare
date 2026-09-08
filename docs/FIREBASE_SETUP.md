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

## Provisioning clinician accounts

Clinician access is a **server-set Firebase Auth custom claim**
(`role: "doctor"`). The app cannot create a doctor account, and a user cannot
grant themselves the role: `isDoctor()` in `firestore.rules` reads the claim
only, and the rules refuse any client write that sets `role: "doctor"` on a
profile without it.

Setting a claim requires Admin SDK credentials. Use either an
Application Default Credentials login or a service-account key:

```bash
# Option A: ADC (no key file to store)
gcloud auth application-default login

# Option B: service-account key, from
# Firebase console > Project settings > Service accounts > Generate new private key
export GOOGLE_APPLICATION_CREDENTIALS=/absolute/path/service-account.json
```

Then provision the account:

```bash
cd tools
npm install

# Create a new clinician account and grant the claim
node grant_doctor.mjs \
  --project YOUR_PROJECT_ID \
  --username dr.smith \
  --password 'ChooseAStrongPass1' \
  --name 'Dr A Smith'

# Grant the claim to an account that already exists
node grant_doctor.mjs --project YOUR_PROJECT_ID --username dr.smith

# Withdraw clinician access
node grant_doctor.mjs --project YOUR_PROJECT_ID --username dr.smith --revoke
```

The script sets the claim, revokes existing refresh tokens so stale ID tokens
cannot keep the old role, and writes the `users/{uid}` profile the interface
renders from. Hand the username and password to the clinician; they sign in on
the **Doctor login**. If they were already signed in, they must sign out and
back in to pick up the new token.

Never commit the service-account key. `.gitignore` already excludes
`service-account*.json`, `*-service-account*.json` and `tools/node_modules/`.

## Production prerequisites

Server-verified clinician identity is in place, but it is not the whole of a
production posture. Before storing real patient data: verify each clinician
against a professional register before running the script, add audit logging of
clinician reads, validate clinical content with the clinical team, define data
retention and deletion, and complete institutional ethical, legal, privacy and
incident-response reviews.
