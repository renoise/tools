# Duplex.Applications.PatternSequence

## About

The PatternSequence application allows you to control the Renoise pattern-sequence.

## Available mappings

| Name       | Description   |
| -----------|---------------|  
|`display_previous`|PatternSequence: Display previous pattern<br>[Press] Go to previous pattern in song<br>[Hold] Go to first pattern in song|  
|`display_next`|PatternSequence: Display next pattern<br>[Press] Go to next pattern in song<br>[Hold] Go to last pattern in song|  

## Default options 
  
*This application has no options.*  

## Default palette 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Color|Text|Value|
| ------------- |------|----|-----|  
|`previous_disabled`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|▲|false|  
|`next_disabled`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|▼|false|  
|`next_enabled`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFF00; color: black">0xFF,0xFF,0x00</div>|▼|true|  
|`previous_enabled`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFF00; color: black">0xFF,0xFF,0x00</div>|▲|true|  

## Changelog

1.01
- Tool-dev: use cLib/xLib libraries

0.98.20 
- Initial version
