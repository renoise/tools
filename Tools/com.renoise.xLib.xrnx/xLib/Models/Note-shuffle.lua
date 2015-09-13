--[[============================================================================
Note-shuffle.lua
============================================================================]]--

return {
arguments = {
  {
      name = "instr_idx",
      value = 7,
      properties = {
          min = 1,
          quant = 1,
          max = 255,
          zero_based = true,
          display_as_hex = true,
      },
      bind = "rns.selected_instrument_index_observable",
      description = "Specify the instrument number",
  },
  {
      name = "num_steps",
      value = 3,
      properties = {
          min = 1,
          quant = 1,
          max = 32,
      },
      description = "Specify the number of steps in the sequence",
  },
  {
      name = "volume",
      value = 128,
      properties = {
          max = 128,
          min = 0,
      },
      description = "Specify the general volume level",
  },
  {
      name = "shuffle",
      value = 0.26,
      properties = {
          max = 1,
          min = 0,
      },
      description = "Control the amount of shuffle",
  },
},
data = {
},
callback = [[
-------------------------------------------------------------------------------
-- Control the amount of shuffle (delay on every second note)
-- Don't forget to enable the delay column 
-------------------------------------------------------------------------------
local arp_index = (xinc)%args.num_steps
xline.note_columns[1] = 
{
  note_value = arp_index + (arp_index%2 == 1 and 36 or 24),
  instrument_value = args.instr_idx,
  volume_value = args.volume,
  delay_value = (xinc%2 == 1) and math.floor(255*args.shuffle) or 0,
}

]],
}