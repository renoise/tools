-----------------------------------------------------------
-- Ruleset definition for xRules
-- Visit http://www.renoise.com/tools/xrules for more info
-----------------------------------------------------------
return {
osc_enabled = false,
manage_voices = false,
description = "This set is a demonstration of message routing in xRules. It will accept any MIDI input and route notes into Renoise (→ Notes) while sending all other messages to the  output of your choice (→ Other). Notice how MIDI input is disabled for the rules receiving input - otherwise, they would also process normal MIDI input. \n",
{
  osc_pattern = {
      pattern_in = "",
      pattern_out = "",
  },
  name = "Input",
  actions = {
      {
          route_message = "Current Ruleset:→ Notes",
      },
      {
          route_message = "Current Ruleset:→ Other",
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
  name = "→ Notes",
  actions = {
      {
          output_message = "internal_raw",
      },
  },
  conditions = {
      {
          message_type = {
              equal_to = "note_on",
          },
      },
      {
          2,
      },
      {
          message_type = {
              equal_to = "note_off",
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
  name = "→ Other",
  actions = {
      {
          set_port_name = "loopMIDI Port",
      },
      {
          output_message = "external_midi",
      },
  },
  conditions = {
      {
          message_type = {
              not_equal_to = "note_on",
          },
      },
      {
          message_type = {
              not_equal_to = "note_off",
          },
      },
  },
  match_any = true,
  midi_enabled = false,
}
}