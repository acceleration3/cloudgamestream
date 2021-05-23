Param([Parameter(Mandatory=$false)] [Switch]$RebootSkip)

If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Arguments = "& '" + $MyInvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $Arguments
    Break
}

function Write-HostCenter { param($Message) Write-Host ("{0}{1}" -f (' ' * (([Math]::Max(0, $Host.UI.RawUI.BufferSize.Width / 2) - [Math]::Floor($Message.Length / 2)))), $Message) }

Start-Transcript -Path "$PSScriptRoot\Log.txt"

clear

Write-HostCenter "Openstream Automatic Installer 3000"
Write-HostCenter "Stolen, I mean forked, from acceleration3"
Write-Host ""

try {

    if([bool]((quser) -imatch "rdp")) {
        throw "You are running a Microsoft RDP session, please use Anydesk and change your password"
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
    Write-Host "Step 2 - Applying fixes" -ForegroundColor Yellow
    & $PSScriptRoot\Steps\2_Apply_Fixes.ps1

    Write-Host ""
    Write-Host "Finished! Please head back to the README on GitHub or continue with the guide you're following" -ForegroundColor DarkGreen

    $restart = (Read-Host "Would you like to restart now? (y/n)").ToLower();
    if($restart -eq "y") {
        Restart-Computer -Force 
    }
} catch {
    Write-Host $_.Exception -ForegroundColor Red
    Stop-Transcript
    Pause
}
