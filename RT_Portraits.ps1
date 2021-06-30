#SET CONSTANTS
###
#RogueTech Dir (Where RTLauncher exists)
$RTroot = "D:\RogueTech"
#Script Root
$RTScriptroot = "D:\RogueTech\WikiGenerators"
cd $RTScriptroot
#cache path
$CacheRoot = "$RTroot\RtlCache\RtCache"

$ImageInFolder = "D:\RogueTech\RtlCache\RtCache\MechPortraitsCrew\"
$ImageOutFolder = "D:\RogueTech\WikiGenerators\Outputs\Portraits\"

New-Alias Magick D:\RogueTech\WikiGenerators\Tools\Magick\magick.exe -Force

$ImageList = Get-ChildItem $ImageInFolder -Recurse -Filter "*.dds"
foreach ($Image in $ImageList) {
    $ImageName = [io.path]::GetFileNameWithoutExtension($Image)
    Magick $($Image.FullName) -rotate "180" $($ImageOutFolder + $ImageName + ".png")
}

#PWB Upload part
#Script Root
$PWBRoot = "D:\\PYWikiBot"

py $PWBRoot\\pwb.py upload -pt:0 -recursive -keep -ignorewarn -noverify -summary:"BotUpdate" $ImageOutFolder -descfile:"$($RTScriptroot+ '\BotUpdate.txt')"