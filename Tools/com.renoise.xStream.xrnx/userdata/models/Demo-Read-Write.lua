--[[===========================================================================
Demo - Read & Write.lua
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
-- Demonstrates how xStream is both reading and writing pattern lines
-- This model will create a C-4 note for every fourth line, and increase the
-- volume as it iterates over those previously created notes
-------------------------------------------------------------------------------
local do_output = xpos.line%4 == 1
if do_output then
  local notecol = xline.note_columns[1]
  if (notecol.note_value == EMPTY_NOTE_VALUE) then 
    notecol.note_value = 48
    notecol.volume_value = 0
  else
    local vol = notecol.volume_value
    notecol.volume_value = (vol+1)%127
  end
end
]],
}