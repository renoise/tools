--[[===========================================================================
Demo-Increment.lua
===========================================================================]]--

return {
arguments = {
  {
      ["description"] = "",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "volume",
      ["properties"] = {
          ["display_as"] = "hex",
          ["max"] = 100,
          ["min"] = 0,
          ["zero_based"] = false,
      },
      ["value"] = 93,
  },
  {
      ["description"] = "",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "basenote",
      ["properties"] = {
          ["display_as"] = "note",
          ["fire_on_start"] = false,
          ["max"] = 120,
          ["min"] = 0,
      },
      ["value"] = 58.2,
  },
},
presets = {
  {
      ["basenote"] = 48.2,
      ["name"] = "C-4",
      ["volume"] = 37,
  },
  {
      ["basenote"] = 38.2,
      ["name"] = "D-3",
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
  volume_value = (args.volume+xinc)%0x40
}
]],
}