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
-- Create a burst of scheduled events
-------------------------------------------------------------------------------
if (xinc == 1) then  
  -- scheduling a whole line (will clear existing)
  xbuffer:schedule_line({note_columns = {{note_string = "C-4"}}},3)  
  -- scheduling note columns (will retain other content)
  xbuffer:schedule_note_column({note_string="C-4"},2,5)
  xbuffer:schedule_note_column({note_string="C-4"},1,8)
  -- scheduling effect columns (will retain other content)
  xbuffer:schedule_effect_column({value_string="11"},1,3)
  xbuffer:schedule_effect_column({amount_string="22"},1,4)
end
]],
}