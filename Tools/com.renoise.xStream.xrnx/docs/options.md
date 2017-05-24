### Options dialog       

#### General Options

<img src="./images/options_general.png"> 

**Autostart tool:** enable this option to automatically launch xStream when Renoise starts  

**Remember selected model:** enable this option to make xStream recall the last selected model you chose on startup. Alternatively (when disabled), specify any model that you want to use as the default.

**Userdata location:** provide a custom (alternative) location for xStream models, presets and favorites. If you are planning to create your own models, it is strongly recommended to specify a location outside of the tool folder, as this folder will be overwritten when/if you update the tool.

**Statistics:** Provides some handy statistics about the xStream tool, including RAM usage and current streaming position (if any) 

#### Streaming Options

<img src="./images/options_streaming.png"> 

**Suspend streaming while hidden:** if you are not planning to use the streaming feature while the main GUI is hidden, enable this checkbox. Triggering favorites will still work, but only while playback is stopped (offline mode, apply to track/selection). 

**Enable streaming:** this popup allows you to select among different modes to enable automatic streaming.  
`Manual`: enable the streaming from the global toolbar.  
`Auto - Play`: enable streaming once playback in Renoise starts.  
`Auto - Play + Edit`: enable streaming when starting playback while in edit mode.  

**Default scheduling:** choose the scheduling mode for favorites and presets.  
`None` - do not schedule  
`Beat` - wait for next beat (default setting)   
`Bar` - wait for next bar (depends on metronome beats)   
`Pattern` - wait until next pattern  

**Stream mute-mode:** choose the mute-mode that you prefer (muting is done via the Global toolbar).  
`None` - will stop producing output and instead, clear the pattern ahead of the streaming position.  
`Off` - will write initial note-offs, and then clear the pattern ahead of the streaming position.   

**Writeahead factor:** this value will determine how far ahead the streaming will write. Lower values will cause more lines to be written, while a higher value will decrease the number of lines. The _actual_ number of lines depends on the current BPM/LPB combination (the General Options will display this value).     

if you have plenty of CPU power, you could try decrease the `writeahead` amount. This will in turn increase the number of lines being written to the pattern, ahead of the playback position, and thus, reduce the risk of skipped lines.

#### MIDI Options

<img src="./images/options_midi.png"> 

Here you can select which MIDI input and output devices to use, configure the internal MIDI routing and finetune how MIDI messages are interpreted by xStream.

Once you have enabled some devices, all your models will be able to respond to incoming [MIDI events](#event-dialog) and create messages of their own. 


#### Output Options

<img src="./images/options_output.png"> 

These settings decide how output is written to the pattern editor/automation lane. Note that each model can override these values - they are only provided as sensible defaults. 

**include_hidden:** by default, xStream will not reveal note-columns if they don't receive any data. By enabling this feature, you can easily end up create fully expanded 12-note column / 8 effect-columns tracks, so use with care!

**clear_undefined:** this options will affect how xStream will treat undefined lines and columns. By default, all lines are defined, as the tool reads from the pattern. But if you should choose to define any column as {} (an empty table), or use of the constants `EMPTY_XLINE/EMPTY_NOTE_COLUMNS/EMPTY_EFFECT_COLUMNS`, then the lines will be cleared as a result. _Disable this option when you want to preserve existing data and only write explicitly defined values into the pattern._

**expand_columns:** enable this option to reveal columns and sub-columns as they receive data. For example, if a model is making use of the delay column, it will be allowed to show this column once you run the model. Of course, this is only relevant when your delay column was originally hidden.   

