# VoiceRunner


This tool adds advanced pattern-data sorting to Renoise, using a number of different algorithms. 

Technically the tool relies on concept called _voice-runs_. Meaning, it understands a pattern as being made up from several smaller snippets, each of which represent the time passed from pressing a key on a piano, to releasing it. 

Doing this for large amounts of pattern-data can be quite heavy, so use with caution!  



## Quickstart

Download the tool from the [Renoise tool page](http://www.renoise.com/tools/voicerunner), and double-click or drag the xrnx file on top of the Renoise window to install.

The tool can be triggered in a number of ways:  

* From the Renoise Tools menu > VoiceRunner
* From the supplied MIDI and keyboard shortcuts (search for 'VoiceRunner') 
* By right-clicking the pattern editor

## User interface

If you launch the tool, the main dialog will look something like this:

[SCREENSHOT]

In the upper part, you can choose which scope to use.   

* **Selection in Pattern** : sort the selected range in the pattern 
* **Track in Pattern** : sort the current track 
* **Group in Pattern** : sort all tracks in the current group 
* **Whole Pattern** : sort every track in the pattern

In the middle, you can choose your sorting algorithm: 

* **Low > High** : lower notes first, then higher ones (compact)
* **High > Low** : higher notes first, then lower ones (compact)
* **Unique Notes** : put each unique note in a separate note-column (max. 12 notes)

In the lower part, you can trigger various actions.
   
* **Sort** : pressing this button will sort the pattern according to the selected scope.   
* **Select** : this will select the _voice-run_ below the cursor (if any). 

Note that 'Select' works independently of the scope you have selected.  To finetune the behaviour, see 'Detection' in the Advanced settings panel. 

Click the little checkbox near the bottom to show the Advanced settings.

## Advanced settings

### Overall

**Launch on startup** : show tool when Renoise starts.  
**Reset to defaults** : reset to default settings.

### Sorting : adjust sorting preferences 

**Allow column names** : some of the sorting algorithm can specify column names, but they are applied if this option is enabled.  
**Match visible cols** : when the sorting reduces the number of note-columns, enable this option to hide them (note that when sorting results in _additional_ columns, they are always shown).  

### Detection : finetune the voice-collection of the tool 

**Split at note** : the most fine-grained option available - will create a split point for every note encountered.      
**Split at note-change** : treat every change in pitch as a split point. For pitch sorting, it's recommended to leave this on.   
**Stop at note-off** : if enabled, the tool stops collecting data once a note-off command is reached. Usually this is safe option to enable, but since Renoise allows you to manipulate voices also after they have been released, you might want to leave it unchecked. 

## Keyboard Shortcuts

	Global : VoiceRunner : Show dialog...
	Global : VoiceRunner : Select Voice-Run...
	Global : PhraseMate : Sort Selection In Pattern
	Global : PhraseMate : Sort Track in Pattern
	Global : PhraseMate : Sort Group in Pattern
	Global : PhraseMate : Sort Whole Pattern

## Menu Entries

	Main Menu : Tools : VoiceRunner...
	Pattern Editor : VoiceRunner : Select Voice-Run
	Pattern Editor : VoiceRunner : Select Voice-Run (Toggle)
	Pattern Editor : VoiceRunner : Sort Selection In Pattern
	Pattern Editor : VoiceRunner : Sort Track in Pattern
	Pattern Editor : VoiceRunner : Sort Group in Pattern
	Pattern Editor : VoiceRunner : Sort Whole Pattern


## MIDI Mappings

	Tools : VoiceRunner : Create Phrase from Selection in Pattern [Trigger]

