Write-Host @"





































"@

#This parses ChassDef and MechDef for info
#
#

#SET FUNCTIONS
###
#data chopper function
    #args: delimiter, position, input
function datachop {
    $array = @($args[2] -split "$($args[0])")    
    return $array[$args[1]]
}

#SETTINGS
###
#HPValueMod is for the dynamic math to change actual combat values.
$ArmorValueMod = 1
$StructureValueMod = 1


#SET CONSTANTS
###
#RogueTech Dir (Where RTLauncher exists)
$RTroot = "D:\\RogueTech"
#Script Root
$RTScriptroot = "D:\\RogueTech\\WikiGenerators"
cd $RTScriptroot
#cache path
$CacheRoot = "$RTroot\\RtlCache\\RtCache"
#stringarray - factions - sort by display alpha
    #fuck this. build it from \RogueTech Core\Faction.json
$FactionFile = "$CacheRoot\\RogueTech Core\\Faction.json"

#save file
$MechsFile = "$RTScriptroot\\Outputs\\TankListTable.json"
#build faction groups. data incomplete (no periphery tags exist, factions can be containered in multiple groups), create from human readable CSV.
$GroupingFile = "$RTScriptroot\\Inputs\\FactionGrouping.csv"
#Tag input
$SpecialFile = "$RTScriptroot\\Inputs\\VehicleSpecial.csv"
#weight file
$ClassFile = "$RTScriptroot\\Inputs\\Class.csv"
#string - conflictfile
$conflictfile = "$RTScriptroot\\Outputs\\vehicleconflict.csv"
#stringarray - CDef special
#$CDefSpecial = @("OmniMech","Primitive","EliteMech","PrototypeMech","ProtoMech","SLDFMech","HeroMech","ClanMech","SocietyMech")
#stringarray - MDef Special
#$MDefSpecial = @($null,"unit_primitive","unit_elite","unit_prototype","unit_protomech","unit_sldf","unit_hero",$null,$null)
#Define CDef and MDef in $SpecialFile
$SpecialFileObject = Import-Csv $SpecialFile
#Tag Titles
$SpecialTitle = $SpecialFileObject.TagTitle
#CDef (FILL WITH $null IF NOTHING COMPARABLE)
$SpecialCDef = $SpecialFileObject.CDEF
#MDef (FILL WITH $null IF NOTHING COMPARABLE)
$SpecialMDef = $SpecialFileObject.MDEF
#Define Weights in $ClassFile
$ClassFileObject = Import-Csv $ClassFile
#Tag Titles
$ClassTitle = $ClassFileObject.TagTitle
#CDef (FILL WITH $null IF NOTHING COMPARABLE)
$ClassCDef = $ClassFileObject.CDEF
#MDef (FILL WITH $null IF NOTHING COMPARABLE)
$ClassMDef = $ClassFileObject.MDEF

#SET OPTIONS
###
#string - isolate for Mechs/Vehicles/???
$CDefFileType = "json"
$MDefFileType = "json"
$CDefMask = "vehiclechassisdef"
$MDefMask = "vehicledef"
#Exclusion list. Split up to assist with readability and reporting.
    #Not required to surround Exclusion text with *. loop will handle. 
$MDefExclusionManual = @($(Import-Csv "$RTScriptroot\\Inputs\\ExcludeManual.csv").Manual)
$MDefExclusionIgnore = @($(Import-Csv "$RTScriptroot\\Inputs\\ExcludeIgnore.csv").Ignore)
$MDefExclusion = $($MDefExclusionManual + $MDefExclusionIgnore) | where {$_}
for ($h = 0; $h -lt $($MDefExclusion.Count); $h++) {
    $MDefExclusion[$h] = "*$($MDefExclusion[$h])*"
}
    
#IMPORT OBJECT TABLES
###
#faction table
    #Keys: ID; Name; FriendlyName; Description; FactionDefID; IsRealFaction; IsGreatHouse; IsClan; IsMercenary; IsPirate; DoesGainReputation; CanAlly; IsProceduralContractFaction; IsCareerScoringFaction; IsCareerIgnoredContractTarget; IsCareerStartingDisplayFaction; IsStoryStartingDisplayFaction; HasAIBehaviorVariableScope
$FactionObject = $($(Get-Content $FactionFile | ConvertFrom-Json).enumerationValueList)
#grouping table
    #Keys: BLACKLIST; CLAN; INNERSPHERE; MERC; PERIPHERY; PIRATE
$GroupingCSVObject = Import-Csv -Path "$GroupingFile" 
#holy shit this can't import properly
$GroupKeyList = $($GroupingCSVObject | Get-Member -MemberType Properties).Name
$GroupObject = [pscustomobject]@{}
foreach ($BuildGroup in $GroupKeyList) {
    Add-Member -InputObject $GroupObject -MemberType NoteProperty -Name $BuildGroup -Value @()
    $GroupObject.$BuildGroup = $(Import-Csv -Path $GroupingFile | select -ExpandProperty $BuildGroup)
    $GroupObject.$BuildGroup = $($GroupObject.$BuildGroup | Where-Object {$_})
}
#building a list of files (ChassisDef) to work with. Isolate for: $ChassisDefMask (see SET OPTIONS)    
$MDefFileObjectList = @(Get-ChildItem $CacheRoot -Recurse -Filter "$MDefMask*.$MDefFileType" -Exclude $MDefExclusion)

#build a table of mechs, exportable
    #Name, QName (unique name), Signature (Variant), SubVar (SubVarian), Factions, Weight, Class, Hardpoints, Special
#search each file for info. write to holder array var
$Mechs = @()

#Localization File for parsing names >=(
Write-Progress -Activity "Scanning Text Objects"
$TextFileName = "Localization.json"
$TextFileList = $(Get-ChildItem $CacheRoot -Recurse -Filter $TextFileName)
$TextObject = $null
foreach ($TextFile in $TextFileList) {
    $TextObject += $TextFile | Get-Content -raw | ConvertFrom-Json
}

#create conflict file
#ascii required for excel cuz M$
@"
Comparing
CDEF=,$($SpecialCDef -join ",")
MDEF=,$($SpecialMDef -join ",")
===================,headerlines,4
|CONFLICT| ,CDef // MDef, || ,Missing Tag, |Missing in| ,file
"@ | Out-File -FilePath $conflictfile -Encoding ascii

Write-Host @"












"@

$i = 0
foreach ($MDefFileObject in $MDefFileObjectList) { 
    $i++
    write-progress -activity "Scanning files" -Status "$i of $($MDefFileObjectList.Count)"
    #init and null critical vars
    $MechCName = $null
    $MechQName = $null
    #$MechVarActual = $null
    #$MechVar = $null
    $Class = $null
    $Special = $null


    #setup CDef and MDef objects
    $filePathMDef = $MDefFileObject.VersionInfo.FileName
    $fileNameMDef = $MDefFileObject.Name
    $FileObjectModRoot = "$($MDefFileObject.DirectoryName)\\.."
    try {$MDefObject = ConvertFrom-Json $(Get-Content $filePathMDef -raw)} catch {"TankParser|Parsing vehicledef: " + $filePathMDef | Out-File $RTScriptroot\ErrorLog.txt -Append -Encoding utf8}
    $fileNameCDef = "$($MDefObject.ChassisID).$($CDefFileType)"
    $CDefFileObject = Get-ChildItem $FileObjectModRoot -Recurse -Filter "$fileNameCDef"
    #if not found in modroot, try everything
    if (!$CDefFileObject) {
        $CDefFileObject = Get-ChildItem $CacheRoot -Recurse -Filter "$fileNameCDef"
    }
    #error with CDef definition if still nothing
    if (-not !$CDefFileObject) {
        $filePathCDef = $CDefFileObject.VersionInfo.FileName
        try {$CDefObject = $(Get-Content $filePathCDef -raw | ConvertFrom-Json)} catch {"TankParser|Parsing vehiclechassisdef: " + $filePathCDef | Out-File $RTScriptroot\ErrorLog.txt -Append -Encoding utf8}
    
        #init mech object for storage
        $Mech = $([PSCustomObject] @{
            MechDefFile = $(datachop $CacheRoot 1 $filePathMDef)
            ChassisDefFile = $(datachop $CacheRoot 1 $filePathCDef)
        })

        #0 ID - the ID used by mod - << chassis_variant_customname >>
        $MechID = $(datachop ".$CDefFileType" 0 $(datachop "$($CDefMask)_" 1 "$fileNameCDef"))
        $Mech | Add-Member -MemberType NoteProperty -Name "ID" -Value $mechID

        # VTOL work
        $Mech | Add-Member -MemberType NoteProperty -Name "VTOL" -Value $false
        if ($MDefObject.VehicleTags.items.Contains("unit_vtol")) {
            $Mech.VTOL = $true
        }

        #7 Tags - !pull info from both! - ChassisDef XNOR MechDef
        ### REF ONLY: $CDef = $CDefSpecial = @("OmniMech","Primitive","EliteMech","PrototypeMech","ProtoMech","SLDFMech","HeroMech","ClanMech","SocietyMech")
        #Do tag work
        $j = 0
        $Mech | Add-Member -MemberType NoteProperty -Name "Special" -Value @()
        foreach ($Special in $SpecialTitle) {
            $CTag = $SpecialCDef[$j]
            $MTag = $SpecialMDef[$j]
            if (($CDefObject.ChassisTags.items -contains $CTag) -or ($MDefObject.VehicleTags.items -contains $MTag)) {
                $Mech.Special += $Special
            }
        
            #do audit below here.
            if ($MTag -and $CTag) {
                #parses whole file as a single string.
                if (($(Get-Content $filePathCDef -Raw) -like "*$CTag*") -like $false) {
                    "CONFLICT ,$CTag // $MTag, || ,$CTag, Missing in ,$(datachop $CacheRoot 1 $filePathCDef)" >> $conflictfile
                } elseif (($(Get-Content $filePathMDef -Raw) -like "*$MTag*") -like $false) {
                    "CONFLICT ,$CTag // $MTag, || ,$MTag, Missing in ,$(datachop $CacheRoot 1 $filePathMDef)" >> $conflictfile
                }
            }
            #do audit above here. 
            $j++
        }

        #4 Weight - / - << "Tonnage": >>
        $Mech | Add-Member -MemberType NoteProperty -Name "Tonnage" -Value $CDefObject.Tonnage

        #5 Weight Class
        #Do tag work
        $l = 0
        $Mech | Add-Member -MemberType NoteProperty -Name "Class" -Value ""
        if (-not $Mech.VTOL) {
            foreach ($Class in $ClassTitle) {
                $CTag = $ClassCDef[$l]
                $MTag = $ClassMDef[$l]
                if ($CDefObject.weightClass -contains $CTag) {
                    $Mech.Class = $($Class.ToUpper())
                }
                $l++
            }
            #SuperHeavy override
            if (($Mech.Tonnage -gt 100) -or ($MDefObject.VehicleTags.items -contains "unit_superheavytank")) {
                $Mech.Class = "SHTANK"
        }
        #VTOL weight defs override
        } else { 
            switch ($Mech.Tonnage) {
                {$_ -gt 45} {$Mech.Class = "ASSAULT"}
                {$_ -le 45 -and $_ -gt 30} {$Mech.Class = "HEAVY"}
                {$_ -le 30 -and $_ -gt 15} {$Mech.Class = "MEDIUM"}
                {$_ -le 15} {$Mech.Class = "LIGHT"}
            }
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
        
        #3 Factions - !pull info from mechdef! - /vehicletags/items - each faction has own tag
        $Mech | Add-Member -MemberType NoteProperty -Name "Factions" -Value @()
        $m = 0
        foreach ($Faction in $FactionObject) {
            $FactionName = $Faction.Name
            if ($MDefObject.VehicleTags.items -contains $FactionName) {
                $Mech.Factions += $FactionName
            }
            $m++
        }
            #3.1 remember to isolate for "CLASSIFIED".
                    #same location, tag is: << "BLACKLISTED" >>
                    #if found flag BLACKLISTED as TRUE
        $Mech | Add-Member -MemberType NoteProperty -Name "BLACKLIST" -Value $false
        #Force BLACKLISTED if WIKIBL
        if ($MDefObject.MechTags.items -contains 'WikiBL') {
            $MDefObject.MechTags.items += "BLACKLISTED"
        }
        if (($MDefObject.VehicleTags.items -contains $GroupObject.BLACKLIST) -or ($MDefObject.RequiredToSpawnCompanyTags.items.Count -gt 0)) {
                $Mech.BLACKLIST = $true
        }
            #need some kind of wombocombo script to "group" for WIKIGROUPS clans/IS/mercs/periphery/etc...
        foreach ($GroupName in $GroupKeyList) { 
            #ignore blacklist group, I just put it in grouping list for less files to pull from
            if ($GroupName -notlike "BLACKLIST") {
                $Mech | Add-Member -MemberType NoteProperty -Name $GroupName -Value $false
                $GroupMembers = $GroupObject.$GroupName
                if (-not $GroupMembers.where{$_ -notin $Mech.Factions}) {
                    $Mech.$GroupName = $true
                }
            }
        }

        #6 Hardpoints - /locations - << "WeaponMount": >>
        $Mech | Add-Member -MemberType NoteProperty -Name "WeaponMounts" -Value ([pscustomobject]@{})
        $OmniSlot = 0
        $EnergySlot  = 0
        $BallisticSlot = 0
        $MissileSlot = 0
        $AntiPersonnelSlot = 0
        $BattleArmorSlot = 0
        foreach ($Location in $CDefObject.Locations) {
            foreach ($Hardpoint in $Location.Hardpoints) {
                #Omni - if Omni true, add to omni count instead
                if ($Hardpoint.Omni) {
                    $OmniSlot++
                #don't count WeaponMountID (mod slots)
                } elseif ((-not !$Hardpoint.WeaponMount) -and (-not $Hardpoint.Omni)) {
                    #exclude NotSet
                    if ($Hardpoint.WeaponMount -ne "NotSet") {
                        $(Get-Variable "$($Hardpoint.WeaponMount)Slot").Value++
                    }
                #except for the BA slots urrrggg
                } elseif (($Hardpoint.WeaponMountID -like "BattleArmor") -and (-not $Hardpoint.Omni)) {
                    $BattleArmorSlot++
                }
            }
        }
        #need something to grab JJs
        $Mech.WeaponMounts = $([pscustomobject]@{
            OmniSlot = $OmniSlot
            EnergySlot = $EnergySlot
            BallisticSlot = $BallisticSlot
            MissileSlot = $MissileSlot
            SupportSlot = $AntiPersonnelSlot
            BASlot = $BattleArmorSlot
            JJSlot = $CDefObject.MaxJumpjets
        })
        #8 Grab loadout: weapons, ECM, etc.
        $FixedLoadout = $CDefObject.FixedEquipment | select -ExpandProperty ComponentDefID | sort | group | select -ExcludeProperty ("Group","Values")
        $DynamicLoadout = $MDefObject.Inventory | select -ExpandProperty ComponentDefID | sort | group | select -ExcludeProperty ("Group","Values")
        $Mech | Add-Member -MemberType NoteProperty -Name "Loadout" -Value ([pscustomobject]@{})
        $Mech.Loadout = $([pscustomobject]@{
            Dynamic = $DynamicLoadout
            Fixed = $FixedLoadout
        })
        # grab icon name
        $Mech | Add-Member -MemberType NoteProperty -Name "Icon" -Value $($CDefObject.Description.Icon)
        # grab Mod Name
        $ModName = $($(datachop $CacheRoot 1 $MDefFileObject.DirectoryName) -split "\\")[1]
        $Mech | Add-Member -MemberType NoteProperty -Name "Mod" -Value $ModName
        # grab HP amounts
        $Mech | Add-Member -MemberType NoteProperty -Name "HP" -Value ([pscustomobject]@{})
        # Structure
        $HPTypeList = @{'Structure'='InternalStructure';'SetArmor'='AssignedArmor';'MaxArmor'='MaxArmor'}
        $HPLocationList = @('Front','Left','Right','Rear','Turret')
        foreach ($HPType in $HPTypeList.GetEnumerator().Name) {
            $Mech.HP | Add-Member -MemberType NoteProperty -Name $HPType -Value ([pscustomobject]@{})
            $HPDefObject = $CDefObject
            #HPValueMod is for the dynamic math to change actual combat values.
            $HPValueMod = $ArmorValueMod
            if ($HPType -like 'SetArmor') {
                $HPDefObject = $MDefObject
            }
            if ($HPType -like 'Structure') {
                $HPValueMod = $StructureValueMod
            }
            foreach ($HPLocation in $HPLocationList) {
                $Mech.HP.$HPType | Add-Member -MemberType NoteProperty -Name $HPLocation -Value $($($HPDefObject.Locations | where -Property Location -Like $HPLocation).$($HPTypeList.$HPType) * $HPValueMod)
            }
        }
        #Grab and trim Mech Blurb
        $MechBlurb = $MDefObject.Description.Details
        #Regex cleanup
        $MechBlurb = $($($MechBlurb.Split("`n")) -Replace ('^[ \t]*','')) -Join ("`n") #split by lines, trim leading spaces/tabs, rejoin
        $MechBlurb = $MechBlurb -Replace ('<color=(.*?)>(.*?)<\/color>','<span style="color:$1;">$2</span>') #replace color tag
        $MechBlurb = $MechBlurb -Replace ('<b>(.*?)<\/b>','$1') #remove bold
        $Mech | Add-Member -MemberType NoteProperty -Name "Blurb" -Value $MechBlurb
        ###START OVERRIDES SECTION
        
        ###END OVERRIDES SECTION

        #Prep VariantGlue
        $VariantLink = $($Mech.Name.Full)
        $VariantGlue = $($VariantLink+" "+$($Mech.Name.SubVar)).Trim()
        if (-not !$Mech.Name.Hero) {
            $VariantGlue += " ($($Mech.Name.Hero))"
        }
        if (-not !$mech.Name.Unique) {
            $VariantGlue += " aka $($Mech.Name.Unique)"
        }
        #variantglue unresolvable conflicts override
        if ([bool]($BlacklistOverride | ? {$filePathMDef -match $_})) {
            $VariantGlue += " $($Mech.Mod)"
        } elseif ($Mech.Name.Full -eq 'CGR-C') {
            $VariantGlue += " -$($Mech.Name.Chassis)-"
        } elseif ($Mech.Name.Full -eq 'MAD-BH') {
            $VariantGlue += " -$($Mech.Name.Chassis)-"
        } elseif ($Mech.Name.Full -eq 'MAD-4S') {
            $VariantGlue += " -$($Mech.Name.Chassis)-"
        } elseif ($Mech.Name.Full -eq 'BZK-P') {
            $VariantGlue += " -$($Mech.Name.Chassis)-"
        } elseif ($Mech.Name.Full -eq 'BZK-RX') {
            $VariantGlue += " -$($Mech.Name.Chassis)-"
        } elseif ($Mech.Name.Full -eq 'OSR-4C') {
            $VariantGlue += " -$($Mech.Name.Chassis)-"
        } elseif ($Mech.Name.Full -eq 'HND-1') {
            $VariantGlue += " -$($Mech.Name.Chassis)-"
        } elseif ($Mech.Name.Full -eq 'HND-3') {
            $VariantGlue += " -$($Mech.Name.Chassis)-"
        }
        
        #DupeCleaner
        #check if duped, add to holder array and rename original
        if (@($Mechs | ? {$_.Name.LinkName -eq $VariantGlue}).Count -eq 1) {
            $DupeLinkHolderArray += $VariantGlue
            $DupeLinkHolder = $($Mechs | ? {$_.Name.LinkName -eq $VariantGlue})
            if ($DupeLinkHolder.Mod -ne 'Base 3061') {
                $DupeLinkHolder.Name.LinkName = $DupeLinkHolder.Name.LinkName + " " + $DupeLinkHolder.Mod
            }
        }
        #if current is in holderarray, add mech's mod to link before creating.
        if ($DupeLinkHolderArray -contains $VariantGlue) {
            if ($Mech.Mod -ne 'Base 3061') {
                $VariantGlue += " $($Mech.Mod)"
            }
        }
        $Mech.Name | Add-Member -NotePropertyName 'LinkName' -NotePropertyValue $VariantGlue

        #add mechobject to $mechs
        $Mechs += $Mech
    } else {
        Write-Error -Message "Error with ChassisID in $filePathMDef"
        pause
    }
}
#load overrides
#CleanupDupes

#DirtyDupes
$DupeLinkName = $Mechs | group {$_.Name.LinkName} | ? {$_.Count -ge 2}
if ($DupeLinkName.Count -gt 0) {
    Write-Host "Dupe LinkNames found"
    $DupeLinkName
    pause
}
#save to file
$Mechs | ConvertTo-Json -Depth 10 | Out-File $MechsFile -Force