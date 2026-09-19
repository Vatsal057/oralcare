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

There are two ways to create a clinician in this pilot.

**In-app enrolment code (pilot convenience).** The Doctor login offers *Create a
new doctor account*, which asks for the enrolment code held in
`AuthRepository.doctorEnrolmentCode`. This needs no Admin credentials. It is also
the weak path: the code ships inside the app bundle, so anyone who reads it can
self-assign the clinician role. Use it for demos, not for real patient data.

**Server-set custom claim (recommended).** The script below sets a Firebase Auth
custom claim that a client cannot forge. `isDoctor()` in `firestore.rules`
accepts the claim or the profile field today; for a real deployment, remove the
profile-field branch so the claim is the only route.

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
  --name 'Dr A Smith' \
  --clinic 'City Dental, Ahmedabad'

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

## Publishing the screening-centre directory

The app reads screening centres from the `screening_centers` collection and only
falls back to the list compiled into the binary, telling the patient when it has
done so. Publishing verified entries therefore corrects a wrong phone number for
every user without shipping a release.

```bash
cd tools
npm install

# inspect what is currently published
node seed_centers.mjs --project YOUR_PROJECT_ID --list

# publish a verified list
node seed_centers.mjs --project YOUR_PROJECT_ID --file centers.json
```

`centers.json` is an array of centres. `id`, `name`, `type`, `city`, `state`,
`address`, `phone` and `timings` are required; `type` must be one of
`dentalInstitute`, `oncologyCentre`, `oralMedicineOmfs`, `communityScreening`.
Set `verifiedOn` to the date you confirmed the details by phone — the script
warns about any entry without it.

```json
[
  {
    "id": "cids_coorg",
    "name": "Coorg Institute of Dental Sciences",
    "type": "dentalInstitute",
    "city": "Virajpet",
    "state": "Karnataka",
    "address": "K.K. Campus, Maggula Village, Virajpet 571218",
    "phone": "+91 8274 256479",
    "timings": "Monday – Saturday: 9:00 AM – 4:00 PM",
    "services": ["Biopsy", "Oral Medicine OPD", "Tobacco cessation"],
    "verifiedOn": "2026-09-19"
  }
]
```

The rules make this collection readable by any signed-in user and refuse all
client writes, so it can only be curated with Admin credentials.

## Production prerequisites

Before storing real patient data: remove the in-app enrolment-code path and the
profile-field branch of `isDoctor()`, make the `doctors` directory admin-only,
verify each clinician against a professional register before provisioning, add
audit logging of clinician reads, validate clinical content with the clinical
team, define data retention and deletion, and complete institutional ethical,
legal, privacy and incident-response reviews.
