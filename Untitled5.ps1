Write-Host @"





































"@

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
$ComponentFilter = "*`"Id`"*:*`"mechdef*"
$GearFile = $RTScriptroot+"\\Outputs\\MechTableV2.json"

###INIT VARS
$ComponentObjectList = @()

#get a list of jsons
#construct mega component object list
$JSONList = Get-ChildItem $CacheRoot -Recurse -Filter "*.json"
$JSONList = $JSONList | ? {($_.FullName -notmatch 'VanillaNoLoot')}
$i = 0
$WonkyList = @()
foreach ($JSONFile in $JSONList) {
    Write-Progress -Activity "Collecting Components" -Status "$($i+1) of $($JSONList.Count) JSONs found."
    $JSONRaw = Get-Content $JSONFile.FullName -Raw
    if ($JSONRaw -like $ComponentFilter) {
        try {
            $JSONObject = $($JSONRaw | ConvertFrom-Json)
            $ComponentObjectList += $JSONObject
        } catch {
            "GearParser|Error parsing: " + $JSONFile | Out-File $RTScriptroot\ErrorLog.txt -Append -Encoding utf8
        }
    }
    $i++
}
Write-Output "$($ComponentObjectList.Count) components collected"
#output to file 
$ComponentObjectList | ConvertTo-Json -Depth 99 > $GearFile
$WonkyList | Export-Csv $WonkyFile -NoTypeInformation