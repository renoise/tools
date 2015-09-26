--[[============================================================================
FX-Commands - Copy.lua
============================================================================]]--

return {
arguments = {
  {
      name = "instr_idx",
      value = 2,
      properties = {
          min = 1,
          quant = 1,
          max = 255,
          zero_based = true,
          display_as_hex = true,
      },
      bind = "rns.selected_instrument_index_observable",
      description = "Instrument number (bound to selected instrument)",
  },
  {
      name = "interval",
      value = 3,
      properties = {
          min = 1,
          quant = 1,
          max = 255,
      },
      description = "Output for every X line",
  },
  {
      name = "fx_number",
      value = 1,
      properties = {
          display = "popup",
          items = "xEffectColumn.SUPPORTED_EFFECTS",
      },
      description = "Choose among available FX commands",
  },
  {
      name = "fx_amt_x_",
      value = 3,
      properties = {
          min = 0,
          max = 15,
          quant = 1,
          display_as_hex = true,
      },
      description = "Choose FX amount (first digit)",
  },
  {
      name = "fx_amt__y",
      value = 8,
      properties = {
          min = 0,
          max = 15,
          quant = 1,
          display_as_hex = true,
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
  {
      fx_number = 2,
      interval = 3,
      fx_amt__y = 0,
      instr_idx = 2,
      fx_amt_x_ = 0,
  },
  {
      fx_number = 1,
      interval = 3,
      fx_amt__y = 8,
      instr_idx = 2,
      fx_amt_x_ = 3,
  },
},
data = {
},
callback = [[
-----------------------------------------------------------------------------
-- FX-Commands 
-- Output to effect column, pass everything else through
-----------------------------------------------------------------------------

if (xinc%args.interval == 0) then
    xline.effect_columns[1] = {
      number_value = SUPPORTED_EFFECT_CHARS[args.fx_number],
      amount_value = args.fx_amt_x_ *16 + args.fx_amt__y,
    }
else
  xline.effect_columns[1] = {}
end  










]],
}