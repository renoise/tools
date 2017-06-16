--[[===========================================================================
→ InstrRemap.lua
===========================================================================]]--

return {
arguments = {
  {
      ["description"] = "",
      ["linked"] = false,
      ["locked"] = true,
      ["name"] = "instr_index",
      ["properties"] = {
          ["display_as"] = "hex",
          ["max"] = 254,
          ["min"] = 0,
          ["zero_based"] = false,
      },
      ["value"] = 1,
  },
},
presets = {
},
data = {
},
events = {
},
options = {
 color = 0x000000,
},
callback = [[
-------------------------------------------------------------------------------
-- Set instrument index 
-- For all notes, or individually for each note column
-- TODO Specify a specific instrument index to remap only that one
-------------------------------------------------------------------------------

for k = 1,#xline.note_columns do
  local note_col = xline.note_columns[k]
  if note_col.note_value and                  -- only when a note is set
    (note_col.note_value < EMPTY_NOTE_VALUE)  -- and not empty/note-off
  then
    note_col.instrument_value = args.instr_index
  end
end
]],
}