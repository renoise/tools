# xStream Lua Reference

xStream is using a subset of the Renoise Lua API to create and manipulate data. Below, you will find a reference to the properties and methods that are unique to xStream. 

Please note that this is by no means a complete reference of Lua or the Renoise API. If you are not familiar with those, it's highly recommended to visit the [Renoise scripting page](https://github.com/renoise/xrnx).  


## Constants

|Name|Type|Value/Description|
|----|----|-----------------|
|`NOTE_OFF_VALUE`|number|121, shown as "OFF" in pattern. <br>See [xNoteColumn.NOTE_OFF_VALUE](https://renoise.github.io/luadocs/xlib/modules/xNoteColumn.html#NOTE_OFF_VALUE)
|`EMPTY_NOTE_VALUE`|number|120, shown as "---" in pattern. <br>See [xNoteColumn.EMPTY_NOTE_VALUE](https://renoise.github.io/luadocs/xlib/modules/xNoteColumn.html#EMPTY_NOTE_VALUE)
|`EMPTY_VOLUME_VALUE`|number|255, shown as "‥" in pattern. <br>See [xNoteColumn.EMPTY_VOLUME_VALUE](https://renoise.github.io/luadocs/xlib/modules/xNoteColumn.html#EMPTY_VOLUME_VALUE)
|`EMPTY_VALUE`|number|255, shown as "…" in pattern. <br>See [xLinePattern.EMPTY_VALUE](https://renoise.github.io/luadocs/xlib/modules/xLinePattern.html#EMPTY_VALUE)
|`EMPTY_NOTE_COLUMNS`|table|Set of 12 empty tables. <br>See [xLine.EMPTY_NOTE_COLUMNS](https://renoise.github.io/luadocs/xlib/modules/xLine.html#EMPTY_NOTE_COLUMNS)
|`EMPTY_EFFECT_COLUMNS`|table|Set of 8 empty tables. <br>See [xLine.EMPTY_EFFECT_COLUMNS](#classes).
|`EMPTY_XLINE`|table|Set of empty note/effect-columns. <br>See [xLine.EMPTY_XLINE](#classes)
|`SUPPORTED_EFFECT_CHARS`|table|List of effect commands (values) <br>See [xEffectColumn.SUPPORTED_EFFECT_CHARS](https://renoise.github.io/luadocs/xlib/modules/xEffectColumn.html#SUPPORTED_EFFECTS)

## Properties 


|Name|Type|Description|
|----|----|-----------|
|`rns`|object|Shorthand for `renoise.song()` [read-only]
|`renoise`|object|Access to the global renoise object [read-only] 
|`xinc`|number|An ever-increasing counter, available once output starts [read-only]
|`args`|table|Provides access to [model arguments](about_models.md#arguments) 
|`data`|table|Provides access to [model user-data](about_models.md#data)  
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
|`automation_playmode`|number|The automation 'playmode'. Possible values are `xStreamBuffer.PLAYMODE.POINTS`, `xStreamBuffer.PLAYMODE.LINEAR` and `xStreamBuffer.PLAYMODE.CUBIC`   
|`track_index`|number|The selected track index  
|`mute_mode`|number|The current mute mode. Possible values are `xStreamBuffer.MUTE_MODE.NONE` and `xStreamBuffer.MUTE_MODE.OFF`
|`output_mode`|number|The current output mode. Possible values are `xStreamProcess.OUTPUT_MODE.STREAMING`, `xStreamProcess.OUTPUT_MODE.TRACK` and `xStreamProcess.OUTPUT_MODE.SELECTION`

## Methods

These are the most important methods to know about, as they are used in the example models: 

|Name|Description|
|----|-----------|
|`xstream:output_message()`| Trigger MIDI messages over the internal OSC server in Renoise. <br>@param xmsg (xMidiMessage or xOscMessage) <br>@param mode (xStream.OUTPUT_OPTIONS)
|`xbuffer:wipe_futures()`|Erase all pre-calculated output ahead of current playback position
|`xbuffer:read_from_pattern()`|Read a line from the pattern (or scheduled, if it exists)<br>@param `xinc` (int), the buffer position<br>@param `[pos]` (SongPos), where to read from song<br>@return `xLine`, xline descriptor (never nil)
|`xbuffer:schedule_line()`|Arguments: `xline,xinc`
|`xbuffer:schedule_note_column()`|Arguments: `xnotecol,col_idx,xinc`
|`xbuffer:schedule_effect_column()`|Arguments: `xeffectcol,col_idx,xinc`

## Classes

xStream-specific classes

    xStream
    xStreamProcess

## Supporting classes

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
| xNoteColumn | A virtual representation of renoise.NoteColumn
| xEffectColumn | A virtual representation of renoise.EffectColumn
| xOscMessage | An extended OSC message
| xAutomation | Easy control of parameter automation
| xParameter | N/A
| xSongPos | Static methods for working with renoise.SongPos.
| xPatternSequencer | Static methods for working with the renoise.PatternSequence
| xPlayPos | Extended play-position which support fractional time (between lines).
| xAudioDevice | Static methods for dealing with Audio Devices.
| xPhraseManager | tatic methods for managing phrases, phrase mappings and presets.

> < Previous - [Coding with xStream](coding_intro.md) 
