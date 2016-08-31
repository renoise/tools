-----------------------------------------------------------
-- Ruleset definition for xRules
-- Visit http://www.renoise.com/tools/xrules for more info
-----------------------------------------------------------
return {
osc_enabled = true,
manage_voices = false,
description = [["Automapping" an XY Pad: the function will pass value 1+2 into any 
selected XY Pad - automation can be recorded too (enable edit mode)
]],
{
  osc_pattern = {
      pattern_in = "/accxyz %f %f %f",
      pattern_out = "",
  },
  name = "Tilt → XY Pad",
  actions = {
      {
          call_function = [[--rprint(values)
local dev = rns.selected_device
if dev and (dev.name == "*XY Pad") then
 local param_x = dev.parameters[1]
 local param_y = dev.parameters[2]
 local track_idx = rns.selected_track_index
 local y = cLib.scale_value(values[1],1,-1,0,1)
 local x = cLib.scale_value(values[2],-1,1,0,1)
 x = cLib.clamp_value(x,0,1
 y = cLib.clamp_value(y,0,1)
 if rns.transport.edit_mode then
  record_automation(track_idx,param_x,x)
  record_automation(track_idx,param_y,y)
 else
  if not has_automation(track_idx,param_x) then
   param_x.value = x
  end
  if not has_automation(track_idx,param_y) then
   param_y.value = y
  end
 end
end
]],
      },
  },
  conditions = {},
  match_any = true,
  midi_enabled = false,
}
}