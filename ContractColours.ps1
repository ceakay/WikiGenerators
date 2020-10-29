$ColourFile = "D:\\RogueTech\\RtlCache\\RtCache\\ColourfulFlashpoints\\settings.json"
$ColourOutFile = "D:\\RogueTech\\WikiGenerators\\Outputs\\Colours.UTF8"
$ColourObject = Get-Content $ColourFile -Raw | ConvertFrom-Json
$ColourObject = $ColourObject.contractMarkers
$ColourText = @"
{{-start-}}
'''Contract Cosmetic Rework'''
= Contract Cosmetics =

== Contract Name ==
Contract Names are now randomly generated from a pool of possible combinations. 

== Contract Colors ==
{| class="wikitable sortable"
|-
! Color !! Contract Type
"@
foreach ($ColourItem in $ColourObject) {
    $Colour = $ColourItem.colour.Colour.ToUpper()
    $Alpha = $(1 - $ColourItem.colour.Alpha)
    $Contracts = $ColourItem.contractIds -join ", "
    $ColourText += "`r`n|-`r`n! <span style=`"color:$Colour; opacity:$Alpha`">'''$Colour'''</span>`r`n| $Contracts"
}
$ColourText += "`r`n|}`r`n{{-stop-}}"
$ColourText | Set-Content -Encoding UTF8 $ColourOutFile

$PWBRoot = "D:\\PYWikiBot"
py $PWBRoot\\pwb.py pagefromfile -file:$ColourOutFile -notitle -force -pt:0