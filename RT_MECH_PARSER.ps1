Write-Host @"





































"@

#This parses ChassDef and MechDef for info
#
#

#SET FUNCTIONS
###
#makearray function
    #args: delimeter, input
function makearray {
    $array = @($args[1] -split "$($args[0])")
    return $array
}

#data chopper function
    #args: delimiter, position, input
function datachop {
    $array = @($args[2] -split "$($args[0])")    
    return $array[$args[1]]
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
#stringarray - factions - sort by display alpha
    #fuck this. build it from \RogueTech Core\Faction.json
$FactionFile = "$CacheRoot\\RogueTech Core\\Faction.json"

#PrefabIDFile
$PrefabIDFile = "$RTScriptroot\\Outputs\\PrefabID.json"
#save file
$MechsFile = "$RTScriptroot\\Outputs\\MechListTable.json"
#build faction groups. data incomplete (no periphery tags exist, factions can be containered in multiple groups), create from human readable CSV.
$GroupingFile = "$RTScriptroot\\Inputs\\FactionGrouping.csv"
#Tag input
$SpecialFile = "$RTScriptroot\\Inputs\\Special.csv"
#weight file
$ClassFile = "$RTScriptroot\\Inputs\\Class.csv"
#string - conflictfile
$conflictfile = "$RTScriptroot\\Outputs\\conflict.csv"
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
$CDefMask = "chassisdef"
$MDefMask = "mechdef"
#Exclusion list. Split up to assist with readability and reporting.
    #Not required to surround Exclusion text with *. loop will handle. 
$MDefExclusionManual = @($(Import-Csv "$RTScriptroot\\Inputs\\ExcludeManual.csv").Manual)
$MDefExclusionIgnore = @($(Import-Csv "$RTScriptroot\\Inputs\\ExcludeIgnore.csv").Ignore)
$BlacklistOverride = @($(Import-Csv "$RTScriptroot\\Inputs\\Blacklist.csv").Blacklist)
$MDefExclusion = $($MDefExclusionManual + $MDefExclusionIgnore) | where {$_}
for ($h = 0; $h -lt $($MDefExclusion.Count); $h++) {
    $MDefExclusion[$h] = "*$($MDefExclusion[$h])*"
}
    
#Affinities
$AffinitiesFile = "$CacheRoot\\MechAffinity\\settings.json"
$EquipAffinitiesMaster = $(Get-Content $AffinitiesFile -Raw | ConvertFrom-Json).quirkAffinities
$EquipAffinitiesIDNameHash = @{}
foreach ($EquipAffinity in $EquipAffinitiesMaster) {
    foreach ($AffinityItem in $EquipAffinity.quirkNames) {
        $EquipAffinitiesIDNameHash.Add($AffinityItem,$EquipAffinity.affinityLevels.levelName)
    }
}
$FixedAffinityObject = [pscustomobject]@{}
$FixedAffinityFile = "$RTScriptroot\\Outputs\\FixedAffinity.json"

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

#Build an objecthash of PrefabID
$PrefabID = [pscustomobject]@{}

#Build object for gearusedby
$GearUsedBy = [pscustomobject]@{}
$GearUsedByFile = "$RTScriptroot\\Outputs\\GearUsedBy.json"

#DupeLinkHolderArray
$DupeLinkHolderArray = @()

#create conflict file
#ascii required for excel cuz M$
@"
Comparing
CDEF=,$($SpecialCDef -join ",")
MDEF=,$($SpecialMDef -join ",")
===================,headerlines,4
|CONFLICT| ,CDef // MDef, || ,Missing Tag, |Missing in| ,file
"@ | Out-File -FilePath $conflictfile -Encoding ascii

$i = 0
#Testing Filter
#$MDefFileObjectList = $MDefFileObjectList | ? {$_.Name -match 'DIRGE'}
foreach ($MDefFileObject in $MDefFileObjectList) { 
    $i++
    write-progress -activity "Scanning files" -Status "$i of $($MDefFileObjectList.Count)"
    #init and null critical vars
    $MechCName = $null
    $MechQName = $null
    $MechVarActual = $null
    $MechVar = $null
    $MechPostVar = $null
    $MechSubVar = $null
    $MechHeroName = $null
    $Class = $null
    $Special = $null


    #setup CDef and MDef objects
    $filePathMDef = $MDefFileObject.VersionInfo.FileName
    $fileNameMDef = $MDefFileObject.Name
    $FileObjectModRoot = "$($MDefFileObject.DirectoryName)\\.."
    try {$MDefObject = ConvertFrom-Json $(Get-Content $filePathMDef -raw)} catch {"MechParser|Parsing mechdef: " + $filePathMDef | Out-File $RTScriptroot\ErrorLog.txt -Append -Encoding utf8}
    $fileNameCDef = "$($MDefObject.ChassisID).$($CDefFileType)"
    $CDefFileObject = Get-ChildItem $FileObjectModRoot -Recurse -Filter "$fileNameCDef"
    #if not found in modroot, try everything
    if (!$CDefFileObject) {
        $CDefFileObject = Get-ChildItem $CacheRoot -Recurse -Filter "$fileNameCDef"
    }
    #error with CDef definition if still nothing
    if (-not !$CDefFileObject) {
        $filePathCDef = $CDefFileObject.VersionInfo.FileName
        try {$CDefObject = $($(Get-Content $filePathCDef -raw).Replace("`"WeaponMount`"", "`"WeaponMountID`"") | ConvertFrom-Json)} catch {"MechParser|Parsing chassisdef: " + $filePathCDef | Out-File $RTScriptroot\ErrorLog.txt -Append -Encoding utf8} #make weaponmount consistent
    
        #init mech object for storage
        $Mech = $([PSCustomObject] @{
            MechDefFile = $(datachop $CacheRoot 1 $filePathMDef)
            ChassisDefFile = $(datachop $CacheRoot 1 $filePathCDef)
        })

        #0 ID - the ID used by mod - << chassis_variant_customname >>
        $MechID = $(datachop ".$CDefFileType" 0 $(datachop "$($CDefMask)_" 1 "$fileNameCDef"))
        $Mech | Add-Member -MemberType NoteProperty -Name "ID" -Value $mechID

        #7 Tags - !pull info from both! - ChassisDef XNOR MechDef
        ### REF ONLY: $CDef = $CDefSpecial = @("OmniMech","Primitive","EliteMech","PrototypeMech","ProtoMech","SLDFMech","HeroMech","ClanMech","SocietyMech")
        #Do tag work
        $j = 0
        $Mech | Add-Member -MemberType NoteProperty -Name "Special" -Value @()
        foreach ($Special in $SpecialTitle) {
            $CTag = $SpecialCDef[$j]
            $MTag = $SpecialMDef[$j]
            if (($CDefObject.ChassisTags.items -contains $CTag) -or ($MDefObject.MechTags.items -contains $MTag)) {
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

        # grab Mod Name
        $ModName = $($(datachop $CacheRoot 1 $MDefFileObject.DirectoryName) -split "\\")[1]
        $Mech | Add-Member -MemberType NoteProperty -Name "Mod" -Value $ModName

        #4 Weight - / - << "Tonnage": >>
        $Mech | Add-Member -MemberType NoteProperty -Name "Tonnage" -Value $CDefObject.Tonnage

        #5 Weight Class
        #Do tag work
        $l = 0
        $Mech | Add-Member -MemberType NoteProperty -Name "Class" -Value ""
        foreach ($Class in $ClassTitle) {
            $CTag = $ClassCDef[$l]
            $MTag = $ClassMDef[$l]
            if (($CDefObject.weightClass -contains $CTag) -or ($MDefObject.MechTags.items -contains $MTag)) {
                #need condition for PA to override all
                if ($Mech.Class -notcontains "POWER") {
                    $Mech.Class = $($Class.ToUpper())
                }
            }
            
            $l++
        }
        #if class is power, remove protomech tag 
        if ($Mech.Class -contains "POWER") {
            $Mech.Special = $Mech.Special -replace ("PROTO","") | where {$_}
        }

        #2 Signature - / - << "VariantName": >> - $MechVarActual
            #also handles Hero Names
        $Mech | Add-Member -MemberType NoteProperty -Name "Name" -Value ([pscustomobject]@{})
        $MechVarActual = $CDefObject.VariantName
        ###Variant override
        #custom override for ZEUX0003
        if ($MechVarActual -eq "ZEUX0003") {
            $MechVarActual = "ZEU-9WD"
        }
        $Mech.Name | Add-Member -MemberType NoteProperty -Name "Variant" -Value "$($MechVarActual.ToUpper())"
        $MechVar = $MechVarActual
        for ($k = 0 ; $k -lt $($MechVarActual.Length) ; $k++) {
            if ($MechID -notlike "*$MechVar*") {
                $MechVar = $MechVar.Substring(0,$($MechVar.Length) - 1)
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
        $MechCName = $CDefObject.Description.UIName
        $Mech.Name | Add-Member -MemberType NoteProperty -Name "MechUIName" -Value "$($MDefObject.Description.UIName)"
        $Mech.Name | Add-Member -MemberType NoteProperty -Name "Chassis" -Value "$($MechCName.ToUpper())"
        #1.1 Unique Name
        if ($($MDefObject.Description.UIName) -notlike "*$MechCName*") {
            $MechQName = datachop " $MechVar" 0 "$($MDefObject.Description.UIName)"
        } else {
            $MechQName = ""
        }
        $Mech.Name | Add-Member -MemberType NoteProperty -Name "Unique" -Value "$($MechQName.ToUpper())"

        #3 Factions - !pull info from mechdef! - /mechtags/items - each faction has own tag
        $Mech | Add-Member -MemberType NoteProperty -Name "Factions" -Value @()
        $m = 0
        foreach ($Faction in $FactionObject) {
            $FactionName = $Faction.Name
            if ($MDefObject.MechTags.items -contains $FactionName) {
                $Mech.Factions += $FactionName
            }
            $m++
        }
            #3.1 remember to isolate for "CLASSIFIED".
                    #same location, tag is: << "BLACKLISTED" >>
                    #if found flag BLACKLISTED as TRUE
        $Mech | Add-Member -MemberType NoteProperty -Name "BLACKLIST" -Value $false
        if (($MDefObject.MechTags.items -contains $GroupObject.BLACKLIST) -or ($MDefObject.RequiredToSpawnCompanyTags.items.Count -gt 0)) {
            $Mech.BLACKLIST = $true
        }   

        #Blacklist Override. Flashpoint/FP mechs generally.
        if ([bool]($BlacklistOverride | ? {$filePathMDef -match $_})) {
            $Mech.BLACKLIST = $true
            #exclusion for Base Flashpoint
            if ($Mech.Mod -match 'Base FlashPoint') {
                $Mech.BLACKLIST = $false
            }
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
        $Mech | Add-Member -MemberType NoteProperty -Name "Hardpoint" -Value ([pscustomobject]@{})
        foreach ($Location in $CDefObject.Locations) {
            $LocationName = $Location.Location
            $Mech.Hardpoint | Add-Member -MemberType NoteProperty -Name "$LocationName" -Value @()
            foreach ($Hardpoint in $Location.Hardpoints) {
                #Omni - if Omni true, add to omni count instead
                if ($Hardpoint.Omni) {
                    $OmniSlot++
                    $Mech.Hardpoint.$LocationName += 'Omni'
                #the BA slots
                } elseif (($Hardpoint.WeaponMountID -like "BattleArmor") -and (-not $Hardpoint.Omni)) {
                    $BattleArmorSlot++
                    $Mech.Hardpoint.$LocationName += "$($Hardpoint.WeaponMountID)"
                } else {
                    if (-not ($Hardpoint.WeaponMountID -match 'NotSet' -or $Hardpoint.WeaponMountID -match 'SpecialMelee' -or $Hardpoint.WeaponMountID -match 'Special')) {
                        $(Get-Variable "$($Hardpoint.WeaponMountID)Slot").Value++
                        $Mech.Hardpoint.$LocationName += "$($Hardpoint.WeaponMountID)"
                    }
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
        $LocationHash = @{
            'Head' = 'HD'
            'LeftArm' = 'LA'
            'LeftTorso' = 'LT'
            'CenterTorso' = 'CT'
            'RightTorso' = 'RT'
            'RightArm' = 'RA'
            'LeftLeg' = 'LL'
            'RightLeg' = 'RL'
        }
        $FixedLoadout = $CDefObject.FixedEquipment | select ComponentDefID, MountedLocation | group MountedLocation
        $DynamicLoadout = $MDefObject.Inventory | select ComponentDefID, MountedLocation | group MountedLocation
        $Mech | Add-Member -MemberType NoteProperty -Name "Loadout" -Value ([pscustomobject]@{})
        $Mech.Loadout = $([pscustomobject]@{
            Dynamic = [pscustomobject]@{}
            Fixed = [pscustomobject]@{}
        })
        foreach ($LocationEnum in $LocationHash.GetEnumerator()) {
            $Mech.Loadout.Dynamic | Add-Member -MemberType NoteProperty -Name $LocationEnum.Value -Value @()
            $Mech.Loadout.Fixed | Add-Member -MemberType NoteProperty -Name $LocationEnum.Value -Value @()
        }
        $FixedLoadout | % { $Mech.Loadout.Fixed.$($LocationHash.$($_.Name)) = $_.Group.ComponentDefID }
        $DynamicLoadout | % { $Mech.Loadout.Dynamic.$($LocationHash.$($_.Name)) = $_.Group.ComponentDefID }
        #Handle special loadouts
        if ($CDefObject.Custom.ArmActuatorSupport.LeftDefaultShoulder) {
            $Mech.Loadout.Fixed.LA += $CDefObject.Custom.ArmActuatorSupport.LeftDefaultShoulder
        }
        if ($CDefObject.Custom.ArmActuatorSupport.RightDefaultShoulder) {
            $Mech.Loadout.Fixed.RA += $CDefObject.Custom.ArmActuatorSupport.RightDefaultShoulder
        }
        # grab icon name
        $Mech | Add-Member -MemberType NoteProperty -Name "Icon" -Value $($CDefObject.Description.Icon)
        # grab HP amounts
        $Mech | Add-Member -MemberType NoteProperty -Name "HP" -Value ([pscustomobject]@{})
        # Structure
        $Mech.HP | Add-Member -MemberType NoteProperty -Name "Structure" -Value @{}
        $Mech.HP.Structure = @{
            HD = $($CDefObject.Locations | where -Property Location -Like "Head").InternalStructure
            LA = $($CDefObject.Locations | where -Property Location -Like "LeftArm").InternalStructure
            LT = $($CDefObject.Locations | where -Property Location -Like "LeftTorso").InternalStructure
            CT = $($CDefObject.Locations | where -Property Location -Like "LeftTorso").InternalStructure
            RT = $($CDefObject.Locations | where -Property Location -Like "RightTorso").InternalStructure
            RA = $($CDefObject.Locations | where -Property Location -Like "RightArm").InternalStructure
            LL = $($CDefObject.Locations | where -Property Location -Like "LeftLeg").InternalStructure
            RL = $($CDefObject.Locations | where -Property Location -Like "RightLeg").InternalStructure
        }
        $Mech.HP.Structure.Add('Total',$($Mech.HP.Structure.Values | % -Begin {$HPTotalHolder = 0} -Process {$HPTotalHolder += $_} -End {$HPTotalHolder}))
        # SetArmor
        $Mech.HP | Add-Member -MemberType NoteProperty -Name "SetArmor" -Value @{}
        $Mech.HP.SetArmor = @{
            HD = $($MDefObject.Locations | where -Property Location -Like "Head").AssignedArmor
            LA = $($MDefObject.Locations | where -Property Location -Like "LeftArm").AssignedArmor
            LTF = $($MDefObject.Locations | where -Property Location -Like "LeftTorso").AssignedArmor
            CTF = $($MDefObject.Locations | where -Property Location -Like "CenterTorso").AssignedArmor
            RTF = $($MDefObject.Locations | where -Property Location -Like "RightTorso").AssignedArmor
            LTR = $($MDefObject.Locations | where -Property Location -Like "LeftTorso").AssignedRearArmor
            CTR = $($MDefObject.Locations | where -Property Location -Like "CenterTorso").AssignedRearArmor
            RTR = $($MDefObject.Locations | where -Property Location -Like "RightTorso").AssignedRearArmor
            RA = $($MDefObject.Locations | where -Property Location -Like "RightArm").AssignedArmor
            LL = $($MDefObject.Locations | where -Property Location -Like "LeftLeg").AssignedArmor
            RL = $($MDefObject.Locations | where -Property Location -Like "RightLeg").AssignedArmor
        }
        $Mech.HP.SetArmor.Add('Total',$($Mech.HP.SetArmor.Values | % -Begin {$HPTotalHolder = 0} -Process {$HPTotalHolder += $_} -End {$HPTotalHolder}))
        # MaxArmor
        $Mech.HP | Add-Member -MemberType NoteProperty -Name "MaxArmor" -Value @{}
        $Mech.HP.MaxArmor = @{
            HD = $($CDefObject.Locations | where -Property Location -Like "Head").MaxArmor
            LA = $($CDefObject.Locations | where -Property Location -Like "LeftArm").MaxArmor
            LTF = $($CDefObject.Locations | where -Property Location -Like "LeftTorso").MaxArmor
            CTF = $($CDefObject.Locations | where -Property Location -Like "CenterTorso").MaxArmor
            RTF = $($CDefObject.Locations | where -Property Location -Like "RightTorso").MaxArmor
            LTR = $($CDefObject.Locations | where -Property Location -Like "LeftTorso").MaxRearArmor
            CTR = $($CDefObject.Locations | where -Property Location -Like "CenterTorso").MaxRearArmor
            RTR = $($CDefObject.Locations | where -Property Location -Like "RightTorso").MaxRearArmor
            RA = $($CDefObject.Locations | where -Property Location -Like "RightArm").MaxArmor
            LL = $($CDefObject.Locations | where -Property Location -Like "LeftLeg").MaxArmor
            RL = $($CDefObject.Locations | where -Property Location -Like "RightLeg").MaxArmor
        }
        $Mech.HP.MaxArmor.Add('Total',$($Mech.HP.MaxArmor.Values | % -Begin {$HPTotalHolder = 0} -Process {$HPTotalHolder += $_} -End {$HPTotalHolder}))
        #Grab and trim Mech Blurb
        $MechBlurb = $MDefObject.Description.Details
        
        #Regex cleanup
        $MechBlurb = $($($MechBlurb.Split("`n")) -Replace ('^[ \t]*','')) -Join ("`n") #split by lines, trim leading spaces/tabs, rejoin
        $MechBlurb = $MechBlurb -Replace ('<color=(.*?)>(.*?)<\/color>','<span style="color:$1;">$2</span>') #replace color tag
        $MechBlurb = $MechBlurb -Replace ('<b>(.*?)<\/b>','$1') #remove bold
        $Mech | Add-Member -MemberType NoteProperty -Name "Blurb" -Value $MechBlurb
        #11 - PrefabID
        # if custom AV exists
        if (-not !$CDefObject.Custom.AssemblyVariant.PrefabID) {
            # if exclude is false
            if ($CDefObject.Custom.AssemblyVariant.Exclude -eq $false) {
                $Mech | Add-Member -MemberType NoteProperty -Name "PrefabID" -Value $CDefObject.Custom.AssemblyVariant.PrefabID
            }
        } else {
            $Mech | Add-Member -MemberType NoteProperty -Name "PrefabID" -Value $CDefObject.PrefabBase
        }

        #12 - Chassisdef
        $Mech | Add-Member -MemberType NoteProperty -Name "ChassisID" -Value $MDefObject.ChassisID

        #13 - ArmActuatorSupport
        if ([bool]($CDefObject.Custom.ArmActuatorSupport)) {
            $Mech | Add-Member -MemberType NoteProperty -Name "ArmActuatorSupport" -Value $([pscustomobject]@{})
            $Mech.ArmActuatorSupport | Add-Member -MemberType NoteProperty -Name "LA" -Value $CDefObject.Custom.ArmActuatorSupport.LeftLimit
            $Mech.ArmActuatorSupport | Add-Member -MemberType NoteProperty -Name "RA" -Value $CDefObject.Custom.ArmActuatorSupport.RightLimit
        }

        ###START OVERRIDES SECTION
        #convert to proto to power
        #
        if ($Mech.Class -eq "PROTO") {
            $Mech.Class = "POWER"
        }
        #Plasma Beak
        if ($Mech.Name.Chassis -like "PLASMA BEAK") {
            $Mech.Class = "POWER"
        }
        #Simple Omni Overrides
        $OmniOverrides = $(Import-Csv "$RTScriptroot\\Inputs\\OmniOverrides.csv")
        foreach ($OmniOverride in $OmniOverrides) {
            if (($Mech.Name.Chassis -like $OmniOverride.BaseChassis) -and ($Mech.WeaponMounts.OmniSlot -gt 0)) {
                $Mech.Name.Chassis = $OmniOverride.OmniChassis
            }
        }
        #Simple Unique to Chassis Override
        $UCOverrides = @($(Import-Csv "$RTScriptroot\\Inputs\\UCOverrides.csv").UCOverrides)
        foreach ($UCOverride in $UCOverrides) {
            if ($Mech.Name.Unique -like $UCOverride) {
                $Mech.Name.Unique = $null
                $Mech.Name.Chassis = $UCOverride
            }
        }
        #RFL-3N (C) cleanup
        if ($Mech.Name.Variant -like "RFL-3N (C)") {
            $Mech.Name.Hero = ""
        }
        #KERES cleanup
        if ($Mech.Name.Variant -like "C-PRT-O-PX") {
            $Mech.Name.Unique = ""
            $Mech.Name.Hero = "KERES PX"
        }
        #Beetle Drone
        if ($Mech.Name.Chassis -like "AUTOMECH") {
            $Mech.Name.Chassis = "BEETLE DRONE"
        }
        #Comet Scream
        if ($Mech.Name.Chassis -like "FIGHTER AUTOMECH") {
            $Mech.Name.Chassis = "COMET SCREAM"
            $Mech.Name.Unique = ""
        }
        #Sounder // Lambor
        if (($Mech.Name.Chassis -like "WHEELED AUTOMECH") -and ($Mech.Name.Unique -like "LAMBOR*")) {
            $Mech.Name.Chassis = "SOUNDER"
        }
        #Grimdark
        if ($Mech.Name.Chassis -like "BESTIAL AUTOMECH") {
            $Mech.Name.Chassis = "GRIMDARK"
            $Mech.Name.Unique = ""
        }
        #Noise jammer
        if ($Mech.Name.Chassis -like "COMMUNICATIONS SPECIALIST") {
            $Mech.Name.Chassis = "NOISE JAMMER"
            $Mech.Name.Unique = ""
        }
        #Optimus
        if (($Mech.Name.Chassis -like "WHEELED AUTOMECH") -and ($Mech.Name.Unique -like "PRIMUS*")) {
            $Mech.Name.Chassis = "LEADER"
        }
        #Avatar fuckiness
        if ($Mech.Name.Variant -like "AV1*") {
            $Mech.Name.Chassis = "AVATAR"
        }
        if ($Mech.Name.Variant -like "AV2*") {
            $Mech.Name.Chassis = "AVATAR II"
        }
        #Toads Overrides
        if ($Mech.ID -match 'salamander_AP') {
            $Mech.Name.Hero = 'AP'
        }
        if ($Mech.ID -match 'salamander_laser') {
            $Mech.Name.Hero = 'Laser'
        }
        ###END OVERRIDES SECTION
        
        #Prep VariantGlue
        $VariantLink = $($Mech.Name.Variant)
        $VariantGlue = $($VariantLink+$($Mech.Name.SubVariant)).Trim()
        if (-not !$Mech.Name.Hero) {
            $VariantGlue += " ($($Mech.Name.Hero))"
        }
        if (-not !$mech.Name.Unique) {
            $VariantGlue += " aka $($Mech.Name.Unique)"
        }
        #variantglue unresolvable conflicts override
        if ([bool]($BlacklistOverride | ? {$filePathMDef -match $_})) {
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
        } elseif ($Mech.Name.Variant -eq 'HND-1') {
            $VariantGlue += " -$($Mech.Name.Chassis)-"
        } elseif ($Mech.Name.Variant -eq 'HND-3') {
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

        #PrefabID/Compatible Variants
        if (-not !$Mech.PrefabID) {
            #Create prefabid if not exist
            if (!$(iex $('$PrefabID.'+"'"+$($Mech.PrefabID)+"'"))) {
                $PrefabID | Add-Member -MemberType NoteProperty -Name "$($Mech.PrefabID)" -Value $([pscustomobject]@{})
            }
            #create tonnage sub id if not exist
            if (!$(iex "$('$PrefabID.'+"'"+$($Mech.PrefabID)+"'"+'.'+$($Mech.Tonnage))")) {
                $PrefabID.$($Mech.PrefabID) | Add-Member -MemberType NoteProperty -Name $($Mech.Tonnage) -Value @()
            }            
            $PrefabID.$($Mech.PrefabID).$($Mech.Tonnage) += $Mech.MechDefFile
        }
        
        #Parse Loadout list to gearusedby.json
        if (!$Mech.BLACKLIST) {
            $MechUsesGearList = $($(@($FixedLoadout.Group.ComponentDefID) + @($DynamicLoadout.Group.ComponentDefID)) | group).Name
            foreach ($MechUsesGear in $MechUsesGearList) {
                if (!($GearUsedBy.psobject.Properties.Name -contains $MechUsesGear)) {
                    $GearUsedBy | Add-Member -NotePropertyName $MechUsesGear -NotePropertyValue @()
                }
                $GearUsedBy.$MechUsesGear += $Mech.Name.LinkName
            }
        }

        #Parse Affinities to File
        $FixedList = [string[]]$FixedLoadout.Group.ComponentDefID
        $AffinityList = [string[]]$EquipAffinitiesIDNameHash.Keys
        if (!$Mech.BLACKLIST) {
            if (-not !$FixedList) {
                foreach ($FixedAffinityItem in $(compare $AffinityList $FixedList -ExcludeDifferent -IncludeEqual).InputObject) {
                    if ($FixedAffinityObject.psobject.Properties.Name -notcontains $FixedAffinityItem) {
                        $FixedAffinityObject | Add-Member -NotePropertyName $FixedAffinityItem -NotePropertyValue @()
                    }
                    $FixedAffinityObject.$FixedAffinityItem += $Mech.Name.LinkName
                }
            }
        }

        #Add the raw defobjects
        $Mech | Add-Member -NotePropertyName Wiki -NotePropertyValue $([pscustomobject]@{})
        $Mech.Wiki | Add-Member -NotePropertyName MDef -NotePropertyValue $MDefObject
        $Mech.Wiki | Add-Member -NotePropertyName CDef -NotePropertyValue $CDefObject

        #add mechobject to $mechs
        $Mechs += $Mech
    } else {
        Write-Error -Message "Error with ChassisID in $filePathMDef"
    }
}
#load overrides
#CleanupDupes

#DirtyDupes
$DupeLinkName = $Mechs | group {$_.Name.LinkName} | ? {$_.Count -ge 2}
if ($DupeLinkName.Count -gt 0) {
    Write-Host "Dupe LinkNames found"
    $DupeLinkName
    #pause
}
#save to file
$Mechs | ConvertTo-Json -Depth 10 | Out-File $MechsFile -Force
$PrefabID | ConvertTo-Json -Depth 10 | Out-File $PrefabIDFile -Force
$GearUsedBy | ConvertTo-Json -Depth 10 | Out-File $GearUsedByFile -Force
$FixedAffinityObject | ConvertTo-Json -Depth 100 | Out-File $FixedAffinityFile -Force
