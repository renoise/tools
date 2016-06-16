--[[===========================================================================
Simple.lua
===========================================================================]]--

return {
arguments = {
  {
      ["locked"] = false,
      ["name"] = "instr_idx",
      ["linked"] = false,
      ["value"] = 1,
      ["properties"] = {
          ["max"] = 255,
          ["min"] = 1,
          ["display_as"] = "hex",
          ["zero_based"] = true,
      },
      ["bind"] = "rns.selected_instrument_index_observable",
      ["description"] = "Specify the instrument number",
  },
  {
      ["locked"] = false,
      ["name"] = "volume",
      ["linked"] = false,
      ["value"] = 63.944347826087,
      ["properties"] = {
          ["max"] = 128,
          ["display_as"] = "hex",
          ["min"] = 0,
      },
      ["description"] = "Specify the general volume level",
  },
},
presets = {
},
data = {
},
events = {
},
options = {
 color = 0x505552,
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