--[[============================================================================
Transpose.lua
============================================================================]]--

return {
arguments = {
},
data = {
},
callback = [[
-------------------------------------------------------------------------------
-- Apply transpose to existing notes
-------------------------------------------------------------------------------
-- This callback is evaluated each time that notes are crossed - 
-- it will continue transposing, until all note are at their lowest 
-- possible value (C-0). Leaves note-OFF and empty notes intact.

if (line.note_columns[1].note_value < 120) then
  line.note_columns[1].note_value = line.note_columns[1].note_value - 1
end















]],
}