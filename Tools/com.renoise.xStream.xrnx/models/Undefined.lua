--[[============================================================================
Undefined.lua
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
-- Defined vs. undefined 
-------------------------------------------------------------------------------

-- When a callback is running, the default behavior is to receive a full 
-- line from the pattern, populated with whatever notes, effect commands etc.
-- that the song contains at that point in time. 
-- In other words, every line is fully defined to begin with. 

-- But you can choose to 'undefine' any aspect of a line. You can do this 
-- in various ways - all of which will be demonstrated in this example. 

-- What is important to understand about the difference between 'defined'
-- and 'undefined' content is, that 'defined' content will always show up
-- when writing output. 'Undefined' content, on the other hand, can either 
-- be cleared, or leave existing content intact.

-- You control what will happen by using the 'clear_undefined' flag. The flag
-- can be set anywhere in a callback, and will affect the entire output
-- clear_undefined = false  -- uncomment line to apply in realtime

-- OK, let's study a couple of practical examples

-- Set a note_value as undefined, but leave the existing data intact
xline.columns[1].note_value = nil

-- Undefine an single note column, leave the rest intact
xline.columns[1] = {}

-- Undefine everything 
xline = EMPTY_LINE

-- Undefine all note columns, leave the rest intact
xline.note_columns = EMPTY_NOTE_COLUMNS

-- Undefine all effect columns, leave the rest intact
xline.effect_columns = EMPTY_EFFECT_COLUMNS

-- Alternatively, you could also specify an empty effect column like this
xline.effect_columns = {{},{},{},{},{},{},{},{},} 
-- Note: what you see above is the _actual_ value of EMPTY_EFFECT_COLUMNS,
-- it's just more awkward to type out so many empty tables... 


]],
}