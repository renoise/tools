# About cLib

cLib is pure lua library which can make scripting with the Renoise API a bit easier.  
The library contains methods for working with the file system, basic data-types (string, table and so on), as well other lua/Renoise API-specific details. 

## Documentation

Point your browser to this location to browse the auto-generated luadocs:
https://renoise.github.io/luadocs/clib

## Debugging with cLib

As an alternative to using print statements in your code, you can call the  TRACE/LOG methods. 

**LOG** = Print to console  
**TRACE** = Print debug info (when debugging is enabled) 

cLib comes with a dedicated class for debugging called cDebug. Including this class will replace the standard TRACE and LOG methods with more sophisticated versions. 

