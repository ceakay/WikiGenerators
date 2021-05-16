Write-Host @"





































"@

###FUNCTIONS
#data chopper function
    #args: delimiter, position, input
function datachop {
    $array = @($args[2] -split "$($args[0])")    
    return $array[$args[1]]
}

###SETTINGS
#disable when testing!
# moved uploading to own script
$UploadToWiki = $false

#SET CONSTANTS
###
#RogueTech Dir (Where RTLauncher exists)
$RTroot = "D:\\RogueTech"
#Script Root
$RTScriptroot = "D:\\RogueTech\\WikiGenerators"
cd $RTScriptroot
#cache path
$CacheRoot = "$RTroot\\RtlCache\\RtCache"
#WikiPage unique Identifier
$WikiID = "MechList"
$MexID = "Mex"
#Blurb that goes before 
$Blurb = "$RTScriptroot\\Inputs\\$($WikiID)Blurb.txt"
$TableFile = "$RTScriptroot\\Outputs\\$($WikiID)Table.json"
$WikiPageFile = "$RTScriptroot\\Outputs\\$($WikiID)WikiPage.txt"
$WikiPageFileUTF8 = "$RTScriptroot\\Outputs\\$($WikiID)WikiPage.UTF8"
$WikiPageMexFile = "$RTScriptroot\\Outputs\\$($MexID)WikiPage.txt"
$WikiPageMexFileUTF8 = "$RTScriptroot\\Outputs\\$($MexID)WikiPage.UTF8"
$CatFile = "$RTScriptroot\\Inputs\\Class.csv"
$CatObject = Get-Content $CatFile -raw | ConvertFrom-Csv
$SpecialsFile = "$RTScriptroot\\Inputs\\Special.csv"
$SpecialsObject = Get-Content $SpecialsFile -Raw | ConvertFrom-Csv
$MountsFile = "$RTScriptroot\\Inputs\\WeaponMounts.csv"
$MountsObject = Get-Content $MountsFile -Raw | ConvertFrom-Csv
$GroupingFile = "$RTScriptroot\\Inputs\\FactionGrouping.csv"
$GroupingCSVObject = Import-Csv -Path "$GroupingFile" 
$PWBRoot = "D:\\PYWikiBot"
$PrefabIDFile = "$RTScriptroot\\Outputs\\PrefabID.json"


$BlacklistFile = "$RTScriptroot\\Inputs\\Blacklist.csv"
$BlacklistOverride = $(Import-Csv -Path "$BlacklistFile").Blacklist

#holy shit this can't import properly
$GroupKeyList = $($GroupingCSVObject | Get-Member -MemberType Properties).Name
$GroupObject = [pscustomobject]@{}
write-progress -activity 'Building Faction Groups'
foreach ($BuildGroup in $GroupKeyList) {
    Add-Member -InputObject $GroupObject -MemberType NoteProperty -Name $BuildGroup -Value @()
    $GroupObject.$BuildGroup = $(Import-Csv -Path $GroupingFile | select -ExpandProperty $BuildGroup)
    $GroupObject.$BuildGroup = $($GroupObject.$BuildGroup | Where-Object {$_})
}
$GroupFriendlyFile = "$RTScriptroot\\Inputs\\GroupFriendly.csv"
$GroupFriendlyObject = Import-Csv -Path $GroupFriendlyFile
#Build faction friendlyname table
$FactionFriendlyObject = [pscustomobject]@{}
write-progress -activity 'Gathering Faction Friendly Names'
$FactionFriendlyFileList = Get-ChildItem $RTroot -Recurse -Filter "faction_*.json" -ErrorAction SilentlyContinue
foreach ($FactionFriendlyFile in $FactionFriendlyFileList) {
    try { 
        $FactionDefObj = Get-Content $FactionFriendlyFile.VersionInfo.FileName -Raw | ConvertFrom-Json
    } catch {
        "MechWiki|FactionFile error: " + $FactionFriendlyFile.VersionInfo.FileName | Out-File $RTScriptroot\ErrorLog.txt -Append -Encoding utf8
    }
    try {
        $FactionFriendlyObject | Add-Member -Type NoteProperty -Name $FactionDefObj.factionID -Value $($FactionDefObj.Name).Replace("the ","") -Force
    } catch { 
        "MechWiki|Faction error: " + $($FactionDefObj.factionID) + $($FactionFriendlyFile.VersionInfo.FileName) | Out-File $RTScriptroot\ErrorLog.txt -Append -Encoding utf8
    }
}
<#
foreach ($Key in $GroupKeyList) {
    foreach ($FactionName in $GroupObject.$Key) {
        $FactionDefFileObj = $(Get-ChildItem $RTroot -Recurse -Filter "faction_$FactionName.json" -ErrorAction SilentlyContinue)
        if (-not !$FactionDefFileObj) {
            $FactionDefObj = $(Get-Content $FactionDefFileObj.VersionInfo.FileName -Raw | ConvertFrom-Json)
            $FactionFriendlyObject | Add-Member -Type NoteProperty -Name $FactionName -Value $($FactionDefObj.Name).Replace("the ","")
        }
    }
}
#>
#FactionIgnoreList
$FactionIgnoreObj = Import-Csv "$RTScriptroot\\Inputs\\FactionIgnoreList.csv"
$FactionIgnoreList = @($FactionIgnoreObj.IgnoreUs)
#Icon Names LAWD!
$IconFilesList = Get-ChildItem $CacheRoot -Recurse -Filter "*.dds"

#Build Item Friendly Name Hash
#build Item Slots hash
<#
Write-Progress -Activity 'Gathering Item Friendly Names'
$AllJSON = Get-ChildItem $CacheRoot -Recurse -Filter "*.json" -Include 'Ammo*','Ammunition*','BoltOn*','default_*','emod*','gear*','hand*','lootable*','LoreGear*','NoBoxAmmo*','Omni*','PA*','PartialWing*','protomech*','prototype*','quirk_*','supercharged*','special_*','weapon*','zeusx*' -ErrorAction SilentlyContinue
#>
$GearFile = $RTScriptroot+"\\Outputs\\GearTable.json"
$GearObject = Get-Content $GearFile -raw | ConvertFrom-Json
$ItemFriendlyHash = @{}
$ItemSlotsHash = @{}
foreach ($Item in $GearObject) {
    #Build Item Friendly Name Hash
    if (-not !$Item.Description.UIName) {
        try {$ItemFriendlyHash.Add($Item.Description.Id,$Item.Description.UIName)} catch {"MechWiki|Dupe gear ID: $($Item.Description.Id)" | Out-File $RTScriptroot\ErrorLog.txt -Append -Encoding utf8}
    }
    #build Item Slots hash
    if (-not !$Item.InventorySize) {
        try {$ItemSlotsHash.Add($Item.Description.Id,$Item.InventorySize)} catch {""}
    } else {
        try {$ItemSlotsHash.Add($Item.Description.Id,1)} catch {""}
    }
}


#Build Affinities
$AffinitiesFile = "$CacheRoot\\MechAffinity\\settings.json"
$CAffinitiesMaster = $(Get-Content $AffinitiesFile -Raw | ConvertFrom-Json).chassisAffinities
$EquipAffinitiesMaster = $(Get-Content $AffinitiesFile -Raw | ConvertFrom-Json).quirkAffinities
$EquipAffinitiesIDNumHash = @{}
$EquipAffinitiesIDNameHash = @{}
$EquipAffinitiesIDDescHash = @{}
foreach ($EquipAffinity in $EquipAffinitiesMaster) {
    foreach ($AffinityItem in $EquipAffinity.quirkNames) {
        $EquipAffinitiesIDNumHash.Add($AffinityItem,$EquipAffinity.affinityLevels.missionsRequired)
        $EquipAffinitiesIDNameHash.Add($AffinityItem,$EquipAffinity.affinityLevels.levelName)
        $EquipAffinitiesIDDescHash.Add($AffinityItem,$EquipAffinity.affinityLevels.decription)
    }
}


$RTVersion = $(Get-Content "$CacheRoot\\RogueTech Core\\mod.json" -raw | ConvertFrom-Json).Version

write-progress -activity 'Forming Wiki Table'
#init table text
$ClassTable = "" 
$WikiTable = "Last Updated RT Version $RTVersion`r`n`r`n"
$WikiMexTable = ""

#Lead Page name goes here in wikimedia bold
$WikiPageTitle = "Mechs"
$WikiTable = "@@@$WikiPageTitle@@@`r`n" + $WikiTable

#load objects
$MechsMasterObject = $(Get-Content $TableFile -Raw | ConvertFrom-Json)
$PrefabID = $(Get-Content $PrefabIDFile -Raw | ConvertFrom-Json)

#categories
$CatOrder = @('POWER','LIGHT','MEDIUM','HEAVY','ASSAULT','SHEAVY')
$CatTitles = @('Power Armour','Light Mechs','Medium Mechs','Heavy Mechs','Assault Mechs','Super Heavies')
$CatTonnage = @('Under 20','20-35','40-55','60-75','80-100','Over 100')

#SortTable
$HPTopSort = @('LA','HD','RA')
$HPMidSort = @('LT','CT','RT')
$HPBotSort = @('LL','','RL')
$HPSort= @($HPTopSort, $HPMidSort, $HPBotSort)
$TableRowNames = @('Arms/Head','Torso','Legs')
$HPLongSortHash = @{
    LA = 'LeftArm'
    HD = 'Head'
    RA = 'RightArm'
    LT = 'LeftTorso'
    CT = 'CenterTorso'
    RT = 'RightTorso'
    LL = 'LeftLeg'
    RL = 'RightLeg'
}

#Mounts
$Mounts = @('O','B','E','M','S','BA','JJ')
$MountsLongHash = @{
    O = 'Omni'
    B = 'Ballistic'
    E = 'Energy'
    M = 'Missile'
    S = 'AntiPersonnel'
    BA = 'BattleArmor'
    JJ = 'JumpJet'
}

#load blurb
$WikiTable += $(Get-Content $Blurb -raw) + "`r`n"

#Generate MDefLinkName hash with $MechsMasterObject
$MechMDefLinkHash = @{}
$MechsMasterObject | % {$MechMDefLinkHash.Add($_.MechDefFile, $_.Name.LinkName)}

#Localization File
Write-Progress -Activity "Scanning Text Objects"
$TextFileName = "Localization.json"
$TextFileList = $(Get-ChildItem $CacheRoot -Recurse -Filter $TextFileName)
$TextObject = $null
foreach ($TextFile in $TextFileList) {
    $TextObject += $TextFile | Get-Content -raw | ConvertFrom-Json
}

#START PAGE JOBS HERE
$WikiOutFolder = $RTScriptroot+"\\Outputs\\Mechs"
$JobOutFolder = $WikiOutFolder+"\\Job"
#Purge Folder
Remove-Item "$WikiOutFolder\\*" -Recurse -Force
$null = New-Item -ItemType Directory $JobOutFolder
Get-Job | Remove-Job -Force

$ThreadCount = 32 #Number of desired threads
#get trimmed count
$Divisor = (($MechsMasterObject.Count - ($MechsMasterObject.Count % $ThreadCount)) / $ThreadCount)
#if there's remainder, round it up
if ($MechsMasterObject.Count % $ThreadCount -ne 0) {
    $Divisor++ 
}
#divisor = number of units to chuck into a job
for ($JobCount=0;$JobCount -lt $ThreadCount; $JobCount++) {
    #start job to build item page from $masterlist
    if ($JobCount -eq $ThreadCount - 1) {
        $JobInputObject = $MechsMasterObject[$(0+($JobCount*$Divisor))..$($($MechsMasterObject.Count)-1)]
    } else {
        $JobInputObject = $MechsMasterObject[$(0+($JobCount*$Divisor))..$(($Divisor*(1+$JobCount))-1)]
    }
    $JobOutputFile = $JobOutFolder+"\\Chunk$JobCount.txt"
    Start-Job -Name $("ItemJob"+$JobCount) -FilePath D:\RogueTech\WikiGenerators\RT-CreateMechPages.ps1 -ArgumentList $JobInputObject,$Mounts,$MountsObject,$GroupObject,$CAffinitiesMaster,$HPSort,$TableRowNames,$ItemFriendlyHash,$GearObject,$ItemSlotsHash,$EquipAffinitiesIDNameHash,$EquipAffinitiesIDNumHash,$EquipAffinitiesIDDescHash,$PrefabID,$FactionIgnoreList,$MechMDefLinkHash,$GroupFriendlyObject,$FactionFriendlyObject,$HPLongSortHash,$MountsLongHash,$SpecialsObject,$JobOutputFile | Out-Null
}

#END PAGE JOBS HERE

$f = 0
$h = 0
foreach ($Cat in $CatOrder) {
    #if ($f -ge 10) {break} #for testing
    $CatHeaderName = $CatTitles[$h]
    $h++ 
    write-progress -activity "Filling Category" -Status "$h of $($CatOrder.Count)" -Id 1
#generate header
    $CatFriendly = $($CatObject | where -Property TagTitle -Contains $Cat).Friendly
    $CatHeader = @"
== $CatHeaderName == 
{| class="wikitable sortable mw-collapsible"
|+
! scope="col" style="width: 150px;" | Name
! Signature
! Weight
! Hardpoints 
! HP
! Special
"@
    $WikiTable += $CatHeader
    $MechsFilteredObject = $MechsMasterObject | where -Property class -contains $Cat | sort -Property ({$_.Name.Chassis}, {$_.Name.Variant}, {$_.Name.SubVariant}, {$_.Name.Unique}, {$_.Name.Hero})
    $MechsChassisGroup = $MechsFilteredObject | Group-Object -Property {$_.name.chassis}
    #build chassis table
    $g = 0
    foreach ($MechsChassis in $MechsChassisGroup) {
        $g++
        write-progress -activity "Chassis" -Status "$g of $($MechsChassisGroup.Count)" -Id 2 -ParentId 1
        #build table from bottom up, need to 'join' factions
        $ChassisTable = ""
        $VariantCount = $MechsChassis.Count
        $ChassisName = $MechsChassis.Name
        #sort backwards as we're building bottom up
        $Mechs = $MechsChassis.Group | sort -Property ({$_.Name.Hero}, {$_.Name.Unique}, {$_.Name.SubVariant}, {$_.Name.Variant}) -Descending
        $FactionGroupCounter = 0
        for ($i=0; $i -lt $VariantCount; $i++) {
            write-progress -activity "Variant" -Status "$($i + 1) of $VariantCount" -Id 3 -ParentId 2
            $f++
            write-progress -activity "Total" -Status "$f of $($MechsMasterObject.Count)"
            #init
            $Mech = $Mechs[$i]
            $j = $i
            $TagText = ""
            $MountsText = ""
            $FactionText = ""
            $GroupList = ""
            $FactionList = ""
            $VariantText = ""
            $LoadoutText = ""
            $LoadoutQuirkText = ""
            $LoadoutAffinityText = ""
            $HPText = ""
            #special
            foreach ($Tag in $Mech.Special) {
                $TagText += "[[Guides/Mech_Bay|$($($SpecialsObject | where -Property TagTitle -contains $Tag).Friendly)]]<br>`r`n"
            }
            $TagText = "|<small>$($TagText.Trim())</small>`r`n"
            $ChassisTable = $TagText+$ChassisTable

            #HP Main Only
            if (-not $Mech.BLACKLIST) {
                $HPText = "A=$($Mech.HP.SetArmor.Total)/$($Mech.HP.MaxArmor.Total) ''S=$($Mech.HP.Structure.Total)''"
            } else {
                $HPText = "CLASSIFIED"
            }
            $ChassisTable = "| "+$HPText+"`r`n"+$ChassisTable

            #main page hardpoints - list in $mounts in order of display
            if ($Mech.BLACKLIST) {
                $MountsText = "CLASSIFIED"
            } else {
                foreach ($Mount in $Mounts) {
                    $MountTag = $($MountsObject | where -Property Friendly -like $Mount).TagTitle
                    if ($($Mech.WeaponMounts | select -ExpandProperty $MountTag) -gt 0) {
                        $MountsText += "$($Mech.WeaponMounts | select -ExpandProperty $MountTag)$Mount "
                    }
                }
            }
            $MountsText = "$($MountsText.Trim())"
            $ChassisTable = "| "+$MountsText+"`r`n"+$ChassisTable
            #Weight
            $ChassisTable = "|$($Mech.Tonnage) [$CatFriendly]`r`n"+$ChassisTable
            
            #variant/signature
            $VariantLink = $($Mech.Name.Variant)
            $VariantGlue = $Mech.Name.LinkName
            $VariantText += "[["+$WikiPageTitle+"/"+"$VariantGlue|'''"+$($VariantLink+"'''"+$($Mech.Name.SubVariant)).Trim()+"]]`r`n"
            if (-not !$Mech.Name.Hero) {
                $VariantText += "($($Mech.Name.Hero))`r`n"
            }
            if (-not !$mech.Name.Unique) {
                $VariantText += "`'`'aka $($Mech.Name.Unique)`'`'`r`n"
            }
            $ChassisTable = "|-`r`n|$($VariantText.Trim())`r`n"+$ChassisTable

        }
        #remove leading row mark
        $ChassisTable = $($($ChassisTable.Substring(2)).Trim())
        #icon handling
        $IconFile = $Mech.Icon
        if (-not !$IconFile) {
            $IconName = $IconFile
        } else {
            #WATCH THIS TITLE CASE FUCKER. GODDAM YOU SUCK POWERSHELL
            $IconName = $((Get-Culture).TextInfo.ToTitleCase($($($Mech.Name.Chassis).ToLower())) -replace('[-_\W+]',''))
        }   
        #chassis name
        $ChassisTable = "|colspan=`"1`" rowspan=`"$VariantCount`" style=`"vertical-align:middle;text-align:center;`" | [[File:$IconName.png|link=|120px]]`r`n$($Mech.Name.Chassis)`r`n"+$ChassisTable
        #chassis table header
        $ChassisTable = "`r`n|-`r`n"+$ChassisTable
        $WikiTable += $ChassisTable

    }
    #generate Footer
    $CatFooter = "`r`n|}`r`n`r`n"
    $WikiTable += $CatFooter
}
#save it to file at end
$WikiTable = "{{-start-}}`r`n"+$WikiTable+"`r`n{{-stop-}}"
$WikiTable > $WikiPageFile
#Convert UTF8
Get-Content $WikiPageFile | Set-Content -Encoding UTF8 $WikiPageFileUTF8

while((Get-Job | Where-Object {$_.State -ne "Completed"}).Count -gt 0) {
    Start-Sleep -Milliseconds 250
    Write-Progress -id 0 -Activity 'Waiting for Item jobs'
    foreach ($job in (Get-Job)) {
        Write-Progress -Id $job.Id -Activity $job.Name -Status $job.State -ParentId 0
    }
}
#Cleanup Averages Job
Get-Job | Remove-Job

#Join into a supersized file for pwb upload - Item Pages
$(Get-ChildItem $JobOutFolder -Recurse -Exclude '!*').FullName | % {Get-Content $_ -Raw | Out-File "$WikiOutFolder\\!MechPages.txt" -Encoding utf8 -Append}
