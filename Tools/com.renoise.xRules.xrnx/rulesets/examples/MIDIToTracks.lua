-----------------------------------------------------------
-- Ruleset definition for xRules
-- More info @ http://www.renoise.com/tools/xrules
-----------------------------------------------------------
return {
osc_enabled = false,
manage_voices = false,
description = [[Demonstrates how to route incoming MIDI notes into specific tracks
(in this case, C-2 goes to track 01 and D-2 goes to track 02)
]],
{
  ["actions"] = {
      {
          ["call_function"] = [[-- set to this instrument (NB: 01 is "00" in Renoise)
instrument_index = 1
if (message_type == "note_on") 
or (message_type == "note_off") then
 -- specify track routings 
 if (values[1] == 24) then     -- C-2
  track_index = 1
 elseif (values[1] == 26) then -- D-2
  track_index = 2
 end
end ]],
      },
      {
          ["output_message"] = 1,
      },
  },
  ["conditions"] = {},
  ["match_any"] = true,
  ["midi_enabled"] = true,
  ["name"] = "",
  ["osc_pattern"] = {
      ["pattern_in"] = "",
      ["pattern_out"] = "",
  },
}
}