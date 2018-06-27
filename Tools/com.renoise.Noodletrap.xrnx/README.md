# Noodletrap

Noodletrap is a tool for Renoise that enables an alternative keyboard recording workflow, in which recordings - "noodlings" - are stored as phrases in the selected instrument instead of being record directly into the song. This approach lends itself well to spontaneous jamming and improvisation as you don't have to "make room" in the song first and instead, can focus on playing. 

Phrases are automatically created each time you start a new recording. Along with MIDI-mappable buttons for the most important features of the GUI, this allows a standalone workflow where you can control the entire recording process from your master keyboard or other MIDI device. 

## Main features

* **Convenience**: record ideas without the need to "make room in the song" first
* **Ease of use**: the entire recording workflow can be controlled via MIDI or shortcuts   
* **Precision**: record using high resolution (adjustable LPB for each recording)
* **Flexibility**: afterwards, recording can be anywhere in the song, in any track (phrase)
* **Integration**: support for trigger options (hold and mono), and MIDI commands (pitchbend/cc/prg)
* **Customizable**: almost every option in the tool can be tailored to suit your needs 


## How to use 

First, launch the tool. This is done from the Renoise Tools menu. The tool remains active only while the GUI is visible.     

When launching Noodletrap the first time, it is set to "manual mode" + "first incoming note". This means that you should hit the button in the lower left corner labelled 'Start' in order to prepare for a recording. Once the button has been clicked, it will wait for the first incoming note. 

Hit a key on your MIDI controller, or strike a key on your PC keyboard while the dialog is focused to begin recording. Now, you should see a "counter" appear in the lower middle section. It contains the length of the recording (lines), plus a countdown to when the recording is automatically completed.
If you want a longer countdown (perhaps because you want long pauses in your recording?), you can customize this setting from (Record > Stop).  

Once done with the recording, you can view the resulting recording by either double-clicking the button in the 'phrase bar' (the visual representation of phrases in the instrument).

Instead of waiting for the recording timeout, you can also hit ESC or Return to stop the recording right away. 

After a good recording session you might want to trim the resulting phrases or loop them, but otherwise they should be ready for use. Close Noodletrap by clicking the 'X' (close button) in the upper right corner or the big button labelled "Done". 

## FAQ

**Can this tool write phrases into the pattern?** 

As this tool is dealing with recording of notes (input), it would perhaps seem obvious that you could also write them back to the pattern (output). However, another tool [PhraseMate](http://www.renoise.com/tools/phrasemate) is recommended for this purpose. 

**I see notes appearing in the pattern editor as I am recording**

This is Renoise, recording notes in the usual way. You have to deselect the MIDI port in the Renoise preferences, so Noodletrap can have exclusive access to it.  

**Only the PC keyboard is working when I record**

Have you specified a MIDI port in Noodletrap? Does the controller input notes? Check the events log and MIDI panel in Renoise   

**Bugs and feedback**

This tool has a dedicated topic on the renoise forum, where you can leave any feedback or report bugs.  


## Tips and tricks

**Recording long takes**

In Renoise, no recording can be longer than 512 lines. Noodletrap offers two ways of overcoming this limitation: first of all, you can choose to split a recording if you exceed this length (Record > Split > When more than #lines). If you feel that splitting the recording is not attractive, consider lowering the phrase LPB (Phrase > LPB > Specify) - the latter is probably the best option, especially if you are not relying on MIDI commands (as these can only be specified/recorded per-line) 

**Quick access/navigation** 

While the Noodletrap dialog is focused, you can navigate the phrase mappings using the keyboard shortcuts, or double-click the buttons in the phrase bar to set focus to the phrase/editor   

**Phrase presets**

Don't forget that Renoise allows you to save any phrase in your user library. If you recorded a particularly good one, perhaps it could be useful in other projects as well? Click the dropdown menu in the upper right corner of the phrase editor to make it available at any time. 

## Limitations
API wishlist: key_off_handler
Bug? Sometimes, passing value from keyhandler does not sound a note 


## MIDI mappings / GUI 

* `Start/Stop` - when not recording, prepare for a new recording. When recording, stop the current recording.
* `Split` - when recording, hit this button to split the recording (continue recording in a new phrase)
* `Cancel/Done` - when recording, cancel and return to initial state. When not recording, closes dialog. 
    

## Keyboard shortcuts 

*Note that these shortcuts are only relevant when the Noodletrap dialog is focused*
 
* `[Left/Right arrow keys]` Push the arrow keys to select the current phrase 
* `[Delete]` Remove the current phrase from the instrument 
* `[Enter]` When not recording: prepare for input ("record-arm"). While recording: finalize recording  ("stop") 
* `[Esc]` While recording: cancel recording, else toggle edit mode 
* `[Tab]` Will take you back and forth between the phrase editor and your "current working space" 
(it will try to memorize whatever middle frame you have currently selected, and restore that)

## Changelog

v0.99 - in progress

  FEATURE More precisely laid out phrase bar (vLib integration)
  CHANGE MIDI/Note events optionally logged to terminal (can be specified in Settings)  
  CHANGE Disable PC keyboard input by default, show "warning" when enabling
  FIXED Sometimes, error occurs when deleting phrases in 'bar' (issue#141)
  FIXED Disallow recording when there is no room (issue#141)
  FIXED Error when opening tool without active instrument (issue#129 + issue#76)

v0.98 - 10 May 2016

	FIXED Unresponsible MIDI input on startup (apparently not fixed in 0.97)
	FEATURE Recording of MIDI commands (pitchbend, pressure, control/program change) 
	CORE Using xLib where possible

v0.97 - 05 May 2016

	FIXED Missing MIDI input ports on startup 
	FEATURE MIDI Device hot-plugging 

v0.96 - 28 October 2015

	Small bugfix for 0.95

v0.95 - 28 October 2015

	Preliminary support for API5 (Renoise 3.1)

v0.94 - 09 July 2015

	FIXME No longer output doubled note-off
	FIXME Better use of empty note-columns (more compact recordings)
	FEATURE Quantize note input
	FEATURE Preserve note length (when quantizing)
	FEATURE Respect monophonic setting in instrument (single-column takes)
	CODE Refactored events into NTrapEvent class

v0.93 - 24 June 2015

	FIXME: now displays selected MIDI port correctly on startup. 
	FIXME: Do not initialize tool dialog when launching. Also, “sleep” while hidden
	FIXME: Record “start” option : first note should always be a note-on 
	FIXME: could throw error on certain combinations of MIDI key transpose and renoise transpose (very low notes) 
	TWEAK: when record-armed, but not recording, “stop button” will cancel the take 
	TWEAK: double-clicking phrase buttons should now always toggle phrase editor. Previously, it was a bit fiddly and sometimes requires three clicks. 
	TWEAK: Made “Phrase LPB = Song” the default option when creating new phrases

v0.91
	
	MIDI Assignable record buttons
	When using timed recording mode "stop after note --> beats" + "start at first incoming note", automatically prepare for new recording after having finished one. 
	FIXME When basing the recording’s length of an existing phrase, the result would become one line longer
	FIXME When another instrument is loaded on top of (replacing) the working instrument, selecting a phrase could throw an error

v0.9 

	Fixing various bugs

v0.5 

	Initial relese