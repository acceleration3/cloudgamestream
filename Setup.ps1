Param([Parameter(Mandatory=$false)] [Switch]$RebootSkip)

If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Arguments = "& '" + $MyInvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $Arguments
    Break
}

function Write-HostCenter { param($Message) Write-Host ("{0}{1}" -f (' ' * (([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width / 2) - [Math]::Floor($Message.Length / 2)))), $Message) }

Start-Transcript -Path "$PSScriptRoot\Log.txt"

clear

Write-HostCenter "Cloud based GameStream Preparation Tool"
Write-HostCenter "by acceleration3"
Write-Host ""

try {

    if([bool]((quser) -imatch "rdp")) {
        throw "You are running a Microsoft RDP session which will not work to enable GameStream! You need to install a different Remote Desktop software like AnyDesk or TeamViewer!"
    }

    if(!$RebootSkip) {
        Write-Host "Your machine will restart at least once during this setup."
        Write-Host ""
        Write-Host "Step 1 - Installing requirements" -ForegroundColor Yellow
        & $PSScriptRoot\Steps\1_Install_Requirements.ps1 -Main
    } else {
	
        if(Get-ScheduledTask | Where-Object {$_.TaskName -like "GSSetup" }) {
            Unregister-ScheduledTask -TaskName "GSSetup" -Confirm:$false
        }
        Write-Host "The script will now continue from where it left off."
        Pause
    }

    Write-Host ""
    Write-Host "Step 2 - Patching GeForce Experience" -ForegroundColor Yellow
    & $PSScriptRoot\Steps\2_Patch_GFE.ps1

    Write-Host ""
    Write-Host "Step 3 - Disabling Hyper-V Monitor and other GPUs" -ForegroundColor Yellow
    & $PSScriptRoot\Steps\3_Disable_Other_GPUs.ps1

    Write-Host ""
    Write-Host "Step 4 - Applying fixes" -ForegroundColor Yellow
    & $PSScriptRoot\Steps\4_Apply_Fixes.ps1

    Write-Host ""
    Write-Host "Done. You should now be able to use GameStream after you restart your machine." -ForegroundColor DarkGreen

    $restart = (Read-Host "Would you like to restart now? (y/n)").ToLower();
    if($restart -eq "y") {
        Restart-Computer -Force 
    }
} catch {
    Write-Host $_.Exception -ForegroundColor Red
    Stop-Transcript
    Pause
}