-----------------------------------------------------------
-- Ruleset definition for xRules
-- More info @ http://www.renoise.com/tools/xrules
-----------------------------------------------------------
return {
osc_enabled = false,
manage_voices = false,
description = "An implementation of the Mackie Protocol\n(tested with an iControls running factory settings)",
{
  ["osc_pattern"] = {
      ["pattern_in"] = "",
      ["pattern_out"] = "",
  },
  ["name"] = "Input",
  ["actions"] = {
      {
          ["route_message"] = "Current Ruleset:→ Ctrl-Change",
      },
      {
          ["route_message"] = "Current Ruleset:→ Pitch Bend",
      },
      {
          ["route_message"] = "Current Ruleset:→ Notes",
      },
  },
  ["conditions"] = {},
  ["match_any"] = true,
  ["midi_enabled"] = true,
},
{
  ["osc_pattern"] = {
      ["pattern_in"] = "",
      ["pattern_out"] = "",
  },
  ["name"] = "→ Ctrl-Change",
  ["actions"] = {
      {
          ["call_function"] = [[-- Panning is Ctrl-Change on 16-23 (12 is master)
-- Note: transmitting what seems to be rel_7_signed2,
-- at extrame ends, the pots will output
-- 63 = Maximum value, 127 = Minimum value
-----------------------------------------------------------
local track_idx
local v1,v2 = values[1],values[2]
if (v1 == 12) then
  track_idx = xTrack.get_master_track_index()
elseif (v1 >= 16) 
  and (v1 <= 23)
then
  track_idx = v1-15
end
local trk = rns.tracks[track_idx]
if not trk then 
  return 
end
local pan_param = trk.devices[1].parameters[1]
if (v2 == 127) then
  pan_param.value = 0
elseif (v2 == 63) then
  pan_param.value = 1
else
  xParameter.set_value(pan_param,v2,'rel_7_signed2')
end
]],
      },
  },
  ["conditions"] = {
      {
          ["message_type"] = {
              ["equal_to"] = "controller_change",
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
  ["name"] = "→ Pitch Bend",
  ["actions"] = {
      {
          ["call_function"] = [[-- Volume is pitch-bend on channel 1-8  (9 = master)
-----------------------------------------------------------
--rprint(values)
--print("channel",channel)
local trk_idx 
if (channel == 9) then
  trk_idx = xTrack.get_master_track_index()
else
  trk_idx = channel
end

local trk = rns.tracks[channel]
if trk then 
  local val = cLib.scale_value(values[1],0,127,0,1.4125)
  local volume = trk.devices[1].parameters[2]
  volume.value = val
end]],
      },
  },
  ["conditions"] = {
      {
          ["message_type"] = {
              ["equal_to"] = "pitch_bend",
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
  ["name"] = "→ Notes",
  ["actions"] = {
      {
          ["call_function"] = [[-- Notes C-2 through G-2 focuses a track
-- Notes E-1 through B-1 toggles track solo 
-- Notes G#0 through D#1 toggles track mute 
-- Master track: C-4 toggles solo
-- Master track: C#4 toggles mute
-----------------------------------------------------------
rprint(values)
local trk_idx,action 
if (values[1] >= 16) and (values[1] <= 23) then
  trk_idx = values[1] - 15
  action = "mute"
elseif (values[1] >= 8) and (values[1] <= 15) then
  trk_idx = values[1] - 7
  action = "solo"
elseif (values[1] >= 24) and (values[1] <= 31) then
  trk_idx = values[1] - 23
  action = "focus"
end
local trk = rns.tracks[trk_idx]
if trk and action then
  if (action == "focus") then
    rns.selected_track_index = trk_idx
  elseif (action == "mute") then
    local state = trk.mute_state
    if (state == renoise.Track.MUTE_STATE_ACTIVE) then
      trk:mute()
    else
      trk.mute_state = renoise.Track.MUTE_STATE_ACTIVE
    end
  elseif (action == "solo") then
    trk:solo()
  end
end]],
      },
  },
  ["conditions"] = {
      {
          ["message_type"] = {
              ["equal_to"] = "note_on",
          },
      },
  },
  ["match_any"] = true,
  ["midi_enabled"] = false,
}
}