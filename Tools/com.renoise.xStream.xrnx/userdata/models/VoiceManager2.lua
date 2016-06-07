--[[===========================================================================
VoiceManager2.lua
===========================================================================]]--

return {
arguments = {
},
presets = {
},
data = {
},
events = {
  ["voice.triggered"] = [[------------------------------------------------------------------------------
-- respond to voice-manager events
-- @param arg (table) {type = xVoiceManager.EVENTS, index = int}
------------------------------------------------------------------------------

local voice = voices[arg.index]
local pos = buffer:get_scheduled_pos(xStream.SCHEDULE.NONE)
buffer:schedule_note_column(pos,{
  note_value = voice.values[1],
  volume_value = voice.values[2],
  instrument_value = rns.selected_instrument_index,
},voice.note_column_index)
]],
  ["voice.released"] = [[--------------------------------------------------------------------------------
-- respond to voice-manager events
-- @param arg (table) {type = xVoiceManager.EVENTS, index = int}
--------------------------------------------------------------------------------

local voice = voices[arg.index]
local pos = buffer:get_scheduled_pos(xStream.SCHEDULE.NONE)
buffer:schedule_note_column(pos,{
  note_string = "OFF",
},voice.note_column_index)
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