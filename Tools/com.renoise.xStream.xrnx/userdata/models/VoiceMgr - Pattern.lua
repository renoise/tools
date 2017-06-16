--[[===========================================================================
VoiceMgr - Pattern.lua
===========================================================================]]--

return {
arguments = {
  {
      ["locked"] = false,
      ["name"] = "voice_limit",
      ["linked"] = false,
      ["value"] = 1,
      ["properties"] = {
          ["min"] = 0,
          ["max"] = 12,
          ["display_as"] = "integer",
          ["zero_based"] = false,
      },
      ["description"] = "Specify how many voices that can be played simultaneously",
  },
  {
      ["locked"] = false,
      ["name"] = "schedule",
      ["linked"] = false,
      ["value"] = 1,
      ["properties"] = {
          ["min"] = 1,
          ["max"] = 3,
          ["display_as"] = "switch",
          ["items"] = {
              "LINE",
              "BEAT",
              "BAR",
          },
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "clear_active",
      ["linked"] = false,
      ["value"] = true,
      ["properties"] = {
          ["display_as"] = "checkbox",
      },
      ["description"] = "",
  },
  {
      ["locked"] = false,
      ["name"] = "dly_note_on",
      ["linked"] = false,
      ["value"] = true,
      ["properties"] = {
          ["display_as"] = "checkbox",
      },
      ["description"] = "Whether to use delay column on note-on (applies only when schedule = LINE)\n",
  },
  {
      ["locked"] = false,
      ["name"] = "dly_note_off",
      ["linked"] = false,
      ["value"] = true,
      ["properties"] = {
          ["display_as"] = "checkbox",
      },
      ["description"] = "Whether to use delay column on note-offs (applies only when schedule = LINE)\n",
  },
},
presets = {
  {
      ["schedule"] = 1,
      ["name"] = "Monophonic",
      ["dly_note_on"] = true,
      ["dly_note_off"] = true,
      ["voice_limit"] = 1,
  },
  {
      ["schedule"] = 2,
      ["clear_active"] = true,
      ["name"] = "2 voices, BEAT",
      ["voice_limit"] = 2,
      ["dly_note_off"] = false,
      ["dly_note_on"] = false,
  },
},
data = {
  ["get_delay_value"] = [[-------------------------------------------------------------------------------
-- Compute the delay value according to current settings
-------------------------------------------------------------------------------
return function(trigger_type)
  if ((trigger_type == "trigger") and not args.dly_note_on)
  or ((trigger_type == "release") and not args.dly_note_off)
  then
    return 0
  else
    local xplaypos = xpos.playpos()  
    return (args.schedule == xStreamPos.SCHEDULE.LINE)
      and math.floor(xplaypos.fraction * 255) or 0
  end
end]],
},
events = {
  ["voice.triggered"] = [[------------------------------------------------------------------------------
-- respond to voice-manager events
-- @param arg (table) {type = xVoiceManager.EVENTS, index = int}
------------------------------------------------------------------------------
print(">>> events.voice.triggered",xvoicemgr.triggered_index)
local voice = xvoicemgr.voices[arg.index]
local pos,scheduled_xinc = xpos:get_scheduled_pos(args.schedule)
xbuffer:schedule_note_column({
  note_value = voice.values[1],
  volume_value = voice.values[2],
  instrument_value = rns.selected_instrument_index-1,
  delay_value = data.get_delay_value("trigger"),
},voice.note_column_index,scheduled_xinc)]],
  ["args.voice_limit"] = [[------------------------------------------------------------------------------
-- respond to argument 'voice_limit' changes
-- @param val (number/boolean/string)}
------------------------------------------------------------------------------

xvoicemgr.voice_limit = args.voice_limit]],
  ["voice.released"] = [[------------------------------------------------------------------------------
-- respond to voice-manager events
-- @param arg (table) {type = xVoiceManager.EVENTS, index = int}
------------------------------------------------------------------------------
print(">>> events.voice.released",xvoicemgr.released_index)
local voice = xvoicemgr.voices[arg.index]
local pos,scheduled_xinc = xpos:get_scheduled_pos(args.schedule)
local xline = xbuffer:read_from_pattern(scheduled_xinc)
local note_col = xline.note_columns[voice.note_column_index]
-- output note-off only when not occupied by note
if (note_col.note_value >= EMPTY_NOTE_VALUE) then
  xbuffer:schedule_note_column({
    note_string = "OFF",
    delay_value = data.get_delay_value("release"),
  },voice.note_column_index,travelled)
end]],
  ["midi.pitch_bend"] = [[------------------------------------------------------------------------------
-- respond to MIDI 'pitch_bend' messages
-- @param xmsg, the xMidiMessage we have received
------------------------------------------------------------------------------
local visible_note_columns = rns.tracks[read_track_index].visible_note_columns
xbuffer:schedule_note_column({
  instrument_value = rns.selected_instrument_index,
  panning_string = "M1",
},visible_note_columns)
xbuffer:schedule_effect_column({
  number_string = ("%.2X"):format(xmsg.values[2]),
  amount_value = 0,
},1)]],
},
options = {
 color = 0x60AACA,
},
callback = [[
-------------------------------------------------------------------------------
-- Using the voice manager to write MIDI input directly into the pattern. 
-- This is mostly a proof-of-concept, as it's more practical to be able to
-- play notes also while the sequencer is stopped - if you are looking to
-- do that, check out the 'VoiceMgr - Realtime' model instead. 
-------------------------------------------------------------------------------
if args.clear_active then
  for k,v in ipairs(xvoicemgr.voices) do
    xline.note_columns[v.note_column_index] = {}
  end
end
]],
}