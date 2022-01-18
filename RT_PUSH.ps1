$RTScriptroot = "D:\\RogueTech\\WikiGenerators"

"Date: " + $(date) | Out-File $RTScriptroot\ErrorLog.txt -Append -Encoding utf8

$PIDs = @()
$PIDS += (Start-Process pwsh -ArgumentList "$RTScriptroot\RT_GEAR_PARSER.ps1" -WindowStyle Minimized -PassThru).Id
$PIDS += (Start-Process pwsh -ArgumentList "$RTScriptroot\RT_MECH_PARSER.ps1" -WindowStyle Minimized -PassThru).Id
$PIDS += (Start-Process pwsh -ArgumentList "$RTScriptroot\RT_TANK_PARSER.ps1" -WindowStyle Minimized -PassThru).Id
$PIDS += (Start-Process pwsh -ArgumentList "$RTScriptroot\RT_STAR_PARSER.ps1" -WindowStyle Minimized -PassThru).Id
Wait-Process -Id $PIDs #wait for parsers to finish. transcoders may need mulitple

$BASpawnPID = (Start-Process pwsh -ArgumentList "$RTScriptroot\BASpawnPools.ps1" -WindowStyle Minimized -PassThru).Id
$StatusText = 'BASpawnPools'
Write-Progress -id 0 -Activity "Waiting for $StatusText $TypeStatus"
Wait-Process -Id $BASpawnPID

$WikiPID = (Start-Process pwsh -ArgumentList "$RTScriptroot\StartingMechs.ps1" -WindowStyle Minimized -PassThru).Id
$StatusText = 'StartingMechs'
Write-Progress -id 0 -Activity "Waiting for $StatusText $TypeStatus"
#dirty combo scripts. just get em out of the way.
#Wait-Process -Id $WikiPID

$PIDs = @()
$RefHash = @{}

$CreditsPID = (Start-Process pwsh -ArgumentList "$RTScriptroot\RT_Credits.ps1" -WindowStyle Minimized -PassThru).Id
$PIDs += $CreditsPID
$RefHash.Add($CreditsPID,'Credits')

$GearPID = (Start-Process pwsh -ArgumentList "$RTScriptroot\RT_GEAR_WIKI.ps1" -WindowStyle Minimized -PassThru).Id
$PIDs += $GearPID
$RefHash.Add($GearPID,'Gear')

$TankPID = (Start-Process pwsh -ArgumentList "$RTScriptroot\RT_TANK_WIKI_TRANSCODE.ps1" -WindowStyle Minimized -PassThru).Id
$PIDs += $TankPID
$RefHash.Add($TankPID,'Tank')

$MechPID = (Start-Process pwsh -ArgumentList "$RTScriptroot\RT_MECH_WIKI_TRANSCODE.ps1" -WindowStyle Minimized -PassThru).Id
$PIDs += $MechPID
$RefHash.Add($MechPID,'Mech')

foreach ($PriorPID in $PIDs) {
    Get-CimInstance -ClassName win32_process -Filter "ProcessID = $PriorPID" | Invoke-CimMethod -MethodName SetPriority -Arguments @{Priority = 16384}
}

$FinishedPIDs = @()
$PIDs = $PIDs | ? {$_}
$CompareArray = $($(Compare-Object $PIDs $FinishedPIDs) | ? {$_.SideIndicator -match '<='}).InputObject
#Check if the last wiki uploader is done, then start new one
while (-not !$CompareArray) {
    $TypeStatus = "Upload"
    if ((-not [bool]$(Get-Process -Id $WikiPID -ErrorAction SilentlyContinue)) -or ($(Get-Process -Id $WikiPID -ErrorAction SilentlyContinue).HasExited)) { #if wikipid process is done, add to finishedpids
        $TypeStatus = "Transcode"
        $CompareArray = $($(Compare-Object $PIDs $FinishedPIDs) | ? {$_.SideIndicator -match '<='}).InputObject #update comparearray
        foreach ($PIDThing in $CompareArray) { #iterate thru each piditem in comparearray (non-uploaded)
            $StatusText = $($RefHash.$PIDThing)
            if ((-not [bool]$(Get-Process -Id $PIDThing -ErrorAction SilentlyContinue)) -or ($(Get-Process -Id $PIDThing -ErrorAction SilentlyContinue).HasExited)) { #if the PIDitem does not exist, start new upload
                $WikiPID = (Start-Process pwsh -ArgumentList "$RTScriptroot\RT_WIKI_UPLOAD_$StatusText.ps1" -WindowStyle Minimized -PassThru).Id
                $FinishedPIDs += $PIDThing
                break #stop iterating since new process started
            }
        }
    }
    Write-Progress -id 0 -Activity "Waiting for $StatusText $TypeStatus"
    Start-Sleep -Milliseconds 250
}
