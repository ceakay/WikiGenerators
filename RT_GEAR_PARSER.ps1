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
$ComponentFilter = "*`"ComponentType`"*"
$GearFile = $RTScriptroot+"\\Outputs\\GearTable.json"
$WonkyFile = $RTScriptroot+"\\Outputs\\WonkyGear.csv"
#Hard Remove Gear
$GearRemoveCSV = $RTScriptroot+"\\Inputs\\GearRemove.csv"
$GearRemove = @((Import-Csv $GearRemoveCSV).GearRemove)

###INIT VARS
$ComponentObjectList = @()

#get a list of jsons
#construct mega component object list
$JSONList = Get-ChildItem $CacheRoot -Recurse -Filter "*.json"
$JSONList = $JSONList | ? {($_.FullName -notmatch 'VanillaNoLoot')}
$i = 0
foreach ($JSONFile in $JSONList) {
    Write-Progress -Activity "Collecting Components" -Status "$($i+1) of $($JSONList.Count) JSONs found."
    $JSONRaw = Get-Content $JSONFile.FullName -Raw
    if ($JSONRaw -like $ComponentFilter) {
        try {
            $JSONObject = $($JSONRaw | ConvertFrom-Json)
            #Force BLACKLISTED if WIKIBL
            if ($JSONObject.ComponentTags.items -contains "WikiBL") {
                $JSONObject.ComponentTags.items += "BLACKLISTED"
            }
            #UINameFixes
            $JSONObject.Description.UIName = $JSONObject.Description.UIName.Trim() #remove whitespaces
            $JSONObject.Description.UIName = $JSONObject.Description.UIName.Replace("/","") #remove backslash for urls
            $JSONObject.Description.UIName = $JSONObject.Description.UIName.Replace("#","") #remove hash for urls
            $JSONObject.Description.UIName = $JSONObject.Description.UIName.Replace("[","(")
            $JSONObject.Description.UIName = $JSONObject.Description.UIName.Replace("]",")")
            if ($JSONObject.Description.UIName -notmatch '\+\d') {
                $UINameArray = $($JSONObject.Description.UIName -split (" \+"))
            }
            if ($UINameArray.Count -gt 1) {
                $JSONObject.Description.UIName = $UINameArray[0] + " Mk$($UINameArray.Count - 1)"
            }
            $JSONObject | Add-Member -NotePropertyName Wiki -NotePropertyValue $([pscustomobject]@{})
            $JSONObject.Wiki | Add-Member -NotePropertyName Mod -NotePropertyValue $($($($JSONFile.FullName -split $CacheRoot)[1] -split "\\")[1])
            $JSONObject.Wiki | Add-Member -NotePropertyName ModSubFolder -NotePropertyValue $($($($JSONFile.FullName -split $CacheRoot)[1] -split "\\")[2])
            if ($GearRemove -notcontains $JSONObject.Description.Id) {
                $ComponentObjectList += $JSONObject
            }
        } catch {
            "GearParser|Error parsing: " + $JSONFile | Out-File $RTScriptroot\ErrorLog.txt -Append -Encoding utf8
        }
    }
    $i++
}
Write-Output "$($ComponentObjectList.Count) components collected"
#Remove Deprecated/DLC
Write-Progress -Id 0 -Activity "Scrubbing Deprecated"
$ComponentObjectList = $ComponentObjectList | ? {$_.Description.UIName -notmatch 'DEPRECATED'} | ? {$_.Description.UIName -notmatch 'DEPRECIATED'} | ? {$_.Description.UIName -notmatch 'INSTALL DLC MODULE'}
#Remove Linked
Write-Progress -Id 0 -Activity "Scrubbing Linked"
$LinkedList = $ComponentObjectList.Custom.Linked.Links.ComponentDefId | select
$ComponentObjectList = $ComponentObjectList | ? {$_.Description.Id -notin $LinkedList}
#CustomOverrides
$($ComponentObjectList | ? {$_.Description.ID -eq 'Weapon_Laser_TAG_HeyListen'}).Description.UIName = 'TAG (NAVI)'
#id no longer exists $($ComponentObjectList | ? {$_.Description.ID -eq 'Gear_Cockpit_SensorsB_Standard'}).Description.UIName = 'Sensors (B)'
#Make all UINames Unique
$DuplicatesGroup = $($($ComponentObjectList | Group {$_.Description.UIName}) | ? {$_.Count -ge 2})
foreach ($Dupe in $DuplicatesGroup.Name) {
    $DupeCounter = 0
    $ComponentObjectList | ? {$_.Description.UIName -eq $Dupe} | ForEach-Object -Process {
        $DupeCounter++
        $_.Description.UIName = $_.Description.UIName.Trim() + " ($DupeCounter)"
    }
}

#output to file 
$ComponentObjectList | ConvertTo-Json -Depth 99 > $GearFile
$WonkyList | Export-Csv $WonkyFile -NoTypeInformation

