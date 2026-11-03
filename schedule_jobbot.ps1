param(
    [ValidateSet("Install", "Inspect", "Run", "Remove")]
    [string]$Action = "Install"
)

$ErrorActionPreference = "Stop"
$TaskName = "JobBot Daily Discovery"
$ProjectPath = (Resolve-Path $PSScriptRoot).Path
$PythonPath = Join-Path $ProjectPath ".venv\Scripts\python.exe"

switch ($Action) {
    "Install" {
        if (-not (Test-Path $PythonPath)) {
            throw "Virtual-environment Python not found at $PythonPath. Run setup_windows.bat first."
        }
        $taskAction = New-ScheduledTaskAction -Execute $PythonPath -Argument "-m jobbot.cli run" -WorkingDirectory $ProjectPath
        $trigger = New-ScheduledTaskTrigger -Daily -At "09:00"
        $settings = New-ScheduledTaskSettingsSet -StartWhenAvailable
        Register-ScheduledTask -TaskName $TaskName -Action $taskAction -Trigger $trigger -Settings $settings -Description "Discover jobs and generate JobBot reports; never opens or submits applications." -Force | Out-Null
        Write-Output "Installed '$TaskName' for 09:00 local time. The computer must be on and awake."
    }
    "Inspect" {
        Get-ScheduledTask -TaskName $TaskName | Get-ScheduledTaskInfo
    }
    "Run" {
        Start-ScheduledTask -TaskName $TaskName
        Write-Output "Started '$TaskName'. Inspect task state with -Action Inspect."
    }
    "Remove" {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Output "Removed '$TaskName'."
    }
}
