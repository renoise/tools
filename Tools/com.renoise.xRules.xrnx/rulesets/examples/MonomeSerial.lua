-----------------------------------------------------------
-- Ruleset definition for xRules
-- Visit http://www.renoise.com/tools/xrules for more info
-----------------------------------------------------------
return {
osc_enabled = true,
manage_voices = false,
description = "Enter description...",
{
  osc_pattern = {
      pattern_in = "/press %i %i %i",
      pattern_out = "/set $1 $2 $3",
  },
  name = "Chromatic Keys",
  actions = {
      {
          output_message = "external_osc",
      },
      {
          call_function = "-- contruct note message \n-- (velocity is controlled via tilt)\nlocal velocity, pitch = 100, (values[1] * 12) + values[2]\nif rules[2] and rules[2].values then\n  velocity = \n   cLib.scale_value(rules[2].values[2],90,166,0,127)\nend\n-- output note\nif (values[3] == 1) then\n  message_type = \"note_on\"\nelse\n  message_type = \"note_off\"\n  velocity = 0\nend\nvalues[1] = pitch\nvalues[2] = math.floor(velocity)\n",
      },
      {
          output_message = "internal_raw",
      },
  },
  conditions = {},
  match_any = true,
  midi_enabled = false,
},
{
  osc_pattern = {
      pattern_in = "/tilt %f %f",
      pattern_out = "",
  },
  name = "Tilt → XY Pad",
  actions = {
      {
          call_function = "local rns = renoise.song()\nlocal dev = rns.selected_device\nif dev and (dev.name == \"*XY Pad\") then\n local x = cLib.scale_value(values[1],90,166,0,1)\n local y = cLib.scale_value(values[2],90,166,0,1)\n dev.parameters[1].value = cLib.clamp_value(x,0,1)\n dev.parameters[2].value = cLib.clamp_value(y,0,1)\nend",
      },
      {
          output_message = "external_osc",
      },
  },
  conditions = {},
  match_any = true,
  midi_enabled = false,
}
}