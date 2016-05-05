# Noodletrap

Noodletrap is a tool for Renoise that enables an alternative recording workflow, in which recordings - "noodlings" - are stored as phrases in the instrument itself.

## Main features

* Record into phrases at any LPB (lines-per-beat) value
* Many recording options, ability to split recordings into "takes"
* Flexible: trap noodlings even when playback is paused

## Keyboard shortcuts 

*Note that these shortcuts are only relevant when the dialog is focused*
 
* `[Left/Right arrow keys]` Push the arrow keys to select the current phrase 
* `[Delete]` Remove the current phrase from the instrument 
* `[Enter]` When not recording: prepare for input ("record-arm"). While recording: finalize recording  ("stop") 
* `[Esc]` While recording: cancel recording, else toggle edit mode 
* `[Tab]` Will take you back and forth between the phrase editor and your "current working space" 
(it will try to memorize whatever middle frame you have currently selected, and restore that)

## Changelog

### v0.97 - 05 May 2016

	FIXED Missing MIDI input ports on startup 
	FEATURE MIDI Device hot-plugging 

### v0.96 - 28 October 2015

	Small bugfix for 0.95

### v0.95 - 28 October 2015

	Preliminary support for API5 (Renoise 3.1)

### v0.94 - 09 July 2015

	FIXME No longer output doubled note-off
	FIXME Better use of empty note-columns (more compact recordings)
	FEATURE Quantize note input
	FEATURE Preserve note length (when quantizing)
	FEATURE Respect monophonic setting in instrument (single-column takes)
	CODE Refactored events into NTrapEvent class

### v0.93 - 24 June 2015

	FIXME: now displays selected MIDI port correctly on startup. 
	FIXME: Do not initialize tool dialog when launching. Also, “sleep” while hidden
	FIXME: Record “start” option : first note should always be a note-on 
	FIXME: could throw error on certain combinations of MIDI key transpose and renoise transpose (very low notes) 
	TWEAK: when record-armed, but not recording, “stop button” will cancel the take 
	TWEAK: double-clicking phrase buttons should now always toggle phrase editor. Previously, it was a bit fiddly and sometimes requires three clicks. 
	TWEAK: Made “Phrase LPB = Song” the default option when creating new phrases

### v0.91
	
	MIDI Assignable record buttons
	When using timed recording mode "stop after note --> beats" + "start at first incoming note", automatically prepare for new recording after having finished one. 
	FIXME When basing the recording’s length of an existing phrase, the result would become one line longer
	FIXME When another instrument is loaded on top of (replacing) the working instrument, selecting a phrase could throw an error

### v0.9 

	Fixing various bugs

### v0.5 

	Initial relese
