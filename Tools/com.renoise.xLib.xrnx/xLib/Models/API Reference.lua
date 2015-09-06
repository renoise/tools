--[[============================================================================
ArgsExplained.lua
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
      description = "Specify the instrument number to use",
  },
},
data = {
},
callback = [[
-------------------------------------------------------------------------------
-- Arguments and properties
-------------------------------------------------------------------------------

-- Arguments are specified through the model definition, which is a standard
-- lua file. To open and edit the defition, click 'reveal_in_browser', and 
-- edit the file in a text editor (or use the Renoise scripting console). 

-- These are the possible values and properties you can assign 

-- name (string)
--  A string, specifying the name of the argument as it is accessed  - 
--  avoid using special characters or names beginning with a number.

-- description (string, optional)
--  [Optional] String, provides a description of what the argument does.

-- value (number, boolean or string)
--  The default value. Required, as the underlying argument is an observable
--  whose type is based on this default value. 

-- bind (string, optional)
--  A string that, when evaluated, will return some observable property. 
--  Specify this property to bind the argument to something in Renoise - 
--  for example, "rns.transport.keyboard_velocity_observable". 
--  See also: ArgsBinding.lua

-- poll (string, optional)
--  A string that, when evaluated, will return a value of the same type.
--  Specify this property to connect the argument to something in Renoise - 
--  e.g. "rns.selected_note_column_index". See also: ArgsPolling.lua

-- properties.zero_based (boolean, default = false)
--  Some values in the Renoise API, such as the instrument index, starts 
--  counting from 1, but when written to the pattern it starts from zero - 
--  this property, when set, does the conversion for us. 

-- properties.impacts_buffer (boolean, default = true)
--  If set to false, the buffer will not be refreshed as a result of 
--  changing the argument value. Usually, this is the case, but you might
--  control some aspect of Renoise that does not affect the output
--  (in Automation.lua, for example, we change playmode on-the-fly)


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