#Script Root
$PWBRoot = "D:\\PYWikiBot"
$RTScriptroot = "D:\\RogueTech\\WikiGenerators"
$WikiID = "MechList"
$MexID = "Mex"
$WikiPageFileUTF8 = "$RTScriptroot\\Outputs\\$($WikiID)WikiPage.UTF8"
$WikiPageMexFileUTF8 = "$RTScriptroot\\Outputs\\$($MexID)WikiPage.UTF8"
$titlestartend = "@@@"
py $PWBRoot\\pwb.py login
cls
py $PWBRoot\\pwb.py pagefromfile -file:$WikiPageFileUTF8 -notitle -force -pt:0 -titlestart:$titlestartend -titleend:$titlestartend
cls
py $PWBRoot\\pwb.py pagefromfile -file:'D:\RogueTech\WikiGenerators\Outputs\Mechs\!MechPages.txt' -notitle -force -pt:0 -titlestart:$titlestartend -titleend:$titlestartend
cls
