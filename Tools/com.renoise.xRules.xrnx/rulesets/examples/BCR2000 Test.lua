-----------------------------------------------------------
-- Ruleset definition for xRules
-- More info @ http://www.renoise.com/tools/xrules
-----------------------------------------------------------
return {
osc_enabled = false,
manage_voices = false,
description = "Enter description...",
{
  osc_pattern = {
      pattern_in = "",
      pattern_out = "",
  },
  name = "",
  actions = {
      {
          call_function = "print(\"message_type\",message_type)\nprint(\"values\",rprint(values))\nlocal v1,v2 = values[1],values[2]\nlocal master_track_idx = xTrack.get_master_track_index()\nlocal trk = rns.tracks[master_track_idx]\nlocal param = trk.devices[1].parameters[2]\n\nif (message_type == \"controller_change\") then\n  if (v1 == 71) then -- abs\n    xParameter.set_value(param,v2,'abs_7')\n  elseif (v1 == 70) then -- rel1\n    xParameter.set_value(param,v2,'rel_7_twos_comp',0,80)\n  elseif (v1 == 74) then -- rel2\n    xParameter.set_value(param,v2,'rel_7_offset',30,127)\n  elseif (v1 == 1) then -- rel3\n    xParameter.set_value(\n      param,v2,'rel_7_signed2',33,66)\n  elseif (v1 == 0) then -- rel1 (14bit)\n    xParameter.set_value(\n      param,v2,'rel_14_msb',1270,2770,message_type)\n  elseif (v1 == 3) then -- rel2 (14bit)\n    xParameter.set_value(\n      param,v2,'rel_14_offset',0,12700,message_type)\n  elseif (v1 == 4) then -- rel3 (14bit)\n    xParameter.set_value(\n      param,v2,'rel_14_twos_comp',0,1270,message_type)    \n  end\nelseif (message_type == \"program_change\") then\n  xParameter.set_value(param,v1,'abs_7') \nelseif (message_type == \"nrpn\") then\n  \n  if (v1 == 900) then -- abs\n    xParameter.set_value(\n      param,v2,'abs_7',0,127,message_type)\n  elseif (v1 == 190) then -- rel1\n    xParameter.set_value(\n      param,v2,'rel_7_twos_comp',0,127,message_type)\n  elseif (v1 == 800) then -- rel2\n    xParameter.set_value(\n      param,v2,'rel_7_offset',0,127,message_type)\n  elseif (v1 == 830) then -- rel3\n    xParameter.set_value(\n      param,v2,'rel_7_signed2',0,127,message_type)\n  elseif (v1 == 500) then -- abs14\n    xParameter.set_value(\n      param,v2,'abs_14',0,12700,message_type)\n  elseif (v1 == 890) then -- rel2 (14bit)\n    xParameter.set_value(\n      param,v2,'rel_14_offset',0,1270,message_type)\n  elseif (v1 == 790) then -- rel1 (14bit)\n    xParameter.set_value(\n      param,v2,'rel_14_msb',127,7900,message_type)\n  elseif (v1 == 200) then -- abs (14bit)\n    xParameter.set_value(\n      param,v2,'abs_14',0,1270,message_type)\n  elseif (v1 == 850) then -- rel3 (14bit)\n    xParameter.set_value(\n      param,v2,'rel_14_twos_comp',0,1270,message_type)\n  end\nelseif (message_type == \"nrpn_increment\") then\n  xParameter.increment_value(param,v2)\nelseif (message_type == \"nrpn_decrement\") then\n  xParameter.decrement_value(param,v2)\nelseif (message_type == \"pitch_bend\") then\n  xParameter.set_value(param,v2,'abs_7')\nelseif (message_type == \"key_aftertouch\") then\n  xParameter.set_value(param,v2,'abs_7')\nend",
      },
  },
  conditions = {
      {
          port_name = {
              equal_to = "BCR2000",
          },
      },
  },
  match_any = true,
  midi_enabled = true,
}
}