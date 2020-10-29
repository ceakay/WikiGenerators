#This parses ChassDef and MechDef for info
#
#

#FUNCTIONS
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
$RTroot = "D:\RogueTech\"
cd $RTroot
#stringarray - factions - sort by display alpha
    #fuck this. build it from \RtlCache\RtCache\RogueTech Core\Faction.json
$FactionFile = "\RtlCache\RtCache\RogueTech Core\Faction.json"
#string - conflictfilemask
$conflictfilemask = "FIXME"
#stringarray - CDef special
$CDefSpecial = @("elite","omni","primitive")
#stringarray - MDef Special
$MDefSpecial = @("elite","omni","primitive")
##leave CDef and MDef undefined. can partition this out for conflict finder. inject into array with $CDefSpecial and $MDefSpecial below
#stringarray - CDef, must be in same order to compare with MDef
$CDef = @()
#stringarray - MDef, must be in same order to compare with CDef
$MDef = @()


#set options
    #string - isolate for Mechs/Vehicles/???

#build faction table
#init faction hash
$FactionHash = @{
    Faction = @()
    FriendlyName = @()
    GreatHouse = @()
    Clan = @()
    Merc = @()
    Pirate = @()
}

#init keys
$FactionHash.Keys > $null

#pull faction data into hash
$FactionFileRaw = Get-Content $RTroot$FactionFile -Raw
$FactionArrayRaw = (datachop "`"enumerationValueList`" :" 1 $FactionFileRaw)
$FactionArrayRaw = makearray "}," $FactionArrayRaw
for ($i=0; $i -lt $FactionArrayRaw.Count; $i++) {
    $IsReal = (datachop "`"IsRealFaction`" : " 1 $FactionArrayRaw[$i])
    if ($IsReal -like "true*") {
        $FactionHash.Faction += (datachop "`"," 0 (datachop "`"Name`" : `"" 1 $FactionArrayRaw[$i]))
        $FactionHash.FriendlyName += (datachop "`"," 0 (datachop "`"FriendlyName`" : `"" 1 $FactionArrayRaw[$i]))
        $FactionHash.GreatHouse += (datachop "," 0 (datachop "`"IsGreatHouse`" : " 1 $FactionArrayRaw[$i]))
        $FactionHash.Clan += (datachop "," 0 (datachop "`"IsClan`" : " 1 $FactionArrayRaw[$i]))
        $FactionHash.Merc += (datachop "," 0 (datachop "`"IsMercenary`" : " 1 $FactionArrayRaw[$i]))
        $FactionHash.Pirate += (datachop "," 0 (datachop "`"IsPirate`" : " 1 $FactionArrayRaw[$i]))
    }
}

#build into table ???
$FactionArray = @()
$FactionHashObject = [System.Management.Automation.PSCustomObject]$FactionHash
