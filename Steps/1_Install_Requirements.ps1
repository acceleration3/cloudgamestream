Param([Parameter(Mandatory=$false)] [Switch]$Main)

If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Arguments = "& '" + $MyInvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $Arguments
    Break
}

$WorkDir = "$PSScriptRoot\..\Bin"
$Desktop = "C:\Administrator\Desktop"

Function Download-File([string]$Url, [string]$Path, [string]$Name) {
    try {
        if(![System.IO.File]::Exists($Path)) {
	        Write-Host "Downloading `"$Name`"..."
	        Start-BitsTransfer $Url $Path
        }
    } catch {
        throw "`"$Name`" download failed."
    }
}

Import-Module BitsTransfer

$InstallAudio = (Read-Host "You need to have an audio interface installed for GameStream to work. Install VBCABLE? (y/n)").ToLower() -eq "y"
$InstallVideo = (Read-Host "This script will also install the Parsec GPU Updater tool, unless you already have drivers, please type y (y/n)").ToLower() -eq "y"

Download-File "https://open-stream.net/openstream_alpha_2312.1.exe" "$WorkDir\openstream.exe" "Openstream"
Download-File "https://aka.ms/vs/16/release/vc_redist.x64.exe" "$WorkDir\redist.exe" "Visual C++ Redist"
if($InstallAudio) { Download-File "https://download.vb-audio.com/Download_CABLE/VBCABLE_Driver_Pack43.zip" "$WorkDir\vbcable.zip" "VBCABLE" }
if($InstallVideo) {
        Write-Host "Beginning to install the Parsec tool..." -ForegroundColor Red
        $UseExternalScript = (Read-Host "Please verify you want to install the Parsec tool (y/n)").ToLower() -eq "y"
        if($UseExternalScript) {
            $Shell = New-Object -comObject WScript.Shell
            $Shortcut = $Shell.CreateShortcut("$Home\Desktop\Continue.lnk")
            $Shortcut.TargetPath = "powershell.exe"
            $Shortcut.Arguments = "-Command `"Set-ExecutionPolicy Unrestricted; & '$PSScriptRoot\..\Setup.ps1'`" -RebootSkip"
            $Shortcut.Save()
            Download-File "https://github.com/jamesstringerparsec/Cloud-GPU-Updater/archive/master.zip" "Desktop\updater.zip" "Cloud GPU Updater"
        }    
}

Write-Host "Installing Openstream..."

$ExitCode = (Start-Process -FilePath "$WorkDir\openstream.exe" -ArgumentList "-s" -NoNewWindow -Wait -Passthru).ExitCode
if($ExitCode -eq 0) { Write-Host "Installed." -ForegroundColor Green }
else { 
    throw "Installation failed (Error: $ExitCode)."
}

Write-Host "Installing Visual C++ Redist..."

$ExitCode = (Start-Process -FilePath "$WorkDir\redist.exe" -ArgumentList "/install","/quiet","/norestart" -NoNewWindow -Wait -Passthru).ExitCode
if($ExitCode -eq 0) { Write-Host "Installed." -ForegroundColor Green }
elseif($ExitCode -eq 1638) { Write-Host "Newer version already installed." -ForegroundColor Green }
else { 
    throw "Installation failed (Error: $ExitCode)."
}

if($InstallAudio) {
    Write-Host "Installing VBCABLE..."
    Expand-Archive -Path "$WorkDir\vbcable.zip" -DestinationPath "$WorkDir\vbcable"
    Start-Process -FilePath "$WorkDir\vbcable\VBCABLE_Setup_x64.exe" -ArgumentList "-i","-h" -NoNewWindow -Wait

    $osType = Get-CimInstance -ClassName Win32_OperatingSystem
}
