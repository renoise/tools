--[[============================================================================
FX-Commands.lua
============================================================================]]--

return {
arguments = {
  {
      name = "interval",
      value = 2,
      properties = {
          min = 1,
          --quant = 1,
          max = 255,
          display_as = "integer",
      },
      description = "Output for every X line",
  },
  {
      name = "fx_number",
      value = 15,
      properties = {
          --display_as = "popup",
          items = "xEffectColumn.SUPPORTED_EFFECTS",
      },
      description = "Choose among available FX commands",
  },
  {
      name = "fx_amt_x_",
      value = 4,
      properties = {
          min = 0,
          max = 15,
          --quant = 1,
          display_as = "hex",
      },
      description = "Choose FX amount (first digit)",
  },
  {
      name = "fx_amt__y",
      value = 0,
      properties = {
          min = 0,
          max = 15,
          --quant = 1,
          display_as ="hex",
      },
      description = "Choose FX amount (second digit)",
  },
},
presets = {
  {
      fx_number = 15,
      interval = 8,
      fx_amt__y = 0,
      instr_idx = 4,
      fx_amt_x_ = 11,
  },
  {
      fx_number = 15,
      interval = 4,
      fx_amt__y = 0,
      instr_idx = 4,
      fx_amt_x_ = 8,
  },
  {
      fx_number = 15,
      interval = 2,
      fx_amt__y = 0,
      instr_idx = 4,
      fx_amt_x_ = 4,
  },
  {
      fx_number = 4,
      interval = 8,
      fx_amt__y = 0,
      instr_idx = 4,
      fx_amt_x_ = 11,
  },
  {
      fx_number = 3,
      interval = 8,
      fx_amt__y = 5,
      instr_idx = 4,
      fx_amt_x_ = 3,
  },
},
data = {
},
options = {
 color = 0xD77A4B,
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