# SliceMate 

This tool makes it easy to slice a sample from within the pattern editor. 
Just move the edit cursor somewhere - if the slice button is enabled, this means that the tool can insert a slice at the given position.

Use it to remix and re-arrange existing (rendered) songs, or to extract snippets. 

## Features

* Automatically track position in waveform, even with tuned/transposed slices
* Supports the use of delay column for precisely triggered/inserted notes 
* Compact GUI, fully operational via MIDI/keyboard shortcuts 

## Quickstart

Download the tool from the Renoise tool page, and double-click or drag the xrnx file on top of the Renoise window to install.

The tool can be launched in a number of ways:

* From the Renoise Tools menu > SliceMate
* From the supplied MIDI and keyboard shortcuts (search for 'SliceMate')

### How to use

* Load up some (long) sample and enter it into the pattern
* Position the cursor somewhere in the 'trail' and hit slice
* If sample settings are compatible, a new slice/note is inserted
* Move cursor somewhere else, repeat and rinse 

## The user interface 

The user interface is organized into a number of panels:

### Status/options panel

The topmost part is showing the current instrument name:

* Instrument name: show the name of the detected instrument (if any)
* Warning triangle: shown if the tool has detected any problems.
* Detach: click this button to detach the instrument editor 

Below, some more detailed information:

* "Slice": shows you which slice is currently selected
* "Pos": shows you the frame (position in sample) of the slice and/or root sample

Click the small 'gear' button to show tool options:

* "Auto-start tool": will launch the tool when Renoise starts/on a new song
* "Show UI on auto-start": will display the dialog when auto-starting

### Navigation panel

* Left/right arrows: allows you to navigate between columns and tracks
* Previous/next buttons: detect and move cursor to other notes in the song 

### Slice panel 

This panel contains options for the slicing process.

* Insert note: inserts a note in the pattern every time the sample is sliced
* Quantize note: make sure notes are always on a line [1]
* Propagate VOL/PAN: when inserting a note, use the volume and panning from the previous one

[1]: You can record non-quantized ("precise") sliced notes by disabling this feature. Do the slicing while playing, with the pattern-editor cursor set to follow playback.

These options deal with selections, as the cursor position changes:

* Auto-select instrument 
* Auto-select in sample list
* Auto-select in waveform  

Note: if *any* if these options are enabled, the tool will track pattern contains as you navigate around the song (this is the default choice). If you want to do this manually, de-select them all and use the 'Select' button. 


## Limitations

The tool can only work with samples that are configured like this

* Auto-seek: ON, Beat-sync: OFF 
* No pitch modulation (not allowed when auto-seeked)

The tool will tell you if any of the above conditions are not met. 

Also, the tool is not able to reliably track the position if you are 

* Using commands to modify the song tempo (BPM and LPB)
* Using commands sample playback (e.g. 0Bxx/reverse)

Finally, the tool does not support slicing looped samples. 
You can use the tool with such samples, but once the playback reaches the loop end-point, slicing is no longer possible (you should receive an error message if you try). 


