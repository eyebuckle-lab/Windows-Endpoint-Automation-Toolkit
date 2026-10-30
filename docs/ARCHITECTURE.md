# Architecture and data flow

`Run-EndpointAssessment.ps1` sequentially invokes five read-only collectors:

1. `ServiceStatusCheck.ps1` -> `ServiceStatus_*.csv`
2. `Get-EndpointInventory.ps1` -> `EndpointInventory_*.csv`
3. `Get-EndpointHealth.ps1` -> `EndpointHealth_*.csv`
4. `Get-SoftwareInventory.ps1` -> `SoftwareInventory_*.csv`
5. `Get-EndpointCompliance.ps1` -> `EndpointCompliance_*.csv`

It then invokes `New-EndpointSummary.ps1` -> `EndpointSummary_*.csv`.
The summary selects the latest available report of each type; it records
source filenames, but is not an atomic time-synchronized snapshot.

Each collector writes a new CSV under Git-ignored `reports/`. Tests parse scripts,
execute read-only collectors, and check schemas and source references.
`Run-ExtendedTests.ps1` runs six module tests; the separate
`EndpointAssessment.Tests.ps1` exercises the full workflow.

Design decisions: Windows PowerShell 5.1, built-in cmdlets and CIM, no Pester
requirement, no `Win32_Product`, no service configuration changes, no update
installation or Defender scan, and no automatic upload.

### Trust boundaries

`reports/` contains actual device data and must remain private.
`examples/DEMO-*.csv` is synthetic and safe to share as illustrative output.
Source/report timestamps can differ. `Unavailable` should be preserved rather
than interpreted as a security failure or success.
