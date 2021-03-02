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

$PrefabIdentifier = 'chrPrfMech_hatchetmanBase-001'
#$PrefabIdentifier2 = 'chrPrfMech_hatchetmanBase-001'

$ListFile = "$RTScriptroot\\Outputs\\$PrefabIdentifier.txt"
#$ListFile2 = "$RTScriptroot\\Outputs\\$PrefabIdentifier.txt"

$PrefabList = @()
$PrefabList2 = @()

$JSONList = Get-ChildItem $CacheRoot -Recurse -Filter "*.json"
$i = 0
foreach ($JSONFile in $JSONList) {
    Write-Progress -Activity "Scanning Files" -Status "$($i+1) of $($JSONList.Count) JSONs found."
    $JSONRaw = Get-Content $JSONFile.FullName -Raw
    if ($JSONRaw -match $PrefabIdentifier) {
        $PrefabList += $(datachop 'RtCache' 1 $JSONFile.FullName)
    }
    <#
    if ($JSONRaw -match $PrefabIdentifier2) {
        $PrefabList2 += $(datachop 'RtCache' 1 $JSONFile.FullName)
    }
    #>
    $i++
}
Write-Output "$($BushwackerList.Count) $PrefabIdentifier found"
#Write-Output "$($HunchieList.Count) $PrefabIdentifier2 found"
#output to file 
$PrefabList | Out-File $ListFile -Encoding utf8 
#$PrefabList2 | Out-File $ListFile2 -Encoding utf8 