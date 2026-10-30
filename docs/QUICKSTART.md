# Quick start (Windows PowerShell 5.1)

1. Open PowerShell in the `PowerShell-Automation-Toolkit` directory.
2. Run `powershell.exe -NoProfile -File .\Run-EndpointAssessment.ps1`.
3. Open the generated `EndpointSummary_*.csv` in `reports/` and examine its
   `Source*` columns to identify the input reports.
4. Validate changes with `powershell.exe -NoProfile -File .\Run-ExtendedTests.ps1`
   and `powershell.exe -NoProfile -File .\tests\EndpointAssessment.Tests.ps1`.

You can also run `powershell.exe -NoProfile -File .\Run-EndpointAssessment.ps1 -RunTests`
to run the six-module suite first.

### Expected results

- Six module checks complete with `EXTENDED TOOLKIT TESTS PASSED: 6/6`.
- The integration test reports `ASSESSMENT INTEGRATION TEST PASSED`.
- The assessment produces five new diagnostic reports and one new summary report.

### Safety and troubleshooting

- **Real reports are local and private**; don't publish them or paste raw serials.
- `Unavailable` for BitLocker/Defender is not proof that protection is off.
- System policy or Windows edition can restrict access to some properties.
- If a downloaded script is blocked, review it before choosing
  **File Properties > Unblock**. Don't change global execution policy by default.
- The scripts query local Windows state; results may differ between machines.
- `examples/` contains fabricated records for demonstration only.
