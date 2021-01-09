#Script Root
$PWBRoot = "D:\\PYWikiBot"
$RTScriptroot = "D:\\RogueTech\\WikiGenerators"

#push gear navbox first, then remainder pages
py $PWBRoot\\pwb.py pagefromfile -file:'D:\RogueTech\WikiGenerators\Outputs\Gear\!Navbox.txt' -notitle -force -pt:0
cls
py $PWBRoot\\pwb.py pagefromfile -file:'D:\RogueTech\WikiGenerators\Outputs\Gear\!TOCPages.txt' -notitle -force -pt:0
cls
py $PWBRoot\\pwb.py pagefromfile -file:'D:\RogueTech\WikiGenerators\Outputs\Gear\!ItemPages.txt' -notitle -force -pt:0
cls