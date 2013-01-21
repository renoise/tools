--[[============================================================================
gui_controls.lua, everything regarding visual layout control can be found here
============================================================================]]--

---------------------------------------------------------------------------------
-- Keyboard control handler
---------------------------------------------------------------------------------
function key_control(dialog, key)
  --print('name:',key.name,'mod:',key.modifiers, 'repeat:',key.repeated)
  if (key.modifiers == "" and key.name == "esc") then
    row_frequency_size = renoise.song().transport.edit_step
    toggle_midi_record()
    top_tab_arming_toggle()
    set_cursor_location()

  elseif (key.modifiers == "" and (key.name == "return" or key.name == "numpad enter")) then
    if tab_states.top == 2 then
      figure_pos = 1
      jump_edit_step(JUMP_FORWARD)
    end

  elseif (key.modifiers == "" and key.name == "home") then
    if tab_states.top == 2 then
      figure_pos = 1
      env_current_line.row = 0
      line_position_offset = 0
      set_cursor_location()
    end
  elseif (key.modifiers == "control" and key.name == "u") or
         (key.modifiers == "command" and key.name == "u") then
    if #undo_descriptions > 0 then
      undo_management()
    end
    
  elseif (key.modifiers == "control" and key.name == "c") or
         (key.modifiers == "command" and key.name == "c") then
      sf_display()
        
  elseif (key.modifiers == "control" and key.name == "end") or
         (key.modifiers == "command" and key.name == "end") then
    if tab_states.top == 2 then
      jump_to_last_point()
    end

  elseif (key.modifiers == "" and key.name == "end") then
    if tab_states.top == 2 then
      jump_to_end_marker()
    end
    
  elseif (key.modifiers == "" and key.name == "next") then
    if tab_states.top == 1 then
      if tab_states.sub == 1 then
        switch_note_pattern_index = NOTE_PATTERN_CUSTOM
        ea_gui.views.switch_note_pattern.value = NOTE_PATTERN_CUSTOM
        toggle_note_profile_visibility(true, ea_gui)
      end

    elseif tab_states.top == 2 then
      jump_ten_points(JUMP_FORWARD)
    end
    
  elseif (key.modifiers == "" and key.name == "prior") then
    if tab_states.top == 1 then
      if tab_states.sub == 1 then
        switch_note_pattern_index = NOTE_PATTERN_MATRIX
        ea_gui.views.switch_note_pattern.value = NOTE_PATTERN_MATRIX
        toggle_note_profile_visibility(false, ea_gui)
      end

    elseif tab_states.top == 2 then
      jump_ten_points(JUMP_BACKWARD)
    end
  elseif (key.modifiers == "" and string.sub(key.name,1,6) == "numpad") then
    local np_key = string.gsub(key.name, "numpad ", "")
    
    if (np_key == "/") then
      if renoise.song().transport.octave >0 then
        renoise.song().transport.octave = renoise.song().transport.octave - 1
      end
    elseif (np_key == "*") then
      if renoise.song().transport.octave < 8 then
        renoise.song().transport.octave = renoise.song().transport.octave +1
      end
    end
    for t = 0, 9 do
      if (np_key == tostring(t)) then
        if env_current_line.col == ENV_NOTE_COLUMN then
          handle_note_value_input(np_key)
        else
          vol_pan_input_handler(key)
        end
      end
    end    
    if np_key == "-" then
      if env_current_line.col == ENV_NOTE_COLUMN  then
        handle_note_value_input(np_key)
      else
        vol_pan_input_handler(key)
      end
    end

  elseif (key.modifiers == "" and key.name == "f5") then
    row_frequency_size = renoise.song().transport.edit_step
    toggle_midi_record()
    top_tab_arming_toggle()
    set_cursor_location()

  elseif (key.modifiers == "control" and key.name == "up") or
         (key.modifiers == "command" and key.name == "up") then
    if tab_states.top == 2 then
      figure_pos = 1
      jump_edit_step(JUMP_BACKWARD)
    end
    
  elseif (key.modifiers == "" and key.name == "up") then
    if tab_states.top == 2 then
      jump_cell(JUMP_BACKWARD)
    end

  elseif (key.modifiers == "control" and key.name == "down") or
         (key.modifiers == "command" and key.name == "down") then
    if tab_states.top == 2 then
      figure_pos = 1
      jump_edit_step(JUMP_FORWARD)
    end
    
  elseif (key.modifiers == "" and key.name == "down") then
    if tab_states.top == 2 then
      jump_cell(JUMP_FORWARD)
    end

  elseif (key.modifiers == "" and key.name == "left") then
    if tab_states.top == 2 then
      jump_cell(JUMP_LEFT)
    end

  elseif (key.modifiers == "" and key.name == "right") then
    if tab_states.top == 2 then
      jump_cell(JUMP_RIGHT)
    end

  elseif (key.modifiers == "control" and key.name == "tab") or
         (key.modifiers == "command" and key.name == "tab") then
    if tab_states.sub < sub_tabs_bound then
      tab_states.sub = tab_states.sub + 1
    else
      tab_states.sub = 1
    end
    set_selected_tab("sub_tab_",tab_states.sub, sub_tabs_bound)
    set_visible_area()

  elseif (key.modifiers == "control" and key.name == "s") or
         (key.modifiers == "command" and key.name == "s") then
    if tab_states.top == 2 then
      set_sustain_marker()
    end

  elseif (key.modifiers == "shift" and key.name == "s") then
    if tab_states.top == 2 then
      set_loop_marker(LOOP_START)
    end
      
  elseif (key.modifiers == "shift" and key.name == "e") then
    if tab_states.top == 2 then
      set_loop_marker(LOOP_END)
    end

  elseif (key.modifiers == "shift + control" and key.name == "tab") or
         (key.modifiers == "shift + command" and key.name == "tab") then
    if tab_states.sub > 1 then
      tab_states.sub = tab_states.sub - 1
    else
      tab_states.sub = sub_tabs_bound
    end
    set_selected_tab("sub_tab_",tab_states.sub, sub_tabs_bound)
    set_visible_area()
    
  elseif (key.modifiers == "" and key.name == "a") then
    if tab_states.top == 2 then
      set_end_marker()
    end     
    
  elseif (key.modifiers == "" and key.name == "del") or 
         (key.modifiers == "shift" and key.name == "back") then
    if tab_states.top == 2 then
      clear_cell()
    end
    
  elseif (key.modifiers == "" and key.name == "back") then
    if env_current_line.col == ENV_NOTE_COLUMN and not note_mode then
      handle_note_value_input(key.name)
    else
      vol_pan_input_handler(key)
    end
    
  elseif (key.modifiers == "control" and key.character ~= nil) or
         (key.modifiers == "command" and key.character ~= nil) then
    set_renoise_edit_step(key)
    
  elseif (key.modifiers == "" and key.note) then
    if note_mode then
      handle_note(key)
    elseif env_current_line.col == ENV_NOTE_COLUMN then 
      handle_note_value_input(key.character)
    end

    if env_current_line.col == ENV_NOTE_COLUMN then
      return key
    else
      vol_pan_input_handler(key)
    end
    
  elseif key.character ~= nil then
    if env_current_line.col == ENV_VOL_COLUMN or env_current_line.col == ENV_PAN_COLUMN then
      vol_pan_input_handler(key)
    else
      handle_note_value_input(key.character)
    end
    
  elseif key.modifiers == "control" or key.modifiers == "command" then
           key_state = bit.bor(LCMD,key_state)
           if key.repeated == true then
            key_state_time_out = os.clock()
           else
            key_state_time_out = os.clock() + 1
           end
           set_button_states()
           
  elseif key.name == "rcontrol"  or key.name == "rcommand" then
           key_state = bit.bor(RCMD,key_state)
           key_state_time_out = os.clock()
           set_button_states()

  elseif key.modifiers == "shift" then
           key_state = bit.bor(LCAP,key_state)
           if key.repeated == true then
            key_state_time_out = os.clock()
           else
            key_state_time_out = os.clock() + 1
           end
           set_button_states()

  elseif key.name == "rshift" then
           key_state = bit.bor(RCAP,key_state)
           key_state_time_out = os.clock()
           set_button_states()

  elseif key.modifiers == "alt" then
           key_state = bit.bor(LALT,key_state)
           if key.repeated == true then
            key_state_time_out = os.clock()
           else
            key_state_time_out = os.clock() + 1
           end
           set_button_states()

  elseif key.name == "ralt" then
           key_state = bit.bor(RALT,key_state)
           key_state_time_out = os.clock()
           set_button_states()
  end

end  




---------------------------------------------------------------------------------------

function set_renoise_edit_step(key)
  local kchar = key.character
  if string.len(kchar) == 0 then
    key.character = key.name
  end
  if tonumber(key.character) ~= nil then
    if tonumber(key.character) >=0 and tonumber(key.character) <= 9 then
      renoise.song().transport.edit_step = tonumber(key.character)
    end
  end
  if key.character == '-' then
    renoise.song().transport.edit_step = renoise.song().transport.edit_step - 1
  elseif key.character == '=' or key.character == '+' then
    renoise.song().transport.edit_step = renoise.song().transport.edit_step + 1
  end     

end

---------------------------------------------------------------------------------------


function handle_note(key)
--A note key has been pressed on the keyboard.
--Where to put it? 
--in the note matrix? the custom note field or the envelope sequence cell?

  local cur_octave = renoise.song().transport.octave
  local fnote = key_matrix[key.note % NUM_NOTES + 1] .. 
        tostring(cur_octave + math.floor(key.note / NUM_NOTES))
  local rnote = note_matrix[key.note % NUM_NOTES + 1] .. 
        tostring(cur_octave + math.floor(key.note / NUM_NOTES))

  if string.len(rnote) <3 then
    rnote = string.sub(rnote,1,1)..'-'..string.sub(rnote,2,2)
  end

  if midi_record_mode then
    if tab_states.top == 1 then
      if switch_note_pattern_index == NOTE_PATTERN_MATRIX then
        if (ea_gui.views[fnote]) then
          ea_gui.views[fnote].value = not ea_gui.views[fnote].value
        end
      else
        --Fill custom note pattern
        fnote = string.gsub(fnote, "f", "#")
        fnote = string.gsub(fnote, "_", "-")
        if tonumber(string.sub(fnote,3)) < 10 then
          if string.len(ea_gui.views['custom_note_profile'].value) < 3 then
            ea_gui.views['custom_note_profile'].value = fnote
          else
            ea_gui.views['custom_note_profile'].value = 
            ea_gui.views['custom_note_profile'].value..','..fnote
          end          
        end
          
      end
    elseif tab_states.top == 2 then
      if env_current_line.col == ENV_NOTE_COLUMN then

        local cell_row = env_current_line.row + line_position_offset
        if env_current_line.col == 1 then
          if note_mode and (key.note+((cur_octave-4)*12)) <= 71 then
            catched_midi_note = 12
            env_note_value[cell_row] = key.note - catched_midi_note
            jump_edit_step(JUMP_FORWARD)
            set_pitch_table()
          end
        end
      end
    end
  end

end


---------------------------------------------------------------------------------------


function handle_note_value_input(key)
  if tab_states.top == 2 then
    local cell_row = env_current_line.row + line_position_offset
    local col_number = "0"
    if note_mode then
      return
    end
    if midi_record_mode then
      for x = 0, 9 do
        if key == tostring(x) then
          col_number = tostring(env_note_value[cell_row])
          if col_number == "9999" or col_number == "2555" or col_number == nil then
            col_number = ""
          end
          if string.len(col_number) > 0 then
            if ea_gui.views['env_multiplier'].value == ENV_X100 then
              if string.len(col_number) < 3 and tonumber(col_number) < 0 then
                col_number = col_number..key
                if tonumber(col_number) < -12 then
                  col_number = -12
                end
                if string.len(col_number) == 3 then
                  jump_edit_step(JUMP_FORWARD)
                end
              elseif string.len(col_number) < 2 and tonumber(col_number) >= 0 then
                col_number = col_number..key
                if tonumber(col_number) > 12 then
                  col_number = 12
                end
                if string.len(col_number) == 2 then
                  jump_edit_step(JUMP_FORWARD)
                end
              else
                env_note_value[cell_row] = tonumber(col_number)
                jump_edit_step(JUMP_FORWARD)
              end
            end
            
            if ea_gui.views['env_multiplier'].value == ENV_X10 then
              if string.len(col_number) < 4 and tonumber(col_number) < 0 then
                col_number = col_number..key
                if tonumber(col_number) < -120 then
                  col_number = -120
                end
                if string.len(col_number) == 4 then
                  env_note_value[cell_row] = tonumber(col_number)
                  jump_edit_step(JUMP_FORWARD)
                end
              elseif string.len(col_number) < 3 and tonumber(col_number) >= 0 then
                col_number = col_number..key
                if tonumber(col_number) > 120 then
                  col_number = 120
                end
                if string.len(col_number) == 3 then
                  env_note_value[cell_row] = tonumber(col_number)
                  jump_edit_step(JUMP_FORWARD)
                end
              else
                col_number = tonumber(col_number)
                jump_edit_step(JUMP_FORWARD)
              end
            end

            if ea_gui.views['env_multiplier'].value == ENV_X1 then
              if string.len(col_number) < 5 and tonumber(col_number) < 0 then
                col_number = col_number..key
                if tonumber(col_number) < -1200 then
                  col_number = -1200
                end
                if string.len(col_number) == 5 then
                  env_note_value[cell_row] = tonumber(col_number)
                  jump_edit_step(JUMP_FORWARD)
                end
              elseif string.len(col_number) < 4 and tonumber(col_number) >= 0 then
                col_number = col_number..key
                if tonumber(col_number) > 1200 then
                  col_number = 1200
                end
                if string.len(col_number) == 4 then
                  env_note_value[cell_row] = tonumber(col_number)
                  jump_edit_step(JUMP_FORWARD)
                end
              else
                jump_edit_step(JUMP_FORWARD)
              end
            end
          else
            col_number = col_number..key
          end
          env_note_value[cell_row] = tonumber(col_number)
          
         break
        end
      end
      
      if key == "-" and tonumber(env_note_value[cell_row]) >= -1200 and 
         tonumber(env_note_value[cell_row]) <= 1200 then
--        if env_vol_value[cell_row] < 0 then
          env_note_value[cell_row] = 0-tonumber(env_note_value[cell_row])
  --      end
      end
      if key == "back" and string.len(env_note_value[cell_row]) >= 0 then
        col_number = env_note_value[cell_row]
        if col_number ~= "9999" and col_number ~= "2555" and col_number ~= nil then
          col_number = string.sub(col_number,1,string.len(col_number)-1)
        end
        if col_number == "" or col_number == "-" then
          env_note_value[cell_row] = "9999"
        else
          env_note_value[cell_row] = col_number
        end
      end
      populate_columns()
        
    end

  end
end
---------------------------------------------------------------------------------------

function send_midi_messages(fnote,midi_note_val)
--  print(fnote,midi_note_val)
  if ea_gui.views['profile_selection'].visible == true then
    if switch_note_pattern_index == NOTE_PATTERN_MATRIX then
      if fnote ~= nil then
        fnote = string.gsub(fnote, "#", "f")
        fnote = string.gsub(fnote, "-", "_")
        if (ea_gui.views[fnote]) then
          ea_gui.views[fnote].value = not ea_gui.views[fnote].value
        end            
      end
    else
      if fnote ~= nil then
        if string.len(ea_gui.views['custom_note_profile'].value) < 3 then
          ea_gui.views['custom_note_profile'].value = fnote
        else
          ea_gui.views['custom_note_profile'].value = 
          ea_gui.views['custom_note_profile'].value..','..fnote
        end
      end
    end
  end
  if ea_gui.views['envelope_profile'].visible == true then
    local cell_row = env_current_line.row + line_position_offset
--    if catched_midi_note == -1 then
--      catched_midi_note = midi_note_val
      catched_midi_note = 48
--    end
    if env_current_line.col == 1 and (midi_note_val - catched_midi_note) >= -12 and 
       (midi_note_val - catched_midi_note) <= 12 then    
       
      env_note_value[cell_row] = midi_note_val - catched_midi_note    
      jump_edit_step(JUMP_FORWARD)
    end
    set_pitch_table()    
  end
    
end

--------------------------------------------------------------------------------
-- dialog visibility toggles
--------------------------------------------------------------------------------

function clear_cell()
  figure_pos = 1
  local cell_row = env_current_line.row + line_position_offset
  if env_current_line.col == ENV_NOTE_COLUMN then
    if midi_record_mode then
      env_note_value[cell_row] = EMPTY_CELL
    end

  elseif env_current_line.col == ENV_VOL_COLUMN then
    if midi_record_mode then
      env_vol_value[cell_row] = EMPTY_CELL
    end

  elseif env_current_line.col == ENV_PAN_COLUMN then
    if midi_record_mode then
      env_pan_value[cell_row] = EMPTY_CELL
    end
  end

  if midi_record_mode then
    --Jump to the next edit step
      jump_edit_step(JUMP_FORWARD)
  end

  set_cursor_location()
  set_pitch_table()  
end

---------------------------------------------------------------------------------------

function vol_pan_input_handler(key)
  if tab_states.top == 2 then
    local cell_row = env_current_line.row + line_position_offset
    local col_number = "0"
    local key_stroke = key.character
    
    if midi_record_mode then
      for x = 0, 9 do
        if key_stroke == tostring(x) then
              
          if env_current_line.col == ENV_VOL_COLUMN then
            col_number = tostring(env_vol_value[cell_row])

          elseif env_current_line.col == ENV_PAN_COLUMN then
            col_number = tostring(env_pan_value[cell_row])
          end  

          if figure_pos == 1 then
            col_number = "00"
            col_number = key.character..string.sub(col_number,2,2)
            figure_pos = 2

          elseif figure_pos == 2 then
            if col_number == ".." or col_number == "<>" then
              col_number = "00"
            end

            if string.sub(col_number,1,1) ~= '-' then
              col_number = string.sub(col_number,1,1)..key.character
            else
              col_number = '-'..string.sub(col_number,2,2)..key.character
            end

            if env_current_line.col == ENV_VOL_COLUMN then
              figure_pos = 3

            elseif env_current_line.col == ENV_PAN_COLUMN then
              figure_pos = 1
              jump_edit_step(JUMP_FORWARD)
            end  

          elseif figure_pos == 3 then
            if col_number == ".." or col_number == "<>" then
              col_number = "00"
            end
            col_number = string.sub(col_number,1,2)..key.character
            jump_edit_step(JUMP_FORWARD)
          end

          if env_current_line.col == ENV_VOL_COLUMN then
            env_vol_value[cell_row] = tonumber(col_number)

          elseif env_current_line.col == ENV_PAN_COLUMN then
            if env_pan_value[cell_row] < 0 and tonumber(col_number) > 0 then
              col_number = "-"..col_number
            end
            env_pan_value[cell_row] = tonumber(col_number)
          end

          break
        end
      end
      local col_number = ""
      if env_current_line.col == ENV_VOL_COLUMN then
        if tonumber(env_vol_value[cell_row]) > 100 then
          env_vol_value[cell_row] = 100
          figure_pos = 1
        end
        col_number = tostring(env_vol_value[cell_row])
      elseif env_current_line.col == ENV_PAN_COLUMN then
        if env_pan_value[cell_row] ~= nil then
          if tonumber(env_pan_value[cell_row]) > 50 then
            env_pan_value[cell_row] = 50
            figure_pos = 1
          elseif tonumber(env_pan_value[cell_row]) < -50 then
            env_pan_value[cell_row] = -50
            figure_pos = 1
          end
        end
        col_number = tostring(env_pan_value[cell_row])
      end

      if env_current_line.col == ENV_PAN_COLUMN then
        if key.character == "-" then
          figure_pos = 1
          env_pan_value[cell_row] = 0 - env_pan_value[cell_row]
          col_number = tostring(env_pan_value[cell_row])
        end
        
      end

      if key.name == "back" and string.len(col_number) >= 0 then
        if col_number ~= "9999" and col_number ~= "256" and col_number ~= nil then
          col_number = string.sub(col_number,1,string.len(col_number)-1)
        end
        if col_number == "" or col_number == "-" then
          col_number = "9999"
        end
      end      
      if env_current_line.col == ENV_VOL_COLUMN then
        env_vol_value[cell_row] = tonumber(col_number)
      elseif env_current_line.col == ENV_PAN_COLUMN then
        env_pan_value[cell_row] = tonumber(col_number)
      end
      
      populate_columns()
        
    end

  end
end

---------------------------------------------------------------------------------------


function set_end_marker()
  local cell_row = env_current_line.row + line_position_offset

  if env_current_line.col == ENV_NOTE_COLUMN then
    if midi_record_mode then
      for t = 0, MAXIMUM_FRAME_LENGTH do
        if tonumber(env_note_value[t]) == NOTE_SCHEME_TERMINATION then
          env_note_value[t] = EMPTY_CELL
              
        end
      end
      if note_loop_start > cell_row then
        note_loop_start = cell_row
      end
      if note_loop_end > cell_row then
        note_loop_end = cell_row
      end
      if note_sustain > cell_row then
        note_sustain = cell_row
      end

      note_scheme_size = cell_row

      if note_scheme_size < MINIMUM_FRAME_LENGTH then
        note_scheme_size = MINIMUM_FRAME_LENGTH
      end

      env_note_value[note_scheme_size] = NOTE_SCHEME_TERMINATION
    end

  elseif env_current_line.col == ENV_VOL_COLUMN then
    if midi_record_mode then
      for t = 0, MAXIMUM_FRAME_LENGTH do
        if tonumber(env_vol_value[t]) == VOL_PAN_TERMINATION then
          env_vol_value[t] = EMPTY_CELL
              
        end
      end
      if vol_loop_start > cell_row then
        vol_loop_start = cell_row
      end
      if vol_loop_end > cell_row then
        vol_loop_end = cell_row
      end
      if vol_sustain > cell_row then
        vol_sustain = cell_row
      end

      vol_scheme_size = cell_row

      if vol_scheme_size < MINIMUM_FRAME_LENGTH then
        vol_scheme_size = MINIMUM_FRAME_LENGTH
      end

      env_vol_value[vol_scheme_size] = VOL_PAN_TERMINATION

    end
  elseif env_current_line.col == ENV_PAN_COLUMN then
    if midi_record_mode then
      for t = 0, MAXIMUM_FRAME_LENGTH do
        if tonumber(env_pan_value[t]) == VOL_PAN_TERMINATION then
          env_pan_value[t] = EMPTY_CELL
              
        end
      end
      if pan_loop_start > cell_row then
        pan_loop_start = cell_row
      end
      if pan_loop_end > cell_row then
        pan_loop_end = cell_row
      end
      if pan_sustain > cell_row then
        pan_sustain = cell_row
      end

      pan_scheme_size = cell_row

      if pan_scheme_size < MINIMUM_FRAME_LENGTH then
        pan_scheme_size = MINIMUM_FRAME_LENGTH
      end

      env_pan_value[pan_scheme_size] = VOL_PAN_TERMINATION

    end
      
  end    
  set_cursor_location()
  set_pitch_table()

end

---------------------------------------------------------------------------------------


function set_loop_marker(marker)
  if marker == LOOP_START then

    if env_current_line.col == ENV_NOTE_COLUMN then
  
      if note_loop_start ~= env_current_line.row + line_position_offset then
        note_loop_start = env_current_line.row + line_position_offset
      else
        note_loop_start = -1
      end
      if note_loop_start > note_loop_end and note_loop_end > -1 then
        note_loop_start = note_loop_end 
      end
      if note_loop_end > note_scheme_size then
        note_loop_end = note_scheme_size
      end
      if note_loop_start > note_scheme_size then
        note_loop_start = note_scheme_size
      end
          
    elseif env_current_line.col == ENV_VOL_COLUMN then
  
      if vol_loop_start ~= env_current_line.row + line_position_offset then
        vol_loop_start = env_current_line.row + line_position_offset
      else
        vol_loop_start = -1
      end
      if vol_loop_start > vol_loop_end and vol_loop_end > -1 then
        vol_loop_start = vol_loop_end
      end
  
    else
  
      if pan_loop_start ~= env_current_line.row + line_position_offset then
        pan_loop_start = env_current_line.row + line_position_offset
      else
        pan_loop_start = -1
      end
      if pan_loop_start > pan_loop_end and pan_loop_end > -1 then
        pan_loop_start = pan_loop_end 
      end
  
    end

  else

    if env_current_line.col == ENV_NOTE_COLUMN then

      if note_loop_end ~= env_current_line.row + line_position_offset then
        note_loop_end = env_current_line.row + line_position_offset
      else
        note_loop_end = -1
      end
      if note_loop_end < note_loop_start  and note_loop_end > -1 then
        note_loop_end = note_loop_start 
      end
      if note_loop_end > note_scheme_size then
        note_loop_end = note_scheme_size 
      end
      if note_loop_start > note_scheme_size then
        note_loop_start = note_scheme_size
      end
        
    elseif env_current_line.col == ENV_VOL_COLUMN then

      if vol_loop_end ~= env_current_line.row + line_position_offset then
        vol_loop_end = env_current_line.row + line_position_offset
      else
        vol_loop_end = -1
      end
      if vol_loop_end < vol_loop_start  and vol_loop_end > -1 then
        vol_loop_end = vol_loop_start
      end

    else

      if pan_loop_end ~= env_current_line.row + line_position_offset then
        pan_loop_end = env_current_line.row + line_position_offset
      else
        pan_loop_end = -1
      end
      if pan_loop_end < pan_loop_start and pan_loop_end > -1 then
        pan_loop_end = pan_loop_start
      end

    end

  end      
  configure_envelope_loop()
  set_cursor_location()
end

---------------------------------------------------------------------------------------

function set_sustain_marker()
  if env_current_line.col == ENV_NOTE_COLUMN then
    if note_sustain ~= env_current_line.row + line_position_offset then
      note_sustain = env_current_line.row + line_position_offset
    else
      note_sustain = -1
    end
    if note_sustain > note_scheme_size then
      note_sustain = note_scheme_size
    end
        
  elseif env_current_line.col == ENV_VOL_COLUMN then
    if vol_sustain ~= env_current_line.row + line_position_offset then
      vol_sustain = env_current_line.row + line_position_offset
    else
      vol_sustain = -1
    end
  else
    if pan_sustain ~= env_current_line.row + line_position_offset then
      pan_sustain = env_current_line.row + line_position_offset
    else
      pan_sustain = -1
    end
  end
  if env_auto_apply then
    apply_table_to_envelope()
  end
  set_cursor_location()

end

---------------------------------------------------------------------------------------

function jump_cell(direction)
  figure_pos = 1

  if direction == JUMP_FORWARD then
    if env_current_line.row < visible_lines-1 then
      env_current_line.row = env_current_line.row + 1
    else
      line_position_offset = line_position_offset + 1
      if line_position_offset + visible_lines > 1001 then
        line_position_offset = 1001 - visible_lines
      end
    end
  elseif direction == JUMP_BACKWARD then
    if env_current_line.row > 0 then
      env_current_line.row = env_current_line.row -1
    else
      line_position_offset = line_position_offset - 1
      if line_position_offset < 0 then
        line_position_offset = 0
      end
    end
  elseif direction == JUMP_LEFT then
    if env_current_line.col > 1 then
      env_current_line.col = env_current_line.col -1
    else 
      env_current_line.col = 3
    end
  elseif direction == JUMP_RIGHT then
    if env_current_line.col < 3 then
      env_current_line.col = env_current_line.col + 1
    else
      env_current_line.col = 1
    end  
  end
  set_cursor_location()

end

---------------------------------------------------------------------------------------

function jump_ten_points(direction)
  figure_pos = 1
  if direction == JUMP_FORWARD then
    if env_current_line.row < visible_lines-10 then
      env_current_line.row = env_current_line.row + 10
    else
      line_position_offset = line_position_offset + 10
      if line_position_offset + visible_lines > 1001 then
        line_position_offset = 1001 - visible_lines
        env_current_line.row = visible_lines-1
      end
    end
  else
    if env_current_line.row -10 > 0 then
      env_current_line.row = env_current_line.row -10
    else
      line_position_offset = line_position_offset - 10
      if line_position_offset < 0 then
        line_position_offset = 0
        env_current_line.row = 0
      end
    end  
  end
  set_cursor_location()

end

---------------------------------------------------------------------------------------

function jump_to_last_point()
  figure_pos = 1
  line_position_offset = 1001 - visible_lines        
  env_current_line.row = visible_lines - 1         
  set_cursor_location()
end

---------------------------------------------------------------------------------------

function jump_to_end_marker()
  figure_pos = 1

  if env_current_line.col == ENV_NOTE_COLUMN then
    if note_scheme_size < visible_lines  then
      line_position_offset = 0
      env_current_line.row = note_scheme_size 
    else
      line_position_offset = note_scheme_size - (visible_lines - 1)
      env_current_line.row = visible_lines - 1
    end

  elseif env_current_line.col == ENV_VOL_COLUMN then
    if vol_scheme_size < visible_lines  then
      line_position_offset = 0
      env_current_line.row = vol_scheme_size 
    else
      line_position_offset = vol_scheme_size - (visible_lines - 1)
      env_current_line.row = visible_lines - 1
    end
  
  elseif env_current_line.col == ENV_PAN_COLUMN then
    if pan_scheme_size < visible_lines  then
      line_position_offset = 0
      env_current_line.row = pan_scheme_size 
    else
      line_position_offset = pan_scheme_size - (visible_lines - 1)
      env_current_line.row = visible_lines - 1
    end

  end

  set_cursor_location()
  
end

---------------------------------------------------------------------------------------

function jump_edit_step(direction)
  local next_row = row_frequency_size

  if row_frequency_step == FREQ_TYPE_LINES then
    next_row = next_row * sample_envelope_line_sync()
  end

  local prev_pos = env_current_line.row
  if direction == 1 then
    local next_pos = env_current_line.row + next_row

    if next_pos + line_position_offset < 1001 then
      local line_factor = next_pos / visible_lines
      local pages = math.floor(line_factor)      
  
      if next_pos > visible_lines-1 then
        line_position_offset = line_position_offset + (pages*visible_lines) 
        env_current_line.row = next_pos - (pages*visible_lines) 
      else
        env_current_line.row = next_pos
      end
    else
      line_position_offset = 1001 - visible_lines
      env_current_line.row = visible_lines - 1  
    end      
  else
    local next_pos = env_current_line.row - next_row
    if next_pos + line_position_offset >= 0 then
      local line_factor = (next_pos / visible_lines)
      local pages = math.floor(line_factor)      
      if next_pos < 0 then
        env_current_line.row = env_current_line.row +line_position_offset - next_row
        line_position_offset = line_position_offset + (pages*visible_lines) 
        env_current_line.row = env_current_line.row - line_position_offset
      else
        env_current_line.row = next_pos
      end
    else
      line_position_offset = 0
      env_current_line.row = 0
    end
  end

  set_cursor_location()    
end


---------------------------------------------------------------------------------------


function populate_columns()
  for t = 0,visible_lines-1 do
    local cell_pos = t+line_position_offset
    
    if tonumber(env_note_value[cell_pos]) ~= EMPTY_CELL and env_note_value[cell_pos] ~= nil and env_note_value[cell_pos] ~= 'nil' and
       tonumber(env_note_value[cell_pos]) ~= NOTE_SCHEME_TERMINATION then
      if note_mode then
        if string.sub(env_note_value[cell_pos],1,1) ~= '[' and env_note_value[cell_pos] ~= nil then
          --Some strange bug causing this function to be called with a note_value containing decimals
          --had to hack-fix it with a math.floor as i was never capable of tracking the root of this problem.
          ea_gui.views['note_pos_'..tostring(t)].text=midi_notes[math.floor(tonumber(env_note_value[cell_pos]))+48]
        else
          local temp_val = env_note_value[cell_pos]
          temp_val = math.round(tonumber(string.sub(temp_val,2,string.len(temp_val)-1)))
          
          ea_gui.views['note_pos_'..tostring(t)].text='['..midi_notes[temp_val+48]..']'
        end
        
      else
        ea_gui.views['note_pos_'..tostring(t)].text=tostring(env_note_value[cell_pos])
      end
    else
      if note_mode then
        if tonumber(env_note_value[cell_pos]) == NOTE_SCHEME_TERMINATION then
          ea_gui.views['note_pos_'..tostring(t)].text="<->"
        else
          ea_gui.views['note_pos_'..tostring(t)].text="---"
        end
      else
        if tonumber(env_note_value[cell_pos]) == NOTE_SCHEME_TERMINATION then
          ea_gui.views['note_pos_'..tostring(t)].text="<.>"
        else
          ea_gui.views['note_pos_'..tostring(t)].text=".."
        end
      end
      
    end

    if tonumber(env_vol_value[cell_pos]) ~= EMPTY_CELL and env_vol_value[cell_pos] ~= nil and
       tonumber(env_vol_value[cell_pos]) ~= VOL_PAN_TERMINATION then
      ea_gui.views['vol_pos_'..tostring(t)].text=tostring(env_vol_value[cell_pos])
    else
      if tonumber(env_vol_value[cell_pos]) == VOL_PAN_TERMINATION then
        ea_gui.views['vol_pos_'..tostring(t)].text="<>"
      else
        ea_gui.views['vol_pos_'..tostring(t)].text=".."
      end
    end

    if tonumber(env_pan_value[cell_pos]) ~= EMPTY_CELL and env_pan_value[cell_pos] ~= nil and
       tonumber(env_pan_value[cell_pos]) ~= VOL_PAN_TERMINATION then
      ea_gui.views['pan_pos_'..tostring(t)].text=tostring(env_pan_value[cell_pos])
    else
      if tonumber(env_pan_value[cell_pos]) == VOL_PAN_TERMINATION then
        ea_gui.views['pan_pos_'..tostring(t)].text="<>"
      else
        ea_gui.views['pan_pos_'..tostring(t)].text=".."
      end
    end

  end
end


---------------------------------------------------------------------------------------

function set_cursor_location()
  local cursor_color = CURSOR_POS_COLOR
  if midi_record_mode then
    cursor_color = CURSOR_POS_EDIT_COLOR
  end
  for t = 0, visible_lines-1 do
    note_pos_color[t] = COLOR_UNSELECTED
    vol_pos_color[t] = COLOR_UNSELECTED
    pan_pos_color[t] = COLOR_UNSELECTED
    if line_position_offset + t == note_loop_start then
      if note_pos_color[t] ~= COLOR_UNSELECTED then
        local high = bit.bxor(note_pos_color[t][1],LOOP_START_COLOR[1])
        local mid = bit.bxor(note_pos_color[t][2],LOOP_START_COLOR[2])
        local low = bit.bxor(note_pos_color[t][3],LOOP_START_COLOR[3])
        note_pos_color[t] = {high,mid,low}
      else
        note_pos_color[t] = LOOP_START_COLOR
      end
    end
    if line_position_offset + t == note_loop_end then
      if note_pos_color[t] ~= COLOR_UNSELECTED then
        local high = bit.bxor(note_pos_color[t][1],LOOP_END_COLOR[1])
        local mid = bit.bxor(note_pos_color[t][2],LOOP_END_COLOR[2])
        local low = bit.bxor(note_pos_color[t][3],LOOP_END_COLOR[3])
        note_pos_color[t] = {high,mid,low}
      else
        note_pos_color[t] = LOOP_END_COLOR
      end
    end
    if line_position_offset + t == vol_loop_start then
      if vol_pos_color[t] ~= COLOR_UNSELECTED then
        local high = bit.bxor(vol_pos_color[t][1],LOOP_START_COLOR[1])
        local mid = bit.bxor(vol_pos_color[t][2],LOOP_START_COLOR[2])
        local low = bit.bxor(vol_pos_color[t][3],LOOP_START_COLOR[3])
        vol_pos_color[t] = {high,mid,low}
      else
        vol_pos_color[t] = LOOP_START_COLOR
      end
    end
    if line_position_offset + t == vol_loop_end then
      if vol_pos_color[t] ~= COLOR_UNSELECTED then
        local high = bit.bxor(vol_pos_color[t][1],LOOP_END_COLOR[1])
        local mid = bit.bxor(vol_pos_color[t][2],LOOP_END_COLOR[2])
        local low = bit.bxor(vol_pos_color[t][3],LOOP_END_COLOR[3])
        vol_pos_color[t] = {high,mid,low}
      else
        vol_pos_color[t] = LOOP_END_COLOR
      end
    end
    if line_position_offset + t == pan_loop_start then
      if pan_pos_color[t] ~= COLOR_UNSELECTED then
        local high = bit.bxor(pan_pos_color[t][1],LOOP_START_COLOR[1])
        local mid = bit.bxor(pan_pos_color[t][2],LOOP_START_COLOR[2])
        local low = bit.bxor(pan_pos_color[t][3],LOOP_START_COLOR[3])
        pan_pos_color[t] = {high,mid,low}
      else
        pan_pos_color[t] = LOOP_START_COLOR
      end
    end
    if line_position_offset + t == pan_loop_end then
      if pan_pos_color[t] ~= COLOR_UNSELECTED then
        local high = bit.bxor(pan_pos_color[t][1],LOOP_END_COLOR[1])
        local mid = bit.bxor(pan_pos_color[t][2],LOOP_END_COLOR[2])
        local low = bit.bxor(pan_pos_color[t][3],LOOP_END_COLOR[3])
        pan_pos_color[t] = {high,mid,low}
      else
        pan_pos_color[t] = LOOP_END_COLOR
      end
    end

    if line_position_offset + t == note_sustain then
      if note_pos_color[t] ~= COLOR_UNSELECTED then
        local high = bit.bxor(note_pos_color[t][1],SUSTAIN_COLOR[1])
        local mid = bit.bxor(note_pos_color[t][2],SUSTAIN_COLOR[2])
        local low = bit.bxor(note_pos_color[t][3],SUSTAIN_COLOR[3])
        note_pos_color[t] = {high,mid,low}
      else
        note_pos_color[t] = SUSTAIN_COLOR
      end
    end

    if line_position_offset + t == vol_sustain then
      if vol_pos_color[t] ~= COLOR_UNSELECTED then
        local high = bit.bxor(vol_pos_color[t][1],SUSTAIN_COLOR[1])
        local mid = bit.bxor(vol_pos_color[t][2],SUSTAIN_COLOR[2])
        local low = bit.bxor(vol_pos_color[t][3],SUSTAIN_COLOR[3])
        vol_pos_color[t] = {high,mid,low}
      else
        vol_pos_color[t] = SUSTAIN_COLOR
      end
    end

    if line_position_offset + t == pan_sustain then
      if pan_pos_color[t] ~= COLOR_UNSELECTED then
        local high = bit.bxor(pan_pos_color[t][1],SUSTAIN_COLOR[1])
        local mid = bit.bxor(pan_pos_color[t][2],SUSTAIN_COLOR[2])
        local low = bit.bxor(pan_pos_color[t][3],SUSTAIN_COLOR[3])
        pan_pos_color[t] = {high,mid,low}
      else
        pan_pos_color[t] = SUSTAIN_COLOR
      end
    end
  end

  if env_current_line.col == 1 then
    note_pos_color[env_current_line.row]= cursor_color
  elseif env_current_line.col == 2 then
    vol_pos_color[env_current_line.row]= cursor_color
  else
    pan_pos_color[env_current_line.row]= cursor_color
  end
  for t = 0, visible_lines-1 do
    local env_edit_pos = t+line_position_offset
    ea_gui.views['note_pos_'..tostring(t)].color = note_pos_color[t]
    ea_gui.views['vol_pos_'..tostring(t)].color = vol_pos_color[t]
    ea_gui.views['pan_pos_'..tostring(t)].color = pan_pos_color[t]
    ea_gui.views['track_position_'..tostring(t)].text = string.format("%04d", env_edit_pos)
  end
  populate_columns()
end


---------------------------------------------------------------------------------------


function set_button_states()
--depending on which modifier key has been pressed, some buttons get a 
--special click option, the state-color should be changed for it though.
  if key_state == LCAP or key_state == RCAP then
    if env_auto_apply == false then
      ea_gui.views['env_auto_apply'].color = bool_button[env_auto_apply]
      ea_gui.views['env_auto_apply'].text = "Auto-sync changes"
    end
    ea_gui.views['fetch_notes'].color = CURSOR_POS_COLOR
    ea_gui.views['fetch_volume'].color = CURSOR_POS_COLOR
    ea_gui.views['fetch_panning'].color = CURSOR_POS_COLOR
  end

  if key_state == LCMD or key_state == RCMD then
    ea_gui.views['fetch_notes'].color = CURSOR_POS_EDIT_COLOR
  end
  if key_state == LALT or key_state == RALT then
    ea_gui.views['fetch_notes'].color = SUSTAIN_COLOR
    ea_gui.views['fetch_volume'].color = SUSTAIN_COLOR
    ea_gui.views['fetch_panning'].color = SUSTAIN_COLOR
  end
  
  if key_state == LALT + LCMD or key_state == RALT + RCMD or 
     key_state == RALT + LCMD or key_state == LALT + RCMD then
    local high = bit.bxor(CURSOR_POS_EDIT_COLOR[1],SUSTAIN_COLOR[1])
    local mid = bit.bxor(CURSOR_POS_EDIT_COLOR[2],SUSTAIN_COLOR[2])
    local low = bit.bxor(CURSOR_POS_EDIT_COLOR[3],SUSTAIN_COLOR[3])
    ea_gui.views['fetch_notes'].color = {high,mid,low}
    ea_gui.views['fetch_volume'].color = COLOR_THEME
    ea_gui.views['fetch_panning'].color = COLOR_THEME
  end  

  if key_state == LCAP + LCMD or key_state == RCAP + RCMD or 
     key_state == RCAP + LCMD or key_state == LCAP + RCMD then
    local high = bit.bxor(CURSOR_POS_EDIT_COLOR[1],CURSOR_POS_COLOR[1])
    local mid = bit.bxor(CURSOR_POS_EDIT_COLOR[2],CURSOR_POS_COLOR[2])
    local low = bit.bxor(CURSOR_POS_EDIT_COLOR[3],CURSOR_POS_COLOR[3])
    ea_gui.views['fetch_notes'].color = LOOP_START_COLOR --{high,mid,low}
    ea_gui.views['fetch_volume'].color = COLOR_THEME
    ea_gui.views['fetch_panning'].color = COLOR_THEME
  end  


end

function change_gui_properties()

  change_from_tool = true
  ea_gui.views['vol_assist_high_val'].value = vol_assist_high_val
  ea_gui.views['vol_assist_low_val'].value = vol_assist_low_val
  ea_gui.views['vol_assist_high_size'].value = vol_assist_high_size
  ea_gui.views['pan_assist_first_val'].value = pan_assist_first_val
  ea_gui.views['pan_assist_second_val'].value = pan_assist_next_val
  ea_gui.views['pan_assist_first_size'].value = pan_assist_first_size
  if vol_pulse_mode > 0 then
    ea_gui.views['vol_pulse_mode'].value = vol_pulse_mode 
  else
    ea_gui.views['vol_pulse_mode'].value = 1
  end
  if pan_pulse_mode > 0 then
    ea_gui.views['pan_pulse_mode'].value = pan_pulse_mode 
  else
    ea_gui.views['pan_pulse_mode'].value = 1
  end
  change_from_tool = true

end

---------------------------------------------------------------------------------------

function toggle_pan_vol_color()
  ea_gui.views['envelope_volume_toggle'].color = bool_button[envelope_volume_toggle]
  ea_gui.views['envelope_panning_toggle'].color = bool_button[envelope_panning_toggle]

end


---------------------------------------------------------------------------------------

function set_selected_tab(tab_area,tab, count)
  for tab_select = 1, count do
    ea_gui.views[tab_area..tostring(tab_select)].visible = false
    if tab_select == tab then
      ea_gui.views[tab_area..tostring(tab_select)].mode=IMAGE_TOGGLED_MODE
    else
      ea_gui.views[tab_area..tostring(tab_select)].mode=IMAGE_UNTOGGLED_MODE
    end
    ea_gui.views[tab_area..tostring(tab_select)].visible = true
    
  end
  
  
end


---------------------------------------------------------------------------------------

function toggle_sync_fields()
    change_from_tool = true
      ea_gui.views['sync_pitch_column'].value = tonumber(note_freq_val)
      ea_gui.views['sync_vol_column'].value = tonumber(vol_freq_val)
      ea_gui.views['sync_pan_column'].value = tonumber(pan_freq_val)
    change_from_tool = false
  
end

---------------------------------------------------------------------------------------

function top_tab_arming_toggle()
  if midi_record_mode == true then
    if tab_states.top == 1 then
      ea_gui.views['top_tab_1'].mode = 'plain'
      ea_gui.views['top_tab_1'].bitmap = "images/tab_pattern_arp_armed.png"
      ea_gui.views['top_tab_2'].bitmap = "images/tab_envelope_arp.png"
    elseif tab_states.top == 2 then
      ea_gui.views['top_tab_2'].mode = 'plain'
      ea_gui.views['top_tab_2'].bitmap = "images/tab_envelope_arp_armed.png"
      ea_gui.views['top_tab_1'].bitmap = "images/tab_pattern_arp.png"
    else
      ea_gui.views['top_tab_1'].bitmap = "images/tab_pattern_arp.png"
      ea_gui.views['top_tab_2'].bitmap = "images/tab_envelope_arp.png"
    end
  else
    ea_gui.views['top_tab_1'].bitmap = "images/tab_pattern_arp.png"
    ea_gui.views['top_tab_2'].bitmap = "images/tab_envelope_arp.png"
    set_selected_tab("top_tab_",tab_states.top, top_tabs_bound)
  end
end


---------------------------------------------------------------------------------------

function visible_subtabs(tab,bound)
  for _ = 1,bound do
    ea_gui.views['sub_tab_'..tostring(_)].visible = false
  end
  
  if tab == 1 then
    if tab_states.top == 1  then
      sub_tabs_bound = pat_tabs_bound
      ea_gui.views['sub_tab_1'].bitmap = "images/tab_note_profile.png"
      ea_gui.views['sub_tab_2'].bitmap = "images/tab_ins_volume.png"
      ea_gui.views['sub_tab_3'].bitmap = "images/tab_options.png"
      ea_gui.views['sub_tab_4'].bitmap = "images/tab_pool_area.png"
      ea_gui.views['sub_tab_5'].bitmap = "images/tab_presets.png"  
    end

    
  else
    if tab_states.top == 2  then
      bound = env_tabs_bound --take care non functional tabs aren't made visible!
      sub_tabs_bound = env_tabs_bound

      ea_gui.views['sub_tab_1'].bitmap = "images/tab_env_profile.png"
      ea_gui.views['sub_tab_2'].bitmap = "images/tab_options.png"
      ea_gui.views['sub_tab_3'].bitmap = "images/tab_presets.png"
--      ea_gui.views['sub_tab_4'].bitmap = "images/tab_pool_area_back.png"
--      ea_gui.views['sub_tab_5'].bitmap = "images/tab_presets_back.png"  
    end

  end
  for _ = 1,bound do
    ea_gui.views['sub_tab_'..tostring(_)].visible = true
  end
end


---------------------------------------------------------------------------------------

function set_visible_area()
 
  if tab_states.top == 1 then
    if gui_layout_option == LAYOUT_TABS then  
      ea_gui.views['sub_tab_row'].visible = true
      ea_gui.views['env_toggle_row'].visible = false
      set_selected_tab("sub_tab_",tab_states.sub, pat_tabs_bound)
      if tab_states.sub == 1 then
        ea_gui.views.switch_note_pattern.value = switch_note_pattern_index
        
        if ea_gui.views['switch_note_pattern'].value ~= NOTE_PATTERN_MATRIX then
          ea_gui.views['note_and_octave_props'].visible = true
        else
          ea_gui.views['complete_matrix'].visible = true
        end
        ea_gui.views['profile_selection'].visible = true
      else
        if ea_gui.views['switch_note_pattern'].value ~= NOTE_PATTERN_MATRIX then
          ea_gui.views['note_and_octave_props'].visible = false
        else
          ea_gui.views['complete_matrix'].visible = false
        end
        ea_gui.views['profile_selection'].visible = false
      end
      if tab_states.sub == 2 then
        ea_gui.views['ins_vol_props'].visible = true
      else
        ea_gui.views['ins_vol_props'].visible = false
      end
  
      if tab_states.sub == 3 then
        ea_gui.views['arpeggiator_options'].visible = true
      else
        ea_gui.views['arpeggiator_options'].visible = false
      end
      
      if tab_states.sub == 4 then
        ea_gui.views['application_area'].visible = true
      else
        ea_gui.views['application_area'].visible = false
      end

      if tab_states.sub == 5 then
        ea_gui.views['preset_area'].visible = true
      else
        ea_gui.views['preset_area'].visible = false
      end
      ea_gui.views['pat_execution_area'].visible = true    
      
    elseif gui_layout_option == LAYOUT_FULL then
    
      ea_gui.views['sub_tab_row'].visible = false
      ea_gui.views['profile_selection'].visible = true     
      ea_gui.views.switch_note_pattern.value = switch_note_pattern_index
      if ea_gui.views['switch_note_pattern'].value ~= NOTE_PATTERN_MATRIX then
        ea_gui.views['note_and_octave_props'].visible = true
        ea_gui.views['complete_matrix'].visible = false
      else
        ea_gui.views['note_and_octave_props'].visible = false
        ea_gui.views['complete_matrix'].visible = true
      end
      ea_gui.views['ins_vol_props'].visible = true
      ea_gui.views['arpeggiator_options'].visible = true
      ea_gui.views['application_area'].visible = true
      ea_gui.views['preset_area'].visible = true
      ea_gui.views['pat_execution_area'].visible = true    

    else  --LAYOUT_CUSTOM

      ea_gui.views['sub_tab_row'].visible = false
      ea_gui.views['pat_toggle_row'].visible = true 
      ea_gui.views['env_toggle_row'].visible = false
      ea_gui.views['profile_selection'].visible = pat_toggle_states[1]  
      ea_gui.views.switch_note_pattern.value = switch_note_pattern_index
      if ea_gui.views['switch_note_pattern'].value ~= NOTE_PATTERN_MATRIX then
        ea_gui.views['note_and_octave_props'].visible = pat_toggle_states[1]
        ea_gui.views['complete_matrix'].visible = false
      else
        ea_gui.views['note_and_octave_props'].visible = false
        ea_gui.views['complete_matrix'].visible = pat_toggle_states[1]
      end
      ea_gui.views['ins_vol_props'].visible = pat_toggle_states[2]
      ea_gui.views['arpeggiator_options'].visible = pat_toggle_states[3]
      ea_gui.views['application_area'].visible = pat_toggle_states[4]
      ea_gui.views['preset_area'].visible = pat_toggle_states[5]
      ea_gui.views['pat_execution_area'].visible = true          
    end
  else
    ea_gui.views['note_and_octave_props'].visible = false
    ea_gui.views['ins_vol_props'].visible = false
    ea_gui.views['complete_matrix'].visible = false
    ea_gui.views['profile_selection'].visible = false
    ea_gui.views['arpeggiator_options'].visible = false
    ea_gui.views['application_area'].visible = false
    ea_gui.views['preset_area'].visible = false
    ea_gui.views['pat_execution_area'].visible = false  
    ea_gui.views['pat_toggle_row'].visible = false
  end
  
  
  if tab_states.top == 2 then
    ea_gui.views['sub_tab_4'].visible = false
    ea_gui.views['sub_tab_5'].visible = false
    ea_gui.views['env_execution_area'].visible = true    
    if tab_states.sub > env_tabs_bound then
      tab_states.sub = env_tabs_bound
      set_selected_tab("sub_tab_",env_tabs_bound, env_tabs_bound)
    end
    if gui_layout_option == LAYOUT_TABS then  
--      ea_gui.views['sub_tab_row'].visible = true
      ea_gui.views['sub_tab_row'].visible = false

--      if tab_states.sub == 1 then
        ea_gui.views['envelope_profile'].visible = true
        ea_gui.views['envelope_track'].visible = true
--      else
--        ea_gui.views['envelope_profile'].visible = false
--        ea_gui.views['envelope_track'].visible = false
--      end
--      if tab_states.sub == 2 then
        ea_gui.views['envelope_options'].visible = true
--      else
--        ea_gui.views['envelope_options'].visible = false
--      end
--      if tab_states.sub == 3 then
        ea_gui.views['envelope_preset_area'].visible = true 
--      else
--        ea_gui.views['envelope_preset_area'].visible = false
--      end
    elseif gui_layout_option == LAYOUT_FULL then
      ea_gui.views['sub_tab_row'].visible = false
      ea_gui.views['envelope_profile'].visible = true
      ea_gui.views['envelope_track'].visible = true
      ea_gui.views['envelope_options'].visible = true
      ea_gui.views['envelope_preset_area'].visible = true 
    else  --LAYOUT_CUSTOM
      ea_gui.views['sub_tab_row'].visible = false
--      ea_gui.views['env_toggle_row'].visible = true 
      ea_gui.views['env_toggle_row'].visible = false
      ea_gui.views['envelope_profile'].visible = true
      ea_gui.views['envelope_track'].visible = true
      ea_gui.views['envelope_options'].visible = true
      ea_gui.views['envelope_preset_area'].visible = true
--[[
      ea_gui.views['envelope_profile'].visible = env_toggle_states[1]  
      ea_gui.views['envelope_track'].visible = env_toggle_states[1]
      ea_gui.views['envelope_options'].visible = env_toggle_states[2]
      ea_gui.views['envelope_preset_area'].visible = env_toggle_states[3]
      ea_gui.views['envelope_profile']:resize()
      ea_gui.views['envelope_track']:resize()
--      print(ea_gui.views['right_column'].height)
      if env_toggle_states[2] == false then
        if ea_gui.views['right_column'].height - preset_area_height > 0 then
          ea_gui.views['right_column'].height = ea_gui.views['right_column'].height - preset_area_height
        else
         -- ea_gui.views['right_column'].height = 1
        end
      else
        ea_gui.views['right_column'].height = ea_gui.views['right_column'].height + preset_area_height
      end
      if env_toggle_states[3] == false then
        if ea_gui.views['right_column'].height - preset_options_height > 0 then
          ea_gui.views['right_column'].height = ea_gui.views['right_column'].height - preset_options_height
        else
        end
      else
        ea_gui.views['right_column'].height = ea_gui.views['right_column'].height + preset_options_height
      end
--]]      
    end
------------------------------------------------    
--Remove the below three lines when done testing
------------------------------------------------    
--    ea_gui.views['envelope_profile'].visible = false  
--    ea_gui.views['envelope_options'].visible = false
--    ea_gui.views['envelope_preset_area'].visible = false    

  else
    ea_gui.views['envelope_profile'].visible = false  
    ea_gui.views['envelope_options'].visible = false
    ea_gui.views['envelope_preset_area'].visible = false
    ea_gui.views['env_toggle_row'].visible = false
    ea_gui.views['envelope_track'].visible = false
    ea_gui.views['env_execution_area'].visible = false
  end
  
  
  if tab_states.top == 3 then
    ea_gui.views['sub_tab_row'].visible = false 
    ea_gui.views['app_option_area'].visible = true    
  else
    ea_gui.views['app_option_area'].visible = false
  end
end


---------------------------------------------------------------------------------------


function update_envelope_arpeggiator_instrument_list()
  local ins_list = {}
  for _ = 1,#renoise.song().instruments do
    ins_list[_] = renoise.song().instruments[_].name
  end
  ea_gui.views['instrument_selection'].items = ins_list
  ea_gui.views['instrument_selection'].value = renoise.song().selected_instrument_index
end


---------------------------------------------------------------------------------------

function toggle_midi_record()
  midi_record_mode = not midi_record_mode

  if midi_record_mode == true then
    midi_record_color = MIDI_RECORDING
    midi_engine('start')
  else
    midi_record_color = MIDI_MUTED
    midi_engine('stop')
  end
  ea_gui.views['midi_record_mode'].color = midi_record_color

end


---------------------------------------------------------------------------------------

function change_distance_step(value, vb)
  distance_step = value

  if popup_distance_mode_index == NOTE_DISTANCE_DELAY then
    vb.views.vbox_distance_step.max = MAX_DELAY_STEPS
  else
    vb.views.vbox_distance_step.max = MAX_PATTERN_LINES
  end

end


---------------------------------------------------------------------------------------

function change_distance_mode(value,vb)
  popup_distance_mode_index = value

  if value == NOTE_DISTANCE_DELAY then
    vb.views.vbox_distance_step.max = MAX_DELAY_STEPS

    toggle_chord_mode_active(false,vb)

    if vb.views.vbox_distance_step.value > MAX_DELAY_STEPS then
      vb.views.vbox_distance_step.value = MAX_DELAY_STEPS
    end

  else
    toggle_chord_mode_active(true,vb)
  
    vb.views.vbox_distance_step.max = MAX_PATTERN_LINES
  end

end


---------------------------------------------------------------------------------------

function change_octave_order(value,vb)
  popup_octave_index = value

  if value >= PLACE_TOP_DOWN_TOP and value <= PLACE_DOWN_TOP_DOWN then
    vb.views.octave_repeat_mode.visible = true
    vb.views.octave_repeat_mode_text.visible = true
  else
    vb.views.octave_repeat_mode.visible = false
    vb.views.octave_repeat_mode_text.visible = false
  end
  if value == PLACE_RANDOM then
    vb.views.popup_note_order.value = PLACE_RANDOM
    if vb.views.popup_octave_order.active == true then
      vb.views.popup_note_order.active = false
    end
  else
    if vb.views.popup_note_order.value == PLACE_RANDOM then
      vb.views.popup_note_order.value = PLACE_TOP_DOWN
    end
    
    if vb.views.popup_note_order.active == false then
      vb.views.popup_note_order.active = true
    end
  end
end


--------------------------------------------------------------------------------

function set_termination_step(value,vb)
  -- Termination by note-cut (Fx) or note-off?
  -- Define the maximum number and set the step variable
  termination_step = value

  if termination_index == NOTE_OFF_DISTANCE_TICKS then
    if value > MAX_TICKS then
      --FF in Renoise means an "Empty" value so max ticks in
      -- the pan/vol columns can never exceed 14
      value = MAX_TICKS - 1
    end
    vb.views.vbox_termination_step.max = MAX_TICKS - 1
    vb.views.vbox_termination_step.min = 1

  else
    vb.views.vbox_termination_step.min = 0
    vb.views.vbox_termination_step.max = MAX_PATTERN_LINES
  end

end


--------------------------------------------------------------------------------

function set_termination_minmax(value,vb)
  -- Termination by note-cut (Fx) or note-off?
  -- Define the maximum number and set the index variable
  termination_index = value

  if value == NOTE_DISTANCE_DELAY then

    if vb.views.vbox_termination_step.value > MAX_TICKS then
      --FF in Renoise means an "Empty" value so max ticks in
      -- the pan/vol columns can never exceed 14
      vb.views.vbox_termination_step.value = MAX_TICKS - 1
    end
    vb.views.vbox_termination_step.max = MAX_TICKS - 1
    vb.views.vbox_termination_step.min = 1

  else
    vb.views.vbox_termination_step.min = 0
    vb.views.vbox_termination_step.max = MAX_PATTERN_LINES
  end
end


--------------------------------------------------------------------------------

function change_note_order(value,vb)
  --How should notes be placed?
  popup_note_index = value

  if value >= PLACE_TOP_DOWN_TOP and value <= PLACE_DOWN_TOP_DOWN then
    vb.views.repeat_note.visible = true
    vb.views.repeat_note_title.visible = true
  else
    vb.views.repeat_note.visible = false
    vb.views.repeat_note_title.visible = false
  end
  if value == PLACE_RANDOM then
    if vb.views.switch_note_pattern.value == NOTE_PATTERN_MATRIX then
      vb.views.popup_octave_order.value = PLACE_RANDOM
      if vb.views.popup_note_order.active == true then
        vb.views.popup_octave_order.active = false
      end
    end
  else
    if vb.views.popup_octave_order.value == PLACE_RANDOM then
      vb.views.popup_octave_order.value = PLACE_TOP_DOWN
    end
    if vb.views.popup_octave_order.active == false then
      vb.views.popup_octave_order.active = true
    end
  end
end


--------------------------------------------------------------------------------

function change_instrument_insertion(value,vb)
  --How should instrument numbers be placed?
  instrument_insertion_index = value

  if value >= PLACE_TOP_DOWN_TOP and value <= PLACE_DOWN_TOP_DOWN then
    vb.views.repeat_instrument.visible = true
    vb.views.repeat_instrument_title.visible = true
  else
    vb.views.repeat_instrument.visible = false
    vb.views.repeat_instrument_title.visible = false
  end

end


--------------------------------------------------------------------------------

function change_velocity_insertion(value,vb)
  --How should velocity or effect numbers be placed?
  velocity_insertion_index = value

  if value >= PLACE_TOP_DOWN_TOP and value <= PLACE_DOWN_TOP_DOWN then
    vb.views.repeat_velocity.visible = true
    vb.views.repeat_velocity_title.visible = true
  else
    vb.views.repeat_velocity.visible = false
    vb.views.repeat_velocity_title.visible = false
  end

end


--------------------------------------------------------------------------------

function set_area_selection(value,vb)
  -- If track or column in song is checked
  -- make sure we have unique pattern numbers in the sequencer
  -- If not, offer to make them unique.
  local chooser = vb.views.chooser

  if value==OPTION_TRACK_IN_SONG or value==OPTION_COLUMN_IN_SONG then
    local seq_status = check_unique_pattern(vb)

    if seq_status== -1 then
--      vb.views.chooser.value = area_to_process
    else
      area_to_process = value
      vb.views.chooser.value = value
    end

  else
    area_to_process = value
  end
  
  -- Don't allow the chord mode in column area option.
  if value==OPTION_COLUMN_IN_PATTERN or value==OPTION_COLUMN_IN_SONG then
    chord_mode = false
    --vb.views.chord_mode_box_title.visible = false
    vb.views.chord_mode_box.visible = false
  else
    if vb.views.max_note_colums.value > 1 then
      if vb.views.chord_mode_box.value == true then
      chord_mode = true
      end
      --vb.views.chord_mode_box_title.visible = true
      vb.views.chord_mode_box.visible = true
    end
  end

end


--------------------------------------------------------------------------------

function toggle_custom_arpeggiator_profile_visibility(value, vb)
  -- Custom distance patterns are allowed to be put in a textfield
  -- However this textfield should only be visible when this
  -- option is toggled.
  switch_arp_pattern_index = value

  
  if value == ARPEGGIO_PATTERN_CUSTOM then
    value = true
  else         
    value = false
  end

  if value == true then
--    vb.views.custom_arpeggiator_profile_title.visible = true
--    vb.views.custom_arpeggiator_profile.visible = true
    vb.views.custom_arpeggiator_layout.visible = true
  else
--    vb.views.custom_arpeggiator_profile_title.visible = false
--    vb.views.custom_arpeggiator_profile.visible = false
    vb.views.custom_arpeggiator_layout.visible = false
  end

end


--------------------------------------------------------------------------------

function toggle_note_profile_visibility(show, vb)
  -- Allowing a custom note pattern can be inserted in a textfield.
  -- But the textfield should only be visible when this
  -- option is toggled.
  if show == true then
--    vb.views.custom_note_profile_title.visible = true
    vb.views.custom_note_profile.visible = true
  else
--    vb.views.custom_note_profile_title.visible = false
    vb.views.custom_note_profile.visible = false
  end

end


--------------------------------------------------------------------------------
function toggle_chord_mode_active(value,vb)
  vb.views.chord_mode_box.active = value
end

function toggle_chord_mode_visibility(value,vb)
  -- If more notecolumns are selected, then make the
  -- chord-mode button appear, else hide it.
  max_note_columns = vb.views.max_note_colums.value

  if value < 2 then
    value = false
  else
    value = true
  end

  if value == true then
    vb.views.chord_mode_box_title.visible = true
    vb.views.chord_mode_box.visible = true
    vb.views.popup_distance_mode.active = true
  else
    vb.views.chord_mode_box_title.visible = false
    vb.views.chord_mode_box.visible = false
    vb.views.popup_distance_mode.value = 1
    vb.views.popup_distance_mode.active = false
  end

end


--------------------------------------------------------------------------------

function toggle_octave_visibility(show, vb)
  -- If the note matrix is visible, so should be
  -- the octave order option (this cannot be used with
  -- custom note profile). Also the repeat checkboxes
  -- may only appear if TdT or DtD options are picked.
  if show == true then
    vb.views.popup_octave_order_text.visible = true
    vb.views.popup_octave_order.visible = true
    vb.views.octave_repeat_mode_text.visible = true
    local pidx = vb.views.popup_octave_order.value

    if pidx >= PLACE_TOP_DOWN_TOP and pidx <= PLACE_DOWN_TOP_DOWN then
      vb.views.octave_repeat_mode.visible = true
      vb.views.octave_repeat_mode_text.visible = true
    else
      vb.views.octave_repeat_mode.visible = false
      vb.views.octave_repeat_mode_text.visible = false
    end

  else
    vb.views.popup_octave_order_text.visible = false
    vb.views.popup_octave_order.visible = false
    vb.views.popup_octave_order.value = PLACE_TOP_DOWN
    vb.views.octave_repeat_mode_text.visible = false
    vb.views.octave_repeat_mode.visible = false
  end

end


--[[============================================================================
tone matrix actions
============================================================================]]--

function toggle_note_matrix_visibility(show)
  -- Show the note matrix when selected, hide it when
  -- the custom note profile option is selected.
  if show == NOTE_PATTERN_MATRIX then
   ea_gui.views['complete_matrix'].visible = true
   ea_gui.views['note_and_octave_props'].visible = false
  else
   ea_gui.views['complete_matrix'].visible = false
   ea_gui.views['note_and_octave_props'].visible = true
  end

end




---------------------------------------------------------------------------------------

function note_state(octave, note)
   return note_states[octave * NUM_NOTES + note]
end

---------------------------------------------------------------------------------------

function octave_state(octave)
   return octave_states[octave]
end


---------------------------------------------------------------------------------------

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


---------------------------------------------------------------------------------------

-- Toggle one full octave row

function toggle_octave_row(vb, oct)
   oct = oct - 1
   local checkbox = nil
   local cb = vb.views
   for note = 1, NUM_NOTES do
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


---------------------------------------------------------------------------------------

-- Toggle one full note row

function toggle_note_row(vb, note)
   local checkbox = nil
   local cb = vb.views
   for oct = 0, NUM_OCTAVES-1 do
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


---------------------------------------------------------------------------------------

function set_all_row_state(vb, btext)
   local checkbox = nil
   local cb = vb.views
   for t = 0, NUM_OCTAVES-1 do
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


---------------------------------------------------------------------------------------

--[[ 
  Look which notes are set in the tone-matrix in one octave 
--]]

function harvest_notes_in_octave(octave)
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


--------------------------------------------------------------------------------
--      End of teh road...
--------------------------------------------------------------------------------

