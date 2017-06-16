--[[===========================================================================
Transpose.lua
===========================================================================]]--

return {
arguments = {
  {
      ["description"] = "",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "semitones",
      ["properties"] = {
          ["display_as"] = "integer",
          ["max"] = 120,
          ["min"] = -120,
          ["zero_based"] = false,
      },
      ["value"] = 2,
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
-- Simple transpose 
-- Will apply transpose to all notes by @semitones
-------------------------------------------------------------------------------

for k = 1,#xline.note_columns do
  local note_col = xline.note_columns[k]
  if note_col.note_value and                  -- only when a note is set
    (note_col.note_value < EMPTY_NOTE_VALUE)  -- and not empty/note-off
  then
    local new_note = note_col.note_value + args.semitones
    note_col.note_value = cLib.clamp_value(new_note,0,119)
  end
end
]],
}