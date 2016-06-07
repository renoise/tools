--[[===========================================================================
Qxx Shuffle.lua
===========================================================================]]--

return {
arguments = {
  {
      ["locked"] = false,
      ["name"] = "fx_column_idx",
      ["linked"] = false,
      ["value"] = 0,
      ["properties"] = {
          ["max"] = 8,
          ["min"] = 0,
          ["display_as"] = "integer",
          ["zero_based"] = false,
      },
      ["description"] = "The FX column where we write Qxx commands (0 = selected)",
  },
  {
      ["locked"] = false,
      ["name"] = "shuffle_amount",
      ["linked"] = false,
      ["value"] = 14,
      ["properties"] = {
          ["max"] = 15,
          ["min"] = 0,
          ["display_as"] = "integer",
          ["zero_based"] = false,
      },
      ["description"] = "The shuffle amount (in ticks)",
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
-- Tick-based shuffle
-- Will output Qxx commands into every Nth line (customizable), in the
-- effect column of your choice - or the selected one
-------------------------------------------------------------------------------
local fx_col_idx = (args.fx_column_idx == 0) and
  rns.selected_effect_column_index or args.fx_column_idx
--print(fx_col_idx)
if (fx_col_idx > 0) -- when a note column is focused
  and (xinc%2 ~= 0)
then
  xline.effect_columns[fx_col_idx].number_string = "0Q"
  xline.effect_columns[fx_col_idx].amount_value = args.shuffle_amount
end
]],
}