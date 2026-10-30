# Endpoint Health Diagnostics
# Windows PowerShell 5.1 - Read-only

[CmdletBinding()]
param(
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $root 'reports'
}

if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
    throw "Reports directory not found: $OutputDirectory"
}

function Get-ServiceState {
    param([string]$Name)

    try {
        return [string](Get-Service -Name $Name -ErrorAction Stop).Status
    }
    catch {
        return 'Unavailable'
    }
}

# Read Windows uptime and system-drive information
$os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop

$disk = Get-CimInstance Win32_LogicalDisk `
    -Filter "DeviceID='$($env:SystemDrive)'" `
    -ErrorAction Stop

$uptimeDays = $null
$freeGB = $null
$freePercent = $null

if ($os.LastBootUpTime) {
    $uptimeDays = [math]::Round(
        ((Get-Date) - $os.LastBootUpTime).TotalDays, 2
    )
}

if ($null -ne $disk -and $disk.Size -gt 0) {
    $freeGB = [math]::Round([double]$disk.FreeSpace / 1GB, 2)
    $freePercent = [math]::Round(
        ([double]$disk.FreeSpace / [double]$disk.Size) * 100, 2
    )
}

# Defender details may be unavailable on some computers
$realtimeProtection = 'Unavailable'
$signatureUpdated = 'Unavailable'

if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue) {
    try {
        $defender = Get-MpComputerStatus -ErrorAction Stop
        $realtimeProtection = [string]$defender.RealTimeProtectionEnabled

        if ($defender.AntivirusSignatureLastUpdated) {
            $signatureUpdated = $defender.AntivirusSignatureLastUpdated.ToString(
                'yyyy-MM-dd HH:mm:ss'
            )
        }
    }
    catch {
        Write-Warning "Defender information is unavailable."
    }
}

$health = [PSCustomObject]@{
    CollectedAt            = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    ComputerName           = $env:COMPUTERNAME
    UptimeDays             = $uptimeDays
    WindowsUpdateService   = Get-ServiceState 'wuauserv'
    BITSService            = Get-ServiceState 'BITS'
    DefenderService        = Get-ServiceState 'WinDefend'
    DefenderRealtime       = $realtimeProtection
    DefenderSignatureDate  = $signatureUpdated
    SystemDrive            = $env:SystemDrive
    DriveFreeGB            = $freeGB
    DriveFreePercent       = $freePercent
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss_fff'
$csvPath = Join-Path $OutputDirectory "EndpointHealth_$timestamp.csv"

if (Test-Path -LiteralPath $csvPath) {
    throw "Report already exists: $csvPath"
}

$health | Export-Csv -LiteralPath $csvPath `
    -NoTypeInformation -Encoding UTF8 -ErrorAction Stop

Write-Host "ENDPOINT HEALTH REPORT CREATED" -ForegroundColor Green
Write-Host "Saved to: $csvPath"
