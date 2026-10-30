# Get-EndpointCompliance.ps1
# Read-only Windows endpoint security posture snapshot; NOT a policy compliance verdict.
# Windows PowerShell 5.1; writes a new CSV only.
[CmdletBinding()]
param([string]$OutputDirectory)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $root 'reports'
}
if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
    throw "Reports directory missing: $OutputDirectory"
}

function Show-Value {
    param([object]$Value)
    if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) {
        return 'Unavailable'
    }
    return [string]$Value
}

# BitLocker may require elevation or may not exist on some Windows editions.
$bitLockerStatus = 'Unavailable'
$bitLockerProtection = 'Unavailable'
$bitLockerEncryptionPercent = 'Unavailable'
if (Get-Command Get-BitLockerVolume -ErrorAction SilentlyContinue) {
    try {
        $volume = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction Stop
        if ($null -ne $volume) {
            $bitLockerStatus = Show-Value $volume.VolumeStatus
            $bitLockerProtection = Show-Value $volume.ProtectionStatus
            $bitLockerEncryptionPercent = Show-Value $volume.EncryptionPercentage
        }
    }
    catch { Write-Warning 'BitLocker information unavailable for this account or system.' }
}

$firewall = @{ Domain = 'Unavailable'; Private = 'Unavailable'; Public = 'Unavailable' }
if (Get-Command Get-NetFirewallProfile -ErrorAction SilentlyContinue) {
    try {
        $profiles = @(Get-NetFirewallProfile -ErrorAction Stop)
        foreach ($profile in $profiles) {
            $key = [string]$profile.Name
            if ($firewall.ContainsKey($key)) {
                $firewall[$key] = Show-Value $profile.Enabled
            }
        }
    }
    catch { Write-Warning 'Windows Firewall profile information unavailable.' }
}

$defenderRealtime = 'Unavailable'
$defenderAntivirus = 'Unavailable'
$defenderSignatureDate = 'Unavailable'
if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue) {
    try {
        $defender = Get-MpComputerStatus -ErrorAction Stop
        $defenderRealtime = Show-Value $defender.RealTimeProtectionEnabled
        $defenderAntivirus = Show-Value $defender.AntivirusEnabled
        if ($null -ne $defender.AntivirusSignatureLastUpdated) {
            $defenderSignatureDate = $defender.AntivirusSignatureLastUpdated.ToString('yyyy-MM-dd HH:mm:ss')
        }
    }
    catch { Write-Warning 'Defender information unavailable.' }
}

$updateStatus = 'Unavailable'
$updateStartType = 'Unavailable'
try {
    $updateService = Get-Service -Name 'wuauserv' -ErrorAction Stop
    $updateStatus = Show-Value $updateService.Status
    $updateStartType = Show-Value $updateService.StartType
}
catch { Write-Warning 'Windows Update service information unavailable.' }

# This registry value is optional and is not a complete assessment of update compliance.
$noAutoUpdatePolicy = 'NotConfigured'
try {
    $policy = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' `
        -Name 'NoAutoUpdate' -ErrorAction Stop
    $noAutoUpdatePolicy = Show-Value $policy.NoAutoUpdate
}
catch [System.Management.Automation.ItemNotFoundException] { }
catch { $noAutoUpdatePolicy = 'Unavailable' }

$result = [PSCustomObject]@{
    CollectedAt                  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    ComputerName                 = $env:COMPUTERNAME
    BitLockerVolumeStatus        = $bitLockerStatus
    BitLockerProtectionStatus    = $bitLockerProtection
    BitLockerEncryptionPercent   = $bitLockerEncryptionPercent
    FirewallDomainEnabled       = $firewall.Domain
    FirewallPrivateEnabled      = $firewall.Private
    FirewallPublicEnabled       = $firewall.Public
    DefenderRealtimeEnabled     = $defenderRealtime
    DefenderAntivirusEnabled     = $defenderAntivirus
    DefenderSignatureDate       = $defenderSignatureDate
    WindowsUpdateService        = $updateStatus
    WindowsUpdateStartType      = $updateStartType
    UpdatePolicyNoAutoUpdate    = $noAutoUpdatePolicy
}

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss_fff'
$suffix = [guid]::NewGuid().ToString('N').Substring(0, 8)
$csvPath = Join-Path $OutputDirectory "EndpointCompliance_${stamp}_${suffix}.csv"
if (Test-Path -LiteralPath $csvPath) { throw "Refusing to overwrite report: $csvPath" }
$result | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
$verified = @(Import-Csv -LiteralPath $csvPath -ErrorAction Stop)
if ($verified.Count -ne 1) { throw 'CSV verification failed: expected one row.' }
Write-Host 'ENDPOINT COMPLIANCE SNAPSHOT CREATED'
Write-Host "Report: $csvPath"
Write-Host 'Note: This is a configuration snapshot, not a compliance/pass-fail verdict.'
