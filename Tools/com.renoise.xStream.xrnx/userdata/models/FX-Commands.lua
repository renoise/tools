--[[===========================================================================
FX-Commands.lua
===========================================================================]]--

return {
arguments = {
  {
      name = "interval",
      value = 4,
      properties = {
          min = 1,
          display_as = "integer",
          max = 255,
      },
      description = "Output for every X line",
  },
  {
      name = "fx_number",
      value = 15,
      properties = {
          items = "xEffectColumn.SUPPORTED_EFFECTS",
      },
      description = "Choose among available FX commands",
  },
  {
      name = "fx_amt_x_",
      value = 8,
      properties = {
          min = 0,
          display_as = "hex",
          max = 15,
      },
      description = "Choose FX amount (first digit)",
  },
  {
      name = "fx_amt__y",
      value = 0,
      properties = {
          min = 0,
          display_as = "hex",
          max = 15,
      },
      description = "Choose FX amount (second digit)",
  },
},
presets = {
  {
      fx_number = 15,
      name = "",
      interval = 8,
      fx_amt__y = 0,
      instr_idx = 4,
      fx_amt_x_ = 11,
  },
  {
      fx_number = 15,
      name = "",
      interval = 4,
      fx_amt__y = 0,
      instr_idx = 4,
      fx_amt_x_ = 8,
  },
  {
      fx_number = 15,
      name = "",
      interval = 2,
      fx_amt__y = 0,
      instr_idx = 4,
      fx_amt_x_ = 4,
  },
  {
      fx_number = 4,
      name = "",
      interval = 8,
      fx_amt__y = 0,
      instr_idx = 4,
      fx_amt_x_ = 11,
  },
  {
      fx_number = 3,
      name = "",
      interval = 8,
      fx_amt__y = 5,
      instr_idx = 4,
      fx_amt_x_ = 3,
  },
},
data = {
},
options = {
 color = 0xCA8759,
},
callback = [[
-------------------------------------------------------------------------------
-- FX-Commands 
-- Output to first effect column, leave everything else intact
-------------------------------------------------------------------------------

if (xinc%args.interval == 0) then
    xline.effect_columns[1] = {
      number_value = SUPPORTED_EFFECT_CHARS[args.fx_number],
      amount_value = args.fx_amt_x_ *16 + args.fx_amt__y,
    }
end  






]],
}