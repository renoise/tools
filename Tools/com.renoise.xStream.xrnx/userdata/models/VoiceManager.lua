--[[===========================================================================
VoiceManager.lua
===========================================================================]]--

return {
arguments = {
  {
      ["locked"] = false,
      ["name"] = "voice_limit",
      ["linked"] = false,
      ["value"] = 2,
      ["properties"] = {
          ["max"] = 12,
          ["min"] = 0,
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
          ["max"] = 3,
          ["min"] = 1,
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
    local fract_playpos = xplaypos:get_fractional()  
    return (args.schedule == xStream.SCHEDULE.LINE)
      and math.floor(fract_playpos.fraction * 255) or 0
  end
end]],
},
events = {
  ["voice.triggered"] = [[------------------------------------------------------------------------------
-- respond to voice-manager events
-- @param arg (table) {type = xVoiceManager.EVENTS, index = int}
------------------------------------------------------------------------------
print(">>> events.voice.triggered",xstream.voicemgr.triggered_index)
local voice = xvoices[arg.index]
local pos = xbuffer:get_scheduled_pos(args.schedule)
xbuffer:schedule_note_column({
  note_value = voice.values[1],
  volume_value = voice.values[2],
  instrument_value = rns.selected_instrument_index,
  delay_value = data.get_delay_value("trigger"),
},voice.note_column_index,pos)]],
  ["voice.released"] = [[------------------------------------------------------------------------------
-- respond to voice-manager events
-- @param arg (table) {type = xVoiceManager.EVENTS, index = int}
------------------------------------------------------------------------------
print(">>> events.voice.released",xstream.voicemgr.released_index)
local voice = xvoices[arg.index]
local pos = xbuffer:get_scheduled_pos(args.schedule)
xbuffer:schedule_note_column({
  note_string = "OFF",
  delay_value = data.get_delay_value("release"),
},voice.note_column_index,pos)]],
},
options = {
 color = 0x60AACA,
},
callback = [[
-------------------------------------------------------------------------------
-- Testing the voice-manager + MIDI events
-- All output is created by event hooks that schedule xlines
-------------------------------------------------------------------------------

-- override the global voicemgr setting:
xstream.voicemgr.voice_limit = args.voice_limit
]],
}