--[[============================================================================
-- Duplex.Globals
============================================================================]]--

--[[--
Various global constants, functions and methods for tracing output

- To enable tracing of output, see TRACE() 

--]]

--==============================================================================


--- The main folder
MODULE_PATH = "./Duplex/"  

DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
DEFAULT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT

--- Lowest possible note 
LOWER_NOTE = -12                  

--- Highest possible note 
UPPER_NOTE = 107                  

--- Decibel constant
RENOISE_DECIBEL = 1.4125375747681 

--- Table of note names 
NOTE_ARRAY = { "C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-" }


--- (Enum)
DEVICE_PROTOCOL = {
  OSC = 1,
  MIDI = 2,
}

--- (Enum) 
DEVICE_MESSAGE = {
  OSC = 1,                    --- Osc Message
  MIDI_CC = 2,                --- Midi CC Message
  MIDI_NOTE = 3,              --- Midi Note Message
  MIDI_PITCH_BEND = 4,        --- Midi Pitch Bend Message
  MIDI_CHANNEL_PRESSURE = 5,  --- Midi Channel Pressure
  MIDI_KEY = 6,               --- Midi Note Message (unspecific)
  MIDI_PROGRAM_CHANGE = 7,    --- Midi Program Change Event
}

--- (Enum) 
DEVICE_EVENT = {
  BUTTON_PRESSED = 1,   -- button event
  BUTTON_RELEASED = 2,  -- button event
  BUTTON_HELD = 3,      -- button event            
  VALUE_CHANGED = 4,    -- slider, encoder event   
  KEY_PRESSED = 5,      -- key event               
  KEY_RELEASED = 6,     -- key event               
  KEY_HELD = 7,         -- key event               
  PITCH_CHANGED = 8,    -- key event               
  CHANNEL_PRESSURE = 9, -- key event               
}

--- (Enum) valid attributes for `param` nodes in the control-map 
INPUT_TYPE = {
  BUTTON = 1,           -- standard bidirectional button which output a value on press & release, but does not control it's internal state
  TOGGLEBUTTON = 2,     -- bidirectional button which toggles the state internally - this type of control does not support release & hold events (examples are buttons on the BCF/BCR controller)
  PUSHBUTTON = 3,       -- bidirectional button which will output values on press & release while controlling it's state internally. Some examples are Automap "momentary" buttons, or TouchOSC pushbuttons
--ENCODER = 4,          -- relative/endless encoder
  FADER = 5,            -- manual fader
  DIAL = 6,             -- basic rotary encoder 
  XYPAD = 7,            -- XY pad 
  KEYBOARD = 8,         -- keyboard
  KEY = 9,              -- key (drum-pad)
  LABEL = 10,            -- text display
}

--- (Enum) used for layout purposes
ORIENTATION = {
  VERTICAL = 1,
  HORIZONTAL = 2,
  NONE = 3,
}


--------------------------------------------------------------------------------
-- helper functions
--------------------------------------------------------------------------------

--- compare two numbers with variable precision

function compare(val1,val2,precision)
  val1 = math.floor(val1 * precision)
  val2 = math.floor(val2 * precision)
  return val1 == val2 
end

--- quick'n'dirty table compare, compares values (not keys)
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

--- count table entries, including mixed types
-- @return int or nil

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

--- look for value within table
-- @return boolean

function table_find(t,val)
  for _,v in ipairs(t)do
    if (val==v) then
      return true
    end
  end
  return false
end

--- check if values are the same
-- (useful for detecting if a color is tinted)
-- @return boolean

function table_has_equal_values(t)

  local val = nil
  for k,v in ipairs(t) do
    if (val==nil) then
      val = v
    end
    if (val~=v) then
      return false
    end
  end
  return true

end


--- split_filename

function split_filename(filename)
  local _, _, name, extension = filename:find("(.+)%.(.+)$")

  if (name ~= nil) then
    return name, extension
  else
    return filename 
  end
end

--- replace character in string

function replace_char(pos, str, r)
  return str:sub(1, pos-1) .. r .. str:sub(pos+1)
end

--- convert note-column pitch number into string value
-- @param val - NoteColumn note-value, e.g. 120
-- @return nil or NoteColumn note-string, e.g. "OFF"

function note_pitch_to_value(val)
  if not val then
    return nil
  elseif (val==120) then
    return "OFF"
  elseif(val==121) then
    return "---"
  elseif(val==0) then
    return "C-0"
  else
    local oct = math.floor(val/12)
    local note = NOTE_ARRAY[(val%12)+1]
    return string.format("%s%s",note,oct)
  end
end

--- interpret note-string
-- some examples of input: C#5  C--1  C-1 C#-1
-- note that wildcard will return a fixed octave (1)
-- @return int

function value_to_midi_pitch(str_val)
  local note = nil
  local octave = nil
  -- use first letter to match note
  local note_part = str_val:sub(0,2)
  for k,v in ipairs(NOTE_ARRAY) do
    if (note_part==v) then
      note = k-1
      break
    end
  end
  local oct_part = strip_channel_info(str_val)
  if (oct_part):find("*") then
    octave = 1
  else
    octave = tonumber((oct_part):sub(3))
  end
  return note+octave*12
end

--- extract cc number from a parameter
function extract_cc_num(str_val)
 return str_val:match("%d+")
end

--- get_playing_pattern
function get_playing_pattern()
  local idx = renoise.song().transport.playback_pos.sequence
  return renoise.song().patterns[renoise.song().sequencer.pattern_sequence[idx]]
end

--- get_master_track
function get_master_track()
  for i,v in pairs(renoise.song().tracks) do
    if v.type == renoise.Track.TRACK_TYPE_MASTER then
      return v
    end
  end
end

--- get_master_track_index
function get_master_track_index()
  for i,v in pairs(renoise.song().tracks) do
    if v.type == renoise.Track.TRACK_TYPE_MASTER then
      return i
    end
  end
end

--- get send track
function send_track(send_index)
  if (send_index <= renoise.song().send_track_count) then
    -- send tracks are always behind the master track
    local trk_idx = renoise.song().sequencer_track_count + 1 + send_index
    return renoise.song():track(trk_idx)
  else
    return nil
  end
end

--- get average from color
function get_color_average(color)
  return (color[1]+color[2]+color[3])/3
end

--- check if colorspace is monochromatic
function is_monochrome(colorspace)
  if table.is_empty(colorspace) then
    return true
  end
  local val = math.max(colorspace[1],
    math.max(colorspace[2],
    math.max(colorspace[3])))
  return (val==1)
end


--- remove channel info from value-string
function strip_channel_info(str)
  return string.gsub (str, "(|Ch[0-9]+)", "")
end

--- remove note info from value-string
function strip_note_info(str)
  local idx = (str):find("|") or 0
  return str:sub(idx)
end

--- remove note info from value-string
function has_note_info(str)
  local idx = (str):find("|") or 0
  return str:sub(idx)
end


--- get the type of track: sequencer/master/send
function determine_track_type(track_index)
  local master_idx = get_master_track_index()
  local tracks = renoise.song().tracks
  if (track_index < master_idx) then
    return renoise.Track.TRACK_TYPE_SEQUENCER
  elseif (track_index == master_idx) then
    return renoise.Track.TRACK_TYPE_MASTER
  elseif (track_index <= #tracks) then
    return renoise.Track.TRACK_TYPE_SEND
  end
end

--- round_value (from http://lua-users.org/wiki/SimpleRound)
function round_value(num) 
  if num >= 0 then return math.floor(num+.5) 
  else return math.ceil(num-.5) end
end

--- clamp_value: ensure value is within min/max
function clamp_value(value, min_value, max_value)
  return math.min(max_value, math.max(value, min_value))
end

--- wrap_value: 'rotate' value within specified range
-- (with a range of 0-127, a value of 150 will output 22
function wrap_value(value, min_value, max_value)
  local range = max_value - min_value + 1
  assert(range > 0, "invalid range")
  while (value < min_value) do
    value = value + range
  end
  while (value > max_value) do
    value = value - range
  end
  return value
end

--- scale_value: scale a value to a range within a range
-- for example, we could have a range of 0-127, and want
-- to distribute the numbers 1-8 evenly across that range
-- @param value (number) the value we wish to scale
-- @param low_val (number) the lowest value in 'our' range
-- @param high_val (number) the highest value in 'our' range
-- @param min_val (number) the lowest possible value
-- @param max_val (number) the highest possible value
function scale_value(value,low_val,high_val,min_val,max_val)
  local incr1 = min_val/(high_val-low_val)
  local incr2 = max_val/(high_val-low_val)-incr1
  return(((value-low_val)*incr2)+min_val)
end

--- logarithmic scaling within a fixed space
-- @param ceiling (number) the upper boundary 
-- @param val (number) the value to scale
function log_scale(ceiling,val)
  local log_const = ceiling/math.log(ceiling)
  return math.log(val)*log_const
end

--- inverse logarithmic scaling (exponential)
function inv_log_scale(ceiling,val)
  local ref_val = ceiling-val+1
  return ceiling-log_scale(ceiling,ref_val)
end

--- return the fractional part of a number
function fraction(val)
  return val-math.floor(val)
end

--- check for whole number, using format() 
function is_whole_number(n)
  return (("%.8f"):format(n-math.floor(n)) == "0.00000000") 
end

--- determine the sign of a number
function sign(x)
    return (x<0 and -1) or 1
end

--- get average of supplied numbers
function average(...)
  local rslt = 0
  for i=1, #arg do
    rslt = rslt+arg[i]
  end
	return rslt/#arg
end

--- greatest common divisor
function gcd(m,n)
  while n ~= 0 do
    local q = m
    m = n
    n = q % n
  end
  return m
end

--- least common multiplier (2 args)
function lcm(m,n)
  return ( m ~= 0 and n ~= 0 ) and m * n / gcd( m, n ) or 0
end

--- find least common multiplier 
-- @param t (table), use values in table as argument
function least_common(t)
  local cm = t[1]
  for i=1,#t-1,1 do
    cm = lcm(cm,t[i+1])
  end
  return cm
end


--------------------------------------------------------------------------------
--- Debug tracing & logging
--
-- set one or more expressions to either show all or only a few messages 
-- from TRACE calls.
-- 
-- Some examples: 
--    {".*"} -> show all traces
--    {"^Display:"} " -> show traces, starting with "Display:" only
--    {"^ControlMap:", "^Display:"} -> show "Display:" and "ControlMap:"

local _log_to_file = false
local _trace_filters = nil
--local _trace_filters = {"^Mlrx"}
--local _trace_filters = {"^Mlrx*","^Browser*"}
--local _trace_filters = {".*"}

--------------------------------------------------------------------------------

if (_trace_filters ~= nil) then
  
  --- TRACE impl
  -- @param (vararg)
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
        if _log_to_file then
          LOG_FILE(result)
        end
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


--- call this to avoid using print() statements in source code
function LOG(str)
  if _log_to_file then
    LOG_FILE(str)
  end
  print(str)
end

--- append text to log.txt in the tool's root folder
-- (warning: this is slow, only use when needed!)
function LOG_FILE(str)
  str =  ("%f - %s"):format(os.clock(),str)
  local str_log = renoise.tool().bundle_path .. "log.txt"
  local fileref = io.open(str_log,"a+")
  fileref:write(str.."\n")
  fileref:flush()
  fileref:close()
end


