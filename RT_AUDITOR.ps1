#This audits tags
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


#RogueTech Dir (Where RTLauncher exists)
$RTroot = "D:\\RTDev"
cd $RTroot
#Script Root
$RTScriptRoot = "D:\\RogueTech\\WikiGenerators"
#cache path
$CacheRoot = "$RTroot\\RogueTech"
#stringarray - factions - sort by display alpha
    #fuck this. build it from \RogueTech Core\Faction.json
$FactionFile = "$CacheRoot\\RogueTech Core\\Faction.json"
#build faction groups. data incomplete (no periphery tags exist, factions can be containered in multiple groups), create from human readable CSV.
$GroupingFile = "$RTScriptRoot\\Inputs\\FactionGrouping.csv"
#string - conflictfile
$conflictfile = "$RTScriptRoot\\conflict.csv"
#stringarray - CDef special
#$CDefSpecial = @("OmniMech","Primitive","EliteMech","PrototypeMech","ProtoMech","SLDFMech","HeroMech","ClanMech","SocietyMech")
#stringarray - MDef Special
#$MDefSpecial = @($null,"unit_primitive","unit_elite","unit_prototype","unit_protomech","unit_sldf","unit_hero",$null,$null)
##leave CDef and MDef undefined. can partition this out for conflict finder. inject into array with $CDefSpecial and $MDefSpecial below
#stringarray - CDef (FILL WITH $null IF NOTHING COMPARABLE)
$CDef = 
#stringarray - MDef (FILL WITH $null IF NOTHING COMPARABLE)
$MDef = 


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
$FactionObject = $($(Get-Content $FactionFile | ConvertFrom-Json).enumerationValueList)
#grouping table
    #Keys: BLACKLIST; CLAN; INNERSPHERE; MERC; PERIPHERY; PIRATE
$GroupingObject = Import-Csv -Path "$GroupingFile"
#building a list of files (ChassisDef) to work with. Isolate for: $ChassisDefMask (see SET OPTIONS)    
$MDefFileObjectList = @(Get-ChildItem $CacheRoot -Recurse -Filter "$MDefMask*.$MDefFileType" -Exclude $MDefExclusion)


#build a table of mechs, exportable to CSV
    #Name, QName (unique name), Signature (Variant), SubVar (SubVarian), Factions, Weight, Class, Hardpoints, Special
#search each file for info. write to holder array var
$i = 0

#create conflict file
#ascii required for excel cuz M$
@"
Comparing
CDEF=,$($CDef -join ",")
MDEF=,$($MDef -join ",")
===================
|CONFLICT| ,CDef // MDef, || ,Missing Tag, |Missing in| ,file
"@ | Out-File -FilePath $conflictfile -Encoding ascii

foreach ($MDefFileObject in $MDefFileObjectList) { 
    #setup CDef and MDef objects
    $i++
    write-progress -activity "Scanning files" -Status "$i of $($MDefFileObjectList.Count)"
    $filePathMDef = $MDefFileObject.VersionInfo.FileName
    $fileNameMDef = Split-Path $MDefFileObject.VersionInfo.FileName -Leaf
    $MDefObject = $(Get-Content $filePathMDef | ConvertFrom-Json)
    $fileNameCDef = "$($MDefObject.ChassisID).$($CDefFileType)"
    $CDefFileObject = Get-ChildItem $CacheRoot -Recurse -Filter "$fileNameCDef"
    $filePathCDef = $CDefFileObject.VersionInfo.FileName
    $CDefObject = $(Get-Content $filePathCDef | ConvertFrom-Json)
    
    $j = 0

    foreach ($CTag in $CDef) {
        #do audit below here. use $MDef[$j]
        $MTag = $MDef[$j]
        if ($MTag -and $CTag) {
            #parses whole file as a single string.
            if (($(Get-Content $filePathCDef -Raw) -like "*$CTag*") -like $false) {
                "CONFLICT ,$CTag // $MTag, || ,$CTag, Missing in ,$(datachop $CacheRoot 1 $filePathCDef)" >> $conflictfile 
            } elseif (($(Get-Content $filePathMDef -Raw) -like "*$MTag*") -like $false) {
                "CONFLICt ,$CTag // $MTag, || ,$MTag, Missing in ,$(datachop $CacheRoot 1 $filePathMDef)" >> $conflictfile
            }
        }
        #do audit above here. 
        $j++
    }

}

#Some Cleanup Shit
if (!$StoreEncode) {
    $PSDefaultParameterValues.Remove('*:Encoding')
} else {
    $PSDefaultParameterValues = @{ '*:Encoding' = "$StoreEncode" }
}
