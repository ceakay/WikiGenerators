
foreach ($Cat in $CatOrder) {
    $z++
    $MainBlockText = "##MainBlockText$z##"
    $MainBlockFile = "$RTScriptroot\\Outputs\\Mechs\\LoadoutBlock\\##LoadoutText$f##.txt"
    Start-Job -Name $("MainBlockJob"+$z) -ScriptBlock $MainBlock | Out-Null #start job with $loadoutblock

    $CatHeaderName = $($CatObject | where -Property TagTitle -Contains $Cat).FTitle
    $h++ 
#generate header
    $CatFriendly = $($CatObject | where -Property TagTitle -Contains $Cat).Friendly
    
    $WikiTable += $CatHeader
    $MechsFilteredObject = $MechsMasterObject | where -Property class -contains $Cat | sort -Property ({$_.Name.Chassis}, {$_.Name.Variant}, {$_.Name.SubVariant}, {$_.Name.Unique}, {$_.Name.Hero})
    $MechsChassisGroup = $MechsFilteredObject | Group-Object -Property {$_.name.chassis}
    
    #generate Footer
    
    $WikiTable += $CatFooter
}

#wait for jobbed sections to finish
while((Get-Job | Where-Object {$_.State -ne "Completed"}).Count -gt 0) {
    Start-Sleep -Milliseconds 250
    Write-Progress -id 0 -Activity 'Waiting for jobs'
    foreach ($job in (Get-Job)) {
        Write-Progress -Id $job.Id -Activity $job.Name -Status $job.State -ParentId 0
    }
}
#Cleanup Averages Job
Get-Job | Remove-Job

#WikiMexTable subout
for ($m=1; $m -le $($MechsMasterObject.Count); $m++) {
    $Search = "##LoadoutText$m##"
    $LoadoutBlockFile = "$RTScriptroot\\Outputs\\Mechs\\LoadoutBlock\\##LoadoutText$m##.txt"
    $LoadoutBlockText = Get-Content $LoadoutBlockFile -Raw
    $WikiMexTable = $WikiMexTable.Replace($Search,$LoadoutBlockText)
}

#save it to file at end
$WikiTable = "{{-start-}}`r`n"+$WikiTable+"`r`n{{-stop-}}"
$WikiTable > $WikiPageFile
$WikiMexTable > $WikiPageMexFile
#Convert UTF8
<#
Get-Content $WikiPageFile | Set-Content -Encoding UTF8 $WikiPageFileUTF8
Get-Content $WikiPageMexFile | Set-Content -Encoding UTF8 $WikiPageMexFileUTF8
#>
if ($UploadToWiki) {
    py $PWBRoot\\pwb.py login
    cls
    py $PWBRoot\\pwb.py pagefromfile -file:$WikiPageFileUTF8 -notitle -force -pt:0
    cls
    py $PWBRoot\\pwb.py pagefromfile -file:$WikiPageMexFileUTF8 -notitle -force -pt:0
    cls
}
