# Standalone PowerShell 5.1 smoke test; never removes existing reports.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$module = Join-Path $root 'scripts\Get-SoftwareInventory.ps1'
$reports = Join-Path $root 'reports'
if (-not (Test-Path -LiteralPath $module -PathType Leaf)) { throw 'Module missing.' }
$tokens = $null
$parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile(
    $module, [ref]$tokens, [ref]$parseErrors
)
if ($parseErrors.Count -gt 0) { throw 'Module has syntax errors.' }
$before = @(Get-ChildItem -LiteralPath $reports -Filter 'SoftwareInventory_*.csv' -File |
    ForEach-Object { $_.FullName })
& $module -OutputDirectory $reports | Out-Null
$new = @(Get-ChildItem -LiteralPath $reports -Filter 'SoftwareInventory_*.csv' -File |
    Where-Object { $before -notcontains $_.FullName })
if ($new.Count -ne 1) { throw "Expected 1 new report; found $($new.Count)." }
$rows = @(Import-Csv -LiteralPath $new[0].FullName)
if ($rows.Count -lt 1) { throw 'No inventory records.' }
$expected = @('CollectedAt','ComputerName','Name','Version','Publisher',
    'InstallDate','Scope','Architecture','RegistryKey')
$actual = @($rows[0].PSObject.Properties.Name)
if (($actual -join '|') -cne ($expected -join '|')) { throw 'Incorrect CSV columns.' }
foreach ($row in $rows) {
    if ([string]::IsNullOrWhiteSpace($row.Name)) { throw 'Empty software name.' }
    if ($row.Scope -notin @('Machine','CurrentUser')) { throw 'Unknown scope.' }
    if ($row.Architecture -notin @('64-bit','32-bit')) { throw 'Unknown registry view.' }
}
Write-Host 'TEST PASSED'
Write-Host "Inventory entries: $($rows.Count)"
Write-Host "Report: $($new[0].Name)"
