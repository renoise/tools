-----------------------------------------------------------
-- Ruleset definition for xRules
-- More info @ http://www.renoise.com/tools/xrules
-----------------------------------------------------------
return {
osc_enabled = false,
manage_voices = false,
description = "-------------------------------------------------------------------------------------\nAUTOMAPPING OF DEVICE PARAMETERS\n(and record automation, pass messages on to Renoise)\n-------------------------------------------------------------------------------------\n\nThis ruleset will listen to a specific CC message (1, or mod-wheel),\nand apply the value to the selected parameter in Renoise. All other \nmessages will be forwarded to Renoise (so, still useful). \n\nAutomation recording is performed automatically when the \nparameter is automatable and edit mode has been enabled. \n\n## How to select a target parameter \n\n1. In Renoise, while the lower DSP automation lane is visible, the\ncurrently selected parameter becomes the target\n\n2. Else, we target the _first visible parameter_ of the selected device \nin the Mixer tab (whether this tab is visible or not). This makes it easy to provide a 'fallback' parameter, simply right-clicking the\ndevice in the mixer\n\n",
{
  osc_pattern = {
      pattern_in = "",
      pattern_out = "",
  },
  name = "Intercept",
  actions = {
      {
          call_function = [[local device = rns.selected_device
if not device then return end

-- get the selected parameter

local param = nil
if renoise.app().window.lower_frame_is_visible 
  and (renoise.app().window.active_lower_frame == 
    renoise.ApplicationWindow.LOWER_FRAME_TRACK_AUTOMATION)
then
  param = rns.selected_parameter
end
if not param then
  -- use the first parameter in the mixer 
  local params = xAudioDevice.get_mixer_parameters(device)
  if table.is_empty(params) then return end
  param = params[1]
end

if not param 
  or not param.is_automatable 
then
  return
end

-- we have a parameter, now set/record value

local track_idx = rns.selected_track_index
if rns.transport.edit_mode then  
  record_automation(track_idx,param,values[2],__xmsg.mode)
else
  xParameter.set_value(param,values[2],__xmsg.mode)
end
]],
      },
  },
  conditions = {
      {
          message_type = {
              equal_to = "controller_change",
          },
      },
      {
          value_1 = {
              equal_to = 1,
          },
      },
  },
  match_any = true,
  midi_enabled = true,
},
{
  osc_pattern = {
      pattern_in = "",
      pattern_out = "",
  },
  name = "Pass through",
  actions = {
      {
          output_message = "internal_raw",
      },
  },
  conditions = {
      {
          message_type = {
              not_equal_to = "controller_change",
          },
      },
      {
          2,
      },
      {
          value_1 = {
              not_equal_to = 1,
          },
      },
  },
  match_any = true,
  midi_enabled = true,
}
}