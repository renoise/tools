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
  ["note_off"] = [[-------------------------------------------------------------------------------
-- respond to note_off messages
-- @param xmsg, the xMidiMessage we have received
-------------------------------------------------------------------------------

if (data.voice_count > #voices) then
  data.voice_count = #voices
  --xstream.buffer:unschedule()  
end


]],
  ["note_on"] = [[-------------------------------------------------------------------------------
-- respond to note_on messages 
-- @param xmsg, the xMidiMessage we have received
-------------------------------------------------------------------------------

if (data.voice_count < #voices) then
  data.voice_count = #voices
  local voice = voices[#voices]
  local scheduled_xline = EMPTY_XLINE
  scheduled_xline.note_columns[voice.note_column_index] = {
    note_value = voice.values[1],
    volume_value = voice.values[2]
  }
  xstream.buffer:schedule_line(xStream.SCHEDULE.NONE,scheduled_xline)
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