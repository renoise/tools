--[[===========================================================================
Euclidean Rhythms.lua
===========================================================================]]--

return {
arguments = {
  {
      name = "a_steps",
      value = 16,
      properties = {
          max = 32,
          min = 1,
          display_as = "integer",
          zero_based = false,
      },
      description = "",
  },
  {
      name = "a_pulses",
      value = 6,
      properties = {
          max = 32,
          min = 1,
          display_as = "integer",
          zero_based = false,
      },
      description = "",
  },
  {
      name = "a_offset",
      value = 0,
      properties = {
          max = 16,
          min = -16,
          display_as = "integer",
          zero_based = false,
      },
      description = "",
  },
  {
      name = "a_invert",
      value = false,
      properties = {
          display_as = "checkbox",
      },
      description = "makes note-on become note-off and vice versa",
  },
  {
      name = "a_pitch",
      value = 36.23781479452,
      properties = {
          max = 119,
          display_as = "note",
          min = 0,
      },
      description = "",
  },
  {
      name = "a_velocity",
      value = 128,
      properties = {
          min = 0,
          max = 128,
          display_as = "hex",
          zero_based = false,
      },
      description = "",
  },
  {
      name = "a_column",
      value = 1,
      properties = {
          min = 1,
          max = 12,
          display_as = "integer",
          zero_based = false,
      },
      description = "",
  },
},
presets = {
  {
      name = "",
      a_offset = 0,
      a_column = 1,
      a_steps = 16,
      a_pitch = 36.23781479452,
      a_invert = false,
      a_velocity = 128,
      a_pulses = 6,
  },
},
data = {
},
options = {
 color = 0x000000,
},
callback = [[
-------------------------------------------------------------------------------
-- Euclidean Rhythms
-------------------------------------------------------------------------------

local generate = function(steps,pulses,offset,invert,pitch,velocity,column)
  local rslt = nil
  local step_size = steps/pulses
  local position = (xinc%steps)
  local pulses_table = {}
  for k = 0,(pulses-1) do
    local pulse = math.ceil(step_size * k)+offset
    table.insert(pulses_table,pulse % steps)
  end
  local do_output = table.find(pulses_table,position)
  if invert then 
    do_output = not do_output 
  end
  if do_output then
    xline.note_columns[column] = {
      note_value = pitch,
      volume_value = velocity == 0x80 and EMPTY_VOLUME_VALUE or velocity
    }
  else
    xline.note_columns[column] = {}
  end
end

generate(args.a_steps,
  args.a_pulses,
  args.a_offset,
  args.a_invert,
  args.a_pitch,
  args.a_velocity,
  args.a_column)
  
-- here are some additional generators 
-- (arguments are specified manually...)
generate(16,2,4,false,49,0x60,2)
generate(11,4,0,false,50,0x40,3)
generate(14,4,1,false,51,0x60,4)
generate(13,5,4,false,52,0x60,5)



]],
}