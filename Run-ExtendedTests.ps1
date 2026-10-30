# Run-ExtendedTests.ps1
# Runs the existing 4-test runner, then the new compliance and summary tests.
[CmdletBinding()]
param()
$ErrorActionPreference = 'Stop'
$exe = Join-Path $PSHOME 'powershell.exe'
$jobs = @(
    @{ Name = 'Existing four-module suite'; Path = (Join-Path $PSScriptRoot 'Run-AllTests.ps1'); PassText = 'ALL TESTS PASSED' },
    @{ Name = 'Endpoint Compliance'; Path = (Join-Path $PSScriptRoot 'tests\EndpointCompliance.Tests.ps1'); PassText = 'TEST PASSED' },
    @{ Name = 'Unified Reporting'; Path = (Join-Path $PSScriptRoot 'tests\EndpointSummary.Tests.ps1'); PassText = 'TEST PASSED' }
)
$passedGroups = 0
foreach ($job in $jobs) {
    Write-Host "`n=== $($job.Name) ===" -ForegroundColor Cyan
    if (-not (Test-Path -LiteralPath $job.Path -PathType Leaf)) { throw "Test file missing: $($job.Path)" }
    $output = @(& $exe -NoProfile -NonInteractive -File $job.Path 2>&1)
    $exitCode = $LASTEXITCODE
    $lines = @($output | ForEach-Object { [string]$_ })
    foreach ($line in $lines) { Write-Host $line }
    if ($exitCode -ne 0 -or ($lines -notcontains $job.PassText)) {
        throw "TEST GROUP FAILED: $($job.Name) (exit code $exitCode)"
    }
    $passedGroups++
}
if ($passedGroups -ne 3) { throw 'Not all test groups ran.' }
Write-Host "`nEXTENDED TOOLKIT TESTS PASSED: 6/6" -ForegroundColor Green
