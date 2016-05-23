--[[===========================================================================
Euclidean Rhythms 2.lua
===========================================================================]]--

return {
arguments = {
  {
      name = "a_steps",
      value = 13,
      properties = {
          min = 1,
          max = 32,
          display_as = "integer",
          zero_based = false,
      },
      description = "",
  },
  {
      name = "a_pulses",
      value = 5,
      properties = {
          min = 1,
          max = 32,
          display_as = "integer",
          zero_based = false,
      },
      description = "",
  },
  {
      name = "a_offset",
      value = 4,
      properties = {
          min = -16,
          max = 16,
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
      description = "make notes become rests and vice versa",
  },
  {
      name = "a_stretch",
      value = false,
      properties = {
          display_as = "checkbox",
      },
      description = "enable 'stretch' to make notes arrive with even spacing ",
  },
  {
      name = "a_cyclelength",
      value = 12,
      properties = {
          min = 0,
          max = 255,
          display_as = "integer",
          zero_based = false,
      },
      description = "restart cycle every n number of lines",
  },
  {
      name = "a_lock_cycle",
      value = true,
      properties = {
          display_as = "checkbox",
      },
      description = "When enabled, cycle length is locked to step count. When disabled, length is determined by cycle_length",
  },
  {
      name = "a_blanknotes",
      value = false,
      properties = {
          display_as = "checkbox",
      },
      description = "do not paste rests, and paste blank lines as notes (a mute generator)",
  },
  {
      name = "a_pitch",
      value = 36,
      properties = {
          max = 119,
          display_as = "note",
          min = 0,
      },
      description = "",
  },
  {
      name = "a_instrument",
      value = 0,
      properties = {
          max = 128,
          min = 0,
          display_as = "hex",
          zero_based = false,
      },
      description = "",
  },
  {
      name = "a_velocity",
      value = 128,
      properties = {
          max = 128,
          min = 0,
          display_as = "hex",
          zero_based = false,
      },
      description = "",
  },
  {
      name = "a_column",
      value = 5,
      properties = {
          max = 12,
          min = 1,
          display_as = "integer",
          zero_based = false,
      },
      description = "",
  },
},
presets = {
  {
      a_offset = 0,
      a_column = 1,
      a_steps = 16,
      a_pitch = 36.23781479452,
      a_instrument = 0,
      a_cyclelength = 32,
      a_stretch = false,
      name = "16-6-0",
      a_lock_cycle = true,
      a_velocity = 128,
      a_invert = false,
      a_blanknotes = false,
      a_pulses = 6,
  },
  {
      a_offset = 4,
      a_column = 2,
      a_steps = 16,
      a_pitch = 37,
      a_instrument = 0,
      a_cyclelength = 12,
      a_stretch = false,
      name = "16-2-4",
      a_lock_cycle = true,
      a_velocity = 128,
      a_invert = false,
      a_blanknotes = false,
      a_pulses = 2,
  },
  {
      a_offset = 0,
      a_column = 3,
      a_steps = 14,
      a_pitch = 38,
      a_instrument = 0,
      a_cyclelength = 12,
      a_stretch = false,
      name = "14-9-0",
      a_lock_cycle = true,
      a_velocity = 128,
      a_invert = false,
      a_blanknotes = false,
      a_pulses = 9,
  },
  {
      a_offset = 1,
      a_column = 4,
      a_steps = 14,
      a_pitch = 39,
      a_instrument = 0,
      a_cyclelength = 12,
      a_stretch = false,
      name = "14-4-1",
      a_lock_cycle = true,
      a_velocity = 128,
      a_invert = false,
      a_blanknotes = false,
      a_pulses = 4,
  },
  {
      a_offset = 4,
      a_column = 5,
      a_steps = 13,
      a_pitch = 36,
      a_instrument = 0,
      a_cyclelength = 12,
      a_stretch = false,
      name = "13-5-4",
      a_lock_cycle = true,
      a_velocity = 128,
      a_invert = false,
      a_blanknotes = false,
      a_pulses = 5,
  },
},
data = {
},
options = {
 color = 0x69997A,
},
callback = [[
-------------------------------------------------------------------------------
-- Euclidean Rhythms 
-------------------------------------------------------------------------------

local generate = function(steps,pulses,offset,pitch,instrument,velocity,column,lock_cycle,cyclelength,invert,stretch,blanknotes)
  local rslt = nil
  local step_size = steps/pulses
  local cyclemod = (xinc%cyclelength)
  local position = lock_cycle and (xinc%steps) or (cyclemod%steps) 
  local pulses_table = {}
  local pulses_full = {}
  local pulses_fract = {}
  for k = 0,(pulses-1) do
    local pulse = (step_size * k) + offset
    local pulse_mod = (pulse % steps)
    --local pulse_mod = (pulse % cyclemod)
    
    local pulse_fract = {}
    if stretch then
      pulse_fract = pulse_mod-math.floor(pulse_mod)
      table.insert(pulses_table,math.floor(pulse_mod))
    else
      pulse_fract = pulse_mod-math.ceil(pulse_mod)
      table.insert(pulses_table,math.ceil(pulse_mod))    
    end
    table.insert(pulses_fract,pulse_fract)
    table.insert(pulses_full,pulse_mod + pulse_fract)
  end
  local do_output = table.find(pulses_table,position)
  --print("do_output",do_output)  
  if invert then 
    do_output = not do_output 
  end
  if do_output and not blanknotes then
    xline.note_columns[column] = {
      note_value = pitch,
      volume_value = velocity == 0x80 and EMPTY_VOLUME_VALUE or velocity,
      instrument_value = instrument,
      delay_value = math.floor(pulses_fract[do_output] * 255)
    }
  elseif blanknotes then
    if do_output then
      xline.note_columns[column] = {
        volume_value = 255,
        note_value = 121,
        instrument_value = 255,
      }
    end
  else
    xline.note_columns[column] = {}
  end
end
generate(args.a_steps,
  args.a_pulses,
  args.a_offset,
  args.a_pitch,
  args.a_instrument,
  args.a_velocity,
  args.a_column,
  args.a_lock_cycle,
  args.a_cyclelength,
  args.a_invert,
  args.a_stretch,
  args.a_blanknotes)
  







]],
}