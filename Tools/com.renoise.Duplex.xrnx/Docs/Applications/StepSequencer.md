# Duplex.Application.StepSequencer

## About

The Duplex StepSequencer is a basic but functional step sequencer. You get the best experience by running it on a LED-backlit grid/pad-based controller with a reasonable amount of buttons. 

## How to use:

- Press an empty button to put a note down, using the currently selected 
  instrument, base-note and volume
- Press a lit button to remove the note
- Press and hold a lit button to copy the note. Toggle a note on/off somewhere 
  else to paste the copied note to this location
- Transpose note up/down by pressing and holding any number of notes, and then 
  pressing the transpose buttons. Changes will be applied to all held notes
- Adjust note volume by pressing and holding any number of notes, and then 
  pressing a level button. Changes will be applied to all held notes
- Press level/transpose buttons when no notes are held, to adjust the base-note 
  and default volume


## Available mappings 

| Name          | Description   |
| ------------- |---------------|
|`track`|Sequencer: Flip through tracks|  
|`grid`|Sequencer: press to toggle note on/off<br>[Hold single button] to copy note<br>[Hold multiple buttons] to adjust level/transpose
|`line`|Sequencer: Flip up/down through lines|  
|`transpose`|Sequencer: 4 buttons for transpose|<br>1st: Oct down<br>2nd: Semi down<br>3rd: Semi up<br>4th: Oct up|  
|`levelsteps`|Sequencer: Increase the note volume step wise|  
|`levelslider`|Sequencer: Adjust note volume|  
|`level`|Sequencer: Adjust note volume|  
|`next_line`|Sequencer: Go to next line|  
|`prev_line`|Sequencer: Go to previous line| 

## Available options 

| Name          | Description   |
| ------------- |---------------|
|`follow_column`|Enable this if you want to align the sequencer to the currently selected column in pattern|  
|`follow_line`|Enable this if you want to align the sequencer with the selected line in pattern|  
|`volume_steps`|Specify the step size of the volume-steps button|  
|`follow_track`|Enable this if you want to align the sequencer to the selected track in pattern|  
|`page_size`|Specify the step size when using paged navigation|  
|`write_mode`|Choose if you want to write notes to the pattern dependent from Renoise's edit mode.|  
|`line_increment`|Choose the number of lines to jump for each step when flipping through pattern|  
|`play_notes`|Choose if you want to play the instrument / note on pushing a trigger pad or grid button. If 'Write mode' is set to 'Only in edit mode', notes will be played only if edit mode is off.|  
|`display_notes`|Choose if you want to display the note valuesonto the grid buttons in Duplex|  
|`grid_mode`|Choose if you want to edit multiple tracks with the grid or only one track.|  

## Changelog

0.99 (by Eran Dax Lonker)
- Added: "grid mode" option - use all grid buttons for only one track/column
- Added: "follow column" option - use the currently selected column
- Added: "Write mode" option - insert notes only if pattern edit mode is on
- Added: "Play notes" option - plays the current note if trigger pads is
          pushed (via OSC, if "Write notes" set not to "All time", notes 
          will be played only if pattern edit mode is off.)
- Added: "display notes" option - display notes + volumens on the grid buttons
- Added: new mapping "levelslider" (single slider for setting the volume) 
          new mapping "lvelsteps" (single button for rotating the volume)
- Added: grid mapping parameter button_size ... only needed to decide whether
          it's possible to display the note volume in addition to the note value
- Fixed: wrong note octave in renoise notifications 

0.98.21
- Support line_notifier when slots are aliased (also when created and/or removed)
- Workflow: when navigating from a long pattern into a shorter one, start from 
  the top (IOW, always restrict to the actual pattern length)
- Fixed: update the volume-level display when base volume is changed
- Fixed: selecting a group track could cause an error

0.98.20
- Fixed: focus bug when holding button

0.98.18
- Mappings track, level, line, transpose are now optional. This should fix an 
  issue with the nano2K config that didn’t specify ‘track’
- Fixed: under certain conditions, could throw error on startup

0.98  
- Palette now uses the standard format (easier to customize)
- Sequencer tracks can be linked with instruments, simply by assigning 
  the same name to both. 
  UISpinner (deprecated) control replaced with UISlider+UIButton(s)

0.96
- Option: "follow_track", set to align to selected track in Renoise
- Option: "track_increment", specify custom step size for track-switching

0.95  
- The sequencer is now fully synchronized with the currently selected 
  pattern in  Renoise. You can copy, delete or move notes around, 
  and the StepSequencer will update it's display accordingly
- Enabling Renoise's follow mode will cause instant catch-up
- Display volume/base-note changes in the status bar
- Orientation: use as sideways 16-step sequencer on monome128 etc.
- Option: "increment by this amount" value for navigating lines
- Improved performance 

0.93  
- Support other devices than the Launchpad (such as the monome)
- Display playposition and volume simultaneously 

0.92  
- Original version
