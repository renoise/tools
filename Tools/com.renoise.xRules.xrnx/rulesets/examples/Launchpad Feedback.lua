-----------------------------------------------------------
-- Ruleset definition for xRules
-- More info @ http://www.renoise.com/tools/xrules
-----------------------------------------------------------
return {
osc_enabled = false,
manage_voices = false,
description = "",
{
  ["osc_pattern"] = {
      ["pattern_in"] = "",
      ["pattern_out"] = "",
  },
  ["name"] = "",
  ["actions"] = {
      {
          ["call_function"] = [[if (type(cc_toggle)=="nil") then
  cc_toggle = false
end
if (values[1] == 111) then
  if (values[2] == 127) then
    cc_toggle = not cc_toggle
  end
  values[2] = cc_toggle and 127 or 0
end
]],
      },
      {
          ["output_message"] = "internal_raw",
      },
      {
          ["output_message"] = "external_midi",
      },
  },
  ["conditions"] = {},
  ["match_any"] = true,
  ["midi_enabled"] = true,
}
}