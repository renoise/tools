# PhraseMate

PhraseMate aims to make it more convenient to work with phrases in Renoise.   

## Quickstart

Download the tool from the [Renoise tool page](http://www.renoise.com/tools/phrasemate), and double-click or drag the xrnx file on top of the Renoise window to install.

The tool can be triggered in a number of ways:  

* From the Renoise Tools menu > PhraseMate
* From the supplied MIDI and keyboard shortcuts (search for 'PhraseMate') 
* By right-clicking the pattern editor/matrix  

## How it works

The tool has a number of distinctive operating modes:

**Input** - read from pattern/song and automatically turn into phrases

TODO...

**Output** - turn existing instrument-phrases into normal pattern-data    

TODO...

**Realtime** - monitor the pattern and insert Zxx commands in realtime

TODO...

## Questions & Answers

**Q: (Realtime mode) When I enter a note into the pattern at a location where there's already a Zxx command, I can't change it to "my" Zxx value**   

**A**: This is a limitation of the tool. An easy way to circumvent this limitation is by clearing the existing note first, or by manually selecting the phrase before entering the note (for convenience, you can use the next/previous phrase keyboard shortcuts for this purpose). 

--- 

**Q: (Realtime mode) When I paste data into Renoise, this tool is adding Zxx commands "everywhere". How can I avoid this?**   

**A**: PhraseMate is listening for changes to the pattern as long as edit mode is enabled in Renoise, and the instrument is set to 'Program' mode. So you can either disable Edit mode in Renoise (ESC) - many copy/paste clipboard actions will still be accessible - or set the instrument to 'Off' or 'Keymap' mode.   

--- 

**Q: (Output) After writing, why do the pattern sound differently than my phrase?** 

**A**: Most likely, because the instrument/phrase is using a harmonic scale. Unlike notes, phrases in Renoise are harmonized in real-time. It's a planned feature to support harmonization of notes on output. 

--- 

**Q: (Output) After writing my phrase to the pattern, the result is slower or faster than the source?** 

**A**: Phrases can have an independent LPB (lines-per-beat) value. PhraseMate does not attempt to change the speed when it creates output, but simply writes the data "as-it". Consider using a tool such as [this one](http://forum.renoise.com/index.php/topic/27930-new-tool-28-30-flexible-pattern-resizer/) if you would like to stretch or squash pattern data after it's written. 

## Implementation details
* (Input) When collecting phrases with the 'replace notes' option enabled, the tool cannot insert more than 12 phrase triggers per track. 
* (Input) When the source instrument is already making use of phrases, notes that trigger phrases are skipped
* (Input) When starting to collect phrases from the middle of a pattern/song, ghost notes are not resolved until an instrument is reached. As a result, the first notes might be missing. 
* (Output) Phrase output is currently limited to sequencer tracks (avoid targeting group/send/master tracks)

## Roadmap / planned 

* The ability to transpose and harmonize notes (both when reading and writing from/to pattern)
* The ability to merge multiple (sample-based) instruments into a single one while capturing phrases. 

  