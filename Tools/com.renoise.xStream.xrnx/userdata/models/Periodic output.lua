--[[===========================================================================
Periodic output.lua
===========================================================================]]--

return {
arguments = {
  {
      name = "instr_idx",
      value = 1,
      properties = {
          max = 255,
          min = 1,
          display_as = "hex",
          zero_based = true,
      },
      bind = "rns.selected_instrument_index_observable",
      description = "Specify the instrument number",
  },
  {
      name = "interval",
      value = 8,
      properties = {
          min = 1,
          display_as = "integer",
          max = 32,
      },
      description = "Specify the number of steps in the sequence",
  },
  {
      name = "offset",
      value = 4,
      properties = {
          min = -32,
          display_as = "integer",
          max = 32,
      },
      description = "Specify the sequence offset",
  },
  {
      name = "produce_note_off",
      value = true,
      properties = {},
      description = "Decide if note is followed by a note-off",
  },
},
presets = {
},
data = {
},
options = {
 color = 0x505552,
},
callback = [[
-------------------------------------------------------------------------------
-- Repeating notes (intervals)
-- An example of how to create repeating notes with a custom interval. 
-- You could use this for rhythmic purposes by creating various presets 
-- for kick, snare, hihat and so on... 
-------------------------------------------------------------------------------

local incr_offset = xinc + args.offset

if (incr_offset % args.interval == 0) then
  xline.note_columns[1] = {
    note_value = 36,
    instrument_value = args.instr_idx
  }
elseif args.produce_note_off and (incr_offset % args.interval == 1) then
  xline.note_columns[1] = {
    note_value = 120
  }
else
  xline.note_columns[1] = {}
end







]],
}