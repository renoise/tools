--[[============================================================================
UsingData.lua
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
},
data = {
  current_pitch = 36,
},
callback = [[
-------------------------------------------------------------------------------
-- Using user data in callbacks
-------------------------------------------------------------------------------

-- Usually, any variables you define in a callback will only "live" for 
-- the duration of that single callback. This is why (user-)data are handy, 
-- as they can be freely specified (supports all basic lua types) and provide 
-- your callback with a storage mechanism. 

-- You need to specify your data in the definition, after which you can 
-- access it like this: 'data.name_of_your_data'

-- OK, now for an example implementation. We are going to add a 'counter' to
-- our callback, so we can increase the note pitch each time a note is being
-- written to the pattern (with random intervals to make it interesting). 

-- First, let's decide if we are going to produce any output: 
local produce_output = (math.random(0,5) == 0)

-- *If* we are going to produce output, we raise the "current_pitch" 
-- by one and store this as the new value

if (produce_output) then
  data.current_pitch = data.current_pitch + 1
  -- restrict pitch to within the middle range 36-60
  if (data.current_pitch > 60) then
    data.current_pitch = 36
  end

  -- Now, we are ready to produce output 
  line = {
    note_columns = {
      {
        note_value = data.current_pitch,
        instrument_value = args.instr_idx,
      },
    },
  }

else
  -- Empty when no output
  line = {}

end





]],
}