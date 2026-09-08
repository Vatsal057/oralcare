#!/usr/bin/env node
// Provisions or revokes clinician access for the OralCare pilot.
//
// Clinician access is a Firebase Auth custom claim (`role: "doctor"`). Only a
// holder of Admin SDK credentials can set it, so a user of the app can never
// promote themselves. The Firestore rules read this claim and nothing else when
// deciding whether shared patient records may be read.
//
// Usage:
//   node grant_doctor.mjs --username dr.smith --password 'Str0ngPass' --name 'Dr A Smith'
//   node grant_doctor.mjs --username dr.smith            # existing account
//   node grant_doctor.mjs --username dr.smith --revoke
//
// Credentials, in order of preference:
//   GOOGLE_APPLICATION_CREDENTIALS=/path/service-account.json
//   or `gcloud auth application-default login` (Application Default Credentials)
//
// Never commit the service-account file. See docs/FIREBASE_SETUP.md.

import process from 'node:process';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

/** Synthetic e-mail domain: must match AuthRepository._emailDomain. */
const EMAIL_DOMAIN = 'oralpilot.app';
const DOCTOR_ROLE = 'doctor';

function parseArgs(argv) {
  const args = { revoke: false };
  for (let i = 0; i < argv.length; i += 1) {
    const key = argv[i];
    if (key === '--revoke') {
      args.revoke = true;
    } else if (key.startsWith('--')) {
      const value = argv[i + 1];
      if (value === undefined || value.startsWith('--')) {
        throw new Error(`Missing value for ${key}`);
      }
      args[key.slice(2)] = value;
      i += 1;
    } else {
      throw new Error(`Unexpected argument: ${key}`);
    }
  }
  return args;
}

function validateUsername(username) {
  if (!username) {
    throw new Error('--username is required.');
  }
  // Same rule as AuthRepository._validateCredentials, so a provisioned account
  // can actually be typed into the app's login form.
  if (!/^[A-Za-z0-9._-]{3,}$/.test(username)) {
    throw new Error(
      'Username must be at least 3 characters and use letters, numbers, dot, dash or underscore only.',
    );
  }
}

function validatePassword(password) {
  if (password === undefined) return;
  if (password.length < 8 || !/[A-Za-z]/.test(password) || !/\d/.test(password)) {
    throw new Error(
      'Password must be at least 8 characters and include a letter and a number.',
    );
  }
}

async function findOrCreateUser(auth, email, password, displayName) {
  try {
    return { user: await auth.getUserByEmail(email), created: false };
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
    if (!password) {
      throw new Error(
        `No account exists for ${email}. Pass --password to create one.`,
      );
    }
    const user = await auth.createUser({ email, password, displayName });
    return { user, created: true };
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  validateUsername(args.username);
  validatePassword(args.password);

  const username = args.username.trim();
  const email = `${username.toLowerCase()}@${EMAIL_DOMAIN}`;

  initializeApp({
    credential: applicationDefault(),
    projectId: args.project || process.env.GOOGLE_CLOUD_PROJECT,
  });

  const auth = getAuth();
  const db = getFirestore();

  if (args.revoke) {
    const user = await auth.getUserByEmail(email);
    await auth.setCustomUserClaims(user.uid, null);
    // Force existing sessions to obtain a fresh token without the claim.
    await auth.revokeRefreshTokens(user.uid);
    await db.collection('users').doc(user.uid).set(
      { role: 'patient' },
      { merge: true },
    );
    console.log(`Revoked clinician access for ${username} (${user.uid}).`);
    console.log('That account must sign in again; it no longer reads shared records.');
    return;
  }

  const { user, created } = await findOrCreateUser(
    auth,
    email,
    args.password,
    args.name,
  );

  await auth.setCustomUserClaims(user.uid, { role: DOCTOR_ROLE });
  // The claim is embedded in the ID token, so old tokens must be invalidated.
  await auth.revokeRefreshTokens(user.uid);

  // The profile document drives the interface; the claim drives authorisation.
  await db.collection('users').doc(user.uid).set(
    {
      username,
      username_lower: username.toLowerCase(),
      role: DOCTOR_ROLE,
      patient_id: null,
      full_name: args.name ?? null,
      age: null,
      sex: null,
      consent_app: false,
      consent_photo: false,
      consent_share: false,
      created_at: new Date().toISOString(),
    },
    { merge: true },
  );

  console.log(
    `${created ? 'Created' : 'Updated'} clinician account ${username} (${user.uid}).`,
  );
  console.log(`Sign in with username: ${username}`);
  console.log('If that account was already open in the app, sign out and in again.');
}

main().catch((error) => {
  console.error(`\nFailed: ${error.message}`);
  if (error.code === 'auth/insufficient-permission' || /credential/i.test(error.message)) {
    console.error(
      'Check GOOGLE_APPLICATION_CREDENTIALS, or run: gcloud auth application-default login',
    );
  }
  process.exitCode = 1;
});
