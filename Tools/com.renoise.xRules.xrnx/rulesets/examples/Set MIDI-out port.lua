-----------------------------------------------------------
-- Ruleset definition for xRules
-- Visit http://www.renoise.com/tools/xrules for more info
-----------------------------------------------------------
return {
osc_enabled = false,
manage_voices = false,
description = "",
{
  osc_pattern = {
      pattern_in = "",
      pattern_out = "",
  },
  name = "",
  actions = {
      {
          set_port_name = "LoopBe Internal MIDI",
      },
      {
          output_message = "external_midi",
      },
      {
          set_port_name = "loopMIDI Port",
      },
      {
          output_message = "external_midi",
      },
  },
  conditions = {},
  match_any = true,
  midi_enabled = true,
}
}