# Endpoint Health automated smoke test
# Windows PowerShell 5.1 - No Pester required
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$healthScript = Join-Path $root 'scripts\Get-EndpointHealth.ps1'
$reports = Join-Path $root 'reports'

# Verify required paths
if (-not (Test-Path -LiteralPath $healthScript -PathType Leaf)) {
    throw 'TEST FAILED: Health script missing.'
}

if (-not (Test-Path -LiteralPath $reports -PathType Container)) {
    throw 'TEST FAILED: Reports directory missing.'
}

# Check health script syntax
$tokens = $null
$parseErrors = $null

[void][System.Management.Automation.Language.Parser]::ParseFile(
    $healthScript,
    [ref]$tokens,
    [ref]$parseErrors
)

if ($parseErrors.Count -gt 0) {
    throw 'TEST FAILED: Health script has syntax errors.'
}

# Remember existing CSV files without modifying them
$before = @(
    Get-ChildItem -LiteralPath $reports -Filter 'EndpointHealth_*.csv' -File |
        Select-Object -ExpandProperty FullName
)

# Run the read-only health script
& $healthScript -OutputDirectory $reports | Out-Null

# Identify the new report
$newReports = @(
    Get-ChildItem -LiteralPath $reports -Filter 'EndpointHealth_*.csv' -File |
        Where-Object { $before -notcontains $_.FullName }
)

if ($newReports.Count -ne 1) {
    throw "TEST FAILED: Expected 1 new report, found $($newReports.Count)."
}

# Import CSV data
$rows = @(Import-Csv -LiteralPath $newReports[0].FullName)

if ($rows.Count -ne 1) {
    throw "TEST FAILED: Expected 1 CSV record, found $($rows.Count)."
}

# Verify exactly 11 expected fields
$expected = @(
    'CollectedAt',
    'ComputerName',
    'UptimeDays',
    'WindowsUpdateService',
    'BITSService',
    'DefenderService',
    'DefenderRealtime',
    'DefenderSignatureDate',
    'SystemDrive',
    'DriveFreeGB',
    'DriveFreePercent'
)

$actual = @($rows[0].PSObject.Properties.Name)

if (($actual -join '|') -cne ($expected -join '|')) {
    throw 'TEST FAILED: CSV columns do not match expected schema.'
}

# Verify basic report values
if ($rows[0].ComputerName -ne $env:COMPUTERNAME) {
    throw 'TEST FAILED: Computer name mismatch.'
}

if ([string]::IsNullOrWhiteSpace($rows[0].CollectedAt)) {
    throw 'TEST FAILED: Collection timestamp missing.'
}

if ($rows[0].DefenderRealtime -notin @('True', 'False', 'Unavailable')) {
    throw 'TEST FAILED: Invalid Defender protection value.'
}

Write-Host 'TEST PASSED' -ForegroundColor Green
Write-Host "CSV fields verified: $($actual.Count)"
Write-Host "Report: $($newReports[0].Name)"
