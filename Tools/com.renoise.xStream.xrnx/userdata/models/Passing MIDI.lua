--[[===========================================================================
Passing MIDI.lua
===========================================================================]]--

return {
arguments = {
},
presets = {
},
data = {
},
events = {
  ["midi.note_on"] = [[------------------------------------------------------------------------------
-- respond to MIDI 'note_on' messages
-- @param xmsg, the xMidiMessage we have received
------------------------------------------------------------------------------

xstream:output_message(xmsg,'internal_auto')]],
  ["midi.note_off"] = [[------------------------------------------------------------------------------
-- respond to MIDI 'note_off' messages
-- @param xmsg, the xMidiMessage we have received
------------------------------------------------------------------------------

xstream:output_message(xmsg,'internal_auto')]],
},
options = {
 color = 0x000000,
},
callback = [[
-------------------------------------------------------------------------------
-- Passing MIDI to the internal OSC server in Renoise 
-- look at the events.midi.note_on/off 
-------------------------------------------------------------------------------

]],
}