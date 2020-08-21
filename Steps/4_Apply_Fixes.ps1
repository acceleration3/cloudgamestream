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
$Status = @("NvAPI failed to initialize", "Failed to query GPUs", "Failed to get display count", "Failed to query displays", "Failed to set EDID")

$ExitCode = (Start-Process -FilePath "$WorkDir\ResolutionFix.exe" -WorkingDirectory "$WorkDir" -Argument "-g 0","-d 0" -NoNewWindow -Wait -PassThru).ExitCode
if($ExitCode -ne 0) {
    $Message = $Status[$($ExitCode - 1)]
    throw "Adding EDID failed: $Message"
}

Start-Sleep -Seconds 2
Write-Host "Resolution fix applied." -ForegroundColor Green
