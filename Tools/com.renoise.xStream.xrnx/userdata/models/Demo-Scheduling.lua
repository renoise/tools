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
-- Most models are generating/transforming pattern data on a line-by-line
-- basis, but it's possible to schedule things to happen at a later time too,
-- by using the schedule_line/note_column/effect_column() methods.
-------------------------------------------------------------------------------

-- all scheduling happens on the first line: 
if (xinc == 1) then  

  -- ==== schedule a whole line ====
  -- (the last argument is the buffer position)

  xbuffer:schedule_line({
    note_columns = {
      {note_string = "C-4"},
      {note_string = "D-4"},      
      {note_string = "E-4"},      
     }
    },3) -- buffer position

  -- ==== schedule note columns ====
  -- (the last two arguments are column index and buffer position)

  xbuffer:schedule_note_column({note_string="C-4"},3,5)
  xbuffer:schedule_note_column({note_string="C-4"},1,8)

  -- ==== schedule effect columns ====
  -- (the last two arguments are column index and buffer position)

  xbuffer:schedule_effect_column({number_string="11"},1,3)
  xbuffer:schedule_effect_column({
    number_string = "0Z",
    amount_string = "22"
  },1,2)
  
end
]],
}