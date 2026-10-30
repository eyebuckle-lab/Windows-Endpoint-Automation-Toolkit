# PowerShell Automation Toolkit â€” Portfolio Overview

## Project

Windows endpoint administration and IT asset management toolkit, built for
Windows PowerShell 5.1. Uses native service queries, CIM, the uninstall registry,
and available Defender/Firewall/BitLocker commands to generate CSV diagnostics.

## Capabilities

1. **Service audit:** Windows Update, BITS and Defender service status/startup type.
2. **Endpoint inventory:** hardware identity, Windows build, CPU, memory and system disk.
3. **Endpoint health:** uptime, disk free space and available Defender details.
4. **Software inventory:** uninstall-registry entries (not `Win32_Product`).
5. **Configuration snapshot:** BitLocker, Firewall, Defender and update settings.
6. **Unified reporting:** one CSV referencing the latest source report of each type.

## One-command demonstration

From inside the PowerShell-Automation-Toolkit directory:

```powershell
.\Run-EndpointAssessment.ps1
```

To run the existing six-module regression tests first:

```powershell
.\Run-EndpointAssessment.ps1 -RunTests
```

Each run creates five new source reports and one summary in `reports/`.
The launcher validates the newly created files, row counts, and summary source
names. Existing CSV reports are preserved.

## Automated tests

```powershell
.\Run-ExtendedTests.ps1
.\tests\EndpointAssessment.Tests.ps1
```

## Security and limitations

- System queries are read-only; reports are the only expected system-side writes.
- The `reports/` folder is Git-ignored; reports can contain device serial numbers,
  installed application details and security configuration. Do **not** publish them.
- BitLocker, Defender and Firewall information may be unavailable without the
  necessary privileges, Windows components, or compatible security software.
- A stopped service alone does not imply a fault.
- Registry software inventory excludes portable programs and can omit Store apps,
  other user profiles and applications not registered in uninstall keys.
- The configuration snapshot is **not** a formal compliance determination.
- Unified reporting joins files collected sequentially, not an atomic snapshot.
- Tests verify basic outputs and schema, not every possible operating-system state.

## Technical decisions

- PowerShell 5.1 compatibility with no external Pester dependency.
- Isolated diagnostics, transparent CSV output and independently runnable tests.
- Explicit refusal to overwrite reports, with no installers or service changes.
- Local Git history; source code is not pushed automatically.
