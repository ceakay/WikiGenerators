function ChassAffinities {
    $CacheRoot = "D:\\RogueTech\\RtlCache\\RtCache"
    $RTScriptroot = "D:\\RogueTech\\WikiGenerators"
    $AffinitiesFile = "$CacheRoot\\MechAffinity\\settings.json"
    $FixedAffinityFile = "$RTScriptroot\\Outputs\\FixedAffinity.json"
    $EquipAffinitiesMaster = $(Get-Content $AffinitiesFile -Raw | ConvertFrom-Json).chassisAffinities
    $EquipAffinitiesRef = @()
    foreach ($EquipAffinity in $EquipAffinitiesMaster) {
        foreach ($AffinityItem in $EquipAffinity.chassisNames) {
            $EquipAffinitiesRef += [pscustomobject]@{
                ID = $AffinityItem
                Num = $EquipAffinity.affinityLevels.missionsRequired
                Name = $EquipAffinity.affinityLevels.levelName
                Description = $EquipAffinity.affinityLevels.decription
            }
        }
    }
    $FixedAffinityObject = Get-Content $FixedAffinityFile -Raw | ConvertFrom-Json

    $GearFile = $RTScriptroot+"\\Outputs\\GearTable.json"
    $GearObject = Get-Content $GearFile -raw | ConvertFrom-Json
    $ItemFriendlyHash = @{}
    $ItemSlotsHash = @{}
    foreach ($Item in $GearObject) {
        #Build Item Friendly Name Hash
        if (-not !$Item.Description.UIName) {
            try {$ItemFriendlyHash.Add($Item.Description.Id,$Item.Description.UIName)} catch {"MechWiki|Dupe gear ID: $($Item.Description.Id)" | Out-File $RTScriptroot\ErrorLog.txt -Append -Encoding utf8}
        }
        #build Item Slots hash
        if (-not !$Item.InventorySize) {
            try {$ItemSlotsHash.Add($Item.Description.Id,$Item.InventorySize)} catch {""}
        } else {
            try {$ItemSlotsHash.Add($Item.Description.Id,1)} catch {""}
        }
    }

    $InputObject = @()
    foreach ($Item in $($($EquipAffinitiesRef | group Name | sort Name).GetEnumerator())) {
        $InputObject += [pscustomobject]@{
            Name = $Item.Name
            "Missions Required" = @($Item.Group.Num)[0]
            Description = @($Item.Group.Description)[0]
        }
    }
    
    return $InputObject
}

function GearAffinities {
    $CacheRoot = "D:\\RogueTech\\RtlCache\\RtCache"
    $RTScriptroot = "D:\\RogueTech\\WikiGenerators"
    $AffinitiesFile = "$CacheRoot\\MechAffinity\\settings.json"
    $FixedAffinityFile = "$RTScriptroot\\Outputs\\FixedAffinity.json"
    $EquipAffinitiesMaster = $(Get-Content $AffinitiesFile -Raw | ConvertFrom-Json).quirkAffinities
    $EquipAffinitiesRef = @()
    foreach ($EquipAffinity in $EquipAffinitiesMaster) {
        foreach ($AffinityItem in $EquipAffinity.quirkNames) {
            $EquipAffinitiesRef += [pscustomobject]@{
                ID = $AffinityItem
                Num = $EquipAffinity.affinityLevels.missionsRequired
                Name = $EquipAffinity.affinityLevels.levelName
                Description = $EquipAffinity.affinityLevels.decription
            }
        }
    }
    $FixedAffinityObject = Get-Content $FixedAffinityFile -Raw | ConvertFrom-Json

    $GearFile = $RTScriptroot+"\\Outputs\\GearTable.json"
    $GearObject = Get-Content $GearFile -raw | ConvertFrom-Json
    $ItemFriendlyHash = @{}
    $ItemSlotsHash = @{}
    foreach ($Item in $GearObject) {
        #Build Item Friendly Name Hash
        if (-not !$Item.Description.UIName) {
            try {$ItemFriendlyHash.Add($Item.Description.Id,$Item.Description.UIName)} catch {"MechWiki|Dupe gear ID: $($Item.Description.Id)" | Out-File $RTScriptroot\ErrorLog.txt -Append -Encoding utf8}
        }
        #build Item Slots hash
        if (-not !$Item.InventorySize) {
            try {$ItemSlotsHash.Add($Item.Description.Id,$Item.InventorySize)} catch {""}
        } else {
            try {$ItemSlotsHash.Add($Item.Description.Id,1)} catch {""}
        }
    }

    $InputObject = @()
    foreach ($Item in $($($EquipAffinitiesRef | group Name | sort Name).GetEnumerator())) {
        $GearListLink = ""
        foreach ($ID in @($Item.Group.ID)) {
            $GearListLink += $("<br>[[Gear/$($ItemFriendlyHash.$ID)|$($ItemFriendlyHash.$ID)]]")
        }
        $GearListLink = $($GearListLink.Trim('<br>'))
        $InputObject += [pscustomobject]@{
            Name = $Item.Name
            "Missions Required" = @($Item.Group.Num)[0]
            Description = @($Item.Group.Description)[0]
            "Gear List" = $GearListLink
        }
    }
    
    return $InputObject
}

function FormatWikiTableFrom-Array {
    #Params
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)]
        $InputObject
    )

    #Begin
    $TableOptionsObject = @"
ID,Value,Enabled
1,sortable,$false
2,mw-collapsible,$false
3,mw-collapsed,$false
"@ | ConvertFrom-Csv
    #parse string to bool
    foreach ($Item in $TableOptionsObject) {
        $Item.Enabled = [bool]::Parse($Item.Enabled)
    }
    $TableOptionsFinish = $false
    #Get header options
    do {
        Clear-Host
        $TableOptionsObject | FT
        $TableOptionsErrors
        $TableOptionsSelect = Read-Host "Toggle Option or enter blank to continue: "
        $TableOptionsErrors = $null
        Switch ($TableOptionsSelect) {
            "" {$TableOptionsFinish = $true}
            default {
                try {
                    $OptionHolder = $($TableOptionsObject | ? {$_.ID -eq $TableOptionsSelect})
                    $OptionHolder.Enabled = !$OptionHolder.Enabled
                } catch {
                    $TableOptionsErrors = "Invalid Selection"
                }
            }
        }
    } until ($TableOptionsFinish)
    $TableOptions = ""
    foreach ($EnabledOption in $($TableOptionsObject | ? {$_.Enabled -eq $true})) {
        $TableOptions += " $($EnabledOption.Value)"
    }
    $TableHeader = "{| class=`"wikitable$TableOptions`"`r`n"
    $TableFooter = "|}"

    #Read first item for titles
    $TableTitle = ""
    $TitleList = $InputObject[0].psobject.Properties.Name
    foreach ($TitleItem in $TitleList) {
        $TableTitle += " !! $TitleItem"
    }
    $TableTitle = "!" + $($TableTitle.Trim()).Trim('!') + "`r`n"

    #Read contents into table
    $TableContent = ""
    foreach ($ObjectItem in $InputObject) {
        $TableLine = ""
        $TableContent += "|-`r`n"
        foreach ($Title in $TitleList) {
            $TableLine += " || $($ObjectItem.$Title)"
        }
        $TableLine = "|" + $($TableLine.Trim()).Trim('|') + "`r`n"
        $TableContent += $TableLine
    }

    $Table = $($TableHeader + $TableTitle + $TableContent + $TableFooter)

    reutrn $Table
}