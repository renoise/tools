# ScaleMate

## Description

ScaleMate offers quick access to the built-in instrument scales in Renoise, organized by the number of notes.

If the user-interface is visible, the currently set scale and key are shown there. Push a button to select. Alternatively, use the available keyboard shortcuts / MIDI mappings.

Whenever you select a scale or key, you can tell ScaleMate to write this into the pattern (technically, a MIDI command). This also works while recording, and allows you to switch scales on the fly.

## Bonus info: scales and keys

Scales are a live trigger option that affect instruments in Renoise. Scales don't affect already-recorded notes unless the instrument contains an active phrase. 
However, when a scale is selected, and you are rehearsing or recording an instrument, the scale is applied in realtime.

The commands being written to the pattern are the same as the specified by the Renoise MIDI implementation chart: (http://tutorials.renoise.com/wiki/MIDI#MIDI_Messages)

**CC#14 (Scale Key)** - Determine the root key for the scale  
**CC#15 (Scale Mode)** - Apply a harmonic scale to the preset  

## Download

Get the most recent stable version from the Renoise tool page:  
http://www.renoise.com/tools/scalemate

## Bugs and Support

Found a bug and want to report it? Tool-related discussion is located here:    
http://forum.renoise.com/index.php/topic/49787-new-tool-31-scalemate/

## Changelog

### 0.2 
- Added: scale key
- Bug fixes

### 0.11 + 0.12
- Bug fixes

### 0.1
- "managed to put this together in a little hacking session last night"