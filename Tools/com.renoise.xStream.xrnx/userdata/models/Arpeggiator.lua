--[[===========================================================================
Arpeggiator.lua
===========================================================================]]--

return {
arguments = {
  {
      ["description"] = "",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "mode",
      ["properties"] = {
          ["display_as"] = "popup",
          ["fire_on_start"] = false,
          ["impacts_buffer"] = false,
          ["items"] = {
              "up",
              "down",
              "up_down",
              "ordered",
              "random",
          },
          ["max"] = 5,
          ["min"] = 1,
      },
      ["value"] = 2,
  },
  {
      ["description"] = "",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "phrase_idx",
      ["properties"] = {
          ["display_as"] = "integer",
          ["max"] = 100,
          ["min"] = 0,
          ["zero_based"] = false,
      },
      ["value"] = 0,
  },
  {
      ["description"] = "",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "lock_to",
      ["properties"] = {
          ["display_as"] = "popup",
          ["fire_on_start"] = false,
          ["impacts_buffer"] = false,
          ["items"] = {
              "pattern",
              "keystroke",
              "stream",
          },
          ["max"] = 3,
          ["min"] = 1,
      },
      ["value"] = 1,
  },
  {
      ["description"] = "",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "stepsize",
      ["properties"] = {
          ["display_as"] = "integer",
          ["fire_on_start"] = false,
          ["max"] = 16,
          ["min"] = 1,
          ["zero_based"] = false,
      },
      ["value"] = 1,
  },
  {
      ["description"] = "",
      ["linked"] = false,
      ["locked"] = false,
      ["name"] = "oct_range",
      ["properties"] = {
          ["display_as"] = "integer",
          ["fire_on_start"] = false,
          ["impacts_buffer"] = false,
          ["max"] = 4,
          ["min"] = 0,
          ["zero_based"] = false,
      },
      ["value"] = 0,
  },
},
presets = {
  {
      ["lock_to"] = 1,
      ["mode"] = 1,
      ["name"] = "",
      ["oct_range"] = 1,
      ["stepsize"] = 1,
  },
},
data = {
  ["curr_oct"] = [[-- return a value of some kind 
return 0]],
  ["direction"] = [[-- "up" or "down" (when up_down)
return "up"]],
  ["get_voice_index"] = [[-------------------------------------------------------------------------------
-- return the active voice index and maintain the position/octave
-------------------------------------------------------------------------------

return function(arg)
  local voice,voice_idx = nil  
  if (args.mode == 1) then -- up --
  
    voice = xvoices[data.position]
    voice,voice_idx = xvoicemgr:get_by_pitch(voice.values[1])
    local _,higher_idx = xvoicemgr:get_higher(voice_idx)
    local _,highest_idx = xvoicemgr:get_highest()
    if higher_idx then
      voice_idx = higher_idx
    elseif (voice_idx == highest_idx) then
      local lowest_voice,lowest_idx = xvoicemgr:get_lowest()
      voice_idx = lowest_idx    
      data.rotate_oct("up")
    else
      voice_idx = highest_idx
    end
    
  elseif (args.mode == 2) then -- down --
    
    voice = xvoices[data.position]
    voice,voice_idx = xvoicemgr:get_by_pitch(voice.values[1])

    local _,lower_idx = xvoicemgr:get_lower(voice_idx)
    local _,lowest_idx = xvoicemgr:get_lowest()
    if lower_idx then
      voice_idx = lower_idx
    elseif (voice_idx == lowest_idx) then
      local _,highest_idx = xvoicemgr:get_highest()
      voice_idx = highest_idx        
      data.rotate_oct("down")     
    else
      voice_idx = lowest_idx
    end
        
  elseif (args.mode == 3) then -- up_down --

    voice = xvoices[data.position]
    voice,voice_idx = xvoicemgr:get_by_pitch(voice.values[1])
  
    local _,lowest_idx = xvoicemgr:get_lowest()
    local _,highest_idx = xvoicemgr:get_highest()
    
    if (highest_idx == voice_idx) then
      local _,lower_idx = xvoicemgr:get_lower(voice_idx)
      voice_idx = lower_idx
      data.direction = "down"
      data.rotate_oct("down")
    elseif (lowest_idx == voice_idx) then
      local _,higher_idx = xvoicemgr:get_higher(voice_idx)
      voice_idx = higher_idx
      data.direction = "up"
      data.rotate_oct("up")
    elseif (data.direction == "up") then
      local _,higher_idx = xvoicemgr:get_higher(voice_idx)
      voice_idx = higher_idx
    elseif (data.direction == "down") then
      local _,lower_idx = xvoicemgr:get_lower(voice_idx)
      voice_idx = lower_idx
    end
    
  elseif (args.mode == 4) then -- ordered --
  
    data.position = (data.position+1) % #xvoices
    if (data.position == 0) then
      data.position = #xvoices
      data.rotate_oct("up")
    end    
    
  elseif (args.mode == 5) then -- random --
  
    data.position = math.random(1,#xvoices)
    data.curr_oct = math.random(0,args.oct_range)
    
  end
  --print(">>> voice_idx",voice_idx)
  if not voice_idx then
    voice_idx = data.position
  else
    data.position = voice_idx  
  end
  return voice_idx
end]],
  ["keystroke_xinc"] = [[-- remember the position at which the key was first struck
return nil]],
  ["position"] = [[-- return a value of some kind 
return 1]],
  ["rotate_oct"] = [[-- return a value of some kind
return function(direction)
  if (direction == "down") then
    if (data.curr_oct > 0) then
      data.curr_oct = data.curr_oct-1
    elseif (data.curr_oct == 0) then
      data.curr_oct = args.oct_range
    end  
  elseif (direction == "up") then
    if (data.curr_oct < args.oct_range) then
      data.curr_oct = data.curr_oct+1
    elseif (data.curr_oct == args.oct_range) then
      data.curr_oct = 0
    end    
  end
  return 
end]],
},
events = {
  ["args.oct_range"] = [[------------------------------------------------------------------------------
-- respond to argument 'oct_range' changes
-- @param val (number/boolean/string)}
------------------------------------------------------------------------------

-- ensure octave is always valid
if (data.curr_oct > args.oct_range) then
  data.curr_oct = args.oct_range
end]],
  ["voice.released"] = [[------------------------------------------------------------------------------
-- respond to voice-manager events
-- ('xvoicemgr.triggered/released/stolen_index' contains the value)
------------------------------------------------------------------------------
-- make sure position is always valid
if (data.position == #xvoices) then
  data.position = data.position-1
end
-- clear output ahead of the current position
xbuffer:wipe_futures()]],
  ["voice.triggered"] = [[------------------------------------------------------------------------------
-- respond to voice-manager events
-- ('xvoicemgr.triggered/released/stolen_index' contains the value)
------------------------------------------------------------------------------

-- initialize on first note
if (#xvoices == 1) then
  data.position = 1
  data.keystroke_xinc = xinc  
  data.curr_oct = args.oct_range
  
end

xbuffer:wipe_futures()]],
},
options = {
 color = 0x935875,
},
callback = [[
-------------------------------------------------------------------------------
-- Arpeggiator model
-- * accepts input via MIDI (enable in Options) 
-- * traditional arpeggiator modes: up/down/ordered/random
-- * 'lock' defines if generated pattern is locked to pattern start,
--   streaming progress or time since first keystroke
-------------------------------------------------------------------------------

local note_col_idx = rns.selected_note_column_index

-- figure out whether we should output at all...
if (#xvoices > 0) then

  -- global counter 
  local count = nil
  if (args.lock_to == 1) then -- pattern
    count = xpos.line-1
  elseif (args.lock_to == 2) then -- keystroke
    count = xinc-data.keystroke_xinc
  elseif (args.lock_to == 3) then -- stream
    count = xinc
  end
  
  local do_output = (count % args.stepsize == 0)
  if do_output then     
    local voice_idx = data.get_voice_index()
    local voice = xvoices[voice_idx]
    xline.note_columns[note_col_idx] = {
      note_value = voice.values[1] + (data.curr_oct*12),
      volume_value = voice.values[2],
      instrument_value = rns.selected_instrument_index-1,
    }
    xline.effect_columns[1] = {
      number_string = "0Z",
      amount_value = args.phrase_idx,
    }
  else
    -- clear inbetween output
    xline.note_columns[note_col_idx] = {}
  end
else
  xline.note_columns[note_col_idx] = {}
end
]],
}