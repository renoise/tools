--[[----------------------------------------------------------------------------
-- Duplex.Globals
----------------------------------------------------------------------------]]--

-- Consts

MODULE_PATH = "./Duplex/"  
NOTE_ARRAY = { "C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-" }


-- Protocols

DEVICE_OSC_PROTOCOL = 0
DEVICE_MIDI_PROTOCOL = 1

-- Message types

MIDI_CC_MESSAGE = 2
MIDI_NOTE_MESSAGE = 3
MIDI_PITCH_BEND_MESSAGE = 4
OSC_MESSAGE = 5

-- Event types

--  button event
DEVICE_EVENT_BUTTON_PRESSED = 1  
--  button event
DEVICE_EVENT_BUTTON_RELEASED = 2  
--  slider, encoder event
DEVICE_EVENT_VALUE_CHANGED = 3    
--  button event
DEVICE_EVENT_BUTTON_HELD = 4

-- Input methods

-- standard bidirectional button which output a value on press
-- & release, but does not control it's internal state
-- (a control-map @type="button" attribute)
CONTROLLER_BUTTON = 1    
-- bidirectional button which toggles the state internally 
-- this type of control does not support release & hold events
-- Examples are buttons on the BCF/BCR controller 
-- (a control-map @type="togglebutton" attribute)
CONTROLLER_TOGGLEBUTTON = 2    
-- bidirectional button which will output values on press & release 
-- while controlling it's state internally. Some examples are 
-- Automap "momentary" buttons, or TouchOSC pushbuttons
-- (a control-map @type="pushbutton" attribute)
CONTROLLER_PUSHBUTTON = 3
--  relative/endless encoder
-- (a control-map @type="encoder" attribute)
--CONTROLLER_ENCODER = 3
-- manual fader
-- (a control-map @type="fader" attribute)
CONTROLLER_FADER = 4
-- basic rotary encoder 
-- (a control-map @type="dial" attribute)
CONTROLLER_DIAL = 5      

-- UIComponents

UI_COMPONENT_TOGGLEBUTTON = 1
UI_COMPONENT_PUSHBUTTON = 2
UI_COMPONENT_SLIDER = 3
UI_COMPONENT_SPINNER = 4
UI_COMPONENT_CUSTOM = 5
UI_COMPONENT_BUTTONSTRIP = 6

-- Miscellaneous

VERTICAL = 80
HORIZONTAL = 81


-- Renoise API consts

RENOISE_DECIBEL = 1.4125375747681

DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
DEFAULT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT

MUTE_STATE_ACTIVE = 1
MUTE_STATE_OFF = 2
MUTE_STATE_MUTED = 3

SOLO_STATE_ON = 1
SOLO_STATE_OFF = 2

TRACK_TYPE_SEQUENCER = 1
TRACK_TYPE_MASTER = 2
TRACK_TYPE_SEND = 3

--------------------------------------------------------------------------------
-- device configurations & preferences
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

-- global or configuration settings for duplex

duplex_preferences = renoise.Document.create("ScriptingToolPreferences") {

  -- the number of seconds required to trigger DEVICE_EVENT_BUTTON_HELD
  -- fractional values are supported, 0.5 is half a second
  button_hold_time = 0.5,

  -- debug option: when enabled, dump MIDI messages received and send by duplex
  -- to the sdt out (Renoise terminal)
  dump_midi = false,

  -- list of user configuration settings (like MIDI device names, app configs)
  -- added during runtime for all available configs:
  
  -- configurations = {
  --    autostart [boolean] -- if this config should be started with Renoise
  --    device_in_port [string] -- custom MIDI in device name
  --    device_out_port [string] -- custom MIDI out device name
  -- }
}


--------------------------------------------------------------------------------

-- returns a hopefully unique, xml node friendly key, that is used in the 
-- preferences tree for the given configuration

function configuration_settings_key(config)

  -- use device_name + config_name as base
  local key = (config.device.display_name .. " " .. config.name):lower()
  
  -- convert spaces to _'s
  key = key:gsub("%s", "_")
  -- remove all non alnums
  key = key:gsub("[^%w_]", "")
  -- and removed doubled _'s
  key = key:gsub("[_]+", "_")
  
  return key
end


--------------------------------------------------------------------------------

-- returns the preferences user settings node for the given configuration.
-- always valid, but properties in the settings will be empty by default

function configuration_settings(config)

  local key = configuration_settings_key(config)
  return duplex_preferences.configurations[key]
end


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
    for _,v in ipairs(table.values(t))do
      rslt = rslt..tostring(v)..","
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

-- split_filename

function split_filename(filename)
  local _, _, name, extension = filename:find("(.+)%.(.+)$")

  if (name ~= nil) then
    return name, extension
  else
    return filename 
  end
end

-- get_playing_pattern

function get_playing_pattern()
  local idx = renoise.song().transport.playback_pos.sequence
  return renoise.song().patterns[renoise.song().sequencer.pattern_sequence[idx]]
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

-- get average from color

function get_color_average(color)
  return (color[1]+color[2]+color[3])/3
end

-- check if colorspace is monochromatic
function is_monochrome(colorspace)
  if table.is_empty(colorspace) then
    return true
  end
  local val = math.max(colorspace[1],
    math.max(colorspace[2],
    math.max(colorspace[3])))
  return (val==1)
end


-- remove channel info from value-string

function strip_channel_info(str)
  return string.gsub (str, "(|Ch[0-9]+)", "")
end


-- get the type of track: sequencer/master/send

function determine_track_type(track_index)
  local master_idx = get_master_track_index()
  local tracks = renoise.song().tracks
  if (track_index < master_idx) then
    return TRACK_TYPE_SEQUENCER
  elseif (track_index == master_idx) then
    return TRACK_TYPE_MASTER
  elseif (track_index <= #tracks) then
    return TRACK_TYPE_SEND
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

local _trace_filters = nil
--local _trace_filters = {"^Mixer"}
--local _trace_filters = {"^Recorder","^UISlider"}
--local _trace_filters = {"^UIButtonStrip", "^UISlider","^Browser"}
--local _trace_filters = {"^Recorder", "^Effect","^Navigator","^Mixer","^Matrix"}
--local _trace_filters = {"^StepSequencer", "^Transport","^MidiDevice","^MessageStream","^"}
--local _trace_filters = {".*"}

--------------------------------------------------------------------------------
-- TRACE impl

if (_trace_filters ~= nil) then
  
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
    for _,filter in pairs(_trace_filters) do
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

