--[[============================================================================
-- Duplex.Globals
============================================================================]]--

--[[--

Various global constants, functions and methods

--]]

--==============================================================================


--- The main folder
MODULE_PATH = "./Duplex/"  

DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
DEFAULT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT

--- (Enum) used for layout purposes
ORIENTATION = {
  VERTICAL = 1,
  HORIZONTAL = 2,
  NONE = 3,
}

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
  MIDI_NRPN = 8,              --- Midi Non-Registered Parameter Number
}


--- (Enum) the type of event (pressed, held etc.)
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

--- (Enum) valid `mode` attributes for <Param> nodes
PARAM_MODE = {
  "abs",              -- absolute value (the default, will accept floating point values)
  "abs_7",            -- 7 bit absolute value (quantize to 7 bit range before output)
  "abs_14",           -- 14 bit absolute value

  "rel_7_signed",     -- 7 bit relative signed value 
                      -- Increase at [065 - 127], decrease at [001 - 063]

  "rel_7_signed2",    -- 7 bit relative signed value 
                      -- Increase at [001 - 063], decrease at [065 - 127]
                      -- (known as "Relative 3" in the Behringer B-Control series)

  "rel_7_offset",     -- 7 bit relative value        
                      -- Increase at [065 - 127], decrease at [063 - 000]
                      -- (known as "Relative 2" in the Behringer B-Control series)

  "rel_7_twos_comp",  -- 7 bit relative value        
                      -- Increase at [001 - 64],  decrease at [127 - 065]
                      -- (known as "Relative 1" in the Behringer B-Control series)

  "rel_14_msb",       -- 14 bit relative value 
                      -- CC: increase at [0x01 - 0x7F] when MSB is 0x00, decrease at [0x7F - 0x01] when MSB is 0x7F
                      -- NRPN: increase at [0x01 - 0x7F] when MSB is 0x00, decrease at [0x01 - 0x7F] when MSB is 0x40
                      -- (known as "Relative 1" in the Behringer B-Control series)

  "rel_14_offset",    -- 14 bit relative value 
                      -- CC: increase at [0x01 - 0x7F] when MSB is 0x40, decrease at [0x7F - 0x01] when MSB is 0x3F
                      -- NRPN: increase at [0x01 - 0x7F] when MSB is 0x40, decrease at [0x7F - 0x00] when MSB is 0x3F 
                      -- (known as "Relative 2" in the Behringer B-Control series)

  "rel_14_twos_comp"  -- 14 bit relative value 
                      -- CC: increase at [0x01 - 0x7F] when MSB is 0x00, decrease at [0x01 - 0x7F] when MSB is 0x40
                      -- NRPN: increase at [0x01 - 0x7F] when MSB is 0x00, decrease at [0x7F - 0x00] when MSB is 0x7F 
                      -- (known as "Relative 3" in the Behringer B-Control series)
}

--- (Enum) valid `type` attributes for <Param> nodes
INPUT_TYPE = {
  "button",           -- standard bidirectional button which output a value on press and release, 
                      -- but does not control it's internal state

  "togglebutton",     -- bidirectional button which toggles the state internally -  
                      -- this type of control does not support release and hold events 
                      -- (examples are buttons on the BCF/BCR controller)

  "pushbutton",       -- bidirectional button which will output values on press and release 
                      -- while controlling it's state internally. Some examples are 
                      -- Automap "momentary" buttons, or TouchOSC pushbuttons

  "fader",            -- manual fader
  "dial",             -- basic rotary encoder 
  "xypad",            -- XY pad 
  "keyboard",         -- keyboard
  "key",              -- key (drum-pad)
  "label",            -- text display
}

--------------------------------------------------------------------------------
-- helper functions
--------------------------------------------------------------------------------

-- pack arguments into table

function pack_args(...)
  return (#arg >0) and arg or nil
end


--- split_filename
-- TODO use cLib/cFileSystem methods

function split_filename(filename)
  local _, _, name, extension = filename:find("(.+)%.(.+)$")

  if (name ~= nil) then
    return name, extension
  else
    return filename 
  end
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


--- check if colorspace is monochromatic
function is_monochrome(colorspace)
  if table.is_empty(colorspace) then
    return true
  end
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


