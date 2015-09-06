--[[============================================================================
ArgsBinding.lua
============================================================================]]--

return {
arguments = {
  {
      name = "velocity",
      value = 51,
      properties = {
          min = 0,
          quant = 1,
          max = 127,
          display_as_hex = true,
      },
      bind = "rns.transport.keyboard_velocity_observable",
      description = "Specify the keyboard velocity",
  },
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
},
data = {
},
callback = [[
-------------------------------------------------------------------------------
-- Binding arguments to observable properties 
-------------------------------------------------------------------------------

-- In the Renoise API, most properties come in two flavours: the actual value, 
-- accompanied by it's observable. For example, here is keyboard velocity:
--  => rns.transport.keyboard_velocity
--  => rns.transport.keyboard_velocity_observable

-- Usually, you would access the value via the first one, or attach a 
-- 'notifier' to the second, in order to recieve notifications as the value
-- has changed. 

-- But when working in a callback, it's recommended to use another approach: 
-- instead of manually requesting the keyboard velocity, we instead 'bind' the 
-- observable values to an argument. Apart from simplifying the code and
-- always keeping the renoise property and argument values in sync, this 
-- has the advantage that the buffer is refreshed on each value-change. 

-- To see the actual how the binding is specified, open the model definition
-- in a text editor (click 'reveal_in_browser' to locate the file)

line = {
  note_columns = {
    {
      note_value = math.random(36,60),
      instrument_value = args.instr_idx,
      volume_value = args.velocity,
    }  
  }
}

]],
}