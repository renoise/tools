# About xLib

The xLib library is a suite of classes that extend the standard Renoise API. 

## How to use 

If you are planning to use xLib in your own project, start by including the xLib.lua file, and define the _trace_filters constant. 

	_xlibroot = 'source/xLib/classes/'
	require (_xlibroot..'xLib')
	_trace_filters = nil


Next, require any classes you need in the main.lua of your tool. You can choose to define the xLib include path `_xlibroot`, but this is entirely optional (internally, it is only used for unit testing).  

	require (_xlibroot..'xSample')

### Special considerations

To improve performance, the xLib is using a single reference to the Renoise song object - called `rns`. You will need to define and maintain this variable yourself. For example, by refreshing it when a new document becomes available:

	renoise.tool().app_new_document_observable:add_notifier(function()
	  rns = renoise.song()
	end)


## LOG and TRACE 

As an alternative to using print statements in your code, you can call the xLib TRACE/LOG methods. 

**LOG** = Print to console  
**TRACE** = Print debug info (when debugging is enabled) 

xLib comes with a dedicated class for debugging called xDebug. Including this class will replace the standard TRACE and LOG methods with more sophisticated versions. 

