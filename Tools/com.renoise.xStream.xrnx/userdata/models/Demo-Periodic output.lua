--[[===========================================================================
Demo-Periodic output.lua
===========================================================================]]--

return {
arguments = {
  {
      ["description"] = "Specify the instrument number",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "instr_idx",
      ["properties"] = {
          ["display_as"] = "hex",
          ["max"] = 255,
          ["min"] = 1,
          ["zero_based"] = true,
      },
      ["value"] = 1,
  },
  {
      ["description"] = "",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "notecol_idx",
      ["properties"] = {
          ["display_as"] = "integer",
          ["max"] = 12,
          ["min"] = 1,
          ["zero_based"] = false,
      },
      ["value"] = 1,
  },
  {
      ["description"] = "",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "note_value",
      ["properties"] = {
          ["display_as"] = "note",
          ["max"] = 119,
          ["min"] = 0,
      },
      ["value"] = 36,
  },
  {
      ["description"] = "Specify the number of steps in the sequence",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "interval",
      ["properties"] = {
          ["display_as"] = "integer",
          ["max"] = 32,
          ["min"] = 1,
      },
      ["value"] = 4,
  },
  {
      ["description"] = "Specify the sequence offset",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "offset",
      ["properties"] = {
          ["display_as"] = "integer",
          ["max"] = 32,
          ["min"] = -32,
      },
      ["value"] = 0,
  },
  {
      ["description"] = "Decide if note is followed by a note-off",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "produce_note_off",
      ["properties"] = {},
      ["value"] = false,
  },
},
presets = {
  {
      ["instr_idx"] = 1,
      ["interval"] = 4,
      ["name"] = "Bass Drum",
      ["note_value"] = 36,
      ["notecol_idx"] = 1,
      ["offset"] = 0,
      ["produce_note_off"] = false,
  },
  {
      ["instr_idx"] = 1,
      ["interval"] = 8,
      ["name"] = "Snare Drum",
      ["note_value"] = 38,
      ["notecol_idx"] = 1,
      ["offset"] = 4,
      ["produce_note_off"] = false,
  },
  {
      ["instr_idx"] = 1,
      ["interval"] = 2,
      ["name"] = "Closed Hihat",
      ["note_value"] = 42,
      ["notecol_idx"] = 1,
      ["offset"] = 1,
      ["produce_note_off"] = false,
  },
  {
      ["instr_idx"] = 1,
      ["interval"] = 4,
      ["name"] = "Open Hihat",
      ["note_value"] = 46,
      ["notecol_idx"] = 1,
      ["offset"] = 2,
      ["produce_note_off"] = false,
  },
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
-- Repeating notes (intervals)
-- An example of how to create repeating notes with a custom interval. 
-- You could use this for rhythmic purposes by creating various presets 
-- for kick, snare, hihat and so on... 
-------------------------------------------------------------------------------
 
local incr_offset = xinc + args.offset
 
if (incr_offset % args.interval == 0) then
  xline.note_columns[args.notecol_idx] = {
    note_value = 36,
    instrument_value = args.instr_idx
  }
elseif args.produce_note_off and (incr_offset % args.interval == 1) then
  xline.note_columns[args.notecol_idx] = {
    note_value = 120
  }
else
  xline.note_columns[args.notecol_idx] = {}
end
]],
}