﻿#Script Root
$PWBRoot = "D:\\PYWikiBot"
$RTScriptroot = "D:\\RogueTech\\WikiGenerators"
$titlestartend = "@@@"
#Unit Affinities Push
py $PWBRoot\\pwb.py pagefromfile -file:'D:\RogueTech\WikiGenerators\Outputs\Unit_Affinities.utf8' -notitle -force -pt:0 -titlestart:$titlestartend -titleend:$titlestartend
cls
#push gear navbox first, then remainder pages
py $PWBRoot\\pwb.py pagefromfile -file:'D:\RogueTech\WikiGenerators\Outputs\Gear\!Navbox.txt' -notitle -force -pt:0 -titlestart:$titlestartend -titleend:$titlestartend
cls
py $PWBRoot\\pwb.py pagefromfile -file:'D:\RogueTech\WikiGenerators\Outputs\Gear\!TOCPages.txt' -notitle -force -pt:0 -titlestart:$titlestartend -titleend:$titlestartend
cls
py $PWBRoot\\pwb.py pagefromfile -file:'D:\RogueTech\WikiGenerators\Outputs\Gear\!ItemPages.txt' -notitle -force -pt:0 -titlestart:$titlestartend -titleend:$titlestartend
cls