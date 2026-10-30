# Windows PowerShell 5.1; reads uninstall registry entries only.
# Does not use Win32_Product or make system changes.
[CmdletBinding()]
param([string]$OutputDirectory)
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path (Split-Path -Parent $PSScriptRoot) 'reports'
}
if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
    throw "Report directory not found: $OutputDirectory"
}

$uninstall = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
$sources = @(
    @{Path="Registry::HKEY_LOCAL_MACHINE\$uninstall"; Scope='Machine'; Architecture='64-bit'},
    @{Path="Registry::HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"; Scope='Machine'; Architecture='32-bit'},
    @{Path="Registry::HKEY_CURRENT_USER\$uninstall"; Scope='CurrentUser'; Architecture='64-bit'},
    @{Path="Registry::HKEY_CURRENT_USER\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"; Scope='CurrentUser'; Architecture='32-bit'}
)
$collectedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$rows = @(
    foreach ($source in $sources) {
        if (-not (Test-Path -LiteralPath $source.Path)) { continue }
        try { $keys = @(Get-ChildItem -LiteralPath $source.Path -ErrorAction Stop) }
        catch {
            Write-Warning "Cannot enumerate $($source.Path): $($_.Exception.Message)"
            continue
        }
        foreach ($key in $keys) {
            try {
                $app = Get-ItemProperty -LiteralPath $key.PSPath -ErrorAction Stop
                $name = [string]$app.DisplayName
                if ([string]::IsNullOrWhiteSpace($name)) { continue }
                if ([string]$app.SystemComponent -eq '1') { continue }
                [PSCustomObject]@{
                    CollectedAt = $collectedAt
                    ComputerName = $env:COMPUTERNAME
                    Name = $name.Trim()
                    Version = [string]$app.DisplayVersion
                    Publisher = [string]$app.Publisher
                    InstallDate = [string]$app.InstallDate
                    Scope = $source.Scope
                    Architecture = $source.Architecture
                    RegistryKey = [string]$key.Name
                }
            }
            catch { Write-Warning "Cannot read $($key.Name): $($_.Exception.Message)" }
        }
    }
)
if ($rows.Count -eq 0) { throw 'No installed-program registry records found.' }

$stamp = Get-Date -Format 'yyyyMMdd_HHmmss_fff'
$suffix = [guid]::NewGuid().ToString('N').Substring(0, 6)
$csv = Join-Path $OutputDirectory "SoftwareInventory_${stamp}_${suffix}.csv"
if (Test-Path -LiteralPath $csv) { throw "Report already exists: $csv" }
$rows | Sort-Object Name, Version, Scope, Architecture |
    Export-Csv -LiteralPath $csv -NoTypeInformation -Encoding UTF8 -ErrorAction Stop
Write-Host 'SOFTWARE INVENTORY CREATED'
Write-Host "Records: $($rows.Count)"
Write-Host "Report: $csv"
