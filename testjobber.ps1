$PageText = $null

$somehash = @{}

for ($i=0; $i -lt 100; $i++) {
    $PageText += "{{-start-}}`r`nPage $i`r`n##ReplaceMe$i##`r`n{{-stop-}}`r`n"
    $somehash.Add($i,'yay!')
    #Start-Job -Name "BigTable$i" -ScriptBlock {}
}


for ($i=0; $i -lt 100; $i++) {
    $PageText = $PageText.Replace("##ReplaceMe$i##",$($somehash.$i)+$i)
    #Start-Job -Name "BigTable$i" -ScriptBlock {}
}
