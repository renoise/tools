--[[============================================================================
Globals.lua
============================================================================]]--

return {
arguments = {
},
data = {
},
callback = [[
-------------------------------------------------------------------------------
-- The most important globals 
-------------------------------------------------------------------------------

-- Constants

-- INCR -- internal line count (ever-increasing)
-- NOTE_OFF_VALUE = 121 ("OFF")
-- EMPTY_NOTE_VALUE = 120 ("---")
-- EMPTY_VALUE = 255

-- Variables 

-- rns  -- shorthand syntax for renoise.song()
-- args -- (table, ObservableXXX) access to model arguments 
-- data -- (table, various) read/write access to user-data
-- xstream -- (xStream) access to certain flags
--  .track_index (int) <- pattern
--  .device_index (int) <- automation
--  .parameter_index (int) <- automation
--  .mute_mode (xStream.MUTE_MODE)
--  .clear_undefined (bool)
--  .expand_columns (bool)
--

-- About 'data'
-- Usually, any variables you define in a callback will only live within
-- a single callback. This is why 'data' is handy, as it provides a 
-- storage mechanism for your callback
-- You need to specify your data in the definition, after which you can 
-- access it like this: 'data.name_of_your_data'





]],
}