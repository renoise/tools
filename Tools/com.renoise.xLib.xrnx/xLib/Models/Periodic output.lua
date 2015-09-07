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
      value = 8,
      properties = {
          min = 1,
          quant = 1,
          max = 32,
      },
      description = "Specify the number of steps in the sequence",
  },
  {
      name = "offset",
      value = 4,
      properties = {
          min = -32,
          quant = 1,
          max = 32,
      },
      description = "Specify the sequence offset",
  },
  {
      name = "produce_note_off",
      value = true,
      --properties = {},
      description = "Decide if note is followed by a note-off",
  },
},
data = {
},
callback = [[
-------------------------------------------------------------------------------
-- Create notes with different intervals
-------------------------------------------------------------------------------

local incr_offset = INCR + args.offset

if (incr_offset % args.interval == 0) then
  line.note_columns[1] = {
    note_value = 36,
    instrument_value = args.instr_idx
  }
elseif args.produce_note_off and (incr_offset % args.interval == 1) then
  line.note_columns[1] = {
    note_value = 120
  }
else
  line.note_columns[1] = {}
end




]],
}