<!-- toolkit-release-batch-v1 -->
# PowerShell Automation Toolkit

Read-only Windows endpoint administration and IT asset-management diagnostics,
written for **Windows PowerShell 5.1**. The toolkit exports local CSV reports,
offers a one-command assessment, and includes independent automated tests.

## Quick start

Open Windows PowerShell in the `PowerShell-Automation-Toolkit` folder:

```powershell
powershell.exe -NoProfile -File .\Run-EndpointAssessment.ps1
```

To run the six module tests and the end-to-end assessment integration test:

```powershell
powershell.exe -NoProfile -File .\Run-ExtendedTests.ps1
powershell.exe -NoProfile -File .\tests\EndpointAssessment.Tests.ps1
```

The assessment creates five fresh source CSVs and one consolidated summary in
`reports/`. You can also use `-RunTests` with `Run-EndpointAssessment.ps1` to run
the six module tests before the assessment.

## Capabilities

| Capability | Main entry point |
| --- | --- |
| Windows Update, BITS and Defender service audit | `scripts/ServiceStatusCheck.ps1` |
| Hardware, OS, processor, memory and disk inventory | `scripts/Get-EndpointInventory.ps1` |
| Uptime, Defender and disk health snapshot | `scripts/Get-EndpointHealth.ps1` |
| Installed-program uninstall-registry inventory | `scripts/Get-SoftwareInventory.ps1` |
| BitLocker, Firewall, Defender and update configuration snapshot | `scripts/Get-EndpointCompliance.ps1` |
| Latest-available report aggregation | `scripts/New-EndpointSummary.ps1` |

Run `Run-ExtendedTests.ps1` to test the six modules. The separate
`tests/EndpointAssessment.Tests.ps1` tests the complete assessment workflow.
The tests create reports; they do not intentionally delete existing reports.

## Demonstration and architecture

- `examples/DEMO-*.csv`: **100% fabricated demonstration records**. They do not
  contain real endpoint identifiers or report values, and are not assessment inputs.
- `docs/QUICKSTART.md`: usage and troubleshooting.
- `docs/ARCHITECTURE.md`: design and data flow.
- `docs/RELEASE_NOTES.md`: v1.0.0 release scope.
- `PORTFOLIO.md`: project narrative for technical interviews.

## Scope and limitations

- Windows 10/11 and Windows PowerShell 5.1; some CIM, security and registry
  information can be unavailable depending on edition, permissions or software.
- This is a **read-only configuration snapshot**, not an organizational
  compliance certification or a vulnerability assessment.
- Windows services may legitimately be stopped; this alone does not indicate a fault.
- Software inventory uses uninstall registry entries and may omit Microsoft Store,
  portable applications, or software installed in other user profiles.
- The unified report uses latest available reports. Collection timestamps are not
  synchronized; inspect the source-reference columns before drawing conclusions.
- Automated tests cover basic functionality and CSV schemas, not all Windows states.

## Privacy and safety

**Never commit or publish the real `reports/` directory**: it can contain serial
numbers, installed software names and security configuration. Git ignores
`reports/`. The `examples/` directory contains synthetic data only.
No remote Git push is made by the toolkit's development batches. Review all code
before running it, especially on managed or production devices.

No public license has been selected; confirm licensing before public distribution.
