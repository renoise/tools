--[[===========================================================================
Increment.lua
===========================================================================]]--

return {
arguments = {
  {
      ["locked"] = false,
      ["name"] = "volume",
      ["linked"] = false,
      ["value"] = 37,
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
      ["value"] = 43.2,
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

-- write looping values (0x10-0x30) into the volume column ... 
xline.note_columns[1] = {
  note_value = args.basenote + xinc%8,
  volume_value = args.volume 
}


]],
}