# About xLib

The xLib library is a suite of classes that extend the standard Renoise API. 

## Documentation

Point your browser to this location to browse the auto-generated luadocs:
https://renoise.github.io/luadocs/xlib

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

## Examples

xLib is used in many of the tools on our github repository: 
https://github.com/renoise/xrnx/tree/master/Tools/

There is a packaged (renoise tool) version of xLib, configured to run some unit-tests:
https://github.com/renoise/xrnx/tree/master/Tools/com.renoise.xLib.xrnx




