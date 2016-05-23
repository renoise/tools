--[[============================================================================
Random increase.lua
============================================================================]]--

return {
arguments = {
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
},
data = {
  current_pitch = 14,
},
options = {
 color = 0x505552,
},
callback = [[
-------------------------------------------------------------------------------
-- Using user data in callbacks
-- In this example, a 'current_pitch' is defined in our user-data. 
-- We increment this value each time a note is written to the pattern
-- Tip: loop, and disable 'clear_undefined' to make it more interesting!!
-------------------------------------------------------------------------------

local produce_output = (math.random(0,5) == 0)
if (produce_output) then
  data.current_pitch = data.current_pitch + 1
  -- restrict pitch to within the middle range 36-60
  if (data.current_pitch > 60) then
    data.current_pitch = 36
  end

  -- Now, we are ready to produce output 
  xline.note_columns[1] = {
    note_value = data.current_pitch,
    instrument_value = args.instr_idx,
  }
else
  xline.note_columns[1] = {}
end


]],
}