--[[===========================================================================
Demo-xLine Basics.lua
===========================================================================]]--

return {
arguments = {
},
presets = {
},
data = {
},
events = {
},
options = {
 color = 0x000000,
},
callback = [[
-------------------------------------------------------------------------------
-- Demo-xLine : accessing Note/EffectColumn properties
-- (open the scripting terminal to view output)
-------------------------------------------------------------------------------

-- Configure variables pointing to first note/effect-column
local notecol = xline.note_columns[1]
local fxcol = xline.effect_columns[1]

-- Display what line we are accessing: 
print(">>> Current line/sequence index: ",xpos.line.."/"..xpos.sequence)

-- READING --

-- Print all properties for the first note-column 
print("note",notecol.note_string,notecol.note_value)
print("instrument",notecol.instrument_string,notecol.instrument_value)
print("volume",notecol.volume_string,notecol.volume_value)
print("panning",notecol.panning_string,notecol.panning_value)
print("delay",notecol.delay_string,notecol.delay_value)
print("effect_number",notecol.effect_number_string,notecol.effect_number_value)
print("effect_amount",notecol.effect_amount_string,notecol.effect_amount_value)

print("number",notecol.number_string,notecol.number_value)
print("amount",notecol.amount_string,notecol.amount_value)

-- WRITING --

-- Alternate between C-4 and note-off using the modulo operator (%)
local note_string = (xinc%2 == 0) and "C-4" or "OFF"

-- Write into the first note column 
notecol.note_string = note_string
notecol.volume_string = "40" -- 0x40 when value (hex)
notecol.panning_string = 255 -- EMPTY_VALUE or 255 when value
notecol.delay_value = math.random(0,255)

-- Write a random delay into the second note column 
local notecol = xline.note_columns[2]
if notecol then
  -- Yay, we have a second note-column (see below)
  xline.note_columns[2].delay_value = math.random(0,255)
else
  -- Note: here we are defining the note-column from scratch
  -- Why? Because we just checked, and it doesn't seem to be defined
  -- This is often the case when "include_hidden" (Options > Output)  
  -- is not enabled - in this case, hidden columns are never read.
  xline.note_columns[2] = {
    delay_value = math.random(0,255)
  }
end
]],
}