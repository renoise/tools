# Duplex.Applications.Keyboard

< Back to [Applications](../Applications.md)

## About

The Duplex Keyboard is a flexible keyboard replacement for Renoise. It offers the following extra features

* Supports pad/grid controllers and OSC devices
* In grid mode, offers customizable layouts (harmonic, isomorphic, etc.)
* Able to remap received mod-wheel/pitch bend message to CC messages (record as automation)
* Can interpret an(y) incoming message as mod-wheel/pitch-bend
* Does split-keyboard layouts, routing to instruments and tracks. 

## Prerequisites

The Keyboard application will not work unless you have enabled the internal OSC server in Renoise (Renoise prefereces -> OSC settings). It should be set to "UPD" protocol, and use the same port as specified in Duplex/Globals.lua (by default, this is set to the same value as Renoise, "8000").

## How it works 

The Keyboard application can be used as a standard keyboard (visulized as black & white keys in the virtual control surface), or as individually-mapped keys/pads, suitable for grid and pad controllers.

![Keyboard_devices](../Images/Keyboard_devices.png)

**Keyboard Mode**  
When you are using the application in the standard keyboard mode, it might receive pitch bend and channel pressure information from the device, which can then be A) ignored, B) broadcast as MIDI (unchanged), C) or routed internally to any MIDI CC message (this in turn means that you can easily use the native MIDI mapping in Renoise to map the pitch bend to any parameter) 

Furthermore, since we are using internally-triggered notes we have the ability to trigger notes inside a specific track, using a specific instrument. The default setting is identical to the standard behavior in Renoise, and will simply use the currently selected track/instrument. But it's possible to select any track or instrument by specifying it in the options.
 
Note that you can stack multiple Keyboard applications to control/trigger multiple instruments with a single master keyboard. The "MIDI-Keyboard" device comes with a configuration that demonstrate this ("Stacked Keys"), in which three instrument are triggered, each with different settings.

**Grid Mode**  
In grid mode, the Keyboard application is able to visualize the currently selected instrument's keyzone/sample mappings in realtime. This makes it a lot easier to see exactly where each sound is located, and even works as you are moving mappings around, or transposing the keyboard (octave up/down). 

![Keyboard_sample_mappings](../Images/Keyboard_sample_mappings.png)

Also, all of the UISlider mappings (volume, octave, pitch bend, etc.) support grid mode, as their mappings can be mapped to buttons just as easily as they can be mapped to a physical slider or fader. 

Furthermore, the grid mode supports a number of different layouts. Each one has it's own character,
and will invite to different playing styles: 
 
**Harmonic**: choose this layout if you are playing an instrument within a specific harmonic scale.
Left and right are the keys within the scale, up and down will move through octaves.
 
**Isomorphic**: this layout is nice if you want to reach all notes (not restricted to a harmonic scale).
Specific finger patterns will result in specific chords, no matter where you press. 
 
**Piano**: this is a "piano style" layout, useful if you are used to playing a traditional piano but otherwise
not really advisable (it takes up a lot of space to have separate rows of black and white keys). 
 
**Harmonic scales and keys**  
Here is an image that show how each layout will respond to a harmonic scale.
See how the harmonic layout is the only one without redundant pitches?

![Keyboard_scale_harmonic](../Images/Keyboard_scale_harmonic.gif)

In this image, we are setting the scale key to every possible value.

![Keyboard_scale_isomorphic](../Images/Keyboard_scale_isomorphic.gif)

Setting the scale key does not simply transpose the notes - it pushes the scale upwards by the
selected number of semitones. As a result, the trigger pad/button might be assigned to a different
pitch (generally speaking, you do not want to apply a harmonic scale to the isomorphic layout.
It only seemed like a good idea for this screenshot, as it clearly demonstrates what is happening). 

**Additional Features**

* Voice-manager: the foundation for some of the more advanced features, basically it keeps track of
the currently playing notes, their designated instrument and track + it eliminates the potential problem
of stuck notes when you're changing octave from within Renoise while pressing one or more keys
* Upper and lower range, to create a split keyboard (so you don't have to edit your instrument to achieve this)

## Links

Tool discussion is located on the [Renoise forum](http://forum.renoise.com/index.php?/topic/33806-new-tool-duplex-keyboard/)

## Available mappings
  
| Name       | Description   |
| -----------|---------------|  
|`track_sync`|Keyboard: sync track with Renoise|  
|`volume_sync`|Keyboard: sync volume with Renoise|  
|`key_grid`|Keyboard: trigger notes using buttons or pads|  
|`track_set`|Keyboard: set active keyboard track|  
|`volume`|Keyboard: volume control|  
|`keys`|Keyboard: trigger notes using keyboard|  
|`instr_set`|Keyboard: set active keyboard instrument|  
|`octave_down`|Keyboard: transpose keyboard down|  
|`mod_wheel`|Keyboard: mod wheel|  
|`cycle_layout`|Keyboard: cycle between available layouts|  
|`all_notes_off`|Keyboard: stop all playing notes|  
|`pressure`|Keyboard: channel pressure|  
|`octave_up`|Keyboard: transpose keyboard up|  
|`octave_sync`|Keyboard: sync octave with Renoise|  
|`octave_set`|Keyboard: set active keyboard octave|  
|`instr_sync`|Keyboard: sync instrument with Renoise|  
|`pitch_bend`|Keyboard: pitch-bend wheel|  

## Default options 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Description   |
| ------------- |---------------|  
|`mod_wheel`|Determine how to treat incoming mod wheel messages|  
|`release_type`|Determine how to respond when the same key is triggered<br>multiple times without being released inbetween hits: <br>'wait' means to wait until all pressed keys are released, <br>'release when possible' will use the first opportunity to <br> release the note (enable if you experience stuck notes)|  
|`button_width`|Specify the button width (when in grid mode)|  
|`base_volume`|Determine how to control keyboard volume|  
|`keyboard_mode`|Determine how notes should be triggered|  
|`lower_note`|Specify a note as lower boundary|  
|`pitch_bend`|Determine how to treat incoming pitch bend messages|  
|`channel_pressure`|Determine how to treat incoming channel pressure|  
|`base_octave`|Specify the default starting octave|  
|`velocity_mode`|Determine how to act on velocity range (the range specified in the control-map)|  
|`button_height`|Specify the button height (when in grid mode)|  
|`instr_index`|Choose which instrument to control|  
|`grid_layout`|Specify a keyboard layout for the grid|  
|`grid_labelling`|Choose how notes are displayed in the grid|  
|`grid_highlight`|Choose what to highlight in the grid<br>1: `"No highlighting"`<br>2: `"Highlight base-key"`<br>3: `"Highlight sample mappings"`|  
|`upper_note`|Specify a note as upper boundary|  
|`track_index`|Choose which track to use |  

## Default palette 
  
> Can be overridden in [configurations](../Configurations.md)

| Name          | Color|Text|Value|
| ------------- |------|----|-----|  
|`volume_sync_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|·|false|  
|`key_released`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|·|false|  
|`key_out_of_bounds`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|·|false|  
|`volume_sync_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|■|true|  
|`all_notes_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|⚡|false|  
|`slider_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#C08080; color: black">0xC0,0x80,0x80</div>|·|false|  
|`cycle_layout_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>||false|  
|`key_pressed`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|·|true|  
|`cycle_layout_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>||true|  
|`all_notes_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|⚡|true|  
|`track_sync_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|■|true|  
|`slider_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFC0FF; color: black">0xFF,0xC0,0xFF</div>|▪|true|  
|`octave_sync_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|·|false|  
|`octave_up_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|+12|false|  
|`instr_sync_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|■|true|  
|`octave_down_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|-12|true|  
|`octave_sync_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|■|true|  
|`octave_up_on`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|+12|true|  
|`key_released_selected`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#808040; color: white">0x80,0x80,0x40</div>|·|false|  
|`octave_down_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|-12|false|  
|`track_sync_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|·|false|  
|`key_released_content`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#404040; color: white">0x40,0x40,0x40</div>|·|false|  
|`key_pressed_content`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#FFFFFF; color: black">0xFF,0xFF,0xFF</div>|·|true|  
|`instr_sync_off`|<div style="padding-left:0.5em;padding-right:0.5em; background-color:#000000; color: white">0x00,0x00,0x00</div>|·|false|  

## Changelog

1.04
- Added: grid display options : key/sample highlighting + note labelling
- Fixed: HarmonicWrapped layout + scales no longer shows duplicate notes

1.01
- Tool-dev: use cLib/xLib libraries
- Added: HarmonicWrapped grid layout 
- Tweaked Launchpad configuration

0.99.4
- Support for Renoise 3 trigger options (hold/mono modes)
- Custom grid layouts (harmonic, isomorphic layout and piano emulation)

0.99.2
- Adapted to UIKey changes 
- New mapping: mod_wheel

0.98.32
- TWEAK: velocity now is set to an explicit value, or synced to Renoise keyboard 
  velocity will output a fixed velocity (previously it was relative to messages)

0.98.16
- Display message on how to enable OSC server (first time only)

0.98.15
- New option: “Keyboard Mode”, choose which notes (if any) to trigger

0.98 
- First release 