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

MIDI_CC_MESSAGE = 2
MIDI_NOTE_MESSAGE = 3
MIDI_PITCH_BEND_MESSAGE = 4

OSC_MESSAGE = 5

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
-- bidirectional button which toggles the state internally (LED)
CONTROLLER_TOGGLEBUTTON = 21    
--  bidirectional encoder (LED)
--CONTROLLER_ENCODER = 22
-- manual fader
CONTROLLER_FADER = 23
-- basic rotary encoder 
CONTROLLER_DIAL = 24      

VERTICAL = 80
HORIZONTAL = 81


-- Renoise API consts

RENOISE_DECIBEL = 1.4125375747681

DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
DEFAULT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT

MUTE_STATE_ACTIVE = 1
MUTE_STATE_OFF = 2


--------------------------------------------------------------------------------
-- device configurations
--------------------------------------------------------------------------------

-- device and application setup for controllers, registered by the controllers
-- itself. each entry must have the following properties defined. all 
-- configurations will be shown in the browser, sorted by device name 

-- {
--   ** configuration properties
--   name = "Some Config", -- config name as visible in the browser
--   pinned = true, -- when true, config is added to the duplex context menu
--
--   ** device properties
--   device = {
--     class_name = nil, -- optional custom device class          
--     display_name = "Some Device", -- as visible in the browser
--     device_name = "Some Device", -- MIDI device name
--     control_map = "controlmap.xml", -- path & name of the control map
--     protocol = DEVICE_MIDI_PROTOCOL
--   },
--
--   ** applications
--   applications = { -- list of applications and app configs
--     Mixer = { options = "Something" }, -- a mixer app
--     Effect = { options = "Something" } -- an effect app
--   } 
-- }
  
duplex_configurations = table.create()


--------------------------------------------------------------------------------
-- preferences
--------------------------------------------------------------------------------

-- global or configuration settings for duplex

duplex_preferences = renoise.Document.create{
  -- list of device configurations that should be started by default
  autostart_configurations = {""},

  -- the number of seconds required to trigger DEVICE_EVENT_BUTTON_HELD
  -- fractional values are supported, 0.5 is half a second
  button_hold_time = 1,

  -- debug option: when enabled, dump MIDI messages received and send by duplex
  -- to the sdt out (Renoise terminal)
  dump_midi = false
}


--------------------------------------------------------------------------------
-- helper functions
--------------------------------------------------------------------------------

-- compare two numbers with variable precision

function compare(val1,val2,precision)
  val1 = math.floor(val1 * precision)
  val2 = math.floor(val2 * precision)
  return val1 == val2 
end

-- quick'n'dirty table compare, compares values (not keys)
-- @return boolean, true if identical

function table_compare(t1,t2)
  local to_string = function(t)
    local rslt = ""
    for _,__ in ipairs(table.values(t))do
      rslt = rslt..tostring(__)..","
    end
    return rslt
  end
  return (to_string(t1)==to_string(t2))
end

-- count table entries, including mixed types
-- @return number or nil

function table_count(t)
  local n=0
  if ("table" == type(t)) then
    for key in pairs(t) do
      n = n + 1
    end
    return n
  else
    return nil
  end
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

--local __trace_filters = {"^MidiDevice"}
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

  function TRACE()
    -- do nothing
  end
    
end

