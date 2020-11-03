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
#$ErrorFile = "$RTScriptroot\\Error\\PrefabRunErrors$(date -Format YYMMDD-HHmm).txt"

$BushwackerListFile = "$RTScriptroot\\Outputs\\chrprfmech_bushwackerbase.txt"
$HunchieListFile = "$RTScriptroot\\Outputs\\chrPrfMech_hunchbackBase.txt"

$BushwackerList = @()
$HunchieList = @()

$JSONList = Get-ChildItem $CacheRoot -Recurse -Filter "*.json"
$i = 0
foreach ($JSONFile in $JSONList) {
    Write-Progress -Activity "Scanning Files" -Status "$($i+1) of $($JSONList.Count) JSONs found."
    $JSONRaw = Get-Content $JSONFile.FullName -Raw
    if ($JSONRaw -match 'chrprfmech_bushwackerbase') {
        $BushwackerList += $(datachop 'RtCache' 1 $JSONFile.FullName)
    }
    if ($JSONRaw -match 'chrPrfMech_hunchbackBase') {
        $HunchieList += $(datachop 'RtCache' 1 $JSONFile.FullName)
    }
    $i++
}
Write-Output "$($BushwackerList.Count) chrprfmech_bushwackerbase found"
Write-Output "$($HunchieList.Count) chrprfmech_bushwackerbase found"
#output to file 
$BushwackerList | Out-File $BushwackerListFile -Encoding utf8 
$HunchieList | Out-File $HunchieListFile -Encoding utf8 