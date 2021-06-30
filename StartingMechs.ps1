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

Write-Host @"





































"@


#SET CONSTANTS
###
#RogueTech Dir (Where RTLauncher exists)
$RTroot = "D:\\RogueTech"
#Script Root
$RTScriptroot = "D:\\RogueTech\\WikiGenerators"
cd $RTScriptroot
#cache path
$CacheRoot = "$RTroot\\RtlCache\\RtCache"

#The MegaHash for friendlyname
$DefLinkNameHash = @{}
$Mechs = Get-Content $RTScriptroot\\Outputs\\MechListTable.json -raw | ConvertFrom-Json
$Tanks = Get-Content $RTScriptroot\\Outputs\\TankListTable.json -raw | ConvertFrom-Json
$Gears = Get-Content $RTScriptroot\\Outputs\\GearTable.json -raw | ConvertFrom-Json
$Mechs | select @{Name = 'DefName'; Expression = {if (!$_.MechDefFile) {"$($_.Description.ID)"} else {"$($($_.MechDefFile -split '\\')[-1].Split('.')[0])"}}}, @{Name = 'LinkName'; Expression = {if (!$_.Name.LinkName) {$_.Description.UIName} else {$_.Name.LinkName}}} | % {if (!$($DefLinkNameHash.$($_.DefName))) {$DefLinkNameHash.Add($_.DefName, $_.LinkName)}}
$Tanks | select @{Name = 'DefName'; Expression = {if (!$_.MechDefFile) {"$($_.Description.ID)"} else {"$($($_.MechDefFile -split '\\')[-1].Split('.')[0])"}}}, @{Name = 'LinkName'; Expression = {if (!$_.Name.LinkName) {$_.Description.UIName} else {$_.Name.LinkName}}} | % {if (!$($DefLinkNameHash.$($_.DefName))) {$DefLinkNameHash.Add($_.DefName, $_.LinkName)}}
$Gears | select @{Name = 'DefName'; Expression = {if (!$_.MechDefFile) {"$($_.Description.ID)"} else {"$($($_.MechDefFile -split '\\')[-1].Split('.')[0])"}}}, @{Name = 'LinkName'; Expression = {if (!$_.Name.LinkName) {$_.Description.UIName} else {$_.Name.LinkName}}} | % {if (!$($DefLinkNameHash.$($_.DefName))) {$DefLinkNameHash.Add($_.DefName, $_.LinkName)}}

$RTVersion = $(Get-Content "$CacheRoot\\RogueTech Core\\mod.json" -raw | ConvertFrom-Json).Version
$TheText = "{{-start-}}`r`n@@@Starting Equipment@@@`r`n"
$TheText += @"
Last Updated: $RTVersion

In the 1.6 update, HBS reworked Battletech’s starter selection process. Starters are now randomly picked from defined pools of mechs, with each pool corresponding to a slot in the starting lance. We've adopted this system to make faction-specific starter mech pools.

When starting a new career, your choice of faction determines the mech pools you roll on. It also determines a relationship bonus (or sometimes malus) with at least one faction in the game.
			  
Most factions will have both light and a medium faction-themed pool of mechs. Most factions also roll on 3 generic pools that assign common mechs found everywhere and used by everyone during the Invasion era. Neither good nor bad, these mechs will likely be succession wars era tech and possibly less capable than your faction picks. There are various exceptions to this rule, as you can see below. Comstar pick from 5 custom pools that are restricted to light mechs only. 

These pools use [http://www.masterunitlist.info/Era/FactionEraDetails?FactionId=18&EraId=13 Comstar’s canonical mechs] and the advanced mechs used by the 5 Great Houses or mercenary troops. The generic Clan pools follow a similar formula, with 2 20/25 ton lists, 2 30 ton lists and a 35/40 ton list providing the 5th pick. These all offer a mixture of Omnimechs, ex [http://www.sarna.net/wiki/Star_League_Defense_Force SLDF] mechs or ex [http://www.sarna.net/wiki/Category:SLDF_Royal_BattleMechs Royal] mechs, each with vastly improved capabilities than their Inner Sphere counterparts.

__TOC__

= Starts =

Each start will pick from a number of tables. Below is a list of the tables used, as well the number of picks for each table. This will provide you your starting lance. 

"@


#The Factions Section

$CareersFile = "D:\RogueTech\RtlCache\RtCache\IRTweaks\Menus\CareerDifficultySettings.json"
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

$StartingMechsListsCSVs = $(Get-ChildItem $CacheRoot -Recurse -Filter "itemcollection_mechs*.csv" | select name, fullname | ? {$_.Name -ne 'itemCollection_Mechs_rare.csv'}) | group name
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
        if ($ModName -match'IRTweaks' -or $BGModName -match 'RogueTech Core') {
            $ModName = $null
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

In order to understand these entries it may be helpful to check [https://www.sarna.net/wiki/Main_Page Sarna] or Roguetech's [[Full_List_of_Mechs|Full List of Mechs]].

 When pointed to a particular table, the starting mechbay population algorithm adds all of the numerical entry weights up together and then rolls 1dN, where N is the total of the weights in that table. This means that a unit with a weight of 4 has four times the likelihood of being selected than a unit with a weight of 1, but the actual percentage chance of any unit's selection depends on the total weight number of the table.

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
    foreach ($MechItem in $($StartingMechsLists.$GroupName | ? {$_})) {
        $i++
        Write-Progress -Activity "Number $i - $($MechItem.ID)"
        if ($MechItem.ID -match 'mechdef') {
            $TheText += "`r`n|-`r`n| [[Mechs/$($DefLinkNameHash.$($MechItem.ID))|$($DefLinkNameHash.$($MechItem.ID))]]`r`n| Mech `r`n| $($MechItem.Quantity)`r`n| $($MechItem.Rarity)`r`n| $($MechItem.ModName)"
        } elseif ($MechItem.ID -match 'vehicledef') {
            $TheText += "`r`n|-`r`n| [[Vehicles/$($DefLinkNameHash.$($MechItem.ID))|$($DefLinkNameHash.$($MechItem.ID))]]`r`n| Vehicle `r`n| $($MechItem.Quantity)`r`n| $($MechItem.Rarity)`r`n| $($MechItem.ModName)"
        } else {
            $TheText += "`r`n|-`r`n| [[Gear/$($DefLinkNameHash.$($MechItem.ID))|$($DefLinkNameHash.$($MechItem.ID))]]`r`n| Gear `r`n| $($MechItem.Quantity)`r`n| $($MechItem.Rarity)`r`n| $($MechItem.ModName)"
        }
        
    }
    $TheText += "`r`n|}"
}

#The Careers Section
$TheText += @"

= Backgrounds =

Each background career will award a lootbox of bonus equipment on your second day. Similar to starts, these pick from tables. 

"@

$StartingBackgroundsJSONs = $(Get-ChildItem $CacheRoot -Recurse -Filter "background_career*.json"| sort BaseName | select name, fullname, @{Name = "Mod"; Expression = {$(Split-Path $_.FullName -Parent).Split('\\')[-2]}} | ? {$_.Name -ne 'itemCollection_Mechs_rare.csv'})
$StartingBackgroundsJSONs | ? {$_.Mod -eq 'RogueBackgrounds'} | % {$_.Mod = $null} #remove base careers 'mod'
$BGTableNameHash = @{}

foreach ($BackgroundsJSON in $StartingBackgroundsJSONs) {
    $BackgroundsObject = Get-Content $BackgroundsJSON.FullName -Raw | ConvertFrom-Json
    $BackgroundsObject | Add-Member -NotePropertyName Mod -NotePropertyValue $BackgroundsJSON.Mod
    $BackgroundsEventID = $BackgroundsObject.Results.ForceEvents.EventID
    $BackgroundsItemCollectionReference = $(Get-Content $(Get-ChildItem $CacheRoot -Recurse -Filter "$BackgroundsEventID*.json").FullName -Raw | ConvertFrom-Json).Options.ResultSets.Results.Actions.value
    $TheText += "`r`n`r`n== $($BackgroundsObject.Description.Name) ==`r`n"
    if (-not !$BackgroundsItemCollectionReference) {
        if ($BackgroundsItemCollectionReference -match 'vehicledef_AWACS') {
            $TheText += "`r`n`r`nNo bonus equipment picks awarded. [[Vehicles/AWACS|AWACS]] awarded directly to roster."
        } else {
            $BackgroundsItemCollection = $(Get-Content $(Get-ChildItem $CacheRoot -Recurse -Filter "$BackgroundsItemCollectionReference*.csv").FullName) | Select -Skip 1 | ConvertFrom-Csv -Header Name, Type, Picks, Chance

            $TheText += @"
`r`n{| class="wikitable" style="text-align: left;"
! Table Used
! Picks on Table
"@
            foreach ($BackgroundTables in $BackgroundsItemCollection) {
                $TableNameArray = $($BackgroundTables.Name -split '_')
                $TableName = $($($TableNameArray[1..$($TableNameArray.Count - 1)]) -join ' ').ToUpper()
                if (!$($BGTableNameHash.$($BackgroundTables.Name))) {
                    $BGTableNameHash.Add($BackgroundTables.Name, $TableName)
                }
                $TheText += @"

|-
| [[#$TableName|$TableName]]
| $($BackgroundTables.Picks)
"@
            }
            $TheText += "`r`n|}"
        }
    } else {
        $TheText += "`r`n`r`nNo bonus equipment picks awarded."
    }
}

#Backgrounds Tables
#Need to parse collections for recursive references #Raza5WHY
#yes, i'm doing needless loops. I can't be fucked to clean this up.
do {
    $CollectionsFound = 0
    foreach ($Collection in @($BGTableNameHash.GetEnumerator())) {
        $CollectionRefIDArray = $($(Get-Content $(Get-ChildItem $CacheRoot -Recurse -Filter "$($Collection.Name)*.csv").FullName) | Select -Skip 1 | ? {$_ -match 'Reference'} | ConvertFrom-Csv -Header Name, Type, Picks, Chance).Name
        foreach ($CollectionRefID in $CollectionRefIDArray) {
            $CollectionRefNameArray = $($CollectionRefID -split '_')
            $CollectionRefName = $($($CollectionRefNameArray[1..$($CollectionRefNameArray.Count - 1)]) -join ' ').ToUpper()
            if (!$($BGTableNameHash.$($CollectionRefID))) {
                $BGTableNameHash.Add($CollectionRefID, $CollectionRefName)
                $CollectionsFound++
            }
        }
    }
} while ($CollectionsFound -ne 0)

$TheText += @"

= Background Tables =

The tables that backgrounds pick from.

"@

$BGTableNameArray = @($BGTableNameHash.GetEnumerator()).Value | Sort-STNumerical


foreach ($BGTableName in $BGTableNameArray) {
    $TheText += "`r`n`r`n== $($BGTableName) ==`r`n"
    $BGTable = $($BGTableNameHash.GetEnumerator() | ? {$_.Value -eq $BGTableName}).Name
    $BGTableFiles = $(Get-ChildItem $CacheRoot -Filter "$BGTable.csv" -Recurse).FullName
    $BGTableLists = @()
    foreach ($BGTableFile in $BGTableFiles) {
        $BGModName = Split-Path $(Split-Path $(Split-Path $BGTableFile -Parent) -Parent) -Leaf
        if ($BGModName -match 'RogueBackgrounds' -or $BGModName -match 'RogueTech Core') {
            $BGModName = $null
        }
        $BGTableLists += Get-Content $BGTableFile | select -Skip 1 | % {$_ += ",$BGModName";$_} | ConvertFrom-Csv -Header 'ID', 'Type', 'Quantity', 'Rarity', 'ModName'
    }

    $TheText += @"
`r`n{| class="wikitable" style="text-align: left;"
!Unit Designation
!Unit Type
!No. of Units
!Entry Weight
!Module
"@
    foreach ($MechItem in $BGTableLists) {
        $i++
        Write-Progress -Activity "Number $i - $($MechItem.ID)"
        if ($MechItem.Type -match 'Reference') {
            $TheText += "`r`n|-`r`n| [[#$($BGTableNameHash.$($MechItem.ID))|$($BGTableNameHash.$($MechItem.ID))]]`r`n| Reference `r`n| $($MechItem.Quantity)`r`n| $($MechItem.Rarity)`r`n| $($MechItem.ModName)"
        } elseif ($MechItem.ID -match 'mechdef') {
            $TheText += "`r`n|-`r`n| [[Mechs/$($DefLinkNameHash.$($MechItem.ID))|$($DefLinkNameHash.$($MechItem.ID))]]`r`n| Mech `r`n| $($MechItem.Quantity)`r`n| $($MechItem.Rarity)`r`n| $($MechItem.ModName)"
        } elseif ($MechItem.ID -match 'vehicledef') {
            $TheText += "`r`n|-`r`n| [[Vehicles/$($DefLinkNameHash.$($MechItem.ID))|$($DefLinkNameHash.$($MechItem.ID))]]`r`n| Vehicle `r`n| $($MechItem.Quantity)`r`n| $($MechItem.Rarity)`r`n| $($MechItem.ModName)"
        } else {
            $TheText += "`r`n|-`r`n| [[Gear/$($DefLinkNameHash.$($MechItem.ID))|$($DefLinkNameHash.$($MechItem.ID))]]`r`n| Gear `r`n| $($MechItem.Quantity)`r`n| $($MechItem.Rarity)`r`n| $($MechItem.ModName)"
        }
        
    }
    $TheText += "`r`n|}"
}

#PYWrapper
$TheText += "`r`n{{-stop-}}"
$OutFile = "D:\\RogueTech\\WikiGenerators\\Outputs\\StartingMechs.UTF8"
$TheText | Set-Content -Encoding UTF8 $OutFile

$PWBRoot = "D:\\PYWikiBot"
$titlestartend = "@@@"
py $PWBRoot\\pwb.py pagefromfile -file:$OutFile -notitle -force -pt:0 -titlestart:$titlestartend -titleend:$titlestartend
