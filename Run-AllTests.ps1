# PowerShell Automation Toolkit - Unified Test Runner
# Windows PowerShell 5.1 compatible

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$tests = @(
    'ServiceStatusCheck.Tests.ps1'
    'EndpointInventory.Tests.ps1'
    'EndpointHealth.Tests.ps1'
    'SoftwareInventory.Tests.ps1'
)

$testDirectory = Join-Path $PSScriptRoot 'tests'
$powershellExe = Join-Path $PSHOME 'powershell.exe'

$passed = 0
$failed = 0

foreach ($testName in $tests) {
    Write-Host "`nRunning: $testName" -ForegroundColor Cyan

    $testPath = Join-Path $testDirectory $testName

    if (-not (Test-Path -LiteralPath $testPath -PathType Leaf)) {
        Write-Host "FAILED: Test file missing." -ForegroundColor Red
        $failed++
        continue
    }

    # Run each test in a separate PowerShell process
    $output = @(
        & $powershellExe -NoProfile -NonInteractive `
            -File $testPath 2>&1
    )
    $exitCode = $LASTEXITCODE

    $lines = @($output | ForEach-Object { [string]$_ })
    $output | ForEach-Object { Write-Host "$_" }

    $hasPassMessage = @(
        $lines | Where-Object { $_ -match '^TEST PASSED\s*$' }
    ).Count -gt 0

    if ($exitCode -eq 0 -and $hasPassMessage) {
        Write-Host "PASSED: $testName" -ForegroundColor Green
        $passed++
    }
    else {
        Write-Host "FAILED: $testName (exit code $exitCode)" -ForegroundColor Red
        $failed++
    }
}

Write-Host "`n=================================="
Write-Host "POWERSHELL TOOLKIT TEST SUMMARY"
Write-Host "Tests passed: $passed"
Write-Host "Tests failed: $failed"
Write-Host "=================================="

if ($failed -gt 0) {
    throw "$failed toolkit test(s) failed."
}

Write-Host "ALL TESTS PASSED" -ForegroundColor Green

