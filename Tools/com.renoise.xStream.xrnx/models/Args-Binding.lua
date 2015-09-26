--[[============================================================================
API - Binding.lua
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
      value = 45,
      properties = {
          min = 0,
          max = 127,
          quant = 1,
          display_as_hex = true,
      },
      bind = "rns.transport.keyboard_velocity_observable",
      description = "Specify the keyboard velocity",
  },
  {
      name = "instr_idx",
      value = 5,
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
},
presets = {
},
data = {
},
callback = [[
-------------------------------------------------------------------------------
-- Binding arguments to observable properties 
-------------------------------------------------------------------------------

-- In the lua code for this example (the model defition), we have specified
-- that our arguments are bound to these observable properties:
--
--   velocity_enabled  => rns.keyboard_velocity_enabled_observable
--   velocity         => rns.keyboard_velocity_observable
--   instr_idx        => rns.selected_instrument_index
--
-- To see how the binding is specified, open the model definition in a 
-- text editor by clicking the 'reveal_location' button just below.
-- Apart from keeping the renoise property and argument values in sync, 
-- bind has the advantage that buffers are automatically refreshed 

xline.note_columns[1] = {
  note_value = (xinc%36)+36,
  instrument_value = args.instr_idx,
  volume_value = args.velocity_enabled and args.velocity or EMPTY_VOLUME_VALUE,
}  


]],
}