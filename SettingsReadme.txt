Any settings or manual mid-code overrides in the code can be found here. Search for the comments to find the relevant sections. 
Any additional help can be found after '>>'

==RT Mech Parser==
##Variant override
#custom override for ZEUX0003
>> Variant name weirdness in the defs. 

#convert to proto to power
>> merges protomech class into powerarmor class for tabling. 

#Plasma Beak
>> mech mis-classed

#Simple Omni Overrides
>> See \inputs\omnioverrides.csv
>> Some omnimechs have same chassis names as non-omni. overrides their ChassisName with new one. 

#Simple Unique to Chassis Override
>> see \inputs\ucoverrides.csv
>> Some mechs should have unique names override their defined chassis names

#RFL-3N (C) cleanup
>> cleans up weirdness

#KERES cleanup
>> cleans up weirdness

#Beetle Drone
>> trans

#Comet Scream
>> form

#Sounder // Lambor
>> ers

#Grimdark
>> ro

#Noise jammer
>> bots

#Noise jammer
>> in

#Optimus
>> disguise!

#Avatar fuckiness
>> Avatar chassis names beinng fucky. using variant code to override

==RT Tank Parser==

#HPValueMod is for the dynamic math to change actual combat values.
>> 2x multiplier numbers for dynamic combat vehicle hp buff

#SuperHeavy override
>> override vehicle class by weight or tag

#VTOL weight defs override
>> override vtol classes

#Red October Override
>> fucky chassis name

==RT Gear Parser==
>> n/a

==RT Mech Wiki Transcode== 
#disable when testing!
>> pywikibot do upload. $true enables. $false disables

==RT Tank Wiki Transcode==
#disable when testing!
>> pywikibot do upload. $true enables. $false disables

