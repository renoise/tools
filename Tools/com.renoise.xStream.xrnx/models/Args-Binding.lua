--[[============================================================================
Args-Binding.lua
============================================================================]]--

return {
arguments = {
  {
      name = "velocity_enabled",
      value = true,
      properties = {},
      bind = "rns.transport.keyboard_velocity_enabled_observable",
      description = "Whether to apply velocity or note",
  },
  {
      name = "velocity",
      value = 83,
      properties = {
          min = 0,
          max = 127,
          --quant = 1,
          display_as = "hex",
      },
      bind = "rns.transport.keyboard_velocity_observable",
      description = "Specify the keyboard velocity",
  },
  {
      name = "instr_idx",
      value = 1,
      properties = {
          min = 1,
          --quant = 1,
          max = 255,
          zero_based = true,
          display_as = "hex",
      },
      bind = "rns.selected_instrument_index_observable",
      description = "Specify the instrument number",
  },
},
presets = {
  {
      velocity_enabled = true,
      velocity = 84,
      instr_idx = 1,
  },
  {
      velocity_enabled = true,
      velocity = 84,
      instr_idx = 1,
  },
},
data = {
},
options = {
 color = 0x60AACA,
},
callback = [[
-------------------------------------------------------------------------------
-- Binding to (observable) properties 
-- Output notes that go from C-3 to B-5 while using the selected instrument
-- in Renoise, and the currently specified keyboard velocity. 
-- Arguments will update value in Renoise and vice versa
---=====================================================-----------------------
-- Bindings are specified in the .lua model definition - reveal this file  
-- by clicking the 'magnifying glass' in the models menu below...

xline.note_columns[1] = {
  note_value = (xinc%36)+36,
  instrument_value = args.instr_idx,
  volume_value = args.velocity_enabled and args.velocity or EMPTY_VOLUME_VALUE,
}  

]],
}