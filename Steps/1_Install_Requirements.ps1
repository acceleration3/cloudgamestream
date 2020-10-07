Param([Parameter(Mandatory=$false)] [Switch]$Main)

If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Arguments = "& '" + $MyInvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $Arguments
    Break
}

$WorkDir = "$PSScriptRoot\..\Bin"

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
if($InstallAudio) { Download-File "https://download.vb-audio.com/Download_CABLE/VBCABLE_Driver_Pack43.zip" "$WorkDir\vbcable.zip" "VBCABLE" }
if($InstallVideo) { Download-File "https://download.microsoft.com/download/b/8/f/b8f5ecec-b8f9-47de-b007-ac40adc88dc8/442.06_grid_win10_64bit_international_whql.exe" "$WorkDir\Drivers.exe" "NVIDIA GRID Drivers" }

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

if($InstallAudio) {
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

if($InstallVideo) {
    if($Main) {
        Write-Host "Installing NVIDIA GRID GPU drivers... Your machine will reboot after installing."
        $script = "-Command `"Set-ExecutionPolicy Unrestricted; & '$PSScriptRoot\..\Setup.ps1'`" -RebootSkip";
        $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $script
        $trigger = New-ScheduledTaskTrigger -AtLogon -RandomDelay "00:00:30"
        $principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest
        Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName "GSSetup" -Description "GSSetup" | Out-Null
    }
    $ExitCode = (Start-Process -FilePath "$WorkDir\Drivers.exe" -ArgumentList "/s","/clean" -NoNewWindow -Wait -PassThru).ExitCode
    if($ExitCode -eq 0) {
        if($Main) {
            Write-Host "NVIDIA GRID GPU drivers installed. The script will now restart the machine." -ForegroundColor Green 
            Start-Sleep -Seconds 3
            Restart-Computer -Force
            Start-Sleep -Seconds 10
            throw "Failed to restart after 10 seconds. Please restart manually."
        } else {
            Write-Host "NVIDIA GRID GPU drivers installed." -ForegroundColor Green 
        }
    } else {
        if($Main) { 
            Unregister-ScheduledTask -TaskName "GSSetup" -Confirm:$false 
        }

        Write-Host "Failed to install the recommended NVIDIA GRID driver due to possible incompatibility." -ForegroundColor Red
        $UseExternalScript = (Read-Host "Would you like to use the Cloud GPU Updater script by jamesstringerparsec? The driver the script will install may or may not be compatible with this patch. A shortcut will be created in the Desktop to continue this installation after finishing the script. (y/n)").ToLower() -eq "y"
        if($UseExternalScript) {
            $Shell = New-Object -comObject WScript.Shell
            $Shortcut = $Shell.CreateShortcut("$Home\Desktop\Continue GFE Patching.lnk")
            $Shortcut.TargetPath = "powershell.exe"
            $Shortcut.Arguments = "-Command `"Set-ExecutionPolicy Unrestricted; & '$PSScriptRoot\..\Setup.ps1'`" -RebootSkip"
            $Shortcut.Save()
            Download-File "https://github.com/jamesstringerparsec/Cloud-GPU-Updater/archive/master.zip" "$WorkDir\updater.zip" "Cloud GPU Updater"
            
            if(![System.IO.File]::Exists("$WorkDir\Updater")) {
                Expand-Archive -Path "$WorkDir\updater.zip" -DestinationPath "$WorkDir\Updater"
            }

            Start-Process -FilePath "powershell.exe" -ArgumentList "-Command `"$WorkDir\Updater\Cloud-GPU-Updater-master\GPUUpdaterTool.ps1`""
            [Environment]::Exit(0)
        }
    }
}