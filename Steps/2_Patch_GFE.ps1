If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Arguments = "& '" + $MyInvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $Arguments
    Break
}

$WorkDir = "$PSScriptRoot\..\Bin\"

Write-Host "Enabling NVIDIA FrameBufferCopy..."
$ExitCode = (Start-Process -FilePath "$WorkDir\NvFBCEnable.exe" -ArgumentList "-enable" -NoNewWindow -Wait -PassThru).ExitCode
if($ExitCode -ne 0) {
    throw "Failed to enable NvFBC. (Error: $ExitCode)"
} else {
    Write-Host "Enabled NvFBC successfully." -ForegroundColor Green
}

Write-Host "Patching GeForce Experience to enable GameStream..."
Stop-Service -Name NvContainerLocalSystem | Out-Null
$ExitCode = (Start-Process -FilePath "$WorkDir\GFEPatch.exe" -NoNewWindow -Wait -PassThru).ExitCode
if($ExitCode -ne 0) {
    $Status = @("Failed to match regex", "Target file not found", "Found no signature", "Found no NVIDIA device to patch")
    $Message = $Status[$($ExitCode - 1)]
    throw "Patcher error: $Message."
} else {
    Write-Host "Patched sucessfully." -ForegroundColor Green
}

Write-Host "Adding hosts file rules to block updates..."
$BlockedHosts = @("telemetry.gfe.nvidia.com", "ls.dtrace.nvidia.com", "ota.nvidia.com", "ota-downloads.nvidia.com", "rds-assets.nvidia.com", "nvidia.tt.omtrdc.net", "api.commune.ly")
$HostsFile = "$env:SystemRoot\System32\Drivers\etc\hosts"
$HostsContent = [String](Get-Content -Path $HostsFile)
$Appended = ""

foreach($Entry in $BlockedHosts) {
    if($HostsContent -notmatch $Entry) {
        $Appended += "0.0.0.0 $Entry`r`n"
    }
}

if($Appended.Length -gt 0) {
    $Appended = $Appended.Substring(0,$Appended.length-2)
    Write-Host "Added hosts:`r`n$Appended"
    Add-Content -Path $HostsFile -Value $Appended
}

Write-Host "Adding a GameStream rule to the Windows Firewall..."
New-NetFirewallRule -DisplayName "NVIDIA GameStream TCP" -Direction inbound -LocalPort 47984,47989,48010 -Protocol TCP -Action Allow | Out-Null
New-NetFirewallRule -DisplayName "NVIDIA GameStream UDP" -Direction inbound -LocalPort 47998,47999,48000,48010 -Protocol UDP -Action Allow | Out-Null