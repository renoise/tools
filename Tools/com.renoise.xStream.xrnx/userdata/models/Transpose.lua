--[[===========================================================================
Transpose.lua
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
 color = 0x505552,
},
callback = [[
-------------------------------------------------------------------------------
-- Apply transpose to notes 
-- Demonstrates how pattern data is not only written, but also read: 
-- the model will continue transposing, until all note are at their lowest 
-- possible value (C-0). Leaves note-OFF and empty notes intact.
-------------------------------------------------------------------------------

if (xline.note_columns[1].note_value < 120) then
  xline.note_columns[1].note_value = xline.note_columns[1].note_value - 1
end
]],
}