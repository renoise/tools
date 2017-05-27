# xStream Changelog

## 1.57
- Fixed: error when updating view with out-of-range value #99
- Fixed: error when trying to select data from editor popup #100
- Fixed: error is thrown when entering "return" into main method #97
- Fixed: model doesn't work when last line is comment #95
- Fixed: expecting "models" to be present in custom user-folder #87
- Fixed: favorite icons and preset highlighting (got broken in 1.55)
- Fixed: ChordMemory model had a few flaws
- Changed: more compact, cleaned up GUI

## 1.55
- Core: refactored several internal classes
- Core: more solid, simpler streaming implementation
- Fixed: loading favorites.xml was broken
- Fixed: selecting [no argument] would throw an error
- Fixed: table constants (e.g. EMPTY_XLINE) are now returned as a copy
- Fixed: read-only value arguments are not MIDI assignable
- Fixed: error when trying to create argument with just one "item"
- Fixed: failure to export presets when arguments are tabbed
- Fixed: setting custom userdata folder is now applied immediately
- Added: ability to migrate userdata to a custom folder
- Added: xLFO class + demonstration model
- Added: RandomScale model 
- Added: Updated documentation 

## 1.52 
- Fixed: Automation output accidentally got broken in 1.51
- Fixed: Event notification no longer fired on inactive models
- Fixed: Model "modified" state no longer reset when stream starts
- Added: Renamed models - simple demonstrations are now prefixed by 'Demo-'
- Added: Skip evaluation of callback if main contains no code (comment only)
- Added: Scheduling a note or effect column now able to merge with existing content
- Added: New models, ColumnEraser and Arpeggiator 

## 1.5
- Added: MIDI Support (send/receive)
- Added: Voice Manager
- Added: Buffer access (scheduling)
- Added: Events handlers for 
  * Model events (MIDI, VOICE)
  * Renoise events (a whole lot)
  * Arguments (if any)
- Plus various bugs and small enhancements

## 1.47
- Fixed: Stop streaming when loading a new song while streaming 
- Fixed: A few out-of-bounds song position issues (strengthened checks)
- Added: Tabbed arguments - see Args-Tabbed model for an example
- Added: Linkable arguments - a "sub-feature" of tabbed arguments
- Added: Locked and linked argument state now saved as part of a preset
- Added: Custom userdata folder - containing models, preset and favorites

## 1.46
- Fixed: filename lower/uppercase issue on linux
- Fixed: expand_columns not working when targeting Nth column (not starting from 1)
- Fixed: better "recovery" when deleting patterns while streaming 

## 1.45
- Rewritten GUI (again): the "compact mode" is gone, favorites and options are now dialogs
* Added: Documentation
* Added: Ability to "pin" the favorites window so it will appear on top
* Added: Ability to MIDI-map arguments (CMD/CTRL+M) 
* Fixed: A couple of bugs have been fixed here and there

## 1.41
- Bug fixes 

## 1.40
- Added: inline editing, creation of arguments (no need to open .lua file)
- Added: 'wizard' style creation/import of models (e.g. paste model as string)
- Added: reordering of presets and arguments
- Added: ability to name presets (default is no name, shown as "Preset #x")
- Added: callback: check the 'output_mode' (streaming,track,selection)
- Added: callback: ability to set argument values (updates controls too)
- Added: using HSL color space for highlights (looks more Renoise native)
- Added: various small UI tweaks, improved icon set
- Added: detect longstrings and block comments before saving a model
- Added: renamed argument displays (please update models accordingly)
  
## 1.35
- Bug fixes

## 1.2
- Rewritten UI
- Added: Scheduling 
- Added: Favorites
- Added: External presets ()

## 1.02
- Fixed: Avoid recreating model/preset button-lists as a result of these buttons being clicked

## 1.00
- Initial release
