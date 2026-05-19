# Windows usage monitoring with PRTG Push sensor
Monitoring Windows usage (CPU, Memory, Disk Usage, Uptime) with HTTP Push Data Advanced PRTG Sensor
It works better than WMI and it's cheaper on the sensor cost

## Tested on
- Windows Server 2025 (built-in powershell)
- Windows 11 pro (built-in powershell)

## Setup 

Create a **HTTP Push Data Advanced** sensor in your PRTG and grab the **Identification Token**.

Download the script:
```powershell
$sourceUrl = "https://raw.githubusercontent.com/stylersnico/prtg-windows-usage-push-monitoring/refs/heads/main/windows-usage.ps1"
$destinationPath = "C:\_Scripts\windows-usage.ps1"
if (-Not (Test-Path -Path ([System.IO.Path]::GetDirectoryName($destinationPath)))) {
    New-Item -ItemType Directory -Force -Path ([System.IO.Path]::GetDirectoryName($destinationPath))
}
Invoke-WebRequest -Uri $sourceUrl -OutFile $destinationPath
```

Edit it to put your **PRTG IP** and **Identification token** at the end.

Create a scheduled task that send the data every minute:
```powershell
$taskName = "Windows_Usage_Monitor"
$scriptPath = "C:\_Scripts\windows-usage.ps1"
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$scriptPath`""
$trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Minutes 1) -RepetitionDuration (New-TimeSpan -Days 365)
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Description "Windows Usage Monitor Script" -User "SYSTEM"
```

When the data is in PRTG, edit the alerting if needed (default values are built-in).

## Screenshots
<img width="1952" height="842" alt="image" src="https://github.com/user-attachments/assets/191e2b65-ff50-4bd1-a099-d9c8bebdf94a" />

