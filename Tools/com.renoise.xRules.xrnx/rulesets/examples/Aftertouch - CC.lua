-----------------------------------------------------------
-- Ruleset definition for xRules
-- More info @ http://www.renoise.com/tools/xrules
-----------------------------------------------------------
return {
osc_enabled = false,
manage_voices = false,
description = "This ruleset will convert channel aftertouch into CCs,\nwhile passing all other messages on to Renoise\n1. Select the input port in the rule named \"Input\"\n2. Choose the CC number in the rule named \"Convert\"\n   (it's part of the function..)",
{
  ["osc_pattern"] = {
      ["pattern_in"] = "",
      ["pattern_out"] = "",
  },
  ["name"] = "Input",
  ["actions"] = {
      {
          ["route_message"] = "Current Ruleset:Convert",
      },
      {
          ["route_message"] = "Current Ruleset:Pass",
      },
  },
  ["conditions"] = {
      {
          ["port_name"] = {
              ["equal_to"] = "4- SL MkII",
          },
      },
  },
  ["match_any"] = true,
  ["midi_enabled"] = true,
},
{
  ["osc_pattern"] = {
      ["pattern_in"] = "",
      ["pattern_out"] = "",
  },
  ["name"] = "Convert",
  ["actions"] = {
      {
          ["set_message_type"] = "controller_change",
      },
      {
          ["call_function"] = [[-- convert the raw MIDI message 
values[2] = values[1] -- the aftertouch value
values[1] = 0x01 -- CC number (between 0-127)
  ]],
      },
      {
          ["output_message"] = "internal_auto",
      },
  },
  ["conditions"] = {
      {
          ["message_type"] = {
              ["equal_to"] = "ch_aftertouch",
          },
      },
  },
  ["match_any"] = true,
  ["midi_enabled"] = false,
},
{
  ["osc_pattern"] = {
      ["pattern_in"] = "",
      ["pattern_out"] = "",
  },
  ["name"] = "Pass",
  ["actions"] = {
      {
          ["output_message"] = 1,
      },
  },
  ["conditions"] = {
      {
          ["message_type"] = {
              ["not_equal_to"] = "ch_aftertouch",
          },
      },
  },
  ["match_any"] = true,
  ["midi_enabled"] = false,
}
}