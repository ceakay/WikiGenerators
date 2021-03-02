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
