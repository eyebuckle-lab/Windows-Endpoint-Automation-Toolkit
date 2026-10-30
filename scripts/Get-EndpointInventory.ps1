# Endpoint Inventory - Windows PowerShell 5.1
# Read-only Windows inventory and CSV export

[CmdletBinding()]
param(
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'

$toolkitRoot = Split-Path -Parent $PSScriptRoot

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $toolkitRoot 'reports'
}

if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
    throw "Reports directory not found: $OutputDirectory"
}

function Read-InventoryCim {
    param(
        [string]$ClassName,
        [string]$Filter
    )

    try {
        if ([string]::IsNullOrWhiteSpace($Filter)) {
            Get-CimInstance -ClassName $ClassName -ErrorAction Stop |
                Select-Object -First 1
        }
        else {
            Get-CimInstance -ClassName $ClassName -Filter $Filter -ErrorAction Stop |
                Select-Object -First 1
        }
    }
    catch {
        Write-Warning "Could not read $ClassName : $($_.Exception.Message)"
    }
}

function Get-InventoryText {
    param($Value)

    if ($null -eq $Value -or
        [string]::IsNullOrWhiteSpace([string]$Value)) {
        return 'Unavailable'
    }

    return [string]$Value
}

$computer = Read-InventoryCim 'Win32_ComputerSystem'
$os = Read-InventoryCim 'Win32_OperatingSystem'
$bios = Read-InventoryCim 'Win32_BIOS'
$cpu = Read-InventoryCim 'Win32_Processor'

$driveFilter = "DeviceID='$($env:SystemDrive)'"
$disk = Read-InventoryCim 'Win32_LogicalDisk' $driveFilter

$ramGB = $null
$totalDiskGB = $null
$freeDiskGB = $null

if ($null -ne $computer.TotalPhysicalMemory) {
    $ramGB = [math]::Round(
        [double]$computer.TotalPhysicalMemory / 1GB, 2
    )
}

if ($null -ne $disk.Size) {
    $totalDiskGB = [math]::Round(
        [double]$disk.Size / 1GB, 2
    )
}

if ($null -ne $disk.FreeSpace) {
    $freeDiskGB = [math]::Round(
        [double]$disk.FreeSpace / 1GB, 2
    )
}

$inventory = [PSCustomObject]@{
    CollectedAt  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    ComputerName = $env:COMPUTERNAME
    Manufacturer = Get-InventoryText $computer.Manufacturer
    Model        = Get-InventoryText $computer.Model
    SerialNumber = Get-InventoryText $bios.SerialNumber
    WindowsName  = Get-InventoryText $os.Caption
    WindowsVersion = Get-InventoryText $os.Version
    WindowsBuild = Get-InventoryText $os.BuildNumber
    Processor    = Get-InventoryText $cpu.Name
    RAM_GB       = $ramGB
    SystemDrive  = $env:SystemDrive
    DriveTotalGB = $totalDiskGB
    DriveFreeGB  = $freeDiskGB
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss_fff'
$csvPath = Join-Path $OutputDirectory "EndpointInventory_$timestamp.csv"

if (Test-Path -LiteralPath $csvPath) {
    throw "CSV already exists: $csvPath"
}

$inventory | Export-Csv -LiteralPath $csvPath `
    -NoTypeInformation -Encoding UTF8 -ErrorAction Stop

Write-Host 'INVENTORY EXPORT COMPLETED' -ForegroundColor Green
Write-Host "Saved to: $csvPath"
