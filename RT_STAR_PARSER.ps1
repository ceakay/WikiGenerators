###SET CONSTANTS
###
#RogueTech Dir (Where RTLauncher exists)
$RTroot = "D:\\RogueTech"
cd $RTroot
#Script Root
$RTScriptroot = "D:\\RogueTech\\WikiGenerators"
#cache path
$CacheRoot = "$RTroot\\RtlCache\\RtCache"
#Define component unique
$StarFile = $RTScriptroot+"\\Outputs\\StarTable.json"

###INIT VARS
$StarObjectList = @()

#get a list of jsons
#construct mega component object list
$JSONList = Get-ChildItem $CacheRoot -Recurse -Filter "StarSystemDef*.json"
$i = 0
$FunkyNameList = @()
foreach ($JSONFile in $JSONList) {
    Write-Progress -Activity "Collecting Star Systems" -Status "$($i+1) of $($JSONList.Count) JSONs found."
    $JSONRaw = Get-Content $JSONFile.FullName -Raw
    if ($JSONRaw -match '\\u') {
        $FunkyNameList += $JSONFile.FullName
    }
    $StarObjectList += $($JSONRaw | ConvertFrom-Json)
    $i++
}
Write-Output "$($StarObjectList.Count) Star Systems collected"
#output to file 
$StarObjectList | ConvertTo-Json -Depth 99 > $StarFile