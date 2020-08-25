If (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    $Arguments = "& '" + $MyInvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $Arguments
    Break
}

Write-Host "Disabling HyperV Monitor and non-NVIDIA GPUs..."
displayswitch.exe /internal
Get-PnpDevice -Class "Display" -Status OK | where { $_.Name -notmatch "nvidia" } | Disable-PnpDevice -confirm:$false
Start-Sleep -Seconds 2
Write-Host "Disabled." -ForegroundColor Green