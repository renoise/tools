--[[============================================================================
Simple.lua
============================================================================]]--

return {
arguments = {
  {
      name = "instr_idx",
      value = 1,
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
      name = "volume",
      value = 128,
      properties = {
          max = 128,
          min = 0,
      },
      description = "Specify the general volume level",
  },
},
data = {
},
callback = [[
-------------------------------------------------------------------------------
-- A simple example, creating random notes in two columns
-- (enable 'expand columns' to reveal columns as they are written to)
-------------------------------------------------------------------------------

line.note_columns = {
  {
    note_value = math.random(36,48),
    instrument_value = args.instr_idx,
    volume_value = args.volume,
  },
  {
    note_value = math.random(48,60),
    instrument_value = args.instr_idx,
    volume_value = args.volume,
  
  }
}

]],
}