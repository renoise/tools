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
options = {
 color = 0x505552,
},
callback = [[
-------------------------------------------------------------------------------
-- What can be defined in a callback? 
-- + All standard lua properties and methods, plus:
-------------------------------------------------------------------------------
-- ## Constants ##
-- NOTE_OFF_VALUE = 121 ("OFF")
-- EMPTY_NOTE_VALUE = 120 ("---")
-- EMPTY_VOLUME_VALUE = 255
-- EMPTY_VALUE = 255
-- EMPTY_NOTE_COLUMNS = (table)
-- EMPTY_EFFECT_COLUMNS = (table)
-- EMPTY_XLINE = (table)
-- SUPPORTED_EFFECT_CHARS = (table)
--------------------------------------------------------------------------------- ## Properties ##
-- rns  -- shorthand syntax for renoise.song()
-- xinc -- internal line count (ever-increasing)
-- xline -- read/writeable model of renoise.PatternLine
-- xpos -- the position in the song (sequence, line)
-- args -- (table, ObservableXXX) access to model arguments 
-- data -- (table, various) user-data (see section below)
------------------------------------------------------------------------------
-- ## xStream properties ##
-- track_index (int)
-- device_index (int) 
-- parameter_index (int)
-- mute_mode (xStream.MUTE_MODE)
-- clear_undefined (bool)
-- expand_columns (bool)
------------------------------------------------------------------------------
-- ## Methods ##
-- Harmonize a note according to the selected scale/key
-- (see xScale for the full implementation details)
-- restrict_to_scale(note_value,scale_index,key_index)
------------------------------------------------------------------------------
-- ## About data ##
-- Usually, any variables you define in a callback will only live within
-- a single callback. This is why 'data' is handy, as it provides a 
-- storage mechanism for your callback which lives for as long as the
-- model is active. You access data like this: data.name_of_your_data
-- You can specify your data in the model definition, or at runtime, during  
-- execution of the callback method. If you choose to save your definition, 
-- runtime-created data will not be stored as part of that definition. 
------------------------------------------------------------------------------
-- ## About arguments (args) ##
-- Arguments are specified through the model definition, which is a standard
-- lua file. To open and edit the defition, click 'reveal_in_browser', and 
-- edit the file in a text editor (or use the Renoise scripting console). 
------------------------------------------------------------------------------
-- ## More info
-- Please see full documentation and forum topic online:
-- www.renoise.com/tools/xstream




]],
}