# Service Status Check - PowerShell 5.1
# Read-only service inspection and CSV export

[CmdletBinding()]
param(
    [string]$OutputDirectory = [Environment]::GetFolderPath('MyDocuments')
)

$ErrorActionPreference = 'Stop'
$serviceNames = @('wuauserv', 'BITS', 'WinDefend')

if (-not (Test-Path -LiteralPath $OutputDirectory -PathType Container)) {
    throw "Output directory does not exist: $OutputDirectory"
}

$results = @(
    foreach ($name in $serviceNames) {
        try {
            $service = Get-Service -Name $name -ErrorAction Stop

            [PSCustomObject]@{
                ComputerName = $env:COMPUTERNAME
                CheckedAt    = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                ServiceName  = $name
                Status       = [string]$service.Status
                StartType    = [string]$service.StartType
                Error        = ''
            }
        }
        catch {
            [PSCustomObject]@{
                ComputerName = $env:COMPUTERNAME
                CheckedAt    = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                ServiceName  = $name
                Status       = 'Error'
                StartType    = 'N/A'
                Error        = $_.Exception.Message
            }
        }
    }
)

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss_fff'
$csvPath = Join-Path $OutputDirectory "ServiceStatus_$timestamp.csv"

$results | Export-Csv -LiteralPath $csvPath -NoTypeInformation -Encoding UTF8

$verified = @(Import-Csv -LiteralPath $csvPath)

if ($verified.Count -ne 3) {
    throw "CSV verification failed: expected 3 records."
}

Write-Host "CSV verification passed." -ForegroundColor Green
Write-Host "Saved to: $csvPath"
$results | Format-Table -AutoSize
