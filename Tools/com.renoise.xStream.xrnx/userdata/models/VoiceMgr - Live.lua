--[[===========================================================================
VoiceMgr - Realtime.lua
===========================================================================]]--

return {
arguments = {
  {
      ["locked"] = false,
      ["name"] = "voice_limit",
      ["linked"] = false,
      ["value"] = 2,
      ["properties"] = {
          ["min"] = 0,
          ["max"] = 12,
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
  ["voice.stolen"] = [[------------------------------------------------------------------------------
-- respond to voice-manager events
-- @param arg (table) {type = xVoiceManager.EVENTS, index = int}
------------------------------------------------------------------------------
print(">>> events.voice.stolen",xvoicemgr.stolen_index)
local xmsg = xvoicemgr.voices[xvoicemgr.stolen_index]
xmsg.message_type = xMidiMessage.TYPE.NOTE_OFF
xstream:output_message(xmsg,'internal_auto')]],
  ["voice.triggered"] = [[------------------------------------------------------------------------------
-- respond to voice-manager events
-- @param arg (table) {type = xVoiceManager.EVENTS, index = int}
------------------------------------------------------------------------------
print(">>> events.voice.triggered",xvoicemgr.triggered_index)
local xmsg = xvoicemgr.voices[xvoicemgr.triggered_index]
xstream:output_message(xmsg,'internal_auto')]],
  ["args.voice_limit"] = [[------------------------------------------------------------------------------
-- respond to argument 'voice_limit' changes
-- @param val (number/boolean/string)}
------------------------------------------------------------------------------

xvoicemgr.voice_limit = val]],
  ["voice.released"] = [[------------------------------------------------------------------------------
-- respond to voice-manager events
-- @param arg (table) {type = xVoiceManager.EVENTS, index = int}
------------------------------------------------------------------------------
print(">>> events.voice.released",xvoicemgr.released_index)
local xmsg = xvoicemgr.voices[xvoicemgr.released_index]
xstream:output_message(xmsg,'internal_auto')]],
  ["midi.pitch_bend"] = [[------------------------------------------------------------------------------
-- respond to MIDI 'pitch_bend' messages
-- @param xmsg, the xMidiMessage we have received
------------------------------------------------------------------------------

xstream:output_message(xmsg,'internal_auto')]],
},
options = {
 color = 0x000000,
},
callback = [[
-------------------------------------------------------------------------------
-- Passing MIDI to the internal OSC server in Renoise in real-time. 
-- NB: the OSC server needs to be enabled and match the settings in 'Options',
-- or the model will not be able to route it's MIDI messages into Renoise.
-------------------------------------------------------------------------------

-- nothing to see here, but check out the event callbacks ↘
]],
}