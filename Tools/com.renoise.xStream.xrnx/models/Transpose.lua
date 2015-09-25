--[[============================================================================
Transpose.lua
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
-- Apply transpose to existing notes in first note-column
-------------------------------------------------------------------------------
-- This callback is evaluated each time that notes are crossed - 
-- it will continue transposing, until all note are at their lowest 
-- possible value (C-0). Leaves note-OFF and empty notes intact.

if (xline.note_columns[1].note_value < 120) then
  xline.note_columns[1].note_value = xline.note_columns[1].note_value - 1
end

















]],
}