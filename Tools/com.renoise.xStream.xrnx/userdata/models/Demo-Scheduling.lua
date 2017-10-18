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

-- scheduling happens on the very first line - this model doesn't 
-- do anything beyond that point ... 

if (xinc == 0) then  

  -- schedule three note columns for line #00:
  
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