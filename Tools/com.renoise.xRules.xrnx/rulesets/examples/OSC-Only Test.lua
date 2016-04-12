-----------------------------------------------------------
-- Ruleset definition for xRules
-- More info @ http://www.renoise.com/tools/xrules
-----------------------------------------------------------
return {
osc_enabled = true,
manage_voices = false,
description = "",
{
  osc_pattern = {
      pattern_in = "/kuva %i:foo",
      pattern_out = "",
  },
  name = "Integer",
  actions = {
      {
          set_value_1 = 1,
      },
      {
          output_message = 1,
      },
  },
  conditions = {},
  match_any = true,
  midi_enabled = false,
},
{
  osc_pattern = {
      pattern_in = "/space %n:bar",
      pattern_out = "",
  },
  name = "Number",
  actions = {
      {
          set_value_1 = -22,
      },
      {
          output_message = 1,
      },
  },
  conditions = {},
  match_any = true,
  midi_enabled = false,
},
{
  osc_pattern = {
      pattern_in = "/asdf %f:baz",
      pattern_out = "",
  },
  name = "Float",
  actions = {
      {
          call_function = "print(\">>> Float\",__xmsg)",
      },
      {
          output_message = 1,
      },
  },
  conditions = {},
  match_any = true,
  midi_enabled = false,
},
{
  osc_pattern = {
      pattern_in = "/some/pattern %s:my_string",
      pattern_out = "",
  },
  name = "String",
  actions = {
      {
          call_function = "print(\">>> String\",rprint(values))",
      },
      {
          output_message = 1,
      },
  },
  conditions = {},
  match_any = true,
  midi_enabled = false,
},
{
  osc_pattern = {
      pattern_in = "/some/pattern %s:my_string",
      pattern_out = "",
  },
  name = "String (hello!)",
  actions = {
      {
          output_message = 1,
      },
  },
  conditions = {
      {
          value_1 = {
              equal_to = 1,
          },
      },
  },
  match_any = true,
  midi_enabled = false,
},
{
  osc_pattern = {
      pattern_in = "/foo/bar/baz",
      pattern_out = "",
  },
  name = "Pattern only",
  actions = {
      {
          call_function = "print(\">>> Pattern only\",rprint(values))",
      },
      {
          output_message = 1,
      },
  },
  conditions = {},
  match_any = true,
  midi_enabled = false,
},
{
  osc_pattern = {
      pattern_in = "/some/pattern",
      pattern_out = "",
  },
  name = "Pattern only #2",
  actions = {
      {
          output_message = 1,
      },
  },
  conditions = {},
  match_any = true,
  midi_enabled = false,
},
{
  osc_pattern = {
      pattern_in = "/foo/bar/baz %n:foo %n:bar %n:baz",
      pattern_out = "",
  },
  name = "Patt + values (1,2,3)",
  actions = {
      {
          output_message = "internal_auto",
      },
  },
  conditions = {
      {
          value_1 = {
              equal_to = 1,
          },
      },
      {
          value_2 = {
              equal_to = 2,
          },
      },
      {
          value_3 = {
              equal_to = 3,
          },
      },
  },
  match_any = true,
  midi_enabled = false,
},
{
  osc_pattern = {
      pattern_in = "/foo/bar/baz %n:foo %n:bar %n:baz",
      pattern_out = "",
  },
  name = "Patt + values",
  actions = {
      {
          output_message = 1,
      },
  },
  conditions = {},
  match_any = true,
  midi_enabled = false,
}
}