param (
    [Parameter(Mandatory=$false, Position=0)][string]$CacheDir
)

###FUNCTIONS
#useful functions
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

Function IIf($If, $IfTrue, $IfFalse) {
    If ($If) {If ($IfTrue -is "ScriptBlock") {&$IfTrue} Else {$IfTrue}}
    Else {If ($IfFalse -is "ScriptBlock") {&$IfFalse} Else {$IfFalse}}
}

#get-functions
Function Get-RTValid($CacheRoot) {
    try {
        Get-Content "$CacheRoot\RogueTech Core\mod.json" -Raw -ErrorAction Stop | Out-Null
        $ReturnText = "Lock In Cache"
    } catch {
        $ReturnText = "Invalid Cache DIR"
    }
    return $ReturnText
}

Function Get-Folder($initialDirectory="") {
    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

    $foldername = New-Object System.Windows.Forms.FolderBrowserDialog
    $foldername.Description = "Select a folder"
    $foldername.rootfolder = "MyComputer"
    $foldername.SelectedPath = $initialDirectory

    if($foldername.ShowDialog() -eq "OK")
    {
        $folder += $foldername.SelectedPath
    }
    return $folder
}

Function RepLevels {
    
    $ReturnItem = [pscustomobject]@{
        Array = @(
            "Loathed",
            "Hated",
            "Disliked",
            "Indifferent",
            "Liked",
            "Friendly",
            "Honored",
            "Allied"
        )
        ComboBox = @()
        SimGameEnum = @()
    }

    $i=0
    foreach ($Level in $ReturnItem.Array) {
        $ReturnItem.ComboBox += [pscustomobject]@{
            display = $Level
            value = $i
        }
        $ReturnItem.SimGameEnum += [pscustomobject]@{
            display = $Level
            value = $i-3
        }
        if ($Level -match "Allied") {
            $($ReturnItem.SimGameEnum | ? {$_.display -eq "Allied"}).value = 3
        }
        $i++
    }
    return $ReturnItem
}

Function Get-DSResultsBySystem {
    param (
        [Parameter(Mandatory=$true, Position=0)][array]$SShopsDef,
        [Parameter(Mandatory=$true, Position=1)][array]$DSSystemTags,
        [Parameter(Mandatory=$true, Position=2)][string]$DSSystemOwner,
        [Parameter(Mandatory=$true, Position=3)][string]$DSSystemGroup,
        [Parameter(Mandatory=$true, Position=4)][int]$DSSystemRep
    )

    #Pass Tags, then Owner, then Group
    #Compare objects, isolate for uniques found in conditions, not ALL the results to get only results where all tag conditions are met
    $DSSystemPassTags = $SShopsDef | ? {-not (Compare-Object $([array]$($_.conditions.tag)) $($DSSystemTags) | ? SideIndicator -eq '<=')}
    #Check owner and owner's group
    $DSSystemPassOwner = $DSSystemPassTags | ? {($_.conditions.owner -eq $DSSystemOwner) -or ($_.conditions.owner -eq $DSSystemGroup) -or (!$_.conditions.owner)}
    #Check rep
    $DSSystemPassAll = $DSSystemPassOwner | ? {
        (!$_.conditions.rep) -or
        ($DSSystemRep -ge $_.conditions.repvalue -and $_.conditions.repmod -eq "ge") -or 
        ($DSSystemRep -eq $_.conditions.repvalue -and $_.conditions.repmod -eq "eq") -or
        ($DSSystemRep -le $_.conditions.repvalue -and $_.conditions.repmod -eq "le")
    }

    return $($($DSSystemPassAll.items | group).Name | Sort-STNumerical)
}

#Load cache functions
Function Load-Stars($CacheRoot) {
    #construct object lists
    #Stars/Systems
    $JSONList = Get-ChildItem $CacheRoot -Recurse -Filter "StarSystemDef*.json"
    $StarObjectList = @()
    foreach ($JSONFile in $JSONList) {
        $JSONRaw = Get-Content $JSONFile.FullName -Raw
        $StarObject = $($JSONRaw | ConvertFrom-Json)
        $StarObject | Add-Member -NotePropertyName DynShops -NotePropertyValue $([pscustomobject]@{})
        $StarObject.DynShops | Add-Member -NotePropertyName Id -NotePropertyValue $(datachop "starsystemdef_" 1 $($StarObject.Description.Id))
        $StarObjectList += $StarObject
    }
    return $StarObjectList
}


#Feature functions
Function DynShops {
    param (
        [Parameter(Mandatory=$true, Position=0)][string]$CacheRoot,
        [Parameter(Mandatory=$true, Position=1)][pscustomobject]$StarObjectList
    )

    [void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

    #Faction Stuff
    $DynShopsMod = Get-Content $CacheRoot\\DynamicShops\\mod.json -Raw | ConvertFrom-Json
    $FactionLayout = $DynShopsMod.Settings.GenericFactions
    #FactionFriendlyDict
    $FactionFriendlyDict = @()
    foreach ($FactionFile in $(Get-ChildItem $CacheRoot -Recurse -Filter "faction_*.json").FullName) {
        $FactionJSON = Get-Content -Raw $FactionFile | ConvertFrom-Json
        $FactionFriendlyDict += [pscustomobject]@{
            id = $($FactionJSON.ID -split 'faction_')[1]
            name = $FactionJSON.Name
            shortname = $FactionJSON.ShortName
        }
    }
    #Convert All Possible Factions
    foreach ($FactionGroup in $FactionLayout) {
        $NewFactionGroupMembers = @()
        foreach ($FactionLayoutMember in $FactionGroup.Members) {
            $NewFactionGroupMembers += $($FactionFriendlyDict | ? {$_.shortname -match $FactionLayoutMember}).name
        }
        $NewFactionGroupMembers = $NewFactionGroupMembers | ? {$_}
        $FactionGroup.Members = $NewFactionGroupMembers
    }
    $DSAllFactions = $($FactionLayout.Members | group).Name | sort

    #Load SShops
    $SShopsDefList = Get-ChildItem "$CacheRoot\DynamicShops\sshops" -Recurse -Filter "*.json"
    $SShopsDef = @()
    $RepRef = $(RepLevels).ComboBox
    foreach ($SShopsDefFile in $SShopsDefList) {
        $SShopsDefJSON = Get-Content $SShopsDefFile.FullName -Raw | ConvertFrom-Json
        $SShopsDefJSON.conditions | % {$_ | Add-Member -NotePropertyName name -NotePropertyValue $SShopsDefFile.BaseName}
        foreach ($SShopsDefItem in $SShopsDefJSON) {
            if (-not !$($SShopsDefItem.conditions.rep)) {
                switch ([char]$($SShopsDefItem.conditions.rep[0])) {
                    {">", "+" -eq $_} {$SShopsDefItem.conditions.rep = $SShopsDefItem.conditions.rep.Substring(1); $SShopsDefItem.conditions | Add-Member -NotePropertyName repmod -NotePropertyValue "ge"; break}
                    {"<", "-" -eq $_} {$SShopsDefItem.conditions.rep = $SShopsDefItem.conditions.rep.Substring(1); $SShopsDefItem.conditions | Add-Member -NotePropertyName repmod -NotePropertyValue "le"; break}
                    default {$SShopsDefItem.conditions | Add-Member -NotePropertyName repmod -NotePropertyValue "eq"; break}
                }
                $SShopsDefItem.conditions | Add-Member -NotePropertyName repvalue -NotePropertyValue $($RepRef | ? {$_.display -eq $SShopsDefItem.conditions.rep}).value
            }
        }
        $SShopsDef += $SShopsDefJSON
    }
    
    #Load ItemCollections
    $ICFileList = Get-ChildItem "$CacheRoot\DynamicShops" -Recurse -Filter "*.csv"
    $ICDef = @()
    foreach ($ICFile in $ICFileList) {
        $ICDef += [pscustomobject]@{
            name = $ICFile.BaseName
            object = $(Get-Content $ICFile.FullName | select -Skip 1 | ConvertFrom-Csv -Header @("itemname","itemtype","quantity","weight"))
        }
    }
    foreach ($ICGroup in $ICDef) {
        $ICEmbeddedLists = $null
        do {
            $ICEmbeddedLists = $ICGroup.object | ? {-not (Compare-Object $ICDef.name $_.itemname | ? SideIndicator -eq '=>')}
            foreach ($ICEmbeddedList in $ICEmbeddedLists) {
                #store reference name
                $ResolveMe = $ICEmbeddedList.itemname
                #remove reference, add reference contents
                $ICGroup.object = [array]$($ICGroup.object | ? {$_.itemname -ne $ResolveMe}) + $($ICDef | ? {$_.name -eq $ResolveMe}).object
            }
        } while (-not !$ICEmbeddedLists)
        Write-Output ".`r`n"
    }
        
        


    $winDynShopsMain = New-Object System.Windows.Forms.Form
    $winDynShopsMain.ClientSize = '700,700'
    $winDynShopsMain.FormBorderStyle = "FixedToolWindow"
    $winDynShopsMain.Text = "Dynamic Shops"
    $winDynShopsMain.BackColor = "#222222"
    $winDynShopsMain.ForeColor = "#FFFFFF"

    #Start ShopsBySystem

    $labelShopsBySystem = New-Object System.Windows.Forms.Label
    $labelShopsBySystem.Text = "Shops by System"
    $labelShopsBySystem.Width = 250
    $labelShopsBySystem.AutoSize = $true
    $labelShopsBySystem.Font = New-Object System.Drawing.Font('Arial',16)
    $labelShopsBySystem.Location = New-Object System.Drawing.Point(10,10)
    $winDynShopsMain.Controls.Add($labelShopsBySystem)

    $labelDSSystemName = New-Object System.Windows.Forms.Label
    $labelDSSystemName.Text = "System: "
    $labelDSSystemName.Width = 50
    $labelDSSystemName.TextAlign = "MiddleRight"
    $labelDSSystemName.Location = New-Object System.Drawing.Point(10,40)
    $winDynShopsMain.Controls.Add($labelDSSystemName)

    $dropDSSystemName = New-Object System.Windows.Forms.ComboBox
    $dropDSSystemName.DropDownStyle = "DropDownList"
    $dropDSSystemName.Width = 250
    $dropDSSystemName.Location = New-Object System.Drawing.Point(60,40)
    $dropDSSystemName.Items.AddRange($($StarObjectList.Description.Name | Sort-STNumerical))
    $dropDSSystemName.SelectedIndex = 0
    $dropDSSystemName.Add_SelectedValueChanged({
        $txtTagResults.Text = & $strTagResults
    })
    $winDynShopsMain.Controls.Add($dropDSSystemName)

    $labelDSSystemOwner = New-Object System.Windows.Forms.Label
    $labelDSSystemOwner.Text = "Owner: "
    $labelDSSystemOwner.Width = 50
    $labelDSSystemOwner.TextAlign = "MiddleRight"
    $labelDSSystemOwner.Location = New-Object System.Drawing.Point(10,70)
    $winDynShopsMain.Controls.Add($labelDSSystemOwner)

    $dropDSSystemOwner = New-Object System.Windows.Forms.ComboBox
    $dropDSSystemOwner.DropDownStyle = "DropDownList"
    $dropDSSystemOwner.Width = 250
    $dropDSSystemOwner.Location = New-Object System.Drawing.Point(60,70)
    $dropDSSystemOwner.Items.AddRange($DSAllFactions)
    $dropDSSystemOwner.SelectedIndex = 0
    $dropDSSystemOwner.Add_SelectedValueChanged({
        $txtDSOwnerGroup.Text = $($FactionLayout | ? {$_.members -contains $dropDSSystemOwner.SelectedItem}).Name
        $txtTagResults.Text = Invoke-Command $strTagResults
    })
    $winDynShopsMain.Controls.Add($dropDSSystemOwner)
    
    $labelDSOwnerGroup = New-Object System.Windows.Forms.Label
    $labelDSOwnerGroup.Text = "Group: "
    $labelDSOwnerGroup.Width = 50
    $labelDSOwnerGroup.TextAlign = "MiddleRight"
    $labelDSOwnerGroup.Location = New-Object System.Drawing.Point(10,100)
    $winDynShopsMain.Controls.Add($labelDSOwnerGroup)

    $txtDSOwnerGroup = New-Object System.Windows.Forms.TextBox
    $txtDSOwnerGroup.ReadOnly = $true
    $txtDSOwnerGroup.Text = $($($FactionLayout | ? {$_.members -contains $dropDSSystemOwner.SelectedItem}).Name)
    $txtDSOwnerGroup.Width = 250
    $txtDSOwnerGroup.Location = New-Object System.Drawing.Point(60,100)
    $winDynShopsMain.Controls.Add($txtDSOwnerGroup)

    $labelDSOwnerRep = New-Object System.Windows.Forms.Label
    $labelDSOwnerRep.Text = "Rep: "
    $labelDSOwnerRep.Width = 50
    $labelDSOwnerRep.TextAlign = "MiddleRight"
    $labelDSOwnerRep.Location = New-Object System.Drawing.Point(10,130)
    $winDynShopsMain.Controls.Add($labelDSOwnerRep)

    $dropDSOwnerRep = New-Object System.Windows.Forms.ComboBox
    $dropDSOwnerRep.DropDownStyle = "DropDownList"
    $dropDSOwnerRep.Width = 250
    $dropDSOwnerRep.Location = New-Object System.Drawing.Point(60,130)
    $dropDSOwnerRep.Items.AddRange($(RepLevels).ComboBox)
    $dropDSOwnerRep.SelectedIndex = 0
    $dropDSOwnerRep.ValueMember = "value"
    $dropDSOwnerRep.DisplayMember = "display"
    $dropDSOwnerRep.Add_SelectedValueChanged({
        $txtTagResults.Text = & $strTagResults
    })        
    $winDynShopsMain.Controls.Add($dropDSOwnerRep)

    $labelDSOwnerRep = New-Object System.Windows.Forms.Label
    $labelDSOwnerRep.Text = "TagDbug"
    $labelDSOwnerRep.Width = 55
    $labelDSOwnerRep.TextAlign = "MiddleRight"
    $labelDSOwnerRep.Location = New-Object System.Drawing.Point(5,160)
    $winDynShopsMain.Controls.Add($labelDSOwnerRep)

    #script+stringBlock template for TagResults
    $strTagResults = {
        $script:DSSystemTags = $($($StarObjectList | ? {$_.Description.Name -eq $dropDSSystemName.SelectedItem}).Tags.items)
        $script:DSSystemOwner = $($($FactionFriendlyDict | ? {$_.name -match $dropDSSystemOwner.SelectedItem}).id)
        $script:DSSystemGroup = $($txtDSOwnerGroup.Text)
        $script:DSSystemRep = if ([int]$($dropDSOwnerRep.SelectedItem.value) -gt 6) {6} else {[int]$($dropDSOwnerRep.SelectedItem.value)}
    @"
System Tags:
$DSSystemTags

Faction:
$DSSystemOwner

Group:
$DSSystemGroup

Rep:
$DSSystemRep
"@
    }

    $txtTagResults = New-Object System.Windows.Forms.TextBox
    $txtTagResults.Multiline = $true
    $txtTagResults.ReadOnly = $true
    $txtTagResults.ScrollBars = "Both"
    $txtTagResults.Width = 250
    $txtTagResults.Height = 90
    $txtTagResults.Location = New-Object System.Drawing.Point(60,160)
    $txtTagResults.Text = & $strTagResults
    $txtTagResults.Add_TextChanged({
        $listDSResults.Items.Clear()
        $arrayItemCollection = [array]$(Get-DSResultsBySystem -SShopsDef $SShopsDef -DSSystemTags @($DSSystemTags) -DSSystemOwner $DSSystemOwner -DSSystemGroup $DSSystemGroup -DSSystemRep $DSSystemRep) 
        $rangeDSResults = $arrayItemCollection
        $listDSResults.Items.AddRange($rangeDSResults)
    })
    $winDynShopsMain.Controls.Add($txtTagResults)

    $labelDSResults = New-Object System.Windows.Forms.Label
    $labelDSResults.Text = "Results"
    $labelDSResults.Width = 55
    $labelDSResults.TextAlign = "MiddleRight"
    $labelDSResults.Location = New-Object System.Drawing.Point(5,260)
    $winDynShopsMain.Controls.Add($labelDSResults)

    $listDSResults = New-Object System.Windows.Forms.ListBox
    $listDSResults.SelectionMode = "One"
    $listDSResults.ScrollAlwaysVisible = $true
    $listDSResults.HorizontalScrollbar = $true
    $listDSResults.Width = 250
    $listDSResults.Height = 400
    $listDSResults.Location = New-Object System.Drawing.Point(60,260)
    $winDynShopsMain.Controls.Add($listDSResults)

    $btnDSViewOnWiki = New-Object System.Windows.Forms.Button
    $btnDSViewOnWiki.Text = "View on`nWiki"
    $btnDSViewOnWiki.Width = 55
    $btnDSViewOnWiki.Height = 55
    $btnDSViewOnWiki.Location = New-Object System.Drawing.Point(5,600)
    $btnDSViewOnWiki.Add_Click({
        Start-Process $("https://roguetech.fandom.com/wiki/" + $listDSResults.SelectedItem)
    })
    $winDynShopsMain.Controls.Add($btnDSViewOnWiki)

    #End ShopsBySystem

    $divDSMain = New-Object System.Windows.Forms.Label
    $divDSMain.Text = ""
    $divDSMain.AutoSize = $false
    $divDSMain.BorderStyle = "Fixed3D"
    $divDSMain.Width = 2
    $divDSMain.Height = 700
    $divDSMain.Location = New-Object System.Drawing.Point(350,0)
    $winDynShopsMain.Controls.Add($divDSMain)

    #Start ShopsByItem

    $winDynShopsMain.ShowDialog()
}


#Set Defaults/Constants
###
$CacheDir = "D:\RogueTech\RtlCache\RtCache" #Cache Dir
$CacheTotal = "?"

<#

#Init IDLinkHash
$IDLinkHash = @{}

#Load Gear
$GearFile = $RTScriptroot+"\\Outputs\\GearTable.json"
$GearObjectList = Get-Content -Raw $GearFile | ConvertFrom-Json
$GearObjectList | ? {$_.Description.UIName -ne ''} | foreach { $IDLinkHash[$($_.Description.ID)] = "Gear/$($_.Description.UIName)" }


#>

#Init WinForms
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

#Init Main
$RefToolMain = New-Object System.Windows.Forms.Form
$RefToolMain.ClientSize = '500,500'
$RefToolMain.FormBorderStyle = "FixedToolWindow"
$RefToolMain.Text = "RT Reference Tool"
$RefToolMain.BackColor = "#111111"
$RefToolMain.ForeColor = "#FFFFFF"

#Find Cache
$btnCacheDir = New-Object System.Windows.Forms.Button
$btnCacheDir.Text = "RT Cache DIR"
$btnCacheDir.Location = New-Object System.Drawing.Point(10,10)
$btnCacheDir.AutoSize = $true
$btnCacheDir.Add_Click({
    $txtCacheDir.Text = Get-Folder $txtCacheDir.Text
    $btnCacheValid.Text = $(Get-RTValid($txtCacheDir.Text))
    if ($btnCacheValid.Text -eq "Invalid Cache DIR") {
        $btnCacheValid.Enabled = $false
    } else {
        $btnCacheValid.Enabled = $true
    }
})
$RefToolMain.Controls.Add($btnCacheDir)

$txtCacheDir = New-Object System.Windows.Forms.TextBox
$txtCacheDir.Width = 250
$txtCacheDir.Height = 30
$txtCacheDir.Location = New-Object System.Drawing.Point(100,10)
$txtCacheDir.Text = $CacheDir
$txtCacheDir.Enabled = $false
$RefToolMain.Controls.Add($txtCacheDir)

$btnCacheValid = New-Object System.Windows.Forms.Button
$btnCacheValid.Text = Get-RTValid($txtCacheDir.Text)
$btnCacheValid.Location = New-Object System.Drawing.Point(350,10)
$btnCacheValid.AutoSize = $true
$btnCacheValid.Add_Click({
    if ($btnCacheValid.Text -eq "Lock In Cache") {
        $btnCacheDir.Enabled = $false
        $btnCacheValid.Enabled = $false
        $btnCacheValid.Text = "Cache Locked In"
        $CacheDir = $txtCacheDir.Text
        #enable all remaining functions
        $labelStatus.Text = "Loading caches - this may take a while... Systems (1/$CacheTotal)"
        Start-Sleep -Milliseconds 100
        $script:StarObjectList = Load-Stars($CacheDir)
        $labelStatus.Text = "Cache Loaded"
        $btnStartDynShops.Enabled = $true
    }
})
$RefToolMain.Controls.Add($btnCacheValid)

#Status Label
$labelStatus = New-Object System.Windows.Forms.Label
$labelStatus.AutoSize = $true
$labelStatus.Text = "Waiting for cache lock"
$labelStatus.Location = New-Object System.Drawing.Point(10,40)
$RefToolMain.Controls.Add($labelStatus)

#Buttons
$btnStartDynShops = New-Object System.Windows.Forms.Button
$btnStartDynShops.Text = "Dynamic Shops"
$btnStartDynShops.Width = 150
$btnStartDynShops.TextAlign = "MiddleCenter"
$btnStartDynShops.Enabled = $false
$btnStartDynShops.Location = New-Object System.Drawing.Point(10,70)
$btnStartDynShops.Add_Click({
    DynShops -CacheRoot $CacheDir -StarObjectList $StarObjectList
})
$RefToolMain.Controls.Add($btnStartDynShops)





[void]$RefToolMain.ShowDialog()


