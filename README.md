# Exchange Server Health Menu

A PowerShell 5.1-compatible, menu-driven health checker for on-premises
Exchange Server.

This repository is **reconstructed from the earlier conversation requirements**
rather than copied verbatim from a retained source file. The recovered
requirements were: two regional choices, timestamped output, a quit option and
an invalid-selection loop.

## Before use

Edit the placeholder arrays in `Exchange-HealthMenu.ps1`:

```powershell
Servers = @('EXA01','EXA02')
```

Run the script from the Exchange Management Shell, or a PowerShell session with
the relevant Exchange cmdlets loaded.

The script checks Exchange service health, mailbox database copy state and
transport queues when those cmdlets are available.
