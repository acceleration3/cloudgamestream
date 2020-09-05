Param([Parameter(Mandatory=$true)] [string]$DeviceID, [Parameter(Mandatory=$true)] [string]$TargetFile)
"Device ID: " + $DeviceID
"Target File: " + $TargetFile

if(!(Test-Path -Path $TargetFile)) {
    throw "Target file does not exist."
}

$BackupFile = "${TargetFile}.backup"
if(!(Test-Path -Path $BackupFile)) {
    Copy-Item $TargetFile $BackupFile
}

$DeviceIDUI64 = 0
try {
    $DeviceIDUI64 = [uint64]("0x$DeviceID")
}
catch {
    throw "Invalid device ID."
}

$Signature = [uint64]0x13D9
$ReplaceBytes = [System.BitConverter]::GetBytes($DeviceIDUI64);
$Data = [System.IO.File]::ReadAllBytes($BackupFile)
$FileSize = $Data.Count
$Patched = $false
for($i=0; $i -lt ($FileSize - 8); $i++) {
    $Search = [System.BitConverter]::ToUInt64($Data, $i);
    if($Search -eq $Signature) {
        "Found: 0x" + $i.ToString("X")
        for($j=0; $j -lt 8; $j++) {
            $Data[$i + $j] = $ReplaceBytes[$j]
        }
        $Patched = $true
    }
}

if(!$Patched) {
    throw "Found no matches for the signature."
}

Remove-Item -Path $TargetFile
[System.IO.File]::WriteAllBytes($TargetFile, $Data)
Write-Host "Patched successfully." -ForegroundColor DarkGreen