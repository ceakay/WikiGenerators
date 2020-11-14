###FUNCTIONS
#data chopper function
    #args: delimiter, position, input
function datachop {
    $array = @($args[2] -split "$($args[0])")    
    return $array[$args[1]]
}

###SETTINGS
#disable when testing!
$UploadToWiki = $false

###SET CONSTANTS
###
#RogueTech Dir (Where RTLauncher exists)
$RTroot = "D:\\RogueTech"
#Script Root
$RTScriptroot = "D:\\RogueTech\\WikiGenerators"
cd $RTScriptroot
#cache path
$CacheRoot = "$RTroot\\RtlCache\\RtCache"
#PWB
$PWBRoot = "D:\\PYWikiBot"

#other files
#inputs
$WeaponClassFile = $RTScriptroot+"\\Inputs\\WeaponClass.csv"
$WeaponsPageBlurbFile = $RTScriptroot+"\\Inputs\\Blurbs\\Weapons.txt"
$EquipmentPageBlurbFile = $RTScriptroot+"\\Inputs\\Blurbs\\Equipment.txt"

#outputs
$GearFile = $RTScriptroot+"\\Outputs\\GearTable.json"


#Init tables
$ComponentObjectList = Get-Content $GearFile -Raw | ConvertFrom-Json
$WeaponObjectList = $ComponentObjectList | where {$_.ComponentType -eq 'Weapon'}
$EquipmentObjectList = $ComponentObjectList | where {$_.ComponentType -ne 'Weapon'}
$WeaponClassHash = @{}
Import-Csv $WeaponClassFile | % { $WeaponClassHash[$_.Name] = $_.Friendly }

#Localization File
Write-Progress -Activity "Scanning Text Objects"
$TextFileName = "Localization.json"
$TextFileList = $(Get-ChildItem $CacheRoot -Recurse -Filter $TextFileName)
$TextObject = $null
foreach ($TextFile in $TextFileList) {
    $TextObject += $TextFile | Get-Content -raw | ConvertFrom-Json
}
#and convert to hash
Write-Progress -Activity "Hashing Text Objects"
$TextObjectHash = @{}
$TextObject | foreach { $TextObjectHash[$_.Name] = $_.Original }

#Wiki Titles
$WeaponsTitle = 'Weapons'
$EquipmentTitle = 'Equipment'

#WikiPages
$WeaponsPage = $RTScriptroot+"\\Outputs\\WeaponsPage.txt"
$WeaponsPageUTF8 = $RTScriptroot+"\\Outputs\\WeaponsPage.UTF8"
$WepxPage = $RTScriptroot+"\\Outputs\\WepxPage.txt"
$WepxPageUTF8 = $RTScriptroot+"\\Outputs\\WepxPage.UTF8"

$EquipmentPage = $RTScriptroot+"\\Outputs\\EquipmentPage.txt"
$EquipmentPageUTF8 = $RTScriptroot+"\\Outputs\\WeaponsPage.UTF8"

#Init Wiki Page Text
$WeaponsPageBlurb = Get-Content $WeaponsPageBlurbFile -raw
#$EquipmentPageBlurb = Get-Content $EquipmentPageBlurbFile
$RTVersion = $(Get-Content "$CacheRoot\\RogueTech Core\\mod.json" -raw | ConvertFrom-Json).Version

$WeaponsPageText = "{{-start-}}`r`n'''$WeaponsTitle'''`r`nLast Updated RT Version $RTVersion`r`n`r`n$WeaponsPageBlurb`r`n{{-stop-}}`r`n"
$EquipmentPageText = "{{-start-}}`r`n'''$EquipmentTitle'''`r`nLast Updated RT Version $RTVersion`r`n`r`n$EquipmentPageBlurb`r`n{{-stop-}}`r`n"

$WeaponTableHeader = @"
`r`n{| class="wikitable sortable"
!
!
! colspan="2" |Fitting
!
! colspan="3" |Damage
! colspan="4" | Per salvo
! colspan="5" |Modifiers
! colspan="5" |Range
|-
!<small>Name</small>
!<small>Ammo</small>
!<small>Tonnage</small>
!<small>Slots</small>
!<small>Value</small>
!<small>Norm</small>
!<small>Heat</small>
!<small>Stab</small>
!<small>Rounds</small>
!<small>Projectiles</small>
!<small>Heat</small>
!<small>Recoil</small>
!<small>Accuracy</small>
!<small>Evasion Ignored</small>
!<small>Crit Chance</small>
!<small>Falloff</small>
!<small>TAC</small>
!<small>Min</small>
!<small>Short</small>
!<small>Medium</small>
!<small>Long</small>
!<small>Max</small>`r`n
"@

$WepxModesTableHeader = @"
`r`n{| class="wikitable"
! colspan="3" |
! colspan="3" | Damage
! colspan="4" | Per salvo
! colspan="5" | Modifiers
! colspan="5" | Range
! colspan="15" | Chance to jam at gunnery skill level(%)
! rowspan="2" | Other effects
|-
!<small>Mode</small>
!<small>Default</small>
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
!<small>Crit Chance</small>
!<small>Falloff</small>
!<small>TAC</small>
!<small>Min</small>
!<small>Short</small>
!<small>Medium</small>
!<small>Long</small>
!<small>Max</small>`r`n
!<small>1</small>
!<small>2</small>
!<small>3</small>
!<small>4</small>
!<small>5</small>
!<small>6</small>
!<small>7</small>
!<small>8</small>
!<small>9</small>
!<small>10</small>
!<small>11</small>
!<small>12</small>
!<small>13</small>
!<small>14</small>
!<small>15</small>
"@

$WepxPageText = ""
#parse weapons
#Break into BEMS
$Weapons = [pscustomobject]@{}
$WeaponClassList = @($($WeaponObjectList | group -Property category).Name | where {$_})
$WeaponOtherList = $null
foreach ($WeaponClass in $WeaponClassList) {
    $Weapons | Add-Member -MemberType NoteProperty -Name $WeaponClass -Value ([pscustomobject]@{})
    $Weapons.$WeaponClass = $WeaponObjectList | where { $_.Category -eq $WeaponClass -and $_.Description.UIName -notlike "*Deprecated*" -and $_.ComponentTags.items -notlike "*BLACKLISTED*" -and $_.ComponentTags.items -notcontains "BLACKLISTED"}
    $WeaponOtherList += "|$WeaponClass"
}
$WeaponOtherList = $WeaponOtherList.Substring(1)
$WeaponsOther = $WeaponObjectList | where { $_.Category -notmatch $WeaponOtherList}
$WeaponClassList = @($($WeaponsOther | group -Property weaponCategoryID).Name | where {$_})
foreach ($WeaponClass in $WeaponClassList) {
    $Weapons | Add-Member -MemberType NoteProperty -Name $WeaponClass -Value ([pscustomobject]@{})
    $Weapons.$WeaponClass = $WeaponsOther | where { $_.weaponCategoryID -eq $WeaponClass -and $_.Description.UIName -notlike "*Deprecated*" -and $_.ComponentTags.items -notlike "*BLACKLISTED*" -and $_.ComponentTags.items -notcontains "BLACKLISTED"}
}

#sort
foreach ($WeaponClass in $Weapons.psobject.Properties.Name) {
    $Weapons.$WeaponClass = $Weapons.$WeaponClass | sort -Property Type, {$_.WeaponSubType -replace '\d+'}, {$_.WeaponSubType -replace '\D+' -as [int] }, {$_.Description.UIName}
}

#Create Tables
foreach ($WeaponClass in $Weapons.psobject.Properties.Name) {
    $WeaponClassList = $Weapons.$WeaponClass | group -Property Type
    $WeaponClassFriendly = $($WeaponClassHash.$WeaponClass)
    $WeaponsTableText = "{{-start-}}`r`n'''$WeaponsTitle/$WeaponClassFriendly'''`r`n"
    foreach ($WeaponType in $WeaponClassList.Name) {
        $WeaponTypeList = $($WeaponClassList | where {$_.Name -eq $WeaponType}).Group | group -Property WeaponSubType
        if (-not !$WeaponType) {
            $WeaponsTableText += "`r`n==$WeaponType==`r`n"
        } else {
            $WeaponsTableText += "`r`n==Other==`r`n"
        }
        foreach ($WeaponSubType in $WeaponTypeList.Name) {
            $WeaponSubTypeList = $($WeaponTypeList | where {$_.Name -eq $WeaponSubType}).Group
            if (-not !$WeaponSubType) {
                $WeaponsTableText += "`r`n===$WeaponSubType===`r`n"
            } else {
                $WeaponsTableText += "`r`n===Other===`r`n"
            }
            $WeaponsTableText += $WeaponTableHeader
            foreach ($Weapon in $WeaponSubTypeList) {
                #ammo overrides
                if ($Weapon.AmmoCategory -like "*Internal*") {
                    $WeaponAmmo = "Internal"
                } elseif ($Weapon.AmmoCategory -like "NotSet") {
                    $WeaponAmmo = $null
                } elseif (!$Weapon.AmmoCategory) {
                    $WeaponAmmo = $Weapon.ammoCategoryID
                } else {
                    $WeaponAmmo = $Weapon.AmmoCategory
                }
                #ConstructLink
                $LinkToWeapon = "$WeaponsTitle/$WeaponClassFriendly/$($Weapon.Description.UIName -replace "/" -replace " \+","+")"
                #WeaponRow Start
                $WeaponsTableText += @"
|-
| [[$LinkToWeapon|$($Weapon.Description.UIName -replace " \+","+")]]
"@
                if (!$WeaponAmmo) {
                    $WeaponsTableText += "`r`n|`r`n"
                } else {
                    $WeaponsTableText += "`r`n| [[$EquipmentTitle|$WeaponAmmo]]`r`n"
                }
                $WeaponsTableText += @"
| $($Weapon.Tonnage)
| $($Weapon.InventorySize)
| $([MATH]::Round($($Weapon.Description.Cost/1000+.499),0))K
| $($Weapon.Damage)
| $($Weapon.HeatDamage)
| $($Weapon.Instability)
| $($Weapon.ShotsWhenFired)
| $($Weapon.ProjectilesPerShot)
| $($Weapon.HeatGenerated)
| $($Weapon.AttackRecoil)
| $($Weapon.AccuracyModifier)
| $($Weapon.EvasivePipsIgnored)
| $($Weapon.CriticalChanceMultiplier)`r`n
"@
                if ($Weapon.isHeatVariation -or $Weapon.isStabilityVariation -or $Weapon.isDamageVariation) {
                    if ($Weapon.DistantVarianceReversed) {
                        $WeaponsTableText += "| +$($Weapon.DistantVariance)`r`n"
                    } else {
                        $WeaponsTableText += "| -$($Weapon.DistantVariance)`r`n"
                    }
                } else {
                    $WeaponsTableText += "| 0`r`n"
                }
                $WeaponsTableText += @"
| $($Weapon.APCriticalChanceMultiplier)
| $($Weapon.MinRange)
| $($Weapon.RangeSplit[0])
| $($Weapon.RangeSplit[1])
| $($Weapon.RangeSplit[2])
| $($Weapon.MaxRange)`r`n
"@
                #WeaponRow End
                #Create weapon page here guhhhhhhhhhh
                $WepxPageText += "{{-start-}}`r`n'''$LinkToWeapon'''`r`n"
                $WepxPageText += "`r`n==Description==`r`n"
                $BlurbCheck = $(datachop '__/' 1 $Weapon.Description.Details)
                if (-not !$BlurbCheck) {
                    $BlurbCheck = $(datachop '/__' 0 $BlurbCheck)
                    $MiniHash = $($TextObject | where -Property "Name" -Like $BlurbCheck)
                    if ($MiniHash.Count -eq 1) {
                        $WeaponDesc = $MiniHash.Original
                    } elseif ($MiniHash.Count -gt 1) {
                        $WeaponDesc = $MiniHash[0].Original
                    }
                } else {
                    $WeaponDesc = $Weapon.Description.Details
                }
                $WepxPageText += "`r`n$WeaponDesc`r`n"
                $WepxPageText += "`r`n==Bonuses and Attributes==`r`n"
                $WepxPageText += "`r`n<ul style='color: #ff8000;'>`r`n"
                foreach ($WepBonus in $Weapon.Custom.BonusDescriptions.Bonuses) {
                    $BonusSplit = $WepBonus -split ": "
                    $BonusKey = $BonusSplit[0]
                    $BonusValue = $BonusSplit[1]
                    $MiniHash = $($TextObjectHash.GetEnumerator() | where {$_.Key -like "*$($BonusKey).Full*"})
                    if ($MiniHash.Count -eq 1) {
                        $BonusDesc = $MiniHash.Value
                    } elseif ($MiniHash.Count -gt 1) {
                        $BonusDesc = $MiniHash[0].Value
                    }
                    if (-not !$BonusValue) {
                        $BonusDesc = $BonusDesc.Replace("{0}",$BonusValue)
                    }
                    $WepxPageText += "<li>$BonusDesc</li>`r`n"
                }
                $WepxPageText += "</ul>`r`n"
                $WepxPageText += "`r`n==Firing Modes==`r`n"
                $WepxPageText += "`r`n$WepxModesTableHeader"
                foreach ($Mode in $Weapon.Modes) {
                    #IsDefault
                    if ($Mode.isBaseMode) {
                        $WepxIsDefault = "&#10004;"
                    } else {
                        $WepxIsDefault = $null
                    }
                    #ModeMulitpliers
                    $ModeMultipliers = @('Damage','Heat','Instability','CriticalChance')
                    foreach ($ModeMultiplier in $ModeMultipliers) {
                        $ModeHolder = $(Get-Variable $("Mode."+$ModeMultiplier+"Multiplier")).Value
                        if (!$ModeHolder) {
                            $ModeHolder = 1
                        }
                        Set-Variable $("Mode"+$ModeMultiplier+"Multiplier") $ModeHolder
                    }
                    #MATHS                    
                    $DamagePershot = ($Weapon.Damage + $Mode.DamagePerShot) * $ModeDamageMultiplier
                    $HeatPerShot = ($Weapon.HeatDamage + $Mode.HeatDamagePerShot) * $ModeHeatMultiplier
                    $StabPerShot = ($Weapon.Instability + $Mode.Instability) * $ModeInstabilityMultiplier
                    $Shots = $Weapon.ShotsWhenFired + $Mode.ShotsWhenFired
                    $Proj = $Weapon.ProjectilesPerShot + $Mode.ProjectilesPerShot
                    $HeatGen = ($Weapon.HeatGenerated + $Mode.HeatGenerated)
                    $Recoil = $Weapon.AttackRecoil + $Mode.AttackRecoil
                    $Accur = $Weapon.AccuracyModifier + $Mode.AccuracyModifier
                    $Evasive = $Weapon.EvasivePipsIgnored + $Mode.EvasivePipsIgnored
                    $Crit = ($Weapon.CriticalChanceMultiplier + $Mode.CriticalChanceMultiplier) * 100
                    $Falloff = $Mode.DistantVariance
                    if ((!$Falloff) -or ($Falloff -eq 0)) {
                        $Falloff = $Weapon.DistantVariance
                    }
                    $Falloff = $Falloff * 100
                    $WepxPageText += @"
|-
| $($Weapon.Modes.UIName)
| $WepxIsDefault
| $($Weapon.Modes.AmmoCategory)
| $DamagePerShot
| $HeatPerShot
| $StabPerShot
| $Shots
| $Proj
| $HeatGen
| $Recoil
| $Accur
| $Evasive
| +$($Crit)%
| $($Falloff)%
!<small>TAC</small>
!<small>Min</small>
!<small>Short</small>
!<small>Medium</small>
!<small>Long</small>
!<small>Max</small>`r`n
!<small>1</small>
!<small>2</small>
!<small>3</small>
!<small>4</small>
!<small>5</small>
!<small>6</small>
!<small>7</small>
!<small>8</small>
!<small>9</small>
!<small>10</small>
!<small>11</small>
!<small>12</small>
!<small>13</small>
!<small>14</small>
!<small>15</small>
|
"@
#####KEEP ADDDING SHIT HERE!
            }
            $WeaponsTableText += "|}`r`n"
        }
    }
    $WeaponsTableText += "{{-stop-}}`r`n"
    $WeaponsPageText += $WeaponsTableText
}
#Mash text and do file things
$WeaponsPageText > $WeaponsPage
Get-Content $WeaponsPage | Set-Content -Encoding UTF8 $WeaponsPageUTF8
$WepxPageText > $WepxPage
Get-Content $WepxPage | Set-Content -Encoding UTF8 $WepxPageUTF8

#Do Ammo only here. 

#Upload to wiki
if ($UploadToWiki) {
    py $PWBRoot\\pwb.py login
    cls
    py $PWBRoot\\pwb.py pagefromfile -file:$WeaponsPageUTF8 -notitle -force -pt:0
    cls
}