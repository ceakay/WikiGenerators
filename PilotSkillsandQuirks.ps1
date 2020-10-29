###FUNCTIONS
#data chopper function
    #args: delimiter, position, input, backup position
function datachop {
    $array = @($args[2] -split "$($args[0])")
    if (($array.Count -le $args[1]) -and (-not !$args[3])) {
        return $array[$args[3]]
    }
    else {
        return $array[$args[1]]
    }
}

#SET CONSTANTS
###
#RogueTech Dir (Where RTLauncher exists)
$RTroot = "D:\\RogueTech"
#Script Root
$RTScriptroot = "D:\\RogueTech\\WikiGenerators"
cd $RTScriptroot
#cache path
$CacheRoot = "$RTroot\\RtlCache\\RtCache"
$QuirksFile = "$CacheRoot\\MechAffinity\\settings.json"
$AbilitiesFolder = "$CacheRoot\\Abilifier\\abilities"
$QuirksMasterObject = Get-Content $QuirksFile -Raw | ConvertFrom-Json
$PilotQuirks = $QuirksMasterObject.pilotQuirks | sort quirkName

$PilotQuirkText = @"
{{-start-}}
'''Pilot Skills and Quirks'''
This page provides overview of mechwarriors passive/active Skills and Quirks in the RogueTech mod:

* Reworked skill tree with additional bonuses provided to mechwarriors
* Reworked abilities
* Mechwarrior/Pilot quirks now provide benefits or penalties to various skills and other benefits

Pilots can also earn [[Unit Affinities]] as they become more familiar with mechs and vehicles. These specializations provide larger bonuses as a pilot becomes more familiar with their unit(s).

= Resetting the Skill Tree =
To reset the skill tree, SHIFT+LMB the Skills Tab. This will cost 500K, and requires Training Module 2. 

''aka Reskill, Re-skill, change skill, respec, retrain''

= Skill Tree =
== Passive Roll Bonus (PRB)==
Each point in a skill provides a passive bonus to rolls, and can go beyond the 10 through additional equipment and pilot's quirks.

* Gunnery: Accuracy, Weapon Jamming
* Piloting: Initiative, Melee
* Guts: Panic, Injury Resist, Heat (i.e. Shutdown Override, Ammo Explosion, etc.)
* Tactics: Sensor, Initiative

Special article on [[How Gunnery Affects CTH]], since the maths is ''special''.

In addition to these passive bonuses, there are other explicit bonuses. See the Skills Table below.

== Skills Table ==

{| class="wikitable"
! colspan="2" |
!1
!2
!3
!4
!5
!6
!7
!8
!9
!10
|-
! rowspan="3" |<small>Gunnery</small>
!<small>Base CTH%</small>
|<small>+1%</small>
|<small>+2%</small>
|<small>+3%</small>
|<small>+4%</small>
|<small>+5%</small>
|<small>+6%</small>
|<small>+7%</small>
|<small>+8%</small>
|<small>+9%</small>
|<small>+10%</small>
|-
!<small>Jam Chance</small>
|<small>-1%</small>
|<small>-2%</small>
|<small>-3%</small>
|<small>-4%</small>
|<small>-5%</small>
|<small>-6%</small>
|<small>-7%</small>
|<small>-8%</small>
|<small>-9%</small>
|<small>-10%</small>
|-
!<small>Unjam Chance</small>
|<small>+10%</small>
|<small>+20%</small>
|<small>+30%</small>
|<small>+40%</small>
|<small>+50%</small>
|<small>+60%</small>
|<small>+70%</small>
|<small>+80%</small>
|<small>+90%</small>
|<small>+100%</small>
|-
! rowspan="2" |<small>Piloting</small>
!<small>Melee Accuracy</small>
|<small>+2%</small>
|<small>+4%</small>
|<small>+6%</small>
|<small>+8%</small>
|<small>+10%</small>
|<small>+12%</small>
|<small>+14%</small>
|<small>+16%</small>
|<small>+18%</small>
|<small>+20%</small>
|-
!<small>Initiative Randomness</small>
|
|<small>-1</small>
|
|<small>-2</small>
|
|<small>-3</small>
|
|<small>-4</small>
|
|<small>-5</small>
|-
! rowspan="1" |<small>Guts</small>
!<small>Resist:<br>Initiative,&nbsp;Injury,&nbsp;& Melee</small>
|
|<small>1</small>
|
|<small>2</small>
|
|<small>3</small>
|
|<small>4</small>
|
|<small>5</small>
|-
! rowspan="1" |<small>Tactics</small>
!<small>Initiative, Reduced&nbsp;Hesitation</small>
|
|<small>1</small>
|
|<small>2</small>
|
|<small>3</small>
|
|<small>4</small>
|
|<small>5</small>
|}

== Abilities ==
The table below provides overview of active skills in the RogueTech. There are two types:
* Passive: these skills are always 'on' and apply their bonuses.
* Active: these skills require to be activated to apply their bonuses, but do not end turn. 

{| class="wikitable"
!
!Tier
!Abilities
!Description
|-
! rowspan="4" |Gunnery
! rowspan="2" |Level 5</br>Passive
!Bandit
|
* Critical Strike Chance Increase: 25%
* Clustering Roll Modifiers: +6
|-
!Focus Fire</br><small>Passive</small>
|
* Improved Called Shot Multiplier: 6% 
* Recoil: -1
|-
! rowspan="2" |Level 8</br>Active
!Warlord
|
* Accuracy: +1
* Clustering Roll Modifiers: +10
* Improved Called Shot Multiplier: 10%
* Cooldown: 3 turns
|-
!Controlled Bursts
|
* Heat Generated: -10%, 2 turns
* Recoil: -1, 2 turns
* Cooldown: 3 Turns
|-
! rowspan="4" |Piloting
! rowspan="2" |Level 5</br>Passive
!Awareness
|
* Evasive Pips are immune to sensor locks
|-
!Escapist
|
* Max Evasive Pips: +2
|-
! rowspan="2" |Level 8</br>Active
!Mobility
|
* Walk MovePoints: +1
* Cooldown: 3 Turns
|-
!Phantom Mech
|
* ECM: +2, 2 turns
* Visibility and Sensor Signatures: -50%, 2 turns
* Cooldown: 3 turns
|-
! rowspan="4" |Guts
! rowspan="2" |Level 5</br>Passive
!Hardcase
|
* Stability Damage Taken: -10%
|-
!Juggernaut
|
* Initiative, Injury, and Melle Resist: +1
* Braces afer Melee and DFA
|-
! rowspan="2" |Level 8</br>Active
!Berserker
|
* For All Melee Attacks:
** Accuracy: +1
** Damage: +20%
** Charge Self Damage: -10%
** DFA Self Damage: -15%
* Cooldown: 3 turns
|-
!Coolant Vent
|
* Heat Sink Capacity: +60
* Cooling Penalty: -30, 3 turns
** Cooling improves by 10 each turn until recovered.
* Cooldown: 4 turns
|-
! rowspan="4" |Tactics
! rowspan="2" |Level 5</br>Passive
!Cautious
|
* Stability Bars Removed When Reserving: 1
* Initiative and Tactics Rolls: +1
|-
!Tactician
|
* Maximum Sight/Sensor Distance: +15%
* Initiative and Tactics Rolls: +1
|-
! rowspan="2" |Level 8</br>Active
!Field Command
|
* All player units gain:
** Sensors: +1, 2 turns
** Sensors/Sight Distance: +15%, 2 turns
* Initiative and Tactics Rolls: +1
* Cooldown: 3 turns
|-
!Sensor Lock
|
* Target 1 enemy unit in sensor range
** Revealed until end of round
** 1 Evasive Pip removed
** Sensor Signature and Visibility: +100%
* Initiative and Tactics Rolls: +1
* DOES NOT END YOUR TURN
|}

== Pilot Quirks ==
The table below provides an overview of the mechwarrior quirks.

{| class="wikitable"
!Quirk
!Description
"@

foreach ($PilotQuirk in $PilotQuirks) {
    $PilotQuirkText += "`r`n|-`r`n| $($PilotQuirk.quirkName)`r`n| $($PilotQuirk.description)"
}
$PilotQuirkText += "`r`n|}`r`n{{-stop-}}"

$OutFile = "D:\\RogueTech\\WikiGenerators\\Outputs\\PilotSkillsandQuirks.UTF8"
$PilotQuirkText | Set-Content -Encoding UTF8 $OutFile
$PWBRoot = "D:\\PYWikiBot"
py $PWBRoot\\pwb.py pagefromfile -file:$OutFile -notitle -force -pt:0