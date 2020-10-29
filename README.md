# WikiGenerators
Powershell scripts for RogueTech.gamepedia.com

Requires PyWikiBot (PWB) - https://help.gamepedia.com/Pywikibot

Requires Powershell 5.1 (Might work on earlier versions, who the hell knows)

Generally divided into two script categories. 
- Parser: to parse JSONs and trim out required information (make objects workable)
- Transcode: Turns objects into wikimedia markup compatible with GamePedia, and upload via PWB.
- Push: Script to run it all. Fire and Forget. 

What you need from here: 
- Scripts: PARSER, TRANSCODE, PUSH
- Entire Inputs folder. This folder contains some manual inputs that can be customized. Most settings and overrides exist in the CSVs here. The blurb text files are self-explanitory. Some overrides exist in the scripts themselves - check SettingsReadme.txt
