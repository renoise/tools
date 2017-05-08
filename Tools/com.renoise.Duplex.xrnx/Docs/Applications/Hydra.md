# Duplex.Applications.Hydra

## Features

* Device locking
* Device navigation 
* Automation recording 
* Label for displaying the current value

## Available mappings
  
| Name       | Description   |
| -----------|---------------|  
|`next_device`|RoamingDSP: Next device|  
|`lock_button`|RoamingDSP: Lock/unlock device|  
|`value_display`|Hydra: display current value|  
|`input_slider`|Hydra: control value|  
|`prev_device`|RoamingDSP: Previous device|  

## Default options 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Description   |
| ------------- |---------------|  
|`locked`|Disable locking if you want the controls to<br>follow the currently selected device |  
|`follow_pos`|Follow the selected device in the DSP chain|  
|`record_method`|Determine if/how to record automation |  
|`interpolation`|Determine the shape of automation envelopes|  

## Default palette 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Color|Text|Value|
| ------------- |------|----|-----|  
|`prev_device_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|◄|false|  
|`next_device_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|►|true|  
|`lock_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|♥|false|  
|`lock_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|♥|true|  
|`next_device_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|►|false|  
|`prev_device_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|◄|true|  

## Changelog

1.01
- Tool-dev: use cLib/xLib libraries

0.98
- First release