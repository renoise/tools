--[[----------------------------------------------------------------------------
-- Duplex.Globals
----------------------------------------------------------------------------]]--

-- use standard Lua API extensions from branches/future already now
pcall(require, "future")


--------------------------------------------------------------------------------
-- Duplex consts
--------------------------------------------------------------------------------

MODULE_PATH = "./Duplex/"  
NOTE_ARRAY = { "C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-" }

-- Protocols

DEVICE_OSC_PROTOCOL = 0
DEVICE_MIDI_PROTOCOL = 1

MIDI_CC_MESSAGE = 6
MIDI_NOTE_MESSAGE = 7
OSC_MESSAGE = 8

-- Event types

--  button event
DEVICE_EVENT_BUTTON_PRESSED = 10  
--  button event
DEVICE_EVENT_BUTTON_RELEASED = 11  
--  slider, encoder event
DEVICE_EVENT_VALUE_CHANGED = 12    
--  button event
DEVICE_EVENT_BUTTON_HELD = 13

-- Input methods

-- bidirectional button (LED)
CONTROLLER_BUTTON = 20    
--  bidirectional encoder (LED)
CONTROLLER_ENCODER = 21  
-- manual fader (possibly with parameter-pickup, so we both recieve & transmit MIDI)  
CONTROLLER_FADER = 22    
-- motorized fader
CONTROLLER_MFADER = 23   
-- basic rotary encoder (MIDI input only) 
CONTROLLER_POT = 24      

VERTICAL = 80
HORIZONTAL = 81


-- Renoise API consts

RENOISE_DECIBEL = 1.4125375747681

DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
DEFAULT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT

MUTE_STATE_OFF = 2
MUTE_STATE_ACTIVE = 1


--------------------------------------------------------------------------------
-- helper functions
--------------------------------------------------------------------------------

-- compare two numbers with variable precision

function compare(val1,val2,precision)
  val1 = math.floor(val1*precision)
  val2 = math.floor(val2*precision)
  return val1==val2 
end


-- get_master_track

function get_master_track()
  for i,v in pairs(renoise.song().tracks) do
    if v.type == renoise.Track.TRACK_TYPE_MASTER then
      return v
    end
  end
end


-- get_master_track_index

function get_master_track_index()
  for i,v in pairs(renoise.song().tracks) do
    if v.type == renoise.Track.TRACK_TYPE_MASTER then
      return i
    end
  end
end



--------------------------------------------------------------------------------
-- debug tracing
--------------------------------------------------------------------------------

-- set one or more expressions to either show all or only a few messages 
-- from TRACE calls.

-- Some examples: 
-- {".*"} -> show all traces
-- {"^Display:"} " -> show traces, starting with "Display:" only
-- {"^ControlMap:", "^Display:"} -> show "Display:" and "ControlMap:"

local __trace_filters = nil


--------------------------------------------------------------------------------
-- TRACE impl

if (__trace_filters ~= nil) then
  
  function TRACE(...)
    local result = ""
  
    -- try serializing a value or return "???"
    local function serialize(obj)
      local succeeded, result = pcall(tostring, obj)
      if succeeded then
        return result 
      else
       return "???"
      end
    end
    
    -- table dump helper
    local function rdump(t, indent, done)
      local result = "\n"
      done = done or {}
      indent = indent or string.rep(' ', 2)
      
      local next_indent
      for key, value in pairs(t) do
        if (type(value) == 'table' and not done[value]) then
          done[value] = true
          next_indent = next_indent or (indent .. string.rep(' ', 2))
          result = result .. indent .. '[' .. serialize(key) .. '] => table\n'
          rdump(value, next_indent .. string.rep(' ', 2), done)
        else
          result = result .. indent .. '[' .. serialize(key) .. '] => ' .. 
            serialize(value) .. '\n'
        end
      end
      
      return result
    end
   
    -- concat args to a string
    local n = select('#', ...)
    for i = 1, n do
      local obj = select(i, ...)
      if( type(obj) == 'table') then
        result = result .. rdump(obj)
      else
        result = result .. serialize(select(i, ...))
        if (i ~= n) then 
          result = result .. "\t"
        end
      end
    end
  
    -- apply filter
    for _,filter in pairs(__trace_filters) do
      if result:find(filter) then
        print(result)
        break
      end
    end
  end
  
else

  function TRACE(...)
    -- do nothing
  end
    
end

