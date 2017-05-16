# xStream Lua Reference

xStream is using a subset of the Renoise Lua API. If you are not familiar with Lua or the Renoise API, it's recommended to visit the [Renoise scripting page](https://github.com/renoise/xrnx). Also, xStream comes with [many examples](...), which should make learning easier.   


> It's recommended to [open the scripting console]() for more detailed feedback and the ability to print debug information.  

### Properties 

`rns` - shorthand for renoise.song()  
`renoise` - access to the global renoise object  
`xinc` - (number) an ever-increasing counter, initialized when output is started  
`xline` - (table) the current line, containing the following entries  
`xline.note_columns[]` - (table) access note columns in the xline  
`xline.note_columns[].note_value` -> [number, 0-119, 120=Off, 121=Empty]  
`xline.note_columns[].note_string` -> [string, 'C-0'-'G-9', 'OFF' or '---']  
`xline.note_columns[].instrument_value` -> [number, 0-254, 255==Empty]  
`xline.note_columns[].instrument_string` -> [string, '00'-'FE' or '..']  
`xline.note_columns[].volume_value` -> [number, 0-127, or number, 0-65535]  
`xline.note_columns[].volume_string` -> [string, '00'-'ZF' or '..']  
`xline.note_columns[].panning_value` -> [number, 0-127 or number, 0-65535]  
`xline.note_columns[].panning_string` -> [string, '00'-'ZF' or '..']  
`xline.note_columns[].delay_value` -> [number, 0-255]  
`xline.note_columns[].delay_string` -> [string, '00'-'FF' or '..']  
`xline.effect_columns[]` - (table) access effect columns in the xline  
`xline.effect_columns[].number_value` -> [number, 0-65535]  
`xline.effect_columns[].number_string` -> [string, '00'-'ZZ']  
`xline.effect_columns[].amount_value` -> [number, 0-255]  
`xline.effect_columns[].amount_string` -> [string, '00'-'FF']  
`xpos (xStreamPos)` -> the song position - see also xLib documentation  
`xpos.line (number)` -> line in pattern  
`xpos.sequence (number)` -> pattern sequence index  
`xstream (xStream)` -> access to the xStream instance  
`xmodel (xStreamModel)` -> access to the running xStreamModel instance (the selected one)
`xbuffer (xStreamBuffer)` -> access to the stream buffer (shorthand for xstream.buffer)  
`xvoicemgr (xVoiceManager)` -> access the voice-manager (shorthand for xstream.voicemgr)  
`xvoices (table<xMidiMessage>)` -> access the active voices (shorthand for xstream.voicemgr.voices)  
`xplaypos (xPlayPos)` -> access the 'precise' playback position (shorthand for xstream.stream.playpos)   
`args (table, ObservableXXX)` -> access to model arguments  
`data (table)` -> optional user-data, access via 'data.my_value'  
`clear_undefined (boolean)` -> how to treat empty lines (see Options dialog for more details)  
`expand_columns (boolean)` -> whether to automatically show columns as data is written  
`include_hidden (boolean)` -> whether to include hidden columns when reading & writing  
`automation_playmode (xStreamBuffer.PLAYMODE)` -> the current playmode: POINTS,LINEAR,CUBIC   
`track_index (number)` -> the selected track index  
`mute_mode (xStreamBuffer.MUTE_MODE)` -> the current mute mode: NONE,OFF  
`output_mode (xStreamProcess.OUTPUT_MODE)` -> the current output mode: STREAMING,TRACK,SELECTION

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

