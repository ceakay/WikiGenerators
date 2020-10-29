###SET CONSTANTS
###
#RogueTech Dir (Where RTLauncher exists)
$RTroot = "D:\\RogueTech"
#Script Root
$RTScriptroot = "D:\\RogueTech\\WikiGenerators"
cd $RTScriptroot
#cache path
$CacheRoot = "$RTroot\\RtlCache\\RtCache"
#Define component unique
$ComponentFilter = "*`"ComponentType`"*"
$GearFile = $RTScriptroot+"\\Outputs\\GearTable.json"

###INIT VARS
$ComponentObjectList = @()

#get a list of jsons
#construct mega component object list
$JSONList = Get-ChildItem $CacheRoot -Recurse -Filter "*.json"
$i = 0
foreach ($JSONFile in $JSONList) {
    Write-Progress -Activity "Collecting Components" -Status "$($i+1) of $($JSONList.Count) JSONs found."
    $JSONRaw = Get-Content $JSONFile.FullName -Raw
    if ($JSONRaw -like $ComponentFilter) {
        try {
            $ComponentObjectList += $($JSONRaw | ConvertFrom-Json)
        } catch {
            Write-Host $JSONFile
        }
    }
    $i++
}
Write-Output "$($ComponentObjectList.Count) components collected"
#output to file 
$ComponentObjectList | ConvertTo-Json -Depth 10 > $GearFile