--[[===========================================================================
Demo-Increment.lua
===========================================================================]]--

return {
arguments = {
  {
      ["locked"] = false,
      ["name"] = "volume",
      ["linked"] = false,
      ["value"] = 0,
      ["properties"] = {
          ["zero_based"] = false,
          ["max"] = 100,
          ["display_as"] = "hex",
          ["min"] = 0,
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "basenote",
      ["linked"] = false,
      ["value"] = 38.2,
      ["properties"] = {
          ["min"] = 0,
          ["fire_on_start"] = false,
          ["display_as"] = "note",
          ["max"] = 120,
      },
      ["description"] = "",
  },
},
presets = {
  {
      ["name"] = "C-4",
      ["basenote"] = 48.2,
      ["volume"] = 37,
  },
  {
      ["name"] = "D-3",
      ["basenote"] = 38.2,
      ["volume"] = 0,
  },
},
data = {
},
events = {
},
options = {
 color = 0xC9B36D,
},
callback = [[
-------------------------------------------------------------------------------
-- Increment (xinc)
-- The global incrementor, 'xinc', is an ever-increasing line counter,
-- and essential if you want to produce movement over time
-------------------------------------------------------------------------------
-- here we use xinc to loop through 8 notes, using the 'modulo' operator
xline.note_columns[1] = {
  note_value = args.basenote + xinc%8,
  volume_value = args.volume
}
]],
}