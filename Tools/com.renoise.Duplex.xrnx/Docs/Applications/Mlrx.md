# Duplex.Applications.Mlrx

## About

Mlrx is a live performance loop sequencer for Renoise, inspired by mlr by tehn. 
Due to it's grid-centric layout, Mlrx will only be fun to use if you have a grid/pad-controller. 

It comes with a comprehensive set of features:

* Independantly playing samples and/or phrases in any tempo
* Many triggering modes and options can be defined for each track
* Supports samples, sliced samples and phrases 
* "Streaming" output means seamless transitions between patterns, loops
* Record everything you do into patterns or phrases (create from scratch)
* Use an additional MIDI controller for transposing & triggering

Tool discussion is located on the [Renoise forum](http://forum.renoise.com/index.php?/topic/38924-new-tool-30-mlrx/)

## Available mappings

| Name       | Description   |
| -----------|---------------|
|`arp_mode`|Mlrx: Set arpeggiator mode <br>ALL = pick random offset from all triggers <br>RND = pick random offset among held triggers <br>FW  = step through held triggers, order of arrival <br>4TH = pick random offset (in step of four) from most recent trigger <br>4TH = pick random offset (in step of two) from most recent trigger|
|`automation`|Mlrx: Automation mode <br>READ = Only display automation data |<br>READ + WRITE = Display automation, record when moved <br>WRITE = Start recording from the moment a parameter is moved|
|`clone`|Mlrx: Press to create a duplicate of the current pattern|
|`decrease_cycle`|Mlrx: Decrease cycle length|
|`drift_amount`|Mlrx: Set drift amount (between -256 and 256)|
|`drift_enable`|Mlrx: Select drifting mode <br>OFF = do not apply drift <br>'*' = apply drift using entire sample <br>'/' = apply drift using cycle range|
|`drift_label`|Mlrx: Display drifting info|
|`erase`|Mlrx: Press to erase the entire pattern|
|`group_levels`|Mlrx: Adjust velocity for each group|
|`group_panning`|Mlrx: Adjust panning for each group|
|`group_toggles`|Mlrx: Toggle group recording/mute state <br>When blinking, press to stop recording <br>When not blinking, press to toggle mute state|
|`increase_cycle`|Mlrx: Increase cycle length|
|`matrix`|Mlrx: Assign this track to group A/B/C/D|
|`select_track`|Mlrx: Set the active track (hold the button and simultaneously press a group toggle-button to assign this track to that group)|
|`set_cycle_16`|Mlrx: Set cycle length to a sixteenth|
|`set_cycle_2`|Mlrx: Set cycle length to half|
|`set_cycle_4`|Mlrx: Set cycle length to quarter|
|`set_cycle_8`|Mlrx: Set cycle length to an eigth|
|`set_cycle_custom`|Mlrx: Set cycle length to exact value|
|`set_cycle_es`|Mlrx: Sync cycle length with Renoise edit-step|
|`set_mode_hold`|Mlrx: Set track to HOLD mode (continously looping sound)|
|`set_mode_toggle`|Mlrx: Set track to TOGGLE mode (continously looping & toggleable, clears existing data)|
|`set_mode_touch`|Mlrx: Set track to TOUCH mode (produce output only while pressed)|
|`set_mode_write`|Mlrx: Set track to WRITE mode (produce output only while pressed, clears existing data)|
|`set_source_phrase`|Mlrx: Set source to PHRASE mode <br>[Press] to toggle phrase playback for instrument <br>[Hold] to capture pattern data into phrase (when stopped), or start a phrase recording (when playing)|
|`set_source_slice`|Mlrx: Set source to SLICE mode <br>[Hold] to apply/remove slicing from selected sample|
|`shuffle_amount`|Mlrx: Set shuffle amount (0-255)|
|`shuffle_label`|Mlrx: Displays info about shuffle|
|`tempo_down`|Mlrx: Tempo down <br>[Press] to decrease by a single tempo/LPB <br>[Hold] to halve current tempo (when possible)| 
|`tempo_up`|Mlrx: Tempo up <br>[Press] to increase by a single tempo/LPB <br>[Hold] to double current tempo (when possible)|
|`toggle_arp`|Mlrx: Toggle arpeggiator on/off|
|`toggle_exx_output`|Mlrx: Toggle output of envelope offset commands|
|`toggle_loop`|Mlrx: Enable/disable sample loop|
|`toggle_note_output`|Mlrx: Toggle output of notes|
|`toggle_shuffle_cut`|Mlrx: Enable/disable shuffle cut (Cxx)|
|`toggle_sxx_output`|Mlrx: Toggle output of sample offset commands|
|`toggle_sync`|Mlrx: Enable 'beat-sync' in instrument|
|`track_labels`|Mlrx: Display information about this track|
|`track_levels`|Mlrx: Adjust velocity for each track|
|`track_panning`|Mlrx: Adjust panning for each track|
|`transpose_down`|Mlrx: Transpose down <br>[Press] to transpose by a single semitone <br>[Hold] to transpose by an octave|
|`transpose_up`|Mlrx: Transpose up <br>[Press] to transpose by a single semitone <br>[Hold] to transpose by an octave|
|`triggers`|Mlrx: Sample trigger|
|`xy_pad`|Mlrx: XY-Pad input|

## Available options

| Name       | Description   |
| -----------|---------------|
|`active_track`|Determine how to select the active mlrx-track|
|`automation`|Select automation mode|
|`collapse_tracks`|Determine if tracks in the pattern editor should be collapsed|
|`group_panning`|Choose input for controlling the active group panning|
|`group_velocity`|Choose input for controlling the active group velocity|
|`midi_controller`|Specify a MIDI controller for transpose & triggering|
|`play_on_trig`|Determine how to handle playback & recording|
|`sample_prep`|Determine how to handle newly added samples|
|`set_focus`|Determine how focus in Renoise follows the active mlrx-track|
|`track_panning`|Choose input for controlling the active track panning|
|`track_velocity`|Choose input for controlling the active track velocity|

## Changelog

1.01
- Tool-dev: use cLib/xLib libraries, refactored some code
- High-res automation recording (interleaved or punch-in)

0.99.1
- Realtime recording into phrases

0.99
- Many new features, better integration with Renoise

0.98
- First release 

