Param(
    [Parameter(Mandatory = $True)]
    $InputObject,
        
    [Parameter(Mandatory = $True)]
    $Mounts,

    [Parameter(Mandatory = $True)]
    $MountsObject,

    [Parameter(Mandatory = $True)]
    $GroupObject,

    [Parameter(Mandatory = $True)]
    $CAffinitiesMaster,
    
    [Parameter(Mandatory = $True)]
    $HPSort,

    [Parameter(Mandatory = $True)]
    $TableRowNames,

    [Parameter(Mandatory = $True)]
    $ItemFriendlyHash,
    
    [Parameter(Mandatory = $True)]
    $GearObject,

    [Parameter(Mandatory = $True)]
    $ItemSlotsHash,

    [Parameter(Mandatory = $True)]
    $EquipAffinitiesIDNameHash,

    [Parameter(Mandatory = $True)]
    $EquipAffinitiesIDNumHash,

    [Parameter(Mandatory = $True)]
    $EquipAffinitiesIDDescHash,

    [Parameter(Mandatory = $True)]
    $PrefabID,
    
    [Parameter(Mandatory = $True)]
    $FactionIgnoreList,
    
    [Parameter(Mandatory = $True)]
    $MechMDefLinkHash,

    [Parameter(Mandatory = $True)]
    $GroupFriendlyObject,

    [Parameter(Mandatory = $True)]
    $FactionFriendlyObject,

    [Parameter(Mandatory = $True)]
    $HPLongSortHash,

    [Parameter(Mandatory = $True)]
    $MountsLongHash,
    
    [Parameter(Mandatory = $True)]
    $SpecialsObject,

    [Parameter(Mandatory = $True)]
    $OutputFile

)

###FUNCTIONS
#data chopper function
    #args: delimiter, position, input
function datachop {
    $array = @($args[2] -split "$($args[0])")    
    return $array[$args[1]]
}

##INITS
$WikiPageTitle = 'Mechs'

$ReturnText = ""
foreach ($Mech in $InputObject) {
    #setup MexPage
    $WikiMexTable += "{{-start-}}`r`n'''"+$WikiPageTitle+"/"+$($Mech.Name.LinkName)+"'''`r`n"
    if (-not $Mech.BLACKLIST) {

        #MountsText
        $MountsText = ""
        foreach ($Mount in $Mounts) {
            $MountTag = $($MountsObject | where -Property Friendly -like $Mount).TagTitle
            if ($($Mech.WeaponMounts | select -ExpandProperty $MountTag) -gt 0) {
                $MountsText += "$($Mech.WeaponMounts | select -ExpandProperty $MountTag)$Mount "
            }
        }
        #HPText
        $HPText = "A=$($Mech.HP.SetArmor.Total)/$($Mech.HP.MaxArmor.Total) ''S=$($Mech.HP.Structure.Total)''"

        #Compatible Variants
        $CompatVarText = ""
        if (-not !$Mech.PrefabID) {
            <#if ($Mech.Special.Count -gt 0) {
                if ([bool]($Mech.Special | ? {$_ -match 'OMNI'})) {
                    $CompatVarText += "`r`n-[[Guides/Mech Bay|Omnimech]]-`r`n"
                } else { 
                    $CompatVarText += "`r`n-[[Guides/Mech Bay|Special]]-`r`n"
                }
            }#>
            $CompatVarList = $PrefabID.$($Mech.PrefabID).$($Mech.Tonnage) | sort
            foreach ($CompatVar in $CompatVarList) {
                $CompatVarLinkName = $($MechMDefLinkHash.$CompatVar)
                $CompatVarText += "`r`n* [[Mechs/"+$CompatVarLinkName+"|"+$CompatVarLinkName+"]]"
            }
        } else {
            $CompatVarText += "`r`nNo Compatible"
        }
        $CompatVarText = "`r`n<div align=`"left`">"+$CompatVarText+"`r`n</div>"

        #Factions
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

        #loadoutText
        #loadout subtable
        $LoadoutText = "`r`n==Mech Bay==`r`n"
        $LoadoutText += "`r`n"+'##LoadoutQuirkText##'+"`r`n"
        $LoadoutText += "`r`n{| class=`"wikitable`"`r`n"
        $LoadoutText += "|-`r`n! Fixed Gear || Affinity`r`n"
        $LoadoutText += "##LoadoutAffinityText##"
        $LoadoutText += "|}`r`n"
        $LoadoutText += "`r`n{| class=`"wikitable`"`r`n"
        $LoadoutText += "|-`r`n! !! !! Left !! Center !! Right`r`n"
        $LoadoutAffinityText = ""
        $LoadoutQuirkText = ""
                
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
                        $MountCount = $($Mech.Hardpoint.$($HPLongSortHash.$TableLoc) | ? {$_ -eq $MountsLongHash.$Mount}).Count
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
                            if ([bool]($EquipAffinitiesIDNameHash.$($FixedItem.Name))) {
                                $FixedItemID = $FixedItem.Name
                                $LoadoutAffinityText += "|-`r`n| [[Gear/$ItemFriendlyName|$ItemFriendlyName]] || $($EquipAffinitiesIDNameHash.$FixedItemID) ($($EquipAffinitiesIDNumHash.$FixedItemID)): $($EquipAffinitiesIDDescHash.$FixedItemID)`r`n"
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
        #do ##LoadoutQuirkText## replacement
        $LoadoutText = $($LoadoutText -split ("##LoadoutQuirkText##")) -join $LoadoutQuirkText
        $LoadoutText = $($LoadoutText -split ("##LoadoutAffinityText##")) -join $LoadoutAffinityText

        #Setup Infobox
        $WikiMexTable += "{{Infobox MechPage`r`n"
        $WikiMexTable += "| name       = $($Mech.Name.MechUIName)`r`n"
        $WikiMexTable += "| icon       = $($Mech.Icon + '.png')`r`n"
        $WikiMexTable += "| signature  = $($Mech.Name.Variant)`r`n"
        $WikiMexTable += "| class      = $($Mech.Class)`r`n"
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
        #Mech Tags
        if ($Mech.Special.Count -gt 0) {
            $MechBlurb += "`r`n{| class=`"wikitable`"`r`n|-`r`n! [[Guides/Mech Bay|Special Tags]]`r`n|-`r`n|"
            $MechBlurbSpecialTags = ""
            foreach ($MechSpecial in $Mech.Special) {
                $MechBlurbSpecialTags += "$($($SpecialsObject | where -Property TagTitle -contains $MechSpecial).Friendly) - "
            }
            $MechBlurbSpecialTags = $MechBlurbSpecialTags.Trim(' - ')
            $MechBlurb += "`r`n" + $MechBlurbSpecialTags
            $MechBlurb += "`r`n|}"
        }
        $WikiMexTable += "`r`n==Description==`r`n`r`n"+$MechBlurb+"`r`n"
        $WikiMexTable += "`r`n"+$LoadoutText+"`r`n"
    } else {
        $WikiMexTable += "#REDIRECT [[Classified]]`r`n`r`n$($Mech.MechDefFile)`r`n"
    }
    $WikiMexTable +="{{-stop-}}`r`n"
    $ReturnText += $WikiMexTable
}

$ReturnText | Out-File "$OutputFile" -Encoding utf8 -Force