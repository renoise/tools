-----------------------------------------------------------
-- Ruleset definition for xRules
-- Visit http://www.renoise.com/tools/xrules for more info
-----------------------------------------------------------
return {
osc_enabled = false,
manage_voices = false,
description = "",
{
  osc_pattern = {
      pattern_in = "",
      pattern_out = "",
  },
  name = "",
  actions = {
      {
          set_channel = 1,
      },
      {
          output_message = "internal_raw",
      },
  },
  conditions = {},
  match_any = true,
  midi_enabled = true,
}
}