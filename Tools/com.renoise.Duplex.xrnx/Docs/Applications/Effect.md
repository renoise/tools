# Duplex.Applications.Effect

## Features

* Access every parameter of every effect device (including plugins)
* Flip through parameters using paged navigation
* Select between devices using a number of fixed buttons
* Enable grid-controller mode by assigning "parameters" to a grid
* Parameter subsets make it possible to control only certain values
* Supports automation recording 

## Available mappings
  
| Name       | Description   |
| -----------|---------------|  
|`param_prev`|Effect: Previous Parameter page|  
|`device_prev`|Effect: Select previous device|  
|`device`|Effect: Select among devices via buttons|  
|`preset_next`|Effect: Select next device preset|  
|`parameters`|Effect: Parameter value|  
|`param_active`|(UILed...) Display active parameter|  
|`device_name`|Effect: Display device name|  
|`param_next`|Effect: Next Parameter page|  
|`device_select`|Effect: Select device via knob/slider|  
|`preset_prev`|Effect: Select previous device preset|  
|`device_next`|Effect: Select next device|  
|`param_values`|Effect: Display parameter value|  
|`param_names`|Effect: Display parameter name|  

## Default options 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Description   |
| ------------- |---------------|  
|`record_method`|Determine if/how to record automation |  
|`include_parameters`|Select which parameter set you want to control.|  

## Default palette 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Color|Text|Value|
| ------------- |------|----|-----|  
|`device_nav_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|·|false|  
|`slider_background`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#004000; color: white">0x00,0x40,0x00</div>|·|false|  
|`slider_tip`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|·|true|  
|`prev_device_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|◄|true|  
|`prev_device_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|◄|false|  
|`background`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|·|false|  
|`slider_track`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|·|true|  
|`next_device_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|►|true|  
|`next_preset_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|►|false|  
|`device_nav_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|■|true|  
|`prev_param_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|◄|false|  
|`parameter_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>||false|  
|`next_param_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|►|false|  
|`parameter_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>||true|  
|`next_param_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|►|true|  
|`prev_param_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|◄|true|  
|`next_preset_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|►|true|  
|`prev_preset_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|◄|true|  
|`prev_preset_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|◄|false|  
|`next_device_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|►|false|  

## Changelog

1.01
- Tool-dev: use cLib/xLib libraries
- High-res automation recording (interleaved or punch-in)

0.99.?? by Eran Dax Lonker
- Added: possibilty to set an index for the group (for instance: you start with the second knob in group for the parameters and the first one is for device browsing) 

0.99.xx
- New mapping: "param_active" (UILed, enabled/working parameters)

0.98.27
- New mapping: “device_name” (UILabel)
- New mappings: “param_names”,”param_values” (UILabels for parameters)
- New mappings: “param_next”,”param_next” (UIButtons, replaces UISpinner)

0.98.19
- Fixed: device-navigator now works after switching song/document

0.98  
- Support for automation recording
- New mapping: select device via knob/slider
- New mappings: previous/next device
- New mappings: previous/next preset

### 0.97  
- Better performance, as UI updates now happen in idle loop 
- Option to include parameters based on criteria 
  ALL/MIXER/AUTOMATED_PARAMETERS

### 0.95  
- Grid controller support (with configurations for Launchpad, etc)
- Seperated device-navigator group size from parameter group size
- Use standard (customizable) palette instead of hard-coded values
- Applied feedback fix, additional check for invalid meta-device values

0.92  
- Contextual tooltip support: show name of DSP parameter

0.91  
- Fixed: check if "no device" is selected (initial state)

0.90  
- Check group sizes when building application
- Various bug fixes

0.81  
- First release

