--[[----------------------------------------------------------------------------
-- Duplex.Globals
----------------------------------------------------------------------------]]--

-- internal Duplex consts

MODULE_PATH = "./Duplex/"  
NOTE_ARRAY = { "C-","C#","D-","D#","E-","F-","F#","G-","G#","A-","A#","B-" }

DEVICE_OSC_PROTOCOL = 0
DEVICE_MIDI_PROTOCOL = 1

MIDI_CC_MESSAGE = 6
MIDI_NOTE_MESSAGE = 7
OSC_MESSAGE = 8

--  button event
DEVICE_EVENT_BUTTON_PRESSED = 10  
--  button event
DEVICE_EVENT_BUTTON_RELEASED = 11  
--  slider, encoder event
DEVICE_EVENT_VALUE_CHANGED = 12    

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

MUTE_STATE_OFF = 2
MUTE_STATE_ACTIVE = 1


--------------------------------------------------------------------------------
-- helper functions
--------------------------------------------------------------------------------

-- compare:
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


-- deepcopy

function deepcopy(object)
  local lookup_table = {}

  local function _copy(object)
    if type(object) ~= "table" then
      return object
    elseif lookup_table[object] then
      return lookup_table[object]
    end
    
    local new_table = {}
    lookup_table[object] = new_table
    
    for index, value in pairs(object) do
      new_table[_copy(index)] = _copy(value)
    end
    
    return setmetatable(new_table, getmetatable(object))
  end
  
  return _copy(object)
end

