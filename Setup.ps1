Param([Parameter(Mandatory=$false)] [Switch]$RebootSkip)

If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Arguments = "& '" + $MyInvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $Arguments
    Break
}

function Write-HostCenter { param($Message) Write-Host ("{0}{1}" -f (' ' * (([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width / 2) - [Math]::Floor($Message.Length / 2)))), $Message) }

Start-Transcript -Path "Log.txt"
Set-Location -Path $PSScriptRoot

clear

Write-HostCenter "Cloud based GameStream Preparation Tool" -ForegroundColor Yellow
Write-HostCenter "by acceleration3" -ForegroundColor Yellow
Write-Host ""

if($RebootSkip -eq $false) {
    Write-Host "Your computer will restart at least once during this setup."
    Write-Host ""
    Write-Host "WARNING: Using Microsoft Remote Desktop will create a virtual monitor separate from the one running the NVIDIA GPU and prevent GeForce Experience from enabling the GameStream feature! You need to use another type of Remote Desktop solution such as AnyDesk or TeamViewer!" -ForegroundColor Red
    Write-Host ""

    $InstallAudio = (Read-Host "You need to have an audio interface installed for GameStream to work. Install VBCABLE? (y/n)").ToLower();
    $InstallDrivers = (Read-Host "You also need the NVIDIA GRID Drivers installed. Installing will reboot your machine. Install the tested and recommended ones? (y/n)").ToLower();

    Write-Host ""

    Write-Host "Step 1 - Installing requirements..." -ForegroundColor DarkGreen
    & .\Steps\1_Install_Requirements.ps1 -Main

    if($InstallAudio -eq "y") { & .\Steps\1_opt_Install_VBCABLE.ps1 -Main }

    if($InstallDrivers -eq "y") {
        $directory = [string](Get-Location);
        $script = "-Command `"Set-ExecutionPolicy Unrestricted; & " + $directory + "\Setup.ps1`" -RebootSkip";
        $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $script -WorkingDirectory $directory
        $trigger = New-ScheduledTaskTrigger -AtLogon -RandomDelay "00:00:30"
        Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "GSSetup" -Description "GSSetup" | Out-Null
        & .\Steps\1_opt_Install_Drivers.ps1 -Main
        Restart-Computer -Force
    }
} else {
    Unregister-ScheduledTask -TaskName "GSSetup" -Confirm:$false
    Write-Host "The script will now continue from where it left off."
    Pause
}

Write-Host "Step 2 - Patching GeForce Experience..." -ForegroundColor DarkGreen
& .\Steps\2_Patch_GFE.ps1 -Main

Write-Host "Step 3 - Disabling Hyper-V Monitor and other GPUs..." -ForegroundColor DarkGreen
& .\Steps\3_Disable_Other_GPUs.ps1 -Main

Write-Host "Step 4 - Applying fixes..." -ForegroundColor DarkGreen
& .\Steps\4_Apply_Fixes.ps1 -Main

Write-Host "Done. You should now be able to use GameStream after you restart your computer." -ForegroundColor DarkGreen
$restart = (Read-Host "Would you like to restart now? (y/n)").ToLower();

if($restart -eq "y")  {
    Restart-Computer -Force
}
