#SET CONSTANTS
###
#RogueTech Dir (Where RTLauncher exists)
$RTroot = "D:\\RogueTech"
#Script Root
$RTScriptroot = "D:\\RogueTech\\WikiGenerators"
cd $RTScriptroot
#cache path
$CacheRoot = "$RTroot\\RtlCache\\RtCache"
$CreditsFile = "$RTScriptroot\\Outputs\\Credits.wiki"

$FileList = Get-ChildItem $CacheRoot -Filter 'mod.json' -Recurse
$ModArray = @()

foreach ($File in $FileList.FullName) {
    $FileContent = Get-Content $File
    $RawContent = @()
    foreach ($Line in $FileContent) {
        $RawContent += $Line -replace '^\s*\/\/.*$',' '
    }
    $RawContent = $RawContent | Out-String
    if ($RawContent -match "`"Author`"") { 
        try {
            $Mod = ConvertFrom-Json $RawContent
            $Mod.Name = Split-Path $(Get-Item $File).DirectoryName -Leaf
            $ModArray += $Mod
        }
        catch {$File}
    }
}

$WikiText = "Last Updated RT Version $($(Get-Content "$CacheRoot\\RogueTech Core\\mod.json" -raw | ConvertFrom-Json).Version)`r`n`r`n" + $(Get-Content "$RTScriptroot\Inputs\Blurbs\Credits.txt" -Raw)

$ModsTable = "{| class=`"wikitable`"`r`n|-`r`n! Mod !! Author`r`n"
foreach ($Mod in $ModArray) {
    $ModsTable += "|-`r`n| [[Mods/$($Mod.Name)|$($Mod.Name)]] || $($Mod.Author)`r`n"
}
$ModsTable += "|}`r`n"

$WikiText = "{{-start-}}`r`n'''Credits'''`r`n" + $WikiText + "`r`n{{-stop-}}`r`n"
$WikiText -replace ('##ModsTable##',$ModsTable) | Out-File -Encoding utf8 $CreditsFile
