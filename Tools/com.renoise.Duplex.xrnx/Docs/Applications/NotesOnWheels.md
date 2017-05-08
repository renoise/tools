# Duplex.Applications.NotesOnWheels

## About 

N.O.W. allows you to create a sequence and control all aspects of each step (such as the pitch, velocity etc.) in realtime. 

As for input, N.O.W. is very flexible, as you can control it via an additional MIDI input. Also, the virtual control surface will, when focused, detect and respond to keypresses within a specific range. 

The virtual keyboard supports both ordinary transpose (one octave up/down from the middle C), and multi-step sequences (press keys while holding the SHIFT modifier). Same goes for the external MIDI keyboard, which can be set up to act upon CC messages and pitch bend. 


### Controller setup

A dedicated control surface is located in the Renoise tools menu:
Duplex > Custombuilt > Notes On Wheels

    _________________________________________________
    |  _  _  _  _  _  _  _  _  _  _  _  _   _  _    | 
    | |_||_||_||_||_||_||_||_||_||_||_||_| |_||_|   | <- Position + Line offset
    |  _  _  _  _  _  _  _  _  _  _  _  _   ______  | 
    | (_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_) |__||__| | <- Pitch controls
    |  _  _  _  _  _  _  _  _  _  _  _  _   ______  | 
    | (_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_) |__||__| | <- Velocity controls
    |  _  _  _  _  _  _  _  _  _  _  _  _   ______  | 
    | (_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_) |__||__| | <- Offset controls
    |  _  _  _  _  _  _  _  _  _  _  _  _   ______  | 
    | (_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_) |__||__| | <- Gate controls
    |  _  _  _  _  _  _  _  _  _  _  _  _   ______  | 
    | (_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_) |__||__| | <- Retrigger controls
    |  _  _  _  _  _  _  _  _  _  _  _  _   _  _    | 
    | |_||_||_||_||_||_||_||_||_||_||_||_| (_)(_)   | <- Steps + Spacing/Length
    |                                               |
    | |Write| |Learn| |Fill| |Global| |Modes.. |    | <- Various controls
    | ______________________________________________|

Also, check out the compact version, which use fewer controls, but still manages to contain every feature of it's bigger brother. This is possible because the sliders in that version are switching between the currently active mode (pitch, velocity etc.), and therefore, require only a small set of physical controls. Perhaps it's a more realistic starting point for your own controller mapping than the fully expanded version? It's located here: 
Duplex > Custombuilt > Notes On Wheels (compact)


## Discuss

Tool discussion is located on the [Renoise forum](http://forum.renoise.com/index.php?/topic/31136-notes-on-wheels-now/)


## Available mappings
  

| Name       | Description   |
| -----------|---------------|  
|`retrig_sliders`|NOW: Change number of retrigs for step |  
|`choose_mode`|NOW: Choose mode|  
|`multi_sliders`|NOW: Mode-dependant slider|  
|`shrink`|NOW: Reduce sequence to half the size|  
|`shift_up`|NOW: Decrease line offset|  
|`velocity_adjust`|NOW: Adjust volume for all steps|  
|`shift_down`|NOW: Increase line offset|  
|`pitch_adjust`|NOW: Transpose all steps|  
|`global`|NOW: Toggle between global/parameter-only output|  
|`step_spacing`|NOW: Line-space between steps|  
|`fill`|NOW: Fill entire track (can be very CPU intensive, use with caution!!)|  
|`set_mode_pitch`|NOW: Set mode to 'pitch'<br>Hold to write sequence to entire pattern|  
|`set_mode_gate`|NOW: Set mode to 'duration'<br>Hold to write sequence to entire pattern|  
|`set_mode_offset`|NOW: Set mode to 'offset'<br>Hold to write sequence to entire pattern|  
|`learn`|NOW: Import sequence from pattern|  
|`set_mode_velocity`|NOW: Set mode to 'velocity'<br>Hold to write sequence to entire pattern|  
|`write`|NOW: Write to pattern in realtime|  
|`gate_sliders`|NOW: Change gate/duration for step |  
|`pitch_sliders`|NOW: Change pitch for step |  
|`multi_adjust`|NOW: Adjust all steps (mode-dependant)|  
|`num_steps`|NOW: Number of steps|  
|`retrig_adjust`|NOW: Adjust retriggering for all steps|  
|`gate_adjust`|NOW: Adjust note length for all steps|  
|`set_mode_retrig`|NOW: Set mode to 'retrigger)<br>Hold to write sequence to entire pattern|  
|`position`|NOW: Displays position within sequence|  
|`extend`|NOW: Repeat sequence twice|  
|`offset_sliders`|NOW: Change sample-offset for step |  
|`velocity_sliders`|NOW: Change velocity for step |  
|`offset_adjust`|NOW: Adjust sample-offset for all steps|  

## Default options 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Description   |
| ------------- |---------------|  
|`global_mode`|Enable to start in global mode (output all parameters/steps)|  
|`fill_mode`|Enable to extend output to the entire track|  
|`edit_sync`|Output to pattern while edit-mode (red border in Renoise) is active|  
|`write_method`|Determine how to write to the pattern|  
|`midi_keyboard`|Use an external MIDI keyboard to control pitch/transpose|  
|`offset_wrap`|Determine adjusting the sample-offset will wrap values or not|  
|`offset_quantize`|Specifies number of possible sample-offset (9xx) commands|  

## Default palette 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Color|Text|Value|
| ------------- |------|----|-----|  
|`set_velocity_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|Velocity|true|  
|`fill_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|Fill|true|  
|`set_gate_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|Gate|true|  
|`set_velocity_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|Velocity|false|  
|`set_retrig_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|Retrig|false|  
|`set_pitch_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|Pitch|true|  
|`shift_down_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|↓|false|  
|`learn_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|Learn|true|  
|`shrink_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|½|false|  
|`shift_down_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|↓|true|  
|`set_retrig_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|Retrig|true|  
|`write_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|Write|false|  
|`fill_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|Fill|false|  
|`learn_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|Learn|false|  
|`set_offset_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|Offset|true|  
|`write_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|Write|true|  
|`global_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|Global|true|  
|`set_pitch_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|Pitch|false|  
|`global_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|Global|false|  
|`extend_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|x²|false|  
|`extend_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|x²|true|  
|`shrink_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|½|true|  
|`position_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|▫|false|  
|`position_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|▪|true|  
|`shift_up_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|↑|true|  
|`shift_up_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|↑|false|  
|`set_gate_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|Gate|false|  
|`set_offset_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|Offset|false|  

## Changelog

1.01
- Tool-dev: use cLib/xLib libraries
- Fixed: Allow unmapped phrases (API5)

0.99.1 
- Added: Phrase recording

0.98.32
- First release


