--[[============================================================================
globals.lua
============================================================================]]--

--require "remdebug.engine"
TOOL_TITLE = "Epic Arpeggiator V3.0 RC2"
--Renoise internal boundary constants
NUM_OCTAVES = 10         --:0 to 9   = 10
NUM_NOTES = 12

MAX_PATTERN_LINES = 511  --:0 to 511 = 512
MAX_TICKS = 15           --:0 to 15  = 16
MAX_DELAY_STEPS = 255    --:0 to 255 = 256
MAX_NOTE_COLUMNS = 12
MAX_EFFECT_COLUMNS = 8
EMPTY = 255              -- value to clear Instrument, Panning, volume and delay column
EMPTY_NOTE = 121
TRACK_TYPE_GROUP = 4

--Initialization
track_index = 1
tone_matrix_dialog = nil
arpeg_option_dialog = nil
pseq_warn_dialog = nil
tone_mode = 1
first_show = false

--Gui object definitions
DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
SECTION_MARGIN = 1
TOOL_FRAME_WIDTH = 472
CHECKBOX_WIDTH = 30
TEXT_ROW_WIDTH = 80
ea_gui = nil
undo_gui = nil
tool_dialog = nil
change_from_tool = false

--------------------------------------------------
-- Pattern arpeggiator options

--Instrument properties
process_instrument_index = 1
process_instruments = {}
instrument_insertion_index = 1
instrument_index = 1
pinstruments_field = "example: 00,01,02,03,0x0a,0x0b,12,13"
instruments_pool_empty = 0
ins_pointer = 1
repeat_se_instrument = false
instrument_pool = {} --For randomisation

--Velocity properties
process_velocity = {}
velocity_insertion_index = 1  --top-down
velocity_index = 128
process_velocity_index = 1
pvelocity_field = "example: 10,20,128 or 0x10,0x7f, also fx values are granted!"
velocity_pool_empty = 0
vel_pointer = 1
repeat_se_velocity = false
velocity_pool = {} --For randomisation

--Octave pointers
popup_octave_index = 1
octave_pointer = 1
repeat_se_octave = true
--custom_octave_field = "0,1,2,3,4,5,6,7,8,9"
octave_pool = {} --For randomisation

--Note positions and pointers and processing method
popup_note_index = 1
note_pointer = 1
new_note_pos = 1
repeat_se_note = false
custom_note_field = "example: C-4,F-5,A#6,G-7"
note_pool = {} --For randomisation
noteoct_pool = {} --For special randomisation.

--Note off positions
note_off_pos = 0
place_note_off = {}
note_off_distance = 0

--Distance between notes
NOTE_DISTANCE_LINES = 1
NOTE_DISTANCE_DELAY = 2
distance_step = 1
popup_distance_mode_index = NOTE_DISTANCE_LINES

--Distance from note to note-off
NOTE_OFF_DISTANCE_LINES = 1
NOTE_OFF_DISTANCE_TICKS = 2
termination_index = NOTE_OFF_DISTANCE_LINES
termination_step = NOTE_DISTANCE_LINES

reset_new_note = {}

--Custom line positions
custom_note_pos = {}
binary_note_table = {}
custom_arpeggiator_field = "example: 0,2,5,7,9,11,nt OR 1,3,5,bn OR 0,1,0,1,0,0,1,1,bn"
custom_index = 1
binary_custom_note = false

--Pattern pointers
previous_pattern = 0
prev_pat_size = 0
cur_pat_size = 0

--Generic option checkbox states
skip_fx = false
overwrite_alias = false
clear_track = true
auto_play_pattern = false

--Distance, random or custom line pattern
ARPEGGIO_PATTERN_DISTANCE = 1
ARPEGGIO_PATTERN_RANDOM = 2
ARPEGGIO_PATTERN_CUSTOM = 3
switch_arp_pattern_index = ARPEGGIO_PATTERN_DISTANCE

--Matrix or custom note-pattern
NOTE_PATTERN_MATRIX = 1
NOTE_PATTERN_CUSTOM = 2
switch_note_pattern_index = NOTE_PATTERN_MATRIX

--Note-columns options to set for the current selected track
track_index = 1
max_note_columns = 1
column_offset = 1 
chord_mode = false
next_column = column_offset

--Note order definitions
PLACE_TOP_DOWN = 1
PLACE_DOWN_TOP = 2
PLACE_TOP_DOWN_TOP = 3
PLACE_DOWN_TOP_DOWN = 4
PLACE_RANDOM = 5


--Selection, pattern or song
OPTION_SELECTION_IN_TRACK = 1
OPTION_TRACK_IN_PATTERN = 2
OPTION_TRACK_IN_SONG = 3
OPTION_COLUMN_IN_PATTERN = 4
OPTION_COLUMN_IN_SONG = 5
area_to_process = OPTION_TRACK_IN_PATTERN


--Error bits
custom_error_flag = false

--Note-matrix attributes
note_matrix = {
   [1]='C', [2]='C#', [3]='D', [4]='D#', [5]='E', [6]='F',
   [7]='F#', [8]='G', [9]='G#', [10]='A', [11]='A#', [12]='B'
}
octave_matrix = {
   [1]=0,[2]=1,[3]=2,[4]=3,[5]=4,[6]=5,
   [7]=6,[8]=7,[9]=8,[10]=9
}

note_states = {}
octave_states = {}

--  initialization

for i = 1, NUM_OCTAVES * NUM_NOTES do
   note_states[i] = false
end

--------------------------------------------------
-- Envelope arpeggiator options
--------------------------------------------------
preset_area_height = 52
preset_options_height = 190
preset_version = "3.15"

processing_instrument = 1
note_scheme_size  = -1
vol_scheme_size  = -1
pan_scheme_size  = -1
cut_scheme_size = -1
res_scheme_size = -1

EMPTY_CELL = 9999
NOTE_OFF = 2555
NOTE_SCHEME_TERMINATION = 2222
VOL_PAN_TERMINATION = 256
MINIMUM_FRAME_LENGTH = 5
MAXIMUM_FRAME_LENGTH = 1000

CURSOR_POS_COLOR = {0x80,0x80,0x80}
CURSOR_POS_EDIT_COLOR = {0xff,0x00,0x00}
COLOR_UNSELECTED = {0x01,0x00,0x00}
COLOR_THEME = {0x00,0x00,0x00}
LOOP_START_COLOR = {0x00,0x84,0x0c}
LOOP_END_COLOR = {0x00,0x1d,0xff}
SUSTAIN_COLOR = {0xff,0xff,0xff}

IMAGE_UNTOGGLED_MODE = 'body_color'
IMAGE_TOGGLED_MODE = 'button_color'

ENV_NOTE_COLUMN = 1
ENV_VOL_COLUMN = 2
ENV_PAN_COLUMN = 3 
ENV_CUT = 4
ENV_RES = 5
ROW_HEIGHT = 12

ARP_MODE_OFF = 1
ARP_MODE_AUTO = 2
ARP_MODE_MANUAL = 3

FREQ_TYPE_LINES = 1
FREQ_TYPE_POINTS = 2
FREQ_TYPE_FREEFORM = 3

ENV_TYPE_POINTS = 1
ENV_TYPE_LINEAIR = 2
ENV_TYPE_CURVE = 3

ENV_LOOP_OFF = 1
ENV_LOOP_FORWARD = 2
ENV_LOOP_BACKWARD = 3
ENV_LOOP_PINGPONG = 4

LOOP_START = 1
LOOP_END = 2
ENV_LOOP_TYPE = {'off','>>', '<<', '><'}

env_current_line ={}
env_current_line.col = ENV_NOTE_COLUMN
env_current_line.row = 0

loop_pos_color = {}
note_pos_color = {}
vol_pos_color = {}
pan_pos_color = {}
line_position_offset = 0
visible_lines = 15
env_pattern_line = {}
note_pos_color[env_current_line.row]= CURSOR_POS_COLOR
envelope_volume_toggle = false
envelope_panning_toggle = false


env_note_value = {}
env_pitch_scheme = ''
note_point_scheme = ''
note_freq_val = 0
note_freq_type = FREQ_TYPE_FREEFORM
env_pitch_type = ENV_TYPE_POINTS --should be fetched from envelope!
auto_note_loop = ARP_MODE_OFF
note_loop_type = 1
note_loop_start = -1
note_loop_end = -1
note_sustain = -1
note_lfo_data = false
note_lfo1_type = 1
note_lfo1_phase = 0
note_lfo1_freq = 1
note_lfo1_amount = 16
note_lfo2_type = 1
note_lfo2_phase = 0
note_lfo2_freq = 1
note_lfo2_amount = 16


env_vol_value = {}
env_vol_scheme = ''
volume_point_scheme = ''
vol_freq_val = 0
vol_freq_type = FREQ_TYPE_FREEFORM
env_volume_type = ENV_TYPE_POINTS --should be fetched from envelope!
auto_vol_loop = ARP_MODE_OFF --Autoloop support yes/no?
vol_loop_type = 1 --The type of loop from the drop down
vol_loop_start = -1
vol_loop_end = -1
vol_sustain = -1
vol_release = -1
vol_assist_low_val = 0
vol_assist_high_val = 100
vol_assist_high_size = 0
vol_pulse_mode = ARP_MODE_OFF
vol_lfo_data = false
vol_lfo1_type = 1
vol_lfo1_phase = 0
vol_lfo1_freq = 1
vol_lfo1_amount = 16
vol_lfo2_type = 1
vol_lfo2_phase = 0
vol_lfo2_freq = 1
vol_lfo2_amount = 16


env_pan_value = {}
env_pan_scheme = ''
panning_point_scheme = ''
pan_freq_val = 0
pan_freq_type = FREQ_TYPE_FREEFORM
env_panning_type = ENV_TYPE_POINTS --should be fetched from envelope!
auto_pan_loop = ARP_MODE_OFF --Autoloop support yes/no?
pan_loop_type = 1 --The type of loop from the drop down
pan_loop_start = -1
pan_loop_end = -1
pan_sustain = -1
pan_assist_first_val = 0
pan_assist_next_val = 0
pan_assist_first_size = 0
pan_pulse_mode = ARP_MODE_OFF
pan_lfo_data = false
pan_lfo1_type = 1
pan_lfo1_phase = 0
pan_lfo1_freq = 1
pan_lfo1_amount = 16
pan_lfo2_type = 1
pan_lfo2_phase = 0
pan_lfo2_freq = 1
pan_lfo2_amount = 16

cutoff_data = false
cutoff_enabled = false
env_cut_value = {}
env_cut_scheme = ''
cutoff_point_scheme = ''
env_cutoff_type = ENV_TYPE_CURVE
cut_loop_type = 1
cut_loop_start = -1
cut_loop_end = -1
cut_sustain  = -1
cut_lfo_data = false
cut_lfo_type = 1
cut_lfo_phase = 0
cut_lfo_freq = 1
cut_lfo_amount = 16
cut_follow = 2
cut_follow_attack = 0
cut_follow_release = 0
cut_follow_amount = 0


resonance_data = false
resonance_enabled = false
env_res_value = {}
env_res_scheme = ''
resonance_point_scheme = ''
resonance_filter_type = 1
env_resonance_type = ENV_TYPE_CURVE
res_loop_type = 1
res_loop_start = -1
res_loop_end = -1
res_sustain  = -1
res_lfo_data = false
res_lfo_type = 1
res_lfo_phase = 0
res_lfo_freq = 1
res_lfo_amount = 16
res_follow = 2
res_follow_attack = 0
res_follow_release = 0
res_follow_amount = 0

cutres_filter_type = 1

note_mode = true --Show notes or figures in the column?


PLAY_MODE_POINTS = 1
ENV_X1 = 1
ENV_X10 = 2
ENV_X100 = 3
TONE = 0.5/1200
pitch_table = {}

tone_factor = ENV_X1
tone_scope_low = -1200
tone_scope_high = 1200
skip_tone_scope_low = false
skip_tone_scope_high = false
skip_tone_scope_slider = false
tone_scope_offset = -12
tone_scope_correction = -12
transpose_pitch_scheme = false
catched_midi_note = -1

env_multiplier = ENV_X100

env_sync_mode = false
--env_free_sync_mode = false

env_auto_apply = false
construct = true  --Execute the construct function by default

change_from_renoise = nil

area_to_fetch = OPTION_COLUMN_IN_PATTERN
columns_to_fetch = 1
note_chord_spacing = 1  --When fetching chords from the pattern editor, 
                        --This spacing sets the amount of points between two notes

JUMP_FORWARD = 1
JUMP_BACKWARD = -1
JUMP_RIGHT = 2
JUMP_LEFT = -2

--------------------------------------------------
-- Generic options


--Keyboard modifier keystates
LCMD = 1
LCAP = 2
LALT = 4
RCMD = 8
RCAP = 16
RALT = 32

key_state = 0
key_state_time_out = 0

figure_pos = 1


--Tab atrributes
TOP_TABS = 1
SUB_TABS = 2
pat_tabs_bound = 5
env_tabs_bound = 3
top_tabs_bound = 3
sub_tabs_bound = pat_tabs_bound

tab_states = {}
tab_states.top = 1
tab_states.sub = 1

--toggle button attributes
BUTTON_SELECTED = {0xff, 0xb6, 0x00}
BUTTON_DESELECTED = {0x2d, 0x11, 0xff}
bool_button = {}
bool_button[true] = BUTTON_SELECTED
bool_button[false] = BUTTON_DESELECTED

pat_toggle_states = {}
env_toggle_states = {}

--Application options
LAYOUT_FULL = 1
LAYOUT_TABS = 2
LAYOUT_CUSTOM = 3

preferences = renoise.Document.create("preferences") {
  master_device = 1,
  master_channel = 0,
  layout=LAYOUT_FULL
}
for _ = 1, sub_tabs_bound do
  if preferences['pat_toggle_'..tostring(_)] == nil then
    preferences:add_property('pat_toggle_'..tostring(_), false)
  end
end

for _ = 1, env_tabs_bound do
  if preferences['env_toggle_'..tostring(_)] == nil then
    preferences:add_property('env_toggle_'..tostring(_), false)
  end
end

if preferences['row_frequency_step'] == nil then
  preferences:add_property('row_frequency_step',FREQ_TYPE_LINES)
end

if preferences['opt_visible_lines'] == nil then
  preferences:add_property('opt_visible_lines',15)
end

if preferences['enable_undo'] == nil then
  preferences:add_property('enable_undo',true)
end

renoise.tool().preferences = preferences
visible_lines = preferences.opt_visible_lines.value
--print(preferences.opt_visible_lines.value)

row_frequency_step = tonumber(preferences.row_frequency_step.value)
row_frequency_size = 1
row_frequency_text = {'lines','pnts'}

gui_layout_option = preferences.layout.value
for _ = 1,sub_tabs_bound do
  pat_toggle_states[_] = preferences['pat_toggle_'..tostring(_)].value
end

for _ = 1,env_tabs_bound do
  env_toggle_states[_] = preferences['env_toggle_'..tostring(_)].value
end

MIDI_RECORDING = {0xff, 0x00, 0x00}
MIDI_MUTED = {0x2d, 0x11, 0xff}

midi_record_mode = false
midi_record_color = MIDI_MUTED

NO_DEVICE = "None"
opened_device = nil
device_list = {}
selected_device = preferences.master_device.value
selected_channel = preferences.master_channel.value
channels = {}
midi_notes = {}
for _ = 1, 16 do
  channels[143+_] = _
end

local mnote = 1
local moctave = 0
for _ = 0,119 do
  if string.find(note_matrix[mnote],'#') == nil then
    midi_notes[_] = note_matrix[mnote]..'-'..tostring(moctave)
  else
    midi_notes[_] = note_matrix[mnote]..tostring(moctave)
  end
  mnote = mnote + 1
  if mnote == 13 then
    moctave = moctave + 1
    mnote = 1
  end
end


--Key_handler tables
key_matrix = {
   [1]='C_', [2]='Cf', [3]='D_', [4]='Df', [5]='E_', [6]='F_',
   [7]='Ff', [8]='G_', [9]='Gf', [10]='A_', [11]='Af', [12]='B_'
}

--Preset manager
PATH_SEPARATOR = "/"
PATTERN = 1
ENVELOPE = 2
ENVELOPE_UNDO = 3
undo_preset_table = {}
undo_descriptions = {}
last_undo_preset = nil
undo_dialog = nil
grace_turn = 0 --This value is used for allowing to undo the tone-scope slider setting
               --and prevent the routine from choking on endless undo requests.
               --See the idle notifier on how the initial value set 
               --in the gui_envelope_arp is treated.
grace_wait = 0 
no_undo = false
enable_undo = true



if (os.platform() == "WINDOWS") then
  PATH_SEPARATOR = "\\"
end

preset_conversion_mode = false
pat_preset_field = nil
pat_preset_file = nil
pat_preset_list = {}
pat_preset_table = {
  "Scheme", "NoteMatrix","NoteProfile","Distance","DistanceMode",
  "OctaveRotation","OctaveRepeat","Termination","TerminationMode",
  "NoteRotation","NoteRepeat","ArpeggioPattern","CustomPattern",
  "NoteColumns", "ChordMode","InstrumentPool","InstrumentRotation",
  "InstrumentRepeat","VolumePool", "VolumeRotation", "VolumeRepeat"
  }
env_preset_field = nil
env_preset_file = nil
env_preset_list = {}
env_preset_table = {
  "Scheme", "PointSequences", "Frequency","FrequencyMode", "LoopMode",
  
  "NoteDrawType","NoteScheme","NotePointSequences","NoteSchemeSize",
  "NoteFrequency","NoteFrequencyMode","NoteLoopMode",
  "NoteLoopType","NoteLoopStart","NoteLoopEnd","NoteSustain",
  "NoteLFOApply",
  "NoteLFO1","NoteLFOPhase1","NoteLFOFrequency1", "NoteLFOAmount1",
  "NoteLFO2","NoteLFOPhase2","NoteLFOFrequency2", "NoteLFOAmount2",

  "ToneFactor","Transpose","TransposeLink","LoopAssistance",
  
  "VolumeScheme","VolumePointSequences","VolumeSchemeSize","VolumeDrawType",
  "VolumeFrequency","VolumeFrequencyMode","VolumeApply","VolumeLoopMode",
  "VolumeLoopType","VolumeLoopStart","VolumeLoopEnd","VolumeSustain",
  "VolumePulseMode","VolumeHighValue","VolumeLowValue",
  "VolumeHighSize","VolumeRelease",
  "VolumeLFOApply",
  "VolumeLFO1","VolumeLFOPhase1","VolumeLFOFrequency1", "VolumeLFOAmount1",
  "VolumeLFO2","VolumeLFOPhase2","VolumeLFOFrequency2", "VolumeLFOAmount2",
  
  "PanningScheme","PanningPointSequences","PanningSchemeSize","PanningDrawType",
  "PanningFrequency","PanningFrequencyMode","PanningApply","PanningLoopMode",
  "PanningLoopType","PanningLoopStart","PanningLoopEnd","PanningSustain",
  "PanningPulseMode","PanningFirstValue","PanningNextValue",
  "PanningFirstSize",
  "PanningLFOApply",
  "PanningLFO1","PanningLFOPhase1","PanningLFOFrequency1", "PanningLFOAmount1",
  "PanningLFO2","PanningLFOPhase2","PanningLFOFrequency2", "PanningLFOAmount2",

  "CutoffApply","CutoffScheme","CutoffPointSequences","CutoffSchemeSize",
  "CutoffDrawType","CutoffEnabled",
  "CutoffLoopType","CutoffLoopStart","CutoffLoopEnd","CutoffSustain",
  "CutoffLFOApply",
  "CutoffLFO","CutoffLFOPhase","CutoffLFOFrequency", "CutoffLFOAmount",
  "CutoffFollower","CutoffFollowerAttack","CutoffFollowerRelease", "CutoffFollowerAmount",

  "ResonanceApply","ResonanceScheme","ResonancePointSequences","ResonanceSchemeSize",
  "ResonanceDrawType","ResonanceEnabled",
  "ResonanceLoopType","ResonanceLoopStart","ResonanceLoopEnd","ResonanceSustain",
  "ResonanceLFOApply",
  "ResonanceLFO","ResonanceLFOPhase","ResonanceLFOFrequency", "ResonanceLFOAmount",
  "ResonanceFollower","ResonanceFollowerAttack","ResonanceFollowerRelease", "ResonanceFollowerAmount",

  "CutResFilterType",
  }

--------------------------------------------------------------------------------
-- helper functions
--------------------------------------------------------------------------------

function randomize(tstart, tend, buffer, compare)
  local number = tostring(os.clock())
  local approved = false
  if tstart == 0 then
    tstart = 1
  end
  if tend < tstart then
    tend = tstart
  end
  if string.find(number,"%.") ~= nil then
    number = string.sub(number, string.find(number,"%.")+1)
  end
  
  math.randomseed( tonumber(number))
   number  = number + math.random(1, 30)
   math.randomseed( tonumber(number))
   math.random(tstart, tend); math.random(tstart, tend); math.random(tstart, tend)
  local result = math.random(tstart, tend)
  return result
end

--------------------------------------------------------------------------------

function math.round(value)
  local floor_val = math.floor(value)
  local float = value - floor_val
  if float < 0.5 then 
    return math.floor(value)
  else
    return math.ceil(value)
  end
end

--------------------------------------------------------------------------------

string.split = function(str, pattern)
  pattern = pattern or "[^%s]+"

  if pattern:len() == 0 then pattern = "[^%s]+" end

  local parts = {__index = table.insert}
  setmetatable(parts, parts)
  str:gsub(pattern, parts)
  setmetatable(parts, nil)
  parts.__index = nil
  return parts
end

--------------------------------------------------------------------------------

function get_tools_root()    
  local dir = renoise.tool().bundle_path
  return dir:sub(1,dir:find("Tools")+5)      
end

--------------------------------------------------------------------------------

function toboolean(value)
  if string.lower(tostring(value)) == "false" or tonumber(value) == 0 then
    return false
  end
  
  return true
end

--------------------------------------------------------------------------------

table.serialize = function(table, separator)
  local stream = nil
  for _ = 1, #table do
    if stream == nil then
      stream = table[_]
    else
      stream = stream .. separator.. table[_]
    end
  end
  return stream  
end

--------------------------------------------------------------------------------

function get_device_index()
  local inputs = renoise.Midi.available_input_devices()
  local device_table = {}

  for t=1,#inputs+1 do
     device_list[t] = inputs[t]
    if t==1 then
      device_list[t] = "None"
    else
      device_list[t] = inputs[(t-1)]      
    end
  end
--  devices[#devices+1] = "Renoise OSC Device"  --Doesn't work yet
  
  if (#device_table>1) then
  end

end



