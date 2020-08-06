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

Import-Module BitsTransfer

$path = "$WorkDir\GFE.exe"

if(![System.IO.File]::Exists($path)) {
	Write-Host "Downloading GeForce Experience..."
	Start-BitsTransfer "https://us.download.nvidia.com/GFE/GFEClient/3.13.0.85/GeForce_Experience_Beta_v3.13.0.85.exe" $path
}

$path = "$WorkDir\redist.exe"

if(![System.IO.File]::Exists($path)) {
	Write-Host "Downloading Visual C++ Redist 2015 x86..."
	Start-BitsTransfer "https://download.microsoft.com/download/9/3/F/93FCF1E7-E6A4-478B-96E7-D4B285925B00/vc_redist.x86.exe" $path
}

Write-Host "Installing Visual C++ Redist 2015 x86..."
Start-Process -FilePath "$WorkDir\redist.exe" -ArgumentList "/install","/quiet","/norestart" -NoNewWindow -Wait

Write-Host "Installing GeForce Experience..."
Start-Process -FilePath "$WorkDir\GFE.exe" -ArgumentList "-s" -NoNewWindow -Wait