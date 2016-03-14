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
  conditions = {
      {
          message_type = {
              equal_to = "note_on",
          },
      },
  },
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
          set_value_1 = -42,
      },
      {
          set_message_type = "note_on",
      },
      {
          set_value_1 = -10,
      },
  },
  conditions = {
      {
          message_type = {
              equal_to = "note_on",
          },
      },
  },
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
          set_value_1 = "MyBrat",
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
      pattern_in = "/foo/bar/baz",
      pattern_out = "",
  },
  name = "Pattern only",
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
      pattern_in = "/foo/bar/baz %i:foo %n:bar %f:baz",
      pattern_out = "",
  },
  name = "Pattern + values",
  actions = {
      {
          set_value_2 = 4,
      },
      {
          set_value_2 = 5,
      },
      {
          set_value_3 = 6,
      },
      {
          output_message = "external_osc",
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
}
}