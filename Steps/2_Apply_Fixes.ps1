If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Arguments = "& '" + $MyInvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $Arguments
    Break
}

$WorkDir = "$PSScriptRoot\..\Bin"

$osType = Get-CimInstance -ClassName Win32_OperatingSystem

if($osType.ProductType -eq 3) {
    Write-Host "Installing Wireless Networking."
    Install-WindowsFeature -Name Wireless-Networking | Out-Null
}

Write-Host "Adding a Openstream rules to the Windows Firewall..."
New-NetFirewallRule -DisplayName "Moonlight TCP" -Direction inbound -LocalPort 47984,47989,48010 -Protocol TCP -Action Allow | Out-Null
New-NetFirewallRule -DisplayName "Moonlight UDP" -Direction inbound -LocalPort 47998,47999,48000,48010 -Protocol UDP -Action Allow | Out-Null

Write-Host "Enabling NVIDIA FrameBufferCopy..."
$ExitCode = (Start-Process -FilePath "$WorkDir\NvFBCEnable.exe" -ArgumentList "-enable" -NoNewWindow -Wait -PassThru).ExitCode
if($ExitCode -ne 0) {
    throw "Failed to enable NvFBC. (Error: $ExitCode)"
} else {
    Write-Host "Enabled NvFBC successfully." -ForegroundColor DarkGreen
}

Write-Host "Applying resolution fix scheduled task..." 
if (!(Test-Path -Path "C:\ResFix")) {
    New-Item -Path C:\ResFix -ItemType Directory | Out-Null
    Copy-Item "$WorkDir\ResFix\*" -Destination "C:\ResFix" -Recurse | Out-Null
    New-Item "C:\ResFix\Folder used by cloudgamestream dont delete.txt" | Out-Null
}

if (!(Get-ScheduledTask -TaskName "SetEDID")) {
    $action = New-ScheduledTaskAction -Execute "C:\ResFix\AtLogon.bat" -WorkingDirectory "C:\ResFix"
    $trigger = New-ScheduledTaskTrigger -AtLogon -RandomDelay "00:00:30"
    $principal = New-ScheduledTaskPrincipal -GroupId "BUILTIN\Administrators" -RunLevel Highest
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "SetEDID" -Principal $principal -Description "Sets an EDID at startup" | Out-Null
}

Start-ScheduledTask -TaskName "SetEDID" | Out-Null

Start-Sleep -Seconds 2
Write-Host "Resolution fix applied." -ForegroundColor Green

    $osType = Get-CimInstance -ClassName Win32_OperatingSystem

    if($osType.ProductType -eq 3) {
        Write-Host "Applying Audio service fix for Windows Server..."
        New-ItemProperty "hklm:\SYSTEM\CurrentControlSet\Control" -Name "ServicesPipeTimeout" -Value 600000 -PropertyType "DWord" | Out-Null
        Set-Service -Name Audiosrv -StartupType Automatic | Out-Null
}
