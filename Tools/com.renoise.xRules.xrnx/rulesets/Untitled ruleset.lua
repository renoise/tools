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
  ["name"] = "Tilt → XY Pad",
  ["actions"] = {
      {
          ["call_function"] = [[rprint(values)
local dev = rns.selected_device
if dev and (dev.name == "*Instr. Automation") then
  --print("got here 1")
 local param_x = dev.parameters[1]
 local track_idx = rns.selected_track_index
 local x = xLib.scale_value(values[2],0,127,0,1)
 x = xLib.clamp_value(x,0,1)
 if rns.transport.edit_mode then
  record_automation(track_idx,param_x,x)
  print("got here 2",x)
 else
  if not has_automation(track_idx,param_x) then
   param_x.value = x
  end
 end
end
]],
      },
  },
  ["conditions"] = {},
  ["match_any"] = true,
  ["midi_enabled"] = true,
}
}