--[[===========================================================================
VoiceManager.lua
===========================================================================]]--

return {
arguments = {
},
presets = {
},
data = {
  ["voice_count"] = [[-------------------------------------------------------------------------------
-- number of active voices in output
-------------------------------------------------------------------------------

return 0
]],
},
events = {
  ["voice.triggered"] = [[--------------------------------------------------------------------------------
-- respond to voice-manager events
-- @param arg (table) {type = xVoiceManager.EVENTS, index = int}
--------------------------------------------------------------------------------
]],
  ["voice.released"] = [[--------------------------------------------------------------------------------
-- respond to voice-manager events
-- @param arg (table) {type = xVoiceManager.EVENTS, index = int}
--------------------------------------------------------------------------------
]],
  ["midi.note_off"] = [[-------------------------------------------------------------------------------
-- respond to note_off messages
-- @param xmsg, the xMidiMessage we have received
-------------------------------------------------------------------------------

if (data.voice_count > #voices) then
  data.voice_count = #voices
  --xstream.buffer:unschedule()  
end


]],
  ["midi.note_on"] = [[-------------------------------------------------------------------------------
-- respond to note_on messages 
-- @param xmsg, the xMidiMessage we have received
-------------------------------------------------------------------------------

if (data.voice_count < #voices) then
  data.voice_count = #voices
  local voice = voices[#voices]
  local scheduling = xStream.SCHEDULE.NONE 
  local pos = xstream.buffer:get_scheduled_pos(scheduling)
  --print("buffer events",rprint(xstream.buffer.events))
  print("note_on - read from pos",pos)
  local scheduled_xline = xstream.buffer:read_pos(pos)
  rprint("scheduled_xline",scheduled_xline)
  scheduled_xline.note_columns[voice.note_column_index] = {
    note_value = voice.values[1],
    volume_value = voice.values[2]
  }
  xstream.buffer:add_line(pos,scheduled_xline)
end

]],
},
options = {
 color = 0x60AACA,
},
callback = [[
-------------------------------------------------------------------------------
-- Testing the voice-manager + MIDI events
-- All output is created by event hooks that schedule xlines
-------------------------------------------------------------------------------











]],
}