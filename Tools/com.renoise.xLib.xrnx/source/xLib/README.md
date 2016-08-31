# About xLib

The xLib library is a suite of classes that extend the standard Renoise API. 

## How to use 

If you are planning to use xLib in your own project, start by including the xLib.lua file, and any classes you need

	_xlibroot = 'source/xLib/classes/'
	require (_xlibroot..'xLib')
	require (_xlibroot..'xSample')

Note: the xLib include path `_xlibroot` is also used internally.  

### Special considerations

To improve performance, the xLib is using a single reference to the Renoise song object - called `rns`. You will need to define and maintain this variable yourself. For example, by refreshing it when a new document becomes available:

	renoise.tool().app_new_document_observable:add_notifier(function()
	  rns = renoise.song()
	end)

