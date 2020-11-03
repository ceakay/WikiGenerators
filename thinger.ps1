###FUNCTIONS
#data chopper function
    #args: delimiter, position, input
function datachop {
    $array = @($args[2] -split "$($args[0])")    
    return $array[$args[1]]
}

###SET CONSTANTS
###
#RogueTech Dir (Where RTLauncher exists)
$RTroot = "D:\\RogueTech"
#Script Root
$RTScriptroot = "D:\\RogueTech\\WikiGenerators"
cd $RTScriptroot
#cache path
$CacheRoot = "$RTroot\\RtlCache\\RtCache"
$ErrorFile = '$RTScriptroot\Error'+$(date -Format YYMMDD-HHmm)+'.txt'

$BushwackerList = @()
$HunchieList = @()

"" > $ErrorFile

$JSONList = Get-ChildItem $CacheRoot -Recurse -Filter "*.json"
$i = 0
foreach ($JSONFile in $JSONList) {
    Write-Progress -Activity "Scanning Files" -Status "$($i+1) of $($JSONList.Count) JSONs found."
    $JSONRaw = Get-Content $JSONFile.FullName -Raw
    if ($JSONRaw -match 'chrprfmech_bushwackerbase') {
        try {
            $BushwackerList += 
        } catch {
            $JSONFile >> $ErrorFile
        }
    }
    $i++
}
Write-Output "$($BushwackerList.Count) chrprfmech_bushwackerbase found"
#output to file 
$ComponentObjectList | ConvertTo-Json -Depth 10 > $GearFile