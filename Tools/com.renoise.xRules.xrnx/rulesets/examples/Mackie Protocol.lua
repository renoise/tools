-----------------------------------------------------------
-- Ruleset definition for xRules
-- More info @ http://www.renoise.com/tools/xrules
-----------------------------------------------------------
return {
osc_enabled = false,
manage_voices = false,
description = "An implementation of the Mackie Protocol\n(tested with an iControls running factory settings)",
{
  osc_pattern = {
      pattern_in = "",
      pattern_out = "",
  },
  name = "Input",
  actions = {
      {
          route_message = "Current Ruleset:→ Ctrl-Change",
      },
      {
          route_message = "Current Ruleset:→ Pitch Bend",
      },
      {
          route_message = "Current Ruleset:→ Notes",
      },
  },
  conditions = {},
  match_any = true,
  midi_enabled = true,
},
{
  osc_pattern = {
      pattern_in = "",
      pattern_out = "",
  },
  name = "→ Ctrl-Change",
  actions = {
      {
          call_function = "-- Panning is Ctrl-Change on 16-23 (12 is master)\n-- Note: transmitting what seems to be rel_7_signed2,\n-- at extrame ends, the pots will output\n-- 63 = Maximum value, 127 = Minimum value\n-----------------------------------------------------------\nlocal track_idx\nlocal v1,v2 = values[1],values[2]\nif (v1 == 12) then\n  track_idx = xTrack.get_master_track_index()\nelseif (v1 >= 16) \n  and (v1 <= 23)\nthen\n  track_idx = v1-15\nend\nlocal trk = rns.tracks[track_idx]\nif not trk then \n  return \nend\nlocal pan_param = trk.devices[1].parameters[1]\nif (v2 == 127) then\n  pan_param.value = 0\nelseif (v2 == 63) then\n  pan_param.value = 1\nelse\n  xParameter.set_value(pan_param,v2,'rel_7_signed2')\nend\n",
      },
  },
  conditions = {
      {
          message_type = {
              equal_to = "controller_change",
          },
      },
  },
  match_any = true,
  midi_enabled = false,
},
{
  osc_pattern = {
      pattern_in = "",
      pattern_out = "",
  },
  name = "→ Pitch Bend",
  actions = {
      {
          call_function = "-- Volume is pitch-bend on channel 1-8  (9 = master)\n-----------------------------------------------------------\n--rprint(values)\n--print(\"channel\",channel)\nlocal trk_idx \nif (channel == 9) then\n  trk_idx = xTrack.get_master_track_index()\nelse\n  trk_idx = channel\nend\n\nlocal trk = rns.tracks[channel]\nif trk then \n  local val = xLib.scale_value(values[1],0,127,0,1.4125)\n  local volume = trk.devices[1].parameters[2]\n  volume.value = val\nend",
      },
  },
  conditions = {
      {
          message_type = {
              equal_to = "pitch_bend",
          },
      },
  },
  match_any = true,
  midi_enabled = false,
},
{
  osc_pattern = {
      pattern_in = "",
      pattern_out = "",
  },
  name = "→ Notes",
  actions = {
      {
          call_function = "-- Notes C-2 through G-2 focuses a track\n-- Notes E-1 through B-1 toggles track solo \n-- Notes G#0 through D#1 toggles track mute \n-- Master track: C-4 toggles solo\n-- Master track: C#4 toggles mute\n-----------------------------------------------------------\nrprint(values)\nlocal trk_idx,action \nif (values[1] >= 16) and (values[1] <= 23) then\n  trk_idx = values[1] - 15\n  action = \"mute\"\nelseif (values[1] >= 8) and (values[1] <= 15) then\n  trk_idx = values[1] - 7\n  action = \"solo\"\nelseif (values[1] >= 24) and (values[1] <= 31) then\n  trk_idx = values[1] - 23\n  action = \"focus\"\nend\nlocal trk = rns.tracks[trk_idx]\nif trk and action then\n  if (action == \"focus\") then\n    rns.selected_track_index = trk_idx\n  elseif (action == \"mute\") then\n    local state = trk.mute_state\n    if (state == renoise.Track.MUTE_STATE_ACTIVE) then\n      trk:mute()\n    else\n      trk.mute_state = renoise.Track.MUTE_STATE_ACTIVE\n    end\n  elseif (action == \"solo\") then\n    trk:solo()\n  end\nend",
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
}
}