
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- manifest
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

manifest = {}
manifest.api_version = 0.2
manifest.author = "Vincent Voois [ http://tinyurl.com/vvrns ]"
manifest.description = "Epic Arpeggiator V1.97"

manifest.notifications = {}

manifest.actions = {}
manifest.actions[#manifest.actions + 1] = {
name = "MainMenu:Tools:Epic Arpeggiator",
--name = "MainMenu:Options:Epic Arpeggiator",
description = "Design note patterns using a note matrix and powerful arpeggiator features",
invoke = function() 
   open_arp_dialog()
end
}

-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- content
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

local NUM_OCTAVES = 10
local NUM_NOTES = 12

local tone_matrix_dialog = nil
local arpeg_option_dialog = nil
local pseq_warn_dialog = nil
local tone_mode = 1
local first_show = false
local track_index = 1
local max_note_columns = 1
local column_offset = 1 

--Gui object definitions
local obj_textlabel = 1
local obj_button = 2 
local obj_checkbox = 3
local obj_switch = 4 
local obj_popup = 5 
local obj_chooser = 6 
local obj_valuebox = 7 
local obj_slider = 8 
local obj_minislider = 9 
local obj_textfield = 10 


--Instrument properties
local process_instrument_index = 1
local process_instruments = {}
local instrument_insertion_index = 1
local instrument_index = 1
local pinstruments_field = "example: 00,01,02,03,0x0a,0x0b,12,13"
local instruments_pool_empty = 0
local ins_pointer = 1
local repeat_se_instrument = false

--Velocity properties
local process_velocity = {}
local velocity_insertion_index = 1  --top-down
local velocity_index = 128
local process_velocity_index = 1
local pvelocity_field = "example: 10,20,128 or 0x10,0x7f, also fx values are granted!"
local velocity_pool_empty = 0
local vel_pointer = 1
local repeat_se_velocity = false

--Octave pointers
local popup_octave_index = 1
local octave_pointer = 1
local repeat_se_octave = true
--custom_octave_field = "0,1,2,3,4,5,6,7,8,9"

--Note positions and pointers and processing method
local popup_note_index = 1
local note_pointer = 1
local new_note_pos = 1
local repeat_se_note = false
local custom_note_field = "example: C-4,F-5,A#6,G-7"

--Distance between notes
local distance_step = 1
local popup_distance_mode_index = 1

--Note off positions
local note_off_pos = 0
local place_note_off = {}

--Distance from note to note-off
local termination_index = 1
local termination_step = 1

--Custom line positions
local custom_note_pos = {}
local custom_arpeggiator_field = "example: 0,2,5,7,9,11,nt OR 1,3,5,bn"
local custom_index = 1

--Pattern pointers
local previous_pattern = 0
local prev_pat_size = 0
local cur_pat_size = 0

--Generic option checkbox states
local skip_fx = false
local clear_track = true
local auto_play_pattern = false

--Distance, random or custom line pattern
local switch_arp_pattern_index = 1
local switch_note_pattern_index = 1

--Note-columns options
local track_index = 1
local max_note_columns = 1
local column_offset = 1 
local chord_mode = false
local next_column = column_offset


--Selection, pattern or song
local marker_area = 2

--Error bits
local custom_error_flag = false

local note_matrix = {
   [1]='C', [2]='C#', [3]='D', [4]='D#', [5]='E', [6]='F',
   [7]='F#', [8]='G', [9]='G#', [10]='A', [11]='A#', [12]='B'
}
local octave_matrix = {
   [1]=0,[2]=1,[3]=2,[4]=3,[5]=4,[6]=5,
   [7]=6,[8]=7,[9]=8,[10]=9
}

-------------------------------------------------------------------------------
-- tone matrix states
-------------------------------------------------------------------------------
local note_states = {}
local octave_states = {}
for i = 1, NUM_OCTAVES * NUM_NOTES do
   note_states[i] = false
end
function note_state(octave, note)
   return note_states[octave * NUM_NOTES + note]
end
function octave_state(octave)
   return octave_states[octave]
end
function set_note_state(octave, note, state)
   local octave_check = 0         
   note_states[octave * NUM_NOTES + note] = state
   --The following is to check if there are other notes still checked in the
   --same octave range... if so, the octave state may not be turned to false!
   for i = 1, NUM_NOTES do
      if note_states[i+(NUM_NOTES*octave)] == true then
         octave_check = octave_check +1
      end      
   end
   octave_states[octave] = state
   if octave_check > 0 then
      octave_states[octave] = true
      octave_check = 0
   end
end
--Toggle one full octave row
function toggle_octave_row(vb, oct)
   oct = oct - 1
   local checkbox = nil
   local cb = vb.views
   for note = 1, 12 do
      if string.find(note_matrix[note], "#") then
         checkbox = note_matrix[note-1].."f"..tostring(oct)
      else
         checkbox = note_matrix[note].."_"..tostring(oct)
      end
      --to invert the checkbox state instead, remove the marked condition lines
      if cb[checkbox].value == false then
         cb[checkbox].value = true 
      else
         cb[checkbox].value = false
      end
   end
end

--Toggle one full note row
function toggle_note_row(vb, note)
   local checkbox = nil
   local cb = vb.views
   for oct = 0, 9 do
      if string.find(note_matrix[note], "#") then
         checkbox = note_matrix[note-1].."f"..tostring(oct)
      else
         checkbox = note_matrix[note].."_"..tostring(oct)
      end
      --to invert the checkbox state instead, remove the marked condition lines
      if cb[checkbox].value == false then
         cb[checkbox].value = true 
      else
         cb[checkbox].value = false
      end
   end
end
function set_all_row_state(vb, btext)
   local checkbox = nil
   local cb = vb.views
   for t = 0, 9 do
      local oct = tostring(t)
      for i = 1, NUM_NOTES do
         if string.find(note_matrix[i], "#") then
            checkbox = note_matrix[i-1].."f"..oct
         else
            checkbox = note_matrix[i].."_"..oct
         end
         if btext == "off" then
            --Toggle off all checkboxes
            cb[checkbox].value = false
         else
            --invert the checkbox state
            if cb[checkbox].value == false then
               cb[checkbox].value = true
            else
               cb[checkbox].value = false
            end
         end
      end
   end
end
-------------------------------------------------------------------------------
-- Processing functions
-------------------------------------------------------------------------------
function harvest_notes_in_octave(octave)
--[[ Look which notes are set in the tone-matrix in one octave --]]
   local note_hyve = {}
   local note_count = 1
   for note = 1, NUM_NOTES do
      if note_state(octave, note) == true then
         note_hyve[note_count] = note_matrix[note]
         note_count = note_count + 1      
      end
   end
   return note_hyve
end
function add_notes(n_column, c_line, vb)
--[[ Start the processing, iterators are doing their work in this routine 
Also the note-, instrument-, velocity- and octave-schemes are generated here 
--]]
   local song = renoise.song()
   local pattern_lines = song.selected_pattern.number_of_lines
   local pattern_index = song.selected_pattern_index
   local track_index = song.selected_track_index
   local track_type = song.selected_track.type
   song.tracks[track_index].visible_note_columns = max_note_columns
   local visible_note_columns = song.tracks[track_index].visible_note_columns
   local iter, pos
   local check_condition = 0
   custom_error_flag = false
   octave_pointer = 1
   note_pointer = 1
   ins_pointer = 1
   vel_pointer = 1
   custom_index = 1
   column_offset = song.selected_note_column_index 
   next_column = column_offset
   
   if track_type ~= renoise.Track.TRACK_TYPE_MASTER and
   track_type ~= renoise.Track.TRACK_TYPE_SEND then
      --show delay column in case it is invisible      
      song.tracks[track_index].delay_column_visible = true
      if switch_note_pattern_index ==1 then
         for i = 1, NUM_OCTAVES * NUM_NOTES do
            if note_states[i] == true then
               check_condition = 1
            end
         end
         if check_condition == 0 then
            renoise.app():show_warning("Please select a desired note-range to generate in the tone-matrix")               
            return
         end
      end
      if marker_area <= 2 or marker_area == 4 then
         iter = song.pattern_iterator:lines_in_pattern_track(pattern_index, 
         track_index)
         renoise.app():show_status("Arpeggiating track / column in pattern")
      elseif marker_area == 3 or marker_area == 5 then
         iter = song.pattern_iterator:lines_in_track(track_index)
         renoise.app():show_status("Arpeggiating track / column in song")
      end
      local line_type = 0
      local onetime = 0
      local cur_line = 0
      local ocsg = 1
      local octave_order = {}
      local note_order = {}
      local ins_order = {}
      local octave_scheme = {}
      local vel_order = {}
      local delay_apply = 0
      local cut_value = termination_step
      local invalid_lines = 0
      local invalid_instruments = 0
      local invalid_octaves = 0
      local pattern_closure = 0
      place_note_off[n_column] = 0
      if switch_arp_pattern_index == 3 then
         if not string.find(custom_arpeggiator_field,"example:") then
            if custom_arpeggiator_field == '' then
               custom_arpeggiator_field = '0,nt'
               vb.views.custom_arpeggiator_profile.value = custom_arpeggiator_field 
            end
            custom_note_pos = custom_arpeggiator_field:split( "[^,%s]+" )
         else
            --Insert first default custom positions
            custom_note_pos[1] = '00' 
            custom_note_pos[2] = '02' 
            custom_note_pos[3] = '05' 
            custom_note_pos[4] = '07' 
            custom_note_pos[5] = '09' 
            custom_note_pos[6] = '11' 
            custom_note_pos[7] = 'nt' 
         end
         for i,j in ipairs(custom_note_pos) do
            if tonumber(j) == nil then
               if j == "nt" then
                  if i-1 > 0 then
                     custom_note_pos[i] = 'nt' --termination_step
                     pattern_closure = 1
                  else
                     renoise.app():show_warning("Please do not start with a termination or distance step")               
                     return
                  end 
               elseif j == "bn" then
                  if i-1 > 0 then
                     custom_note_pos[i] = 'bn' --distance_step 
                     pattern_closure = 1
                  else
                     renoise.app():show_warning("Please do not start with a termination or distance step")               
                     return
                  end 
               else
                  custom_note_pos[i] = 0
               end
            else
               if tonumber(j+1) <=pattern_lines and tonumber(j+1)> 0 then
                  custom_note_pos[i] =tonumber(j+1)
               else
                  invalid_lines = invalid_lines + 1
                  custom_note_pos[i] = 1
               end 
            end
         end
         if pattern_closure == 0 then
            custom_note_pos[#custom_note_pos+1] = 'bn'
            custom_arpeggiator_field = custom_arpeggiator_field..",bn"
            vb.views.custom_arpeggiator_profile.value = custom_arpeggiator_field 
            renoise.app():show_warning("No 'bn' or 'nt' closure used, 'bn' has been"..
            " added\nPlease check your custom pattern-line pool for typo's")               
         end
         if invalid_lines > 0 then
            renoise.app():show_warning("You have "..invalid_lines..
            " line position references in your custom pattern-line pool that exceed"..
            " pattern-size boundaries. Either raise the pattern-size or check for"..
            " comma-misplacements")               
         end
      end
      if not string.find(pvelocity_field,"example:") then
         process_velocity = pvelocity_field:split( "[^,%s]+" )
         for i,j in ipairs(process_velocity) do
            if tonumber(j) == nil then
               process_velocity[i] = 0
            else
               process_velocity[i] =tonumber(j)
            end
         end
         if #process_velocity == 0 then
            velocity_pool_empty = 1
         else
            velocity_pool_empty = 0
         end
      else
         process_velocity[1] = velocity_index
         velocity_insertion_index = 1
      end
      if not string.find(pinstruments_field,"example:") then
         process_instruments = pinstruments_field:split( "[^,%s]+" )
         for i,j in ipairs(process_instruments) do
            if tonumber(j) == nil then
               process_instruments[i] = 0
            else
               if tonumber(j)<=(#song.instruments-1) and tonumber(j)>=0 then
                  process_instruments[i] =tonumber(j)
               else
                  invalid_instruments = invalid_instruments + 1
                  process_instruments[i] = #song.instruments-1
               end 
            end
         end
         if invalid_instruments > 0 then
            renoise.app():show_warning("You have "..invalid_instruments..
            " instrument references in your instrument pool that do not exist."..
            "\nThese have been replaced for the last existing instrument number."..
            "\nEither add those slots and load instruments or check for comma mis"..
            "placements.")               
         end
         if #process_instruments == 0 then
            instruments_pool_empty = 1
         else
            instruments_pool_empty = 0
         end
      else
         process_instruments[1] = song.selected_instrument_index - 1 
         instrument_insertion_index = 1
      end
      if termination_index == 1 then
         cut_value = 0
      end
      if custom_note_pos[1] == 0 or custom_note_pos[1] == nil and switch_arp_pattern_index == 3 then
         switch_arp_pattern_index = 1
         vb.views.switch_arp_pattern.value = 1
      end
      if instruments_pool_empty == 1 then
         --If no instrument is inserted into the instrument pool, select the 
         --current selected instrument from the instrument list.
         process_instruments[1] = song.selected_instrument_index - 1 
         instrument_insertion_index = 1
      end
      if velocity_pool_empty == 1 then
         process_velocity[1] = velocity_index
         velocity_insertion_index = 1
      end
      
      if switch_note_pattern_index ==1 then
         for z = 1,NUM_OCTAVES do
            if octave_states[z]== true then
               octave_scheme[ocsg] = z - 1
               ocsg = ocsg + 1
            end
         end
      end
      if invalid_octaves > 0 then
         renoise.app():show_warning("You have "..invalid_octaves..
         " octave references in your octave pool that are not supported."..
         "\nThese have been replaced for octave 4."..
         "\nPlease check your comma's or remove the wrong octave levels.")               
      end
      octave_order = ferris_wheel (octave_scheme, octave_order, popup_octave_index, repeat_se_octave) 
      ins_order = ferris_wheel (process_instruments, ins_order, instrument_insertion_index, repeat_se_instrument)
      vel_order = ferris_wheel (process_velocity, vel_order, velocity_insertion_index, repeat_se_velocity)
      if clear_track == true then
         clear_track_first()
      end    
      previous_pattern = 0
      local watch_new_note= 0 --if an area is marked, a new note should start
                              --from the first line in that area. not the track.
      for _,line in iter do
         cur_line = _.line
         track_index = _.track
         pattern_index = _.pattern
         cur_pat_size = song.patterns[pattern_index].number_of_lines
         if previous_pattern == 0 then
            previous_pattern = pattern_index
            if switch_arp_pattern_index ~= 3 then   
               new_note_pos = cur_line
               watch_new_note = 1
            else
               if custom_note_pos[custom_index] >= cur_line and 
               custom_index < #custom_note_pos then
                  --If the current line is smaller than the custom row index
                  --we can use the index for the current line
                  new_note_pos = custom_note_pos[custom_index]
               else
                  --However if the terminator position has been been found
                  --or the line is larger, add the position to the line
                  if custom_note_pos[custom_index] == 'nt' then
                     new_note_pos = cur_line+custom_note_pos[custom_index-1]+termination_step
                  elseif custom_note_pos[custom_index] == 'bn' then
                     new_note_pos = cur_line+custom_note_pos[custom_index-1]+distance_step
                  else
                     new_note_pos = cur_line+custom_note_pos[custom_index]
                  end
               end
               custom_index = custom_index +1
               if custom_index > #custom_note_pos then
                  custom_index = 1
               end
            end
            note_off_pos = new_note_pos + termination_step
         else
            prev_pat_size = song.patterns[previous_pattern].number_of_lines
            previous_pattern = pattern_index
            if note_off_pos > prev_pat_size then
               note_off_pos = note_off_pos - prev_pat_size
            end
         end
         for cur_column,note_column in ipairs(line.note_columns) do
         
            if marker_area == 1 and note_column.is_selected then
               if watch_new_note == 1 then
                  new_note_pos = cur_line
                  note_off_pos = new_note_pos + termination_step
                  watch_new_note = 0
               end
            end
            if cur_column <= visible_note_columns and cur_column >= column_offset then
               note_column = place_note(note_column, cur_line, octave_order, 
               ins_order, vel_order, cur_column, track_index, pattern_index)
            end
         end
      end
      if custom_error_flag == true then
         renoise.app():show_warning("Check your note profile... something is"..
         " invalid there. (no or incorrect notes, octave figures or split signs)")
      end

      if auto_play_pattern == true then
         song.transport.loop_pattern = true
         song.transport:start(1)
      end
--[[
--setting the sequencer loop range, this stuff ain't working, i've given up on this.
      if auto_play_pattern == true then
         local l_range = song.transport.loop_range
         if marker_area <= 2 or marker_area == 4 then
            if l_range[1].sequence ~= song.selected_sequence_index and 
            l_range[2] ~= song.selected_sequence_index then
               l_range[1].sequence = song.selected_sequence_index
               l_range[2].sequence = song.selected_sequence_index
               song.transport.loop_range = l_range
            end
         elseif marker_area == 3 or marker_area == 5 then
            l_range[1].sequence = 1
            l_range[2].sequence = #song.sequencer.pattern_sequence
            song.transport.loop_range = l_range
         end
         song.transport.loop_pattern = true
         song.transport:start(1)
      end
--]]
   else
      renoise.app():show_warning("Cannot insert notes in master or send-track!")
   end
end
function clear_track_first()
--[[ Clear area/track/song first --]]
   local song = renoise.song()
   local pattern_index = song.selected_pattern_index
   local track_index = song.selected_track_index
   local iter
   local visible_note_columns = song.tracks[track_index].visible_note_columns
   column_offset = song.selected_note_column_index 
   if marker_area <= 2 or marker_area == 4 then
      iter = song.pattern_iterator:
         lines_in_pattern_track(pattern_index, track_index)
      renoise.app():show_status("Clear and arpeggiate track /column in pattern")
   elseif marker_area == 3 or marker_area == 5 then
      iter = song.pattern_iterator:lines_in_track(track_index)
      renoise.app():show_status("Clear and arpeggiate track /column in song")
   end
   for _,line in iter do
      for c,note_column in ipairs(line.note_columns) do
         if c <= visible_note_columns and c >= column_offset then
            if marker_area < 4 then
               note_column:clear()
            elseif c == column_offset then
               note_column:clear()
            end
         end
      end
   end
end
function set_process_note(octave_order, vel_order)
--[[ Pick a note from the stack and return for insertion --]]
   local ordnot = nil
   local note_order = {}
   local nextnote = 0
   local ordoct = nil
   ordoct = set_process_octave(octave_order)
   local note_scheme = {}
   local repeat_mode = 1
   if switch_note_pattern_index == 2 then
      note_scheme = custom_note_field:split( "[^,%s]+" )
      if note_scheme[1] == nil then
         custom_error_flag = true
         note_scheme[1] = "C-4"
      end
      for i = 1, #note_scheme do
         local tempvar = note_scheme[i]
         if string.len(tempvar) >3 then
            custom_error_flag = true
         end
         tempvar = fix_full_note(tempvar)
         note_scheme[i] = tempvar
       end
   else
      note_scheme = harvest_notes_in_octave(ordoct+1)
   end
   note_order = ferris_wheel (note_scheme, note_order, popup_note_index, repeat_se_note)
   if popup_note_index ~= 5 then --Anything but Random
      if note_pointer > #note_order then
         note_pointer = #note_order
      end
      ordnot = note_order[note_pointer]
      if note_pointer >= #note_order then
         octave_pointer = octave_pointer + 1
         note_pointer = 1
         nextnote = 1
         if octave_pointer > #octave_order then
            octave_pointer = 1
         end
      end
      
      if nextnote == 1 then 
         --If the note_pointer has been set to 1 do not increase it yet!
         nextnote = 0
      else
         note_pointer = note_pointer +1
      end
   else
      --If notes are picked randomly, the upperbound of the note-table
      --will never be reached.... so increase the octave with each note.
      if popup_octave_index ~= 5 then
         octave_pointer = octave_pointer + 1
         if octave_pointer > #octave_order then
            octave_pointer = 1
         end
      end
      ordnot = note_order[randomize(1, #note_order)] 
   end
   return ordnot
end
function fix_full_note(tempvar)
   --[[Check if full note values are valid (start with note and end with figure]]
   local valid_note_found = false
   tempvar = string.sub(tempvar,1,3)
   --Are we tricked with invalid split-chars?
   if string.sub(tempvar,2,2) ~= "#" and string.sub(tempvar,2,2) ~= "-" then
      tempvar = string.sub(tempvar,1,1) .. "-" .. string.sub(tempvar,3,3)
      custom_error_flag = true
   end
   --Are we tricked with invalid octave figures?
   if tonumber(string.sub(tempvar,3,3)) == nil then
      tempvar = string.sub(tempvar,1,2) .. "4"
      custom_error_flag = true
   end
   --Are we tricked with invalid note figures?
   for i = 1,12 do
      if string.upper(string.sub(tempvar,1,1)) == string.sub(note_matrix[i],1,1) then
         valid_note_found = true
         break
      end
   end
   if valid_note_found == false then
      tempvar = "C" .. string.sub(tempvar,2,3)
      custom_error_flag = true
   end   
   --take care only the first three characters of the tempvar are returned
   tempvar = string.sub(tempvar,1,3)
   return tempvar
end
function set_process_octave(octave_order)
--[[ Pick an octave from the stack and return for insertion --]]
   local ordoct = nil
   if popup_octave_index ~= 5 then --Anything but Random
      if octave_order[octave_pointer] == nil and octave_pointer == 0 then
         octave_pointer = 1
      end
      ordoct = tonumber(octave_order[octave_pointer])
   else
      ordoct = octave_order[randomize(1, #octave_order)] 
   end
   return ordoct
end
function set_process_instrument(ins_order)
--[[ Pick an instrument number from the stack and return for insertion --]]
   local tempins = nil
   if instrument_insertion_index ~= 5 then --Anything but Random
      if ins_order[ins_pointer] ~= nil then
         tempins = tonumber(ins_order[ins_pointer]) 
      end
   else
      tempins = tonumber(ins_order[randomize(1,#ins_order)]) 
   end
   return tempins
end
function set_process_velocity(vel_order)
--[[ Pick a velocity figure from the stack and return for insertion --]]
   local tempvel = nil
   if velocity_insertion_index ~= 5 then --Anything but Random
      if vel_order[vel_pointer] ~= nil then
         tempvel = tonumber(vel_order[vel_pointer])
      end
   else
      tempvel = tonumber(vel_order[randomize(1, #vel_order)])
   end
   return tempvel
end
function place_note(note_column, cur_line, octave_order, ins_order, vel_order, 
current_column, track, pattern)
--[[In here is determined if a note has to be placed on this line and if so then
also raise all the instrument and velocity pointers to pick a possible new entry
from the stack. If a note-off has to be placed, this is calculated here as well. 
--]]
   local song = renoise.song()
   local delay_apply = 0
   local cut_value = termination_step
   local onetime = 0
   local nextnote = 0
   local note = nil
   local ordoct = nil
   local tempins = nil
   local ordnot = nil
   local tempvel = nil
   local skip = 0
   if switch_arp_pattern_index == 2 then
      --Insert notes at random spots...  

      --Here we have the root of evil for getting empty patterns in song-mode
      --Aparently when notes were placed on the last lines of a pattern, the
      --last note position was adjourned to the next pattern *if* a position
      --was picked by the randomizer to place a note after the last known 
      --note position of the previous pattern. So this caused empty patterns
      --until a note got placed in that last pattern region. So here's the fix:  
      if cur_line >= 1 and cur_line <= distance_step and 
      place_note_off[current_column] == 0 then
         new_note_pos = 1
      end
      skip = randomize(1,2)
   end
   if current_column <= max_note_columns and current_column == next_column then
      if popup_distance_mode_index == 2 then
         if current_column ~= 1 then
            if (current_column-1)*distance_step <= 255 then
               delay_apply = (current_column-1)*distance_step
            end
         end
         if skip ~= 1 then --if skip = 2 or 0, insert note. 
            ordoct = set_process_octave(octave_order)
            ordnot = set_process_note(octave_order, vel_order)
            tempins = set_process_instrument(ins_order)
            tempvel = set_process_velocity(vel_order)
            if octave_order[1] ~= "empty" and octave_order[1] ~= nil then
               if string.find(ordnot,"#") then
                  note = ordnot..tostring(ordoct)
               else
                  note = ordnot.."-"..tostring(ordoct)
               end
            else
              note = ordnot
            end
            
            if termination_index == 2 then
               cut_value = tonumber(0xf0 + termination_step)
            else
               cut_value = 255
            end
            if note ~= nil then
               if note_column.is_selected and marker_area == 1 or marker_area ~= 1 then
                  note_column = fill_cells(note_column, note, tempins, tempvel, 
                  delay_apply, cut_value)
                  if marker_area < 4 then
                     next_column = next_column + 1
                     if next_column > max_note_columns then
                        next_column = column_offset
                     end
                  end 
                  place_note_off[current_column] = cur_line + termination_step
                  if previous_pattern > 0 then
                     prev_pat_size = song.patterns[previous_pattern].number_of_lines
                     if place_note_off[current_column] > prev_pat_size then
                        place_note_off[current_column] = place_note_off[current_column] - prev_pat_size
                     end
                  end
                  vel_pointer = vel_pointer + 1
                  if vel_pointer > #vel_order then
                     vel_pointer = 1
                  end
                  ins_pointer = ins_pointer + 1
                  if ins_pointer > #ins_order then
                     ins_pointer = 1
                  end
               end
            end                         
         end
      else
         if cur_line == new_note_pos and switch_arp_pattern_index ~= 2 or 
         cur_line >= new_note_pos and switch_arp_pattern_index == 2 then
            if skip ~= 1 then --if skip = 2 or 0, insert note.
               if current_column == max_note_columns or chord_mode == false then
                  if switch_arp_pattern_index ~= 3 then   
                     new_note_pos = cur_line + distance_step+1
                     if new_note_pos > cur_pat_size then
                        new_note_pos = new_note_pos - cur_pat_size
                     end
                  else
                     if custom_note_pos[custom_index] ~= "bn" and 
                     custom_note_pos[custom_index] ~= 'nt' then
                        if tonumber(custom_note_pos[custom_index]) >= cur_line and 
                        custom_index < #custom_note_pos then
                           --If the current line is smaller than the custom row index
                           --we can use the index for the current line
                           new_note_pos = custom_note_pos[custom_index]
                        else
                           --However if the end position has been been found
                           --or the line is larger, add the position to the line
                           if custom_index == #custom_note_pos then
                              new_note_pos = cur_line+custom_note_pos[1]
                           else
                              --line number > custom position
                              if custom_index == 1 then
                                 new_note_pos = cur_line+custom_note_pos[custom_index]
                              else
                                 local dif = custom_note_pos[custom_index] - custom_note_pos[custom_index-1]
                                 new_note_pos = cur_line+dif
                              end
                           end
                        end
                     else
                        if custom_note_pos[custom_index] == 'nt' then
                           new_note_pos = cur_line+custom_note_pos[1]+termination_step
                           custom_index = 1
                        elseif custom_note_pos[custom_index] == 'bn' then
                           new_note_pos = cur_line+custom_note_pos[1]+distance_step 
                           custom_index = 1
                        end
                     end
                     if new_note_pos > cur_pat_size then
                     --Sorry we are not going to shift note-ranges for custom 
                     --patterns, that is way dang too hard to keep track of.
                        custom_index = 1
                        new_note_pos = custom_note_pos[custom_index]
                     end
                     custom_index = custom_index +1
                     if custom_index > #custom_note_pos then
                        custom_index = 1
                     end
                  end
               end
               ordoct = set_process_octave(octave_order)
               ordnot = set_process_note(octave_order, vel_order)
               tempins = set_process_instrument(ins_order)
               tempvel = set_process_velocity(vel_order)
               if octave_order[1] ~= "empty" and octave_order[1] ~= nil then
                  if string.find(ordnot,"#") then
                     note = ordnot..tostring(ordoct)
                  else
                     note = ordnot.."-"..tostring(ordoct)
                  end
               else
                  note = ordnot
               end   
               if termination_index == 2 then
                  cut_value = tonumber(0xf0 + termination_step)
               else
                  cut_value = 255
               end
               if note ~= nil then
                  if note_column.is_selected and marker_area == 1 or 
                     marker_area ~= 1 then 
                     if switch_arp_pattern_index ~= 2 or 
                     cur_line <= cur_pat_size - distance_step and 
                     switch_arp_pattern_index == 2 then
                        note_column = fill_cells(note_column, note, tempins, 
                        tempvel, delay_apply, cut_value)
                     end 
                     place_note_off[current_column] = cur_line + termination_step
                     if previous_pattern > 0 then
                        prev_pat_size = song.patterns[previous_pattern].number_of_lines
                        if place_note_off[current_column] > prev_pat_size then
                           place_note_off[current_column] = place_note_off[current_column] - prev_pat_size
                        end
                     end
                     if marker_area < 4 then
                        next_column = next_column + 1
                        if next_column > max_note_columns then
                           next_column = column_offset
                        end
                     end
                     vel_pointer = vel_pointer + 1
                     if vel_pointer > #vel_order then
                        vel_pointer = 1
                     end
                     ins_pointer = ins_pointer + 1
                     if ins_pointer > #ins_order then
                        ins_pointer = 1
                     end
                  end
               end
            end                         
         end
      end
   end               
   --Place note off
   if current_column <= max_note_columns and termination_step > 0 then
      if cur_line == place_note_off[current_column] then
         if note_column.is_selected and marker_area == 1 or marker_area ~= 1 then
            note_column = fill_cells(note_column, 120, 255, 255, 0, 255)
            place_note_off[current_column] = 0
         end
      end
   end
end
function fill_cells(note_column, note, instrument, velocity, delay, cut_value)
--[[Places a note, volume, panning and perhaps a delay value in the cell--]]
   --String 'OFF' was not yet supported when creating this source.
   --value 120 will add a note-off command in the pattern editor, it suffice.
   if note == 120 then
      note_column.note_value = note
   else
      note_column.note_string = note
   end 
   if note ~= 120 then
      note_column.instrument_value = instrument
      if velocity == 128 then
      --Renoise supports 00-80, but 80 translates to 7f and we translate 80 to
      --no value as no value will be maximum by default 
         velocity = 255 
      end
      note_column.volume_value = velocity
   else
      note_column.instrument_value = 255
      note_column.volume_value = 255
   end
   --Superdeluxe fx scanner, it tries to place notecuts in the pan-column.
   --If there is no space, then they will be inserted into the volume column
   --The only moment the new values are discarded when the "ignore vol/pan/del"
   --option has been checked.
   if skip_fx == true then
      if note_column.delay_value == 0 then
         note_column.delay_value = delay
      end
      if cut_value > 0 then
         if note_column.panning_value ~= 255 then
            if note_column.panning_value >= 240 and note_column.panning_value <= 255 then
               note_column.panning_value = cut_value
            else
               if note_column.volume_value ~= 255 then                  
                  if note_column.volume_value >= 240 or note_column.volume_value <= 255 then
                     note_column.volume_value = cut_value
                  end
               end
            end
         else
            note_column.panning_value = cut_value
         end
      end
   else
      note_column.delay_value = delay
      if cut_value > 0 then
         if note_column.panning_value ~= 255 then
            if note_column.panning_value >= 240 and note_column.panning_value <= 255 then
               note_column.panning_value = cut_value
            else
               --Sorry whatever is in the volume column will now be exchanged.
               --Ignore vol/pan/del option will also prevent volume fx being
               --overwritten. 
               note_column.volume_value = cut_value
            end
         else
            note_column.panning_value = cut_value
         end
      end
   end
   return note_column
end
function check_unique_pattern()
--[[Checks if the song sequence has patterns that are repeated--]]
   local song = renoise.song()
   local double = {}
   local doubles = 1
   local add_one = 0
   local hyve = 2
   double[1] = song.sequencer.pattern_sequence[1]
   local i = 2
   local sp_bound = #song.sequencer.pattern_sequence
   local return_val = 0

   while i <= sp_bound do
      for j = 1, #double do
         if song.sequencer.pattern_sequence[i] == double[j] then
            doubles = doubles + 1
            add_one = 0
            break
         else
            add_one = 1
         end
      end
      if add_one == 1 then
         double[hyve] = song.sequencer.pattern_sequence[i]
         add_one = 0
         hyve = hyve +1
      end
      i = i + 1
   end
   if doubles > 1 then
      return_val = cross_write_dialog(-1, double, doubles) 
   end      
   return return_val
end
function make_unique_pattern()
--[[Copies all repeated patterns to a unique pattern--]]
   local song = renoise.song()
   song.sequencer:make_range_unique(1, #song.sequencer.pattern_sequence)
   return
end
function fetch_notes_from_track(vb)
   local song = renoise.song()     
   local pattern_lines = song.selected_pattern.number_of_lines
   local pattern_index = song.selected_pattern_index
   local track_index = song.selected_track_index
   local track_type = song.selected_track.type
   local visible_note_columns = song.tracks[track_index].visible_note_columns
   local iter, pos
   local check_condition = 0
   local checkbox = nil
   local cb = vb.views
   column_offset = song.selected_note_column_index 
   if switch_note_pattern_index == 2 then
      custom_note_field = ''
   end
   if track_type ~= renoise.Track.TRACK_TYPE_MASTER and
   track_type ~= renoise.Track.TRACK_TYPE_SEND then
      if switch_note_pattern_index == 1 then
         if marker_area <= 2 or marker_area == 4 then
            iter = song.pattern_iterator:lines_in_pattern_track(pattern_index, 
            track_index)
            renoise.app():show_status("Fetching notes in pattern-track / column")
         elseif marker_area == 3 or marker_area == 5 then
            iter = song.pattern_iterator:lines_in_track(track_index)
            renoise.app():show_status("Fetching notes in song-track / column")
         end
      else
         iter = song.pattern_iterator:lines_in_pattern_track(pattern_index, 
         track_index)
         renoise.app():show_status("Fetching notes in pattern-track")
      end
      for _,line in iter do
         for cur_column,note_column in ipairs(line.note_columns) do
            if cur_column <= visible_note_columns then
               if switch_note_pattern_index == 1 then
                  if marker_area == 1 and note_column.is_selected or 
                  marker_area == 2 or marker_area == 3 then
                     if string.sub(note_column.note_string,1,1)~="-" and 
                     string.sub(note_column.note_string,1,1)~="O" then
                        if string.find(note_column.note_string, "#") then
                           checkbox = string.sub(note_column.note_string,1,1).."f"..
                           string.sub(note_column.note_string,3,3)
                        else
                           checkbox = string.sub(note_column.note_string,1,1).."_"..
                           string.sub(note_column.note_string,3,3)
                        end
                           cb[checkbox].value = true
                     end 
                  elseif marker_area == 4 and cur_column == column_offset or marker_area == 5 and 
                         cur_column == column_offset then
                     if string.sub(note_column.note_string,1,1)~="-" and 
                     string.sub(note_column.note_string,1,1)~="O" then
                        if string.find(note_column.note_string, "#") then
                           checkbox = string.sub(note_column.note_string,1,1).."f"..
                           string.sub(note_column.note_string,3,3)
                        else
                           checkbox = string.sub(note_column.note_string,1,1).."_"..
                           string.sub(note_column.note_string,3,3)
                        end
                        cb[checkbox].value = true
                     end 
                  end
               else
                  if marker_area == 1 and note_column.is_selected or 
                  marker_area == 2 or marker_area == 3 then
                     if note_column.note_string ~= '---' and 
                     note_column.note_string ~= 'OFF' then
                        custom_note_field = custom_note_field..note_column.note_string..
                        ", "
                     end
                  elseif marker_area == 4 and cur_column == column_offset or marker_area == 5 and
                         cur_column == column_offset then
                     if note_column.note_string ~= '---' and 
                     note_column.note_string ~= 'OFF' then
                        custom_note_field = custom_note_field..note_column.note_string..
                        ", "
                     end
                  end
               end
            end
         end
      end
      if switch_note_pattern_index == 2 then
         cb.custom_note_profile.value = custom_note_field
      end
   end
end
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
function ferris_wheel(source_table, target_table, direction, repeat_mode)
--[[
   Copies one table into another depending on the desired order.
   This routine is specifically designed when one does *not* want to 
   sort out the original table, it is only to create a temporary table
   using the contents of the other in different order or even in 
   mirrored waves.
   I made changes in the top/down/top and down/top/down schemes not to regenerate
   the previous note if it would be the same. 
--]]
      local tend = #source_table
      if repeat_mode == true then
         repeat_mode = 0
      elseif repeat_mode == false then
         repeat_mode = 1
      end
      if direction == 1 or direction == 5 then --Top-Down / random
         target_table = source_table
      elseif direction == 2 then --Down-Top
         local subt = #source_table
         for t=1, #source_table do
           target_table[t] = source_table[subt]
           subt = subt - 1 
         end
      elseif direction == 3 then --Top-Down-Top
         for t=1, #source_table do
           target_table[t] = source_table[t]
         end
         local subt = #source_table 
         local offc = repeat_mode
         if repeat_mode == 0 then
            target_table[#target_table+1] = source_table[#source_table]
            tend = tend+1
         else
            offc = 2
         end
         for t=(tend), (tend*2-offc) do
           target_table[t] = source_table[subt]
           subt = subt - 1 
         end
      elseif direction == 4 then --Down-Top-Down
         local subt = #source_table 
         local tend = #source_table
         local offs = 2
         for t=1, #source_table do
           target_table[t] = source_table[subt]
           subt = subt - 1
         end
         if repeat_mode == 0 then
            target_table[#target_table+1] = source_table[subt]
            tend = tend+1
            offs = 1
         else
            tend = #source_table - 1
         end
         for t=offs, tend do
            target_table[#target_table+1] = source_table[t]
         end
      end
   return target_table
end
-------------------------------------------------------------------------------
-- The GUI dialogs
-------------------------------------------------------------------------------
---                        Main dialog                                     ----
-------------------------------------------------------------------------------
function open_arp_dialog()

      track_index = renoise.song().selected_track_index
      max_note_columns = renoise.song().tracks[track_index].visible_note_columns
      column_offset = renoise.song().selected_note_column_index 
      if max_note_columns < 1 then -- Cursor on Master / sendtrack?
         max_note_columns = 1
         column_offset = 1
      end
      local vb = renoise.ViewBuilder()
      
      local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
      local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
      local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
      local CHECKBOX_WIDTH = 30
      local TEXT_ROW_WIDTH = 80
--[[------------------------------------------------------------------------
Tone Matrix
--------------------------------------------------------------------------]]
      local figure_matrix = vb:column {
         margin = CONTENT_MARGIN,
         uniform = true,
         style = "border"
      }
   --- header column
      local header_content = vb:row {}
      header_content:add_child(
         vb:space {
            width = CHECKBOX_WIDTH + 40
         }
      )
      for note = 1, NUM_NOTES do
         local ALTERED_WIDTH = nil
         --Centering note-ID's above the checkbox columns
         if note == 1 then
            ALTERED_WIDTH = CHECKBOX_WIDTH-3
         elseif note == 2 then       
            ALTERED_WIDTH = CHECKBOX_WIDTH+3
         elseif note == 3 then
            ALTERED_WIDTH = CHECKBOX_WIDTH-3
         elseif note == 4 then       
            ALTERED_WIDTH = CHECKBOX_WIDTH+3
         elseif note == 5 then
            ALTERED_WIDTH = CHECKBOX_WIDTH+2
         elseif note == 6 then       
            ALTERED_WIDTH = CHECKBOX_WIDTH-2
         elseif note == 7 then       
            ALTERED_WIDTH = CHECKBOX_WIDTH-2
         elseif note == 8 then
            ALTERED_WIDTH = CHECKBOX_WIDTH-2
         elseif note == 9 then       
            ALTERED_WIDTH = CHECKBOX_WIDTH+4
         elseif note == 10 then
            ALTERED_WIDTH = CHECKBOX_WIDTH-2
         elseif note == 11 then       
            ALTERED_WIDTH = CHECKBOX_WIDTH+2
         elseif note == 12 then
            ALTERED_WIDTH = CHECKBOX_WIDTH
         end
         header_content:add_child(
            vb:column {
               create_obj(obj_textlabel, '', ALTERED_WIDTH,0,0,0,'id_note'..tostring(note),
               '',note_matrix[note],'',vb),
            }
         )
      end
   
      figure_matrix:add_child(header_content)
   
   --- octave text & note checkbox columns
      local done_content = vb:column {}
      for octave = 1,NUM_OCTAVES do
         local area_content = vb:row {
         }
         -- octave text
         area_content:add_child(
            vb:row{
               create_obj(obj_textlabel, '', CHECKBOX_WIDTH,0,0,'novalue','id_oct'..tostring(octave),
               '',tostring(octave-1),'',vb),
               create_obj(obj_button, '', CHECKBOX_WIDTH,0,0,0,'id_but'..tostring(octave),
               '','>', function() toggle_octave_row(vb, octave) end,vb),
            }
         )
         -- note checkboxes
         for note = 1, NUM_NOTES  do
            local note_tooltip, note_id
   
            if string.find(note_matrix[note], "#") then
               note_tooltip = note_matrix[note]..tostring(octave-1)
               note_id = note_matrix[note-1].."f"..tostring(octave-1)
            else
               note_tooltip = note_matrix[note].."-"..tostring(octave-1)
               note_id = note_matrix[note].."_"..tostring(octave-1)
            end
            
            area_content:add_child(
               create_obj(obj_checkbox, '', CHECKBOX_WIDTH,0,0,
               note_state(octave, note),note_id,note_tooltip,'', 
               function(value)set_note_state(octave, note, value)end,vb)
            )
         end
         done_content:add_child(area_content)
          
      end

      local ntrigger_area = vb:row {}

      -- note/octave row trigger checkboxes
      for tbutton = 0, 1 do
         local btooltip, btext
         local trigger_content = vb:column {}
         if tbutton == 0 then
           btooltip = "Toggle all off"
           btext = "off"
         else
           btooltip = "Invert all (what is on turns off and what is off turns on)"
           btext = "inv"
         end
   
         trigger_content:add_child(
            create_obj(obj_button, '',CHECKBOX_WIDTH,0,0,0,'id_butt'..tostring(tbutton),
            btooltip,btext, function() set_all_row_state(vb, btext) end,vb)
         )
         ntrigger_area:add_child(trigger_content)
      end

      -- note row trigger checkboxes
      for note = 1, NUM_NOTES do
         local note_tooltip
         local trigger_content = vb:column {}
         if string.find(note_matrix[note], "#") then
           note_tooltip = note_matrix[note]
         else
           note_tooltip = note_matrix[note]
         end
   
         trigger_content:add_child(
            create_obj(obj_button, '', CHECKBOX_WIDTH,0,0,0,'id_butn'..tostring(note),
            note_tooltip,'^', function() toggle_note_row(vb, note) end,vb)
         )
         ntrigger_area:add_child(trigger_content)
      end

      local matrix_layout = vb:column{
         id = 'total_matrix',
         done_content,
         ntrigger_area
      }      
      figure_matrix:add_child(matrix_layout)

--[[------------------------------------------------------------------------
Main Dialog
--------------------------------------------------------------------------]]
      local note_header_contents = vb:row {}
      local picker_row_contents = vb:row {}
      local note_row_contents = vb:row {}
      local button_row_contents = vb:row {}
      note_header_contents:add_child(
         vb:text {
            align = "center",
            width = 325,
            text = "Note & Octave properties"
         }
      )      
      picker_row_contents:add_child(
         create_obj(obj_textlabel,'', 95,0,0,0,'idpr1','','Note & Octave scheme',0,vb)
      )
      picker_row_contents:add_child(
         create_obj(obj_switch, '', 160,0,0,switch_note_pattern_index,
         'switch_note_pattern',
         "Matrix:Pick note and octave order from the note-matrix.\n"..
         "Custom:defined in the textfields below.",
         {"Matrix", "Custom"},
         function(value)
            switch_note_pattern_index = value
            arpeg_option_dialog:close()
            open_arp_dialog()
         end,vb)
      )
      picker_row_contents:add_child(
         create_obj(obj_textlabel, 'right', 48,0,0,0,'idprt2','','',0,vb)
      )
      note_row_contents:add_child(
         create_obj(obj_textlabel, '', 119,0,0,0,'custom_note_profile_title',
         '','Custom note profile',0,vb)
      )
      note_row_contents:add_child(
         create_obj(obj_textfield, '', 309,0,0,custom_note_field,'custom_note_profile',
         'Figures go from C to B, Octave figures are accepted as well',0,
         function(value) custom_note_field = value end,vb)
      )
      button_row_contents:add_child(
         create_obj(obj_button, '', 80,0,0,0,'custom_fetch',
         'Read all notes in track and copy them into the note-profile',
         'Fetch from current track',function(value)fetch_notes_from_track(vb)end,vb)
      )
      local arp_header_contents = vb:row {}
      local distance_row_contents = vb:row {}
      local termination_row_header_contents = vb:column {}
      local termination_row_contents = vb:row {}
      arp_header_contents:add_child(
         create_obj(obj_textlabel, 'center', 325,0,0,0,'idaht1','',
         'Arpeggiator options',0,vb)
      )      
      distance_row_contents:add_child(
         create_obj(obj_textlabel, '', 140,0,0,0,'iddr1','',
         'Min. distance between notes',0,vb)
      )
      distance_row_contents:add_child(
         create_obj(obj_valuebox, '', 50,0,512,distance_step,'vbox_distance_step',
         'Amount of lines or delay-values before next note is inserted',0,
         function(value) change_distance_step(value, vb)end,vb)
      )
      distance_row_contents:add_child(
         create_obj(obj_popup, '', 37,0,0,popup_distance_mode_index,'popup_distance_mode',
         'Lin = Lines, Del = Delay. Delay requires more notecolumns',{"Lin", "Del"},
         function(value)change_distance_mode(value,vb)end,vb)
      )
      distance_row_contents:add_child(
         create_obj(obj_textlabel, '', 60,0,0,0,'popup_octave_order_text','',
         'Octave order',0,vb)
      )
      distance_row_contents:add_child(
         create_obj(obj_popup, '', 70,0,0,popup_octave_index,'popup_octave_order',
         'Which order should the octave numbers be generated?',
         {"TopDown", "DownTop", "TopDownTop","DownTopDown", "Random"},
         function(value)change_octave_order(value,vb)end,vb)
      )
      distance_row_contents:add_child(
         create_obj(obj_textlabel, 'right', 40,0,0,0,'octave_repeat_mode_text',
         '','Repeat',0,vb)
      )
      distance_row_contents:add_child(
         create_obj(obj_checkbox, '', 18,0,0,repeat_se_octave,'octave_repeat_mode',
         'Repeat first and end sequence of the octave TdT and DtD sequence',0,
         function(value)
            if value == true then
               repeat_se_octave = 0
            else
               repeat_se_octave = 1
            end
         end,vb)
      )
      termination_row_header_contents:add_child(
         create_obj(obj_textlabel, '', 142,0,0,0,'idtrt4','','Note termination each',
         0,vb)
      )
      termination_row_contents:add_child(
         create_obj(obj_valuebox, '', 50,0,511,termination_step,'vbox_termination_step',
         'Amount of lines or pan/vol fx cut-values',0,
         function(value) set_termination_step(value,vb)end,vb)
      )

      termination_row_contents:add_child(
         create_obj(obj_popup, '', 37,0,0,termination_index,'popup_note_termination_mode',
         "Tck = Ticks will cut (apply note-off) before end of line\n"..
         "Lin = Lines will apply note-off every xx lines",{'Lin', 'Tck'},
         function(value)set_termination_minmax(value,vb)end,vb)
      )
      termination_row_contents:add_child(
         create_obj(obj_textlabel, '', 68,0,0,0,'idtrct1','','Note Order',0,vb)
      )
      termination_row_contents:add_child(
         create_obj(obj_popup, '', 70,0,0,popup_note_index,'popup_note_order',
         'Which order should the notes be generated?',
         {"TopDown", "DownTop", "TopDownTop","DownTopDown", "Random"},
         function(value)change_note_order(value,vb)end,vb)
      )
      termination_row_contents:add_child(
         create_obj(obj_textlabel, 'right', 40,0,0,0,'repeat_note_title','',
         'Repeat',0,vb)
      )
      termination_row_contents:add_child(
         create_obj(obj_checkbox, '', 18,0,0,repeat_se_note,'repeat_note',
         'Repeat first and end sequence of the note scheme TdT and DtD sequence',
         0,function(value)
            if value == true then
               repeat_se_note = 0
            else
               repeat_se_note = 1
            end                  
         end,vb)
      )
      local arpeggiator_area = vb:column{
         margin = CONTENT_MARGIN,
         spacing = CONTENT_SPACING,
         uniform = true,
         width = "100%",
         vb:horizontal_aligner {
            mode = "justify",
            width = "100%",
            vb:column {
               spacing = 8,
               uniform = true,
               vb:row{
                  vb:column{
                     margin = DIALOG_MARGIN,
                     style = "group",
                     vb:horizontal_aligner {
                        mode = "center",
                        note_header_contents
                     },
                     vb:horizontal_aligner {
                        mode = "left",
                        picker_row_contents,
                     },
                     vb:horizontal_aligner {
                        mode = "left",
                        note_row_contents,
                     },
                     vb:horizontal_aligner {
                        mode = "center",
                        button_row_contents,
                     },
                  },
               },
               vb:row{
                  vb:column{
                     margin = DIALOG_MARGIN,
                     style = "group",
                     vb:horizontal_aligner {
                        mode = "center",
                        arp_header_contents
                     },
                     vb:horizontal_aligner {
                        mode = "left",
                        distance_row_contents,
                     },
                     vb:horizontal_aligner{
                        mode = "left",
                        termination_row_header_contents,
                        termination_row_contents,
                     },
                     vb:row {
                        vb:horizontal_aligner {
                           mode = "left",
                           create_obj(obj_textlabel, '', 90,0,0,0,'idtt1','',
                           'Arpeggio Pattern',0,vb),
                           create_obj(obj_switch, '', 160,0,0,switch_arp_pattern_index,
                           'switch_arp_pattern',
                           "Distance:Place each note straight at minimum distance.\n"..
                           "Random:Place notes on random lines, (keeping minimum distance!).\n"..
                           "Custom:defined in the textfield below.",
                           {"Distance", "Random", "Custom"},
                           function(value)toggle_custom_arpeggiator_profile_visibility(value, vb)end,vb),
                           create_obj(obj_textlabel, '', 66,0,0,0,'idtt2','',
                           'Note cols.',0,vb),
                           create_obj(obj_valuebox, '', 51,1,12,max_note_columns,
                           'max_note_colums',
                           "The maximum amount of note-columns that will be\n"..
                           "generated when using delay-distance",
                           0,function(value)toggle_chord_mode_visibility(value,vb)end,vb),
                           create_obj(obj_textlabel, '', 40,0,0,0,'chord_mode_box_title',
                           '','Chord',0,vb),
                           create_obj(obj_checkbox, '', 18,0,0,chord_mode,
                           'chord_mode_box',
                           'Should all notes be placed in chord mode or keep row-distance between each note?',
                           0,function(value)chord_mode = value end,vb),
                        },
                     },
                     vb:row {
                        create_obj(obj_textlabel, '', 98,0,0,0,'custom_arpeggiator_profile_title',
                        '','Custom pattern',0,vb),
                        create_obj(obj_textfield, '', 330,0,0,custom_arpeggiator_field,
                        'custom_arpeggiator_profile',
                        "each figure represents a line, after the last line\n"..
                        "the pattern restarts using the note-off value as "..
                        "the distance (nt) or minimum\nlines between notes (bn)."..
                        " Undefined means restart directly after the last line",
                        0,function(value)custom_arpeggiator_field = value end,vb),
                     },
                  },
               },
            }
         } 
      }
      local property_area = vb:column {
         margin = CONTENT_MARGIN,
         spacing = CONTENT_SPACING,
         uniform = true,
         vb:column {
            style = "group",
            margin = DIALOG_MARGIN,
            uniform = true,
            vb:row {
               width = 325,
               vb:row {
                  width= ((325)/2)-(65)
               },
               create_obj(obj_textlabel, 'center', 410,0,0,0,'idpatl1','',
               'Instrument & volume pool selection',0,vb),
            },
            vb:row {
               create_obj(obj_textlabel, '', 65,0,0,0,'idpatl2','','Inst. pool',0,vb),
               create_obj(obj_textfield, '', 230,0,0,pinstruments_field,
               'popup_procins',
               "Insert instrument numbers, comma separated. The range of "..
               "00-128 will do,\nhexadecimal notation 0x00 - 0x80 is also fine."..
               "If no instrument is filled in,\nthe current selected instrument"..
               "will be used instead.",
               0,function(value)pinstruments_field = value end,vb),
               create_obj(obj_popup, '', 70,0,0,instrument_insertion_index,
               'popup_ins_insertion','How should instrument numbers be inserted from the pool?',
               {"TopDown", "DownTop", "TopDownTop","DownTopDown", "Random"},
               function(value) change_instrument_insertion(value,vb) end,vb),
               create_obj(obj_textlabel, 'right', 40,0,0,0,'repeat_instrument_title',
               '','Repeat',0,vb),
               create_obj(obj_checkbox, '', 18,0,0,repeat_se_instrument,
               'repeat_instrument',
               'Repeat first and end sequence of the instrument TdT and DtD sequence',
               0,function(value)
                  if value == true then
                     repeat_se_instrument = 0
                  else
                     repeat_se_instrument = 1
                  end                  
               end,vb),
            },
            vb:row{
               create_obj(obj_textlabel, '', 65,0,0,0,'idpatl3','','Volume pool',0,vb),
               create_obj(obj_textfield, '', 230,0,0,pvelocity_field,'popup_procvel',
               "Insert velocity and fx values either hex or decimal.\n".. 
               "If the line remains empty or example then the full volume"..
               " will be used.",
               0,function(value)pvelocity_field = value end,vb),
               create_obj(obj_popup, '', 70,0,0,velocity_insertion_index,
               'popup_vel_insertion','How should velocity layers be inserted from the pool?',
               {"TopDown", "DownTop", "TopDownTop","DownTopDown", "Random"},
               function(value) change_velocity_insertion(value,vb) end,vb),
               create_obj(obj_textlabel, 'right', 40,0,0,0,'repeat_velocity_title',
               '','Repeat',0,vb),
               create_obj(obj_checkbox, '', 18,0,0,repeat_se_velocity,'repeat_velocity',
               'Repeat first and end sequence of the velocity TdT and DtD sequence',
               0,function(value)
                  if value == true then
                     repeat_se_velocity = 0
                  else
                     repeat_se_velocity = 1
                  end                  
               end,vb),
            },
         },
         vb:row {
            create_obj(obj_textlabel, '', TEXT_ROW_WIDTH,0,0,0,'idpatl4','','Which area',0,vb),
            create_obj(obj_chooser, '', 265,0,0,marker_area,'chooser','',
            {"Selection in track","Track in pattern", "Track in song", "Column in track", "Column in song"},
            function(value) set_area_selection(value,vb) end,vb),
            vb:column{
               vb:row {
                  create_obj(obj_checkbox, '', 18,0,0,skip_fx,'pacbx1',
                  "When checked, pan/vol/delay values will *not* be\n" ..
                  "over written with new values, if they contain "..
                  "an existing value.\n(except old note-cut commands!)",
                  0,function(value)skip_fx = value end,vb),
                  create_obj(obj_textlabel, '', TEXT_ROW_WIDTH,0,0,0,'idpatl6','',
                  'Skip pan/vol/del',0,vb),
               },
               vb:row {
                  create_obj(obj_checkbox, '', 18,0,0,clear_track,'idpacb2',
                  'Clear track before generating new notes',0,
                  function(value) clear_track = value end,vb),
                  create_obj(obj_textlabel, '', TEXT_ROW_WIDTH,0,0,0,'idpatl7',
                  '','Clear track',0,vb),
               },
               vb:row {
                  create_obj(obj_checkbox,'',18,0,0,auto_play_pattern,'idpacb3',
                  'Auto-play created sequence',0,
                  function(value)auto_play_pattern = value end,vb),
                  create_obj(obj_textlabel, '', TEXT_ROW_WIDTH,0,0,0,'idpatl8','',
                  'Auto play result',0,vb),
               },
            },
         },
         vb:space{height = 3*CONTENT_SPACING},
      --- Let's do it!!
         vb:row {
            vb:space {width = 185},
            create_obj(obj_button, '', 60,0,0,0,'idpabu1','','Arpeggiate!',
            function()add_notes(1,1,vb)end,vb),
            vb:space {width = 165,},
      --- Any help?
            create_obj(obj_button, '', 10,0,0,0,'idpabu2','','?',
            function()show_help() end,vb),
         }
      }
      local operation_area = vb:column {
         arpeggiator_area,
         property_area
      }
      local total_layout = vb:column {
         margin = CONTENT_MARGIN,
         spacing = CONTENT_SPACING,
         uniform = true,
      }
      if switch_note_pattern_index == 2 then
         --Make sure the "show matrix" button won't be visible if the main dialog
         --would be closed and then reopened
         total_layout:add_child(operation_area)
      else
         total_layout:add_child(figure_matrix)
         total_layout:add_child(operation_area)
      end
      if switch_arp_pattern_index == 3 then
         toggle_custom_arpeggiator_profile_visibility(3, vb)         
      else
         toggle_custom_arpeggiator_profile_visibility(1, vb)         
      end
      if max_note_columns < 2 then
         toggle_chord_mode_visibility(1,vb)
      else
         toggle_chord_mode_visibility(2,vb)
      end
      if velocity_insertion_index >= 3 and velocity_insertion_index <= 4 then
         vb.views.repeat_velocity.visible = true
         vb.views.repeat_velocity_title.visible = true
      else
         vb.views.repeat_velocity.visible = false
         vb.views.repeat_velocity_title.visible = false
      end      
      if instrument_insertion_index >= 3 and instrument_insertion_index <= 4 then
         vb.views.repeat_instrument.visible = true
         vb.views.repeat_instrument_title.visible = true
      else
         vb.views.repeat_instrument.visible = false
         vb.views.repeat_instrument_title.visible = false
      end
      if popup_note_index >= 3 and popup_note_index <= 4 then
            vb.views.repeat_note.visible = true
            vb.views.repeat_note_title.visible = true
      else
         vb.views.repeat_note.visible = false
         vb.views.repeat_note_title.visible = false
      end
      if popup_octave_index >= 3 and popup_octave_index <= 4 then
         if switch_note_pattern_index == 1 then
            vb.views.octave_repeat_mode.visible = true
            vb.views.octave_repeat_mode_text.visible = true
         else
            toggle_octave_visibility(false, vb)
         end
      else
         vb.views.octave_repeat_mode.visible = false
         vb.views.octave_repeat_mode_text.visible = false
      end
      if switch_note_pattern_index == 1 then
         toggle_note_profile_visibility(false, vb)
         toggle_octave_visibility(true, vb)
      else
         toggle_note_profile_visibility(true, vb)
         toggle_octave_visibility(false, vb)
      end
      if first_show == false then
         toggle_chord_mode_visibility(1,vb)
         toggle_custom_arpeggiator_profile_visibility(1, vb)         
         toggle_note_profile_visibility(false, vb)
         first_show = true
      end
      if (arpeg_option_dialog and arpeg_option_dialog.visible) then
         arpeg_option_dialog:show()
      else 
         arpeg_option_dialog = nil
         arpeg_option_dialog = renoise.app():show_custom_dialog("Epic Arpeggiator", 
         total_layout)
      end
end


-------------------------------------------------------------------------------
---                     Main dialog visibility toggles                     ----
-------------------------------------------------------------------------------
function change_distance_step(value, vb)
   distance_step = value
   if popup_distance_mode_index == 2 then
      vb.views.vbox_distance_step.max = 255
   else
      vb.views.vbox_distance_step.max = 511
   end
end
function change_distance_mode(value,vb)
   popup_distance_mode_index = value
   if value == 2 then
      vb.views.vbox_distance_step.max = 255
      if vb.views.vbox_distance_step.value > 255 then
         vb.views.vbox_distance_step.value = 255
      end
   else
      vb.views.vbox_distance_step.max = 511
   end
end
function change_octave_order(value,vb)
   popup_octave_index = value
   if value >= 3 and value <= 4 then
      vb.views.octave_repeat_mode.visible = true
      vb.views.octave_repeat_mode_text.visible = true
   else
      vb.views.octave_repeat_mode.visible = false
      vb.views.octave_repeat_mode_text.visible = false
   end
end
function set_termination_step(value,vb)
   if termination_index == 2 then
      if value > 15 then
         value = 15
      end
      vb.views.vbox_termination_step.max = 14
      vb.views.vbox_termination_step.min = 1
   else
      vb.views.vbox_termination_step.min = 0
      vb.views.vbox_termination_step.max = 511                     
   end
   termination_step = value
end
function set_termination_minmax(value,vb)
   termination_index = value
   if value == 2 then
      if vb.views.vbox_termination_step.value > 15 then
         vb.views.vbox_termination_step.value = 14
      end
      vb.views.vbox_termination_step.max = 14
      vb.views.vbox_termination_step.min = 1
   else
      vb.views.vbox_termination_step.min = 0
      vb.views.vbox_termination_step.max = 511
   end
end
function change_note_order(value,vb)
   popup_note_index = value
   if value >= 3 and value <= 4 then
      vb.views.repeat_note.visible = true
      vb.views.repeat_note_title.visible = true
   else
      vb.views.repeat_note.visible = false
      vb.views.repeat_note_title.visible = false
   end
end
function change_instrument_insertion(value,vb)
   instrument_insertion_index = value
   if value >= 3 and value <= 4 then
      vb.views.repeat_instrument.visible = true
      vb.views.repeat_instrument_title.visible = true
   else
      vb.views.repeat_instrument.visible = false
      vb.views.repeat_instrument_title.visible = false
   end
end
function change_velocity_insertion(value,vb)
   velocity_insertion_index = value
   if value >= 3 and value <= 4 then
      vb.views.repeat_velocity.visible = true
      vb.views.repeat_velocity_title.visible = true
   else
      vb.views.repeat_velocity.visible = false
      vb.views.repeat_velocity_title.visible = false
   end
end
function set_area_selection(value,vb)
   local chooser = vb.views.chooser
   if value==3 or value==5 then
      local seq_status = check_unique_pattern()
      if seq_status== -1 then
         vb.views.chooser.value = marker_area
      else
         marker_area = value
         vb.views.chooser.value = value
      end
   else
      marker_area = value
   end
end
function toggle_custom_arpeggiator_profile_visibility(value, vb)
   switch_arp_pattern_index = value
   if value == 3 then
      value = true
   else         
      value = false
   end

   if value == true then
      vb.views.custom_arpeggiator_profile_title.visible = true
      vb.views.custom_arpeggiator_profile.visible = true
   else
      vb.views.custom_arpeggiator_profile_title.visible = false
      vb.views.custom_arpeggiator_profile.visible = false
   end
end
function toggle_note_profile_visibility(show, vb)
   if show == true then
      vb.views.custom_note_profile_title.visible = true
      vb.views.custom_note_profile.visible = true
   else
      vb.views.custom_note_profile_title.visible = false
      vb.views.custom_note_profile.visible = false
   end
end
function toggle_chord_mode_visibility(value,vb)
   max_note_columns = value
   if value < 2 then
      value = false
   else
      value = true
   end
   if value == true then
      vb.views.chord_mode_box_title.visible = true
      vb.views.chord_mode_box.visible = true
   else
      vb.views.chord_mode_box_title.visible = false
      vb.views.chord_mode_box.visible = false
   end

end
function toggle_octave_visibility(show, vb)
   if show == true then
      vb.views.popup_octave_order_text.visible = true
      vb.views.popup_octave_order.visible = true
      vb.views.octave_repeat_mode_text.visible = true
      local pidx = vb.views.popup_octave_order.value
      if pidx >= 3 and pidx <= 4 then
         vb.views.octave_repeat_mode.visible = true
         vb.views.octave_repeat_mode_text.visible = true
      else
         vb.views.octave_repeat_mode.visible = false
         vb.views.octave_repeat_mode_text.visible = false
      end
   else
      vb.views.popup_octave_order_text.visible = false
      vb.views.popup_octave_order.visible = false
      vb.views.octave_repeat_mode_text.visible = false
      vb.views.octave_repeat_mode.visible = false
   end
end
function create_obj(type,pa,pw,pmi,pma,pv,pid,ptt,ptx,pn,vb)
--This is the main GUI creation function
--It is not necessary to have a function like this, you can always embed the below vb:code
--into your source-snippets, this was just a test to see if structurizing it made things
--clearer. The abbreviations obviously do not, but they have been shortened after the program was finished.
--This is what they were named before the program got tagged "finished":
--p stands for Property, id = Identity, a = alignment, w = width, tt = tooltip, tx = text, v = value
--mi = min, ma = max, n = notifier, vb stands for ViewBuilder
   if pa == '' then
      pa = 'left'
   end    
   if type == obj_textlabel then
      return vb:text {id=pid,align=pa,width=pw,tooltip=ptt,text=ptx}
   end
   if type == obj_button then
      return vb:button {id=pid,width=pw,tooltip=ptt,text=ptx,notifier=pn}
   end
   if type == obj_checkbox then
      return vb:checkbox {id=pid,width=pw,tooltip=ptt,value=pv,notifier=pn}
   end
   if type == obj_switch then
      return vb:switch {id=pid,width=pw,tooltip=ptt,items=ptx,value=pv,notifier=pn}
   end
   if type == obj_popup then
      return vb:popup {id=pid,width=pw,tooltip=ptt,items=ptx,value=pv,notifier=pn}
   end
   if type == obj_chooser then
      return vb:chooser {id=pid,width=pw,tooltip=ptt,items=ptx,value=pv,notifier=pn}
   end
   if type == obj_valuebox then
      return vb:valuebox {id=pid,width=pw,tooltip=ptt,min=pmi,max=pma,value=pv,notifier=pn}
   end
   if type == obj_slider then
      return vb:slider {id=pid,width=pw,tooltip=ptt,min=pmi,max=pma,value=pv,notifier=pn}
   end
   if type == obj_minislider then
      return vb:minislider {id=pid,width=pw,tooltip=ptt,min=pmi,max=pma,value=pv,notifier=pn}   
   end
   if type == obj_textfield then
      return vb:textfield{id=pid,align=pa,width=pw,tooltip=ptt,value=pv,notifier=pn}
   end
end

-------------------------------------------------------------------------------
---                     Warning dialog pattern sequence                    ----
-------------------------------------------------------------------------------
function cross_write_dialog(return_val, double, doubles)
   local vb = renoise.ViewBuilder() 
   local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
   local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
   local dialog_title = "Cross-write warning"
   local dialog_content = vb:column { 
      margin = CONTENT_MARGIN,
      spacing = CONTENT_SPACING,
      uniform = true,
      vb:text {
         align="center",
         text = "You have "..#double.." patterns that repeat on "..doubles..
         " positions\n".."If you arpeggiate across the song, you"..
         " might\nunawarely overwrite previously filled areas.\n\nDo you want to"..
         " make the pattern order\nunique in the pattern sequencer?"
      },
      vb:horizontal_aligner{
         mode = "center",
         vb:row{
            spacing = 8,
            create_obj(obj_button, '', 50,0,0,0,'idwdbut1',
            'Making all patterns unique by copying the pattern to a new instance',
            'Make unique',function()
               make_unique_pattern()
               pseq_warn_dialog:close()
               pseq_warn_dialog = nil
               return_val = 0
            end,vb),
            create_obj(obj_button, '', 50,0,0,0,'idwdbut2',
            'reverts to previous area choice','Cancel',function()
               pseq_warn_dialog:close()
               pseq_warn_dialog = nil
            end,vb)
         }
      }
   }
   if (pseq_warn_dialog and pseq_warn_dialog.visible)then
      pseq_warn_dialog:show()
   else
      pseq_warn_dialog = nil
      pseq_warn_dialog = renoise.app():show_custom_dialog(dialog_title,
      dialog_content)
   end
   return return_val
end

-------------------------------------------------------------------------------
---                           Help dialog                                  ----
-------------------------------------------------------------------------------
function show_help()
   local vb = renoise.ViewBuilder()

   local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
   local DIALOG_SPACING = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING

   renoise.app():show_prompt(
      "About Epic Arpeggiator",
            [[
The Epic Arpeggiator allows you to generate notes in different octave ranges and
different note-ranges using different instruments. What is explained here are a 
few things you should know in advance before using this tool Let's start with 
the note matrix:

Each note can be toggled individually. Then you can click on each ">" button and
each "^" button which invert the whole octave or note-row selection. This also
means that what was turned on, will be turned off and vice versa. The "inv" 
button will inverse the complete matrix, similar to what the octave or note-row 
toggle buttons do.

Custom note profile
You can set notes in the note profile, they should all be full notes (meaning:
C-4 or C#4). The note profile offers you to set up note-schemes that the matrix
does not offer you space for. Like percussion patterns with repeative notes on
several places in the sequence.

Fetch from current track
Fetching notes from the current track also depends on the area selection.
If you selected Track from song, it will gather all notes entered in that track
scattered across the whole song. If you only selected an area, only the notes
in the area will be gathered if selection in track has been toggled. The only
exception is fetching notes for the custom note profile where only notes are
fetched from the current pattern or selection.

TopDown, DownTop, etc... -> What are those?
If you are known to arpeggiators, the phrase Up/Down is more common which
ain't much different here:
Note/octave/instrument and velocity queues are placed in blocks depending on the
order. This is how these directions work: Td means order 123 will be repeated as
[123][123]. Dt repeats as [321][321] TdT repeats 123 as [1232][1232] and DtD 
repeats as [3212][3212]. With the TdT and DtD selected, also the repeat 
checkboxes will become available. If you check the repeat box, the first and last
in the order will also be repeated: 123 will then be repeated in TdT as [123321]
[123321] and in DtD as [321123][321123].If you use the tone-matrix, beware that
the order is always oriented from the octave row and then the note. For arbitrary
note orders that the matrix does not put up for you:use the custom note profile
instead.

The arpeggiator options
The minimum distance between notes can be in "lines" or "delay" value. If you 
use the "delay" value, you need to raise the "note cols." valuebox in order to 
make this work. The note-cols value will match the value of the current available
note-columns in the track. If you change this, the change will be directly 
reflected towards the track if you execute the arpeggiation process!  If you 
raise the note columns, the Chord checkbox becomes available, if you check it,
all note-columns on the respective fill-line are filled until the last notecolumn 
has been reached. If you want to create different sized chordprogressions, use 
the custom note-profile for this, however, keep in mind to keep the amount of 
notes per chord exactly the same.If you however are in for some surprises and 
like to experiment with shifted 3-note chord progressions spanned across on 4 or
5 notecolumns or other random outcome, then specially don't use this tool by the
book ;). 


Arpeggio pattern
Custom:places notes according to your personal line-scheme inserted in the text-
line. using nt means closing with a line-termination (note-off or cut defined above)
using bn means uphold the minimum defined distance between the last defined 
row position and the next repetition of your custom pattern. The pattern will be 
repeated until the pattern has been filled out. In song mode only the notes are
shifted across the song, the custom pattern will be restarted from each pattern.
If you do not insert any values in the custom pattern field (leaving the demo 
contents there), distance mode will be automatically selected. You have to add a
pattern. Also, you can't use nt and nb in the same pattern, you also have to close 
your pattern with either "nt" or "bn". If you want your last note directly being 
followed, select bn and set the distance between notes to 00. If you desire 
surprises, attempt to disobey the rules. 

Instrument and volume pool
No instruments or volume values inserted in the textfield result in the current
selected instrument as value and maximum volume as value. You can also insert
the other effect values in the volume pool!


Skip Pan/vol/delay
This function only covers the note distance mode and note termination mode 
routines when note delay and note-cuts are used. When this checkbox is checked, 
the delay column remains untouched if there are existing values. Panning and 
volume columns are not touched by the routine that tries to insert note-cut 
values on either panning or volume column, however fx values filled in the custom 
velocity will always overwrite the existing effect. Ofcourse, the "Clear track" 
checkbox should not be toggled in this case!


                                                                                                                         vV   
]],
      {"OK"}
   )

end
