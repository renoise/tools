-----------------------------------------------------------
-- Ruleset definition for xRules
-- More info @ http://www.renoise.com/tools/xrules
-----------------------------------------------------------
return {
osc_enabled = false,
manage_voices = false,
description = "iControls / xStream  mappings \nNote: valid for the 4th page ('layer') only! \n---------------------------------------------------------\nName    #     Input   Channel  Output\n---------------------------------------------------------\nDial    1-8   CC 30   Ch 1-8  \nFader   1-8   CC 34   Ch 1-8\nUpperBt 1-8   Nt 40   Ch 1-8  --> Convert to CC 17-32\nLowerBt 1-8   Nt 39   Ch 1-8  --> Convert to CC 1-16\nUpperBt 9     Nt 116  Ch 1    --> Convert to CC 64\nLowerBt 9     Nt 117  Ch 1    --> Convert to CC 65\nDial    9     CC 118  Ch 1\nFader   9     CC 119  Ch 1\n",
{
  ["osc_pattern"] = {
      ["pattern_in"] = "",
      ["pattern_out"] = "",
  },
  ["name"] = "notes (buttons)",
  ["actions"] = {
      {
          ["call_function"] = [[-- convert notes into cc messages
rprint(values)
local number,value
if (values[1] == 39) then       -- button 1-8 upper 
  number = channel
elseif (values[1] == 40) then   -- button 1-8 lower 
  number = channel+16
elseif (values[1] == 116) then  -- button 9 upper
  number = 64
elseif (values[1] == 117) then  -- button 9 upper
  number = 65
end
if number then
  value = (message_type == 'note_on') and 127 or 0
  message_type = 'controller_change'
  values[1] = number
  values[2] = value
  output_message('internal_raw')
end]],
      },
  },
  ["conditions"] = {
      {
          ["message_type"] = {
              ["equal_to"] = "note_on",
          },
      },
      {
          2,
      },
      {
          ["message_type"] = {
              ["equal_to"] = "note_off",
          },
      },
  },
  ["match_any"] = true,
  ["midi_enabled"] = true,
}
}