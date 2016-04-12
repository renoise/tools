-----------------------------------------------------------
-- Ruleset definition for xRules
-- Visit http://www.renoise.com/tools/xrules for more info
-----------------------------------------------------------
return {
osc_enabled = false,
manage_voices = false,
description = "Enable MMC commands in Renoise by listening to incoming sysex.\nSee also http://www.blitter.com/~russtopia/MIDI/~jglatt/tech/mmc.htm",
{
  osc_pattern = {
      pattern_in = "",
      pattern_out = "",
  },
  name = "MMC Transport",
  actions = {
      {
          call_function = "local rns = renoise.song()\nif (values[2] == 0x7F)\n -- ignore third byte (manufacturer ID)\n and (values[4] == 0x06)\nthen\n -- MMC STOP ---------------------------------------------\n if (values[5] == 1) then \n  rns.transport:stop()\n -- MMC START --------------------------------------------\n elseif (values[5] == 2) then \n  local mode = renoise.Transport.PLAYMODE_RESTART_PATTERN\n  rns.transport:start(mode)\n -- MMC DEFERRED PLAY ------------------------------------\n elseif (values[5] == 3) then \n  local mode = renoise.Transport.PLAYMODE_CONTINUE_PATTERN\n  rns.transport:start(mode)  \n -- MMC FAST FORWARD -------------------------------------\n elseif (values[5] == 4) then \n  local play_pos = rns.transport.playback_pos\n  play_pos.sequence = play_pos.sequence + 1\n  local seq_len = #rns.sequencer.pattern_sequence\n  if (play_pos.sequence <= seq_len) then\n   local new_patt_idx = \n    rns.sequencer.pattern_sequence[play_pos.sequence]\n   local new_patt = rns:pattern(new_patt_idx)\n   if (play_pos.line > new_patt.number_of_lines) then\n    play_pos.line = 1\n   end\n   rns.transport.playback_pos = play_pos\n  end\n -- MMC REWIND --------------------------------------------\n elseif (values[5] == 5) then \n  local play_pos = rns.transport.playback_pos\n  play_pos.sequence = play_pos.sequence - 1\n  if (play_pos.sequence < 1) then\n   play_pos.sequence = 1\n  end\n  local new_patt_idx = \n   rns.sequencer.pattern_sequence[play_pos.sequence]\n  local new_patt = rns:pattern(new_patt_idx)\n  if (play_pos.line > new_patt.number_of_lines) then\n   play_pos.line = 1\n  end\n  rns.transport.playback_pos = play_pos \n-- MMC RECORD STROBE -------------------------------------\n elseif (values[5] == 6) then \n  rns.transport.edit_mode = true\n -- MMC RECORD EXIT ---------------------------------------\n elseif (values[5] == 7) then \n  rns.transport.edit_mode = false\n -- MMC PAUSE ---------------------------------------------\n elseif (values[5] == 9) then \n  rns.transport:stop()\n end\nend",
      },
  },
  conditions = {
      {
          message_type = {
              equal_to = "sysex",
          },
      },
      {
          sysex = {
              equal_to = "F0 7F * 06 * F7",
          },
      },
  },
  match_any = true,
  midi_enabled = true,
}
}