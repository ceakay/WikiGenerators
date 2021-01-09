#Script Root
$PWBRoot = "D:\\PYWikiBot"
$RTScriptroot = "D:\\RogueTech\\WikiGenerators"
$WikiID = "MechList"
$MexID = "Mex"
$WikiPageFileUTF8 = "$RTScriptroot\\Outputs\\$($WikiID)WikiPage.UTF8"
$WikiPageMexFileUTF8 = "$RTScriptroot\\Outputs\\$($MexID)WikiPage.UTF8"
py $PWBRoot\\pwb.py login
cls
py $PWBRoot\\pwb.py pagefromfile -file:$WikiPageFileUTF8 -notitle -force -pt:0
cls
py $PWBRoot\\pwb.py pagefromfile -file:$WikiPageMexFileUTF8 -notitle -force -pt:0
cls

$WikiID = "TankList"
$MexID = "Tanx"
$WikiPageFileUTF8 = "$RTScriptroot\\Outputs\\$($WikiID)WikiPage.UTF8"
$WikiPageMexFileUTF8 = "$RTScriptroot\\Outputs\\$($MexID)WikiPage.UTF8"
py $PWBRoot\\pwb.py login
cls
py $PWBRoot\\pwb.py pagefromfile -file:$WikiPageFileUTF8 -notitle -force -pt:0
cls
py $PWBRoot\\pwb.py pagefromfile -file:$WikiPageMexFileUTF8 -notitle -force -pt:0
cls

#push gear navbox first, then remainder pages
py $PWBRoot\\pwb.py pagefromfile -file:'D:\RogueTech\WikiGenerators\Outputs\Gear\!Navbox.txt' -notitle -force -pt:0
cls
py $PWBRoot\\pwb.py pagefromfile -file:'D:\RogueTech\WikiGenerators\Outputs\Gear\!TOCPages.txt' -notitle -force -pt:0
cls
py $PWBRoot\\pwb.py pagefromfile -file:'D:\RogueTech\WikiGenerators\Outputs\Gear\!ItemPages.txt' -notitle -force -pt:0
cls