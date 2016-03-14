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
  conditions = {
      {
          channel = {
              between = {
                  1,
                  16,
              },
          },
      },
  },
  match_any = true,
  actions = {
      {
          set_channel = 1,
      },
      {
          call_function = "port_name = \"LoopBe Internal MIDI\"",
      },
      {
          output_message = "external_midi",
      },
  },
}
}