date

Start-Process pwsh -ArgumentList "$PSScriptRoot\StartingMechs.ps1"

$PIDs = @()
$PIDS += (Start-Process pwsh -ArgumentList "$PSScriptRoot\RT_GEAR_PARSER.ps1" -PassThru).Id
$PIDS += (Start-Process pwsh -ArgumentList "$PSScriptRoot\RT_MECH_PARSER.ps1" -PassThru).Id
$PIDS += (Start-Process pwsh -ArgumentList "$PSScriptRoot\RT_TANK_PARSER.ps1" -PassThru).Id
Wait-Process -Id $PIDs

$PIDs = @()
$PIDs += (Start-Process pwsh -ArgumentList "$PSScriptRoot\RT_MECH_WIKI_TRANSCODE.ps1" -PassThru).Id
$PIDs += (Start-Process pwsh -ArgumentList "$PSScriptRoot\RT_TANK_WIKI_TRANSCODE.ps1" -PassThru).Id
$PIDs += (Start-Process pwsh -ArgumentList "$PSScriptRoot\RT_GEAR_WIKI.ps1" -PassThru).Id
Wait-Process -Id $PIDs

$PIDs = @()
$PIDs += (Start-Process pwsh -ArgumentList "$PSScriptRoot\RT_WIKI_UPLOAD.ps1" -PassThru).Id
Wait-Process -Id $PIDs