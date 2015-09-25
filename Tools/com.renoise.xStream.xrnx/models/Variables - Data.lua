--[[============================================================================
Variables - Data.lua
============================================================================]]--

return {
arguments = {
},
presets = {
},
data = {
},
callback = [[
-------------------------------------------------------------------------------
-- About variables and user-data
-------------------------------------------------------------------------------

-- First, some lua basics

-- A local variable will only live for as the callback is evaluated...
-- local im_here_for_a_moment = "some_value"

-- A global variable will continue to live, as long as the callback exists...
-- (a global variable is defined by leaving out the 'local' identifier)
-- im_here_to_stay = "some_value"

-- That's nice and all, but often you want to define things only _once_ 
-- It's annoying having to check if you have created e.g. a table object
-- before you can start using it. Here is an example:
--
-- if not my_awesome_table then       -- check for existence
--  my_awesome_table = {}             -- create the table
-- end
-- my_awesome_table[1] = "some_value" -- assign value

-- This is why 'data' is handy, as it provides a storage mechanism for your 
-- callback, which you can read from or modify as you like. And because data
-- can be specified in the model definition, you are free to initialize it
-- in any way you see fit. 

-- So, the previous example could instead be reduced to 
-- data.my_awesome_table[1] = "some_value"

-- You can specify your data in the model definition, or at runtime, during  
-- execution of the callback method. If you choose to save your definition
-- during execution, any runtime-created data will not be stored as part of 
-- that definition. 




]],
}