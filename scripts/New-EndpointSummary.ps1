# New-EndpointSummary.ps1
# Combines latest CSV reports into one inventory snapshot. Does not run diagnostics.
# Source reports may have different timestamps; inspect Source* columns.
[CmdletBinding()]
param([string]$OutputDirectory)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$reportDir = Join-Path $root 'reports'
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) { $OutputDirectory = $reportDir }
if (-not (Test-Path -LiteralPath $reportDir -PathType Container)) {
    throw "Source report directory missing: $reportDir"
}
if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
    throw "Output directory missing: $OutputDirectory"
}

function Get-LatestReport {
    param([string]$Pattern)
    @(Get-ChildItem -LiteralPath $reportDir -Filter $Pattern -File -ErrorAction Stop |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1) |
        Select-Object -First 1
}
function Get-FirstRow {
    param($File)
    if ($null -eq $File) { return $null }
    $rows = @(Import-Csv -LiteralPath $File.FullName -ErrorAction Stop)
    if ($rows.Count -lt 1) { return $null }
    return $rows[0]
}
function Get-Field {
    param($Row, [string]$FieldName)
    if ($null -eq $Row) { return 'Unavailable' }
    $property = $Row.PSObject.Properties[$FieldName]
    if ($null -eq $property -or [string]::IsNullOrWhiteSpace([string]$property.Value)) {
        return 'Unavailable'
    }
    return [string]$property.Value
}
function Get-SourceName {
    param($File)
    if ($null -eq $File) { return 'Missing' }
    return [string]$File.Name
}

$inventoryFile = Get-LatestReport 'EndpointInventory_*.csv'
$healthFile = Get-LatestReport 'EndpointHealth_*.csv'
$serviceFile = Get-LatestReport 'ServiceStatus_*.csv'
$softwareFile = Get-LatestReport 'SoftwareInventory_*.csv'
$complianceFile = Get-LatestReport 'EndpointCompliance_*.csv'

$inventory = Get-FirstRow $inventoryFile
$health = Get-FirstRow $healthFile
$compliance = Get-FirstRow $complianceFile
$softwareCount = 'Unavailable'
if ($null -ne $softwareFile) {
    $softwareRows = @(Import-Csv -LiteralPath $softwareFile.FullName -ErrorAction Stop)
    $softwareCount = [string]$softwareRows.Count
}
$serviceRows = @()
if ($null -ne $serviceFile) {
    $serviceRows = @(Import-Csv -LiteralPath $serviceFile.FullName -ErrorAction Stop)
}
$windowsUpdateAudit = @($serviceRows | Where-Object { $_.ServiceName -eq 'wuauserv' } | Select-Object -First 1)
$bitsAudit = @($serviceRows | Where-Object { $_.ServiceName -eq 'BITS' } | Select-Object -First 1)
$defenderAudit = @($serviceRows | Where-Object { $_.ServiceName -eq 'WinDefend' } | Select-Object -First 1)
$windowsUpdateAuditRow = if ($windowsUpdateAudit.Count -gt 0) { $windowsUpdateAudit[0] } else { $null }
$bitsAuditRow = if ($bitsAudit.Count -gt 0) { $bitsAudit[0] } else { $null }
$defenderAuditRow = if ($defenderAudit.Count -gt 0) { $defenderAudit[0] } else { $null }

# No sensitive serial numbers or individual software titles in the combined CSV.
$summary = [PSCustomObject]@{
    SummaryCreatedAt           = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    ComputerName               = $env:COMPUTERNAME
    WindowsName                = Get-Field $inventory 'WindowsName'
    WindowsBuild               = Get-Field $inventory 'WindowsBuild'
    RAM_GB                     = Get-Field $inventory 'RAM_GB'
    UptimeDays                 = Get-Field $health 'UptimeDays'
    DriveFreeGB                = Get-Field $health 'DriveFreeGB'
    DriveFreePercent           = Get-Field $health 'DriveFreePercent'
    WindowsUpdateService       = Get-Field $health 'WindowsUpdateService'
    BITSService                = Get-Field $health 'BITSService'
    ServiceAuditWindowsUpdate  = Get-Field $windowsUpdateAuditRow 'Status'
    ServiceAuditBITS           = Get-Field $bitsAuditRow 'Status'
    ServiceAuditDefender       = Get-Field $defenderAuditRow 'Status'
    DefenderRealtime          = Get-Field $health 'DefenderRealtime'
    BitLockerProtectionStatus  = Get-Field $compliance 'BitLockerProtectionStatus'
    FirewallDomainEnabled     = Get-Field $compliance 'FirewallDomainEnabled'
    FirewallPrivateEnabled    = Get-Field $compliance 'FirewallPrivateEnabled'
    FirewallPublicEnabled     = Get-Field $compliance 'FirewallPublicEnabled'
    SoftwareRecordCount        = $softwareCount
    SourceInventory            = Get-SourceName $inventoryFile
    SourceHealth               = Get-SourceName $healthFile
    SourceServices             = Get-SourceName $serviceFile
    SourceSoftware             = Get-SourceName $softwareFile
    SourceCompliance           = Get-SourceName $complianceFile
}

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss_fff'
$suffix = [guid]::NewGuid().ToString('N').Substring(0, 8)
$csvPath = Join-Path $OutputDirectory "EndpointSummary_${stamp}_${suffix}.csv"
if (Test-Path -LiteralPath $csvPath) { throw "Refusing to overwrite report: $csvPath" }
$summary | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
$verified = @(Import-Csv -LiteralPath $csvPath -ErrorAction Stop)
if ($verified.Count -ne 1) { throw 'Summary CSV verification failed.' }
Write-Host 'UNIFIED ENDPOINT SUMMARY CREATED'
Write-Host "Report: $csvPath"
Write-Host 'Note: Values are from the latest available reports, not one synchronized collection.'
