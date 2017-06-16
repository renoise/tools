--[[===========================================================================
Demo-Scheduling.lua
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
-- Scheduling output: 
-- Demonstrates how you can schedule content to appear a later point in time
-- In the example, all notes and effects are scheduled on the first line 
-------------------------------------------------------------------------------

if (xinc == 0) then -- do the scheduling on first line

  -- schedule three note columns
  -- NB: these will not be output during realtime streaming, as the 
  -- playback is then already at this line. Pressing "TRK" will however
  -- write them to the pattern (offline processing)
  
  xbuffer:schedule_line({
    note_columns = {
      {note_string = "C-4"},
      {note_string = "D-4"},      
      {note_string = "E-4"},      
     }
    },0) -- buffer position

  -- next, schedule note columns 2 & 3, output at line 1 & 2:

  xbuffer:schedule_note_column({note_string="F-4"},2,1)
  xbuffer:schedule_note_column({note_string="G-4"},3,2)

  -- finally, schedule lines 3 & 4 for effect column #1

  xbuffer:schedule_effect_column({
    number_string="11"
  },1,3)
  xbuffer:schedule_effect_column({
    number_string = "0Z",
    amount_string = "22"
  },1,4)
  
end
]],
}