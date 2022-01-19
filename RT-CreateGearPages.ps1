Param(
    [Parameter(Mandatory = $True)]
    $InputObject,
        
    [Parameter(Mandatory = $True)]
    $BonusDescriptionHash,

    [Parameter(Mandatory = $True)]
    $MechUsedByListObject,

    [Parameter(Mandatory = $True)]
    $FixedAffinityObject,

    [Parameter(Mandatory = $True)]
    $EquipAffinitiesRef,

    [Parameter(Mandatory = $True)]
    $IDUINameHash,

    [Parameter(Mandatory = $True)]
    $OutputFile

)

function Sort-STNumerical {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $True,
            ValueFromPipeline = $True,
            ValueFromPipelineByPropertyName = $True)]
        [System.Object[]]
        $InputObject,
        
        [ValidateRange(2, 100)]
        [Byte]
        $MaximumDigitCount = 100,

        [Switch]$Descending
    )
    
    Begin {
        [System.Object[]] $InnerInputObject = @()
        
        [Bool] $SortDescending = $False
        if ($Descending) {
            $SortDescending = $True
        }
    }
    
    Process {
        $InnerInputObject += $InputObject
    }

    End {
        $InnerInputObject |
            Sort-Object -Property `
                @{ Expression = {
                    [Regex]::Replace($_, '(\d+)', {
                        "{0:D$MaximumDigitCount}" -f [Int64] $Args[0].Value })
                    }
                },
                @{ Expression = { $_ } } -Descending:$SortDescending
    }
}
#RTVersion
$RTVersion = $(Get-Content "D:\\RogueTech\\RtlCache\\RtCache\\RogueTech Core\\mod.json" -raw | ConvertFrom-Json).Version

$ReturnText = $null
foreach ($Item in $InputObject) {
    #Build gear page
    $ItemText = "{{-start-}}`r`n@@@Gear/$($Item.Description.UIName)@@@`r`n"
    $ItemText += "{{tocright}}`r`n"
    $ItemText += "[https://discord.gg/roguetech BOT PAGE] || RTVer: $RTVersion"
    $ItemText += "=Description=`r`n`r`nID: $($Item.Description.ID)`r`n`r`nManufacturer: $($Item.Description.Manufacturer)`r`n`r`n$($($($Item.Description.Details -split ("`n")) | % {$_.Trim()}) -join ("`r`n"))`r`n"
    $ItemText += "=Attributes=`r`n`r`n"
    $ItemText += @"
{|class="wikitable"
! Tonnage
! Slots
! Value
! Allowed Locations
! Disallowed Locations
|-
| $($Item.Tonnage)
| $($Item.InventorySize)
| $($Item.Description.Cost)
| $($Item.AllowedLocations)
| $($Item.DisallowedLocations)
|}


"@
    $ItemText += "<ul style=`"color: #ff8000;`">`r`n"
    foreach ($Bonus in $Item.Custom.BonusDescriptions.Bonuses) {
        $Bonus = @($Bonus -split (":"))
        $BonusName = $Bonus[0].Trim()
        $BonusText = $($BonusDescriptionHash.$BonusName)
        if ($Bonus.Count -gt 1) {
            $BonusSubstitute = @($Bonus[1] -split (','))
            for ($i=0;$i -lt $BonusSubstitute.Count; $i++) {
                $BonusText = Invoke-Expression $('$BonusText -Replace ("\{'+$i+'\}","'+$($BonusSubstitute[$i]).Trim()+'")')
            }
        }
        $ItemText += "* $BonusText`r`n"
    }
    $ItemText += "</ul>`r`n`r`n"
    if ($Item.ComponentType -match 'AmmunitionBox') {
        $ItemText += "=Ammo Stats=`r`n"
        $ItemText += @"
{| class="wikitable"
! colspan="2" | Ammo
! colspan="3" | <small>Component Explosion<br>Self Damage Per Round</small>
|-
!<small>Capacity</small>
!<small>Cost Per Round</small>
!<small>Norm</small>
!<small>Heat</small>
!<small>Stab</small>
|-
| $($Item.Capacity)
| $($Item.Custom.AmmoCost.PerUnitCost)
| $($Item.Custom.ComponentExplosion.ExplosionDamagePerAmmo)
| $($Item.Custom.ComponentExplosion.HeatDamagePerAmmo)
| $($Item.Custom.ComponentExplosion.StabilityDamagePerAmmo)
|}

"@
    }
    if ($Item.ComponentType -match 'weapon') {
        if ($Item.Category) {
            $ItemCategory = $Item.Category
        } else {
            $ItemCategory = $Item.weaponCategoryID
        }
        $ItemText += "=Weapon Stats=`r`n`r`nCategory: $($ItemCategory)`r`n`r`nType: $($Item.Type)`r`n`r`nSubType: $($Item.WeaponSubType)`r`n"  
        $ItemText += @"
{| class="wikitable"
! colspan="3" |
! colspan="3" | Damage
! colspan="4" | Per salvo
! colspan="2" | Modifiers
! colspan="3" | [[TAC]]
! colspan="5" | Range
! colspan="1" | Other
|-
!<small>Default</small>
!<small>Mode</small>
!<small>Ammo</small>
!<small>Norm</small>
!<small>Heat</small>
!<small>Stab</small>
!<small>Rounds</small>
!<small>Projectiles</small>
!<small>Heat</small>
!<small>Recoil</small>
!<small>Accuracy</small>
!<small>Evasion ignored</small>
!<small>Chance</small>
!<small>Shards</small>
!<small>Armor</small>
!<small>Min</small>
!<small>Short</small>
!<small>Medium</small>
!<small>Long</small>
!<small>Max</small>
!<small>Indirect</small>

"@
        $BaseArrayZero = @('Damage','HeatDamage','Instability','HeatGenerated','AccuracyModifier','EvasivePipsIgnored','RefireModifier','APCriticalChanceMultiplier','APArmorShardsMod','APMaxArmorThickness')
        $BaseArrayOne = @('ShotsWhenFired','ProjectilesPerShot')
        $ItemBaseDefault = ""
        $ItemBaseMode = ""
        $ItemBaseAmmoCategory = $($Item.AmmoCategory)
        $ItemBaseMinRange = $($Item.MinRange)
        $ItemBaseShortRange = $($Item.RangeSplit[0])
        $ItemBaseMiddleRange = $($Item.RangeSplit[1])
        $ItemBaseLongRange = $($Item.RangeSplit[2])
        $ItemBaseMaxRange = $($Item.MaxRange)
        if ($Item.IndirectFireCapable) {
            $ItemBaseIndirectFireCapable = "&#10004;"
        } else {
            $ItemBaseIndirectFireCapable = ""
        }
        foreach ($Stat in $BaseArrayZero) {
            iex $('$ItemBase'+$Stat+' = $($Item.'+$Stat+'); if ($ItemBase'+$Stat+' -eq $null) {$ItemBase'+$Stat+' = 0}')
        }
        foreach ($Stat in $BaseArrayOne) {
            iex $('$ItemBase'+$Stat+' = $($Item.'+$Stat+'); if ($ItemBase'+$Stat+' -eq $null) {$ItemBase'+$Stat+' = 1}')
        }

        if (!$Item.Modes) {
            $ItemBaseDefault = "&#10004;"
            $ItemText += @"
|-
| $ItemBaseDefault
| $ItemBaseMode
| $ItemBaseAmmoCategory
| $ItemBaseDamage
| $ItemBaseHeatDamage
| $ItemBaseInstability
| $ItemBaseShotsWhenFired
| $ItemBaseProjectilesPerShot
| $ItemBaseHeatGenerated
| $ItemBaseRefireModifier
| $ItemBaseAccuracyModifier
| $ItemBaseEvasivePipsIgnored
| $ItemBaseAPCriticalChanceMultiplier
| $ItemBaseAPArmorShardsMod
| $ItemBaseAPMaxArmorThickness
| $ItemBaseMinRange
| $ItemBaseShortRange
| $ItemBaseMiddleRange
| $ItemBaseLongRange
| $ItemBaseMaxRange
| $ItemBaseIndirectFireCapable

"@
        } else {
            foreach ($Mode in $($Item.Modes)) {
                #Modedefault
                if ($Mode.isBaseMode) {
                    $ModeDefault = "&#10004;"
                } else {
                    $ModeDefault = $ItemBaseDefault
                }
                #modeuiname
                if ($Mode.UIName) {
                    $ModeMode = $Mode.UIName
                } else {
                    $ModeMode = $ItemBaseMode
                }
                #modeAmmo
                if ($Mode.AmmoCategory) {
                    $ModeAmmoCategory = $Mode.AmmoCategory
                } else {
                    $ModeAmmoCategory = $ItemBaseAmmoCategory
                }
                #modeindirect
                if ($Mode.IndirectFireCapable) {
                    $ModeIndirectFireCapable = "&#10004;"
                } elseif (-not $Mode.IndirectFireCapable) {
                    $ModeIndirectFireCapable = ""
                } else {
                    $ModeIndirectFireCapable = $ItemBaseIndirectFireCapable
                }
                #modeDamageMultiplier - set default to 1
                if (!$Mode.DamageMultiplier) {
                    $Mode | Add-Member -NotePropertyName 'DamageMultiplier' -NotePropertyValue 1
                }

                $ItemText += @"
|-
| $ModeDefault
| $ModeMode
| $ModeAmmoCategory
| $($($ItemBaseDamage + $Mode.Damage + $Mode.DamagePerShot) * $Mode.DamageMultiplier)
| $($ItemBaseHeatDamage + $Mode.HeatDamage + $Mode.HeatDamagePerShot)
| $($ItemBaseInstability + $Mode.Instability)
| $($ItemBaseShotsWhenFired + $Mode.ShotsWhenFired)
| $($ItemBaseProjectilesPerShot + $Mode.ProjectilesPerShot)
| $($ItemBaseHeatGenerated + $Mode.HeatGenerated)
| $($ItemBaseRefireModifier + $Mode.RefireModifier)
| $($ItemBaseAccuracyModifier + $Mode.AccuracyModifier)
| $($ItemBaseEvasivePipsIgnored + $Mode.EvasivePipsIgnored)
| $($ItemBaseAPCriticalChanceMultiplier + $Mode.APCriticalChanceMultiplier)
| $($ItemBaseAPArmorShardsMod + $Mode.APArmorShardsMod)
| $($ItemBaseAPMaxArmorThickness + $Mode.APMaxArmorThickness)
| $([int]$($ItemBaseMinRange + $Mode.MinRange))
| $([int]$($ItemBaseShortRange + $Mode.ShortRange))
| $([int]$($ItemBaseMiddleRange + $Mode.MediumRange))
| $([int]$($ItemBaseLongRange + $Mode.LongRange))
| $([int]$($ItemBaseMaxRange + $Mode.MaxRange))
| $ModeIndirectFireCapable

"@
            }
        }
        $ItemText += "|}`r`n"
    }

    #List Mechs Used By
    $ItemMechListColToggleMax = 3
    $ItemMechListColToggle = $ItemMechListColToggleMax - 1
    $ItemText += "`r`n=Used By Mechs=`r`n<small>`r`n{| class=`"wikitable mw-collapsible mw-collapsed`"`r`n|-`r`n! colspan=`"$ItemMechListColToggleMax`"|<big>Mechs</big>`r`n"
    if (-not !$($MechUsedByListObject.$($Item.Description.ID))) {
        try {
            $MechUsedByList = $($MechUsedByListObject.$($Item.Description.ID)) | Sort-STNumerical
        } catch {
            $MechUsedByList = $($MechUsedByListObject.$($Item.Description.ID))
        }
        foreach ($MechUsedBy in $MechUsedByList) {
            $ItemMechListColToggle += 1
            if ($ItemMechListColToggle -eq $ItemMechListColToggleMax) {
                $ItemMechListColToggle = 0
                $ItemText += "|-`r`n"
            }
            $ItemText += "| [[Mechs/"+$MechUsedBy+"|"+$MechUsedBy+"]]`r`n"
        }
    }
    $ItemText += "|}`r`n</small>`r`n"

    #List Affinity used by.
    $ItemID = $Item.Description.ID
    $ItemAff = $($EquipAffinitiesRef | ? {$_.ID -eq $ItemID})
    if (-not !$ItemAff) {
        $ItemText += "=Affinity Provided=`r`nAffinity is only provided when this gear is Fixed (that is cannot be removed) to a unit.`r`n{| class=`"wikitable`"`r`n|-`r`n! [[Unit Affinities|Gear Affinity]]`r`n|-`r`n|"
        $ItemText += "`r`n* $($ItemAff.Name) ($($ItemAff.Num)): $($ItemAff.Description)"
        $ItemText += "`r`n|}`r`n`r`n<small>`r`n{| class=`"wikitable mw-collapsible mw-collapsed`"`r`n|-`r`n! colspan=`"$ItemMechListColToggleMax`"|<big>Affinity To Mechs</big>`r`n"
        $ItemMechListColToggleMax = 3
        $ItemMechListColToggle = $ItemMechListColToggleMax - 1
        $GearAffinityMechList = $($FixedAffinityObject.$($ItemID)) | Sort-STNumerical
        foreach ($GearAffinityMech in $GearAffinityMechList) {
            $ItemMechListColToggle += 1
            if ($ItemMechListColToggle -eq $ItemMechListColToggleMax) {
                $ItemMechListColToggle = 0
                $ItemText += "|-`r`n"
            }
            $ItemText += "| [[Mechs/"+$GearAffinityMech+"|"+$GearAffinityMech+"]]`r`n"
        }
        $ItemText += "|}`r`n</small>`r`n`r`n"
    }

    #Regex cleanup
    $ItemText = $ItemText -Replace ('<color=(.*?)>(.*?)<\/color>','<span style="color:$1;">$2</span>') #replace color tag
    $ItemText = $ItemText -Replace ('<b>(.*?)<\/b>','$1') #remove bold

    #Lazy Blacklisted 
    if (($Item.ComponentTags.items -contains "blacklisted") -and ($Item.ComponentTags.items -notcontains "WikiWL")) {
        $ItemText = "{{-start-}}`r`n@@@Gear/$($Item.Description.UIName)@@@`r`n$($Item.Description.ID)`r`n`r`n"
        $ItemText += @"
= WARNING =
YOU ARE ATTEMPTING TO ACCESS CLASSIFIED INFORMATION.

[[File:BLACKLIST.png|300px|frameless|left]]

 This item or unit has been marked as restricted (not directly for player use) or spoiler by the Developers. 
 
 If you feel this was done in error, open a ticket on [https://discord.gg/roguetech Discord].

"@
    }

    #Lootable
    $ItemText += "`r`n= Item Salvage Rules ="
    $ItemText += "`r`nItem can be salvaged by player: "
    if ($Item.Custom.Flags.flags -contains 'no_salvage') {
        $ItemText += "No"
    } else {
        $ItemText += "Yes"
    }
    if ($Item.Custom.Lootable.ItemID) {
        $ItemText += "`r`nItem salvages into: [[Gear/$($IDUINameHash.$($Item.Custom.Lootable.ItemID))]]"
    }
    $ItemText += "`r`n"

    #Close
    $ItemText += "{{-stop-}}`r`n"
    $ReturnText += $ItemText
}

$ReturnText | Out-File "$OutputFile" -Encoding utf8 -Force