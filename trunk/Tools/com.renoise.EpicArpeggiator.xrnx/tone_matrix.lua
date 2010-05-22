-------------------------------------------------------------------------------
-- tone matrix initialisation
-------------------------------------------------------------------------------


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
