Write-Host @"





































"@

###FUNCTIONS
#data chopper function
    #args: delimiter, position, input
function datachop {
    $array = @($args[2] -split "$($args[0])")    
    return $array[$args[1]]
}

#@($GroupedList.'a/a/a/ac' | select {$_.description.uiname}).'$_.description.uiname' | Sort-STNumerical
function Sort-STNumerical {
    <#
        .SYNOPSIS
            Sort a collection of strings containing numbers, or a mix of this and 
            numerical data types - in a human-friendly way.
            This will sort "anything" you throw at it correctly.
            Author: Joakim Borger Svendsen, Copyright 2019-present, Svendsen Tech.
            MIT License
        .PARAMETER InputObject
            Collection to sort.
        
        .PARAMETER MaximumDigitCount
            Maximum numbers of digits to account for in a row, in order for them to be sorted
            correctly. Default: 100. This is the .NET framework maximum as of 2019-05-09.
            For IPv4 addresses "3" is sufficient, but "overdoing" does no or little harm. It might
            eat some more resources, which can matter on really huge files/data sets.
        .PARAMETER Descending
            Optional switch to sort in descending order rather than the default ascending order.
        .EXAMPLE
            $Strings | Sort-STNumerical
            Sort strings containing numbers in a way that magically makes them sorted human-friendly
            
        .EXAMPLE
            $Result = Sort-STNumerical -InputObject $Numbers
            $Result
            Sort numbers in a human-friendly way.
        .EXAMPLE
            @("1.1.0", "1.1.11", "1.1.2") | Sort-STNumerical -Descending
            1.1.11
            1.1.2
            1.1.0
    #>
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

function RT-DynamicFiter {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $True)]
        $InputObject,
        
        [Array]$ComponentTypes,

        [Array]$Categories,

        [Array]$NotCategories
    )

    $ComponentTypesFilter = $null
    $CategoriesFilter = $null
    $NotCategoriesFilter = $null
    $FilterArray = @()
    $JoinedFilter = $Null

    if (-not !$ComponentTypes) {
        foreach ($ComponentType in $ComponentTypes) {
            $ComponentTypesFilter += ' -or ($_.ComponentType -like '+"'$ComponentType'"+')'
        }
        $ComponentTypesFilter = '('+$ComponentTypesFilter.Trim(" -or ")+')'
        $FilterArray += $ComponentTypesFilter
    }

    if (-not !$Categories) {
        foreach ($Category in $Categories) {
            $CategoriesFilter += ' -or ($_.Custom.Category.CategoryID -like '+"'$Category'"+')'
        }
        $CategoriesFilter = '('+$CategoriesFilter.Trim(" -or ")+')'
        $FilterArray += $CategoriesFilter
    }

    if (-not !$NotCategories) {
        foreach ($NotCategory in $NotCategories) {
            $NotCategoriesFilter += ' -and ($_.Custom.Category.CategoryID -notlike '+"'$NotCategory'"+')'
        }
        $NotCategoriesFilter = '('+$NotCategoriesFilter.Trim(" -and ")+')'
        $FilterArray += $NotCategoriesFilter
    }

    if (!$FilterArray) {
        $InputObject
    } else {
        $JoinedFilter = '$InputObject | ? {('+$($FilterArray -join (' -and '))+')}'
        Invoke-Expression $JoinedFilter
    }
}

$JobFunctions = {
    function RT-CreateGearPages {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory = $True)]
            $InputObject,
        
            [Parameter(Mandatory = $True)]
            $BonusDescriptionHash,

            [Parameter(Mandatory = $True)]
            $MechUsedByListObject,

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

        $ReturnText = $null
        foreach ($Item in $InputObject) {
            #Build gear page
            $ItemText = "{{-start-}}`r`n'''Gear/$($Item.Description.UIName)'''`r`n"
            $ItemText += "{{tocright}}`r`n"
            $ItemText += "=Description=`r`n`r`nID: $($Item.Description.ID)`r`n`r`n$($($($Item.Description.Details -split ("`n")) | % {$_.Trim()}) -join ("`r`n"))`r`n"
            $ItemText += "=Attributes=`r`n`r`n"
            $ItemText += @"
{|class="wikitable"
!Tonnage
!Slots
!Value
|-
|$($Item.Tonnage)
|$($Item.InventorySize)
|$($Item.Description.Cost)
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
                $ItemText += "=Weapon Stats=`r`n`r`nCategory: $($Item.Category)`r`n`r`nType: $($Item.Type)`r`n`r`nSubType: $($Item.WeaponSubType)`r`n"  
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

                        $ItemText += @"
|-
| $ModeDefault
| $ModeMode
| $ModeAmmoCategory
| $($ItemBaseDamage + $Mode.Damage + $Mode.DamagePerShot)
| $($ItemBaseHeatDamage + $Mode.HeatDamage)
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
| $([int]$($ItemBaseMiddleRange + $Mode.MiddleRange))
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
            $MechUsedByList = $($MechUsedByListObject.$($Item.Description.ID)) | Sort-STNumerical
            foreach ($MechUsedBy in $MechUsedByList) {
                $ItemMechListColToggle += 1
                if ($ItemMechListColToggle -eq $ItemMechListColToggleMax) {
                    $ItemMechListColToggle = 0
                    $ItemText += "|-`r`n"
                }
                $ItemText += "| [[Mechs/"+$MechUsedBy+"|"+$MechUsedBy+"]]`r`n"
            }
            $ItemText += "|}`r`n</small>`r`n"


            #Regex cleanup
            $ItemText = $ItemText -Replace ('<color=(.*?)>(.*?)<\/color>','<span style="color:$1;">$2</span>') #replace color tag
            $ItemText = $ItemText -Replace ('<b>(.*?)<\/b>','$1') #remove bold

            #Lazy Blacklisted
            if ($Item.ComponentTags.items -contains "blacklisted") {
                $ItemText = "{{-start-}}`r`n'''Gear/$($Item.Description.UIName)'''`r`n#REDIRECT [[Classified]]`r`n"
            }

            #Close
            $ItemText += "{{-stop-}}`r`n"
            $ReturnText += $ItemText
        }

        $ReturnText | Out-File "$OutputFile" -Encoding utf8 -Force

    }
}

###SETTINGS

###SET CONSTANTS
###
#RogueTech Dir (Where RTLauncher exists)
$RTroot = "D:\\RogueTech"
#Script Root
$RTScriptroot = "D:\\RogueTech\\WikiGenerators"
cd $RTScriptroot
#cache path
$CacheRoot = "$RTroot\\RtlCache\\RtCache"
$MinorCatPath = $CacheRoot+"\\RogueTech Core\\categories"
$BonusDescPath = $CacheRoot+"\\RogueTech Core\\bonusDescriptions"

#masterfile
$EquipFile = $RTScriptroot+"\\Outputs\\GearTable.json"

#FiltersFile
$FiltersFile = $CacheRoot+"\\CustomFilters\\mod.json"

#other files
#blurbfiles
$GearPageBlurbFile = $RTScriptroot+"\\Inputs\\Blurbs\\Gear.txt"
$EquipmentPageBlurbFile = $RTScriptroot+"\\Inputs\\Blurbs\\Equipment.txt"
$WeaponsPageBlurbFile = $RTScriptroot+"\\Inputs\\Blurbs\\Weapons.txt"
$AmmunitionPageBlurbFile = $RTScriptroot+"\\Inputs\\Blurbs\\Ammunition.txt"
$InternalsPageBlurbFile = $RTScriptroot+"\\Inputs\\Blurbs\\Internals.txt"

#static hashes
$MajorCatsHash = @{
    WEAPON = "Weapons"
    AMMO = "Ammunition"
    Internals = "Internals"
    EQUIP = "Equipment"
}

#Load Master List, remove blacklisted
Write-Progress -Id 0 -Activity "Loading Master Object"
$MasterList = [System.Collections.ArrayList]@($(Get-Content $EquipFile -Raw | ConvertFrom-Json) | ? {$_.Description.ID -notmatch 'emod_engineslots_size'}  | ? {$_.Description.ID -notmatch 'Gear_LegJet_Assault_Lower'}) #| ? {$_.ComponentTags.items -notcontains "blacklisted"})

#Load Filters List
Write-Progress -Id 0 -Activity "Loading Custom Filters"
$FiltersList = $(Get-Content $FiltersFile -Raw | ConvertFrom-Json).Settings.Tabs
#Remove 'Show'
$FiltersList.Buttons | ? {$_.Tooltip} | % { if ($_.Tooltip -match 'Show ') {$_.Tooltip = datachop 'Show ' 1 $_.Tooltip}}

#Load GearUsedBy
$GearUsedByFile = "$RTScriptroot\\Outputs\\GearUsedBy.json"
$GearUsedBy = Get-Content $GearUsedByFile -Raw | ConvertFrom-Json

#Build minor cat hash
Write-Progress -Id 0 -Activity "Building Hashes"
$MinorCatFiles = Get-ChildItem $MinorCatPath -Filter "Categories*.json"
$MinorCatHash = @{}
foreach ($MinorCatFile in $MinorCatFiles) {
    $MinorCatObject = $(Get-Content $MinorCatFile.FullName -Raw | ConvertFrom-Json).Settings
    foreach ($MinorCatItem in $MinorCatObject) {
        #overrides!
        if ($MinorCatItem.Name -eq 'a/s/m/melee') {$MinorCatItem.DisplayName = 'Melee Ammo'}
        if ($MinorCatItem.Name -eq 'LifeSupportA') {$MinorCatItem.DisplayName = 'Life Support A'}
        if ($MinorCatItem.Name -eq 'LifeSupportB') {$MinorCatItem.DisplayName = 'Life Support B'}
        if ($MinorCatItem.Name -eq 'w/s/h/HandHeld') {$MinorCatItem.DisplayName = 'Hand Held Weapon (Support)'}
        if ($MinorCatItem.Name -eq 'EndoTSM') {$MinorCatItem.DisplayName = 'Triple Strength Myomer Endo'}
        if ($MinorCatItem.Name -eq 'BAECM') {$MinorCatItem.DisplayName = 'BA Electronic Countermeasure Suite'}
        $MinorCatHash.Add($($MinorCatItem.Name), $($MinorCatItem.DisplayName))
    }
}
$MinorCatHashReverse = @{}
foreach ($HashItem in $MinorCatHash.GetEnumerator()) {
    try {$MinorCatHashReverse.Add($HashItem.Value,$HashItem.Key)}
    catch {"GearWiki|Cannot create CatHash: " + $HashItem | Out-File $RTScriptroot\ErrorLog.txt -Append -Encoding utf8}
}

#Build Minor Cat Groups
Write-Progress -Id 0 -Activity "Building Groups"
$GroupedList = [pscustomobject]@{}
foreach ($MasterObject in $MasterList) {
    foreach ($CatID in $($MasterObject.Custom.Category.CategoryID)) {
        if ($MinorCatHash.$CatID) {
            if (!$GroupedList.$($MinorCatHash.$CatID)) {
                $GroupedList | Add-Member -NotePropertyName $($MinorCatHash.$CatID) -NotePropertyValue @()
            }
            $GroupedList.$($MinorCatHash.$CatID) += $MasterObject
        }
    }
}

#Build BonusDescriptions
$BonusDescFiles = Get-ChildItem $BonusDescPath -Filter "BonusDescriptions*.json"
$BonusDescHash = @{}
foreach ($BonusDescFile in $BonusDescFiles) {
    $BonusDescObject = $(Get-Content $BonusDescFile.FullName -Raw | ConvertFrom-Json).Settings
    foreach ($BonusDescItem in $BonusDescObject) {
        $BonusDescHash.Add($($BonusDescItem.Bonus), $($BonusDescItem.Full))
    }
}

#Init Pages Text from blurbfiles
$RTVersion = $(Get-Content "$CacheRoot\\RogueTech Core\\mod.json" -Raw | ConvertFrom-Json).Version
$GearPage = "Last Updated RT Version $RTVersion`r`n`r`n" + $(Get-Content $GearPageBlurbFile -Raw)+"`r`n`r`n"

###BUILD PAGES
#Inits
$i = $j = $k = $l = 0
$PageList = @('Equipment')
$GearOutFolder = $RTScriptroot+"\\Outputs\\Gear"
$ItemOutFolder = $GearOutFolder+"\\Items"
$Navbox = @"
{{Navbox
| name       = NavboxEquipment
| title      = [[Gear]]
| listclass  = hlist

"@
#Purge Folder
Remove-Item "$GearOutFolder\\*" -Recurse -Force
$null = New-Item -ItemType Directory $ItemOutFolder


#Build Item Pages via jobs
Get-Job | Remove-Job -Force #Cleanup Leftover Jobs
$Divisor = 100 #Even numbers only
$Rounder = ($Divisor / 2) - 1
$Counter = [int]$(($MasterList.Count + $Rounder) / $Divisor)
for ($JobCount=0;$JobCount -lt $Counter; $JobCount++) {
    #start job to build item page from $masterlist
    if ($JobCount -eq $Counter - 1) {
        $JobInputObject = $MasterList[$(0+($JobCount*$Divisor))..$($($MasterList.Count)-1)]
    } else {
        $JobInputObject = $MasterList[$(0+($JobCount*$Divisor))..$(($Divisor*(1+$JobCount))-1)]
    }
    $JobOutputFile = $ItemOutFolder+"\\Chunk$JobCount.txt"
    Start-Job -Name $("ItemJob"+$JobCount) -InitializationScript $JobFunctions -ScriptBlock {RT-CreateGearPages -InputObject $using:JobInputObject -BonusDescriptionHash $using:BonusDescHash -MechUsedByListObject $using:GearUsedBy -OutputFile $using:JobOutputFile} | Out-Null
}

#Build TOC pages
foreach ($MajorKey in $FiltersList.Caption) {
    $i++
    Write-Progress -Id 0 -Activity "Building Major Groups" -Status "$i of $($MajorCatsHash.Count)"
    $MajorName = $($MajorCatsHash.$MajorKey)
    $MajorLink = "Gear/$MajorName"
    $PageList += $MajorLink
    $Navbox += "| group$i     = [[$MajorLink|$MajorName]]`r`n| list$i      = "
    $GearPage += "[[$MajorLink]]`r`n`r`n"
    $MajorPageFile = "Gear-$MajorName.txt"
    $MajorPage = $(iex $("Get-Content $"+$MajorName+"PageBlurbFile -Raw"))+"`r`n`r`n"
    $AllMajorEquipFilter = $($FiltersList | ? {$_.Caption -eq $MajorKey}).Filter
    #Override to include subfilter cause i'm lazy as shit to clean up the redundant fiter in weapons
    if ($MajorKey -notmatch 'Weapon') {
        $LowerFilters = $($($FiltersList | ? {$_.Caption -eq $MajorKey}).Buttons | ? {($_.Tooltip -match 'all') -and $_.Tooltip}).Filter
        foreach ($LowerFilter in $LowerFilters) {
            try {$AllMajorEquipFilter | Add-Member -NotePropertyName $LowerFilter.psobject.Properties.Name -NotePropertyValue $LowerFilter.psobject.Properties.Value}
            catch {$AllMajorEquipFilter.$($LowerFilter.psobject.Properties.Name) += $LowerFilter.psobject.Properties.Value}
        }
    }
    if (!$AllMajorEquipFilter.ComponentTypes -and !$AllMajorEquipFilter.Categories -and !$AllMajorEquipFilter.NotCategories) {
        $AllMajorEquip = $MasterList
    } else {
        $AllMajorEquip = RT-DynamicFiter -InputObject $MasterList -ComponentTypes $AllMajorEquipFilter.ComponentTypes -Categories $AllMajorEquipFilter.Categories -NotCategories $AllMajorEquipFilter.NotCategories
    }
    $MajorList = $($FiltersList | ? {$_.Caption -eq $MajorKey}).Buttons | ? {$_.Tooltip} | sort Tooltip    
    foreach ($MinorFilter in $MajorList) {
        $j++
        Write-Progress -Id 1 -Activity "Building Minor Groups" -Status "$j of $($MajorList.Count)" -ParentId 0
        $MinorName = $MinorFilter.Tooltip
        $MinorLink = $MajorLink+"/$MinorName"
        $PageList += $MinorLink
        $Navbox += "• [[$MinorLink|$MinorName]] "
        $MajorPage += "[[$MinorLink]]`r`n`r`n"
        $MinorPageFile =  "Gear-$MajorName-$MinorName.txt"
        if (!$MinorFilter.Filter.ComponentTypes -and !$MinorFilter.Filter.Categories -and !$MinorFilter.Filter.NotCategories) {
            $AllMinorEquip = $AllMajorEquip
        } else {
            $AllMinorEquip = RT-DynamicFiter -InputObject $AllMajorEquip -ComponentTypes $MinorFilter.Filter.ComponentTypes -Categories $MinorFilter.Filter.Categories -NotCategories $MinorFilter.Filter.NotCategories
        }
        $MinorCats = $($AllMinorEquip.Custom.Category.CategoryID | Group).Name | ? {$_} | % {$MinorCatHash.$_} | ? {$_} | Sort-STNumerical
        $MinorPage = $null
        foreach ($MinorCat in $MinorCats) {
            $k++
            Write-Progress -Id 2 -Activity "Building Item Groups" -Status "$k of $($MinorCats.Count)" -ParentId 1
            #Hash the name out
            $MinorPage += "==$MinorCat==`r`n`r`n"
            $FilteredItemList = RT-DynamicFiter -InputObject $($GroupedList.$MinorCat) -ComponentTypes $MinorFilter.Filter.ComponentTypes -Categories $MinorFilter.Filter.Categories -NotCategories $MinorFilter.Filter.NotCategories
            $ItemList = $($FilteredItemList | select {$_.Description.UIName}).'$_.Description.UIName'
            if (-not !$ItemList) {
                $ItemList = $ItemList | Sort-STNumerical
            }
            foreach ($Item in $ItemList) {
                $l++
                Write-Progress -Id 3 -Activity "Populating Items" -Status "$l of $($ItemList.Count)" -ParentId 2
                $MinorPage += "* [[Gear/$Item|$Item]]`r`n"
            }
            $l=0
            $MinorPage += "`r`n"
        }
        $MinorPage = "{{-start-}}`r`n'''$MinorLink'''`r`n{{NavboxEquipment}}`r`n{{Tocright}}`r`n$MinorPage`r`n{{-stop-}}"
        $MinorPage | Out-File "$GearOutFolder\\$MinorPageFile" -Encoding utf8 -Force
        $k=0
    }
    $Navbox += "•`r`n"
    $MajorPage = "{{-start-}}`r`n'''$MajorLink'''`r`n{{NavboxEquipment}}`r`n{{Tocright}}`r`n$MajorPage`r`n{{-stop-}}"
    $MajorPage | Out-File "$GearOutFolder\\$MajorPageFile" -Encoding utf8 -Force
    $j=0
}
$GearPage = "`r`n{{-start-}}`r`n'''Gear'''`r`n{{NavboxEquipment}}`r`n`r`n" + $GearPage + "`r`n{{-stop-}}`r`n"
$GearPage | Out-File "$GearOutFolder\\GearMain.txt" -Encoding utf8 -Force

$Navbox += "}}"
$Navbox = "{{-start-}}`r`n'''Template:NavboxEquipment'''`r`n$Navbox`r`n{{-stop-}}"
$Navbox | Out-File "$GearOutFolder\\!Navbox.txt" -Encoding utf8 -Force

#Join into a supersized file for pwb upload - TOC Pages
$(Get-ChildItem $GearOutFolder -Filter 'Gear*').FullName | % {Get-Content $_ -Raw | Out-File "$GearOutFolder\\!TOCPages.txt" -Encoding utf8 -Append}

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
$(Get-ChildItem $ItemOutFolder -Recurse -Exclude '!*').FullName | % {Get-Content $_ -Raw | Out-File "$GearOutFolder\\!ItemPages.txt" -Encoding utf8 -Append}
