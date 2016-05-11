# xStream

xStream is a [Renoise tool](http://www.renoise.com/tools/) that allows you to generate or transform existing pattern/automation data via custom code. Depending on your experience with lua scripting, you can use the tool's built-in functionality or create new scripts (models) from scratch.

## Features

* Simple syntax which lets you read and write pattern data, one line at a time
* Two operating modes: 'streaming' (real-time) output or 'offline' (apply to track, selection in track)
* The streaming mode works across patterns, and even when using pattern/block-loops
* User code is running in a "sandbox" - this protect against syntax errors while the tool is running
* Define your own variables and change their values in realtime as pattern data is written
* Convenient import & export of 'models' and presets from within the tool itself
* Ability to "lock" certain variables during preset switching (maintain character of model) 
* Ability to "randomize" variables - create random presets (or 'lock' to maintain current value)
* Powerful "favorites" system - launch models/presets from a keyboard/MIDI assignable grid

## How it works

xStream is intended as a tool for producing 'streaming' output - writing pattern/automation data into the selected track as the playback position progresses through a song. Using this approach you can produce pretty much any kind of output, and tweak it in real-time. Think note arpeggiators, weird granular output, harmonization, all sorts of stuff. 

The output is produced by a single function, called the 'model'. This model can use a subset of the Renoise Lua API, as well as a number of supporting classes (which provide convenient methods such as harmonization or automation support).  


## Limitations

To keep things simple(r), xStream is currently limited to the selected track in Renoise. 
   


## The user interface

xStream is _deep_, and it might be overwhelming the first time you launch it. But really, once you get familiar with the user interface it will seem a lot less intimidating.
 
**Here is a quick overview:**
	
	+-----------+---------------------------------------+
	| Settings  | Global toolbar                        |
	|           +-------------------------+-------------+
	|           | Code editor             | Favorites   |
	|           |                         |             |
	|           |                         |             |
	|           |                         |             |
	|           |                         |             |
	|           |                         |             |
	|           |                         |             |
	|           +-----------+---------------------------+
	|           | Models    | Presets     | Arguments   |
	|           |           |             |             |
	|           |           |             |             |
	|           |           |             |             |
	|           |           |             |             |
	+-----------+-----------+-------------+-------------+


* **Settings** - Control how the tools is launched, and finetune various options
* **Global toolbar** - Quick access to streaming and offline output
* **Code Editor** - Where the custom code for each model is defined
* **Models** - Access/create/edit models
* **Presets** - Access/create/edit presets for the current model
* **Arguments** - Access/create/edit arguments for the current model
* **Favorites** - Recall/create/edit model+preset favorites       

## xStream Lua Reference

xStream is using a subset of the Renoise Lua API

### Methods

### Properties 

### Static classes and Constants

xStream provides access not only the Renoise API, but  also some other useful classes that extend the Renoise API - visit the [xLib documentation](http://example.net/) for more details 

## Changelog

#### Done vX.X
