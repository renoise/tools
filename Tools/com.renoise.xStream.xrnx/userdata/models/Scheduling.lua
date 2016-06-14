--[[===========================================================================
Scheduling.lua
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
-- Create a burst of scheduled notes
-------------------------------------------------------------------------------
if (xinc == 1) then  
  xbuffer:schedule_line({note_columns = {{note_string = "C-4"}}},3)
  xbuffer:schedule_note_column({note_string="C-4"},2,5)
  xbuffer:schedule_note_column({note_string="C-4"},1,8)
  --xbuffer:schedule_note_column({note_string="C-4"},3,5)
  --xbuffer:schedule_note_column({note_string="C-4"},4,9)
  --xbuffer:schedule_note_column({note_string="C-4"},5,10)
  --xbuffer:schedule_note_column({note_string="C-4"},6,10)
end
]],
}