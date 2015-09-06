--[[============================================================================
Periodic output.lua
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
      name = "interval",
      value = 3,
      properties = {
          min = 1,
          quant = 1,
          max = 32,
      },
      description = "Specify the number of steps in the sequence",
  },
},
data = {
},
callback = [[
-------------------------------------------------------------------------------
-- Create notes with different intervals
-------------------------------------------------------------------------------

if (INCR % args.interval == 0) then
  line.note_columns[1] = {
    note_value = math.random(24,48),
    instrument_value = args.instr_idx
  }
elseif (INCR % args.interval == 1) then
  line.note_columns[1] = {
    note_value = 120
  }
else
  line.note_columns[1] = {}
end



]],
}