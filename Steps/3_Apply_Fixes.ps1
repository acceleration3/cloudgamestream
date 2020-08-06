Param([Parameter(Mandatory=$false)] [Switch]$Main)

If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Arguments = "& '" + $MyInvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $Arguments
    Break
}

if($Main -eq $true) {
    $WorkDir = ".\Bin"
}else{
    $WorkDir = "..\Bin"
}

$osType = Get-CimInstance -ClassName Win32_OperatingSystem

if($osType.ProductType -eq 3)
{
    Write-Host "Windows Server detected, installing Wireless Networking."
    Install-WindowsFeature -Name Wireless-Networking | Out-Null

    Write-Host "Audio service booting fix"
    New-ItemProperty "hklm:\SYSTEM\CurrentControlSet\Control" -Name "ServicesPipeTimeout" -Value 600000 -PropertyType "DWord" | Out-Null
    Set-Service -Name Audiosrv -StartupType Automatic | Out-Null
}

Write-Host "Applying resolution fix"
Start-Process -FilePath "$WorkDir\ResolutionFix.exe" -NoNewWindow -Wait -PassThru