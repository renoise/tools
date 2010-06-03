-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- global definitions
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

NUM_OCTAVES = 9
NUM_NOTES = 12

track_index = 1
tone_matrix_dialog = nil
arpeg_option_dialog = nil
pseq_warn_dialog = nil
tone_mode = 1
first_show = false
max_note_columns = 1
column_offset = 1 

--Gui object definitions
obj_textlabel = 1
obj_button = 2 
obj_checkbox = 3
obj_switch = 4 
obj_popup = 5 
obj_chooser = 6 
obj_valuebox = 7 
obj_slider = 8 
obj_minislider = 9 
obj_textfield = 10 

--Instrument properties
process_instrument_index = 1
process_instruments = {}
instrument_insertion_index = 1
instrument_index = 1
pinstruments_field = "example: 00,01,02,03,0x0a,0x0b,12,13"
instruments_pool_empty = 0
ins_pointer = 1
repeat_se_instrument = false

--Velocity properties
process_velocity = {}
velocity_insertion_index = 1  --top-down
velocity_index = 128
process_velocity_index = 1
pvelocity_field = "example: 10,20,128 or 0x10,0x7f, also fx values are granted!"
velocity_pool_empty = 0
vel_pointer = 1
repeat_se_velocity = false

--Octave pointers
popup_octave_index = 1
octave_pointer = 1
repeat_se_octave = true
--custom_octave_field = "0,1,2,3,4,5,6,7,8,9"

--Note positions and pointers and processing method
popup_note_index = 1
note_pointer = 1
new_note_pos = 1
repeat_se_note = false
custom_note_field = "example: C-4,F-5,A#6,G-7"

--Distance between notes
distance_step = 1
popup_distance_mode_index = 1

--Note off positions
note_off_pos = 0
place_note_off = {}

--Distance between notes
NOTE_DISTANCE_LINES = 1
NOTE_DISTANCE_DELAY = 2
termination_step = NOTE_DISTANCE_LINES

--Distance from note to note-off
NOTE_OFF_DISTANCE_LINES = 1
NOTE_OFF_DISTANCE_TICKS = 2
termination_index = NOTE_OFF_DISTANCE_LINES

--Custom line positions
custom_note_pos = {}
custom_arpeggiator_field = "example: 0,2,5,7,9,11,nt OR 1,3,5,bn"
custom_index = 1

--Pattern pointers
previous_pattern = 0
prev_pat_size = 0
cur_pat_size = 0

--Generic option checkbox states
skip_fx = false
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

--Note-columns options
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
   [7]=6,[8]=7,[9]=8
}

note_states = {}
octave_states = {}



--[[----------------Helper functions-----------------------------]]

function randomize(tstart, tend)
   local number = tostring(os.clock())
   if string.find(number,"%.") ~= nil then
      number = string.sub(number, string.find(number,"%.")+1)
   end
   math.randomseed( tonumber(number))
   number  = number + math.random(1, 7)
   math.randomseed( tonumber(number))
   math.random(tstart, tend); math.random(tstart, tend); math.random(tstart, tend)
   local result = math.random(tstart, tend)
   return result
end


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
