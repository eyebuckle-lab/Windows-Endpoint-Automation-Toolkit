# EndpointAssessment.Tests.ps1
# Standalone integration test; runs six collectors and validates summary provenance.
# Does not remove or overwrite existing reports.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$assessment = Join-Path $root 'Run-EndpointAssessment.ps1'
$reports = Join-Path $root 'reports'

if (-not (Test-Path -LiteralPath $assessment -PathType Leaf)) {
    throw 'Assessment launcher missing.'
}
$tokens = $null
$errors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile(
    $assessment, [ref]$tokens, [ref]$errors
)
if ($errors.Count -gt 0) {
    throw "Assessment launcher has $($errors.Count) syntax error(s)."
}
$before = @(Get-ChildItem -LiteralPath $reports -Filter 'EndpointSummary_*.csv' -File |
    Select-Object -ExpandProperty FullName)
& $assessment | Out-Host
$newReports = @(Get-ChildItem -LiteralPath $reports -Filter 'EndpointSummary_*.csv' -File |
    Where-Object { $before -notcontains $_.FullName })
if ($newReports.Count -ne 1) {
    throw "Expected exactly one new summary; found $($newReports.Count)."
}
$rows = @(Import-Csv -LiteralPath $newReports[0].FullName -ErrorAction Stop)
if ($rows.Count -ne 1) { throw 'Expected one summary record.' }
foreach ($column in @('SourceServices','SourceInventory','SourceHealth',
    'SourceSoftware','SourceCompliance')) {
    if ([string]::IsNullOrWhiteSpace([string]$rows[0].$column) -or
        $rows[0].$column -eq 'Missing') {
        throw "Missing provenance at $column"
    }
}
Write-Host 'ASSESSMENT INTEGRATION TEST PASSED' -ForegroundColor Green
