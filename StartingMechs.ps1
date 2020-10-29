###FUNCTIONS
#data chopper function
    #args: delimiter, position, input, backup position
function datachop {
    $array = @($args[2] -split "$($args[0])")
    if (($array.Count -le $args[1]) -and (-not !$args[3])) {
        return $array[$args[3]]
    }
    else {
        return $array[$args[1]]
    }
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
$TheText = "{{-start-}}`r`n'''Starting Mechs by Faction Choice'''`r`n"
$TheText += @"
In the 1.6 update, HBS reworked Battletech’s starter selection process. Starters are now randomly picked from defined pools of mechs, with each pool corresponding to a slot in the starting lance. We've adopted this system to make faction-specific starter mech pools.

When starting a new career, your choice of faction determines the mech pools you roll on. It also determines a relationship bonus (or sometimes malus) with at least one faction in the game.
			  
Most factions will have both light and a medium faction-themed pool of mechs. Most factions also roll on 3 generic pools that assign common mechs found everywhere and used by everyone during the Invasion era. Neither good nor bad, these mechs will likely be succession wars era tech and possibly less capable than your faction picks. There are various exceptions to this rule, as you can see below. Comstar pick from 5 custom pools that are restricted to light mechs only. 

These pools use [http://www.masterunitlist.info/Era/FactionEraDetails?FactionId=18&EraId=13 Comstar’s canonical mechs] and the advanced mechs used by the 5 Great Houses or mercenary troops. The generic Clan pools follow a similar formula, with 2 20/25 ton lists, 2 30 ton lists and a 35/40 ton list providing the 5th pick. These all offer a mixture of Omnimechs, ex [http://www.sarna.net/wiki/Star_League_Defense_Force SLDF] mechs or ex [http://www.sarna.net/wiki/Category:SLDF_Royal_BattleMechs Royal] mechs, each with vastly improved capabilities than their Inner Sphere counterparts.

__TOC__

= Factions =

Please note that this page is not exhaustively complete, as other modules of Roguetech also inject potential starting mechs. An attempt has been made to account for this, but is currently in progress.

"@

#The Factions Section

$CareersFile = "D:\RogueTech\RtlCache\RtCache\BTRandomStartByDifficultyMenu\Menus\CareerDifficultySettings.json"
$CareersBigObject = Get-Content $CareersFile -Raw | ConvertFrom-Json
$CareersObjects = $($CareersBigObject.difficultyList | ? {$_.ID -match 'diff_startingplanet'}).Options
foreach ($CareersObject in $CareersObjects) {
    $TheText += "`r`n== $($CareersObject.Name) =="
    $TheText += "`r`n'''Starting planet''': $($($CareersObject.DifficultyConstants | ? {$_.ConstantName -match 'StartingSystems'}).ConstantValue)`r`n"
    $TheText += "`r`n'''Reputation modifiers''':"
    $RepMods = $($CareersObject.DifficultyConstants | ? {$_.ConstantName -match 'FactionReputation'}).ConstantValue -split ',' | sort
    foreach ($RepMod in $RepMods) {
        $RepMod = $RepMod -split ':'
        $TheText += "`r`n* $($RepMod[0]): " + $(if ($RepMod[1] -gt 0) {"+$($RepMod[1])"} else {$RepMod[1]})
    }
    $TheText += @"
`r`n`r`n{| class="wikitable" style="text-align: left;"
|+'''Starting Mech Tables'''
!Table Used
!Picks on Table
"@
    $StartLists = $($CareersObject.DifficultyConstants | ? {$_.ConstantName -match 'StartingRandomMechLists'}).ConstantValue -split ',' | group | sort Name
    foreach ($StartList in $StartLists) {
        $ListName = datachop 'itemCollection_Mechs_' 1 $StartList[0].Name 
        if ($ListName -match 'Starting_') {
            $ListName = datachop 'Starting_' 1 $ListName
        }
        $ListName = $((Get-Culture).TextInfo.ToTitleCase($($ListName.Split('_') -join ' ').ToLower()))
        $TheText += "`r`n|-`r`n| [[#$ListName|$ListName]]`r`n| $($StartList.Count)"
    }
    $TheText += "`r`n|}`r`n"
}

#The Tables Section

$StartingMechsListsCSVs = $(Get-ChildItem $CacheRoot -Recurse -Filter "itemcollection_mechs*.csv" | select name, fullname) | group name
$StartingMechsListsGrouped = [pscustomobject]@{}
$GroupedNamesArray = @()
$StartingMechsListsCSVs.GetEnumerator() | % {
    Add-Member -InputObject $StartingMechsListsGrouped -MemberType NoteProperty -Name $(datachop '.csv' 0 $_.Name) -Value $_.Group.FullName
    $GroupedNamesArray += $(datachop '.csv' 0 $_.Name)
}
$StartingMechsLists = [pscustomobject]@{}
$GroupNamesArray = @()
foreach ($GroupedName in $GroupedNamesArray) {
    $ListsHolder = @()
    foreach ($GroupedFile in $StartingMechsListsGrouped.$GroupedName) {
        $ModName = Split-Path $(Split-Path $(Split-Path $GroupedFile -Parent) -Parent) -Leaf
        if ($ModName -match'BTRandomStartByDifficultyMenu') {
            $ModName = 'Base 3061'
        }
        $ListsHolder += Get-Content $GroupedFile | select -Skip 1 | % {$_ += ",$ModName";$_} | ConvertFrom-Csv -Header 'ID', 'Type', 'Quantity', 'Rarity', 'ModName'
    }
    $GroupName = $(datachop 'itemcollection_mechs_' 1 $GroupedName)
    if ($GroupName -match 'Starting_') {
        $GroupName = $(datachop 'Starting_' 1 $GroupName)
    }
    $GroupNamesArray += $GroupName
    Add-Member -InputObject $StartingMechsLists -MemberType NoteProperty -Name $GroupName -Value $ListsHolder
}

$GroupNamesArray = $GroupNamesArray | sort

$TheText += @"
`r`n= The Tables =
The tables are formatted like so:
{| class="wikitable" style="text-align: left;"
!Unit Designation
!Unit Type
!No. of Units
!Entry Weight
!Module

|-
|Unit Entry
|Type
|No.
|Weight
|Module
|-
|}

Please note some tables might be incomplete. Other modules inside Roguetech will dynamically modify these starting tables depending on whether they are installed or not; an attempt has been made to account for this, but some additions may well have been missed. If a mech is added by a specific module or set of modules this will be noted in the Module column; these modules are the options you choose in the Roguetech Launcher configuration screen. (Examples: the different DLC support modules, superheavy mechs, Pirate tech, Urbocalypse.) If this column is blank you don't need any extra install options to have a shot at that starter mech.

In order to understand these entries it may be helpful to check [https://www.sarna.net/wiki/Main_Page Sarna] or Roguetech's [[Full_List_of_Mechs|Full List of Mechs]].

 When pointed to a particular table, the starting mechbay population algorithm adds all of the numerical entry weights up together and then rolls 1dN, where N is the total of the weights in that table. This means that a unit with a weight of 4 has four times the likelihood of being selected than a unit with a weight of 1, but the actual percentage chance of any unit's selection depends on the total weight number of the table.
 
 At the moment, unit type is always mechs; however, there are plans to potentially include other unit types (such as vehicles). Similarly the number of units is always 1, but with the addition of different unit types this may change.

"@

$i=0
foreach ($GroupName in $GroupNamesArray) {
    $TheText += "`r`n== $((Get-Culture).TextInfo.ToTitleCase($($GroupName.Split('_') -join ' ').ToLower())) =="
    $TheText += @"
`r`n{| class="wikitable" style="text-align: left;"
!Unit Designation
!Unit Type
!No. of Units
!Entry Weight
!Module
"@
    foreach ($MechItem in $StartingMechsLists.$GroupName) {
        $i++
        Write-Progress -Activity "Number $i - $($MechItem.ID)"
        $Mech = [pscustomobject]@{}
        if ($MechItem.ID -match 'mechdef') {
            $MechDefFile = Get-ChildItem -Path $($CacheRoot + "\" + $MechItem.ModName) -Recurse -Filter "*$($MechItem.ID).json"
            if ($MechDefFile.Count -lt 1) {
                $MechDefFile = Get-ChildItem -Path $CacheRoot -Recurse -Filter "$($MechItem.ID).json"
            }
            $MechDef = Get-Content $MechDefFile.FullName -Raw | ConvertFrom-Json
            $Mech | Add-Member -MemberType NoteProperty -Name 'ModName' -Value $(Split-Path $(Split-Path $(Split-Path $MechDefFile.FullName -Parent) -Parent) -Leaf)
            $fileNameCDef = "$($MechDef.ChassisID).json"
            $ChassDefFile = Get-ChildItem $($CacheRoot + "\" + $Mech.ModName) -Recurse -Filter "$fileNameCDef"
            #if not found in modroot, try everything
            if (!$ChassDefFile) {
                $ChassDefFile = Get-ChildItem $CacheRoot -Recurse -Filter "$fileNameCDef"
            }
            try {$ChassDef = Get-Content $ChassDefFile.FullName -Raw | ConvertFrom-Json}
            catch {
                "$($MechDefFile.Name) $fileNameCDef"
            }

            $MechID = $MechItem.ID
            #2 Signature - / - << "VariantName": >> - $MechVarActual
                #also handles Hero Names
            $Mech | Add-Member -MemberType NoteProperty -Name "Name" -Value ([pscustomobject]@{})
            $MechVarActual = $ChassDef.VariantName
            ###Variant override
            #custom override for ZEUX0003
            if ($MechVarActual -eq "ZEUX0003") {
                $MechVarActual = "ZEU-9WD"
            }
            try {$Mech.Name | Add-Member -MemberType NoteProperty -Name "Variant" -Value "$($MechVarActual.ToUpper())"}
            catch {$MechID; pause}
            $MechVar = $MechVarActual
            for ($k = 0 ; $k -lt $($MechVarActual.Length) ; $k++) {
                if ($MechID -notlike "*$MechVar*") {
                    try {$MechVar = $MechVar.Substring(0,$($MechVar.Length) - 1)}
                    catch {$MechID; $MechVarActual; Pause}
                } 
                if ($($MechVar.Length) -le 3) {
                    $MechVar = $MechVarActual
                    break
                }
            }
            if (-not !$(datachop "$MechVar" 1 $MechID)) {
                $MechPostVar = $(datachop "$MechVar" 1 $MechID)
                $MechPostVar = $MechPostVar.Trim('_')
                $MechPostVar = $MechPostVar.Split("_")
                $MechSubVar = $MechPostVar[0]
                if ($MechPostVar.Count -gt 1) {
                    $MechHeroName = $MechPostVar[1..$($MechPostVar.Length -1)]
                    $MechHeroName = $MechHeroName -join (" ")
                } else {
                    $MechHeroName = ""
                }
            #override for incubus - filename doesn't containt variant
            } elseif ($MechVarActual -eq 'INC-II') {
                $MechPostVar = $(datachop "incubus_II" 1 $MechID)
                $MechPostVar = $MechPostVar.Trim('_')
                $MechPostVar = $MechPostVar.Split("_")
                $MechSubVar = $MechPostVar[0]
                if ($MechPostVar.Count -gt 1) {
                    $MechHeroName = $MechPostVar[1..$($MechPostVar.Length -1)]
                    $MechHeroName = $MechHeroName -join (" ")
                } else {
                    $MechHeroName = ""
                }
            } else {
                $MechSubVar = ""
                $MechHeroName = ""
            }
            $Mech.Name | Add-Member -MemberType NoteProperty -Name "SubVariant" -Value "$($MechSubVar.ToUpper())" -Force
            $Mech.Name | Add-Member -MemberType NoteProperty -Name "Hero" -Value "$($MechHeroName.ToUpper())" -Force
            #1 Name - /description - << "UIName": >>
            $MechCName = $ChassDef.Description.UIName
            $Mech.Name | Add-Member -MemberType NoteProperty -Name "Chassis" -Value "$($MechCName.ToUpper())"
            #1.1 Unique Name
            if ($($MechDef.Description.UIName) -notlike "*$MechCName*") {
                $MechQName = datachop " $MechVar" 0 "$($MechDef.Description.UIName)"
            } else {
                $MechQName = ""
            }
            $Mech.Name | Add-Member -MemberType NoteProperty -Name "Unique" -Value "$($MechQName.ToUpper())"

            #add wikilongname to PrefabID Object
            $VariantLink = $($Mech.Name.Variant)
            $VariantGlue = $($VariantLink+$($Mech.Name.SubVariant)).Trim()
            if (-not !$Mech.Name.Hero) {
                $VariantGlue += " ($($Mech.Name.Hero))"
            }
            if (-not !$mech.Name.Unique) {
                $VariantGlue += " aka $($Mech.Name.Unique)"
            }
            #unresolvable conflicts override
            if ([bool]($BlacklistOverride | ? {$MechDefFile.FullName -match $_})) {
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
            $TheText += "`r`n|-`r`n| [[Mechs/$VariantGlue|$VariantGlue]]`r`n| $($MechItem.Type)`r`n| $($MechItem.Quantity)`r`n| $($MechItem.Rarity)`r`n| $($MechItem.ModName)"
            if ($Mech.ModName -ne $MechItem.ModName) {
                $TheText += " | MechMod: $($Mech.ModName)"
            }
        } else {
            #do vehicle name fuckery here
            #setup CDef and MDef objects
            $Mech | Add-Member -MemberType NoteProperty -Name ID -Value $(datachop 'vehicledef_' 1 $MechItem.ID)
            $MDefFileObject = Get-ChildItem -Path $($CacheRoot + "\" + $MechItem.ModName) -Recurse -Filter "*$($MechItem.ID).json"
            $filePathMDef = $MDefFileObject.VersionInfo.FileName
            $fileNameMDef = $MDefFileObject.Name
            $FileObjectModRoot = "$($MDefFileObject.DirectoryName)\\.."
            try {$MDefObject = ConvertFrom-Json $(Get-Content $filePathMDef -raw)} catch {Write-Host $filePathMDef}
            $fileNameCDef = "$($MDefObject.ChassisID).json"
            $CDefFileObject = Get-ChildItem $FileObjectModRoot -Recurse -Filter "$fileNameCDef"
            #if not found in modroot, try everything
            if (!$CDefFileObject) {
                $CDefFileObject = Get-ChildItem $CacheRoot -Recurse -Filter "$fileNameCDef"
            }
            #2 Signature - / - << "VariantName": >> - $MechVarActual
                #also handles Hero Names
            $Mech | Add-Member -MemberType NoteProperty -Name "Name" -Value ([pscustomobject]@{})
            #1 Name - /description - << "UIName": >>
            #Chassis Name
            #parse for localization
            $LocalCheck = $(datachop '__/' 1 $CDefObject.Description.Name)
            if (-not !$LocalCheck) {
                $LocalCheck = $(datachop '/__' 0 $LocalCheck)
                if ($($TextObject | where -Property "Name" -Like $LocalCheck).Count -eq 1) {
                    $LocalBlurb = $($TextObject | where -Property "Name" -Like $LocalCheck).Original
                } elseif ($($TextObject | where -Property "Name" -Like $LocalCheck).Count -gt 1) {
                    $LocalBlurb = $($TextObject | where -Property "Name" -Like $LocalCheck)[0].Original
                }
                $MechCName = $LocalBlurb
            } else {
                $MechCName = $CDefObject.Description.Name
            }
            #Red October Override
            if ($MechCName -like "? ? ?") {
                $MechCName = "Red October"
            }

            #Full Name (mechdef)
            $LocalCheck = $(datachop '__/' 1 $MDefObject.Description.Name)
            if (-not !$LocalCheck) {
                $LocalCheck = $(datachop '/__' 0 $LocalCheck)
                if ($($TextObject | where -Property "Name" -Like $LocalCheck).Count -eq 1) {
                    $LocalBlurb = $($TextObject | where -Property "Name" -Like $LocalCheck).Original
                } elseif ($($TextObject | where -Property "Name" -Like $LocalCheck).Count -gt 1) {
                    $LocalBlurb = $($TextObject | where -Property "Name" -Like $LocalCheck)[0].Original
                }
                $MechFullName = $LocalBlurb
            } else {
                $MechFullName = $MDefObject.Description.Name
            }
            #Chop the chassis name out for Variant Name. 
            $MechSplitName = $MechFullName -split $MechCName
            $MechVName = ""
            $n = 0
            foreach ($NamePart in $MechSplitName) {
                $MechVName += " "+$NamePart
            }
            $MechVName = $MechVName.Trim()
            if (!$MechVName) {
                $MechVName = $MechCName
            }
            #If full is null, replace with Cname
            if (!$MechFullName) {
                $MechFullName = $MechCName
            }
            #If Variant name is less than 5 characters, just use full name
            # I think this is deprecated, but can't be fucked
            if ($MechVName.Length -lt 5) {
                $MechVName = $MechFullName
            }
            $Mech.Name | Add-Member -MemberType NoteProperty -Name "Chassis" -Value "$($MechCName.ToUpper())"
            $Mech.Name | Add-Member -MemberType NoteProperty -Name "Variant" -Value "$($MechVName.ToUpper())"
            $Mech.Name | Add-Member -MemberType NoteProperty -Name "Full" -Value "$($MechFullName.ToUpper())"
            #Create Link Name
            $SubVar = ""
            $NameArray = $($Mech.Name.Full -Replace "(\W+)","_").Trim("_").Split("_")
            $IDArray = $Mech.ID.Split("_")
            foreach ($NameItem in $NameArray) {
                $IDArray = [Array]$($IDArray | where { $_ -ne $NameItem })
            }
            foreach ($IDItem in $IDArray) {
                $SubVar += $IDItem + " "
            }
            $VariantLink = $($Mech.Name.Full + " " + $SubVar).Trim().ToUpper()
            $Mech.Name | Add-Member -MemberType NoteProperty -Name "SubVar" -Value $SubVar
            $VariantLink = $($Mech.Name.Full + " " + $Mech.Name.SubVar)
            $VariantLink = $VariantLink.Replace("'","")
            $VariantLink = $VariantLink.Trim()
            $VariantGlue = $VariantLink

            $TheText += "`r`n|-`r`n| [[Vehicles/$VariantGlue|$VariantGlue]]`r`n| Vehicle`r`n| $($MechItem.Quantity)`r`n| $($MechItem.Rarity)`r`n| $($MechItem.ModName)"
            if ($Mech.ModName -ne $MechItem.ModName) {
                $TheText += " <> MechMod: $($Mech.ModName)"
            }
        }
        
    }
$TheText += "`r`n|}"
}
$TheText += "`r`n{{-stop-}}"
$OutFile = "D:\\RogueTech\\WikiGenerators\\Outputs\\StartingMechs.UTF8"
$TheText | Set-Content -Encoding UTF8 $OutFile

$PWBRoot = "D:\\PYWikiBot"
py $PWBRoot\\pwb.py pagefromfile -file:$ColourOutFile -notitle -force -pt:0