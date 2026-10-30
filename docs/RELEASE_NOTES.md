# Portfolio release v1.0.0 - local release notes

## Included

- Six read-only endpoint diagnostic/reporting modules.
- A unified assessment command that generates five fresh diagnostic CSVs and a
  consolidated report with source references.
- Six module-level automated tests and one separate integration test.
- README, quick-start documentation, architecture notes and synthetic demo CSVs.

## Known limitations

- Software inventory does not cover all installation technologies and profiles.
- Some BitLocker/Defender/Firewall fields can be `Unavailable` without elevation,
  compatible editions or components; no compliance verdict is issued.
- The summary references latest available reports collected at different times.
- Integration tests are Windows-specific and must pass locally before tagging.

## Release safety

- No real `reports/` files or serial numbers should be included in Git.
- A local Git commit and annotated `v1.0.0` tag are offered only after tests pass.
- No Git remote is created or pushed by this script.
