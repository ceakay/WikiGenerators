﻿###FUNCTIONS
$AutomaticVariables = Get-Variable
function RT-ScriptVars {
    Compare-Object (Get-Variable) $AutomaticVariables -Property Name -PassThru | Where -Property Name -ne "AutomaticVariables"
}

#data chopper function
    #args: delimiter, position, input
function datachop {
    $array = @($args[2] -split "$($args[0])")    
    return $array[$args[1]]
}

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
    $FactionDefObj = Get-Content $FactionFriendlyFile.VersionInfo.FileName -Raw | ConvertFrom-Json
    try {$FactionFriendlyObject | Add-Member -Type NoteProperty -Name $FactionDefObj.factionID -Value $($FactionDefObj.Name).Replace("the ","")} catch { $FactionFriendlyFile }
}

#FactionIgnoreList
$FactionIgnoreObj = Import-Csv "$RTScriptroot\\Inputs\\FactionIgnoreList.csv"
$FactionIgnoreList = @($FactionIgnoreObj.IgnoreUs)
#Icon Names LAWD!
$IconFilesList = Get-ChildItem $CacheRoot -Recurse -Filter "*.dds"

#Build Item Friendly Name Hash
<#
Write-Progress -Activity 'Gathering Item Friendly Names'
$AllJSON = Get-ChildItem $CacheRoot -Recurse -Filter "*.json" -Include 'Ammo*','Ammunition*','BoltOn*','default_*','emod*','gear*','hand*','lootable*','LoreGear*','NoBoxAmmo*','Omni*','PA*','PartialWing*','protomech*','prototype*','quirk_*','supercharged*','special_*','weapon*','zeusx*' -ErrorAction SilentlyContinue
#>
$GearFile = $RTScriptroot+"\\Outputs\\GearTable.json"
$GearObject = Get-Content $GearFile -raw | ConvertFrom-Json
$ItemFriendlyHash = @{}
foreach ($Item in $GearObject) {
    if (-not !$Item.Description.UIName) {
        try {$ItemFriendlyHash.Add($Item.Description.Id,$Item.Description.UIName)} catch {Write-Host "Dupe: $($Item.Description.Id)"}
    }
}
#build Item Slots hash
$ItemSlotsHash = @{}
foreach ($Item in $GearObject) {
    if (-not !$Item.InventorySize) {
        try {$ItemSlotsHash.Add($Item.Description.Id,$Item.InventorySize)} catch {Write-Host "Dupe: $($Item.Description.Id)"}
    } else {
        try {$ItemSlotsHash.Add($Item.Description.Id,1)} catch {Write-Host "Dupe: $($Item.Description.Id)"}
    }
}

#Build ChassisAffinities
$AffinitiesFile = "$CacheRoot\\MechAffinity\\settings.json"
$CAffinitiesMaster = $(Get-Content $AffinitiesFile -Raw | ConvertFrom-Json).chassisAffinities

$RTVersion = $(Get-Content "$CacheRoot\\RogueTech Core\\mod.json" -raw | ConvertFrom-Json).Version

write-progress -activity 'Forming Wiki Table'
#init table text
$ClassTable = "" 
$WikiTable = "Last Updated RT Version $RTVersion`r`n`r`n"

#Lead Page name goes here in wikimedia bold
$WikiPageTitle = "Mechs"
$WikiTable = "'''$WikiPageTitle'''`r`n" + $WikiTable

#load objects
$MechsMasterObject = $(Get-Content $TableFile -Raw | ConvertFrom-Json)
$PrefabID = $(Get-Content $PrefabIDFile -Raw | ConvertFrom-Json)

#categories
$CatOrder = @('POWER','LIGHT','MEDIUM','HEAVY','ASSAULT','SHEAVY')
<#$CatTitles = @{
    POWER = 'Power Armour'
    LIGHT = 'Light Mechs'
    MEDIUM = 'Medium Mechs'
    HEAVY = 'Heavy Mechs'
    ASSAULT = 'Assault Mechs'
    SHEAVY = 'Super Heavies'
}#>

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
    S = 'Support'
    BA = 'BattleArmor'
    JJ = 'JumpJet'
}

#load blurb
$WikiTable += $(Get-Content $Blurb -raw) + "`r`n"

#Localization File
Write-Progress -Activity "Scanning Text Objects"
$TextFileName = "Localization.json"
$TextFileList = $(Get-ChildItem $CacheRoot -Recurse -Filter $TextFileName)
$TextObject = $null
foreach ($TextFile in $TextFileList) {
    $TextObject += $TextFile | Get-Content -raw | ConvertFrom-Json
}

$CatBlock = {
    #use all declared variables and plunk into scriptblock
    $CatBlockVarList = $using:CatBlockVarList
    foreach ($VarPair in $CatBlockVarList.GetEnumerator()) {
        Set-Variable -Name $($VarPair.Name) -Value $($VarPair.Value)
    }
    #functionlol
    function datachop {
        $array = @($args[2] -split "$($args[0])")    
        return $array[$args[1]]
    }
    $WikiTable = ""
    $WikiMexTable = ""
    #build chassis table
    foreach ($MechsChassis in $MechsChassisGroup) {
        #build table from bottom up, need to 'join' factions
        $ChassisTable = ""
        $VariantCount = $MechsChassis.Count
        $ChassisName = $MechsChassis.Name
        #sort backwards as we're building bottom up
        $Mechs = $MechsChassis.Group | sort -Property ({$_.Name.Hero}, {$_.Name.Unique}, {$_.Name.SubVariant}, {$_.Name.Variant}) -Descending
        $FactionGroupCounter = 0
        for ($i=0; $i -lt $VariantCount; $i++) {
            write-progress -activity "Variant" -Status "$($i + 1) of $VariantCount" -Id 3 -ParentId 2
            #init
            $Mech = $Mechs[$i]
            $TagText = ""
            $MountsText = ""
            $FactionText = ""
            $GroupList = ""
            $FactionList = ""
            $VariantText = ""
            $LoadoutText = ""
            $LoadoutQuirkText = ""
            $HPText = ""
            #special
            foreach ($Tag in $Mech.Special) {
                $TagText += "[[Guides/Mech_Bay|$($($SpecialsObject | where -Property TagTitle -contains $Tag).Friendly)]]<br>`r`n"
            }
            $TagText = "|<small>$($TagText.Trim())</small>`r`n"
            $ChassisTable = $TagText+$ChassisTable
            #HP fix
            #FUUUUUUUU imported as object. create a holder hash, dump object to hash, convert object to hashtable and overwrite
            $HPItems = @($($mech.HP.psobject.Properties | select -Property Name).Name)
            foreach ($HPItem in $HPItems) {
                $HolderHashHP = @{}
                $Mech.HP.$HPItem.psobject.Properties | foreach { $HolderHashHP[$_.Name] = $_.Value }
                $Mech.HP.$HPItem = @{}
                $Mech.HP.$HPItem = $HolderHashHP
                $HolderHPTotal = 0
                $Mech.HP.$HPItem.GetEnumerator() | foreach { $HolderHPTotal += $_.Value }
                $Mech.HP.$HPItem.Add("Total", $HolderHPTotal)
            }
            #loadout/HP
            $LoadoutQuirkText = ""

            #loadout subtable
            $LoadoutText = "`r`n==Mech Bay==`r`n"
            $LoadoutText += "`r`n"+'##LoadoutQuirkText##'+"`r`n"
            $LoadoutText += "`r`n{| class=`"wikitable`"`r`n"
            $LoadoutText += "|-`r`n! !! !! Left !! Center !! Right`r`n"
                
            $TableRowCount = 0
            foreach ($TableRow in $HPSort) {
                $LoadoutText += "|-`r`n! rowspan=`"4`" | '''$($TableRowNames[$TableRowCount])'''`r`n"
                #MexPage Health/HP
                $LoadoutText += "! Health`r`n"
                if ($TableRowCount -eq 1) {
                    #Torso Row
                    foreach ($TableLoc in $TableRow) {
                        if (-not !$TableLoc) {
                            $LoadoutText += "! FA="+$($Mech.HP.SetArmor.$($TableLoc+"F"))+"/"+$($Mech.HP.MaxArmor.$($TableLoc+"F"))+" RA="+$($Mech.HP.SetArmor.$($TableLoc+"R"))+"/"+$($Mech.HP.MaxArmor.$($TableLoc+"R"))+"<br>''S=$($Mech.HP.Structure.$TableLoc)''`r`n"
                        } else {
                            $LoadoutText += "! `r`n"
                        }
                    }
                } else {
                    foreach ($TableLoc in $TableRow) {
                        if (-not !$TableLoc) {
                            $LoadoutText += "! A=$($Mech.HP.SetArmor.$TableLoc)/$($Mech.HP.MaxArmor.$TableLoc)<br>''S=$($Mech.HP.Structure.$TableLoc)''`r`n"
                        } else {
                            $LoadoutText += "! `r`n"
                        }
                    }
                }
                $TableRowCount++
                #MexPage HardPoints SubRow
                $LoadoutText += "|-`r`n! HardPoints`r`n"
                foreach ($TableLoc in $TableRow) {
                    if (-not !$TableLoc) {
                        $LoadoutText += "! ["
                        foreach ($Mount in $Mounts) {
                            $MountName = $MountsLongHash.$Mount
                            $MountCount = $($Mech.Hardpoint.$($HPLongSortHash.$TableLoc) | ? {$_ -match $MountName}).Count
                            if ($MountCount -gt 0) {
                                $LoadoutText += " $MountCount$Mount"
                            }
                        }
                        $LoadoutText += " ]`r`n"
                    } else {
                        $LoadoutText += "! `r`n"
                    }
                }
                #Fixed SubRow
                $LoadoutText += "|-`r`n! Fixed`r`n"
                foreach ($TableLoc in $TableRow) {
                    $LoadoutText += "|`r`n"
                    if ([bool]($Mech.ArmActuatorSupport)) {
                        if (($TableLoc -eq 'LA') -or ($TableLoc -eq 'RA')) {
                            $LoadoutText += "Arm Limit: $($Mech.ArmActuatorSupport.$TableLoc)`r`n"
                        }
                    }
                    if ($TableLoc -ne '') {
                        $TableLocItemArray = $Mech.Loadout.Fixed.$($TableLoc) | group | sort Name
                        foreach ($FixedItem in $TableLocItemArray) {
                            if (-not !$($ItemFriendlyHash.$($FixedItem.Name))) {
                                $FixedItemObj = $GearObject | where {$_.Description.Id -like $FixedItem.Name}
                                $ItemFriendlyName = $($ItemFriendlyHash.$($FixedItem.Name))
                                if ($FixedItemObj.Custom.Category.CategoryID -match "positivequirk") {
                                    $LoadoutQuirkText = "* QUIRK: [[Gear/$ItemFriendlyName|$ItemFriendlyName]]`r`n" + $LoadoutQuirkText
                                } elseif ($FixedItemObj.Custom.Category.CategoryID -match "special") {
                                    $LoadoutQuirkText += "* Special: Fixed - [[Gear/$ItemFriendlyName|$ItemFriendlyName]]`r`n"
                                } else {
                                    $LoadoutText += "* $($FixedItem.Count)x [[Gear/$ItemFriendlyName|$ItemFriendlyName]] [$($ItemSlotsHash.$($FixedItem.Name))]`r`n"
                                }
                            }
                        }
                    }
                }
                #Dynamic SubRow
                $LoadoutText += "|-`r`n! Dynamic`r`n"
                foreach ($TableLoc in $TableRow) {
                    $LoadoutText += "|`r`n"
                    if ($TableLoc -ne '') {
                        $TableLocItemArray = $Mech.Loadout.Dynamic.$($TableLoc) | group | sort Name
                        foreach ($FixedItem in $TableLocItemArray) {
                            if (-not !$($ItemFriendlyHash.$($FixedItem.Name))) {
                                $FixedItemObj = $GearObject | where {$_.Description.Id -like $FixedItem.Name}
                                $ItemFriendlyName = $($ItemFriendlyHash.$($FixedItem.Name))
                                if ($FixedItemObj.Custom.Category.CategoryID -match "positivequirk") {
                                    $LoadoutQuirkText = "* QUIRK: [[Gear/$ItemFriendlyName|$ItemFriendlyName]]`r`n" + $LoadoutQuirkText
                                } elseif ($FixedItemObj.Custom.Category.CategoryID -match "special") {
                                    $LoadoutQuirkText += "* Special: Dynamic - [[Gear/$ItemFriendlyName|$ItemFriendlyName]]`r`n"
                                } else {
                                    $LoadoutText += "* $($FixedItem.Count)x [[Gear/$ItemFriendlyName|$ItemFriendlyName]] [$($ItemSlotsHash.$($FixedItem.Name))]`r`n"
                                }
                            }
                        }
                    }
                }
            }
            #wrap loadout
            $LoadoutText = "$($LoadoutText.Trim())`r`n|}`r`n"
            #do $$LoadoutQuirkText$$ replacement
            $LoadoutText = $($LoadoutText -split ("##LoadoutQuirkText##")) -join $LoadoutQuirkText
            
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
            #factions
            if (-not $Mech.BLACKLIST) {
                $FactionText = ""
                # need to sort out for removing groups. Buried in here to only start parsing a stripped group when writing
                $GroupsArray = @($($GroupObject | select -ExcludeProperty BLACKLIST | Get-Member -MemberType NoteProperty).Name | ? {$_ -notlike '*BLACKLIST*'})
                # $Factionlist = working list
                $FactionList = $Mech.Factions | Where-Object {$_ -NotIn $FactionIgnoreList}
                #clansgeneric
                if ([bool]($FactionList -match 'ClansGeneric')) {
                    $Mech.CLAN = $true
                    $FactionList = $($FactionList | Where-Object {($_ -notlike "ClansGeneric")})
                }
                #check each group
                $GroupList = @()
                foreach ($Group in $GroupsArray) {
                    #if marked true
                    if ($Mech.$Group) {
                        #add the Group into the $GroupList, merge after parsing
                        $GroupList += $Group 
                        #delete the group factions from Faction List
                        foreach ($DelFaction in $GroupObject.$Group) {
                            $FactionList = $($FactionList | Where-Object {($_ -notlike "$DelFaction")})
                        }
                    }
                }
                

                #parse FactionList and GroupList into Friendly
                foreach ($FactionGroup in $GroupList) {
                    $FactionText += "`r`n* [[$($($GroupFriendlyObject | where -Property TagTitle -Like $FactionGroup).Friendly)]]"
                }
                foreach ($Faction in $FactionList) {
                    if (-not !$($FactionFriendlyObject.$Faction)) {
                        $FactionText += "`r`n* [[$($FactionFriendlyObject.$Faction)]]"
                    }
                }
                $FactionText = "`r`n<div align=`"left`">"+$FactionText+"`r`n</div>"
            }
            #variant/signature
            #if blacklist, link to classified mech
            #VariantGlue moved to parser
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

            #Compatible Variants
            $CompatVarText = ""
            if (-not !$Mech.PrefabID) {
                if ($Mech.Special.Count -gt 0) {
                    if ([bool]($Mech.Special | ? {$_ -match 'OMNI'})) {
                        $CompatVarText += "`r`n-[[Guides/Mech Bay|Omnimech]]-`r`n"
                    } else { 
                        $CompatVarText += "`r`n-[[Guides/Mech Bay|Special]]-`r`n"
                    }
                }
                $CompatVarList = $PrefabID.$($Mech.PrefabID).$($Mech.Tonnage) | sort
                foreach ($CompatVar in $CompatVarList) {
                    $CompatVarText += "`r`n* [[Mechs/"+$CompatVar+"|"+$CompatVar+"]]"
                }
            } else {
                $CompatVarText += "`r`nNo Compatible"
            }
            $CompatVarText = "`r`n<div align=`"left`">"+$CompatVarText+"`r`n</div>"

            #setup MexPage
            $WikiMexTable += "{{-start-}}`r`n'''"+$WikiPageTitle+"/"+$VariantGlue+"'''`r`n"
            if (-not $Mech.BLACKLIST) {
                #Setup Infobox
                $WikiMexTable += "{{Infobox MechPage`r`n"
                $WikiMexTable += "| name = $($Mech.Name.MechUIName)`r`n"
                $WikiMexTable += "| signature  = $($Mech.Name.Variant)`r`n"
                $WikiMexTable += "| class      = $($CatFriendly)`r`n"
                $WikiMexTable += "| tonnage    = $($Mech.Tonnage)`r`n"
                $WikiMexTable += "| hardpoints = $($MountsText)`r`n"
                $WikiMexTable += "| health     = $($HPText)`r`n"
                $WikiMexTable += "| rtmodule   = $($Mech.Mod)`r`n"
                $WikiMexTable += "| variants   = $CompatVarText`r`n"
                $WikiMexTable += "| factions   = $FactionText`r`n"
                $WikiMexTable += "}}`r`n"
                $BlurbCheck = $(datachop '__/' 1 $Mech.Blurb)
                if (-not !$BlurbCheck) {
                    $BlurbCheck = $(datachop '/__' 0 $BlurbCheck)
                    if ($($TextObject | where -Property "Name" -Like $BlurbCheck).Count -eq 1) {
                        $MechBlurb = $($TextObject | where -Property "Name" -Like $BlurbCheck).Original
                    } elseif ($($TextObject | where -Property "Name" -Like $BlurbCheck).Count -gt 1) {
                        $MechBlurb = $($TextObject | where -Property "Name" -Like $BlurbCheck)[0].Original
                    }
                } else {
                    $MechBlurb = $Mech.Blurb
                }
                #Chassis Affinities
                if (-not !$Mech.PrefabID) {
                    $ChassisAffinities = $($CAffinitiesMaster | ? {$_.chassisNames -match "$($Mech.PrefabID)_$($Mech.Tonnage)"}).affinityLevels
                }
                if (!$ChassisAffinities) {
                    $ChassisAffinities = $($CAffinitiesMaster | ? {$_.chassisNames -match "$($Mech.ChassisID)"}).affinityLevels
                }
                if (-not !$ChassisAffinities) {
                    $MechBlurb += "`r`n{| class=`"wikitable`"`r`n|-`r`n! Mech Affinity`r`n|-`r`n|"
                    foreach ($ChassisAffinity in $ChassisAffinities) {
                        $MechBlurb += "`r`n* $($ChassisAffinity.levelName) ($($ChassisAffinity.missionsRequired)): $($ChassisAffinity.decription)"
                    }
                    $MechBlurb += "`r`n|}"
                }
                #Regex cleanup
                $MechBlurb = $MechBlurb -Replace ('<color=(.*?)>(.*?)<\/color>','<span style="color:$1;">$2</span>') #replace color tag
                $MechBlurb = $MechBlurb -Replace ('<b>(.*?)<\/b>','$1') #remove bold
                $WikiMexTable += "`r`n==Description==`r`n`r`n"+$MechBlurb+"`r`n"
                $WikiMexTable += "`r`n"+$LoadoutText+"`r`n"
            } else {
                $WikiMexTable += "#REDIRECT [[Classified]]`r`n"
            }
            $WikiMexTable +="{{-stop-}}`r`n"
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

    }
    $ChassisTable | Set-Content -Encoding UTF8 "$RTScriptroot\\Outputs\\Mechs\\CatBlock\\##CatBlockText$z##.txt"
    $WikiPageMexFileUTF8 = $WikiPageMexFileUTF8.Replace(".UTF8","$z.UTF8")
    $WikiMexTable | Set-Content -Encoding UTF8 $WikiPageMexFileUTF8
}


$z = 0
foreach ($Cat in $CatOrder) {
    #Declare CatBlock
    $z++
    $CatBlockFile = "$RTScriptroot\\Outputs\\Mechs\\CatBlock\\##CatBlockText$z##.txt"
    $CatHeaderName = $($CatObject | where -Property TagTitle -Contains $Cat).FTitle
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
    $CatFooter = "`r`n|}`r`n`r`n"
    $CatBlockText = $CatHeader+"##CatBlockText$z##"+$CatFooter
    
    #Filter mechs
    $MechsFilteredObject = $MechsMasterObject | where -Property class -contains $Cat | sort -Property ({$_.Name.Chassis}, {$_.Name.Variant}, {$_.Name.SubVariant}, {$_.Name.Unique}, {$_.Name.Hero})
    $MechsChassisGroup = $MechsFilteredObject | Group-Object -Property {$_.name.chassis}

    $WikiMexTable = ""

    $CatBlockVarList = RT-ScriptVars
    Start-Job -Name $("CatBlockJob"+$z) -ScriptBlock $CatBlock | Out-Null #start job with $CatBlock
    $WikiTable += $CatBlockText
}

#wait for jobbed sections to finish
while((Get-Job | Where-Object {$_.State -ne "Completed"}).Count -gt 0) {
    Start-Sleep -Milliseconds 250
    Write-Progress -id 0 -Activity 'Waiting for jobs'
    foreach ($job in (Get-Job)) {
        Write-Progress -Id $job.Id -Activity $job.Name -Status $job.State -ParentId 0
    }
}
#Cleanup Averages Job
Get-Job | Remove-Job

#WikiMexTable subout
for ($m=1; $m -le $($CatOrder.Count); $m++) {
    $Search = "##CatBlockText$m##"
    $CatBlockFile = "$RTScriptroot\\Outputs\\Mechs\\CatBlock\\##CatBlockText$m##.txt"
    $CatBlockText = Get-Content $CatBlockFile -Raw
    $WikiTable = $WikiTable.Replace($Search,$CatBlockText)
}

#save it to file at end
$WikiTable = "{{-start-}}`r`n"+$WikiTable+"`r`n{{-stop-}}"

$WikiTable > $WikiPageFile
Get-Content $WikiPageFile | Set-Content -Encoding UTF8 $WikiPageFileUTF8

