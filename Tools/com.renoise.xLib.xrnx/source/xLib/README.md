# About xLib

The xLib library is a suite of classes that extend the standard Renoise API. 

The idea is to offer additional methods for the built-in objects in Renoise, and to provide alternatives. For example, the xNoteColumn class is a complete emulation of the native renoise.NoteColumn - but not bound to a specific song/pattern. 

## How to use 

If you are planning to use xLib in your own project, start by including the xLib.lua file, and any classes you need

	-- set up include-path
	_xlibroot = 'source/xLib/classes/'

	-- require some classes
	require (_xlibroot..'xLib')
	require (_xlibroot..'xSample')

Note: it's important that you specify the include path, as it's used internally as well.  

### Special considerations

To improve performance, xLib is using a single reference to the Renoise song object - called `rns`. You will need to define and maintain this variable yourself. For example, by refreshing it when a new document becomes available:

	renoise.tool().app_new_document_observable:add_notifier(function()
	  rns = renoise.song()
	end)

## Requirements

xLib requires an additional library called cLib, which you can get here:
https://github.com/renoise/xrnx/tree/master/Tools/com.renoise.cLib.xrnx

To install, copy the 'cLib' folder to your tool (and don't forget to read the instructions which accompany cLib)

## How to use

Since xLib does not 'do' anything on it's own, the standalone version is simply configured to run some unit-tests:
https://github.com/renoise/xrnx/tree/master/Tools/com.renoise.xLib.xrnx

## Examples

xLib is used in many of the tools on our github repository: 
https://github.com/renoise/xrnx/tree/master/Tools/



