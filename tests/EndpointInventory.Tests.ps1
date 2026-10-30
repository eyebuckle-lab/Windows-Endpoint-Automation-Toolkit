# Endpoint Inventory automated smoke test
# Windows PowerShell 5.1 compatible
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$inventory = Join-Path $root 'scripts\Get-EndpointInventory.ps1'
$reports = Join-Path $root 'reports'

if (-not (Test-Path -LiteralPath $inventory -PathType Leaf)) {
    throw 'TEST FAILED: Inventory script missing.'
}

if (-not (Test-Path -LiteralPath $reports -PathType Container)) {
    throw 'TEST FAILED: Reports directory missing.'
}

$tokens = $null
$parseErrors = $null

[void][System.Management.Automation.Language.Parser]::ParseFile(
    $inventory, [ref]$tokens, [ref]$parseErrors
)

if ($parseErrors.Count -gt 0) {
    throw 'TEST FAILED: Inventory script syntax invalid.'
}

$before = @(
    Get-ChildItem -LiteralPath $reports -Filter 'EndpointInventory_*.csv' -File |
        Select-Object -ExpandProperty FullName
)

& $inventory -OutputDirectory $reports | Out-Null

$newReports = @(
    Get-ChildItem -LiteralPath $reports -Filter 'EndpointInventory_*.csv' -File |
        Where-Object { $before -notcontains $_.FullName }
)

if ($newReports.Count -ne 1) {
    throw "TEST FAILED: Expected 1 new report, found $($newReports.Count)."
}

$rows = @(Import-Csv -LiteralPath $newReports[0].FullName)

if ($rows.Count -ne 1) {
    throw "TEST FAILED: Expected 1 CSV row, found $($rows.Count)."
}

$expected = @(
    'CollectedAt', 'ComputerName', 'Manufacturer',
    'Model', 'SerialNumber', 'WindowsName',
    'WindowsVersion', 'WindowsBuild', 'Processor',
    'RAM_GB', 'SystemDrive', 'DriveTotalGB', 'DriveFreeGB'
)

$actual = @($rows[0].PSObject.Properties.Name)
$missing = @($expected | Where-Object { $actual -notcontains $_ })

if ($missing.Count -gt 0 -or $actual.Count -ne 13) {
    throw "TEST FAILED: CSV columns incorrect. Missing: $($missing -join ', ')"
}

if ([string]::IsNullOrWhiteSpace($rows[0].ComputerName)) {
    throw 'TEST FAILED: Computer name is empty.'
}

Write-Host 'TEST PASSED' -ForegroundColor Green
Write-Host "CSV fields verified: $($actual.Count)"
Write-Host "Report: $($newReports[0].Name)"
