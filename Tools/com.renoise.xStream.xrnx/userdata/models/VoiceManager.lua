--[[===========================================================================
VoiceManager2.lua
===========================================================================]]--

return {
arguments = {
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
  if ((trigger_type == "trigger") 
    and not args.dly_note_on)
  or ((trigger_type == "release") 
    and not args.dly_note_off)
  then
    return 0
  else
    local playpos = playpos:get_fractional()  
    return (args.schedule == xStream.SCHEDULE.LINE)
      and math.floor(playpos.fraction * 255) or 0
  end
end]],
},
events = {
  ["voice.triggered"] = [[------------------------------------------------------------------------------
-- respond to voice-manager events
-- @param arg (table) {type = xVoiceManager.EVENTS, index = int}
------------------------------------------------------------------------------
 
local voice = voices[arg.index]
local pos = buffer:get_scheduled_pos(args.schedule)
buffer:schedule_note_column(pos,{
  note_value = voice.values[1],
  volume_value = voice.values[2],
  instrument_value = rns.selected_instrument_index,
  delay_value = data.get_delay_value("trigger"),
},voice.note_column_index)]],
  ["voice.released"] = [[--------------------------------------------------------------------------------
-- respond to voice-manager events
-- @param arg (table) {type = xVoiceManager.EVENTS, index = int}
--------------------------------------------------------------------------------

local voice = voices[arg.index]
local pos = buffer:get_scheduled_pos(args.schedule)
buffer:schedule_note_column(pos,{
  note_string = "OFF",
  delay_value = data.get_delay_value("release"),
},voice.note_column_index)]],
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