$RTScriptroot = "D:\\RogueTech\\WikiGenerators"

"Date: " + $(date) | Out-File $RTScriptroot\ErrorLog.txt -Append -Encoding utf8

$WikiPID = (Start-Process pwsh -ArgumentList "$RTScriptroot\StartingMechs.ps1" -PassThru).Id
$StatusText = 'StartingMechs'
#starting mechs is dirty combo script. just get it out of the way.

$PIDs = @()
$PIDS += (Start-Process pwsh -ArgumentList "$RTScriptroot\RT_GEAR_PARSER.ps1" -PassThru).Id
$PIDS += (Start-Process pwsh -ArgumentList "$RTScriptroot\RT_MECH_PARSER.ps1" -PassThru).Id
$PIDS += (Start-Process pwsh -ArgumentList "$RTScriptroot\RT_TANK_PARSER.ps1" -PassThru).Id
Wait-Process -Id $PIDs #wait for parsers to finish. transcoders may need mulitple

$PIDs = @()
$RefHash = @{}

$MechPID += (Start-Process pwsh -ArgumentList "$RTScriptroot\RT_MECH_WIKI_TRANSCODE.ps1" -PassThru).Id
$PIDs += $MechPID
$RefHash.Add($MechPID,'Mech')

$TankPID = (Start-Process pwsh -ArgumentList "$RTScriptroot\RT_TANK_WIKI_TRANSCODE.ps1" -PassThru).Id
$PIDs += $TankPID
$RefHash.Add($TankPID,'Tank')

$GearPID = (Start-Process pwsh -ArgumentList "$RTScriptroot\RT_GEAR_WIKI.ps1" -PassThru).Id
$PIDs += $GearPID
$RefHash.Add($GearPID,'Gear')

$FinishedPIDs = @()
$PIDs = $PIDs | ? {$_}
$CompareArray = $($(Compare-Object $PIDs $FinishedPIDs) | ? {$_.SideIndicator -match '<='}).InputObject
#Check if the last wiki uploader is done, then start new one
while (-not !$CompareArray) {
    $TypeStatus = "Upload"
    if (-not [bool]$(Get-Process -Id $WikiPID -ErrorAction SilentlyContinue)) { #if wikipid process not exist (is done), add to finishedpids
        $TypeStatus = "Transcode"
        $CompareArray = $($(Compare-Object $PIDs $FinishedPIDs) | ? {$_.SideIndicator -match '<='}).InputObject #update comparearray
        foreach ($PIDThing in $CompareArray) { #iterate thru each piditem in comparearray (non-uploaded)
            $StatusText = $($RefHash.$PIDThing)
            if (-not [bool]$(Get-Process -Id $PIDThing -ErrorAction SilentlyContinue)) { #if the PIDitem does not exist, start new upload
                $WikiPID = (Start-Process pwsh -ArgumentList "$RTScriptroot\RT_WIKI_UPLOAD_$StatusText.ps1" -PassThru).Id
                $FinishedPIDs += $PIDThing
                break #stop iterating since new process started
            }
        }
    }
    Write-Progress -id 0 -Activity "Waiting for $StatusText $TypeStatus"
    Start-Sleep -Milliseconds 1000
}
