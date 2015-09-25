--[[============================================================================
Reference.lua
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
-- What can be defined in a callback? 
-------------------------------------------------------------------------------

-- All standard lua properties and methods, plus:

-- ## Constants ##

-- NOTE_OFF_VALUE = 121 ("OFF")
-- EMPTY_NOTE_VALUE = 120 ("---")
-- EMPTY_VOLUME_VALUE = 255
-- EMPTY_VALUE = 255
-- EMPTY_NOTE_COLUMNS = (table)
-- EMPTY_EFFECT_COLUMNS = (table)
-- EMPTY_XLINE = (table)
-- SUPPORTED_EFFECT_CHARS = (table)

-- ## Properties ##

-- rns  -- shorthand syntax for renoise.song()
-- xinc -- internal line count (ever-increasing)
-- xline -- read/writeable model of renoise.PatternLine
-- xpos -- the position in the song (sequence, line)
-- args -- (table, ObservableXXX) access to model arguments 
-- data -- (table, various) user-data (see section below)

-- ## xStream properties ##

-- track_index (int)
-- device_index (int) 
-- parameter_index (int)
-- mute_mode (xStream.MUTE_MODE)
-- clear_undefined (bool)
-- expand_columns (bool)

-- ## Methods ##

-- Harmonize a note according to the selected scale/key
-- (see xScale for the full implementation details)
-- restrict_to_scale(note_value,scale_index,key_index)

-- ## About data ##

-- Usually, any variables you define in a callback will only live within
-- a single callback. This is why 'data' is handy, as it provides a 
-- storage mechanism for your callback which lives for as long as the
-- model is active. You access data like this: data.name_of_your_data

-- You can specify your data in the model definition, or at runtime, during  
-- execution of the callback method. If you choose to save your definition, 
-- runtime-created data will not be stored as part of that definition. 

-- ## About arguments (args) ##

-- Arguments are specified through the model definition, which is a standard
-- lua file. To open and edit the defition, click 'reveal_in_browser', and 
-- edit the file in a text editor (or use the Renoise scripting console). 

-- These are the possible values and properties you can assign 

-- name (string)
--  A string, specifying the name of the argument as it is accessed  - 
--  avoid using special characters or names beginning with a number.

-- description (string, optional)
--  [Optional] String, provides a description of what the argument does.

-- value (number, boolean or string)
--  The default value. Required, as the underlying argument is an observable
--  whose type is based on this default value. 

-- bind (string, optional)
--  A string that, when evaluated, will return some observable property. 
--  Specify this property to bind the argument to something in Renoise - 
--  for example, "rns.transport.keyboard_velocity_observable". 
--  See also: ArgsBinding.lua

-- poll (string, optional)
--  A string that, when evaluated, will return a value of the same type.
--  Specify this property to connect the argument to something in Renoise - 
--  e.g. "rns.selected_note_column_index". See also: ArgsPolling.lua

-- properties.zero_based (boolean, default = false)
--  Some values in the Renoise API, such as the instrument index, starts 
--  counting from 1, but when written to the pattern it starts from zero - 
--  this property, when set, does the conversion for us. 

-- properties.impacts_buffer (boolean, default = true)
--  If set to false, the buffer will not be refreshed as a result of 
--  changing the argument value. Usually, this is the case, but you might
--  control some aspect of Renoise that does not affect the output
--  (in Automation.lua, for example, we change playmode on-the-fly)





]],
}