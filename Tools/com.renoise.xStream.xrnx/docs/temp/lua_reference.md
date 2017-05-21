# xStream Lua Reference

xStream is using a subset of the Renoise Lua API to create and manipulate data. Below, you will find a reference to the properties and methods that are unique to xStream. 

Please note that this is by no means a complete reference of Lua or the Renoise API. If you are not familiar with those, it's highly recommended to visit the [Renoise scripting page](https://github.com/renoise/xrnx).  

It's recommended to [open the scripting console]() for more detailed feedback and the ability to print debug information.  


### Properties 

|Name|Type|Description|
|----|----|-----------|
|`rns`|object|Shorthand for renoise.song()  
|`renoise`|object|Access to the global renoise object  
|`xinc`|number|An ever-increasing counter, initialized when output is started  
|`xline`|table|The current line  
|`xline.note_columns[]`|table|Table of note columns (between 1-12).<br> Each column can define the following properties:<br>`note_value` : number, 0-119, 120=Off, 121=Empty <br>`note_string` : string, 'C-0'-'G-9', 'OFF' or '---'  <br>`instrument_value` : number, 0-254, 255==Empty  <br>`instrument_string` : string, '00'-'FE' or '..'  <br>`volume_value` : number, 0-127, or number, 0-65535  <br>`volume_string` -> [string, '00'-'ZF' or '..'  <br>`panning_value` : number, 0-127 or number, 0-65535  <br>`panning_string` : string, '00'-'ZF' or '..' <br>`delay_value` : number, 0-255<br>`delay_string` : string, '00'-'FF' or '..' 
|`xline.effect_columns[]`|table|Table of effect columns (between 1-8).<br> Each column can define the following properties:<br> `number_value` : number, 0-65535  <br>`number_string` : string, '00'-'ZZ'  <br> `amount_value` : number, 0-255  <br> `amount_string` : string, '00'-'FF'  
|`xline.automation`|table|
|`xpos`|SongPos|The song position, contains these properties:<br> `sequence` : number <br> `line` : number
|`xstream`|xStream|Access to the main application   
|`xmodel`|xStreamModel|Access to the selected model  
|`xbuffer`|xStreamBuffer|Access to the stream buffer
|`schedule_line()`|function|Schedule a note column (shorthand for xbuffer.schedule_note_column)<br>Arguments: `xline,xinc`
|`schedule_note_column()`|function|_Shorthand for `xbuffer.schedule_note_column`_  <br>Arguments: `xnotecol,col_idx,xinc`
|`schedule_effect_column()`|function|_Shorthand for `xbuffer.schedule_effect_column`_<br>Arguments: `xeffectcol,col_idx,xinc`
|`xvoicemgr`|xVoiceManager|_Shorthand for `xstream.voicemgr`_  
|`xvoices`|table|Access to the active voices<br>_Shorthand for `xstream.voicemgr.voices`_  
|`xplaypos`|xPlayPos|Access the precise playback position<br>_Shorthand for `xstream.stream.playpos`_    
|`args`|table|Access to [model arguments](about_models.md#arguments)
|`data`|table|Access to [model user-data](about_models.md#data)  
|`clear_undefined`|boolean|How to treat empty lines  
|`expand_columns`|boolean|Whether to automatically show columns as data is written  
|`include_hidden`|boolean|Whether to include hidden columns when reading & writing  
|`automation_playmode`|xStreamBuffer.PLAYMODE|The current playmode. Possible values are `POINTS,LINEAR,CUBIC`   
|`track_index`|number|The selected track index  
|`mute_mode`|xStreamBuffer.MUTE_MODE|The current mute mode. Possible values are `NONE,OFF`  
|`output_mode`|xStreamProcess.OUTPUT_MODE|The current output mode. Possible values are `STREAMING,TRACK,SELECTION`

### Constants

	NOTE_OFF_VALUE = 121 ("OFF")
	EMPTY_NOTE_VALUE = 120 ("---")
	EMPTY_VOLUME_VALUE = 255
	EMPTY_VALUE = 255
	EMPTY_NOTE_COLUMNS = (table)
	EMPTY_EFFECT_COLUMNS = (table)
	EMPTY_XLINE = (table)
	SUPPORTED_EFFECT_CHARS = (table)

### Classes

xStream-specific classes

    LFO
    xStream
    xStreamProcess

Supporting classes (xLib). See the [xLib luadoc reference](https://renoise.github.io/luadocs/xlib/index.html) for more information

    xLib
    xLine
    xTrack
    xTransport
    xScale
    xMidiMessage
    xOscMessage  
    xAutomation  
    xParameter  
    xSongPos  
    xPatternSequencer
    xPlayPos
    xAudioDevice
    xPhraseManager

