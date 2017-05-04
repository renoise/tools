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
    | |Write| |Learn| |Fill| |Global| |Modes...|    | <- Various controls
    | ______________________________________________|

Also, check out the compact version, which use fewer controls, but still manages to contain every feature of it's bigger brother. This is possible because the sliders in that version are switching between the currently active mode (pitch, velocity etc.), and therefore, require only a small set of physical controls. Perhaps it's a more realistic starting point for your own controller mapping than the fully expanded version? It's located here: 
Duplex > Custombuilt > Notes On Wheels (compact)


## Discuss

Tool discussion is located on the [Renoise forum](http://forum.renoise.com/index.php?/topic/31136-notes-on-wheels-now/)


## Available mappings

| Name       | Description   |
| -----------|---------------|
|`choose_mode`|NOW: Choose mode|  
|`extend`|NOW: Repeat sequence twice|  
|`fill`|NOW: Fill entire track (can be very CPU intensive, use with caution!!)|  
|`gate_adjust`|NOW: Adjust note length for all steps|  
|`gate_sliders`|NOW: Change gate/duration for step |  
|`global`|NOW: Toggle between global/parameter-only output|  
|`learn`|NOW: Import sequence from pattern|  
|`multi_adjust`|NOW: Adjust all steps (mode-dependant)|  
|`multi_sliders`|NOW: Mode-dependant slider|  
|`num_steps`|NOW: Number of steps|  
|`offset_adjust`|NOW: Adjust sample-offset for all steps|  
|`offset_sliders`|NOW: Change sample-offset for step |  
|`pitch_adjust`|NOW: Transpose all steps|  
|`pitch_sliders`|NOW: Change pitch for step |  
|`position`|NOW: Displays position within sequence|  
|`retrig_adjust`|NOW: Adjust retriggering for all steps|  
|`retrig_sliders`|NOW: Change number of retrigs for step |  
|`set_mode_gate`|NOW: Set mode to 'duration'<br>Hold to write sequence to entire pattern|  
|`set_mode_offset`|NOW: Set mode to 'offset'<br>Hold to write sequence to entire pattern|  
|`set_mode_pitch`|NOW: Set mode to 'pitch'<br>Hold to write sequence to entire pattern|  
|`set_mode_retrig`|NOW: Set mode to 'retrigger)<br>Hold to write sequence to entire pattern|  
|`set_mode_velocity`|NOW: Set mode to 'velocity'<br>Hold to write sequence to entire pattern|  
|`shift_down`|NOW: Increase line offset|  
|`shift_up`|NOW: Decrease line offset|  
|`shrink`|NOW: Reduce sequence to half the size|  
|`step_spacing`|NOW: Line-space between steps|  
|`velocity_adjust`|NOW: Adjust volume for all steps|  
|`velocity_sliders`|NOW: Change velocity for step |  
|`write`|NOW: Write to pattern in realtime|  

## Available options

| Name       | Description   |
| -----------|---------------|
|`edit_sync`|Output to pattern while edit-mode (red border in Renoise) is active|  
|`fill_mode`|Enable to extend output to the entire track|  
|`global_mode`|Enable to start in global mode (output all parameters/steps)|  
|`midi_keyboard`|Use an external MIDI keyboard to control pitch/transpose|  
|`offset_quantize`|Specifies number of possible sample-offset (9xx) commands|  
|`offset_wrap`|Determine adjusting the sample-offset will wrap values or not|  
|`write_method`|Determine how to write to the pattern<br>TOUCH [1] will only output notes while the controller is being used<br>LATCH [2] will start output once the controller is being used<br>WRITE [3] will output notes continously, no matter what|  

## Changelog

0.98  
- First release


