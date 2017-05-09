# Duplex.Applications.Repeater

< Back to [Applications](../Applications.md)

## About

The Duplex Repeater application allows you to take control of any repeater DSP device in a Renoise song.  

## Features
* Jump between different repeater devices in the song
* Remember focused device between sessions
* Built-in automation recording 

## Example configuration

![Repeater_on_remote_sl.png](../Images/Repeater_on_remote_sl.png)  
*The Duplex Repeater configuration for the Remote SL MKII*

## Available mappings
  

| Name       | Description   |
| -----------|---------------|  
|`mode_dotted`|Repeater: Set mode to 'dotted'|  
|`lock_button`|RoamingDSP: Lock/unlock device|  
|`grid`|Repeater: button grid|  
|`next_device`|RoamingDSP: Next device|  
|`prev_device`|RoamingDSP: Previous device|  
|`mode_slider`|Repeater: Control mode using a fader/knob|  
|`divisor_slider`|Repeater: Control divisor using a fader/knob|  
|`mode_free`|Repeater: Set mode to 'free'|  
|`mode_even`|Repeater: Set mode to 'even'|  
|`mode_triplet`|Repeater: Set mode to 'triplet'|  

## Default options 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Description   |
| ------------- |---------------|  
|`mode_select`|Determine the working mode of the grid:<br>Free: scale between 1/1 and 1/128<br>Even: display only 'even' divisors<br>Triplet: display only 'triplet' divisors<br>Dotted: display only 'dotted' divisors<br>Automatic: display 'even','triplet' and 'dotted' <br>  divisors, each on a separate line (automatic layout)|  
|`record_method`|Determine if/how to record automation |  
|`follow_pos`|Follow the selected device in the DSP chain|  
|`locked`|Disable locking if you want the controls to<br>follow the currently selected device |  
|`hold_option`|Determine what to do when a button is released|  
|`divisor_max`|Specify the minimum divisor value|  
|`divisor_min`|Specify the minimum divisor value|  

## Default palette 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Color|Text|Value|
| ------------- |------|----|-----|  
|`disabled`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>||false|  
|`mode_even_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|E|true|  
|`mode_triplet_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|T|true|  
|`prev_device_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|◄|true|  
|`prev_device_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|◄|false|  
|`mode_dotted_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|D|true|  
|`mode_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|■|true|  
|`mode_free_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|F|false|  
|`enabled`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>||true|  
|`next_device_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|►|true|  
|`mode_free_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|F|true|  
|`mode_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|·|false|  
|`mode_even_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|E|false|  
|`lock_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|♥|true|  
|`next_device_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|►|false|  
|`mode_dotted_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|D|false|  
|`lock_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|♥|false|  
|`mode_triplet_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|T|false|  

## Changelog

1.01
- Tool-dev: use cLib/xLib libraries
- High-res automation recording (interleaved or punch-in)

0.98
- First release


