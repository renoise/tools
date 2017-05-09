# Duplex.Applications.MidiActions

< Back to [Applications](../Applications.md)

## About 

MidiActions will expose standard Renoise mappings as fully bi-directional mappings, with customizable scaling (exponential, logarithmic, linear) and range. 

By parsing the GlobalMidiActions file, it literally provides access to hundreds of features inside Renoise, such as BPM, LPB, and even UI view presets. You will have to map each feature manually, but only once - once mapped, the target will remain accessible. 

## Available mappings
  
| Name       | Description   |
| -----------|---------------|  
|`control`|MidiActions: designated control|  

## Default options 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Description   |
| ------------- |---------------|  
|`scaling`|Determine the output scaling|  
|`min_scaling`|Determine the minimum value to output|  
|`action`|List of supported MIDI actions (GlobalMidiActions.lua)|  
|`max_scaling`|Determine the maximum value to output|  

## Default palette 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Color|Text|Value|
| ------------- |------|----|-----|  
|`inactive`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|·|false|  
|`active`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|■|true|  

## Changelog

1.01
- Tool-dev: use cLib/xLib libraries

0.xx
- Initial release
