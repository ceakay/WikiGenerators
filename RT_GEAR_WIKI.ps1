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

<# This got moved to it's own PS1 script because it's too damn big
function RT-CreateGearPages {

#>

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

#Load Master List
Write-Progress -Id 0 -Activity "Loading Master Object"
$MasterList = [System.Collections.ArrayList]@($(Get-Content $EquipFile -Raw | ConvertFrom-Json) | ? {$_.Description.ID -notmatch 'emod_engineslots_size'}  | ? {$_.Description.ID -notmatch 'Gear_LegJet_Assault_Lower'}) #| ? {$_.ComponentTags.items -notcontains "blacklisted"})

#Cleanup Duplicates
#Remove Deprecated
Write-Progress -Id 0 -Activity "Scrubbing Deprecated"
$MasterList = $MasterList | ? {$_.Description.UIName -notmatch 'DEPRECATED!'} | ? {$_.Description.UIName -notmatch 'DEPRECIATED!'}
#Remove Linked
Write-Progress -Id 0 -Activity "Scrubbing Linked"
$LinkedList = $MasterList.Custom.Linked.Links.ComponentDefId | select
$MasterList = $MasterList | ? {$_.Description.Id -notin $LinkedList}
#Check if group contains single or only blacklisted
Write-Progress -Id 0 -Activity "Scrubbing BlacklistOnly and BlacklistSingle"
$DuplicatesGroup = $($($MasterList | Group {$_.Description.UIName}) | ? {$_.Count -ge 2})
$BlacklistOnlyList = @()
$BlacklistSingleList = @()
foreach ($DuplicatesGroupItem in $DuplicatesGroup) {
    if (@($DuplicatesGroupItem.Group | ? {$_.ComponentTags.items -notcontains 'BLACKLISTED'}).Count -eq 0) {
        $DupeCounter = 0
        if (@($DuplicatesGroupItem.Group.Description.Id).Count -gt 1) {
            $DupeCounter = @($DuplicatesGroupItem.Group.Description.Id).Count - 2
        }
        $BlacklistOnlyList += $DuplicatesGroupItem.Group.Description.Id[0..$DupeCounter] #Pick anything to create a classified page with
    } 
    elseif (@($DuplicatesGroupItem.Group | ? {$_.ComponentTags.items -notcontains 'BLACKLISTED'}).Count -ge 1) {
        $BlacklistSingleList += $($DuplicatesGroupItem.Group | ? {$_.ComponentTags.items -contains 'BLACKLISTED'}).Description.Id #If 1 or more are not blacklisted, delete the blacklisted items.
    }
}
$MasterList = $MasterList | ? {$_.Description.Id -notin $BlacklistOnlyList}
$MasterList = $MasterList | ? {$_.Description.Id -notin $BlacklistSingleList}
#Remove Lootables
Write-Progress -Id 0 -Activity "Scrubbing Lootables"
$LootableKeepList = $MasterList.Custom.Lootable.ItemID | select
$DuplicatesGroup = $($($MasterList | Group {$_.Description.UIName}) | ? {$_.Count -ge 2})
$LootableList = $($DuplicatesGroup.Group | ? {-not !$_.Custom.Lootable.ItemID}).Description.ID
$MasterList = $MasterList | ? {$_.Description.Id -notin $LootableList}
#Remove from hard ignore - GearIgnore.CSV
Write-Progress -Id 0 -Activity "Removing from manual list"
$GearIgnoreFile = $RTScriptroot+"\\Inputs\\GearIgnore.csv"
$GearIgnoreList = $(Get-Content $GearIgnoreFile -Raw | ConvertFrom-Csv).GearIgnore
$MasterList = $MasterList | ? {$_.Description.Id -notin $GearIgnoreList}
#CustomOverrides
$($MasterList | ? {$_.Description.ID -eq 'Weapon_Laser_TAG_HeyListen'}).Description.UIName = 'TAG (NAVI)'
$($MasterList | ? {$_.Description.ID -eq 'Gear_Cockpit_SensorsB_Standard'}).Description.UIName = 'Sensors (B)'


#Load Filters List
Write-Progress -Id 0 -Activity "Loading Custom Filters"
$FiltersList = $(Get-Content $FiltersFile -Raw | ConvertFrom-Json).Settings.Tabs
#Remove 'Show'
$FiltersList.Buttons | ? {$_.Tooltip} | % { if ($_.Tooltip -match 'Show ') {$_.Tooltip = datachop 'Show ' 1 $_.Tooltip}}

#Load GearUsedBy
$GearUsedByFile = "$RTScriptroot\\Outputs\\GearUsedBy.json"
$GearUsedBy = Get-Content $GearUsedByFile -Raw | ConvertFrom-Json

#Load Gear Affinities
$AffinitiesFile = "$CacheRoot\\MechAffinity\\settings.json"
$FixedAffinityFile = "$RTScriptroot\\Outputs\\FixedAffinity.json"
$EquipAffinitiesMaster = $(Get-Content $AffinitiesFile -Raw | ConvertFrom-Json).quirkAffinities
$JobEquipAffinitiesRef = @()
foreach ($EquipAffinity in $EquipAffinitiesMaster) {
    foreach ($AffinityItem in $EquipAffinity.quirkNames) {
        $JobEquipAffinitiesRef += [pscustomobject]@{
            ID = $AffinityItem
            Num = $EquipAffinity.affinityLevels.missionsRequired
            Name = $EquipAffinity.affinityLevels.levelName
            Description = $EquipAffinity.affinityLevels.decription
        }
    }
}
$JobFixedAffinityObject = Get-Content $FixedAffinityFile -Raw | ConvertFrom-Json

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
$BonusDescFiles = Get-ChildItem $CacheRoot -Recurse -Filter "BonusDescriptions*.json"
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
    Start-Job -Name $("ItemJob"+$JobCount) -FilePath D:\RogueTech\WikiGenerators\RT-CreateGearPages.ps1 -ArgumentList $JobInputObject,$BonusDescHash,$GearUsedBy,$JobFixedAffinityObject,$JobEquipAffinitiesRef,$JobOutputFile | Out-Null
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
