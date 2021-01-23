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
$WikiID = "TankList"
$MexID = "Tanx"
#Blurb that goes before 
$Blurb = "$RTScriptroot\\Inputs\\$($WikiID)Blurb.txt"
$TableFile = "$RTScriptroot\\Outputs\\$($WikiID)Table.json"
$WikiPageFile = "$RTScriptroot\\Outputs\\$($WikiID)WikiPage.txt"
$WikiPageFileUTF8 = "$RTScriptroot\\Outputs\\$($WikiID)WikiPage.UTF8"
$WikiPageMexFile = "$RTScriptroot\\Outputs\\$($MexID)WikiPage.txt"
$WikiPageMexFileUTF8 = "$RTScriptroot\\Outputs\\$($MexID)WikiPage.UTF8"
$ClassFile = "$RTScriptroot\\Inputs\\Class.csv"
$ClassObject = Get-Content $ClassFile -raw | ConvertFrom-Csv
$SpecialsFile = "$RTScriptroot\\Inputs\\VehicleSpecial.csv"
$SpecialsObject = Get-Content $SpecialsFile -Raw | ConvertFrom-Csv
$MountsFile = "$RTScriptroot\\Inputs\\WeaponMounts.csv"
$MountsObject = Get-Content $MountsFile -Raw | ConvertFrom-Csv
$GroupingFile = "$RTScriptroot\\Inputs\\FactionGrouping.csv"
$GroupingCSVObject = Import-Csv -Path "$GroupingFile" 
$PWBRoot = "D:\\PYWikiBot"
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
foreach ($Key in $GroupKeyList) {
    foreach ($FactionName in $GroupObject.$Key) {
        $FactionDefFileObj = $(Get-ChildItem $RTroot -Recurse -Filter "faction_$FactionName.json" -ErrorAction SilentlyContinue)
        if (-not !$FactionDefFileObj) {
            $FactionDefObj = $(Get-Content $FactionDefFileObj.VersionInfo.FileName -Raw | ConvertFrom-Json)
            $FactionFriendlyObject | Add-Member -Type NoteProperty -Name $FactionName -Value $($FactionDefObj.Name).Replace("the ","")
        }
    }
}
#FactionIgnoreList
$FactionIgnoreObj = Import-Csv "$RTScriptroot\\Inputs\\FactionIgnoreList.csv"
$FactionIgnoreList = @($FactionIgnoreObj.IgnoreUs)
#Icon Names LAWD!
$IconFilesList = Get-ChildItem $CacheRoot -Recurse -Filter "*.dds"

#Build Item Friendly Name Hash
Write-Progress -Activity 'Gathering Item Friendly Names'
$GearFile = $RTScriptroot+"\\Outputs\\GearTable.json"
$GearObject = Get-Content $GearFile -raw | ConvertFrom-Json
$ItemFriendlyHash = @{}
foreach ($Item in $GearObject) {
    #$ItemObject = Get-Content $Item.FullName -Raw | ConvertFrom-Json
    if (-not !$Item.Description.UIName) {
        try {$ItemFriendlyHash.Add($Item.Description.Id,$Item.Description.UIName)} catch {Write-Host "Dupe: $($Item.Description.Id)"}
    }
}

#Get RT Version
$RTVersion = $(Get-Content "$CacheRoot\\RogueTech Core\\mod.json" -raw | ConvertFrom-Json).Version

write-progress -activity 'Forming Wiki Table'
#init table text
$ClassTable = "" 
$WikiTable = "Last Updated RT Version $RTVersion`r`n`r`n"
$WikiMexTable = ""

#Lead Page name goes here in wikimedia bold
$WikiPageTitle = "Vehicles"
$WikiTable = "'''$WikiPageTitle'''`r`n" + $WikiTable

#load objects
$MechsMasterObject = $(Get-Content $TableFile -Raw | ConvertFrom-Json)

#categories
$TanksClassOrder = @('LIGHT','MEDIUM','HEAVY','ASSAULT','SHEAVY')
$TanksClassTitles = @('Light Tanks','Medium Tanks','Heavy Tanks','Assault Tanks','Super Heavy Tanks')
$TanksClassTonnage = @('20-35','40-55','60-75','80-100','Over 100')
$VTOLsClassOrder = @('LIGHT','MEDIUM','HEAVY','ASSAULT')
$VTOLsClassTitles = @('Light VTOL','Medium VTOL','Heavy VTOL','Assault VTOL')
$VTOLsClassTonnage = @('Under 20','20-30','35-45','Over 45')
$VTOLOrder = @($false,$true)

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

#for tanks then vtols

$i = 0
$z = 0
foreach ($VTOL in $VTOLOrder) {
    if (-not $VTOL) {
        $Type = "Tanks"
    } else {
        $Type = "VTOLs"
    }
    $TypeHeader = "`r`n==$Type==`r`n"
    $WikiTable += $TypeHeader
    $ClassOrder = $(Get-Variable -Name $($Type+"ClassOrder")).Value
    $ClassTitles = $(Get-Variable -Name $($Type+"ClassTitles")).Value
    $ClassTonnage = $(Get-Variable -Name $($Type+"ClassTonnage")).Value
    Write-Progress -Activity "Filling Type" -Status "$($i+1) of $($VTOLOrder.Count)" -Id 1
    $j = 0
    # then by class
    foreach ($Class in $ClassOrder) {
        Write-Progress -Activity "Filling Class" -Status "$($j+1) of $($ClassOrder.Count)" -Id 2 -ParentId 1
        $ClassHeaderName = $ClassTitles[$j]
        $ClassFriendly = $($ClassObject | where -Property TagTitle -Contains $Class).Friendly
        $ClassHeader = @"
`r`n=== $ClassHeaderName === 

{| class="wikitable sortable mw-collapsible"
|+
! Chassis !! Variant !! Weight !! Hardpoints !! HP !! Special`r`n
"@
        $WikiTable += $ClassHeader
        $MechsFilteredObject = $MechsMasterObject | where -Property VTOL -like $VTOL | where -Property Class -contains $Class | sort -Property ({$_.Name.Chassis}, {$_.Name.Variant})
        $MechsChassisGroup = $MechsFilteredObject | Group-Object -Property {$_.Name.Chassis}
        #build chassis table
        $k = 0
        foreach ($MechsChassis in $MechsChassisGroup) {
            $k++ 
            write-progress -activity "Chassis" -Status "$k of $($MechsChassisGroup.Count)" -Id 3 -ParentId 2
            $ChassisTable = "|-`r`n"
            $VariantCount = $MechsChassis.Count
            <#
            #icon handling
            $IconFile = $Mech.Icon
            if (-not !$IconFile) {
                $IconName = $IconFile
            } else {
                #WATCH THIS TITLE CASE FUCKER GODDAM YOU SUCK POWERSHELL
                $IconName = $((Get-Culture).TextInfo.ToTitleCase($($($Mech.Name.Chassis).ToLower())) -replace('[-_\W+]',''))
            } 
            #>
            $ChassisTable += "|colspan=`"1`" rowspan=`"$VariantCount`" | $($MechsChassis.Name)`r`n"
            $Mechs = $MechsChassis.Group | sort -Property ({$_.Name.Link})
            for ($l=0; $l -lt $VariantCount; $l++) {
                $Mech = $Mechs[$l]
                write-progress -activity "Variant" -Status "$($l + 1) of $VariantCount" -Id 4 -ParentId 3
                $z++
                write-progress -activity "Total" -Status "$z of $($MechsMasterObject.Count)"
                #reinit
                $TagText = ""
                $MountsText = ""
                $FactionText = ""
                $GroupList = ""
                $FactionList = ""
                $VariantText = ""
                $LoadoutText = ""
                $LoadoutFixedText = ""
                $LoadoutDynamicText = ""
                $LoadoutQuirkText = ""
                $HPText = ""
                $SubVar = ""
                #Variant
                #Need some extra name fuckery for subvariants
                <#
                #Create Link Name
                $NameArray = $($Mech.Name.Full -Replace "(\W+)","_").Trim("_").Split("_")
                $IDArray = $Mech.ID.Split("_")
                foreach ($NameItem in $NameArray) {
                    $IDArray = [Array]$($IDArray | where { $_ -ne $NameItem })
                }
                foreach ($IDItem in $IDArray) {
                    $SubVar += $IDItem + " "
                }
                $VariantLink = $($Mech.Name.Full + " " + $SubVar).Trim().ToUpper()
                #>
                
                $VariantLink = $($Mech.Name.Full + " " + $Mech.Name.SubVar)
                $VariantLink = $VariantLink.Replace("'","")
                $VariantLink = $VariantLink.Trim()
                #if not first variant, start new row. 
                if ($l -ne 0) {
                    $ChassisTable += "|-`r`n"
                }
                $VariantText += "[["+$WikiPageTitle+'/'+$VariantLink+"|'''"+$VariantLink+"''']]`r`n"
                $ChassisTable += "|$($VariantText.Trim())`r`n"
                #Weight/Class
                $ChassisTable += "|$($Mech.Tonnage) [$ClassFriendly]`r`n"
                #Hardpoints
                if ($Mech.BLACKLIST) {
                    $MountsText = "CLASSIFIED"
                } else {
                    $Mounts = @('O','B','E','M','S','BA','JJ')
                    foreach ($Mount in $Mounts) {
                        $MountTag = $($MountsObject | where -Property Friendly -like $Mount).TagTitle
                        if ($($Mech.WeaponMounts | select -ExpandProperty $MountTag) -gt 0) {
                            $MountsText += "$($Mech.WeaponMounts | select -ExpandProperty $MountTag)$Mount "
                        }
                    }
                }
                $MountsText = "|$($MountsText.Trim())`r`n"
                $ChassisTable += $MountsText
                #HP
                $HPItems = @($($mech.HP.psobject.Properties | select -Property Name).Name)
                foreach ($HPItem in $HPItems) {
                    #FUUUUUUUU imported as object. create a holder hash, dump object to hash, convert object to hashtable and overwrite
                    $HolderHashHP = @{}
                    $Mech.HP.$HPItem.psobject.Properties | where -Property MemberType -Like NoteProperty | foreach { $HolderHashHP[$_.Name] = $_.Value }
                    $Mech.HP.$HPItem = @{}
                    $Mech.HP.$HPItem = $HolderHashHP
                    $HolderHPTotal = 0
                    $Mech.HP.$HPItem.GetEnumerator() | foreach { $HolderHPTotal += $_.Value }
                    $Mech.HP.$HPItem.Add("Total", $HolderHPTotal)
                }
                if (-not $Mech.BLACKLIST) {
                    $HPText = "| A=$($Mech.HP.SetArmor.Total)/$($Mech.HP.MaxArmor.Total) ''S=$($Mech.HP.Structure.Total)''`r`n"
                    $HPTopSort = @($null,'Front',$null)
                    $HPMidSort = @('Left','Turret','Right')
                    $HPBotSort = @($null,'Rear',$null)
                    $HPMexText = "`r`n==Vehicle HP==`r`n"
                    $HPMexText += "`r`n{| class=`"wikitable`"`r`n"
                    $HPMexText += "|-`r`n! !! Left !! Center !! Right`r`n"
                    $HPMexText += "|-`r`n| '''Front'''"
                    $HPTopSort | foreach {
                        if (-not !$_) {
                            $HPMexText += "`r`n| A=$($Mech.HP.SetArmor.$_)/$($Mech.HP.MaxArmor.$_)<br>''S=$($Mech.HP.Structure.$_)''"
                        } else {
                            $HPMexText += "`r`n| "
                        }
                    }
                    $HPMexText += "`r`n|-`r`n| '''Sides/Turret'''"
                    $HPMidSort | foreach {
                        if (-not !$_) {
                            $HPMexText += "`r`n| A=$($Mech.HP.SetArmor.$_)/$($Mech.HP.MaxArmor.$_)<br>''S=$($Mech.HP.Structure.$_)''"
                        } else {
                            $HPMexText += "`r`n| "
                        }
                    }
                    $HPMexText += "`r`n|-`r`n| '''Rear'''"
                    $HPBotSort | foreach {
                        if (-not !$_) {
                            $HPMexText += "`r`n| A=$($Mech.HP.SetArmor.$_)/$($Mech.HP.MaxArmor.$_)<br>''S=$($Mech.HP.Structure.$_)''"
                        } else {
                            $HPMexText += "`r`n| "
                        }
                    }
                    $HPMexText += "`r`n|-`r`n| colspan=`"4`" style=`"text-align: center;`" | '''TOTAL:''' A=$($Mech.HP.SetArmor.Total)/$($Mech.HP.MaxArmor.Total) ''S=$($Mech.HP.Structure.Total)''`r`n"
                    $HPMexText += "`r`n|}`r`n"
                } else {
                    $HPText = "| CLASSIFIED `r`n"
                }
                $ChassisTable += $HPText
                #Special
                foreach ($Tag in $Mech.Special) {
                    $TagText += "$($($SpecialsObject | where -Property TagTitle -contains $Tag).Friendly)<br>`r`n"
                }
                $TagText = "|$($TagText.Trim())`r`n"
                $ChassisTable += $TagText
                #Loadout
                if (-not $Mech.BLACKLIST) {
                    #loadout subtable
                    $LoadoutText = "`r`n==Loadout==`r`n"
                
                    #load Fixed
                    if ($Mech.Loadout.PSObject.Properties.name -match 'Fixed') {
                        foreach ($FixedItem in $Mech.Loadout.Fixed) {
                            if ($FixedItem -notlike "") {
                                if (-not !$($ItemFriendlyHash.$($FixedItem.Name))) {
                                    $FixedItemObj = $GearObject | where {$_.Description.Id -like $FixedItem.Name}
                                    if ($FixedItemObj.Custom.Category.CategoryID -match "quirk") {
                                        $LoadoutQuirkText += "* QUIRK: $($ItemFriendlyHash.$($FixedItem.Name))`r`n"
                                    } else {
                                        $LoadoutFixedText += "* $($FixedItem.Count)x $($ItemFriendlyHash.$($FixedItem.Name))`r`n"
                                    }
                                }
                            }
                        }
                    }
                    $LoadoutText += "`r`n"+$LoadoutQuirkText+"`r`n"
                    $LoadoutText += "`r`n{| class=`"wikitable`"`r`n|+`r`n! Fixed !! Dynamic`r`n|-`r`n"
                    $LoadoutText += "|`r`n$($LoadoutFixedText.Trim())`r`n"
                    #load Dynamic
                    if ($Mech.Loadout.PSObject.Properties.name -match 'Dynamic') {
                        foreach ($DynamicItem in $Mech.Loadout.Dynamic) {
                            if (-not !$($ItemFriendlyHash.$($DynamicItem.Name))) {
                                $LoadoutDynamicText += "* $($DynamicItem.Count)x $($ItemFriendlyHash.$($DynamicItem.Name))`r`n"
                            }
                        }
                    }
                    $LoadoutText += "|`r`n$($LoadoutDynamicText.Trim())`r`n"
                    #wrap loadout
                    $LoadoutText = "$($LoadoutText.Trim())`r`n|}`r`n"
                }
                #Faction
                if (-not $Mech.BLACKLIST) {
                    $FactionText = "`r`n==Factions==`r`n`r`n"
                    # need to sort out for removing groups. Buried in here to only start parsing a stripped group when writing
                    $GroupsArray = @($($GroupObject | select -ExcludeProperty BLACKLIST | Get-Member -MemberType NoteProperty).Name)
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
                #setup MexPage
                $WikiMexTable += "{{-start-}}`r`n'''"+$WikiPageTitle+'/'+$VariantLink+"'''`r`n"
                if ($Mech.BLACKLIST) {
                    $WikiMexTable += "#REDIRECT [[Classified]]`r`n"
                } else {
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
                    $WikiMexTable += "`r`n==Description==`r`n`r`nTonnage: $($Mech.Tonnage)`r`n`r`n"+$MechBlurb+"`r`n"
                    $WikiMexTable += "`r`n"+$HPMexText+"`r`n"
                    $WikiMexTable += "`r`n"+$LoadoutText+"`r`n"
                    $WikiMexTable += "`r`n"+$FactionText+"`r`n"
                    #$MechBayDef = $Mech.MechDefFile -split '\\'
                    #$MechBayPNG = $($MechBayDef[$MechBayDef.Count-1] -split ".json")[0]
                    #$WikiMexTable += "`r`n==Mech Bay==`r`n`r`n[[File:$MechBayPNG.png|frameless|1340x1340px]]`r`n"
                }
                $WikiMexTable +="{{-stop-}}`r`n"
            }
            $WikiTable += $ChassisTable
        }
        #generate Footer
        $ClassFooter = "`r`n|}`r`n`r`n"
        $WikiTable += $ClassFooter
        $j++
    }
    $i++
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