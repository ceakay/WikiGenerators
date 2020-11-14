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
$WonkyFile = $RTScriptroot+"\\Outputs\\WonkyGear.csv"

###INIT VARS
$ComponentObjectList = @()

#get a list of jsons
#construct mega component object list
$JSONList = Get-ChildItem $CacheRoot -Recurse -Filter "*.json"
$i = 0
$WonkyList = @()
foreach ($JSONFile in $JSONList) {
    Write-Progress -Activity "Collecting Components" -Status "$($i+1) of $($JSONList.Count) JSONs found."
    $JSONRaw = Get-Content $JSONFile.FullName -Raw
    if ($JSONRaw -like $ComponentFilter) {
        try {
            $JSONObject = $($JSONRaw | ConvertFrom-Json)
            $JSONObject.Description.UIName = $JSONObject.Description.UIName.Replace("/","")
            $UINameArray = $($JSONObject.Description.UIName -split (" \+"))
            if ($UINameArray.Count -gt 1) {
                $JSONObject.Description.UIName = $UINameArray[0] + " Mk$($UINameArray.Count - 1)"
                if ($JSONObject.ComponentTags.items -match 'blacklist') {
                    $BlacklistComponent = $true
                } else {
                    $BlacklistComponent = $false
                }
                $WonkyList += [pscustomobject]@{
                    File = $JSONFile.FullName
                    Blacklist = $BlacklistComponent
                }
            }
            $ComponentObjectList += $JSONObject
        } catch {
            Write-Host $JSONFile
        }
    }
    $i++
}
Write-Output "$($ComponentObjectList.Count) components collected"
#output to file 
$ComponentObjectList | ConvertTo-Json -Depth 99 > $GearFile
$WonkyList | Export-Csv $WonkyFile -NoTypeInformation