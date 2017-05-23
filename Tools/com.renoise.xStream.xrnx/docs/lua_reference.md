# xStream Lua Reference

xStream is using a subset of the Renoise Lua API to create and manipulate data. Below, you will find a reference to the properties and methods that are unique to xStream. 

Please note that this is by no means a complete reference of Lua or the Renoise API. If you are not familiar with those, it's highly recommended to visit the [Renoise scripting page](https://github.com/renoise/xrnx).  


## Constants

|Name|Type|Value|Description|
|----|----|-----|-----------|
|`NOTE_OFF_VALUE`|number|121|"OFF" in the pattern editor
|`EMPTY_NOTE_VALUE`|number|120|"---" in the pattern editor
|`EMPTY_VOLUME_VALUE`|number|255|
|`EMPTY_VALUE`|number|255
|`EMPTY_NOTE_COLUMNS`|table
|`EMPTY_EFFECT_COLUMNS`|table
|`EMPTY_XLINE`|table
|`SUPPORTED_EFFECT_CHARS`|table

## Properties 

|Name|Type|Description|
|----|----|-----------|
|`rns`|object|Shorthand for renoise.song()  
|`renoise`|object|Access to the global renoise object  
|`xinc`|number|An ever-increasing counter, initialized when output is started  
|`args`|table|Access to [model arguments](about_models.md#arguments)
|`data`|table|Access to [model user-data](about_models.md#data)  
|`xpos`|SongPos|The song position, contains these properties:<br> `sequence` : number <br> `line` : number
|`xplaypos`|xPlayPos|Access the precise playback position<br>_Shorthand for `xstream.xpos.playpos`_    
|`xline`|table|The current line. See also [xLine](#classes) below.
|`xline.note_columns[]`|table|Table of note columns (between 1-12).<br> Each column can define the following properties:<br>`note_value` : number, 0-119, 120=Off, 121=Empty <br>`note_string` : string, 'C-0'-'G-9', 'OFF' or '---'  <br>`instrument_value` : number, 0-254, 255==Empty  <br>`instrument_string` : string, '00'-'FE' or '..'  <br>`volume_value` : number, 0-127, or number, 0-65535  <br>`volume_string` -> [string, '00'-'ZF' or '..'  <br>`panning_value` : number, 0-127 or number, 0-65535  <br>`panning_string` : string, '00'-'ZF' or '..' <br>`delay_value` : number, 0-255<br>`delay_string` : string, '00'-'FF' or '..' 
|`xline.effect_columns[]`|table|Table of effect columns (between 1-8).<br> Each column can define the following properties:<br> `number_value` : number, 0-65535  <br>`number_string` : string, '00'-'ZZ'  <br> `amount_value` : number, 0-255  <br> `amount_string` : string, '00'-'FF'  
|`xline.automation`|table|
|`xstream`|xStream|Access to the main application   
|`xmodel`|xStreamModel|Access to the selected model  
|`xbuffer`|xStreamBuffer|Access to the stream buffer
|`xvoicemgr`|xVoiceManager|_Shorthand for `xstream.voicemgr`_  
|`xvoices`|table|Access to the active voices<br>_Shorthand for `xstream.voicemgr.voices`_  
|`clear_undefined`|boolean|How to treat empty lines  
|`expand_columns`|boolean|Whether to automatically show columns as data is written  
|`include_hidden`|boolean|Whether to include hidden columns when reading & writing  
|`automation_playmode`|xStreamBuffer.PLAYMODE|The current playmode. Possible values are `POINTS,LINEAR,CUBIC`   
|`track_index`|number|The selected track index  
|`mute_mode`|xStreamBuffer.MUTE_MODE|The current mute mode. Possible values are `NONE,OFF`  
|`output_mode`|xStreamProcess.OUTPUT_MODE|The current output mode. Possible values are `STREAMING,TRACK,SELECTION`

## Methods

|Name|Description|
|----|-----------|
|`wipe_futures()`|Erase all pre-calculated output ahead of current playback position (shorthand for xbuffer.wipe_futures)
|`read_from_pattern()`|Erase all pre-calculated output ahead of current playback position (shorthand for xbuffer.wipe_futures)
|`schedule_line()`|Schedule a note column (shorthand for xbuffer.schedule_line)<br>Arguments: `xline,xinc`
|`schedule_note_column()`|_Shorthand for `xbuffer.schedule_note_column`_  <br>Arguments: `xnotecol,col_idx,xinc`
|`schedule_effect_column()`|_Shorthand for `xbuffer.schedule_effect_column`_<br>Arguments: `xeffectcol,col_idx,xinc`

## Classes

xStream-specific classes

    xStream
    xStreamProcess

## Supporting classes. 

> Please see the [xLib](https://renoise.github.io/luadocs/xlib/index.html) and [cLib](https://renoise.github.io/luadocs/clib/index.html) luadoc references for more information.

|Name|Description|
|----|-----------|
| cLib | Contains common methods for working with strings, numbers and tables.
| xLFO | Static LFO implementation for generating basic waveforms
| xLib | Global constants and static methods for xLib, the eXtended Renoise API library
| xLine | Represents a single line, including note/effect-columns and automation.
| xTrack | Static Methods for working with renoise.Tracks objects
| xTransport | Extended control of the Renoise transport
| xScale | Methods for working with notes & harmonic scales
| xMidiMessage | An extended MIDI message
| xOscMessage | An extended OSC message
| xAutomation | Easy control of parameter automation
| xParameter | N/A
| xSongPos | Static methods for working with renoise.SongPos.
| xPatternSequencer | Static methods for working with the renoise.PatternSequence
| xPlayPos | Extended play-position which support fractional time (between lines).
| xAudioDevice | Static methods for dealing with Audio Devices.
| xPhraseManager | tatic methods for managing phrases, phrase mappings and presets.

