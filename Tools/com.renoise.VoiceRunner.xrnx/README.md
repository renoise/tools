# VoiceRunner


This tool adds highly configurable pattern-data sorting to Renoise. 


## Quickstart

Download the tool from the [Renoise tool page](http://www.renoise.com/tools/voicerunner), and double-click or drag the xrnx file on top of the Renoise window to install.

The tool can be triggered in a number of ways:  

* From the Renoise Tools menu > VoiceRunner
* From the supplied MIDI and keyboard shortcuts (search for 'VoiceRunner') 
* By right-clicking the pattern editor

## How sorting works


Technically the tool understands a pattern as being made up from several smaller 'voice-runs'. 

[ ILLUSTRATION ]

The illustration shows how each voice-run is limited to a single note-column, but includes any volume/panning/delay/effect-commands. The idea is that sorting can be done much more efficiently when the pattern data is understood as a events (pressing a key on a piano, releasing it) instead of just raw line-by-line data.  

So, obviously it matters a great deal how those data are collected in the first place. Luckily, this is highly configurable! For example, if the tool has all options enabled, collection works on the most fine-grained level possible. 

In the following illustration, selecting various parts of a pattern causes a very small selection to be created: 

[ TODO ]

The opposite is true as well - if all options are disabled, the collection will capture entire pattern-tracks at a time, ignoring individual notes and even note-offs. 

[ TODO ]

## Screenshot

If you launch the tool, the main dialog will look something like this:

[SCREENSHOT]


## Features

### Available scopes

**Selection in Pattern** - Sort the selected range in the pattern  
**Track in Pattern** - Sort the current track  
**Group in Pattern** - Sort all tracks in the current group  
**Whole Pattern** - Sort every track in the pattern  

The selected scope applies to _Merge_ and _Sort_ operations.    


### Sorting mode

**High-to-low, Low-to-high...**  
The selected mode affects all sorting operations. Low and high are referring to the note-value, where A-4 is considered a lower value than A-5.

### Sorting method

**Method [Normal]**  
Should give results that are both _readable_ (columns generally sorted by low-to-high or high-to-low) and _compact_ (note columns packed together as long as this doesn’t conflict with the sort mode). This is the default sorting mode. 

**Method [Compact]**  
This method allows general sorting from low-to-high and high-to-low, packing together note-columns whenever possible. Use this method when you need to minimize the number of required note columns.  
--> See also: Merge (to reduce the number of note-columns even further).
 
**Method [Unique]**    
The unique sorting method will examine the pattern and fit every note it encounters within a dedicated note-column. Use this mode to sort e.g. drum-tracks, where each note-column can represent a unique sound in the drumkit. 

--> Note: this sorting mode does not support open notes across pattern boundaries.  
--> Unique sorting can be further configured. See Options > Overlapping notes

## Other features

**Select**  
Clicking `Select` will (attempt to) capture the voice-run below the current cursor position. This is not only handy for selection, it also makes it clear how the tool is configured to collect data from the pattern. 

**Up/Down**   
Pressing these buttons will attempt to select the voice-run immediately before or after the cursor position. 

**Merge**  
Press this button to merge pattern-data in the selected scope. Currently selected merge options apply. 


## Options


### Overall options

**Launch on startup**  
Show the tool GUI when Renoise starts.
  
**Reset to defaults**  
Reset to default settings, including user prompts.

### Collection options 

--> See also: How sorting works  

**Split at note**  
The most fine-grained option available - will create a split point for every note encountered.
      
**Split at note-change**  
Treat every change in pitch as a split point. For pitch sorting, it's recommended to leave this on.
   
**Stop at note-off**  
If enabled, the tool stops collecting data once a note-off command is reached. Usually this is safe option to enable, but since Renoise allows you to manipulate voices also after they have been released, you might want to leave it unchecked. 

**Stop at note-cut**  
Same as note-off, but applies to the Cx command  

### Sorting options 

#### Overlapping notes

Decide what should happen when the pattern contains simultaneous/overlapping notes

**Always create**   
Create new note-columns when overlapping notes are detected.
   
**First only**  
Ignore additional notes after the first one.
   
**Merge into column**  
Force overlapping notes to be merged into the original note-column.     

### Output options 

**Create note-offs**  
When enabled, notes will receive a terminating note-offs or note-cuts as required.  
When disabled, no such thing. Use this e.g. for 'clean looking' drum tracks.  

**Close open notes**  
When enabled, notes that cross the selection/pattern boundary will be terminated.  
When disabled, notes are allowed to cross the pattern boundary.   
   

## Known issues/problems 

* This tool does not change Renoise from having a maximum of 12 note-columns per track.   
* Sorting large amounts of pattern-data can be quite slow  

## API (for tool authors)

### Iterating across patterns

To preserve voice information across patterns, call reset only once (to begin with), and then invoke sort() as many times as needed. Note that for this to work, you need to move ahead in the song sequence one step at a time. 

### How to use

First, create and configure an instance of this class:

xVoiceSorter{
  sort_mode = xVoiceSorter.SORT_MODE.UNIQUE
}

Then call reset() once, followed by sort() 





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

