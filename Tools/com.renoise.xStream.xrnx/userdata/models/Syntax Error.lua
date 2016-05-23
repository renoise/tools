--[[============================================================================
Syntax Error.lua
============================================================================]]--

return {
	arguments = {
		{
      name = "foo", 
      value = 1, 
    },
		{
      name = "foo", 
      value = 1, 
      description = "Duplicate argument name is not allowed"
    },
		{
      name = 123, 
      value = 1, 
      description = "Name needs to be a string"
    },
		{
      name = "bar", 
      description = "Need a default value, or type would be ambiguous"
    },
		
	},
	callback = [[
-------------------------------------------------------------------------------
-- Here be dragons
-- (xStream will refuse to load this example, as it contains syntax errors)
-------------------------------------------------------------------------------

-- Restricted variables or methods ------------------------

-- Accessing the file system 
io.open("some_path","w") 

-- Redefining the function environment
setfenv(1,{}) 

-- Syntax related mistakes --------------------------------

-- Including a comma at the end of a table definition
some_table = {
	item_1 = {},
	item_2 = {},
	item_3 = {},
}, -- oops!

--[[ Inline block comments ]]

local multiline_string = [[Actually, this is valid lua,
but not supported in a callback context. The reason is that the callback is 
itself stored as a multiline string]],

}
  
