# Standalone Windows PowerShell 5.1 test
$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$serviceScript = Join-Path $root 'scripts\ServiceStatusCheck.ps1'
$reports = Join-Path $root 'reports'

# Verify service script exists
if (-not (Test-Path -LiteralPath $serviceScript -PathType Leaf)) {
    throw 'TEST FAILED: Service script missing.'
}

# Verify service script syntax
$tokens = $null
$parseErrors = $null

[void][System.Management.Automation.Language.Parser]::ParseFile(
    $serviceScript,
    [ref]$tokens,
    [ref]$parseErrors
)

if ($parseErrors.Count -gt 0) {
    throw 'TEST FAILED: Service script has syntax errors.'
}

# Prepare report directory
if (-not (Test-Path -LiteralPath $reports -PathType Container)) {
    New-Item -ItemType Directory -Path $reports | Out-Null
}

# Record existing reports; never delete them
$before = @(
    Get-ChildItem -LiteralPath $reports -Filter 'ServiceStatus_*.csv' -File |
        ForEach-Object { $_.FullName }
)

# Execute read-only service checker
& $serviceScript -OutputDirectory $reports | Out-Null

# Find newly created report
$new = @(
    Get-ChildItem -LiteralPath $reports -Filter 'ServiceStatus_*.csv' -File |
        Where-Object { $before -notcontains $_.FullName }
)

if ($new.Count -ne 1) {
    throw "TEST FAILED: Expected one new report, found $($new.Count)."
}

# Verify report records
$records = @(Import-Csv -LiteralPath $new[0].FullName)
$expected = @('wuauserv', 'BITS', 'WinDefend')

if ($records.Count -ne 3) {
    throw "TEST FAILED: Expected 3 records, found $($records.Count)."
}

for ($i = 0; $i -lt 3; $i++) {
    if ($records[$i].ServiceName -cne $expected[$i]) {
        throw "TEST FAILED: Unexpected service at row $($i + 1)."
    }
}

Write-Host 'TEST PASSED' -ForegroundColor Green
Write-Host "Verified CSV: $($new[0].FullName)"
