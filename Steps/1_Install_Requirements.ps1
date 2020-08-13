Param([Parameter(Mandatory=$false)] [Switch]$Main)

If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Arguments = "& '" + $MyInvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $Arguments
    Break
}

if($Main -eq $true) {
    $WorkDir = ".\Bin"
} else {
    $WorkDir = "..\Bin"
}

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
$InstallVideo = (Read-Host "You also need the NVIDIA GRID Drivers installed. Installing will reboot your machine. Install the tested and recommended ones? (y/n)").ToLower() -eq "y"

Download-File "https://us.download.nvidia.com/GFE/GFEClient/3.13.0.85/GeForce_Experience_Beta_v3.13.0.85.exe" "$WorkDir\GFE.exe" "GeForce Experience"
Download-File "https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x86.exe" "$WorkDir\redist.exe" "Visual C++ Redist 2015 x86"
if($InstallAudio -eq $true) { Download-File "https://download.vb-audio.com/Download_CABLE/VBCABLE_Driver_Pack43.zip" "$WorkDir\vbcable.zip" "VBCABLE" }
if($InstallVideo -eq $true) { Download-File "https://download.microsoft.com/download/b/8/f/b8f5ecec-b8f9-47de-b007-ac40adc88dc8/442.06_grid_win10_64bit_international_whql.exe" "$WorkDir\Drivers.exe" "NVIDIA GRID Drivers" }

Write-Host "Installing GeForce Experience..."

$ExitCode = (Start-Process -FilePath "$WorkDir\GFE.exe" -ArgumentList "-s" -NoNewWindow -Wait -Passthru).ExitCode
if($ExitCode -eq 0) { Write-Host "Installed." -ForegroundColor Green }
else { 
    throw "GeForce Experience installation failed (Error: $ExitCode)."
}

Write-Host "Installing Visual C++ Redist 2015 x86..."

$ExitCode = (Start-Process -FilePath "$WorkDir\redist.exe" -ArgumentList "/install","/quiet","/norestart" -NoNewWindow -Wait -Passthru).ExitCode
if($ExitCode -eq 0) { Write-Host "Installed." -ForegroundColor Green }
elseif($ExitCode -eq 1638) { Write-Host "Newer version already installed." -ForegroundColor Green }
else { 
    throw "Visual C++ Redist 2015 x86 installation failed (Error: $ExitCode)."
}

if($InstallAudio -eq $true) {
    Write-Host "Installing VBCABLE..."
    Expand-Archive -Path "$WorkDir\vbcable.zip" -DestinationPath "$WorkDir\vbcable"
    Start-Process -FilePath "$WorkDir\vbcable\VBCABLE_Setup_x64.exe" -ArgumentList "-i","-h" -NoNewWindow -Wait

    $osType = Get-CimInstance -ClassName Win32_OperatingSystem

    if($osType.ProductType -eq 3) {
        Write-Host "Applying Audio service fix for Windows Server..."
        New-ItemProperty "hklm:\SYSTEM\CurrentControlSet\Control" -Name "ServicesPipeTimeout" -Value 600000 -PropertyType "DWord" | Out-Null
        Set-Service -Name Audiosrv -StartupType Automatic | Out-Null
    }
}

if($InstallVideo -eq $true) {
    Write-Host "Installing NVIDIA GRID GPU drivers... Your machine will reboot after installing."
    $directory = [string](Get-Location);
    $script = "-Command `"Set-ExecutionPolicy Unrestricted; & " + $directory + "\Setup.ps1`" -RebootSkip";
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $script -WorkingDirectory $directory
    $trigger = New-ScheduledTaskTrigger -AtLogon -RandomDelay "00:00:30"
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "GSSetup" -Description "GSSetup" | Out-Null
    $ExitCode = (Start-Process -FilePath "$WorkDir\Drivers.exe" -ArgumentList "-s","-clean" -NoNewWindow -Wait -PassThru).ExitCode
    if($ExitCode -eq 0) {
        Write-Host "NVIDIA GRID GPU drivers installed. The script will now restart the machine." -ForegroundColor Green 
        Restart-Computer -Force
    } else {
        throw "NVIDIA GRID GPU driver instalation failed."
    }
}