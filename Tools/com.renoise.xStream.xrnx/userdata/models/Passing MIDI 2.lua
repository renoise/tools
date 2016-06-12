--[[===========================================================================
Passing MIDI 2.lua
===========================================================================]]--

return {
arguments = {
  {
      ["locked"] = false,
      ["name"] = "voice_limit",
      ["linked"] = false,
      ["value"] = 1,
      ["properties"] = {
          ["max"] = 12,
          ["min"] = 0,
          ["display_as"] = "integer",
          ["zero_based"] = false,
      },
      ["description"] = "",
  },
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

local xmsg = xvoicemgr.voices[xvoicemgr.triggered_index]
xstream:output_message(xmsg,'internal_auto')]],
  ["voice.stolen"] = [[------------------------------------------------------------------------------
-- respond to voice-manager events
-- @param arg (table) {type = xVoiceManager.EVENTS, index = int}
------------------------------------------------------------------------------

local xmsg = xvoicemgr.voices[xvoicemgr.released_index]
xmsg.message_type = xMidiMessage.TYPE.NOTE_OFF
xstream:output_message(xmsg,'internal_auto')]],
  ["voice.released"] = [[------------------------------------------------------------------------------
-- respond to voice-manager events
-- @param arg (table) {type = xVoiceManager.EVENTS, index = int}
------------------------------------------------------------------------------

local xmsg = xvoicemgr.voices[xvoicemgr.released_index]
xstream:output_message(xmsg,'internal_auto')]],
  ["midi.pitch_bend"] = [[------------------------------------------------------------------------------
-- respond to MIDI 'pitch_bend' messages
-- @param xmsg, the xMidiMessage we have received
------------------------------------------------------------------------------

xstream:output_message(xmsg,'internal_auto')

local visible_note_columns = rns.tracks[track_index].visible_note_columns
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
 color = 0x000000,
},
callback = [[
-------------------------------------------------------------------------------
-- Passing MIDI to the internal OSC server in Renoise 
-- How it works: look at the event callbacks to see how messages are passed
-- NB: the OSC server needs to be enabled and match the settings in 'Options'
-------------------------------------------------------------------------------

-- override global voicemgr setting:
xstream.voicemgr.voice_limit = args.voice_limit







]],
}