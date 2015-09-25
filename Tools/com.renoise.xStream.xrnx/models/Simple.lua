--[[============================================================================
Simple.lua
============================================================================]]--

return {
arguments = {
  {
      name = "instr_idx",
      value = 3,
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
      value = 63.944347826087,
      properties = {
          max = 128,
          min = 0,
          display_as_hex = true,
      },
      description = "Specify the general volume level",
  },
},
presets = {
},
data = {
},
callback = [[
-------------------------------------------------------------------------------
-- Simple example
-- Creates random notes in two columns, leave the rest intact
-------------------------------------------------------------------------------

xline.note_columns = {
  {
    note_value = math.random(36,48),
    instrument_value = (xinc%2 == 0) and args.instr_idx or EMPTY_VALUE,
    volume_value = args.volume,
    panning_value = 0x70,
  },
  {
    note_value = math.random(48,60),
    instrument_value = (xinc%2 == 1) and args.instr_idx or EMPTY_VALUE,
    volume_value = args.volume,
    panning_value = 0x10,
  }
}








]],
}