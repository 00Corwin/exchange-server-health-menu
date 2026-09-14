<#
.SYNOPSIS
    Menu-driven Exchange Server health checker for two configurable regions.

.DESCRIPTION
    PowerShell 5.1-compatible script intended to run in the Exchange Management
    Shell. It preserves the original menu behaviour: region selection, a
    timestamp on each run, Q to quit, and a loop for invalid selections.

    Edit the placeholder server arrays before use.
#>

[CmdletBinding()]
param()

$Regions = [ordered]@{
    '1' = @{
        Name    = 'Region-A'
        Servers = @('EXA01','EXA02')
    }
    '2' = @{
        Name    = 'Region-B'
        Servers = @('EXB01','EXB02')
    }
}

function Invoke-ExchangeHealthCheck {
    param(
        [Parameter(Mandatory)]
        [string]$RegionName,

        [Parameter(Mandatory)]
        [string[]]$Servers
    )

    Write-Host ''
    Write-Host ('=' * 72)
    Write-Host "Exchange health check: $RegionName"
    Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host ('=' * 72)

    foreach ($Server in $Servers) {
        Write-Host ''
        Write-Host "[$Server]" -ForegroundColor Cyan

        try {
            $ExchangeServer = Get-ExchangeServer -Identity $Server -ErrorAction Stop
            Write-Host "Role: $($ExchangeServer.ServerRole)"
        }
        catch {
            Write-Warning "Unable to query Exchange server '$Server': $($_.Exception.Message)"
            continue
        }

        if (Get-Command Test-ServiceHealth -ErrorAction SilentlyContinue) {
            Write-Host 'Exchange services:'
            Test-ServiceHealth -Server $Server |
                Select-Object Role,
                    @{Name='RequiredServicesRunning';Expression={ $_.ServicesNotRunning.Count -eq 0 }},
                    ServicesNotRunning |
                Format-Table -AutoSize
        }

        if (Get-Command Get-MailboxDatabaseCopyStatus -ErrorAction SilentlyContinue) {
            Write-Host 'Mailbox database copies:'
            Get-MailboxDatabaseCopyStatus -Server $Server |
                Select-Object Name, Status, CopyQueueLength, ReplayQueueLength |
                Format-Table -AutoSize
        }

        if (Get-Command Get-Queue -ErrorAction SilentlyContinue) {
            Write-Host 'Transport queues:'
            Get-Queue -Server $Server |
                Select-Object Identity, Status, MessageCount, NextHopDomain |
                Format-Table -AutoSize
        }
    }
}

while ($true) {
    Write-Host ''
    Write-Host 'Exchange Health'
    Write-Host '1. Region-A'
    Write-Host '2. Region-B'
    Write-Host 'Q. Quit'

    $Selection = (Read-Host 'Select an option').Trim()

    if ($Selection -match '^[Qq]$') {
        break
    }

    if ($Regions.Contains($Selection)) {
        $Region = $Regions[$Selection]
        Invoke-ExchangeHealthCheck `
            -RegionName $Region.Name `
            -Servers $Region.Servers
    }
    else {
        Write-Warning "Invalid selection '$Selection'. Enter 1, 2 or Q."
    }
}
