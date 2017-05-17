--[[===========================================================================
LFO test.lua
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
-- Empty configuration
-------------------------------------------------------------------------------

if not lfo then
  my_lfo = LFO("sine",16, nil, nil, nil, nil, xinc)
end

-- Use this as a template for your own creations. 
xline.note_columns[1].volume_value = get_lfo(my_lfo)
]],
}