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
$EquipmentPageBlurbFile = $RTScriptroot+"\\Inputs\\Blurbs\\Equipment.txt"
$WeaponPageBlurbFile = $RTScriptroot+"\\Inputs\\Blurbs\\Weapons.txt"
$AmmoPageBlurbFile = 
$InternalsPageBlurbFile = 
$GearPageBlurbFile = 

#hashes
$MajorCatsHash = @{
    WEAPON = "Weapons"
    AMMO = "Ammuntion"
    Internals = "Internals"
    EQUIP = "Gear"
}


#Load Master List, remove blacklisted
Write-Progress -Id 0 -Activity "Loading Master Object"
$MasterList = [System.Collections.ArrayList]@($(Get-Content $EquipFile -Raw | ConvertFrom-Json) | ? {$_.ComponentTags.items -notmatch "blacklist"}) | ? {$_.Description.UIName -notmatch 'Deprecated'}

#Load Filters List
Write-Progress -Id 0 -Activity "Loading Custom Filters"
$FiltersList = $(Get-Content $FiltersFile -Raw | ConvertFrom-Json).Settings.Tabs

#Build minor cat hash
Write-Progress -Id 0 -Activity "Building Hashes"
$MinorCatFiles = Get-ChildItem $MinorCatPath -Filter "Categories*.json"
$MinorCatHash = @{}
foreach ($MinorCatFile in $MinorCatFiles) {
    $MinorCatObject = $(Get-Content $MinorCatFile.FullName -Raw | ConvertFrom-Json).Settings
    foreach ($MinorCatItem in $MinorCatObject) {
        $MinorCatHash.Add($($MinorCatItem.Name), $($MinorCatItem.DisplayName))
    }
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

#Init Pages Text from blurbfiles
$EquipmentPage = Get-Content $EquipmentPageBlurbFile
$PageList = @('Equipment')

foreach ($MajorKey in $MajorCatsHash.Keys) {
    $MajorLink = "Equipment/$($MajorCatsHash.$MajorKey)"
    $PageList += $MajorLink
    $EquipmentPage += "[[$MajorLink]]`r`n"
    $MajorPageFile = $RTScriptroot+"\\Outputs\\$MajorKey-Page.txt"
    $MajorPage = $null
    $MajorList = $($FiltersList | ? {$_.Caption -eq $MajorKey}).Buttons | ? {$_.Tooltip -and $_.Filter.Categories}
    foreach ($MinorFilter in $MajorList) {
        $MinorName = datachop 'Show ' 1 $MinorFilter.Tooltip
        $MinorLink = $MajorLink+"/$MinorName"
        $PageList += $MinorLink
        $MinorCats = $($($MinorFilter.Filter.Categories) | % { $($MinorCatHash.$_) }) | sort
        $MajorPage += "[[$MinorLink]]`r`n"
        $MinorPage = $null
        foreach ($MinorCat in $MinorCats) {
            $MinorPage += "==$MinorCat==`r`n"
            $ItemList = $($GroupedList.$MinorCat | select {$_.description.uiname}).'$_.Description.UIName' | Sort-STNumerical
            foreach ($Item in $ItemList) {
                $MinorPage += "[[Equipment/$Item]]`r`n"
                