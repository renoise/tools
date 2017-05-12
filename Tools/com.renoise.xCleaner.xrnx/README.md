# xCleaner 

This tool can automatically detect and correct a large number of issues in Renoise instruments.  
It has been designed for content-creation, and is meant to be used as one of the last steps before publishing.  

Here is the complete list of issues that the tool is aware of: 

* Unreferenced content
  * Samples which are not being used  
     * Check phrases for keymap (keep when trigger is set to transpose)
     * Check for direct sample references (sample column)
  * Modulation-sets and Effect-chains 
     * When there are no samples assigned to set or chains
     * When unreferenced by devices in other sets or chains
* Sample: channel processing
  * Detect completely silent samples (remove)
  * Stereo samples which are in fact monophonic (reduce to one channel)
  * “Hard-panned” samples with a blank channel in either side (use non-blank)
  * Detect and fix incorrect sample bit-depth (e.g. 16 bit reported as 32 bit)
* Sample loop and trimming: 
  * Detect (and remove) excess data after loop
  * Detect silence (with adjustable loudness threshold) at either end of sample.
* Sample (re-)naming
  * Automatic shortening “VST: Synth1 VST (Honky Piano)” → Honky Piano
  * Automatic (random) name generator 
  * Custom name (batch renamer)

## Installation

Download the most recent stable release from the [Renoise tools page](http://renoise.com/tools/xcleaner).  
Drag and drop the .xrnx file on a Renoise window to install

Launch the tool by right-clicking an instrument in the instruments list (-> xCleaner)

## How to use

TODO

