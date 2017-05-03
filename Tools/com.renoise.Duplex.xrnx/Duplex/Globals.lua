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
HARMONIC_SCALES = {
  ["None"] =                { index=1, keys={1,1,1,1,1,1,1,1,1,1,1,1}, count=12, },
  ["Natural Major"] =       { index=2, keys={1,0,1,0,1,1,0,1,0,1,0,1}, count=7,  },
  ["Natural Minor"] =       { index=3, keys={1,0,1,1,0,1,0,1,1,0,1,0}, count=7,  },
  ["Pentatonic Major"] =    { index=4, keys={1,0,1,0,1,0,0,1,0,1,0,0}, count=5,  },
  ["Pentatonic Minor"] =    { index=5, keys={1,0,0,1,0,1,0,1,0,0,1,0}, count=5,  },
  ["Egyptian Pentatonic"] = { index=6, keys={1,0,1,0,0,1,0,1,0,0,1,0}, count=5,  }, -- obsolete since API v5
  ["Pentatonic Egyptian"] = { index=6, keys={1,0,1,0,0,1,0,1,0,0,1,0}, count=5,  }, 
  ["Blues Major"] =         { index=7, keys={1,0,1,1,1,0,0,1,0,1,0,0}, count=6,  },
  ["Blues Minor"] =         { index=8, keys={1,0,0,1,0,1,1,1,0,0,1,0}, count=6,  },
  ["Whole Tone"] =          { index=9, keys={1,0,1,0,1,0,1,0,1,0,1,0}, count=6,  },
  ["Augmented"] =           { index=10, keys={1,0,0,1,1,0,0,1,1,0,0,1}, count=6,  },
  ["Prometheus"] =          { index=11, keys={1,0,1,0,1,0,1,0,0,1,1,0}, count=6,  },
  ["Tritone"] =             { index=12, keys={1,1,0,0,1,0,1,1,0,0,1,0}, count=6,  },
  ["Harmonic Major"] =      { index=13, keys={1,0,1,0,1,1,0,1,1,0,0,1}, count=7,  },
  ["Harmonic Minor"] =      { index=14, keys={1,0,1,1,0,1,0,1,1,0,0,1}, count=7,  },
  ["Melodic Minor"] =       { index=15, keys={1,0,1,1,0,1,0,1,0,1,0,1}, count=7,  },
  ["All Minor"] =           { index=16, keys={1,0,1,1,0,1,0,1,1,1,1,1}, count=9,  },
  ["Dorian"] =              { index=17, keys={1,0,1,1,0,1,0,1,0,1,1,0}, count=7,  },
  ["Phrygian"] =            { index=18, keys={1,1,0,1,0,1,0,1,1,0,1,0}, count=7,  },
  ["Phrygian Dominant"] =   { index=19, keys={1,1,0,0,1,1,0,1,1,0,1,0}, count=7,  },
  ["Lydian"] =              { index=20, keys={1,0,1,0,1,0,1,1,0,1,0,1}, count=7,  },
  ["Lydian Augmented"] =    { index=21, keys={1,0,1,0,1,0,1,0,1,1,0,1}, count=7,  },
  ["Mixolydian"] =          { index=22, keys={1,0,1,0,1,1,0,1,0,1,1,0}, count=7,  },
  ["Locrian"] =             { index=23, keys={1,1,0,1,0,1,1,0,1,0,1,0}, count=7,  },
  ["Locrian Major"] =       { index=24, keys={1,0,1,0,1,1,1,0,1,0,1,0}, count=7,  },
  ["Super Locrian"] =       { index=25, keys={1,1,0,1,1,0,1,0,1,0,1,0}, count=7,  },
  ["Major Neapolitan"] =    { index=26, keys={1,1,0,1,0,1,0,1,0,1,0,1}, count=7,  }, -- obsolete since API v5
  ["Minor Neapolitan"] =    { index=27, keys={1,1,0,1,0,1,0,1,1,0,0,1}, count=7,  }, -- obsolete since API v5
  ["Neapolitan Minor"] =    { index=27, keys={1,1,0,1,0,1,0,1,1,0,0,1}, count=7,  },
  ["Romanian Minor"] =      { index=28, keys={1,0,1,1,0,0,1,1,0,1,1,0}, count=7,  },
  ["Spanish Gypsy"] =       { index=29, keys={1,1,0,0,1,1,0,1,1,0,0,1}, count=7,  },
  ["Hungarian Gypsy"] =     { index=30, keys={1,0,1,1,0,0,1,1,1,0,0,1}, count=7,  },
  ["Enigmatic"] =           { index=31, keys={1,1,0,0,1,0,1,0,1,0,1,1}, count=7,  },
  ["Overtone"] =            { index=32, keys={1,0,1,0,1,0,1,1,0,1,1,0}, count=7,  },
  ["Diminished Half"] =     { index=33, keys={1,1,0,1,1,0,1,1,0,1,1,0}, count=8,  },
  ["Diminished Whole"] =    { index=34, keys={1,0,1,1,0,1,1,0,1,1,0,1}, count=8,  },
  ["Spanish Eight-Tone"] =  { index=35, keys={1,1,0,1,1,1,1,0,1,0,1,0}, count=8,  },
  ["Nine-Tone Scale"] =     { index=36, keys={1,0,1,1,1,0,1,1,1,1,0,1}, count=9,  },
}

if (renoise.API_VERSION > 4) then
  HARMONIC_SCALES["Pentatonic Egyptian"] = table.rcopy(HARMONIC_SCALES["Egyptian Pentatonic"])  
  HARMONIC_SCALES["Neapolitan Major"] = table.rcopy(HARMONIC_SCALES["Major Neapolitan"])  
  HARMONIC_SCALES["Neapolitan Minor"] = table.rcopy(HARMONIC_SCALES["Minor Neapolitan"])  
  HARMONIC_SCALES["Egyptian Pentatonic"] = nil
  HARMONIC_SCALES["Major Neapolitan"] = nil
  HARMONIC_SCALES["Minor Neapolitan"] = nil
end

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
  return (table.concat(t1,",")==table.concat(t2,","))
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

-- pack arguments into table

function pack_args(...)
  return (#arg >0) and arg or nil
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


