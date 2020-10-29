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
$RTroot = "D:\RogueTech"
#stringarray - factions - sort by display alpha
    #fuck this. build it from \RtlCache\RtCache\RogueTech Core\Faction.json
$FactionFile = "\RtlCache\RtCache\RogueTech Core\Faction.json"
#build faction groups. data incomplete (no periphery tags exist, factions can be containered in multiple groups), create from human readable CSV.
$GroupingFile = "\WikiGenerators\Inputs\FactionGrouping.csv"
#cache path
$CachePath = "\RtlCache"

#string - conflictfilemask
$conflictfilemask = "FIXME"
#stringarray - CDef special
$CDefSpecial = @("OmniMech","Primitive","EliteMech","PrototypeMech","ProtoMech","SLDFMech","HeroMech","ClanMech","SocietyMech")
#stringarray - MDef Special
$MDefSpecial = @("elite","omni","primitive")
##leave CDef and MDef undefined. can partition this out for conflict finder. inject into array with $CDefSpecial and $MDefSpecial below
#stringarray - CDef, must be in same order to compare with MDef
$CDef = @()
#stringarray - MDef, must be in same order to compare with CDef
$MDef = @()


#SET OPTIONS
###
#string - isolate for Mechs/Vehicles/???
$CDefFileType = "json"
$MDefFileType = "json"
$CDefMask = "chassisdef"
$MDefMask = "mechdef"
    #Always surround Exclusion text with *
$MDefExclusion = @("*TARGETDUMMY*","*shadowhawk_REP-ME*")

#BUILD OBJECT TABLES
###
#faction table
    #Keys: ID; Name; FriendlyName; Description; FactionDefID; IsRealFaction; IsGreatHouse; IsClan; IsMercenary; IsPirate; DoesGainReputation; CanAlly; IsProceduralContractFaction; IsCareerScoringFaction; IsCareerIgnoredContractTarget; IsCareerStartingDisplayFaction; IsStoryStartingDisplayFaction; HasAIBehaviorVariableScope
$FactionObject = $($(Get-Content $RTroot$FactionFile | ConvertFrom-Json).enumerationValueList)
#grouping table
    #Keys: BLACKLIST; CLAN; INNERSPHERE; MERC; PERIPHERY; PIRATE
$GroupingObject = Import-Csv -Path "$RTroot$GroupingFile"
#building a list of files (ChassisDef) to work with. Isolate for: $ChassisDefMask (see SET OPTIONS)    
$MDefFileObjectList = @(Get-ChildItem $RTroot$CachePath -Recurse -Filter "$MDefMask*.$MDefFileType" -Exclude $MDefExclusion)


#build a table of mechs, exportable to CSV
    #Name, QName (unique name), Signature (Variant), SubVar (SubVarian), Factions, Weight, Class, Hardpoints, Special
#search each file for info. write to holder array var


#####PASTAENDS

"PATH,MDEF.UINAME" > mechnameaudit.csv
$i = 0
foreach ($MDefFileObject in $MDefFileObjectList) { 
    #setup CDef and MDef objects
    $i++
    write-progress -activity "Scanning files" -Status "$i of $($MDefFileObjectList.Count)"
    $filePathMDef = $MDefFileObject.VersionInfo.FileName
    $fileNameMDef = Split-Path $MDefFileObject.VersionInfo.FileName -Leaf
    $MDefObject = $(Get-Content $filePathMDef | ConvertFrom-Json)
    $fileNameCDef = "$($MDefObject.ChassisID).$($CDefFileType)"
    $CDefFileObject = Get-ChildItem $RTroot$CachePath -Recurse -Filter "$fileNameCDef"
    $filePathCDef = $CDefFileObject.VersionInfo.FileName
    $CDefObject = $(Get-Content $filePathCDef | ConvertFrom-Json)
    
    #Audit with this
    "$($filePathCDef),$($CDefObject.weightClass)" >> mechnameaudit.csv
}
