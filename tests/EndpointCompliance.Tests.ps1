# EndpointCompliance.Tests.ps1 - standalone, no Pester, no deletions.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$scriptPath = Join-Path $root 'scripts\Get-EndpointCompliance.ps1'
$reports = Join-Path $root 'reports'
if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) { throw 'Missing compliance script.' }
$tokens = $null; $parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count -gt 0) { throw 'Compliance script has syntax errors.' }
$before = @(Get-ChildItem -LiteralPath $reports -Filter 'EndpointCompliance_*.csv' -File |
    Select-Object -ExpandProperty FullName)
& $scriptPath -OutputDirectory $reports | Out-Null
$newReports = @(Get-ChildItem -LiteralPath $reports -Filter 'EndpointCompliance_*.csv' -File |
    Where-Object { $before -notcontains $_.FullName })
if ($newReports.Count -ne 1) { throw "Expected exactly one new compliance report, found $($newReports.Count)." }
$rows = @(Import-Csv -LiteralPath $newReports[0].FullName -ErrorAction Stop)
if ($rows.Count -ne 1) { throw 'Compliance report must have one row.' }
$required = @('CollectedAt','ComputerName','BitLockerProtectionStatus','FirewallDomainEnabled',
    'FirewallPrivateEnabled','FirewallPublicEnabled','DefenderRealtimeEnabled',
    'WindowsUpdateService','WindowsUpdateStartType','UpdatePolicyNoAutoUpdate')
foreach ($name in $required) {
    if ($rows[0].PSObject.Properties.Name -notcontains $name) { throw "Missing required CSV column: $name" }
}
if ($rows[0].ComputerName -ne $env:COMPUTERNAME) { throw 'Computer name mismatch.' }
foreach ($name in @('FirewallDomainEnabled','FirewallPrivateEnabled','FirewallPublicEnabled',
    'DefenderRealtimeEnabled')) {
    if ($rows[0].$name -notin @('True','False','Unavailable')) {
        throw "Invalid $name value in report."
    }
}
Write-Host 'TEST PASSED'
Write-Host "Compliance report: $($newReports[0].Name)"
