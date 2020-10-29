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
<#
Write-Progress -Activity 'Gathering Item Friendly Names'
$AllJSON = Get-ChildItem $CacheRoot -Recurse -Filter "*.json" -Include 'Ammo*','Ammunition*','BoltOn*','default_*','emod*','gear*','hand*','lootable*','LoreGear*','NoBoxAmmo*','Omni*','PA*','PartialWing*','protomech*','prototype*','quirk_*','supercharged*','special_*','weapon*','zeusx*' -ErrorAction SilentlyContinue
#>
$GearFile = $RTScriptroot+"\\Outputs\\GearTable.json"
$GearObject = Get-Content $GearFile -raw | ConvertFrom-Json
$ItemFriendlyHash = @{}
foreach ($Item in $GearObject) {
    #$ItemObject = Get-Content $Item.FullName -Raw | ConvertFrom-Json
    if (-not !$Item.Description.UIName) {
        try {$ItemFriendlyHash.Add($Item.Description.Id,$Item.Description.UIName)} catch {Write-Host "Dupe: $($Item.Description.Id)"}
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
$WikiMexTable = ""

#Lead Page name goes here in wikimedia bold
$WikiPageTitle = "Mechs"
$WikiTable = "'''$WikiPageTitle'''`r`n" + $WikiTable

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

$f = 0
$h = 0
foreach ($Cat in $CatOrder) {
    $CatHeaderName = $CatTitles[$h]
    $h++ 
    write-progress -activity "Filling Category" -Status "$h of $($CatOrder.Count)" -Id 1
#generate header
    $CatFriendly = $($CatObject | where -Property TagTitle -Contains $Cat).Friendly
    $CatHeader = @"
== $CatHeaderName == 
{| class="wikitable sortable mw-collapsible"
|+
! Name
! Signature
! Weight !! Hardpoints 
! HP
! Special`r`n
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
            $HPText = ""
            #special
            foreach ($Tag in $Mech.Special) {
                $TagText += "[[Guides/Mech_Bay|$($($SpecialsObject | where -Property TagTitle -contains $Tag).Friendly)]]<br>`r`n"
            }
            $TagText = "|$($TagText.Trim())`r`n"
            $ChassisTable = $TagText+$ChassisTable
            #loadout
            if (-not $Mech.BLACKLIST) {
                #loadout subtable
                $LoadoutText = "`r`n==Loadout==`r`n"
                $LoadoutText += "`r`n"+'##LoadoutQuirkText##'+"`r`n"
                $LoadoutText += "`r`n{| class=`"wikitable`"`r`n"
                $LoadoutText += "|-`r`n! !! !! Left !! Center !! Right`r`n"
                
                $TableRowCount = 0
                foreach ($TableRow in $HPSort) {
                    $LoadoutText += "|-`r`n! rowspan=`"3`" | '''$($TableRowNames[$TableRowCount])'''`r`n"
                    $TableRowCount++
                    #MexPage HardPoints SubRow
                    $LoadoutText += "! HardPoints`r`n"
                    foreach ($TableLoc in $TableRow) {
                        $LoadoutText += "! ["
                        foreach ($Mount in $Mounts) {
                            $MountName = $MountsLongHash.$Mount
                            $MountCount = $($Mech.Hardpoint.$($HPLongSortHash.$TableLoc) | ? {$_ -match $MountName}).Count
                            if ($MountCount -gt 0) {
                                $LoadoutText += " $MountCount$Mount"
                            }
                        }
                        $LoadoutText += " ]`r`n"
                    }
                    #Fixed SubRow
                    $LoadoutText += "|-`r`n! Fixed`r`n"
                    foreach ($TableLoc in $TableRow) {
                        $LoadoutText += "|`r`n"
                        if ($TableLoc -ne '') {
                            $TableLocItemArray = $Mech.Loadout.Fixed.$($TableLoc) | group | sort Name
                            foreach ($FixedItem in $TableLocItemArray) {
                                if (-not !$($ItemFriendlyHash.$($FixedItem.Name))) {
                                    $FixedItemObj = $GearObject | where {$_.Description.Id -like $FixedItem.Name}
                                    if ($FixedItemObj.Custom.Category.CategoryID -match "quirk") {
                                        $LoadoutQuirkText += "* QUIRK: $($ItemFriendlyHash.$($FixedItem.Name))`r`n"
                                    } else {
                                        $LoadoutText += "* $($FixedItem.Count)x $($ItemFriendlyHash.$($FixedItem.Name))`r`n"
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
                                    if ($FixedItemObj.Custom.Category.CategoryID -match "quirk") {
                                        $LoadoutQuirkText += "* QUIRK: $($ItemFriendlyHash.$($FixedItem.Name))`r`n"
                                    } else {
                                        $LoadoutText += "* $($FixedItem.Count)x $($ItemFriendlyHash.$($FixedItem.Name))`r`n"
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
            }
            #HP
            $HPItems = @($($mech.HP.psobject.Properties | select -Property Name).Name)
            foreach ($HPItem in $HPItems) {
                #FUUUUUUUU imported as object. create a holder hash, dump object to hash, convert object to hashtable and overwrite
                $HolderHashHP = @{}
                $Mech.HP.$HPItem.psobject.Properties | foreach { $HolderHashHP[$_.Name] = $_.Value }
                $Mech.HP.$HPItem = @{}
                $Mech.HP.$HPItem = $HolderHashHP
                $HolderHPTotal = 0
                $Mech.HP.$HPItem.GetEnumerator() | foreach { $HolderHPTotal += $_.Value }
                $Mech.HP.$HPItem.Add("Total", $HolderHPTotal)
            }
            if (-not $Mech.BLACKLIST) {
                $HPText = "| A=$($Mech.HP.SetArmor.Total)/$($Mech.HP.MaxArmor.Total) ''S=$($Mech.HP.Structure.Total)''`r`n"
                $HPMexText = "`r`n==Mech Stats==`r`n"
                $HPMexText += "Tonnage: $($Mech.Tonnage)`r`n"
                $HPMexText += "`r`n{| class=`"wikitable`"`r`n"
                $HPMexText += "|-`r`n! Armor+Structure !! Left !! Center !! Right`r`n"
                $HPMexText += "|-`r`n! '''Arms/Head'''"
                $HPTopSort | foreach {
                    if (-not !$_) {
                        $HPMexText += "`r`n| A=$($Mech.HP.SetArmor.$_)/$($Mech.HP.MaxArmor.$_)<br>''S=$($Mech.HP.Structure.$_)''"
                    } else {
                        $HPMexText += "`r`n| "
                    }
                }
                $HPMexText += "`r`n|-`r`n! '''Torso'''"
                $HPMidSort | foreach {
                    if (-not !$_) {
                        $HPMexText += "`r`n| FA="+$($Mech.HP.SetArmor.$($_+"F"))+"/"+$($Mech.HP.MaxArmor.$($_+"F"))+"<br>RA="+$($Mech.HP.SetArmor.$($_+"R"))+"/"+$($Mech.HP.MaxArmor.$($_+"R"))+"<br>''S=$($Mech.HP.Structure.$_)''"
                    } else {
                        $HPMexText += "`r`n| "
                    }
                }
                $HPMexText += "`r`n|-`r`n! '''Legs'''"
                $HPBotSort | foreach {
                    if (-not !$_) {
                        $HPMexText += "`r`n| A=$($Mech.HP.SetArmor.$_)/$($Mech.HP.MaxArmor.$_)<br>''S=$($Mech.HP.Structure.$_)''"
                    } else {
                        $HPMexText += "`r`n| "
                    }
                }
                $HPMexText += "`r`n|-`r`n! colspan=`"4`" style=`"text-align: center;`" | '''TOTAL:''' A=$($Mech.HP.SetArmor.Total)/$($Mech.HP.MaxArmor.Total) ''S=$($Mech.HP.Structure.Total)''`r`n"
                $HPMexText += "`r`n|}`r`n"
            } else {
                $HPText = "| CLASSIFIED `r`n"
            }
            $ChassisTable = $HPText+$ChassisTable
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
            $MountsText = "|$($MountsText.Trim())`r`n"
            $ChassisTable = $MountsText+$ChassisTable
            #Weight
            $ChassisTable = "|$($Mech.Tonnage) [$CatFriendly]`r`n"+$ChassisTable
            #factions
            if (-not $Mech.BLACKLIST) {
                $FactionText = "`r`n==Factions==`r`n`r`n"
                # need to sort out for removing groups. Buried in here to only start parsing a stripped group when writing
                $GroupsArray = @($($GroupObject | select -ExcludeProperty BLACKLIST | Get-Member -MemberType NoteProperty).Name | ? {$_ -notlike '*BLACKLIST*'})
                # $Factionlist = working list
                $FactionList = $Mech.Factions | Where-Object {$_ -NotIn $FactionIgnoreList}
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
                    $FactionText += "* [[$($($GroupFriendlyObject | where -Property TagTitle -Like $FactionGroup).Friendly)]]`r`n"
                }
                foreach ($Faction in $FactionList) {
                    if (-not !$($FactionFriendlyObject.$Faction)) {
                        $FactionText += "* [[$($FactionFriendlyObject.$Faction)]]`r`n"
                    }
                }
            }
            #variant/signature
            #if blacklist, link to classified mech
            $VariantLink = $($Mech.Name.Variant)
            $VariantGlue = $($VariantLink+$($Mech.Name.SubVariant)).Trim()
            if (-not !$Mech.Name.Hero) {
                $VariantGlue += " ($($Mech.Name.Hero))"
            }
            if (-not !$mech.Name.Unique) {
                $VariantGlue += " aka $($Mech.Name.Unique)"
            }
            if ([bool]($BlacklistOverride | ? {$filePathMDef -match $_})) {
                $VariantGlue += " FP"
            }
            #unresolvable conflicts override
            if ([bool]($BlacklistOverride | ? {$filePathMDef -match $_})) {
                $VariantGlue += " $($Mech.Mod)"
            } elseif ($Mech.Name.Variant -eq 'CGR-C') {
                $VariantGlue += " -$($Mech.Name.Chassis)-"
            } elseif ($Mech.Name.Variant -eq 'MAD-BH') {
                $VariantGlue += " -$($Mech.Name.Chassis)-"
            } elseif ($Mech.Name.Variant -eq 'MAD-4S') {
                $VariantGlue += " -$($Mech.Name.Chassis)-"
            } elseif ($Mech.Name.Variant -eq 'BZK-P') {
                $VariantGlue += " -$($Mech.Name.Chassis)-"
            } elseif ($Mech.Name.Variant -eq 'BZK-RX') {
                $VariantGlue += " -$($Mech.Name.Chassis)-"
            } elseif ($Mech.Name.Variant -eq 'OSR-4C') {
                $VariantGlue += " -$($Mech.Name.Chassis)-"
            }
            $VariantText += "[["+$WikiPageTitle+"/"+"$VariantGlue|'''"+$($VariantLink+"'''"+$($Mech.Name.SubVariant)).Trim()+"]]`r`n"
            if (-not !$Mech.Name.Hero) {
                $VariantText += "($($Mech.Name.Hero))`r`n"
            }
            if (-not !$mech.Name.Unique) {
                $VariantText += "`'`'aka $($Mech.Name.Unique)`'`'`r`n"
            }
            $ChassisTable = "|-`r`n|$($VariantText.Trim())`r`n"+$ChassisTable

            #Compatible Variants
            $CompatVarText = "==Compatible Variants==`r`n"
            if (-not !$Mech.PrefabID) {
                if ($Mech.Special.Count -gt 0) {
                    if ([bool]($Mech.Special | ? {$_ -match 'OMNI'})) {
                        $CompatVarText += "This mech is an Omnimech and follows [[Guides/Mech Bay|Omnimech assembly rules]].`r`n"
                    } else { 
                        $CompatVarText += "This mech is a special mech and follows [[Guides/Mech Bay|special assembly rules]].`r`n"
                    }
                }
                foreach ($CompatVar in $PrefabID.$($Mech.PrefabID).$($Mech.Tonnage)) {
                    $CompatVarText += "`r`n* [[Mechs/"+$CompatVar+"|"+$CompatVar+"]]"
                }
            } else {
                $CompatVarText += "This mech has no compatible variants.`r`n"
            }

            #setup MexPage
            $WikiMexTable += "{{-start-}}`r`n'''"+$WikiPageTitle+"/"+$VariantGlue+"'''`r`n"
            if (-not $Mech.BLACKLIST) {
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
                $WikiMexTable += "`r`n==Description==`r`n`r`n"+$MechBlurb+"`r`n"
                $WikiMexTable += "`r`n"+$HPMexText+"`r`n"
                $WikiMexTable += "`r`n"+$LoadoutText+"`r`n"
                $WikiMexTable += "`r`n"+$CompatVarText+"`r`n"
                $WikiMexTable += "`r`n"+$FactionText+"`r`n"
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
        $ChassisTable = "|colspan=`"1`" rowspan=`"$VariantCount`" |{{FP icon|$IconName.png|$($Mech.Name.Chassis)}}`r`n"+$ChassisTable
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
$WikiMexTable > $WikiPageMexFile
#Convert UTF8
Get-Content $WikiPageFile | Set-Content -Encoding UTF8 $WikiPageFileUTF8
Get-Content $WikiPageMexFile | Set-Content -Encoding UTF8 $WikiPageMexFileUTF8
if ($UploadToWiki) {
    py $PWBRoot\\pwb.py login
    cls
    py $PWBRoot\\pwb.py pagefromfile -file:$WikiPageFileUTF8 -notitle -force -pt:0
    cls
    py $PWBRoot\\pwb.py pagefromfile -file:$WikiPageMexFileUTF8 -notitle -force -pt:0
    cls
}