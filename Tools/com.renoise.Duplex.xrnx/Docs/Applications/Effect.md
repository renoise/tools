# Duplex.Applications.Effect

## Features

* Access every parameter of every effect device (including plugins)
* Flip through parameters using paged navigation
* Select between devices using a number of fixed buttons
* Enable grid-controller mode by assigning "parameters" to a grid
* Parameter subsets make it possible to control only certain values
* Supports automation recording 

## Changelog

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

