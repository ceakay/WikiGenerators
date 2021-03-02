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
$TheWord = 'Details'
$ComponentFilter = "*`"$TheWord`"*"
$GearFile = $RTScriptroot+"\\Outputs\\GearTable.json"
$WonkyFile = $RTScriptroot+"\\Outputs\\$TheWord-CharCount.csv"

###INIT VARS
$ComponentObjectList = @()

#get a list of jsons
#construct mega component object list
$JSONList = Get-ChildItem $CacheRoot -Recurse -Filter "*.json"
$i = 0
$WonkyList = @()
foreach ($JSONFile in $JSONList) {
    Write-Progress -Activity "Collecting $ComponentFilter" -Status "Checking $($i+1) of $($JSONList.Count) JSONs found."
    $JSONRaw = Get-Content $JSONFile.FullName -Raw
    if ($JSONRaw -like $ComponentFilter) {
        try {
            $JSONObject = $($JSONRaw | ConvertFrom-Json)
            $WonkyList += [pscustomobject]@{
                File = $JSONFile.FullName
                CharacterCount = $JSONObject.Description.Details.Length
            }
            $ComponentObjectList += $JSONObject
        } catch {
            Write-Host $JSONFile.FullName
        }
    }
    $i++
}
Write-Host "Finished Scanning"
#output to file 
$WonkyList | Export-Csv $WonkyFile -NoTypeInformation