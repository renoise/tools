-----------------------------------------------------------
-- Ruleset definition for xRules
-- Visit http://www.renoise.com/tools/xrules for more info
-----------------------------------------------------------
return {
osc_enabled = true,
manage_voices = false,
description = "",
{
  osc_pattern = {
      pattern_in = "/kuva %i:foo %i:bar",
      pattern_out = "/kuva $2 $1",
  },
  name = "",
  actions = {
      {
          call_function = "device_name = \"Pure Data\"",
      },
      {
          output_message = "external_osc",
      },
  },
  conditions = {
      {
          device_name = {
              equal_to = "Pure Data",
          },
      },
      {
          2,
      },
      {
          port_name = {
              equal_to = "2- SL MkII",
          },
      },
      {
          instrument_index = {
              between = {
                  1,
                  128,
              },
          },
      },
      {
          value_1 = {
              less_than = 121,
          },
      },
      {
          value_2 = {
              greater_than = 1,
          },
      },
  },
  match_any = true,
  midi_enabled = true,
}
}