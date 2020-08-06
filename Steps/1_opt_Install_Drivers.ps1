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

$path = "$WorkDir\Drivers.exe"

if(![System.IO.File]::Exists($path)) {
	Write-Output "Downloading NVIDIA GRID Drivers..."
	Start-BitsTransfer "https://download.microsoft.com/download/b/8/f/b8f5ecec-b8f9-47de-b007-ac40adc88dc8/442.06_grid_win10_64bit_international_whql.exe" $path
}

Write-Host "Installing NVIDIA GRID GPU drivers..."
Start-Process -FilePath "$WorkDir\Drivers.exe" -ArgumentList "-s","-clean" -NoNewWindow -Wait