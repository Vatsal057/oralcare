#!/usr/bin/env node
// Publishes the screening-centre directory to Firestore.
//
// Clinic phone numbers, timings and departments change, and the specification
// requires them to be verified and kept updated. The app reads this collection
// first and only falls back to its built-in copy, so correcting a number here
// fixes it for every user without shipping a release.
//
// VERIFY BEFORE PUBLISHING. A wrong number in a cancer-referral pathway can
// delay care. Each entry should be confirmed by phone, and `verifiedOn` set to
// the date it was checked.
//
// Usage:
//   node seed_centers.mjs --project YOUR_PROJECT_ID --file centers.json
//   node seed_centers.mjs --project YOUR_PROJECT_ID --list
//
// Credentials: GOOGLE_APPLICATION_CREDENTIALS=/path/service-account.json
//          or  gcloud auth application-default login

import process from 'node:process';
import { readFile } from 'node:fs/promises';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const COLLECTION = 'screening_centers';

/** Must match CenterType in lib/domain/referral/screening_centers_catalog.dart. */
const VALID_TYPES = [
  'dentalInstitute',
  'oncologyCentre',
  'oralMedicineOmfs',
  'communityScreening',
];

const REQUIRED = ['id', 'name', 'type', 'city', 'state', 'address', 'phone', 'timings'];

function parseArgs(argv) {
  const args = { list: false };
  for (let i = 0; i < argv.length; i += 1) {
    const key = argv[i];
    if (key === '--list') {
      args.list = true;
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

function validate(center, index) {
  for (const field of REQUIRED) {
    if (!center[field] || String(center[field]).trim() === '') {
      throw new Error(`Centre #${index + 1}: "${field}" is required.`);
    }
  }
  if (!VALID_TYPES.includes(center.type)) {
    throw new Error(
      `Centre "${center.id}": type must be one of ${VALID_TYPES.join(', ')}.`,
    );
  }
  if (center.services !== undefined && !Array.isArray(center.services)) {
    throw new Error(`Centre "${center.id}": services must be a list.`);
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));

  initializeApp({
    credential: applicationDefault(),
    projectId: args.project || process.env.GOOGLE_CLOUD_PROJECT,
  });
  const db = getFirestore();

  if (args.list) {
    const snap = await db.collection(COLLECTION).get();
    if (snap.empty) {
      console.log('The directory is empty. The app is using its built-in copy.');
      return;
    }
    console.log(`${snap.size} centre(s) published:`);
    for (const doc of snap.docs) {
      const d = doc.data();
      console.log(
        `  ${doc.id}: ${d.name} (${d.city}) · ${d.phone}` +
          `${d.verifiedOn ? ` · verified ${d.verifiedOn}` : ' · NOT VERIFIED'}`,
      );
    }
    return;
  }

  if (!args.file) {
    throw new Error('Pass --file centers.json, or --list to inspect.');
  }

  const raw = JSON.parse(await readFile(args.file, 'utf8'));
  const centers = Array.isArray(raw) ? raw : raw.centers;
  if (!Array.isArray(centers) || centers.length === 0) {
    throw new Error('The file must contain a non-empty array of centres.');
  }
  centers.forEach(validate);

  const batch = db.batch();
  for (const center of centers) {
    batch.set(
      db.collection(COLLECTION).doc(center.id),
      {
        ...center,
        services: center.services ?? [],
        updated_at: new Date().toISOString(),
      },
      { merge: true },
    );
  }
  await batch.commit();

  console.log(`Published ${centers.length} centre(s) to ${COLLECTION}.`);
  const unverified = centers.filter((c) => !c.verifiedOn);
  if (unverified.length > 0) {
    console.warn(
      `\nWarning: ${unverified.length} centre(s) have no verifiedOn date: ` +
        unverified.map((c) => c.id).join(', '),
    );
    console.warn('Confirm these by phone before the pilot relies on them.');
  }
}

main().catch((error) => {
  console.error(`\nFailed: ${error.message}`);
  if (/credential/i.test(error.message)) {
    console.error(
      'Check GOOGLE_APPLICATION_CREDENTIALS, or run: gcloud auth application-default login',
    );
  }
  process.exitCode = 1;
});
