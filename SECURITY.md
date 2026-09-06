# Security policy

## Supported versions

The current `main` branch is the supported pilot version.

## Reporting a vulnerability

Do **not** open a public GitHub issue for a vulnerability, exposed Firebase
configuration, access-control problem, or possible patient-data disclosure.

Use GitHub's private vulnerability-reporting feature for this repository when
available. If it is not enabled, contact the repository owner privately through
the contact information on their GitHub profile. Include a minimal reproduction,
the affected component, and any mitigation you have already applied.

We will acknowledge a report promptly, investigate before disclosure, and work
with the reporter on a reasonable remediation timeline.

## Pilot boundary

This repository is not approved for clinical deployment. Its current doctor-role
mechanism is client-set and therefore insufficient for production health-data
access control. See [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md) for the
required production hardening work.
