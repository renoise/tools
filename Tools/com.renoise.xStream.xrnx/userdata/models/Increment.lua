--[[===========================================================================
Increment.lua
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
 color = 0xC9B36D,
},
callback = [[
-------------------------------------------------------------------------------
-- Increment (xinc)
-- The global incrementor, 'xinc', is an ever-increasing line counter,
-- and essential if you want to produce movement over time
-------------------------------------------------------------------------------

-- write looping values (0x10-0x30) into the volume column ... 
xline.note_columns[1] = {
  note_value = xinc 
}
]],
}