# Duplex.Applications.Rotate

< Back to [Applications](../Applications.md)

## About

The Duplex Rotate application allows you to rotate a track/pattern upwards or downwards, optionally including automation. The application is an implementation of taktik's [Rotate tool](http://tools.renoise.com/tools/rotate-pattern)

## Available mappings
  

| Name       | Description   |
| -----------|---------------|  
|`whole_pattern_down`|Rotate: nudge pattern down|  
|`whole_pattern_up`|Rotate: nudge pattern up|  
|`track_in_pattern_down`|Rotate: nudge track down|  
|`track_in_pattern_up`|Rotate: nudge track up|  

## Default options 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Description   |
| ------------- |---------------|  
|`shift_amount`|Number of lines to shift|  
|`shift_automation`|Choose whether to shift automation as well|  
    
## Default palette 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Color|Text|Value|
| ------------- |------|----|-----|  
|`up_dimmed`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#808080; color: white">0x80,0x80,0x80</div>|▲|false|  
|`up_bright`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|▲|true|  
|`down_dimmed`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#808080; color: white">0x80,0x80,0x80</div>|▼|false|  
|`up_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#404040; color: white">0x40,0x40,0x40</div>|▲|false|  
|`down_bright`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|▼|true|  
|`down_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#404040; color: white">0x40,0x40,0x40</div>|▼|false| 

### Changes

1.01
- Tool-dev: use cLib/xLib libraries

0.98
- First release
