# OralCare / Oral Cancer CareConnect — Application Specification

**Build:** pilot, commit `c1bbb75`
**Platforms:** Android (full), Web (full except camera capture)
**Live web build:** https://oralcare.web.app (the original `oral-cancer-pilot-1027-dc3a3.web.app` also stays current — both sites receive every deploy)
**Backend:** Firebase Authentication + Cloud Firestore (free Spark plan; no Cloud Storage, no Cloud Functions)
**Verification at time of writing:** `flutter analyze` clean · 183 tests pass · web, debug APK and 33 MB arm64 release APK build · 41 of 41 illustrations present

---

## How to use this document

This is a reverse-specification: it describes what the application actually does, written so it can be laid side by side with the four source documents.

Sections 1–13 describe the app. **Section 14 is the traceability matrix** — one table per source document, clause by clause, with an implementation status and a pointer into this document. If your goal is "did they build what I asked for", start at section 14 and follow the links back.

Status vocabulary used throughout:

| Status | Meaning |
|---|---|
| **Built** | Implemented and exercised by a test or a build |
| **Built, limited** | Implemented, but with a stated constraint the reader must know about |
| **Recorded only** | The data is captured and stored but does not drive any behaviour |
| **Not built** | Absent, with the reason given |

Source documents referenced:

| Short name | File | Role |
|---|---|---|
| **IPO** | `Oral_Cancer_Mobile_App_Patient_Doctor_Login.docx` | The core Input–Process–Output specification. Sections 1–7, Tables 1–11. Primary contract. |
| **Clinician** | `Copy 3.docx` | Clinician module scope, sections 1–8 |
| **CareConnect** | `Final cHeck.docx` | "Oral Cancer CareConnect" feature list, sections 1–12 / modules D–J |
| **Questionnaire** | `sree cancer questionnaire final (1).docx` | Bilingual English–Kannada illustrated questionnaire; source of all Kannada clinical terms |

---

## 1. System architecture

The IPO document defines four layers (IPO §1). All four exist as distinct code regions:

| IPO layer | Implementation | Location |
|---|---|---|
| PATIENT LOGIN | 20 patient-facing screens | `lib/features/patient/`, `lib/features/auth/`, plus 6 support modules |
| RISK & SAFETY ENGINE | Pure function, no I/O, no Flutter dependency | `lib/domain/risk_engine.dart` |
| DOCTOR LOGIN | 5 clinician screens | `lib/features/doctor/` |
| OUTCOME / VALIDATION DATABASE | Aggregation service + read-only screen | `lib/domain/validation_service.dart`, `lib/features/doctor/validation_screen.dart` |

Layering rule enforced by directory: `domain/` holds pure logic and content catalogues with no Firebase or Flutter imports; `data/` holds models and repositories; `features/` holds screens; `state/` holds in-flight controllers. The risk engine is deliberately isolated so it can be re-run over stored answers during validation without touching the network.

Code size: ~20,400 lines of Dart across `lib/` and `test/`.

---

## 2. Roles and access model

Three roles. Two are user-facing; the third is analytical.

| Role | How it is granted | What it can do |
|---|---|---|
| **Patient** | Self-registration | Own records only |
| **Doctor** | Firebase custom claim `role: doctor`, set server-side by `tools/grant_doctor.mjs` — **or** the pilot enrolment code path (see below) | Read records addressed to them; write clinical assessment and outcome on those records |
| **Coordinator** | Firebase custom claim `role: coordinator` only. **Cannot be self-assigned** — there is deliberately no profile-field fallback for this claim | Read every shared record in the cohort for validation statistics. Can never write a clinical finding, and is not offered to patients as a sharing recipient |

**Guest mode** (CareConnect §1, "guest-information mode") is a fourth, unauthenticated state: the full assessment flow runs, but the profile cannot be saved and records are session-only. Reminders use the patient ID `GUEST`.

### 2.1 The enrolment-code weakness — stated plainly

A clinician can self-register by typing the code `ORAL-PILOT-2026`, and the Firestore rules contain a fallback that trusts `role: doctor` written on a user's own profile document. **Both are security holes**: the code ships inside the app bundle and can be read out of it, and a patient can write `role: doctor` onto their own profile. They were restored at the project owner's explicit request so the pilot can onboard clinicians without a service-account key.

Mitigations in place:
- Build with `--dart-define=ALLOW_ENROLMENT_CODE=false` to remove the path entirely — the Doctor login stops offering account creation and the repository refuses it. Covered by tests that run under either build.
- Override the code without a source edit: `--dart-define=ENROLMENT_CODE=…`
- The coordinator claim has no such fallback, so cohort-wide statistics remain claim-only.

Before real-world deployment, the enrolment path and the `hasDoctorProfile()` rule fallback must both be removed.

---

## 3. Complete screen inventory

26 screens. Patient side first, then clinician.

| # | Screen | Class | File |
|---|---|---|---|
| **Entry and account** | | | |
| 1 | Role selection | `RoleSelectScreen` | `features/auth/role_select_screen.dart` |
| 2 | Login | `LoginScreen` | `features/auth/login_screen.dart` |
| 3 | Registration | `RegisterScreen` | `features/auth/register_screen.dart` |
| 4 | Consent | `ConsentScreen` | `features/patient/consent_screen.dart` |
| **Patient hub** | | | |
| 5 | Check Hub (tab 1) | `PatientHomeScreen` | `features/patient/patient_home_screen.dart` |
| 6 | My profile | `ProfileScreen` | `features/patient/profile_screen.dart` |
| 7 | Reminders | `RemindersScreen` | `features/patient/reminders_screen.dart` |
| **Assessment flow** | | | |
| 8 | Step 1 — Risk factors | `RiskAssessmentScreen` | `features/patient/risk_assessment_screen.dart` |
| 9 | Safety check (conditional) | `RedFlagScreen` | `features/patient/red_flag_screen.dart` |
| 10 | Step 2 — Self-examination | `SelfExamScreen` | `features/patient/self_exam_screen.dart` |
| 11 | Step 3 — Record the finding (conditional) | `LesionScreen` | `features/patient/lesion_screen.dart` |
| 12 | Your result | `ResultScreen` | `features/patient/result_screen.dart` |
| 13 | Past assessment detail | `AssessmentDetailScreen` | `features/patient/assessment_detail_screen.dart` |
| 14 | Clinical reference photos | `LesionReferenceDialog` | `features/patient/lesion_reference_dialog.dart` |
| **CareConnect support modules** | | | |
| 15 | Education (tab 2) | `EducationScreen` | `features/education/education_screen.dart` |
| 16 | DigiLocker (tab 3) | `DigiLockerScreen` | `features/records/digilocker_screen.dart` |
| 17 | Cessation (tab 4) | `CessationScreen` | `features/cessation/cessation_screen.dart` |
| 18 | Care & Rehab hub (tab 5) | `_CareAndRehabHub` | `features/patient/patient_home_screen.dart` |
| 19 | Screening centres & referrals | `ReferralScreen` | `features/referral/referral_screen.dart` |
| 20 | Post-treatment rehabilitation | `RehabilitationScreen` | `features/rehabilitation/rehabilitation_screen.dart` |
| 21 | Emergency guidance | `EmergencyScreen` | `features/emergency/emergency_screen.dart` |
| **Clinician** | | | |
| 22 | Patient queue | `DoctorHomeScreen` | `features/doctor/doctor_home_screen.dart` |
| 23 | Patient record review | `PatientRecordScreen` | `features/doctor/patient_record_screen.dart` |
| 24 | Clinical assessment entry | `ClinicalAssessmentScreen` | `features/doctor/clinical_assessment_screen.dart` |
| 25 | Clinical outcome entry | `OutcomeScreen` | `features/doctor/outcome_screen.dart` |
| 26 | Algorithm validation | `ValidationScreen` | `features/doctor/validation_screen.dart` |

### 3.1 Bottom navigation

Five tabs: `Check Hub` · `Education` · `DigiLocker` · `Cessation` · `Care & Rehab`.

### 3.2 Routing gate

`_RootRouter` in `lib/app.dart` decides in this order:

1. Session initialising → splash
2. No user → screen 1 (role selection)
3. `role == doctor` → screen 22 (queue)
4. `!consent.appAndSelfExam` → screen 4 (consent)
5. Otherwise → screen 5 (Check Hub)

Step 4 is the enforcement point for IPO Table 1 *"Proceed only when consent = Yes"*. **There is no code path that reaches the risk assessment without it** — the gate is in the router, not in a button handler, so it cannot be bypassed by navigation.

---

## 4. Patient assessment flow

### 4.1 Navigation order and branch rules

```
Check Hub  ──"Start Self-Check"──▶  Step 1: Risk factors
                                          │
                        reportsSuspiciousLesion?
                          YES ──▶ Safety check ──┐
                          NO  ───────────────────┤
                                                 ▼
                                    Step 2: Self-examination
                                                 │
                                    shouldRecordLesion?
                          YES ──▶ Step 3: Record the finding ──┐
                          NO  ──────────────────────────────────┤
                                                                ▼
                                                        Your result
                                                                │
                                                          "Done" ──▶ Check Hub
```

Branch predicates (`lib/state/assessment_flow.dart`):

- `reportsSuspiciousLesion` = answer to `suspicious_lesion` is `yes`
- `shouldRecordLesion` = `anySiteAbnormal || reportsSuspiciousLesion`

A consequence worth knowing: a patient who reports a suspicious lesion on Step 1 always reaches Step 3, even if they mark no abnormal site on Step 2. This is intentional — they already said something is wrong, so the app must let them describe it.

The result screen has no back button. Answering "No" to `suspicious_lesion` after previously answering "Yes" erases the duration answer **and every ticked red flag**, so a stale flag can never reach the engine.

### 4.2 Registration fields (IPO Table 1 / CareConnect §1)

| Field | Control | Required | Validation |
|---|---|---|---|
| Username | text | Yes | ≥3 chars, `^[A-Za-z0-9._-]+$` |
| Password | text, obscured | Yes | ≥8 chars, ≥1 letter, ≥1 digit |
| Confirm password | text, obscured | Yes | must match |
| Name | text | No | — |
| Patient ID | text | No | `^[A-Za-z0-9/_-]{3,32}$`; auto-generated if blank |
| **Age in years** | numeric | **Yes** | 0–120 |
| **Gender** | dropdown | **Yes** | Male / Female / Transgender / Prefer not to say |
| Mobile number | phone | No | ≥10 digits if entered |
| Town or city | text | No | — |
| Relevant medical history | text, 2 lines | No | — |
| Emergency contact name | text | No | — |
| Emergency contact number | phone | No | ≥10 digits if entered |

Age and gender are hard-required: age is a scored risk variable, so an absent value would silently score 0. The field is labelled **Gender**, not "Sex" — the IPO document says "Sex, where used", CareConnect §1 says "gender", and the Questionnaire says `GENDER / ಲಿಂಗ`. Gender wins. Accounts created before the rename are still read correctly: `AppUser.fromFirestore` falls back to the legacy `sex` key.

**Patient ID format:** `OC-{year}-{6 chars}`, e.g. `OC-2026-4F9A2C`, derived from the Firebase uid. Uniqueness is proved by a creation-only reservation document at `patient_ids/{patientId}` rather than by querying other users' profiles — a patient must not be able to read the user collection. A failed profile write rolls back the Auth account so a username is never stranded.

### 4.3 Consent (IPO Table 1)

Three independent switches, each a hard gate:

| Consent | Gate effect | Firestore key |
|---|---|---|
| Use the app and examine my own mouth | **Required.** Nothing downstream runs without it | `consent_app` |
| Store a photograph of a finding | Enables/disables photograph capture | `consent_photo` |
| Share my record with a doctor | Enables/disables addressing a record to a clinician | `consent_share` |

Reachable again at any time from the Check Hub shield icon, so consent can be withdrawn as easily as given. Withdrawal is immediate and real: clearing photograph consent strips *all three* routes to the image (see §4.8), and clearing share consent removes the record from the clinician's queue on the next load.

### 4.4 Step 1 — Risk-assessment variables (IPO Table 2)

15 variables. All applicable ones are **required**; Continue is blocked with a count of what is missing. Scores are the provisional pilot weights from IPO Table 2.

| Key | Question | Role | Options → score |
|---|---|---|---|
| `age_band` | Age | scored, **derived** | `<40`→0 · `40–49`→1 · `50–59`→2 · `≥60`→3 |
| `smoking` | Smoking | scored | Never→0 · Former→1 · Current occasional→2 · Current regular→3 |
| `smokeless_tobacco` | Smokeless tobacco | scored | Never→0 · Former→1 · Current→3 |
| `areca_betel` | Areca / betel nut | scored | Never→0 · Former→1 · Occasional current→2 · Regular current→3 |
| `gutkha_pan_masala` | Gutkha / pan masala | exposure only | No · Past · Current — **all unweighted** |
| `exposure_duration` | Duration of tobacco / areca exposure | scored, conditional | <5 y→0 · 5–10 y→1 · >10 y→2 |
| `use_frequency` | Frequency of use | scored, conditional | Occasional→0 · Once daily→1 · Several times daily→2 |
| `alcohol` | Alcohol | scored | None→0 · Occasional→1 · Regular→2 |
| `previous_opmd` | Previous OPMD | scored | No→0 · Yes→**4** · Don't know→**unknown** |
| `previous_oscc` | Previous oral cancer (OSCC) | scored | No→0 · Yes→**5** (+ override) |
| `family_history` | Family history of cancer | exposure only | No · Yes unweighted · Don't know unknown |
| `immunosuppression` | Weakened immune system | exposure only | No · Yes unweighted · Don't know unknown |
| `suspicious_lesion` | Suspicious oral lesion or symptom right now? | red-flag gate | No · Yes |
| `lesion_duration` | How long has it been present? | referral trigger, conditional | <2 weeks · ≥2 weeks |
| `neck_lump` | New or persistent lump in the neck | referral trigger | No · Yes |

**Maximum possible score: 27.**

Age is not asked here — it is read from the profile and mapped to a band, then displayed read-only. Duration and frequency appear only when some tobacco or areca exposure is reported; otherwise a note explains their absence. `lesion_duration` appears only when a suspicious lesion is reported.

Two deliberate design choices in this table:

- **"Don't know" is retained as unknown, never scored as zero.** The unknown keys are stored on the record and listed to both the patient and the clinician. Scoring an unknown as absent would quietly bias the score downward and make the record unauditable.
- **Unweighted variables score zero and are labelled as such.** `gutkha_pan_masala` is unweighted because IPO Table 2 says "final weight to be validated". `family_history` and `immunosuppression` come from CareConnect module D, which lists them with no weights at all. Inventing a weight would move patients between bands on a guess. A test enforces that adding these answers does not change the total.

### 4.5 Safety check — red flags (IPO §2.3)

**13 items**, all optional switches:

| # | Item | Source |
|---|---|---|
| 1 | Non-healing ulcer or sore | IPO §2.3 |
| 2 | Red patch | IPO §2.3 |
| 3 | White patch | IPO §2.3 |
| 4 | Red-and-white patch | IPO §2.3 |
| 5 | Lump or thickening | IPO §2.3 |
| 6 | Unexplained bleeding | IPO §2.3 |
| 7 | Persistent numbness | IPO §2.3 |
| 8 | Difficulty swallowing | IPO §2.3 |
| 9 | Restricted tongue or jaw movement | IPO §2.3 |
| 10 | Persistent neck lump | IPO §2.3 |
| 11 | Teeth loosening without an obvious cause | CareConnect §3 |
| 12 | Difficulty speaking | CareConnect §3 |
| 13 | Unexplained weight loss | CareConnect §3 |

IPO §2.3 lists ten; items 11–13 close the gap against CareConnect §3. In Kannada mode the localised term is the title and the English term stays visible underneath, because that is the term a clinician will ask about.

### 4.6 Step 2 — Guided self-examination (IPO Table 5 / CareConnect §3)

**8 sites.** IPO Table 5 lists seven; `throat` is added from CareConnect §3 ("The back of the throat, where feasible").

| Key | Site | Instruction |
|---|---|---|
| `lips` | Lips | Look for a sore, patch or lump on both lips. |
| `inner_cheeks` | Inner cheeks | Inspect both cheeks. |
| `gums` | Gums | Look for any patch or swelling. |
| `tongue` | Tongue | Inspect the top, both sides and underside. |
| `floor_of_mouth` | Floor of mouth | Inspect under the tongue. |
| `palate` | Palate | Inspect the roof of the mouth. |
| `throat` | Back of the throat | Open wide and look as far back as you comfortably can. Skip this if you cannot see clearly. |
| `neck` | Neck | Feel for any new lump. |

Per site: two switches — *"I examined this site"* and, once examined, *"I found something abnormal"*. Marking abnormal forces examined to true. Each site carries an illustration (`assets/images/1.png`–`8.png`) and, when marked abnormal, a button into the clinical photo gallery for comparison.

**All eight sites now carry an illustration.** `assets/images/8.png` (back of the throat) was added after clinical review; it is an intraoral oropharyngeal view matching the style of the palate image, showing a single midline uvula, symmetric tonsillar pillars, the palatine tonsils and the posterior pharyngeal wall, with healthy mucosa throughout.

The fallback behaviour is retained for any site added in future: `_imageForSite` returns null rather than a default, and the card renders a labelled placeholder — *"No illustration for &lt;site&gt; yet. Follow the written instruction below."* It never substitutes another site's image, because showing the wrong anatomy is worse than showing none.

The illustrations are AI-generated, which removes any stock-photography licensing question but introduces a different one: image models are unreliable on mouth anatomy. Each intraoral image should be checked for a single midline uvula, symmetric tonsillar pillars, plausible tooth count and uniformly healthy mucosa before it ships, because these pictures are the reference a patient compares their own mouth against — a malformed one could make a normal mouth look abnormal, or the reverse.

**Illustration cropping — fixed at clinical review.** The illustrations were being cut off, reported twice by the reviewing clinician. Two independent causes:

1. `BoxFit.cover` on a fixed 200 px-tall box. Cover scales an image to *fill* its box and discards the overflow. The assets range from 1.09:1 to 1.50:1, so **17% to 39% of every illustration was being cropped away**, worst on the neck image at 61% visible. Nothing on screen indicated anything was missing.
2. A dark gradient band carrying the site name was layered over the bottom of the image, hiding the lower part of the anatomy on every card.

Both fixed: `BoxFit.contain` inside a 280 px cap, the site name moved below the illustration, and tap-to-enlarge added with a visible "Tap to enlarge" affordance. Letterboxing an image that is whole beats a flush one that is cut.

The same `BoxFit.cover` bug affected the clinical reference gallery and, more seriously, **lesion photographs in both the patient's and the clinician's views** — where the cropped-away region is the lesion margin and surrounding mucosa a reviewer is specifically looking at. All are now `contain`. There is no remaining `BoxFit.cover` in `lib/`.

### 4.7 Step 3 — Lesion recording (IPO Table 6 / CareConnect module E)

| Field | Control | Required | Notes |
|---|---|---|---|
| Lesion site | dropdown, 11 values | No | Lip · Inner cheek (buccal mucosa) · Gum (gingiva) · Tongue — top surface · Tongue — lateral border · Tongue — underside · Floor of mouth · Palate · Retromolar area · Neck · Other |
| Date first noticed | date picker | No | Range: 5 years ago to today; no future dates. Auto-fills duration if duration is still blank |
| Duration | numeric | No | — |
| Unit | dropdown | No | days · weeks (normalised to days) |
| Pain | switch | No | |
| Bleeding | switch | No | |
| Change in size | switch | No | |
| Change in colour | switch | No | |
| Numbness | switch | No | |
| Difficulty chewing or swallowing | switch | No | |
| Restricted tongue or jaw movement | switch | No | |
| Photograph | camera / gallery | No | Triple-gated — see §4.8 |
| Additional note | text, 500 chars | No | |

A live duration hint escalates as soon as the entered duration reaches 14 days: *"That is 3 weeks. Anything lasting two weeks or longer needs a professional check."*

### 4.8 Photographs (IPO Table 1 / Table 6, CareConnect module E)

Capture is gated three ways: platform (`kIsWeb` disables it with an explanatory banner), photograph consent (buttons hidden), and a re-check inside the picker handler as defence in depth.

Storage went through a design change worth recording, because it affects what a clinician can see.

**Problem:** photographs were device-local, so a clinician reviewing the record on another device saw nothing. The obvious fix — Firebase Cloud Storage — requires the paid Blaze plan, which this pilot does not have.

**Resolution:** the image is stored as bytes in its own Firestore document at `assessments/{id}/lesion_photos/{lesionId}`.

This is not merely a cost workaround; it is the better fit. Cloud Storage rules cannot read a Firestore document, so they could never have checked photograph consent or which clinician the record was addressed to. In Firestore the image sits under exactly the same consent-and-recipient rules as the rest of the record.

**The cost is a size limit.** A Firestore document is capped at 1 MiB. Consequences, all handled explicitly:

- Capture is downscaled hard: 1024 × 1024 max, JPEG quality 55. Typical result 100–150 KB.
- The store refuses anything over 900 KiB (`PhotoDocumentStore.maxBytes`) rather than failing with an opaque write error.
- The patient is told twice — at capture (*"This photograph is too large to send to a doctor. Try taking it again, a little further back."*) and again on the result screen (*"Your photograph stayed on this phone… a doctor will not be able to open it."*). Silence here would leave someone believing a clinician can see an image that never left the phone.
- The same downscaled file is kept locally, so the clinician sees exactly what the patient sees.

Three photograph states are modelled distinctly, because conflating them is what caused the original bug:

| Getter | Meaning |
|---|---|
| `hasLocalPhoto` | A path on the capturing device. Resolves to nothing anywhere else |
| `hasDatabasePhoto` | Bytes in Firestore. Current mechanism |
| `hasUploadedPhoto` | A Cloud Storage URL. **Legacy** — no longer written, still read for records created while it was in use |
| `hasRemotePhoto` | `hasDatabasePhoto \|\| hasUploadedPhoto` — the only forms a clinician can actually open |

Every clinician-facing check uses `hasRemotePhoto`. The queue's "Photograph" pill uses it too, so the queue cannot advertise an image the record is unable to display.

### 4.9 Result screen (IPO Table 7)

This screen is also the commit point: the engine runs once, then RISK_ASSESSMENT, SELF_EXAMINATION, LESION and the photograph are written. **Nothing is shared on save** — sharing is addressed to a named clinician and only happens when the patient picks one.

Displayed, in order: headline and score band · urgency banner when applicable · "What this means" · state-specific advice bullets · "Why you got this result" (engine reasons plus the findings reported) · provisional score card with the **flag scale** (§4.9.1), per-answer contributions and any unknown answers · follow-up plan and next-check date · **Next steps** card (§4.9.2) · photograph-failure notice if applicable · send-to-doctor card · fixed no-diagnosis and provisional-scores notices.

#### 4.9.1 Flag scale — green / yellow / red

Added at clinical review. The provisional score card shows all three bands as flags, not only the one reached, so the patient has a frame of reference for the number:

| Flag | Band | Score | Action shown |
|---|---|---|---|
| 🟢 Green | Lower risk | 0 to 4 | Keep up prevention and check again monthly. |
| 🟡 Yellow | Increased risk | 5 to 9 | Change habits and arrange a professional check. |
| 🔴 Red | Higher risk | 10 or more | See a dentist or doctor. |

The band reached is marked with a filled flag, a tinted row and a `YOU` marker; the others are outlined. **The shape difference, not just the colour, carries the "you are here" signal**, and every row states the band name and score range in text — colour alone is unreadable to a colour-blind patient and invisible to a screen reader.

Score ranges are derived from the cut-off constants (`RiskCategory.rangeLabel`), so moving a threshold cannot leave the displayed range contradicting the engine.

**The override is shown here too.** A persistent red flag or a previous OSCC produces a red flag on a score of 2, and a card that displayed only the green band would contradict the instruction the same screen is giving. When an override fired, a red-flag panel states that it outranks the score band and why. A test pins this case specifically: band green, output red.

#### 4.9.2 Next steps — referral and follow-up reminders

Added at clinical review, because both destinations already existed but were unreachable from the moment they are needed: the centres directory sat two taps into the Care & Rehab tab, and reminders behind a home-screen app-bar icon. Being told "arrange a professional oral examination" and then having to go hunting for the centre list is how a referral quietly fails.

The card sits on the result and on every past assessment, offering:

- **Find a screening centre** → the centres directory and referral-slip generator. Promoted to the primary action, and tinted with the flag colour, when the flag is red.
- **Set a follow-up reminder** → the reminders screen. The wording names the actual date — *"Be reminded two days before 29 Sep"* — rather than describing the feature, and falls back to the monthly self-check when there is no follow-up due.

### 4.10 Sharing (IPO §2, "With consent, send record to doctor")

Sharing is **addressed**, not broadcast. Two fields must both be set for a record to be visible: `shared_with_doctor == 1` and `shared_with_uid == <that clinician's uid>`. Switching sharing off clears the recipient, so access ends at the same instant. Changing the chosen doctor re-commits immediately, so the previous clinician loses access at the moment the new one gains it.

This was the subject of a bug worth recording: the Firestore rules permitted the read, but the client query did not filter on `shared_with_doctor`, and **Firestore rejects any query it cannot prove stays inside the permission** — rules are not filters. The record silently never appeared in the doctor's queue. Fixed with the explicit filter plus a composite index.

---

## 5. Risk and safety engine

`RiskEngine.evaluate()` — a pure function. Order of operations:

1. Derive `age_band` from the profile age and overwrite any stored value.
2. Determine `exposurePresent` — any of smoking / smokeless / areca / gutkha holding a value outside `{never, no}`.
3. Sum scores across the catalogue, in order, recording a per-variable breakdown. Skipped without scoring: conditional variables when no exposure; unanswered variables; **unknown answers (collected into `unknownAnswerKeys`)**; non-scored roles.
4. Band the total: **0–4 lower · 5–9 increased · ≥10 higher.**
5. Compute red-flag state: `neck_lump == yes` forces `persistent_neck_lump` into the flag set so it can never be dropped. `lesionPersistent` requires a red flag present **and** (duration band `≥2 weeks` **or** recorded lesion duration ≥14 days).
6. Apply the override chain — **first match wins**:

| Precedence | Condition | Output state | `professionalCheckRequired` |
|---|---|---|---|
| 1 | Red flag present **and** persistent ≥2 weeks | `PROFESSIONAL CHECK REQUIRED` | **true** |
| 2 | Previous OSCC = Yes | `PROFESSIONAL CHECK REQUIRED` | **true** |
| 3 | Red flag present, under 2 weeks | `Finding recorded — review if it persists` | false |
| 4 | No red flag | Band result | false |

7. Append supplementary reasons: previous OSCC when it co-occurs with branch 1, self-examination abnormality, unknown-answer list.
8. `referralAlert = professionalCheckRequired || category == higher || (redFlagPresent && selfExamAbnormality)`.

**Red flags take precedence over the numerical score**, as IPO §1 and §4 require. The band is still computed and stored even when overridden, because the validation database compares band against clinical outcome.

Note that a `higher` band alone does *not* produce `PROFESSIONAL CHECK REQUIRED` — it raises a referral alert in the clinician's queue and advises a professional examination. Only a persistent red flag or previous OSCC trips the override. This matches IPO Table 4.

### 5.1 Output states (IPO Table 7)

| State | Headline | Storage value |
|---|---|---|
| `lowerRisk` | Lower risk | `lower_risk` |
| `increasedRisk` | Increased risk | `increased_risk` |
| `higherRisk` | Higher risk | `higher_risk` |
| `observeAndReview` | Finding recorded — review if it persists | `observe_and_review` |
| `professionalCheckRequired` | PROFESSIONAL CHECK REQUIRED | `professional_check` |

CareConnect module D asks for four categories: "General prevention guidance / Arrange a routine dental examination / Seek professional evaluation soon / Seek urgent clinical attention". These map onto the five states above — lower risk carries prevention plus routine-examination advice, increased and higher risk carry "seek professional evaluation", and the override carries urgency. The five-state model is kept because the IPO document's `observeAndReview` case (red flag under two weeks) has no CareConnect equivalent and must not be collapsed into either neighbour.

### 5.2 Follow-up policy

| Output state | Follow-up | Status |
|---|---|---|
| `professionalCheckRequired` | +7 days | pending |
| `observeAndReview` | lesion first noticed +14 days (or +1 day if already past) | pending |
| `higherRisk` | +14 days | pending |
| `increasedRisk` | +30 days | pending |
| `lowerRisk` | none | not required |

The `observeAndReview` interval is anchored to when the patient first noticed the lesion, not to today, so the two-week question is answered about the lesion's actual age.

---

## 6. Clinician module

Maps to IPO §3 and the whole of the Clinician document. Scope is deliberately limited to review, documentation, referral and follow-up — the Clinician document's opening line, and the reason there is no automatic staging or diagnosis anywhere.

### 6.1 Patient queue (screen 22)

Records appear **only** after a patient addresses them to this clinician. Live consent is re-checked per case on load, so a withdrawn consent removes the record even if the flag on the assessment still says shared.

Queue priority — lower sorts first, then newest first within a bucket:

| Priority | Bucket |
|---|---|
| 0 | Referral window lapsed with no arrival **and** no reminder sent yet |
| 1 | Red-flag / professional-check override |
| 2 | Referral alert |
| 3 | Everything else |

Bucket 0 outranks the clinical urgency badges on purpose: a referred patient who never arrived and whom nobody has chased is the one most likely to be lost to follow-up, and it is the only state that requires a human to act rather than to read.

Three filters: `Referral alerts only` · `Not yet reviewed` · `Did not attend`. Three counters: referral alerts, awaiting review, did not attend.

### 6.2 Record review (screen 23) — IPO Table 8 left column

Read-only. Sections: app output banner · patient demographics and photo-consent state · how the app reached this output (engine reasons) · risk factors with per-answer score contributions and unknown answers · red flags reported with persistence state · patient self-examination findings · lesion records with photograph · documents the patient shared from DigiLocker · clinical assessment summary · outcome summary.

Every answer is annotated so the clinician can see how it was treated: `(+4)` for a contribution, `(recorded, not scored)` for an unweighted variable, `(unknown)` for a "Don't know". A clinician reading a score needs to know what is inside it.

### 6.3 Clinical assessment entry (screen 24)

Maps to IPO Table 8 right column and Clinician §1–§8. Tri-state controls throughout: **Yes / No / Not recorded**. Every stored boolean is nullable because "not yet decided" is a real clinical state and must not be stored as "No".

| # | Field | Type | Source clause |
|---|---|---|---|
| 1 | Medical history | text | Clinician §1 |
| 2 | Clinical examination performed | Yes/No/NR | IPO T8 |
| 3 | Lesion present | Yes/No/NR | IPO T8 |
| 4 | Lesion description | text | Clinician §3 |
| 5 | Greatest dimension (mm) | decimal | Clinician §3 |
| 6 | Impression | text | Clinician §3 |
| 7 | Further investigation required | Yes/No/NR | Clinician §3 |
| 8 | Biopsy required | Yes/No/NR | IPO T8 |
| 9 | Referral required | Yes/No/NR | Clinician §4 |
| 10 | Referral centre | text | Clinician §4 · **required when referral = Yes** |
| 11 | Referral date | date | Clinician §4 |
| 12 | Patient informed by text to attend a centre | Yes/No/NR | Clinician §3 (the capitalised line) |
| 13 | Date informed | date | Clinician §3 |
| 14 | Patient arrived (date) | date | Clinician §5 |
| 15 | Patient reminded by text | Yes/No/NR | Clinician §5 |
| 16 | Date reminded | date | Clinician §5 |
| 17 | Referral and follow-up instructions | text | Clinician §8 — **shown to the patient** |
| 18 | Follow-up date | date | Clinician §7 |
| 19 | Follow-up status | text | Clinician §7 |

Only two save-time validations: lesion size must parse as a number, and a referral centre is required when a referral is required. Everything else is optional, because a clinician may record an examination before investigations are decided.

### 6.4 The two-week attendance rule (Clinician §5)

*"Patient failed to arrive within two weeks"* is **derived, never typed**:

```
failedToArriveWithinTwoWeeks =
    referralRequired == true
    && referralDate != null
    && patientArrivedDate == null
    && now >= referralDate + 14 days
```

Derived rather than stored so it cannot go stale — a flag written on day 14 would still read "failed to arrive" after the patient turned up on day 20. `needsAttendanceReminder` adds `patientRemindedByText != true`, and that is what drives queue bucket 0.

The entry form shows the same conclusion live while the clinician types, so the screen and the stored record cannot disagree.

### 6.5 Outcome entry (screen 25) — IPO §3.2, Table 9

| Field | Type |
|---|---|
| Professional examination performed | Yes/No/NR |
| Clinical abnormality found | Yes/No/NR |
| Biopsy performed | Yes/No/NR |
| Histopathology result | text |
| Investigation and imaging reports | text |
| Final diagnosis | text |
| OPMD established | Yes/No/NR |
| OSCC established | Yes/No/NR |
| Referral completed | Yes/No/NR |
| Follow-up completed | Yes/No/NR |

Professional-examination and clinical-abnormality prefill from the clinical assessment rather than asking twice.

Histopathology and final diagnosis are **free text, not enumerations**. This is deliberate: the app must not constrain a pathologist's wording, and IPO §7 requires that it "should not diagnose or stage OSCC automatically".

A live agreement preview classifies the case as the clinician types, and names the dangerous one explicitly: *"FALSE NEGATIVE: the app did not flag this patient but disease was established. This is the case type that matters most for safety."*

### 6.6 What the patient is not shown

`AssessmentDetailScreen` shows the patient their referral, centre, dates, attendance and their clinician's instructions. It deliberately **withholds** histopathology, clinical findings and final diagnosis, with the line *"Clinical findings and any test results are discussed with you by your clinician, not shown in the app."*

Communicating a cancer or dysplasia diagnosis is a conversation a clinician must have, not a field an app reveals.

---

## 7. Outcome / validation database

IPO §4 and Table 10. Read-only screen, computed from shared cases.

A case is **flagged** when `professionalCheckRequired || referralAlert`. It is **disease-positive** when OPMD or OSCC is established. A case with only a free-text final diagnosis counts as "outcome recorded" but is **excluded from every metric**, because the binary reference standard is the established disease status, not prose.

| Metric | Formula |
|---|---|
| Sensitivity | TP / (TP + FN) |
| Specificity | TN / (TN + FP) |
| Positive predictive value | TP / (TP + FP) |
| Negative predictive value | TN / (TN + FN) |
| Positive rate per band | disease-positive / with-outcome |

All return `—` rather than 0 when the denominator is zero. A rate of "0.0%" from an empty denominator would be a lie.

Also shown: data-capture counts, the 2×2 matrix, outcome by risk band (with the explicit note that a usable stratification should show the positive rate rising from lower to higher), and **a list of every false negative with a link straight into the record**.

Scope depends on role. A clinician sees only their own patients and is told so in those words: *"They are not the whole cohort, so do not read them as the pilot's performance."* A coordinator sees the whole cohort. The maths is identical; only the input list differs.

A fixed caution sits above everything: *"These are raw counts from pilot data. They have no confidence intervals, no adjustment for verification bias, and no correction for repeated assessments on the same patient. Use them to monitor the pilot, not as validation evidence."*

---

## 8. CareConnect support modules

Six modules covering CareConnect §2, §3 and modules E–J.

### 8.1 Education (screen 15) — CareConnect §2

Trilingual: **English, Hindi, Kannada**. 8 categories, 7 topics, 5 myths, 5 FAQs. Free-text search across titles and summaries; category filter chips.

| # | Topic | Category | Content |
|---|---|---|---|
| 1 | What is Oral Cancer? | Overview | Understanding the disease; importance of early detection. Caution: early oral cancer is frequently completely painless |
| 2 | Major Risk Factors | Risk Factors | 6 items: smokeless tobacco, areca nut/OSMF, bidi & cigarette, alcohol synergy (up to 15×), HPV-16, sharp broken teeth/dentures |
| 3 | Early Signs & Symptoms | Early Signs | The 14-day rule, 7 signs, caution against OTC gels and steroid ointments |
| 4 | Cessation & Habit Change | Prevention | Oral recovery timeline, the 4-D strategy, Quitline `1800-11-2356`, mCessation `011-22901701` |
| 5 | Oral Hygiene & Nutrition | Prevention | 4 protective dietary factors |
| 6 | Biopsy, Staging & Treatment | Biopsy & Care | What a biopsy is; explicitly rebuts the "biopsy spreads cancer" myth |
| 7 | Caregiver & Family Guidance | Caregivers | Supporting without blaming |

Myths covered: age/smoking-only misconception · biopsy spreads cancer · painless means benign · plain supari is safe · oral cancer is contagious.

FAQs: self-examination frequency · normal vs cancerous ulcer · can leukoplakia resolve · what to do on "Professional Check Required" · does the app diagnose (answer: *"No. The app strictly supports awareness, self-examination, and structured referral."*).

Static content, no persistence.

### 8.2 Clinical reference photo gallery (screen 14) — CareConnect §3 ("pics of red, white lesion")

Six pinch-to-zoom reference photographs with key signs and clinical significance, reachable from four places including a per-site button on the self-examination screen:

| Asset | Condition |
|---|---|
| A | Homogeneous Leukoplakia (White Patch) |
| B | Erythroleukoplakia (Mixed Red & White Patch) |
| C | Verrucous Leukoplakia (Thickened White Lesion) |
| D | Chronic Non-Healing Oral Ulcer |
| E | Exophytic Lump / Oral Carcinoma |
| F | Oral Submucous Fibrosis (OSMF) |

Header states: *"photographs cannot diagnose cancer. Only a clinician and biopsy can provide an accurate diagnosis."*

### 8.3 DigiLocker (screen 16) — CareConnect module G

**All 13 document categories from module G:**

| # | Category | # | Category |
|---|---|---|---|
| 1 | Consultation Record | 8 | Prescription |
| 2 | Clinical Photograph | 9 | Surgery / Radiotherapy |
| 3 | Biopsy & Histopathology | 10 | Chemotherapy Record |
| 4 | Blood Investigation | 11 | Discharge Summary |
| 5 | Imaging (CT/MRI/OPG) | 12 | Follow-up Note |
| 6 | Diagnosis & Staging | 13 | Bills & Insurance |
| 7 | Treatment Plan | | |

Per record: category (required), title (required), doctor/hospital, date of report (no future dates), notes, optional attachment, and a **per-document sharing switch**.

Module G's *"Users should control which records are shared and with whom"* is implemented literally: each document carries its own `is_shared` flag, and the clinician's record screen reads only shared documents. The query filter is mandatory, not an optimisation — the rules permit a clinician to read only shared documents, and Firestore rejects a query it cannot prove stays inside that permission.

**Attached pictures are stored server-side.** The image is held as bytes at `users/{uid}/digilocker_files/{recordId}` — the same mechanism as lesion photographs (§4.8), sharing one implementation and one size limit via `ImageDocumentStore`.

This was a defect until clinical review. The locker previously kept only `local_file_path`, a path on the capturing device, which meant a filed biopsy report or clinical photograph disappeared on any other device, was lost with the phone — precisely what a records locker exists to prevent — and showed the reviewing clinician nothing even when the patient had marked it shared.

Design notes:

- The bytes live in a sibling document, not on the record, so listing the locker does not download every image.
- The file document id **is** the record id. That makes the pairing unambiguous and lets the rules locate the parent record.
- The file document deliberately carries **no sharing flag of its own**. The patient makes one `is_shared` decision, on the record, and the rules read that record to authorise the image — so the two cannot drift apart.
- Capture is downscaled to 1400 px at quality 60 and refused above ~900 KiB, with the reason given.
- The image is written **before** the record, so `has_image` on the record is a statement of fact rather than a hope. If the image fails, the record still saves and the patient is told it will not be visible on another device.
- Records filed before this existed show an explanatory note rather than an empty space, so nobody assumes an old picture is safe in the locker.

**Still not built:** multi-page PDF reports. The 1 MiB per-document ceiling makes them impractical without Cloud Storage.

### 8.4 Cessation (screen 17) — CareConnect module H

| Module H requirement | Implementation |
|---|---|
| Tobacco and areca-nut cessation resources | Quitline `1800-11-2356` (8 AM–8 PM), mCessation missed-call `011-22901701`, plus education topic 4 |
| Quit-date setting | Date picker, up to 30 days ahead |
| Habit tracking | Live streak in days and hours; money saved (₹); units avoided |
| Daily motivational messages | **Built, limited** — static motivational copy and milestone feedback. No scheduled daily message engine |
| Identification of triggers | 7-option trigger dropdown with 1–5 intensity slider, logged per craving |
| Referral to cessation services | Quitline and mCessation cards |
| Progress monitoring | 6 recovery milestones, achieved state computed from elapsed time |
| Relapse-support information | Fixed card: *"A slip is not a failure; it is data on what trigger was challenging."* |

Quit plan fields: quit date · habit types (Smokeless Tobacco/Gutkha, Bidi/Cigarette, Areca Nut/Paan/Supari, Alcohol) · units per day · cost per unit · craving log.

Craving triggers: Work/Stress · Social gathering/Friends · After eating a meal · Boredom/Free time · With Chai/Coffee · Anxiety/Restlessness · Other.

Recovery milestones: 20 minutes (heart rate) · 24 hours (carbon monoxide) · 48 hours (taste and smell) · 2 weeks (oral mucosa regeneration) · 1 month (gums and teeth) · 1 year (oral cancer risk drops by 50%).

Craving assistance uses the 4-D strategy: Delay · Deep breath · Drink water · Distract.

Stored at `users/{uid}/cessation/plan`. Not visible to clinicians.

### 8.5 Appointments and referral (screen 19) — CareConnect module F

Four centre types: Dental Institute / College · Comprehensive Cancer Centre · Oral Medicine & OMFS Dept · Community Health Centre.

Five seed centres, each with name, type, city, state, full address, phone, timings and a service list:

| Centre | Type | City |
|---|---|---|
| Coorg Institute of Dental Sciences (CIDS) | Dental institute | Coorg (Virajpet) |
| Kidwai Memorial Institute of Oncology | Oncology centre | Bengaluru |
| Tata Memorial Centre (TMC) | Oncology centre | Mumbai |
| Government Dental College & Research Institute (GDCRI) | Dental institute | Bengaluru |
| Dr. B.R. Ambedkar IRCH (AIIMS) | Oncology centre | New Delhi |

Centres are served from Firestore `screening_centers` and seeded with `tools/seed_centers.mjs`; the bundled list is only a fallback. Clinic phone numbers and timings change, and a hardcoded list cannot be corrected without shipping a release. The banner wording changes to match the source: the bundled fallback says *"These details are the copy built into the app and may be out of date."*

**Appointment requests — Built, limited, and the limit is stated everywhere it could mislead.** The app has no booking integration with any centre. A request is the patient's own record of an intention to attend. It starts as `Saved — centre not yet contacted`, and the patient advances it to `Confirmed with the centre` then `Attended` once they have actually phoned.

Wording used, verbatim:
- *"This saves a reminder for you. The app cannot book for you — you still need to phone the centre."*
- *"Saved to your record for 21 Sep. Now call +91 8274 256479 to confirm — the centre has not been contacted automatically."*
- *"Saved by you. The app does not contact centres for you."*

A save failure is surfaced, not swallowed, so the patient is never shown a false confirmation and left waiting for a call that never comes.

**Referral letters** (module F) are generated as a plain-text clinical referral slip containing demographics, provisional risk band, urgency status, red-flag trigger, lesion and symptoms, four recommended clinical actions, and a safety disclaimer: *"It does NOT constitute a confirmed diagnosis or staging of Oral Squamous Cell Carcinoma."* Copyable to clipboard to hand to a clinician.

**Not built:** teleconsultation (module F, "where legally and technically appropriate") — requires a regulatory decision, not a code change. `Call` buttons display the number for manual dialling rather than launching the dialer.

### 8.6 Post-treatment rehabilitation (screen 20) — CareConnect §9 target users, treatment support

Three treatment modalities, selected by the patient:

| Modality | Hydration interval | Exercises | Focus |
|---|---|---|---|
| Surgery Only | 3 h | 3 | Jaw opening physiotherapy, tongue speech drills, scar mobility, neck/shoulder after node dissection |
| Surgery + Radiotherapy | 2 h | 2 | Xerostomia, saliva substitutes, radiation-caries prevention, swallow reflex |
| Surgery + Chemo + Radiotherapy | 2 h | 2 | Neutropenia infection barrier, oral mucositis, nutrition, psychological support |

7 exercises total, each with target area, instruction, frequency and clinical rationale. 9 clinical priorities and 13 special instructions across the three protocols, including a febrile-neutropenia escalation (*"Any fever above 100.4°F (38°C) is a medical emergency"*), the dry-mouth protocol with sodium-bicarbonate rinse recipe and 1.1% neutral sodium fluoride gel, and explicit psychological-support guidance.

A live hydration prompt turns due based on the modality's interval.

**Built, limited:** nothing on this screen is persisted. Modality choice, hydration time and completed exercises are session-only, and the hydration prompt is an in-screen colour change, not a scheduled notification.

### 8.7 Emergency guidance (screen 21) — CareConnect module J

All five module J situations covered, plus one:

| # | Condition | Module J clause |
|---|---|---|
| 1 | Severe / Uncontrolled Oral Bleeding | Severe bleeding |
| 2 | Difficulty Breathing or Noisy Breathing (Stridor) | Difficulty breathing |
| 3 | Rapidly Increasing Swelling in Neck or Face | Rapidly increasing swelling |
| 4 | Inability to Swallow Saliva or Fluids | Difficulty swallowing |
| 5 | High Fever (>100.4°F / 38°C) During Chemotherapy | High fever during cancer treatment |
| 6 | Severe Post-Operative Complications | Severe post-operative complications |

Each carries an immediate first step and an explicit escalation threshold — e.g. bleeding persisting past 20 minutes of firm pressure, inability to swallow for more than 6 hours, any dark or blue flap discolouration.

Helplines: `112` (National Emergency) and `108` (National Ambulance).

**Built, limited:** the buttons display the number in a dialog rather than launching the dialer. Labelled "Call 112", which implies dialling — worth changing to "Show emergency number" or wiring `url_launcher`.

Reachable in one tap from the top of the Check Hub.

---

## 9. Notifications and reminders — CareConnect module I

All eight module I reminder types exist as scheduling kinds:

| Kind | Notification title | Module I clause |
|---|---|---|
| `selfExamination` | Time for your mouth self-check | Monthly self-examination |
| `dentalCheckUp` | Dental check-up due | Dental check-ups |
| `followUpVisit` | Follow-up visit due | Follow-up visits |
| `biopsyAppointment` | Biopsy appointment | Biopsy appointments |
| `medication` | Medication reminder | Medication schedules |
| `investigation` | Investigation due | Investigation dates |
| `treatmentSession` | Treatment session | Treatment sessions |
| `cessationMilestone` | Quit-plan milestone | Tobacco-cessation milestones |

Schedule: monthly self-check at **09:00** on the same day next month; date-anchored reminders fire at 09:00, **2 days before** the due date. Channel `oralcare_reminders`, timezone `Asia/Kolkata`, inexact scheduling (no exact-alarm permission is requested, so no special permission is needed).

Module I requires *"Notifications must be optional"*: nothing is scheduled until the patient taps **Set reminders**, and **Turn all reminders off** clears everything. Privacy: *"Reminders stay on this device. Nothing is sent to anyone else."*

**Built, limited — Android only.** The browser cannot schedule them, and the screen says so rather than pretending: *"This browser cannot show scheduled reminders. Install the Android app to receive them. Your due dates are still listed below."* When permission is declined it says that too. A reminders screen that silently fails is worse than one that admits it.

---

## 10. Language — CareConnect §2 and §11, Questionnaire

Two layers, on purpose.

**Clinical questions: English and Kannada.** Every Kannada term is taken verbatim from the Sree questionnaire — gender options, yes/no/don't-know, habits, sites, all 8 examination sites and all 13 red flags. In Kannada mode the English term stays visible underneath, because that is the term a clinician will ask about.

**Education module: English, Hindi and Kannada.**

**Hindi is deliberately not offered for clinical questions.** The source documents contain no verified Hindi for them. Machine-translating a clinical red-flag term into a language no clinician on the project has reviewed is a patient-safety risk, not a feature. Tests enforce that every red flag and every examination site has a Kannada term and that no term is left as a placeholder.

Language choice is session-scoped and never written to the profile, so a guest can use Kannada without an account.

**Built, limited:** the surrounding interface chrome (buttons, headings, navigation) is still English. Full UI localisation needs `flutter_localizations` and a reviewed translation of every string.

---

## 11. Data model — IPO §6, Table 11

IPO §6 specifies six tables with `Patient_ID` as the primary linking key. All six exist.

| IPO table | Firestore location |
|---|---|
| USER | `users/{uid}` |
| RISK_ASSESSMENT | `assessments/{assessmentId}` |
| SELF_EXAMINATION | field `self_exam` **inside** the assessment document |
| LESION | `assessments/{assessmentId}/lesions/{lesionId}` |
| CLINICIAN_ASSESSMENT | `assessments/{assessmentId}/clinical/current` |
| OUTCOME | `assessments/{assessmentId}/outcome/current` |

Self-examination is stored inline rather than as a subcollection because it is strictly one-per-assessment; a subcollection would add a read for no benefit.

### 11.1 Full path list

| Path | Contents |
|---|---|
| `users/{uid}` | Profile, role, consent flags |
| `users/{uid}/digilocker_records/{id}` | Patient documents, with `is_shared` and `has_image` |
| `users/{uid}/digilocker_files/{id}` | Attached picture bytes. Id matches the record id |
| `users/{uid}/cessation/plan` | Quit plan and craving log |
| `users/{uid}/appointments/{id}` | Patient-authored visit intentions |
| `patient_ids/{patientId}` | Uniqueness reservation. Doc id *is* the Patient ID |
| `doctors/{uid}` | Public clinician directory. No patient data, no private contact details |
| `screening_centers/{id}` | Centre directory, Admin-SDK seeded |
| `assessments/{id}` | Risk assessment + inline self-examination + sharing + follow-up |
| `assessments/{id}/lesions/{id}` | Lesion records |
| `assessments/{id}/lesion_photos/{id}` | Photograph bytes (Blob), content type, byte count |
| `assessments/{id}/clinical/current` | Clinician assessment |
| `assessments/{id}/outcome/current` | Outcome / reference standard |

The clinician directory is a separate collection from `users` on purpose: patients must be able to list clinicians without being able to read any profile document.

### 11.2 RISK_ASSESSMENT fields — IPO Table 11 *"Risk factors, individual values, total score, category"*

`patient_id` · `owner_uid` · `created_at` · `answers_json` (every individual value) · `risk_score` · `risk_category` · `red_flag` · `red_flags_json` · `lesion_persistent` · `previous_oscc` · `professional_check` · `referral_alert` · `output_state` · `unknown_keys_json` · `breakdown_json` (per-variable contribution) · `reasons_json` · `shared_with_doctor` · `shared_with_uid` · `follow_up_due` · `follow_up_status`

The full engine output is persisted, not recomputed on read. A historical record must always show the score and category that were actually produced at the time — re-running a changed algorithm over old data would corrupt the validation set.

`breakdown_json` and `unknown_keys_json` exist so an auditor can reconstruct exactly how a total was reached.

---

## 12. Security — CareConnect §11

| CareConnect §11 requirement | Status |
|---|---|
| Encrypted data transmission and storage | **Built** — Firebase TLS in transit, encryption at rest |
| Secure login | **Built** — Firebase Authentication; passwords never reach Firestore |
| Optional multi-factor authentication | **Not built** — needs a Firebase Auth MFA configuration decision |
| Role-based access control | **Built, limited** — see §2.1 |
| Consent-based record sharing | **Built** — enforced in rules, not just in UI |
| Audit logs for access and modifications | **Not built** — needs Cloud Functions (paid plan) or a rules-level logging sink |
| Regular data backup | **Not built** — Firestore scheduled export requires the paid plan |
| Data recovery after device loss | **Built** — records are server-side; sign in on a new device restores them. Exception: device-local photographs and DigiLocker attachments |
| Secure logout from shared devices | **Built** |
| Minimal PII collection | **Built** — the clinician's queue shows Patient ID, age and gender only; never a name |
| Clear privacy and retention policy | **Not built** — a document, not code |
| Multilingual and accessibility-friendly | **Built, limited** — see §10 |

### 12.1 Firestore rules summary

| Path | Read | Write |
|---|---|---|
| `users/{uid}` | Self, or any doctor | Self only. Delete denied |
| `users/{uid}/digilocker_records/{id}` | Self, or doctor when `is_shared == 1` | Self only |
| `users/{uid}/digilocker_files/{id}` | Self, or doctor when the **parent record** has `is_shared == 1` | Self only |
| `users/{uid}/cessation`, `.../appointments` | Self only | Self only |
| `doctors/{uid}` | Any signed-in user | That clinician only. Delete denied |
| `screening_centers/{id}` | Any signed-in user | Denied — Admin SDK only |
| `patient_ids/{id}` | `get` only; `list` denied | Create only, and only with own uid. Update and delete denied |
| `assessments/{id}` | Owner, or the addressed doctor, or a coordinator when shared | Owner only, and `owner_uid` must equal the caller |
| `.../lesions/{id}` | Same as parent | Parent owner only |
| `.../lesion_photos/{id}` | Same as parent | Parent owner only |
| `.../clinical/{id}` | Parent owner, addressed doctor, or coordinator | **Addressed doctor only** — a coordinator can read, never write |
| `.../outcome/{id}` | Parent owner or addressed doctor | Addressed doctor only |
| everything else | Denied | Denied |

Subcollection rules were the source of a real data-loss bug: **Firestore rules do not cascade.** A `users/{uid}` rule does not cover `users/{uid}/digilocker_records`, so those writes were being silently rejected while the UI reported success. Every subcollection now has an explicit block.

Note an asymmetry left in place: `clinical` grants a coordinator read access, `outcome` does not. Since the outcome document is the validation reference standard, this looks like an omission worth reviewing — a coordinator computing cohort statistics reads outcomes through the same query.

---

## 13. Clinical and ethical safeguards — CareConnect §12

| Safeguard | Implementation |
|---|---|
| Clear disclaimer that the app does not diagnose | `ClinicalNotices.noDiagnosis`, shown on role selection, consent, every result and every history detail |
| No treatment recommendations without clinical evaluation | Advice is confined to prevention, cessation and "see a professional". No drug, dose or procedure is ever suggested |
| No interpretation of photographs as diagnosis | The gallery states photographs cannot diagnose; the clinician's view labels every image *"Patient-captured image. Lighting, focus and angle are uncontrolled, so it does not replace direct examination."* |
| Referral for suspicious findings | The override chain in §5, the referral alert in the queue, and the centres directory |
| Informed consent for collection and sharing | Three-gate consent screen, re-editable, enforced in the router and the rules |
| Special safeguards for minors and vulnerable users | **Not built.** Age is captured (0–120) but there is no minor-specific pathway, guardian consent, or restriction. Needs a clinical and legal decision before it can be coded |
| Ethical approval for research data | Process, not code |
| De-identification for research | **Built, limited** — the clinician's queue is already name-free. There is no export pipeline, so no de-identification step exists to build yet |
| Transparent explanation of any AI feature | **There is no AI or ML anywhere in this app.** The risk engine is a transparent additive score with a published weight table and a per-answer breakdown shown to both patient and clinician |
| Human clinical oversight of automated alerts | Every alert routes to a clinician who must record their own examination. `doctorResponsibility` notice: *"App output is decision support only."* |
| Mechanism for reporting inaccurate information | **Not built.** No in-app feedback channel exists |

Two further safeguards not requested but present:

- **`provisionalScores`** on every result and history screen: *"Scores and thresholds in this build are provisional for pilot development and have not yet been clinically validated."* IPO Table 3 marks the cut-offs provisional; the app repeats it to the patient rather than only in a document.
- **`validationCaveat`** above the validation statistics, stating they are not validation evidence.

### 13.1 Consent wording accuracy — corrected

Three strings on or above the consent form had gone stale when records moved from device-local storage into Firestore. All three are now corrected, and a test file (`test/consent_wording_test.dart`, 12 tests) pins the claims so they cannot drift back.

| String | Was | Now |
|---|---|---|
| `storageNotice` | *"Records are stored on this device only. Nothing is uploaded."* — false since the Firestore migration | States records are saved to the patient's account, encrypted in transit and at rest, readable only by them unless shared. **Also discloses what the pilot lacks**: no audit trail of who opened a record, no automatic backup |
| `consentPhotoDetail` | *"Photographs stay on this device unless I also agree to share my record with a doctor"* — false; the photograph is written to Firestore as soon as photograph consent is given, independent of share consent | States the photograph is saved to the patient's own account so it is available on any device they sign in to, and that no doctor can open it unless they also share that record |
| `consentShareDetail` | *"a doctor using this app may see my record"* — implies any clinician; sharing is addressed to one | States that only the chosen doctor can open it, that it can be withdrawn at any time, and **discloses the pilot coordinator**, who can read shared records cohort-wide for validation |

The coordinator disclosure was an omission, not a drift: the role was added after the consent text was written, and a patient cannot consent to a disclosure they were never told about.

A related screen string was corrected with them: the lesion screen's photograph section said *"Stays on this device unless you share your record with a doctor."*

**Design decision recorded.** There were two ways to resolve the photograph contradiction: change the text to match the behaviour, or gate the upload on share consent so the original promise became true. The text was changed. Holding the photograph in the patient's own account is a benefit to them — it survives device loss and appears in their history on any device they sign in to — and the Firestore rules already restrict it to the owner plus any clinician they addressed the record to. So "saved to your account, no doctor can see it unless you share" is both accurate and the more useful behaviour. Gating the upload would have traded a real patient benefit for wording convenience.

---

## 14. Traceability matrices

### 14.1 IPO document — `Oral_Cancer_Mobile_App_Patient_Doctor_Login.docx`

| Clause | Requirement | Status | Where |
|---|---|---|---|
| §1 | Four-layer architecture | **Built** | §1 |
| §2 | Patient flow order | **Built** | §4.1 |
| §2.1 T1 | Patient ID / permitted identifier | **Built** | §4.2 |
| §2.1 T1 | Age as demographic + risk variable | **Built**, required | §4.2, §4.4 |
| §2.1 T1 | Sex, where used | **Built** as *Gender*, required | §4.2 |
| §2.1 T1 | Consent for app/self-exam — proceed only when Yes | **Built**, router-enforced | §3.2, §4.3 |
| §2.1 T1 | Consent for photograph | **Built** | §4.3, §4.8 |
| §2.1 T1 | Consent to share with doctor | **Built** | §4.3, §4.10 |
| §2.2 T2 | All 13 risk variables with provisional scores | **Built** | §4.4 |
| §2.2 T2 | Gutkha: capture exposure, weight to be validated | **Built** as unweighted, labelled | §4.4 |
| §2.2 T2 | Previous OPMD "Don't know" retained as unknown | **Built**, never scored as zero | §4.4 |
| §2.2 T3 | Bands 0–4 / 5–9 / ≥10 | **Built** | §5 |
| §2.2 | "Scores and cut-offs are provisional" | **Built**, surfaced to the patient | §13 |
| §2.3 | 10 red-flag questions | **Built**, extended to 13 | §4.5 |
| §2.3 T4 | No red flag → numerical category | **Built**, branch 4 | §5 |
| §2.3 T4 | Red flag <2 weeks → record, advise observation | **Built**, branch 3 | §5 |
| §2.3 T4 | Red flag ≥2 weeks → PROFESSIONAL CHECK REQUIRED | **Built**, branch 1 | §5 |
| §2.3 T4 | Previous OSCC → follow-up irrespective of score | **Built**, branch 2 | §5 |
| §2.4 T5 | 7 self-examination sites, examined + abnormality | **Built**, extended to 8 | §4.6 |
| §2.4 | Abnormality opens lesion module | **Built** | §4.1 |
| §2.5 T6 | All 12 lesion fields | **Built** | §4.7 |
| §2.5 T6 | Photograph, optional upload with consent | **Built** | §4.8 |
| §2.6 T7 | All four output states with guidance | **Built** as 5 states | §5.1 |
| §3 | Doctor flow order | **Built** | §6 |
| §3.1 T8 | Everything the doctor sees | **Built** | §6.2 |
| §3.1 T8 | Everything the doctor enters | **Built**, 19 fields | §6.3 |
| §3.2 T9 | All 13 outcome backend fields | **Built** | §6.5, §11.2 |
| §4 | Combined decision logic, red flag over score | **Built**, precedence chain | §5 |
| §5 | Input → process → output map | **Built** | §1 |
| §6 T11 | Six tables, Patient_ID linking key | **Built** | §11 |
| §7 | Two separated authenticated interfaces | **Built** | §2, §3.2 |
| §7 | Must not diagnose or stage automatically | **Built** — free-text diagnosis, no AI | §6.5, §13 |

**IPO coverage: complete.**

### 14.2 Clinician document — `Copy 3.docx`

| Clause | Requirement | Status | Where |
|---|---|---|---|
| Scope | Limited to review, documentation, referral, follow-up | **Built** | §6 |
| §1 | Patient ID, age, sex | **Built** | §6.2 |
| §1 | Relevant medical history | **Built** — clinician-entered field 1, plus the patient's own from their profile | §6.3 |
| §1 | Tobacco/areca/alcohol history | **Built** — risk factors with score contributions | §6.2 |
| §1 | Previous oral lesion or OSCC history | **Built** | §6.2 |
| §2 | Reported symptoms and duration | **Built** | §6.2 |
| §2 | Lesion site | **Built** | §6.2 |
| §2 | Self-examination findings | **Built** | §6.2 |
| §2 | Patient-uploaded photograph | **Built** | §4.8, §6.2 |
| §2 | Preliminary risk-assessment result | **Built**, with engine reasoning | §6.2 |
| §3 | Lesion description and size | **Built**, fields 4–5 | §6.3 |
| §3 | Clinical findings | **Built** | §6.3 |
| §3 | Provisional clinical impression | **Built**, free text | §6.3 |
| §3 | Further investigation required Yes/No | **Built**, tri-state | §6.3 |
| §3 | PATIENT INFORMED BY TEXT REPLY TO ATTEND A CENTRE | **Built, limited** — recorded with date. The app sends no SMS; it records that the clinician did | §6.3 |
| §4 | Referral required Yes/No | **Built** | §6.3 |
| §4 | Referral centre/clinician | **Built**, required when referral = Yes | §6.3 |
| §4 | Referral date | **Built** | §6.3 |
| §5 | Patient arrived (date) | **Built** | §6.3 |
| §5 | Patient failed to arrive within two weeks | **Built**, derived not typed; drives queue priority 0 | §6.4 |
| §5 | Patient reminded by text | **Built**, with date | §6.3 |
| §6 | Biopsy/histopathology report | **Built** | §6.5 |
| §6 | Relevant investigation/imaging reports | **Built** | §6.5 |
| §6 | Final diagnosis, where available | **Built** | §6.5 |
| §7 | Follow-up date | **Built** | §6.3 |
| §7 | Follow-up status | **Built**, free text | §6.3 |
| §8 | Share selected patient information with authorised clinicians | **Built** — addressed sharing, per-document DigiLocker sharing | §4.10, §8.3 |
| §8 | Send referral/follow-up instructions to the patient | **Built** — field 17, surfaced in the patient's own record | §6.3, §6.6 |

**Clinician coverage: complete.** One constraint: the app records that the patient was informed or reminded by text; it does not send the SMS. No messaging gateway is integrated.

### 14.3 CareConnect — `Final cHeck.docx`

| Clause | Requirement | Status | Where |
|---|---|---|---|
| §1 | Name, age, gender | **Built**, all required | §4.2 |
| §1 | Contact details | **Built** — mobile, email | §4.2 |
| §1 | Location | **Built** — city, PIN | §4.2 |
| §1 | Relevant medical history | **Built** | §4.2 |
| §1 | Tobacco, alcohol, areca-nut use | **Built** — risk questionnaire | §4.4 |
| §1 | Previous oral lesions / cancer history | **Built** | §4.4 |
| §1 | Allergies and current medications | **Built** — profile screen | §3 #6 |
| §1 | Emergency contact information | **Built** | §4.2 |
| §1 | Guest-information mode | **Built** | §2 |
| §2 | All 13 education content areas | **Built** — 7 topics, 5 myths, 5 FAQs | §8.1 |
| §2 | English and regional Indian languages | **Built** — EN/HI/KN education, EN/KN clinical | §10 |
| §3 | 7 self-examination sites incl. back of throat | **Built** — 8 sites | §4.6 |
| §3 | Illustrations, instructions, reminders | **Built, limited** — 7 of 8 illustrations exist | §4.6, §15 |
| §3 | "pics of red, white lesion" | **Built** — 6-photo clinical gallery | §8.2 |
| §3 | All 10 symptom questions | **Built** — 13 red flags | §4.5 |
| §3 | Must state it is not a substitute for clinical examination | **Built** | §13 |
| §D | Risk questionnaire: 10 factor groups | **Built** | §4.4 |
| §D | Family history | **Recorded only** — no agreed weight | §4.4 |
| §D | Immunosuppression | **Recorded only** — no agreed weight | §4.4 |
| §D | Four output categories | **Built** as 5 states | §5.1 |
| §E | Lesion documentation, all 7 fields | **Built** | §4.7 |
| §E | Clinical photographs where possible | **Built, limited** — ≤900 KiB | §4.8 |
| §E | Consultation details, follow-up dates | **Built** — clinician review shown in the patient's record | §6.6 |
| §F | Dental institutes / specialist search | **Built** — 5 centres, 4 types, searchable | §8.5 |
| §F | Location-based screening-centre information | **Built, limited** — city filter, not GPS-based | §8.5 |
| §F | Appointment requests | **Built, limited** — patient-authored, no booking integration | §8.5 |
| §F | Referral letters | **Built** — generated clinical slip | §8.5 |
| §F | Follow-up reminders | **Built** | §9 |
| §F | Emergency contact information | **Built** | §8.7 |
| §F | Teleconsultation support | **Not built** — regulatory decision required | §8.5 |
| §F | Clinician availability verified and updated | **Built** — Firestore-served, seedable without a release | §8.5 |
| §G | All 13 document categories | **Built** | §8.3 |
| §G | Users control which records are shared and with whom | **Built** — per-document flag, rule-enforced | §8.3 |
| §H | All 8 cessation features | **Built, limited** — no scheduled daily message engine | §8.4 |
| §H | Avoid blame, encourage professional support | **Built** — relapse card, quitline referral | §8.4 |
| §I | All 8 reminder types | **Built, limited** — Android only | §9 |
| §I | Notifications optional, privacy addressed | **Built** | §9 |
| §J | All 5 emergency situations | **Built** — 6 conditions | §8.7 |
| §8 | Proposed 12-step user workflow | **Built** — every step has a screen | §4.1, §8 |
| §9 | Target users | Design input, not a feature | — |
| §10 | Clinician module, 9 capabilities | **Built, limited** — see below | §6 |
| §10 | Role-based access | **Built, limited** | §2.1 |
| §11 | Technology and security, 11 items | **Partial** — 4 absent, itemised | §12 |
| §12 | Clinical and ethical safeguards, 11 items | **Partial** — 2 absent, itemised | §13 |

CareConnect §10 clinician capabilities in detail:

| §10 capability | Status |
|---|---|
| Register patients with consent | **Not built** — patients self-register. Clinician-initiated enrolment does not exist |
| Review patient-submitted information | **Built** |
| Record clinical findings | **Built** |
| Upload reports and photographs | **Built, limited** — free-text report fields; no clinician file upload |
| Generate referrals | **Built** — referral fields; the printable slip is patient-side |
| Recommend follow-up | **Built** |
| Communicate securely with patients | **Built, limited** — one-way written instructions surfaced in the patient's record. No messaging thread |
| Monitor high-risk patients | **Built** — priority queue, filters, attendance tracking |
| Create anonymised datasets for approved research | **Not built** — no export pipeline |

### 14.4 Questionnaire — `sree cancer questionnaire final (1).docx`

Used as the **terminology source**, not as a screen to reproduce. The questionnaire is a knowledge–attitude–practice survey instrument (sections 1–4: awareness, causes, features, information sources) and the app is a risk-assessment tool; they serve different purposes.

| Questionnaire element | Use in the app |
|---|---|
| `GENDER / ಲಿಂಗ` — Male / Female / Transgender | Gender options and their Kannada terms | 
| Bilingual Agree / Disagree / Don't know | `ClinicalTerms` answer terms |
| §2 causes: smoking, smokeless tobacco/pan, alcohol, betel leaf & areca, family history | Kannada terms for the habit variables |
| §3 features: white patch, red patch, non-healing ulcer, excess tissue growth, swelling, continuous pain, pus/boil, reduced mouth opening, bleeding gums, sudden loose teeth | Kannada terms for the red-flag checklist; `loose_teeth` red flag added from §3.10 |
| Sites: mouth, throat | Kannada terms for examination sites; `throat` site added |
| §3.3 / §3.11 three-week ulcer threshold | **Discrepancy — see §15** |

The questionnaire's demographic fields not carried into the app — education level, place of residence, annual income, occupation — are research-survey variables with no scoring role in IPO Table 2. They were not added because collecting income and occupation without a scoring or reporting purpose conflicts with CareConnect §11's "minimal collection of personally identifiable information".

---

## 14A. Illustration inventory

Expanded after clinical review, where the reviewing clinician noted the app had too few images. The audit found that only three screens referenced an image at all, and that the education, cessation and risk-factor content models had no image field whatsoever.

`AppImages` (`lib/core/app_images.dart`) declares every expected asset in one place. It is deliberately free of any Flutter import so the `domain/` catalogues can reference paths without pulling UI into that layer.

| Group | Count | Where it appears |
|---|---|---|
| Self-examination sites | 8 | One per site on the guided examination (§4.6) |
| Lesion reference gallery | 13 | Clinical photo gallery, reachable from the self-examination, the red-flag checklist and the home screen |
| Rehabilitation exercises | 7 | One per exercise, on the post-treatment screen (§8.6) |
| Education topics | 7 | Thumbnail in the topic list, header on the topic itself (§8.1) |
| Risk-factor habit questions | 5 | Above the smoking, smokeless tobacco, areca, gutkha and alcohol questions (§4.4) |
| Mouth map | 1 | Above the lesion site picker (§4.7) |
| **Total** | **41** | |

### Graceful absence

Artwork arrives in batches, so every new illustration is drawn through `OptionalAssetImage`, which renders **nothing** when the asset is absent rather than a broken-image frame. The consequence is that a picture appears the moment its file lands in `assets/images/`, with no code change — the same pattern that was already used for the throat illustration.

The cost of that design is that a mistyped path is invisible in the running app. `test/image_coverage_test.dart` closes the gap: it checks that every declared path is well formed and unique and that every topic, exercise and habit question points at a declared constant, then prints which files are still outstanding. It fails only for a missing **self-examination** illustration, because those eight are the guided examination itself rather than supporting material.

### The gallery leads with a healthy mouth

The reference gallery opens with a normal, healthy mouth rather than a pathology. Patients judge their own mouth far more reliably against a baseline than against a catalogue of disease — without one, every normal variation starts to look suspicious.

### Signs added to match the red-flag checklist

The checklist asks the patient to recognise 13 findings by name. Nine are visually depictable, and six of those had no picture. Added: erythroplakia (red patch alone), unexplained gum bleeding, a visible neck lump, teeth loosening, swelling of the mouth or jaw, and pus or a boil. The last two come from the Sree questionnaire's §3 sign list rather than from the IPO document.

The red-flag screen also gained a **"Not sure? Compare with clinical photos"** link. The self-examination screen had linked to the gallery all along; the checklist — the screen that actually asks a patient to identify a sign by name — did not.

### Deliberately without images

The emergency screen stays text-only. Photographs of severe bleeding or airway distress would be distressing, and someone in that situation needs a large phone number rather than a picture. The risk-factor illustrations are neutral and documentary for a related reason: an image that reads as shaming pushes people toward dishonest answers, and the score depends on honest ones.

---

## 15. Open items

### 15.1 Clinical decision required: 2 weeks or 3 weeks?

The app escalates a persistent lesion at **≥14 days**, per IPO §2.2 ("Duration of lesion: <2 weeks / ≥2 weeks — ≥2 weeks = referral trigger"), IPO Table 4, and IPO §4.

The Sree questionnaire says **three weeks** twice:
- §3.3 *"Non-healing Wound or Ulcer of more than three weeks"*
- §3.11 *"I have to see the dentist if a mouth ulcer lasts for more than three weeks"*

These cannot both be right. The threshold appears in the engine, the follow-up policy, the clinician's attendance window, the duration hint, the education content ("The 14-Day Rule") and multiple tests, and it is defined once as `RiskCatalog.persistenceThresholdDays = 14`, so changing it is a one-line change plus test updates.

**This needs the clinical team to choose.** Two weeks is the more cautious threshold and refers more patients; three weeks matches the questionnaire the team wrote. The app currently follows the IPO document because that is the specification it was built against.

### 15.2 Images still needed

| Asset | For | Status |
|---|---|---|
| ~~`assets/images/8.png`~~ | Self-examination site: back of the throat | **Added** — see §4.6 |
| Red patch alone | Sign reference | Suggested addition |
| Swelling of mouth or jaw | Sign reference (Questionnaire §3.5) | Suggested addition |
| Pus / boil | Sign reference (Questionnaire §3.7) | Suggested addition |
| Bleeding gums | Sign reference (Questionnaire §3.9) | Suggested addition |
| Loose teeth | Sign reference (Questionnaire §3.10) | Suggested addition |
| Normal healthy mouth | Baseline for comparison | Suggested addition |

The existing gallery (A–F) covers leukoplakia, erythroleukoplakia, verrucous leukoplakia, chronic ulcer, exophytic lump and OSMF. The gaps are the questionnaire's §3 features that have no reference image, plus a normal baseline — patients consistently benefit more from "this is what normal looks like" than from another pathology photograph.

### 15.3 Weights awaiting clinical agreement

`gutkha_pan_masala`, `family_history` and `immunosuppression` are recorded but score zero. A test enforces that they do not move a patient's score. Supply weights and the test is the only thing that needs changing.

### 15.4 Correctness items to fix

| Item | Severity |
|---|---|
| ~~Consent wording claimed records and photographs stayed on the device~~ | **Fixed** — see §13.1 |
| Enrolment code + `hasDoctorProfile()` rules fallback allow self-assigned clinician role | **High** — must be removed before real deployment |
| `outcome` rules block has no coordinator read branch while `clinical` does | Medium — review whether intentional |
| Emergency and centre "Call" buttons display a number rather than dialling | Low — but the label implies dialling |
| ~~DigiLocker attachments are device-local paths~~ | **Fixed** — see §8.3 |
| ~~Illustrations and photographs cropped by `BoxFit.cover`~~ | **Fixed** — see §4.6 |
| Rehabilitation screen state is not persisted | Low |

### 15.5 Not built, with reasons

| Item | Source | Reason |
|---|---|---|
| Teleconsultation | CareConnect §F | Regulatory decision required |
| Audit logs | CareConnect §11 | Needs Cloud Functions (paid plan) |
| Scheduled backups | CareConnect §11 | Firestore export needs the paid plan |
| Multi-factor authentication | CareConnect §11 | Configuration decision |
| Minor / vulnerable-user safeguards | CareConnect §12 | Needs a clinical and legal pathway definition first |
| Anonymised research export | CareConnect §10, §12 | No export pipeline |
| In-app inaccuracy reporting | CareConnect §12 | Not started |
| Clinician-initiated patient registration | CareConnect §10 | Not started |
| iOS build | CareConnect §11 | Needs a macOS signing identity and an Apple developer account |
| Full UI localisation | CareConnect §11 | Needs reviewed translations of all interface strings |

---

## 16. Test coverage

183 tests across 14 files. All pass.

| File | Covers |
|---|---|
| `risk_engine_test.dart` | Every variable's score contribution, band cut-offs, override precedence, unknown-answer retention, unweighted variables not moving the score, the 14-day boundary at 13 / 14 / 20 days, neck-lump handling, self-exam interaction |
| `sharing_test.dart` | Addressed sharing invariants the Firestore rules depend on — flag alone and recipient alone must both fail |
| `attendance_test.dart` | The two-week attendance rule, including the day-14 boundary and the reminder-needed state |
| `registration_profile_test.dart` | Required age and gender, legacy `sex` key fallback |
| `screening_centers_test.dart` | Firestore-vs-bundled source selection |
| `translation_test.dart` | Every red flag and exam site has a Kannada term; no placeholders; gender options match the questionnaire |
| `reminder_service_test.dart` | Platform gating, id allocation |
| `lesion_photo_test.dart` | The three photograph states, legacy-row compatibility, the 1 MiB limit, and that withdrawing consent cuts every route to the image |
| `consent_wording_test.dart` | Consent-form accuracy: the stale device-only claims cannot reappear, and the account/encryption/audit-gap/coordinator/withdrawal disclosures must stay stated |
| `review_feedback_test.dart` | The clinical-review changes: flag-to-band mapping, that an override shows red over a green band, band ranges derived from the cut-offs, and that a DigiLocker local path is not a viewable image |
| `image_coverage_test.dart` | Every declared asset path is well formed, unique and a `.jpg`; every education topic / exercise / habit question points at a declared asset; the eight self-examination illustrations must exist. Reports how much artwork is present (41 of 41) |
| `enrolment_switch_test.dart` | Behaviour under both `ALLOW_ENROLMENT_CODE` builds |
| `new_features_test.dart` | CareConnect module models |
| `app_smoke_test.dart` | App boots, role selection renders |

Run: `flutter test` and `flutter test --dart-define=ALLOW_ENROLMENT_CODE=false`.

### 16.1 What the tests do not cover

No integration or end-to-end test exercises a real Firebase backend. In particular the following have been verified by build and by rules compilation, **not** by running the actual flow across two devices:

- A photograph captured on one device opening in the clinician's view on another
- The Firestore rules rejecting an unauthorised read at runtime
- Notification delivery on a physical Android device

These need manual verification before demonstration. The README carries a seven-step two-device walkthrough for exactly this.

---

## 17. Build and deploy

```bash
flutter analyze lib test
flutter test
flutter build apk --release
flutter build web -t lib/main.dart
firebase deploy --only firestore:rules,hosting --project oral-cancer-pilot-1027-dc3a3
```

Regenerate this document as a PDF after editing it:

```bash
python3 -m pip install markdown      # once
python3 tools/make_spec_pdf.py       # writes SPECIFICATION.pdf
```

Provisioning tools (require a service-account key):

```bash
node tools/grant_doctor.mjs --username <name>                 # grant the doctor claim
node tools/grant_doctor.mjs --coordinator --username <name>    # grant the coordinator claim
node tools/seed_centers.mjs                                    # seed the centres directory
```

Build switches:

| Switch | Default | Effect |
|---|---|---|
| `ALLOW_ENROLMENT_CODE` | `true` | `false` removes clinician self-registration entirely |
| `ENROLMENT_CODE` | `ORAL-PILOT-2026` | Change the code without editing source |

---

## Appendix A — Content inventory totals

| Item | Count |
|---|---|
| Screens | 26 |
| Risk-assessment variables | 15 (max score 27) |
| Red-flag checklist items | 13 |
| Self-examination sites | 8 |
| Lesion site options | 11 |
| Lesion symptom switches | 7 |
| Patient output states | 5 |
| Clinician assessment fields | 19 |
| Outcome fields | 10 |
| Validation metrics | 4 + per-band positive rate |
| Education topics | 7 (3 languages) |
| Myths and facts | 5 |
| FAQs | 5 |
| Clinical reference photographs | 13 (incl. a healthy-mouth baseline) |
| DigiLocker categories | 13 |
| Screening centres (seed) | 5, across 4 types |
| Cessation milestones | 6 |
| Craving triggers | 7 |
| Rehabilitation modalities | 3 (7 exercises, 13 special instructions) |
| Emergency conditions | 6 |
| Reminder types | 8 |
| Firestore collections / subcollections | 13 |
| Tests | 183 |

## Appendix B — Key constants

| Constant | Value | Defined in |
|---|---|---|
| Lesion persistence threshold | **14 days** | `RiskCatalog.persistenceThresholdDays` |
| Lower-risk band maximum | 4 | `RiskCatalog.lowerRiskMaxScore` |
| Increased-risk band maximum | 9 | `RiskCatalog.increasedRiskMaxScore` |
| Maximum possible score | 27 | `RiskCatalog.maxPossibleScore` |
| Attendance window | **14 days** | `ClinicianAssessmentRecord.attendanceWindowDays` |
| Photograph size ceiling | 900 KiB (Firestore limit 1 MiB) | `PhotoDocumentStore.maxBytes` |
| Photograph capture size | 1024 × 1024, quality 55 | `lesion_screen.dart` |
| Follow-up: professional check | 7 days | `FollowUpPolicy` |
| Follow-up: observe and review | 14 days from first noticed | `FollowUpPolicy` |
| Follow-up: higher risk | 14 days | `FollowUpPolicy` |
| Follow-up: increased risk | 30 days | `FollowUpPolicy` |
| Reminder lead time | 2 days before, 09:00 | `ReminderService` |
| Patient ID format | `OC-{year}-{6 alphanumeric}` | `AuthRepository` |
| Timezone | `Asia/Kolkata` | `ReminderService` |
