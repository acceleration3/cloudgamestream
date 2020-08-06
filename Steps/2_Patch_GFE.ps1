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

Write-Host "Enabling NVIDIA FrameBufferCopy..."
Start-Process -FilePath "$WorkDir\NvFBCEnable.exe" -ArgumentList "-enable","-noreset" -NoNewWindow -Wait

Write-Host "Patching GeForce Experience to enable GameStream..."
Stop-Service -Name NvContainerLocalSystem
Start-Process -FilePath "$WorkDir\GFEPatch.exe" -NoNewWindow -Wait -PassThru

Write-Host "Patching hosts file to block GeForce Experience updates..."
Copy-Item -Path "$WorkDir\hosts.txt" -Destination C:\Windows\System32\drivers\etc\hosts

Write-Host "Disabling HyperV Monitor and GPU..."
displayswitch.exe /internal
Get-PnpDevice -Class "Display" -Status OK | where { $_.Name -notmatch "nvidia" } | Disable-PnpDevice -confirm:$false

Write-Host "Adding a GameStream rule to the Windows Firewall..."
New-NetFirewallRule -DisplayName "NVIDIA GameStream TCP" -Direction inbound -LocalPort 47984,47989,48010 -Protocol TCP -Action Allow | Out-Null
New-NetFirewallRule -DisplayName "NVIDIA GameStream UDP" -Direction inbound -LocalPort 47998,47999,48000,48010 -Protocol UDP -Action Allow | Out-Null