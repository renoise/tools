
-------------------------------------------------------------------------------
-- Processing functions
-------------------------------------------------------------------------------

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
      if area_to_process <= OPTION_TRACK_IN_PATTERN or area_to_process == OPTION_COLUMN_IN_PATTERN then
         iter = song.pattern_iterator:lines_in_pattern_track(pattern_index, 
         track_index)
         renoise.app():show_status("Arpeggiating track / column in pattern")
      elseif area_to_process == OPTION_TRACK_IN_SONG or area_to_process == OPTION_COLUMN_IN_SONG then
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
         velocity_insertion_index = PLACE_TOP_DOWN
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
         instrument_insertion_index = PLACE_TOP_DOWN
      end
      if termination_index == NOTE_OFF_DISTANCE_LINES then
         cut_value = 0
      end
      if custom_note_pos[1] == 0 or custom_note_pos[1] == nil and switch_arp_pattern_index == ARPEGGIO_PATTERN_CUSTOM then
         switch_arp_pattern_index = ARPEGGIO_PATTERN_DISTANCE
         vb.views.switch_arp_pattern.value =  switch_arp_pattern_index
      end
      if instruments_pool_empty == 1 then
         --If no instrument is inserted into the instrument pool, select the 
         --current selected instrument from the instrument list.
         process_instruments[1] = song.selected_instrument_index - 1 
         instrument_insertion_index = PLACE_TOP_DOWN
      end
      if velocity_pool_empty == 1 then
         process_velocity[1] = velocity_index
         velocity_insertion_index = PLACE_TOP_DOWN
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
            if switch_arp_pattern_index ~= ARPEGGIO_PATTERN_CUSTOM then   
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
         
            if area_to_process == OPTION_SELECTION_IN_TRACK and note_column.is_selected then
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
         if area_to_process <= OPTION_TRACK_IN_PATTERN or area_to_process == OPTION_COLUMN_IN_PATTERN then
            if l_range[1].sequence ~= song.selected_sequence_index and 
            l_range[2] ~= song.selected_sequence_index then
               l_range[1].sequence = song.selected_sequence_index
               l_range[2].sequence = song.selected_sequence_index
               song.transport.loop_range = l_range
            end
         elseif area_to_process == OPTION_TRACK_IN_SONG or area_to_process == OPTION_COLUMN_IN_SONG then
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
   if area_to_process <= OPTION_TRACK_IN_PATTERN or area_to_process == OPTION_COLUMN_IN_PATTERN then
      iter = song.pattern_iterator:
         lines_in_pattern_track(pattern_index, track_index)
      renoise.app():show_status("Clear and arpeggiate track /column in pattern")
   elseif area_to_process == OPTION_TRACK_IN_SONG or area_to_process == OPTION_COLUMN_IN_SONG then
      iter = song.pattern_iterator:lines_in_track(track_index)
      renoise.app():show_status("Clear and arpeggiate track /column in song")
   end
   for _,line in iter do
      for c,note_column in ipairs(line.note_columns) do
         if c <= visible_note_columns and c >= column_offset then
            if area_to_process < OPTION_COLUMN_IN_PATTERN then
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
   if switch_note_pattern_index == NOTE_PATTERN_CUSTOM then
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
   if popup_note_index ~= PLACE_RANDOM then --Anything but Random
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
      if popup_octave_index ~= PLACE_RANDOM then
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
   if popup_octave_index ~= PLACE_RANDOM then --Anything but Random
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
   if instrument_insertion_index ~= PLACE_RANDOM then --Anything but Random
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
   if velocity_insertion_index ~= PLACE_RANDOM then --Anything but Random
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
   if switch_arp_pattern_index == ARPEGGIO_PATTERN_RANDOM then
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
               if note_column.is_selected and area_to_process == OPTION_SELECTION_IN_TRACK or area_to_process ~= OPTION_SELECTION_IN_TRACK then
                  note_column = fill_cells(note_column, note, tempins, tempvel, 
                  delay_apply, cut_value)
                  if area_to_process < OPTION_COLUMN_IN_PATTERN then
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
         if cur_line == new_note_pos and switch_arp_pattern_index ~= ARPEGGIO_PATTERN_RANDOM or 
         cur_line >= new_note_pos and switch_arp_pattern_index == ARPEGGIO_PATTERN_RANDOM then
            if skip ~= 1 then --if skip = 2 or 0, insert note.
               if current_column == max_note_columns or chord_mode == false then
                  if switch_arp_pattern_index ~= ARPEGGIO_PATTERN_CUSTOM then   
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
               if termination_index == NOTE_OFF_DISTANCE_TICKS then
                  cut_value = tonumber(0xf0 + termination_step)
               else
                  cut_value = 255
               end
               if note ~= nil then
                  if note_column.is_selected and area_to_process == OPTION_SELECTION_IN_TRACK or 
                     area_to_process ~= OPTION_SELECTION_IN_TRACK then 
                     if switch_arp_pattern_index ~= ARPEGGIO_PATTERN_RANDOM or 
                     cur_line <= cur_pat_size - distance_step and 
                     switch_arp_pattern_index == ARPEGGIO_PATTERN_RANDOM then
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
                     if area_to_process < OPTION_COLUMN_IN_PATTERN then
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
         if note_column.is_selected and area_to_process == OPTION_SELECTION_IN_TRACK or area_to_process ~= OPTION_SELECTION_IN_TRACK then
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
   if switch_note_pattern_index == NOTE_PATTERN_CUSTOM then
      custom_note_field = ''
   end
   if track_type ~= renoise.Track.TRACK_TYPE_MASTER and
   track_type ~= renoise.Track.TRACK_TYPE_SEND then
      if switch_note_pattern_index == NOTE_PATTERN_MATRIX then
         if area_to_process <= OPTION_TRACK_IN_PATTERN or area_to_process == OPTION_COLUMN_IN_PATTERN then
            iter = song.pattern_iterator:lines_in_pattern_track(pattern_index, 
            track_index)
            renoise.app():show_status("Fetching notes in pattern-track / column")
         elseif area_to_process == OPTION_TRACK_IN_SONG or area_to_process == OPTION_COLUMN_IN_SONG then
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
               if switch_note_pattern_index == NOTE_PATTERN_MATRIX then
                  if area_to_process == OPTION_SELECTION_IN_TRACK and note_column.is_selected or 
                  area_to_process == OPTION_TRACK_IN_PATTERN or area_to_process == OPTION_TRACK_IN_SONG then
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
                  elseif area_to_process == OPTION_COLUMN_IN_PATTERN and cur_column == column_offset or area_to_process == OPTION_COLUMN_IN_SONG and 
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
                  if area_to_process == OPTION_SELECTION_IN_TRACK and note_column.is_selected or 
                  area_to_process == OPTION_TRACK_IN_PATTERN or area_to_process == OPTION_TRACK_IN_SONG then
                     if note_column.note_string ~= '---' and 
                     note_column.note_string ~= 'OFF' then
                        custom_note_field = custom_note_field..note_column.note_string..
                        ", "
                     end
                  elseif area_to_process == OPTION_COLUMN_IN_PATTERN and cur_column == column_offset or area_to_process == OPTION_COLUMN_IN_SONG and
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
      if switch_note_pattern_index == NOTE_PATTERN_CUSTOM then
         cb.custom_note_profile.value = custom_note_field
      end
   end
end
