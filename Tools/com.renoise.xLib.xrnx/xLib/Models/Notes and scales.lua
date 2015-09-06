--[[============================================================================
HarmonicScale.lua
============================================================================]]--

return {
arguments = {
  {
    name = "current_scale",
    properties = {items = {"None","Natural Major","Natural Minor"}},
    value = 2,
    description = "Specify which scale to use",
  }
},
data = {
  harmonic_scales = {
    {1,1,1,1,1,1,1,1,1,1,1,1},
    {1,0,1,0,1,1,0,1,0,1,0,1},
    {1,0,1,1,0,1,0,1,1,0,1,0},
  }
},
callback = [[
-------------------------------------------------------------------------------
-- Restricting to a harmonic scale
-------------------------------------------------------------------------------

-- In this example, we are going to restrict existing notes, according to the 
-- selected scale. The scales are defined as user data, and switching is done 
-- via the "current_scale" argument 

local restrict_to_scale = function(note)
  local scale = data.harmonic_scales[args.current_scale]
  local key = note%12
  local tmp_key = key
  while (scale[tmp_key] == 0) do
    tmp_key = tmp_key-1
  end
  return (note - (key-tmp_key))
end

line.note_columns[1] = {
  note_value = restrict_to_scale(line.note_columns[1].note_value),
}

]],
}
  
