# Modules 7 & 8 — Endpoint Configuration and Unified Reporting

This add-on preserves the existing four-module runner `Run-AllTests.ps1`.
Run all six module tests using `Run-ExtendedTests.ps1`.

## Endpoint configuration snapshot

`scripts/Get-EndpointCompliance.ps1` collects available BitLocker, Windows Firewall,
Defender and Windows Update information with read-only cmdlets. Some information
may be `Unavailable` because of Windows edition, permissions, or third-party security products.
The snapshot is **not** a compliance verdict; no organization policy baseline is evaluated.

## Unified endpoint summary

`scripts/New-EndpointSummary.ps1` selects the **latest existing** CSV report of each type
and writes one combined record. It does not trigger fresh collectors or change source files.
Source file columns show where the information originated; values can have different
collection timestamps and must not be treated as synchronized.

## Running modules

From the toolkit directory:

```powershell
.\scripts\Get-EndpointCompliance.ps1
.\scripts\New-EndpointSummary.ps1
.\Run-ExtendedTests.ps1
```

The tests generate new reports. Reports may contain system configuration and device
information; keep `reports/` excluded from Git and avoid publishing them.
No test or script removes an existing CSV or changes Windows security settings.
