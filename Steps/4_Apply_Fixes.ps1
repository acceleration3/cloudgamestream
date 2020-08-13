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

$osType = Get-CimInstance -ClassName Win32_OperatingSystem

if($osType.ProductType -eq 3) {
    Write-Host "Installing Wireless Networking."
    Install-WindowsFeature -Name Wireless-Networking | Out-Null
}

Write-Host "Applying resolution fix..."
$ExitCode = (Start-Process -FilePath "$WorkDir\NvSetEdid.exe" -WorkingDirectory "$WorkDir" -Argument "-a","-f edid.txt","-g 0","-d 0" -NoNewWindow -Wait -PassThru).ExitCode
if($ExitCode -ne 0) {
    $Status = @("NvAPI failed to initialize", "Failed to query GPUs", "Failed to load EDID file", "Failed to get display count", "Failed to query displays", "Failed to set EDID")
    $Message = $Status[$($ExitCode - 1)]
    throw "NvSetEdid error: $Message"
}

$ExitCode = (Start-Process -FilePath "$WorkDir\NvSetEdid.exe" -WorkingDirectory "$WorkDir" -Argument "-r","-g 0","-d 0" -NoNewWindow -Wait -PassThru).ExitCode
if($ExitCode -ne 0) {
    $Status = @("NvAPI failed to initialize", "Failed to query GPUs", "Failed to load EDID file", "Failed to get display count", "Failed to query displays", "Failed to set EDID")
    $Message = $Status[$($ExitCode - 1)]
    throw "NvSetEdid error: $Message"
}