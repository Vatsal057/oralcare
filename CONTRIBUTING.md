# Contributing to OralCare

Thanks for contributing. OralCare is a clinical-awareness pilot, so changes to
clinical logic require more care than ordinary product changes.

## Before opening a pull request

1. Create a focused branch from `main`.
2. Keep clinical-scoring changes separate from visual or structural changes.
3. Run:

   ```bash
   flutter analyze lib test
   flutter test
   flutter build apk --debug
   ```

4. Explain the change, its patient-safety impact, and how you verified it.

## Clinical logic

The score weights, categories, and red-flag override are deliberately marked
**provisional**. Do not alter `lib/domain/risk_catalog.dart` or
`lib/domain/risk_engine.dart` without documented clinical review and matching
tests. Never add code that diagnoses cancer or interprets a photograph as a
diagnosis.

## Security and privacy

Do not commit Firebase configuration for a live project, credentials, exports,
patient records, photographs, screen recordings, or any other personally
identifiable or clinical data. See [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)
and [SECURITY.md](SECURITY.md).

## Commit style

Use concise conventional commits where practical, for example:

- `feat: add post-treatment reminder workflow`
- `fix: preserve share-consent withdrawal in doctor queue`
- `docs: clarify Firebase fork setup`
