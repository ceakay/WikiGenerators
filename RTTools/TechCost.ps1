###SET CONSTANTS
###
#RogueTech Dir (Where RTLauncher exists)
$RTroot = "D:\\RogueTech"
#Script Root
$RTScriptroot = "D:\\RogueTech\\WikiGenerators"
cd $RTScriptroot
#cache path
$CacheRoot = "$RTroot\\RtlCache\\RtCache"
$MinorCatPath = $CacheRoot+"\\RogueTech Core\\categories"

#masterfile
$EquipFile = $RTScriptroot+"\\Outputs\\GearTable.json"


$ComponentObjectList = [System.Collections.ArrayList]@($(Get-Content $EquipFile -Raw | ConvertFrom-Json))

foreach ($Mod in $($($ComponentObjectList | group {$_.Wiki.Mod}).Name)) {
    $ComponentObjectList | ? {$_.Wiki.Mod -eq $Mod} | select @{N='ID'; E={$_.Description.ID}}, @{N='Mod'; E={$_.Wiki.Mod}}, @{N='ModSubFolder'; E={$_.Wiki.ModSubFolder}}, @{N='Default'; E={$_.Custom.WorkOrderCosts.Default.TechCost}}, @{N='Install'; E={$_.Custom.WorkOrderCosts.Install.TechCost}}, @{N='Repair'; E={$_.Custom.WorkOrderCosts.Repair.TechCost}}, @{N='RepairDestroyed'; E={$_.Custom.WorkOrderCosts.RepairDestroyed.TechCost}}, @{N='Remove'; E={$_.Custom.WorkOrderCosts.Remove.TechCost}}, @{N='RemoveDestroyed'; E={$_.Custom.WorkOrderCosts.RemoveDestroyed.TechCost}} | ConvertTo-Csv -NoTypeInformation | Out-File "D:\RogueTech\Workspace\TechCost-$Mod.csv" -Encoding utf8
}

$ComponentObjectList | select @{N='ID'; E={$_.Description.ID}}, @{N='Mod'; E={$_.Wiki.Mod}}, @{N='ModSubFolder'; E={$_.Wiki.ModSubFolder}}, @{N='Default'; E={$_.Custom.WorkOrderCosts.Default.TechCost}}, @{N='Install'; E={$_.Custom.WorkOrderCosts.Install.TechCost}}, @{N='Repair'; E={$_.Custom.WorkOrderCosts.Repair.TechCost}}, @{N='RepairDestroyed'; E={$_.Custom.WorkOrderCosts.RepairDestroyed.TechCost}}, @{N='Remove'; E={$_.Custom.WorkOrderCosts.Remove.TechCost}}, @{N='RemoveDestroyed'; E={$_.Custom.WorkOrderCosts.RemoveDestroyed.TechCost}} | ConvertTo-Csv -NoTypeInformation | Out-File "D:\RogueTech\Workspace\TechCost.csv" -Encoding utf8