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
      pattern_in = "/hello/from/oscjs %n",
      pattern_out = "",
  },
  name = "hello",
  actions = {
      {
          call_function = "print(\">>> GOT HERE - hello\",rprint(values))",
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
      pattern_in = "/test %s %s %s",
      pattern_out = "",
  },
  name = "string",
  actions = {
      {
          call_function = "print(\">>> GOT HERE - string\")",
      },
      {
          output_message = 1,
      },
  },
  conditions = {
      {
          value_1 = {
              equal_to = "foo",
          },
      },
      {
          value_2 = {
              equal_to = "bar",
          },
      },
      {
          value_3 = {
              equal_to = "baz!",
          },
      },
  },
  match_any = true,
  midi_enabled = false,
},
{
  osc_pattern = {
      pattern_in = "/test foo bar baz!",
      pattern_out = "",
  },
  name = "string (literal)",
  actions = {
      {
          call_function = "print(\">>> GOT HERE - string (literal)\")",
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
      pattern_in = "/test %f:frequency",
      pattern_out = "",
  },
  name = "float",
  actions = {
      {
          call_function = "print(\">>> GOT HERE - float\")",
      },
      {
          output_message = 1,
      },
  },
  conditions = {
      {
          value_1 = {
              equal_to = 440.4,
          },
      },
  },
  match_any = true,
  midi_enabled = false,
},
{
  osc_pattern = {
      pattern_in = "/test 440.4",
      pattern_out = "",
  },
  name = "float (literal)",
  actions = {
      {
          call_function = "print(\">>> GOT HERE - float (literal)\")",
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
      pattern_in = "/test %i",
      pattern_out = "",
  },
  name = "integer",
  actions = {
      {
          call_function = "print(\">>> GOT HERE - integer\")",
      },
      {
          output_message = 1,
      },
  },
  conditions = {
      {
          value_1 = {
              equal_to = 48,
          },
      },
  },
  match_any = true,
  midi_enabled = false,
},
{
  osc_pattern = {
      pattern_in = "/test 48",
      pattern_out = "",
  },
  name = "integer (literal)",
  actions = {
      {
          call_function = "print(\">>> GOT HERE - integer (literal)\")",
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
      pattern_in = "/test %n %n",
      pattern_out = "",
  },
  name = "number",
  actions = {
      {
          call_function = "print(\">>> GOT HERE - number\")",
      },
      {
          output_message = 1,
      },
  },
  conditions = {},
  match_any = true,
  midi_enabled = false,
}
}