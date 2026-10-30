# Run-EndpointAssessment.ps1
# Collects fresh diagnostic CSVs and builds a consolidated assessment.
# Windows PowerShell 5.1. Read-only system queries; new CSVs are written to reports/.
[CmdletBinding()]
param([switch]$RunTests)

$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$scriptDir = Join-Path $root 'scripts'
$reportDir = Join-Path $root 'reports'
$testRunner = Join-Path $root 'Run-ExtendedTests.ps1'

if (-not (Test-Path -LiteralPath $reportDir -PathType Container)) {
    throw "Reports directory missing: $reportDir"
}

if ($RunTests) {
    $powershellExe = Join-Path $PSHOME 'powershell.exe'
    Write-Host '=== RUNNING SIX-MODULE REGRESSION SUITE ===' -ForegroundColor Cyan
    & $powershellExe -NoProfile -NonInteractive -File $testRunner
    if ($LASTEXITCODE -ne 0) {
        throw "Regression suite failed with exit code $LASTEXITCODE."
    }
}

function Get-Reports {
    param([string]$Pattern)
    return @(
        Get-ChildItem -LiteralPath $reportDir -Filter $Pattern -File -ErrorAction Stop
    )
}

function Invoke-CheckedCollector {
    param(
        [string]$ScriptName,
        [string]$ReportPattern,
        [int]$MinimumRows,
        [int]$MaximumRows
    )

    $scriptPath = Join-Path $scriptDir $ScriptName
    if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
        throw "Collector missing: $scriptPath"
    }
    $before = @(Get-Reports $ReportPattern | ForEach-Object { $_.FullName })
    Write-Host "`nCollecting: $ScriptName" -ForegroundColor Cyan
    & $scriptPath -OutputDirectory $reportDir | Out-Host
    $newFiles = @(Get-Reports $ReportPattern | Where-Object {
        $before -notcontains $_.FullName
    })
    if ($newFiles.Count -ne 1) {
        throw "Expected one new $ReportPattern report, found $($newFiles.Count)."
    }
    $file = $newFiles[0]
    $rows = @(Import-Csv -LiteralPath $file.FullName -ErrorAction Stop)
    if ($rows.Count -lt $MinimumRows -or $rows.Count -gt $MaximumRows) {
        throw "Unexpected record count in $($file.Name): $($rows.Count)"
    }
    Write-Host "Verified $($file.Name): $($rows.Count) row(s)" -ForegroundColor Green
    return $file.Name
}

# Every collector generates a NEW report; existing reports are preserved.
$sourceNames = @{}
$sourceNames['SourceServices'] = Invoke-CheckedCollector 'ServiceStatusCheck.ps1' 'ServiceStatus_*.csv' 3 3
$sourceNames['SourceInventory'] = Invoke-CheckedCollector 'Get-EndpointInventory.ps1' 'EndpointInventory_*.csv' 1 1
$sourceNames['SourceHealth'] = Invoke-CheckedCollector 'Get-EndpointHealth.ps1' 'EndpointHealth_*.csv' 1 1
$sourceNames['SourceSoftware'] = Invoke-CheckedCollector 'Get-SoftwareInventory.ps1' 'SoftwareInventory_*.csv' 1 ([int]::MaxValue)
$sourceNames['SourceCompliance'] = Invoke-CheckedCollector 'Get-EndpointCompliance.ps1' 'EndpointCompliance_*.csv' 1 1

$summaryScript = Join-Path $scriptDir 'New-EndpointSummary.ps1'
if (-not (Test-Path -LiteralPath $summaryScript -PathType Leaf)) {
    throw "Summary module missing: $summaryScript"
}
$beforeSummary = @(Get-Reports 'EndpointSummary_*.csv' | ForEach-Object { $_.FullName })
Write-Host "`nCreating unified endpoint summary" -ForegroundColor Cyan
& $summaryScript -OutputDirectory $reportDir | Out-Host
$newSummary = @(Get-Reports 'EndpointSummary_*.csv' | Where-Object {
    $beforeSummary -notcontains $_.FullName
})
if ($newSummary.Count -ne 1) {
    throw "Expected one new summary CSV, found $($newSummary.Count)."
}
$summaryRows = @(Import-Csv -LiteralPath $newSummary[0].FullName -ErrorAction Stop)
if ($summaryRows.Count -ne 1) { throw 'Summary must contain exactly one row.' }
if ($summaryRows[0].ComputerName -ne $env:COMPUTERNAME) {
    throw 'Summary computer name does not match the local computer.'
}
foreach ($column in $sourceNames.Keys) {
    $actual = [string]$summaryRows[0].$column
    if ($actual -cne $sourceNames[$column]) {
        throw "Summary source mismatch at $column; expected $($sourceNames[$column]); found $actual."
    }
}

Write-Host "`nASSESSMENT PASSED: 5 fresh source reports and 1 verified summary" -ForegroundColor Green
Write-Host "Summary CSV: $($newSummary[0].FullName)"
Write-Host 'Source files and timestamps are recorded in the summary; do not publish raw reports.'
