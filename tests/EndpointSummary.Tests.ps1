# EndpointSummary.Tests.ps1 - standalone, no Pester, no deletions.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $root 'scripts\New-EndpointSummary.ps1'
$reports = Join-Path $root 'reports'
if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) { throw 'Missing summary script.' }
$tokens = $null; $parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count -gt 0) { throw 'Summary script has syntax errors.' }
$before = @(Get-ChildItem -LiteralPath $reports -Filter 'EndpointSummary_*.csv' -File |
    Select-Object -ExpandProperty FullName)
& $scriptPath -OutputDirectory $reports | Out-Null
$newReports = @(Get-ChildItem -LiteralPath $reports -Filter 'EndpointSummary_*.csv' -File |
    Where-Object { $before -notcontains $_.FullName })
if ($newReports.Count -ne 1) { throw "Expected one new summary report, found $($newReports.Count)." }
$rows = @(Import-Csv -LiteralPath $newReports[0].FullName -ErrorAction Stop)
if ($rows.Count -ne 1) { throw 'Summary must contain one row.' }
$required = @('SummaryCreatedAt','ComputerName','WindowsName','RAM_GB',
    'DriveFreePercent','BitLockerProtectionStatus','ServiceAuditWindowsUpdate','SoftwareRecordCount',
    'SourceInventory','SourceHealth','SourceServices','SourceSoftware','SourceCompliance')
foreach ($name in $required) {
    if ($rows[0].PSObject.Properties.Name -notcontains $name) { throw "Missing summary column: $name" }
}
if ($rows[0].ComputerName -ne $env:COMPUTERNAME) { throw 'Summary computer mismatch.' }
foreach ($name in @('SourceInventory','SourceHealth','SourceServices','SourceSoftware','SourceCompliance')) {
    if ($rows[0].$name -eq 'Missing') { throw "Missing report dependency: $name" }
}
Write-Host 'TEST PASSED'
Write-Host "Summary report: $($newReports[0].Name)"
