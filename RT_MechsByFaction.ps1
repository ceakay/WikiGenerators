Write-Host @"





































"@

###FUNCTIONS
#data chopper function
    #args: delimiter, position, input
function datachop {
    $array = @($args[2] -split "$($args[0])")    
    return $array[$args[1]]
}

###SETTINGS
#disable when testing!
# moved uploading to own script
$UploadToWiki = $false

#SET CONSTANTS
###
#RogueTech Dir (Where RTLauncher exists)
$RTroot = "D:\\RogueTech"
#Script Root
$RTScriptroot = "D:\\RogueTech\\WikiGenerators"
cd $RTScriptroot
#cache path
$CacheRoot = "$RTroot\\RtlCache\\RtCache"
#WikiPage unique Identifier
$WikiID = "MechList"
$MexID = "Mex"
#Blurb that goes before 
$Blurb = "$RTScriptroot\\Inputs\\$($WikiID)Blurb.txt"
$TableFile = "$RTScriptroot\\Outputs\\$($WikiID)Table.json"
$WikiPageFile = "$RTScriptroot\\Outputs\\$($WikiID)WikiPage.txt"
$WikiPageFileUTF8 = "$RTScriptroot\\Outputs\\$($WikiID)WikiPage.UTF8"
$WikiPageMexFile = "$RTScriptroot\\Outputs\\$($MexID)WikiPage.txt"
$WikiPageMexFileUTF8 = "$RTScriptroot\\Outputs\\$($MexID)WikiPage.UTF8"
$CatFile = "$RTScriptroot\\Inputs\\Class.csv"
$CatObject = Get-Content $CatFile -raw | ConvertFrom-Csv
$SpecialsFile = "$RTScriptroot\\Inputs\\Special.csv"
$SpecialsObject = Get-Content $SpecialsFile -Raw | ConvertFrom-Csv
$MountsFile = "$RTScriptroot\\Inputs\\WeaponMounts.csv"
$MountsObject = Get-Content $MountsFile -Raw | ConvertFrom-Csv
$GroupingFile = "$RTScriptroot\\Inputs\\FactionGrouping.csv"
$GroupingCSVObject = Import-Csv -Path "$GroupingFile" 
$PWBRoot = "D:\\PYWikiBot"
$PrefabIDFile = "$RTScriptroot\\Outputs\\PrefabID.json"
