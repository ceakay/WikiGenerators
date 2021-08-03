###SET CONSTANTS
###
#RogueTech Dir (Where RTLauncher exists)
$RTroot = "D:\\RogueTech"
cd $RTroot
#Script Root
$RTScriptroot = "D:\\RogueTech\\WikiGenerators"
#cache path
$CacheRoot = "$RTroot\\RtlCache\\RtCache"
#Define component unique
$StarFile = $RTScriptroot+"\\Outputs\\StarTable.json"
$MW5Data = "D:\\MW5_InnerSphereData.json"

$StarObjectList = Get-Content $StarFile -Raw | ConvertFrom-Json
$MW5DataList = Get-Content $MW5Data -Raw | ConvertFrom-Json

$Counter = 5000

foreach ($StarObject in $StarObjectList) {
    if ($MW5DataList.StarSystemName -contains $StarObject.Description.Name) {
        #Skip
    } else {
        $MW5DataList += [pscustomobject]@{
            Name = $Counter
            StarSystemName = $StarObject.Description.Name
            PosX = [double]$StarObject.Position.x
            PosY = [double]$StarObject.Position.y
            SystemType = $null
            SpectralType = $StarObject.StarType
            Luminosity = $null
            SubType = [double]$null
            SystemStatus = $null
            ChargingStation = $null
            Orbitals = $null
            Habitable = $null
            Description = $StarObject.Description.Details
            Cluster = [pscustomobject]@{
                Id = [pscustomobject]@{
                    PrimaryAssetType = [pscustomobject]@{
                        Name = $null
                    }
                    PrimaryAssetName = $null
                }
            }
            ClusterOverlay = $null
            ClusterConstellation = $null

        }
        $Counter++
    }
}

$MW5DataList | ConvertTo-Json -Depth 22 | % {
    [Regex]::Replace($_, 
        "\\u(?<Value>[a-zA-Z0-9]{4})", {
            param($m) ([char]([int]::Parse($m.Groups['Value'].Value,
                [System.Globalization.NumberStyles]::HexNumber))).ToString() } )} | Out-File D:\RumiesList.json -Force