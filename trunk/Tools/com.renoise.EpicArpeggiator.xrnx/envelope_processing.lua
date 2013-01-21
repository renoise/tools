--[[============================================================================
envelope_processing.lua
============================================================================]]--


function sample_envelope_line_sync(correct)
  --This function rescales the BPM/LPB factor when
  --LPB has an incompatible factor. If the correct parameter
  --is true, the rescaling is executed, if not, then the button
  --to correct is made visible.
  local lpb = renoise.song().transport.lpb
  local bpm = renoise.song().transport.bpm
  local rasters_per_line = 24/lpb
  local approach = rasters_per_line - math.floor(rasters_per_line)
  if approach > 0 then
    if correct then
      ea_gui.views['line_sync_correct'].visible = false
      if lpb > 24 then
        bpm = (bpm / 24 * lpb)
        lpb = 24
      else
        if lpb > 18 and lpb < 24 then
          bpm = (bpm / 24 * lpb)
          lpb = 24
        end
        if lpb > 12 and lpb < 19 then
          bpm = (bpm / 12 * lpb)
          lpb = 12
        end
        if lpb < 12 and lpb > 9 then
          bpm = (bpm / 12 * lpb)
          lpb = 12
        end        
        if lpb < 10 and lpb > 6 then
          bpm = (bpm / 8 * lpb)
          lpb = 8
        end        
        if lpb == 5 then
          bpm = (bpm / 6 * lpb)
          lpb = 6
        end
      end
      renoise.song().transport.bpm = bpm
      renoise.song().transport.lpb = lpb
      rasters_per_line = 24/lpb
    else
      ea_gui.views['line_sync_correct'].visible = true
    end
  else
    ea_gui.views['line_sync_correct'].visible = false
  end
  
  if env_sync_mode == true then
    env_sync_mode = false
    if ea_gui.views['sync_pitch_column'].value > 0 then
      remove_envelope_notifiers ()
        change_line_sync(ENV_NOTE_COLUMN,ea_gui.views['sync_pitch_column'].value)
        
      set_envelope_notifiers(processing_instrument)
    end 

    if ea_gui.views['sync_vol_column'].value > 0 then
      remove_envelope_notifiers ()
        change_line_sync(ENV_VOL_COLUMN,ea_gui.views['sync_vol_column'].value)
      set_envelope_notifiers(processing_instrument)
  
    end 
  
    if ea_gui.views['sync_pan_column'].value > 0 then
      remove_envelope_notifiers ()
        change_line_sync(ENV_PAN_COLUMN,ea_gui.views['sync_pan_column'].value)
      set_envelope_notifiers(processing_instrument)
    end 

  end
  
  return math.floor(rasters_per_line)
  
end


---------------------------------------------------------------------------------------

function lpb_handler()
  env_sync_mode = true
  row_frequency_size = renoise.song().transport.edit_step
  sample_envelope_line_sync()
  if vol_pulse_mode ~= ARP_MODE_OFF then
    construct_envelope_pulse(ENV_VOL_COLUMN)
  end  
  if pan_pulse_mode ~= ARP_MODE_OFF then
    construct_envelope_pulse(ENV_PAN_COLUMN)
  end  
  if ea_gui.views['note_chord_spacing'].value > sample_envelope_line_sync(false)-1 then
    ea_gui.views['note_chord_spacing'].value = sample_envelope_line_sync(false)-1
    note_chord_spacing = sample_envelope_line_sync(false)-1
  end
end


---------------------------------------------------------------------------------------

function change_line_sync(envelope,value)
  if not change_from_tool then
    change_from_tool = true
    if envelope == ENV_NOTE_COLUMN then

      get_current_data()

      note_freq_type = FREQ_TYPE_LINES
      note_freq_val = value
      prepare_note_tables(ENV_NOTE_COLUMN)
      if env_auto_apply then
        set_pitch_table()
      end
      --Auto-vol and auto-pan pulse mode are pitch position depending
      --so they need to be altered when changes happen in the scheme.
      if vol_pulse_mode ~= ARP_MODE_OFF then
        construct_envelope_pulse(ENV_VOL_COLUMN)
      end  
      if pan_pulse_mode ~= ARP_MODE_OFF then
        construct_envelope_pulse(ENV_PAN_COLUMN)
      end  

    end

    if envelope == ENV_VOL_COLUMN then
      vol_freq_type = FREQ_TYPE_LINES
      vol_freq_val = value          
      prepare_note_tables(ENV_VOL_COLUMN)
    end
  
    if envelope == ENV_VOL_COLUMN then
      pan_freq_type = FREQ_TYPE_LINES
      pan_freq_val = value          
      prepare_note_tables(ENV_PAN_COLUMN)
    end

    configure_envelope_loop()
    set_cursor_location()
    change_from_tool = false
  end
  
end

---------------------------------------------------------------------------------------

function set_row_frequency_size()
  row_frequency_size = renoise.song().transport.edit_step
end

---------------------------------------------------------------------------------------


function configure_envelope_loop()
  --Sets the loop properties of each envelope involved.
  --Also does several sanity checks
  local sel_ins = ea_gui.views['instrument_selection'].value
  local ins = renoise.song().instruments[sel_ins].sample_envelopes

  if note_loop_end == nil then
     return
  end
  
  if note_loop_end + 1 > ins.pitch.length then
    ins.pitch.length = note_loop_end +1
  end
  if note_loop_start == nil then
    return
  end
  if note_loop_start + 1 > ins.pitch.length then
    ins.pitch.length  = note_loop_start + 1
  end
  if vol_loop_end == nil then
     return
  end
  if envelope_volume_toggle then
    if vol_loop_end + 1 > ins.volume.length then
      ins.volume.length = vol_loop_end +1
    end
    if vol_loop_start == nil then
      return
    end
    if vol_loop_start + 1 > ins.volume.length then
      ins.volume.length  = vol_loop_start + 1
    end
  end
  if pan_loop_end == nil then
     return
  end
  if envelope_panning_toggle then
    if pan_loop_end + 1 > ins.pan.length then
      ins.pan.length = pan_loop_end +1
    end
    if pan_loop_start == nil then
      return
    end
    if pan_loop_start + 1 > ins.pan.length then
      ins.pan.length  = pan_loop_start + 1
    end
  end
  
  if env_auto_apply then
  --No loop, Auto-loop or manual loop configuration?
    if auto_note_loop == ARP_MODE_AUTO then
      ins.pitch.loop_mode = ENV_LOOP_FORWARD
      note_loop_type = ENV_LOOP_FORWARD
      ins.pitch.loop_start = 1
      ins.pitch.loop_end = note_scheme_size + 1
    else
      ins.pitch.loop_mode = note_loop_type

      if note_loop_start < MAXIMUM_FRAME_LENGTH and note_loop_start > -1 then
        if note_loop_start +1 > ins.pitch.length then 
          ins.pitch.length = note_loop_start + 1
        end
        ins.pitch.loop_start = note_loop_start +1
      end

      if note_loop_end < MAXIMUM_FRAME_LENGTH and note_loop_end > -1 then
        if note_loop_end +1  > ins.pitch.length then 
          ins.pitch.length = note_loop_end + 1
        end
        ins.pitch.loop_end = note_loop_end +1
      end

    end
    
    if envelope_volume_toggle then

      if auto_vol_loop == ARP_MODE_AUTO then
        ins.volume.loop_mode = ENV_LOOP_FORWARD
        vol_loop_type = ENV_LOOP_FORWARD
        ins.volume.loop_start = 1
        ins.volume.loop_end = vol_scheme_size + 1
      else
        ins.volume.loop_mode = vol_loop_type
  
        if vol_loop_start < MAXIMUM_FRAME_LENGTH and vol_loop_start > -1 then
          if vol_loop_start +1 > ins.volume.length then 
            ins.volume.length = vol_loop_start + 1
          end
          ins.volume.loop_start = vol_loop_start +1
        end

        if vol_loop_end < MAXIMUM_FRAME_LENGTH and vol_loop_end > -1 then
          if vol_loop_end +1 > ins.volume.length then 
            ins.volume.length = vol_loop_end + 1
          end
          ins.volume.loop_end = vol_loop_end +1
        end

      end
    end
    
    if envelope_panning_toggle then
      if auto_pan_loop == ARP_MODE_AUTO then
        ins.pan.loop_mode = ENV_LOOP_FORWARD
        pan_loop_type = ENV_LOOP_FORWARD
        ins.pan.loop_start = 1
        ins.pan.loop_end = pan_scheme_size + 1
      else
        ins.pan.loop_mode = pan_loop_type
  
        if pan_loop_start < MAXIMUM_FRAME_LENGTH and pan_loop_start > -1 then
          if pan_loop_start +1 > ins.pan.length then 
            ins.pan.length = pan_loop_start + 1
          end
          ins.pan.loop_start = pan_loop_start +1
        end
  
        if pan_loop_end < MAXIMUM_FRAME_LENGTH and pan_loop_end > -1 then
          if pan_loop_end +1 > ins.pan.length then 
            ins.pan.length = pan_loop_end + 1
          end
          ins.pan.loop_end = pan_loop_end +1
        end
  
      end
    end

  end
  
  if construct then
    construct_envelope()
  end
  ea_gui.views['envelope_note_loop_toggle'].text = ENV_LOOP_TYPE[note_loop_type]
  ea_gui.views['envelope_volume_loop_toggle'].text = ENV_LOOP_TYPE[vol_loop_type]
  ea_gui.views['envelope_panning_loop_toggle'].text = ENV_LOOP_TYPE[pan_loop_type]
  
end



---------------------------------------------------------------------------------------


function construct_envelope_pulse(column)
  
  get_current_data(true)
  local env_pitch_scheme_locations = note_point_scheme:split( "[^,%s]+" )
  local env_pitch_scheme_values = env_pitch_scheme:split( "[^,%s]+" )
  local note_locations = {}
  local low_val_pos = 0
  init_tables(column)  

  for t = 1, #env_pitch_scheme_locations do
    note_locations[t] = tonumber(env_pitch_scheme_locations[t])
  end  

  if column == ENV_VOL_COLUMN then
    if auto_vol_loop == ARP_MODE_AUTO then
      vol_loop_end = note_locations[#note_locations]
    end
  end
  
  if column == ENV_PAN_COLUMN then
    if auto_pan_loop == ARP_MODE_AUTO then
      pan_loop_end = note_locations[#note_locations]
    end
  end

  for t = 1, #note_locations do
    local env_pitch_scheme_value = env_pitch_scheme_values[t]
    if string.sub(env_pitch_scheme_value,1,1) == '[' then
      if string.sub(env_pitch_scheme_value,1,2) == '[-' then
        env_pitch_scheme_value = '-12'
      else
        env_pitch_scheme_value= '12'
      end
    end
    if column == ENV_VOL_COLUMN then
      if vol_pulse_mode == ARP_MODE_OFF then
        return
      end
      if tonumber(env_pitch_scheme_value) < NOTE_SCHEME_TERMINATION then
        env_vol_value[note_locations[t]] = vol_assist_high_val
      else
        env_vol_value[note_locations[t]] = VOL_PAN_TERMINATION
        vol_scheme_size = note_locations[t]
      end

      if t < #env_pitch_scheme_locations and #note_locations > 1 then
        if vol_assist_high_size == 0 then
          low_val_pos = math.round((note_locations[t+1] - note_locations[t])/2)
        else
          low_val_pos = vol_assist_high_size
        end
        if note_locations[t]+low_val_pos < note_locations[t+1] then
          env_vol_value[note_locations[t]+low_val_pos] = vol_assist_low_val
        else
          env_vol_value[note_locations[t+1]-1] = vol_assist_low_val
        end
      else
        if vol_assist_high_size == 0 and #note_locations > 1 then
          
          low_val_pos = math.round((note_locations[t] - note_locations[t-1])/2)
          env_vol_value[note_locations[t-1]+low_val_pos] = vol_assist_low_val
        end      
      end

    elseif column == ENV_PAN_COLUMN then
      if pan_pulse_mode == ARP_MODE_OFF then
        return
      end
      if tonumber(env_pitch_scheme_value) < NOTE_SCHEME_TERMINATION then
        env_pan_value[note_locations[t]] = pan_assist_first_val
      else
        env_pan_value[note_locations[t]] = VOL_PAN_TERMINATION
        pan_scheme_size = note_locations[t]
      end

      if t < #env_pitch_scheme_locations and #note_locations > 1 then
        if pan_assist_first_size == 0 then
          low_val_pos = math.round((note_locations[t+1] - note_locations[t])/2)
        else
          low_val_pos = pan_assist_first_size
        end
        if note_locations[t]+low_val_pos < note_locations[t+1] then
          env_pan_value[note_locations[t]+low_val_pos] = pan_assist_next_val
        else
          env_pan_value[note_locations[t+1]-1] = pan_assist_next_val
        end
      else
        if pan_assist_first_size == 0 and #note_locations > 1 then
          low_val_pos = math.round((note_locations[t] - note_locations[t-1])/2)
          env_pan_value[note_locations[t-1]+low_val_pos] = pan_assist_next_val
        end      
      end


    end

  end
--  populate_columns()
  
  if env_auto_apply then
    apply_table_to_envelope()
  end
  set_cursor_location()

end


---------------------------------------------------------------------------------------


function convert_note_value_tables()
--Value to note corrector: converts value to note values and
--corrects there where necessary. Multiply factor applied always
--rescales the figures to a range of -12  to +12
  local end_table = note_scheme_size
  local division_factor = 100

  if tonumber(env_note_value[note_scheme_size]) ~= NOTE_SCHEME_TERMINATION then
    end_table = MAXIMUM_FRAME_LENGTH
  end

  if ea_gui.views['env_multiplier'].value == ENV_X10 then
    division_factor = 10
  elseif ea_gui.views['env_multiplier'].value == ENV_X100 then
    division_factor = 1
  end

  for t = 0, end_table do
    if string.sub(env_note_value[t],1,1) ~= '[' then
      if tonumber(env_note_value[t]) < NOTE_SCHEME_TERMINATION then
  
        if tonumber(env_note_value[t]) > 120 or tonumber(env_note_value[t]) < -120 then
          division_factor = 100
        end
        local note_value = math.round(tonumber(env_note_value[t]) / division_factor)
        if ea_gui.views['env_multiplier'].value == ENV_X100 and 
          (note_value >12 or note_value < -12) then
          note_value = math.mod(note_value,12)
        end
        if ea_gui.views['env_multiplier'].value == ENV_X10 and 
          (note_value >120 or note_value < -120) then
          note_value = math.mod(note_value,120)
        end
        env_note_value[t] = note_value

      end
    else
      env_note_value[t] = 0
    end
    
  end
  
end

---------------------------------------------------------------------------------------


function set_pitch_table()
--Tone scope output corrector
--Check the values if they are crossing boundaries (e.g.:[14] or [-15])
--and then set the values for the pitch frame to the maximum value
--according to the current tone factor. This way we have a safe zone without
--loosing the original values when crossing the boundaries.
  local song = renoise.song()
  local tool_instrument = ea_gui.views['instrument_selection'].value
  local samples = #song.instruments[tool_instrument].samples
  local factor_selection = ea_gui.views['env_multiplier'].value
  local bound_break = false
  local lowest_note = 0
  local highest_note = 0
  local octave_shift = 0
  
  if note_scheme_size == 0 or note_scheme_size == -1 then
    return
  end
  
--[[
  if env_note_value[note_scheme_size] ~= NOTE_SCHEME_TERMINATION then
    note_scheme_size = MAXIMUM_FRAME_LENGTH
  end
--]]
  for x = 0,note_scheme_size do
    pitch_table[x] = env_note_value[x]
    if tonumber(env_note_value[x]) == NOTE_SCHEME_TERMINATION then
      note_scheme_size = x
      break
    end
  end
  
  --Setting the pitch table factors
  if factor_selection == ENV_X1 then
    tone_factor = 1
  elseif factor_selection == ENV_X10 then
    tone_factor = 10
  else
    tone_factor = 100
  end

  for _ = 0, note_scheme_size do
    if string.sub(pitch_table[_],1,1) == '[' then
      bound_break = true
      break
    end
  end

  if bound_break then
    for _ = 0, note_scheme_size do
      if string.sub(pitch_table[_],1,1) == '[' then
        local temp_pitch = pitch_table[_]
        temp_pitch = string.sub(temp_pitch,2,string.len(temp_pitch)-1)
        if tonumber(temp_pitch) < NOTE_SCHEME_TERMINATION then
        
          if string.sub(temp_pitch,1,1) == '-' then
            if tonumber(temp_pitch) < lowest_note then 
              lowest_note = tonumber(temp_pitch)
            end
          else
            if tonumber(temp_pitch) > highest_note then 
              highest_note = tonumber(temp_pitch)
            end
          end
        end
      end
    end
    
    if highest_note - lowest_note < 24 then
      octave_shift = 12*math.floor(highest_note/12)
      for _ = 0, note_scheme_size do
        local temp_pitch = pitch_table[_]
        if string.sub(pitch_table[_],1,1) == '[' then
          temp_pitch = string.sub(temp_pitch,2,string.len(temp_pitch)-1)
        end
        if tonumber(temp_pitch) < NOTE_SCHEME_TERMINATION then
          pitch_table[_] = tostring(tonumber(temp_pitch) - octave_shift)
        end
      end
    end
  end

  for _ = 0, note_scheme_size do
    if string.sub(pitch_table[_],1,1) == '[' then
      local temp_pitch = pitch_table[_]
      temp_pitch = string.sub(temp_pitch,2,string.len(temp_pitch)-1)
      if tonumber(temp_pitch) < NOTE_SCHEME_TERMINATION then
        if string.sub(temp_pitch,1,1) == '-' then
          if string.len(temp_pitch) == 3 then
            temp_pitch = '-12'
          end
          if string.len(temp_pitch) == 4 then
            temp_pitch = '-120'
          end
          if string.len(temp_pitch) > 4 then
            temp_pitch = '-1200'
          end
        else
          if string.len(temp_pitch) == 2 then
            temp_pitch = '12'
          end
          if string.len(temp_pitch) == 3 then
            temp_pitch = '120'
          end
          if string.len(temp_pitch) > 3 then
            temp_pitch = '1200'
          end
        end
        pitch_table[_] = tonumber(temp_pitch)
      end
    end

    if tonumber(pitch_table[_]) * tone_factor <= 1200 and tonumber(pitch_table[_]) * tone_factor >=  -1200 then
      pitch_table[_] = tonumber(pitch_table[_]) * tone_factor
    end

  end
  
  if construct then
    construct_envelope()
  end
  
end


---------------------------------------------------------------------------------------


function alter_transpose()
--Tone scope adjustment:Adjust the pitch values to the opposite of the
--transpose values. Hitting the same note key will produce the same sound, but
--allows to relocate the origin of the scale and expand notes on
--either lower or higher pitch field.
  local song = renoise.song()
  local tool_instrument = ea_gui.views['instrument_selection'].value
  local samples = #song.instruments[tool_instrument].samples
  
  if note_scheme_size == 0 or note_scheme_size == -1 then
    return
  end
  
  for x = 0,note_scheme_size do
    pitch_table[x] = env_note_value[x]
    if tonumber(env_note_value[x]) == NOTE_SCHEME_TERMINATION then
      note_scheme_size = x
      break
    end
  end

  --Alter the sample transpose figures related to their current setting
  if env_auto_apply then
    for s = 1,samples do
      local sample = song.instruments[tool_instrument].samples[s]
      local ts_difference = tone_scope_correction - tone_scope_offset
      if sample.transpose-1 > -121 and sample.transpose + 1 < 121 then
        sample.transpose = sample.transpose - ts_difference
      end
    end
  end

  if transpose_pitch_scheme == true then
    local pitch_transpose = math.floor(ea_gui.views['tone_scope_slider'].value)
    local pitch_offset = (-12 - pitch_transpose) * tone_factor
    local new_pitch_scheme = ''
    local factor_selection = ea_gui.views['env_multiplier'].value
    local opposite_factor = tone_factor
    if factor_selection == ENV_X100 then
      opposite_factor = 1
    end
    if factor_selection == ENV_X1 then
      opposite_factor = 100
    end
    --We don't need to change the tone_factor for the X10 factor, the opposite is equal
          
    local ts_difference = (tone_scope_correction - tone_scope_offset) * opposite_factor
    
    for _ = 0, note_scheme_size do
      if string.sub(pitch_table[_],1,1) == '[' then
        local temp_pitch = pitch_table[_]
        temp_pitch = string.sub(temp_pitch,2,string.len(temp_pitch)-1)
        pitch_table[_] = temp_pitch
      end
      if tonumber(pitch_table[_]) < NOTE_SCHEME_TERMINATION then
        pitch_table[_] = pitch_table[_] + ts_difference
        
        if pitch_table[_] < (-12 * opposite_factor) or pitch_table[_] > (12 * opposite_factor) then
          pitch_table[_] = '['..pitch_table[_]..']'
        end
      end

    end
    
    for x = 0,note_scheme_size do
      env_note_value[x] = pitch_table[x]
      if tonumber(pitch_table[x]) == NOTE_SCHEME_TERMINATION then
        break
      end
    end
    populate_columns()
    apply_table_to_envelope()
  end

end


---------------------------------------------------------------------------------------


function construct_envelope ()
  -- build all the envelopes and loops.
  local song = renoise.song()
  local tool_instrument = ea_gui.views['instrument_selection'].value
  local instrument = song.instruments[tool_instrument].sample_envelopes

  
  if env_auto_apply then
    local rasters_per_line = sample_envelope_line_sync()
    local loop_start = note_loop_start
    local loop_end = note_loop_end
    local loop_type = note_loop_type
    local point_table = {}
    local loop_end_store = instrument.pitch.loop_end
   
    change_from_tool = true
    instrument.pitch.play_mode = PLAY_MODE_POINTS
    instrument.pitch.enabled = true
    
    instrument.pitch:clear_points()
    instrument.pitch.play_mode = env_pitch_type
   
    for x = 0,note_scheme_size do
      if pitch_table[x] ~= nil and tonumber(pitch_table[x]) ~= nil then --Notes outside the pitch scope fuck up again!!
        if tonumber(pitch_table[x]) < NOTE_SCHEME_TERMINATION then
          local ptone = 0.5 + (tonumber(pitch_table[x]) * TONE)
          instrument.pitch:add_point_at(x+1,ptone)
--          print('<point>'..tostring(x*256),','..tostring(ptone)..'<point>')
        end
      end
    end      

    if note_scheme_size < MINIMUM_FRAME_LENGTH then
      note_scheme_size = MINIMUM_FRAME_LENGTH
    end

    if note_scheme_size < MAXIMUM_FRAME_LENGTH then
      instrument.pitch.length = note_scheme_size + 1
    else
      instrument.pitch.length = MAXIMUM_FRAME_LENGTH
    end
    
    if note_sustain > -1 then
      if instrument.pitch.length >= note_sustain + 1 then
        instrument.pitch.sustain_position = note_sustain + 1
      else
        instrument.pitch.sustain_position = 1
        note_sustain = 1
      end
      instrument.pitch.sustain_enabled = true
    else
      instrument.pitch.sustain_enabled = false
    end

    if envelope_volume_toggle then
      change_from_tool = true
      instrument.volume.enabled = true
      instrument.volume:clear_points()
      instrument.volume.play_mode = env_volume_type
      for x = 0,vol_scheme_size do
        if env_vol_value[x] ~= nil then
          if tonumber(env_vol_value[x]) < VOL_PAN_TERMINATION then
            local pvol = (tonumber(env_vol_value[x]) / 100)
            instrument.volume:add_point_at(x+1,pvol)
          end

        end
      end      
      if vol_release > -1 then
        instrument.volume.fade_amount = vol_release
      end 
      if vol_sustain > -1 then
        if instrument.volume.length >= vol_sustain + 1 then
          instrument.volume.sustain_position = vol_sustain + 1
        else
          instrument.volume.sustain_position = 1
          vol_sustain = 1
        end
        instrument.volume.sustain_enabled = true
      else
        instrument.volume.sustain_enabled = false
      end
      if vol_scheme_size < MINIMUM_FRAME_LENGTH then
        vol_scheme_size = MINIMUM_FRAME_LENGTH
      end

      if vol_scheme_size < MAXIMUM_FRAME_LENGTH then
        instrument.volume.length = vol_scheme_size + 1
      else
        instrument.volume.length = MAXIMUM_FRAME_LENGTH
      end
    else
      instrument.volume.enabled = false
    end
    
    if envelope_panning_toggle then
      change_from_tool = true
      instrument.pan.enabled = true
      instrument.pan:clear_points()

      instrument.pan.play_mode = env_panning_type

      for x = 0,pan_scheme_size do
        if env_pan_value[x] ~= nil then
          if tonumber(env_pan_value[x]) < VOL_PAN_TERMINATION then
            local ppan = (tonumber(env_pan_value[x]) / 100)
            if ppan <= 0 then
              ppan = 0.5 - math.abs(ppan)
            else
              ppan = ppan + 0.5
            end
            instrument.pan:add_point_at(x+1,ppan)
          end
        end
      end      

      if pan_sustain > -1 then
        if instrument.pan.length >= pan_sustain + 1 then
          instrument.pan.sustain_position = pan_sustain + 1
        else
          instrument.pan.sustain_position = 1
          pan_sustain =1
        end
        
        instrument.pan.sustain_enabled = true
      else
        instrument.pan.sustain_enabled = false
        
      end

      if pan_scheme_size < MINIMUM_FRAME_LENGTH then
        pan_scheme_size = MINIMUM_FRAME_LENGTH
      end
     
      if pan_scheme_size < MAXIMUM_FRAME_LENGTH then
        instrument.pan.length = pan_scheme_size + 1
      else
        instrument.pan.length = MAXIMUM_FRAME_LENGTH
      end
    else
      instrument.pan.enabled = false
    end
    construct = false --Don't call myself recursively (endless loop)
      configure_envelope_loop()
    construct = true

--No below routine is not double, in the construct loop function
--there are some sanity checks that are required
    if auto_note_loop == ARP_MODE_AUTO then
      instrument.pitch.loop_start = 1
      instrument.pitch.loop_end = instrument.pitch.length
      instrument.pitch.loop_mode = ENV_LOOP_FORWARD
    end
    
    change_from_tool = false
  end

end



---------------------------------------------------------------------------------------


function fetch_pitch_envelope(manual)
--Get pitch values from the envelope and populate the tool table
  if change_from_tool or (env_auto_apply == false and manual == true) then
    return
  end

  init_tables(ENV_NOTE_COLUMN)
  local song = renoise.song()
  local tool_instrument = ea_gui.views['instrument_selection'].value
  local instrument = song.instruments[tool_instrument].sample_envelopes
  local points = #instrument.pitch.points
  local factor = 100
  note_scheme_size = instrument.pitch.length-1

--x/y values
  
  if env_multiplier == ENV_X10 then
    factor = 10
  elseif env_multiplier == ENV_X1 then
    factor = 1
  end
  
  if env_note_value[0] == NOTE_SCHEME_TERMINATION then
    env_note_value[0] = EMPTY_CELL
  end
  
  for t = 1, points do
    local value = tonumber(instrument.pitch.points[t].value)
    local location = tonumber(instrument.pitch.points[t].time) - 1
    if location > (instrument.pitch.length-1) then
      break
    end
    if value > 0.5 then
      value = value - 0.5
      env_note_value[location] = math.round(value/TONE)
    elseif value < 0.5 then
      env_note_value[location] = math.round((0.5 - value)/TONE) *-1
    else
      env_note_value[location] = 0
    end
    env_note_value[location] = env_note_value[location] / factor
    env_note_value[location] = math.round(env_note_value[location])

  end
  
  env_note_value[instrument.pitch.length-1] = NOTE_SCHEME_TERMINATION
--envelope-type
  env_pitch_type = instrument.pitch.play_mode
--loop-mode and points
  note_loop_type = instrument.pitch.loop_mode
  ea_gui.views['envelope_note_loop_toggle'].text = ENV_LOOP_TYPE[note_loop_type]
  
  if  note_loop_type > ENV_LOOP_OFF then
    note_loop_start = instrument.pitch.loop_start-1
    note_loop_end = instrument.pitch.loop_end-1
  end
  
--sustain
  if instrument.pitch.sustain_enabled then
    note_sustain = instrument.pitch.sustain_position - 1
  else
    note_sustain = -1
  end



--LFO data
  note_lfo1_type = instrument.pitch.lfo1.mode
  note_lfo1_phase = instrument.pitch.lfo1.phase
  note_lfo1_freq = instrument.pitch.lfo1.frequency
  note_lfo1_amount = instrument.pitch.lfo1.amount
  note_lfo2_type = instrument.pitch.lfo2.mode
  note_lfo2_phase = instrument.pitch.lfo2.phase
  note_lfo2_freq = instrument.pitch.lfo2.frequency
  note_lfo2_amount = instrument.pitch.lfo2.amount

  set_cursor_location()



  
end


---------------------------------------------------------------------------------------


function fetch_volume_envelope(manual)
--Get volume values from the envelope and populate the tool table
  if change_from_tool or (env_auto_apply == false and manual == true) then
    return
  end
  local song = renoise.song()
  local tool_instrument = ea_gui.views['instrument_selection'].value
  local instrument = song.instruments[tool_instrument].sample_envelopes
  local points = #instrument.volume.points
  local factor = 100
  vol_scheme_size = instrument.volume.length-1
  init_tables(ENV_VOL_COLUMN)

  envelope_volume_toggle = instrument.volume.enabled

  if ea_gui ~= nil then
    ea_gui.views['envelope_volume_toggle'].color = bool_button[envelope_volume_toggle]
  end

--envelope-type
  env_volume_type = instrument.volume.play_mode
--x/y values
  for t = 0, vol_scheme_size do
    if env_vol_value[t] == VOL_PAN_TERMINATION then
      env_vol_value[t] = EMPTY_CELL
    end
  end

  for t = 1, points do
    local value = tonumber(instrument.volume.points[t].value)
    local location = tonumber(instrument.volume.points[t].time) - 1
    if location > (instrument.volume.length-1) then
      break
    end

    env_vol_value[location] = math.round(value *100)

  end
  
  --Set end of frame marker if it does not contain a value
  if env_vol_value[instrument.volume.length-1] == EMPTY_CELL then
    env_vol_value[instrument.volume.length-1] = VOL_PAN_TERMINATION
  end


--release
  vol_release = instrument.volume.fade_amount
  
--loop-mode and points
  vol_loop_type = instrument.volume.loop_mode
  ea_gui.views['envelope_volume_loop_toggle'].text = ENV_LOOP_TYPE[vol_loop_type]
  if vol_loop_type > ENV_LOOP_OFF then
    vol_loop_start = instrument.volume.loop_start -1
    vol_loop_end = instrument.volume.loop_end -1
  end
--sustain
  if instrument.volume.sustain_enabled then
    vol_sustain = instrument.volume.sustain_position -1
  else
    vol_sustain = -1
  end

--lfo
  vol_lfo1_type = instrument.volume.lfo1.mode
  vol_lfo1_phase = instrument.volume.lfo1.phase
  vol_lfo1_freq = instrument.volume.lfo1.frequency
  vol_lfo1_amount = instrument.volume.lfo1.amount
  vol_lfo2_type = instrument.volume.lfo2.mode
  vol_lfo2_phase = instrument.volume.lfo2.phase
  vol_lfo2_freq = instrument.volume.lfo2.frequency
  vol_lfo2_amount = instrument.volume.lfo2.amount


  set_cursor_location()
end

---------------------------------------------------------------------------------------


function fetch_panning_envelope(manual)
--Get panning values from the envelope and populate the tool table
  if change_from_tool or (env_auto_apply == false and manual == true) then
    return
  end
  
  local song = renoise.song()
  local tool_instrument = ea_gui.views['instrument_selection'].value
  local instrument = song.instruments[tool_instrument].sample_envelopes
  local points = #instrument.pan.points
  local factor = 100
  pan_scheme_size = instrument.pan.length-1
  init_tables(ENV_PAN_COLUMN)

  envelope_panning_toggle = instrument.pan.enabled

  if ea_gui ~= nil then
    ea_gui.views['envelope_panning_toggle'].color = bool_button[envelope_panning_toggle]
  end

--envelope-type
  env_panning_type = instrument.pan.play_mode
  
--x/y values
  for t = 0, pan_scheme_size do
    if env_pan_value[t] == VOL_PAN_TERMINATION then
      env_pan_value[t] = EMPTY_CELL
    end
  end

  for t = 1, points do
    local value = tonumber(instrument.pan.points[t].value)
    local location = tonumber(instrument.pan.points[t].time) - 1
    if location > (instrument.pan.length-1) then
      break
    end
    if value < 0.5 then
      value = math.round((0.5 - value) * -100)
    else
      value = math.round((value - 0.5) * 100)
    end
    env_pan_value[location] = value

  end
  if env_pan_value[instrument.pan.length-1] == EMPTY_CELL then
    env_pan_value[instrument.pan.length-1] = VOL_PAN_TERMINATION
  end
  
--loop-mode and points
  pan_loop_type = instrument.pan.loop_mode
  ea_gui.views['envelope_panning_loop_toggle'].text = ENV_LOOP_TYPE[pan_loop_type]
  if pan_loop_type > ENV_LOOP_OFF then
    pan_loop_start = instrument.pan.loop_start -1
    pan_loop_end = instrument.pan.loop_end -1
  end
--sustain
  if instrument.pan.sustain_enabled then
    pan_sustain = instrument.pan.sustain_position - 1
  else
    pan_sustain = -1
  end

--lfo
  pan_lfo1_type = instrument.pan.lfo1.mode
  pan_lfo1_phase = instrument.pan.lfo1.phase
  pan_lfo1_freq = instrument.pan.lfo1.frequency
  pan_lfo1_amount = instrument.pan.lfo1.amount
  pan_lfo2_type = instrument.pan.lfo2.mode
  pan_lfo2_phase = instrument.pan.lfo2.phase
  pan_lfo2_freq = instrument.pan.lfo2.frequency
  pan_lfo2_amount = instrument.pan.lfo2.amount
    
  set_cursor_location()
end


---------------------------------------------------------------------------------------

function fetch_cut_res_envelopes()
--Get cuttoff and resonance values from the envelope and lfo
  local song = renoise.song()
  local tool_instrument = ea_gui.views['instrument_selection'].value
  local instrument = song.instruments[tool_instrument].sample_envelopes
  local cut_points = #instrument.cutoff.points
  local res_points = #instrument.resonance.points

  cut_scheme_size = instrument.cutoff.length
  res_scheme_size = instrument.resonance.length
  env_cut_scheme = ''
  cutoff_point_scheme = ''
  env_res_scheme = ''
  resonance_point_scheme = ''
  init_tables(false)

--Filter type
  cutres_filter_type = instrument.filter_type

--envelope-type
  cutoff_enabled = instrument.cutoff.enabled
  env_cutoff_type = instrument.cutoff.play_mode

  resonance_enabled = instrument.resonance.enabled
  env_resonance_type = instrument.resonance.play_mode

--x/y values

  for t = 1, cut_points do
    local value = tonumber(instrument.cutoff.points[t].value)
    local location = tonumber(instrument.cutoff.points[t].time) - 1
    if location > (instrument.cutoff.length-1) then
      break
    end
    
    env_cut_value[location] = value
    if t == 1 then
      env_cut_scheme = tostring(value)
      cutoff_point_scheme = tostring(location)
    
    else
      env_cut_scheme = env_cut_scheme..','..tostring(value)
      cutoff_point_scheme = cutoff_point_scheme..','..tostring(location)
    
    end
  end
  
  for t = 1, res_points do
    local value = tonumber(instrument.resonance.points[t].value)
    local location = tonumber(instrument.resonance.points[t].time) - 1
    if location > (instrument.resonance.length-1) then
      break
    end
    
    env_res_value[location] = value
    if t == 1 then
      env_res_scheme = tostring(value)
      resonance_point_scheme = tostring(location)
    
    else
      env_res_scheme = env_res_scheme..','..tostring(value)
      resonance_point_scheme = resonance_point_scheme..','..tostring(location)
    
    end
  end

  
--loop-mode and points
  cut_loop_type = instrument.cutoff.loop_mode
  cut_loop_start = instrument.cutoff.loop_start -1
  cut_loop_end = instrument.cutoff.loop_end -1

  res_loop_type = instrument.resonance.loop_mode
  res_loop_start = instrument.resonance.loop_start -1
  res_loop_end = instrument.resonance.loop_end -1

--sustain
  if instrument.cutoff.sustain_enabled then
    cut_sustain = instrument.cutoff.sustain_position
  else
    cut_sustain = -1
  end

  if instrument.resonance.sustain_enabled then
    res_sustain = instrument.resonance.sustain_position
  else
    res_sustain = -1
  end

--lfo
  cut_lfo_type = instrument.cutoff.lfo.mode
  cut_lfo_phase = instrument.cutoff.lfo.phase
  cut_lfo_freq = instrument.cutoff.lfo.frequency
  cut_lfo_amount = instrument.cutoff.lfo.amount
  cut_follow = instrument.cutoff.follower.enabled
  cut_follow_attack = instrument.cutoff.follower.attack
  cut_follow_release = instrument.cutoff.follower.release
  cut_follow_amount = instrument.cutoff.follower.amount

  res_lfo_type = instrument.resonance.lfo.mode
  res_lfo_phase = instrument.resonance.lfo.phase
  res_lfo_freq = instrument.resonance.lfo.frequency
  res_lfo_amount = instrument.resonance.lfo.amount
  res_follow = instrument.resonance.follower.enabled
  res_follow_attack = instrument.resonance.follower.attack
  res_follow_release = instrument.resonance.follower.release
  res_follow_amount = instrument.resonance.follower.amount
  
  --when saving, these values should be read from the envelopes!
  note_lfo1_type = instrument.pitch.lfo1.mode
  note_lfo1_phase = instrument.pitch.lfo1.phase
  note_lfo1_freq = instrument.pitch.lfo1.frequency
  note_lfo1_amount = instrument.pitch.lfo1.amount
  note_lfo2_type = instrument.pitch.lfo2.mode
  note_lfo2_phase = instrument.pitch.lfo2.phase
  note_lfo2_freq = instrument.pitch.lfo2.frequency
  note_lfo2_amount = instrument.pitch.lfo2.amount
    
  vol_lfo1_type = instrument.volume.lfo1.mode
  vol_lfo1_phase = instrument.volume.lfo1.phase
  vol_lfo1_freq = instrument.volume.lfo1.frequency
  vol_lfo1_amount = instrument.volume.lfo1.amount
  vol_lfo2_type = instrument.volume.lfo2.mode
  vol_lfo2_phase = instrument.volume.lfo2.phase
  vol_lfo2_freq = instrument.volume.lfo2.frequency
  vol_lfo2_amount = instrument.volume.lfo2.amount  
  
  pan_lfo1_type = instrument.pan.lfo1.mode
  pan_lfo1_phase = instrument.pan.lfo1.phase
  pan_lfo1_freq = instrument.pan.lfo1.frequency
  pan_lfo1_amount = instrument.pan.lfo1.amount
  pan_lfo2_type = instrument.pan.lfo2.mode
  pan_lfo2_phase = instrument.pan.lfo2.phase
  pan_lfo2_freq = instrument.pan.lfo2.frequency
  pan_lfo2_amount = instrument.pan.lfo2.amount
    

end

---------------------------------------------------------------------------------------


function get_current_data(column)
--Prepare concatenated strings for saving by the preset manager.
  local song = renoise.song()
  local tool_instrument = ea_gui.views['instrument_selection'].value
  local instrument = song.instruments[tool_instrument].sample_envelopes
  
  env_pitch_scheme = ''
  note_point_scheme = ''
  env_vol_scheme = ''
  volume_point_scheme = ''
  env_pan_scheme = ''
  panning_point_scheme = ''

  fetch_cut_res_envelopes() 
       
  for t = 0, note_scheme_size do
    local table_number = 0
    if string.sub(env_note_value[t],1,1) ~= '[' then
      table_number = tonumber(env_note_value[t])
    end
    if table_number < EMPTY_CELL then
      if t == 0 then
        env_pitch_scheme = tostring(env_note_value[t])
        note_point_scheme = tostring(t)
      else
        env_pitch_scheme = env_pitch_scheme .. ',' .. tostring(env_note_value[t])
        note_point_scheme = note_point_scheme .. ',' .. tostring(t)
      end
      if table_number == NOTE_SCHEME_TERMINATION then
        break
      end
    end
  end
    
  if vol_scheme_size ~= nil then
    for t = 0, vol_scheme_size do
      if tonumber(env_vol_value[t]) < EMPTY_CELL then
        if t == 0 then
          env_vol_scheme = tostring(env_vol_value[t])
          volume_point_scheme = tostring(t)
        else
          env_vol_scheme = env_vol_scheme .. ',' .. tostring(env_vol_value[t])
          volume_point_scheme = volume_point_scheme .. ',' .. tostring(t)
        end
        if tonumber(env_vol_value[t]) == VOL_PAN_TERMINATION then
          break
        end
        
      end
    end
  end
    
  if pan_scheme_size ~= nil then
    for t = 0, pan_scheme_size do
      if tonumber(env_pan_value[t]) < EMPTY_CELL then
        if t == 0 then
          env_pan_scheme = tostring(env_pan_value[t])
          panning_point_scheme = tostring(t)
        else
          env_pan_scheme = env_pan_scheme .. ',' .. tostring(env_pan_value[t])
          panning_point_scheme = panning_point_scheme .. ',' .. tostring(t)
        end
        if tonumber(env_pan_value[t]) == VOL_PAN_TERMINATION then
          break
        end
      end
    end
  end

  note_loop_type = instrument.pitch.loop_mode
  env_pitch_type = instrument.pitch.play_mode

  if instrument.pitch.sustain_enabled then
    note_sustain = instrument.pitch.sustain_position - 1
  else
    note_sustain = -1
  end

  if column == nil then
    vol_loop_type = instrument.volume.loop_mode
    env_volume_type = instrument.volume.play_mode
    vol_release = instrument.volume.fade_amount    

    if auto_vol_loop == ARP_MODE_OFF then
      vol_loop_start = instrument.volume.loop_start - 1
      vol_loop_end = instrument.volume.loop_end - 1
    end

    if instrument.volume.sustain_enabled then
      vol_sustain = instrument.volume.sustain_position - 1
    else
      vol_sustain = -1
    end

    pan_loop_type = instrument.pan.loop_mode
    env_panning_type = instrument.pan.play_mode

    if auto_pan_loop == ARP_MODE_OFF then
      pan_loop_start = instrument.pan.loop_start - 1
      pan_loop_end = instrument.pan.loop_end - 1
    end
    
    if instrument.pan.sustain_enabled then
      pan_sustain = instrument.pan.sustain_position - 1
    else
      pan_sustain = -1
    end  
    
  end
    
end



---------------------------------------------------------------------------------------

function apply_unattended_properties()
  local song = renoise.song()
  local tool_instrument = ea_gui.views['instrument_selection'].value
  local instrument = song.instruments[tool_instrument].sample_envelopes

  disable_cut_res_lfo()
  
  if note_lfo_data then
    set_note_lfo_data(instrument)
  end
  if vol_lfo_data then
    set_vol_lfo_data(instrument)
  end
  if pan_lfo_data then
    set_pan_lfo_data(instrument)
  end
  if cut_lfo_data then
    set_cut_lfo_data(instrument)
  end
  if res_lfo_data then
    set_res_lfo_data(instrument)
  end
  if cutoff_data then
    set_cutoff_data(instrument)
  end
  if resonance_data then
    set_resonance_data(instrument)
  end
  
end

---------------------------------------------------------------------------------------

function disable_cut_res_lfo()

  local song = renoise.song()
  local tool_instrument = ea_gui.views['instrument_selection'].value
  local instrument = song.instruments[tool_instrument].sample_envelopes
  instrument.pitch.lfo1.mode = 1
  instrument.pitch.lfo2.mode = 1
  instrument.volume.lfo1.mode = 1
  instrument.volume.lfo2.mode = 1
  instrument.pan.lfo1.mode = 1
  instrument.pan.lfo2.mode = 1

  instrument.cutoff.enabled = false
  instrument.cutoff.lfo.mode = 1
  instrument.cutoff.follower.enabled = false
  instrument.resonance.enabled = false
  instrument.resonance.lfo.mode = 1 
  instrument.resonance.follower.enabled = false
  
end

---------------------------------------------------------------------------------------

function set_note_lfo_data(instrument)
  instrument.pitch.lfo1.mode = note_lfo1_type
  instrument.pitch.lfo1.phase = note_lfo1_phase
  instrument.pitch.lfo1.frequency = note_lfo1_freq
  instrument.pitch.lfo1.amount = note_lfo1_amount
  instrument.pitch.lfo2.mode = note_lfo2_type
  instrument.pitch.lfo2.phase = note_lfo2_phase
  instrument.pitch.lfo2.frequency = note_lfo2_freq
  instrument.pitch.lfo2.amount = note_lfo2_amount
end

function set_vol_lfo_data(instrument)
  instrument.volume.lfo1.mode = vol_lfo1_type
  instrument.volume.lfo1.phase = vol_lfo1_phase
  instrument.volume.lfo1.frequency = vol_lfo1_freq
  instrument.volume.lfo1.amount = vol_lfo1_amount
  instrument.volume.lfo2.mode = vol_lfo2_type
  instrument.volume.lfo2.phase = vol_lfo2_phase
  instrument.volume.lfo2.frequency = vol_lfo2_freq
  instrument.volume.lfo2.amount = vol_lfo2_amount
end

function set_pan_lfo_data(instrument)
  instrument.pan.lfo1.mode = pan_lfo1_type
  instrument.pan.lfo1.phase = pan_lfo1_phase
  instrument.pan.lfo1.frequency = pan_lfo1_freq
  instrument.pan.lfo1.amount = pan_lfo1_amount
  instrument.pan.lfo2.mode = pan_lfo2_type
  instrument.pan.lfo2.phase = pan_lfo2_phase
  instrument.pan.lfo2.frequency = pan_lfo2_freq
  instrument.pan.lfo2.amount = pan_lfo2_amount
end

function set_cut_lfo_data(instrument)
  if instrument.filter_type ~= cutres_filter_type then
    instrument.filter_type = cutres_filter_type
  end
  instrument.cutoff.lfo.mode = cut_lfo_type 
  instrument.cutoff.lfo.phase = cut_lfo_phase 
  instrument.cutoff.lfo.frequency = cut_lfo_freq
  instrument.cutoff.lfo.amount = cut_lfo_amount
  instrument.cutoff.follower.enabled = toboolean(cut_follow)
-- First change the release, then the attack, due to a bug in the LFO's value changing routine
  if cut_follow_release > 0 then
    instrument.cutoff.follower.release = cut_follow_release
    instrument.cutoff.follower.attack = cut_follow_attack
    instrument.cutoff.follower.amount = cut_follow_amount
  end
end

function set_res_lfo_data(instrument)
  if instrument.filter_type ~= cutres_filter_type then
    instrument.filter_type = cutres_filter_type
  end
  instrument.resonance.lfo.mode = res_lfo_type 
  instrument.resonance.lfo.phase = res_lfo_phase 
  instrument.resonance.lfo.frequency = res_lfo_freq
  instrument.resonance.lfo.amount = res_lfo_amount
  instrument.resonance.follower.enabled = toboolean(res_follow)
-- First change the release, then the attack, due to a bug in the LFO's value changing routine
  if res_follow_release > 0 then
    instrument.resonance.follower.release = res_follow_release
    instrument.resonance.follower.attack = res_follow_attack
    instrument.resonance.follower.amount = res_follow_amount
  end
end

---------------------------------------------------------------------------------------

function set_cutoff_data(instrument)
  if instrument.filter_type ~= cutres_filter_type then
    instrument.filter_type = cutres_filter_type
  end
  
  if cut_scheme_size >= 6 then
    instrument.cutoff.length = cut_scheme_size
  else
    instrument.cutoff.length = 6
  end  
  
  instrument.cutoff.play_mode = env_cutoff_type
  instrument.cutoff.enabled = toboolean(cutoff_enabled)
  instrument.cutoff.loop_mode = cut_loop_type

  if cut_loop_type > ENV_LOOP_OFF then
    instrument.cutoff.loop_start = cut_loop_start + 1
    instrument.cutoff.loop_end = cut_loop_end + 1
  end
  if cut_sustain > -1 then
    instrument.cutoff.sustain_enabled = true
    instrument.cutoff.sustain_position = cut_sustain
  else
    instrument.cutoff.sustain_enabled = false
  end

  instrument.cutoff:clear_points()

  for x = 0,cut_scheme_size do
    if env_cut_value[x] ~= nil then
      if tonumber(env_cut_value[x]) < VOL_PAN_TERMINATION then
        local cut_value = tonumber(env_cut_value[x])
        instrument.cutoff:add_point_at(x+1,cut_value)
      end
    end
  end  

end

---------------------------------------------------------------------------------------

function set_resonance_data(instrument)
  if instrument.filter_type ~= cutres_filter_type then
    instrument.filter_type = cutres_filter_type
  end

  if res_scheme_size >= 6 then
    instrument.resonance.length = res_scheme_size
  else
    instrument.resonance.length = 6
  end

  instrument.resonance.play_mode = env_resonance_type
  instrument.resonance.enabled = toboolean(resonance_enabled)
  instrument.resonance.loop_mode = res_loop_type

  if res_loop_type > ENV_LOOP_OFF then
    instrument.resonance.loop_start = res_loop_start + 1
    instrument.resonance.loop_end = res_loop_end + 1
  end
  if res_sustain > -1 then
    instrument.resonance.sustain_enabled = true
    instrument.resonance.sustain_position = res_sustain
  else
    instrument.resonance.sustain_enabled = false
  end

  instrument.resonance:clear_points()

  for x = 0,res_scheme_size do
    if env_res_value[x] ~= nil then
      if tonumber(env_res_value[x]) < VOL_PAN_TERMINATION then
        local res_value = tonumber(env_res_value[x])
        instrument.resonance:add_point_at(x+1,res_value)
      end
    end
  end  

end

---------------------------------------------------------------------------------------

function populate_cutres_tables(envelope)
    local y_value_table = {}
    local x_value_table = {}
    local end_node = #y_value_table
    local leading_table = 1 --Notes
    local sub_position = 1
        
    if envelope == ENV_CUT then
      y_value_table = env_cut_scheme:split( "[^,%s]+" )
      x_value_table = cutoff_point_scheme:split( "[^,%s]+" )

    elseif envelope == ENV_RES then
      y_value_table = env_res_scheme:split( "[^,%s]+" )
      x_value_table = resonance_point_scheme:split( "[^,%s]+" )

    end
          
    end_node = #y_value_table
          
    if #y_value_table < #x_value_table then
      end_node = #x_value_table
      leading_table = 2
    end
          
    if #y_value_table == #x_value_table then
      leading_table = -1
    end
          
    if leading_table == 1 then
      sub_position = 2
            
      for t = #x_value_table+1, end_node do
        local new_val = tonumber(x_value_table[sub_position]) -
                        tonumber(x_value_table[sub_position -1])
        x_value_table[t] = tonumber(x_value_table[t-1])+new_val
        sub_position = sub_position + 1
      end
    else
      for t = #y_value_table+1, end_node do
        y_value_table[t] = y_value_table[sub_position]
        sub_position = sub_position + 1
        if sub_position > #y_value_table then
          sub_position = 1
        end
      end
    end
    
    for t = 1, end_node do
      if y_value_table[t] ~= nil and x_value_table[t] ~= nil then
        if envelope == ENV_CUT then
          env_cut_value[tonumber(x_value_table[t])] = y_value_table[t]
        elseif envelope == ENV_RES then
          env_res_value[tonumber(x_value_table[t])] = y_value_table[t]
        end
      end
    end

end

---------------------------------------------------------------------------------------


function apply_table_to_envelope()
  if note_scheme_size == 0 or note_scheme_size == -1 then
    construct_envelope ()
  else
    set_pitch_table()
    construct_envelope ()
  end
end

---------------------------------------------------------------------------------------

function handle_pitch_envelope()
  fetch_pitch_envelope(true)
end

---------------------------------------------------------------------------------------

function handle_volume_envelope()
  fetch_volume_envelope(true)
end

---------------------------------------------------------------------------------------


function handle_panning_envelope()
  fetch_panning_envelope(true)
end

function fetch_from_renoise()
end

---------------------------------------------------------------------------------------


function set_envelope_notifiers (new_instrument)
  local song = renoise.song()
  local nw_instrument = song.instruments[new_instrument].sample_envelopes  
  
  remove_envelope_notifiers ()

  if not nw_instrument.pitch.loop_start_observable:has_notifier(handle_pitch_envelope) then
    nw_instrument.pitch.loop_start_observable:add_notifier(handle_pitch_envelope)
  end
  if not nw_instrument.pitch.loop_end_observable:has_notifier(handle_pitch_envelope) then
    nw_instrument.pitch.loop_end_observable:add_notifier(handle_pitch_envelope)
  end
  if not nw_instrument.pitch.loop_mode_observable:has_notifier(handle_pitch_envelope) then
    nw_instrument.pitch.loop_mode_observable:add_notifier(handle_pitch_envelope)
  end
  if not nw_instrument.pitch.sustain_position_observable:has_notifier(handle_pitch_envelope) then
    nw_instrument.pitch.sustain_position_observable:add_notifier(handle_pitch_envelope)
  end
  if not nw_instrument.pitch.sustain_enabled_observable:has_notifier(handle_pitch_envelope) then
    nw_instrument.pitch.sustain_enabled_observable:add_notifier(handle_pitch_envelope)
  end

  if not nw_instrument.pitch.length_observable:has_notifier(handle_pitch_envelope) then
    nw_instrument.pitch.length_observable:add_notifier(handle_pitch_envelope)
  end
  if not nw_instrument.pitch.play_mode_observable:has_notifier(handle_pitch_envelope) then
    nw_instrument.pitch.play_mode_observable:add_notifier(handle_pitch_envelope)
  end
  if not nw_instrument.pitch.points_observable:has_notifier(handle_pitch_envelope) then
    nw_instrument.pitch.points_observable:add_notifier(handle_pitch_envelope)
  end


  
  if not nw_instrument.volume.enabled_observable:has_notifier(handle_volume_envelope) then
    nw_instrument.volume.enabled_observable:add_notifier(handle_volume_envelope)
  end

  if not nw_instrument.volume.loop_start_observable:has_notifier(handle_volume_envelope) then
    nw_instrument.volume.loop_start_observable:add_notifier(handle_volume_envelope)
  end

  if not nw_instrument.volume.loop_end_observable:has_notifier(handle_volume_envelope) then
    nw_instrument.volume.loop_end_observable:add_notifier(handle_volume_envelope)
  end

  if not nw_instrument.volume.loop_mode_observable:has_notifier(handle_volume_envelope) then
    nw_instrument.volume.loop_mode_observable:add_notifier(handle_volume_envelope)
  end

  if not nw_instrument.volume.sustain_position_observable:has_notifier(handle_volume_envelope) then
    nw_instrument.volume.sustain_position_observable:add_notifier(handle_volume_envelope)
  end

  if not nw_instrument.volume.sustain_enabled_observable:has_notifier(handle_volume_envelope) then
    nw_instrument.volume.sustain_enabled_observable:add_notifier(handle_volume_envelope)
  end

  if not nw_instrument.volume.length_observable:has_notifier(handle_volume_envelope) then
    nw_instrument.volume.length_observable:add_notifier(handle_volume_envelope)
  end
  if not nw_instrument.volume.play_mode_observable:has_notifier(handle_volume_envelope) then
    nw_instrument.volume.play_mode_observable:add_notifier(handle_volume_envelope)
  end
  if not nw_instrument.volume.points_observable:has_notifier(handle_volume_envelope) then
    nw_instrument.volume.points_observable:add_notifier(handle_volume_envelope)
  end

  if not nw_instrument.volume.fade_amount_observable:has_notifier(handle_volume_envelope) then
    nw_instrument.volume.fade_amount_observable:add_notifier(handle_volume_envelope)
  end



  if not nw_instrument.pan.enabled_observable:has_notifier(handle_panning_envelope) then
    nw_instrument.pan.enabled_observable:add_notifier(handle_panning_envelope)
  end

  if not nw_instrument.pan.loop_start_observable:has_notifier(handle_panning_envelope) then
    nw_instrument.pan.loop_start_observable:add_notifier(handle_panning_envelope)
  end

  if not nw_instrument.pan.loop_end_observable:has_notifier(handle_panning_envelope) then
    nw_instrument.pan.loop_end_observable:add_notifier(handle_panning_envelope)
  end

  if not nw_instrument.pan.loop_mode_observable:has_notifier(handle_panning_envelope) then
    nw_instrument.pan.loop_mode_observable:add_notifier(handle_panning_envelope)
  end

  if not nw_instrument.pan.sustain_position_observable:has_notifier(handle_panning_envelope) then
    nw_instrument.pan.sustain_position_observable:add_notifier(handle_panning_envelope)
  end

  if not nw_instrument.pan.sustain_enabled_observable:has_notifier(handle_panning_envelope) then
    nw_instrument.pan.sustain_enabled_observable:add_notifier(handle_panning_envelope)
  end

  if not nw_instrument.pan.length_observable:has_notifier(handle_panning_envelope) then
    nw_instrument.pan.length_observable:add_notifier(handle_panning_envelope)
  end
  if not nw_instrument.pan.play_mode_observable:has_notifier(handle_panning_envelope) then
    nw_instrument.pan.play_mode_observable:add_notifier(handle_panning_envelope)
  end
  if not nw_instrument.pan.points_observable:has_notifier(handle_panning_envelope) then
    nw_instrument.pan.points_observable:add_notifier(handle_panning_envelope)
  end


end


---------------------------------------------------------------------------------------

function remove_envelope_notifiers ()
  local song = renoise.song()
  if processing_instrument > #song.instruments then
    return
  end
  local instrument = song.instruments[processing_instrument].sample_envelopes  

--[[  
  if instrument.pitch.loop_start_observable:has_notifier(handle_pitch_envelope) then
    instrument.pitch.loop_start_observable:remove_notifier(handle_pitch_envelope)
  end
  if instrument.pitch.loop_end_observable:has_notifier(handle_pitch_envelope) then
    instrument.pitch.loop_end_observable:remove_notifier(handle_pitch_envelope)
  end
  if instrument.pitch.loop_mode_observable:has_notifier(handle_pitch_envelope) then
    instrument.pitch.loop_mode_observable:remove_notifier(handle_pitch_envelope)
  end
  if instrument.pitch.sustain_position_observable:has_notifier(handle_pitch_envelope) then
    instrument.pitch.sustain_position_observable:remove_notifier(handle_pitch_envelope)
  end
--]]
  if instrument.pitch.length_observable:has_notifier(handle_pitch_envelope) then
    instrument.pitch.length_observable:remove_notifier(handle_pitch_envelope)
  end
  if instrument.pitch.play_mode_observable:has_notifier(handle_pitch_envelope) then
    instrument.pitch.play_mode_observable:remove_notifier(handle_pitch_envelope)
  end
  if instrument.pitch.points_observable:has_notifier(handle_pitch_envelope) then
    instrument.pitch.points_observable:remove_notifier(handle_pitch_envelope)
  end


  if instrument.volume.length_observable:has_notifier(handle_volume_envelope) then
    instrument.volume.length_observable:remove_notifier(handle_volume_envelope)
  end
  if instrument.volume.play_mode_observable:has_notifier(handle_volume_envelope) then
    instrument.volume.play_mode_observable:remove_notifier(handle_volume_envelope)
  end
  if instrument.volume.points_observable:has_notifier(handle_volume_envelope) then
    instrument.volume.points_observable:remove_notifier(handle_volume_envelope)
  end

  if instrument.pan.length_observable:has_notifier(handle_panning_envelope) then
    instrument.pan.length_observable:remove_notifier(handle_panning_envelope)
  end
  if instrument.pan.play_mode_observable:has_notifier(handle_panning_envelope) then
    instrument.pan.play_mode_observable:remove_notifier(handle_panning_envelope)
  end
  if instrument.pan.points_observable:has_notifier(handle_panning_envelope) then
    instrument.pan.points_observable:remove_notifier(handle_panning_envelope)
  end

end


--------------------------------------------------------------------------------
--The following stuff is to fetch notes from the patterns and translate them to
--envelope-values

function note_fetcher()
  columns_to_fetch = 1
  if key_state == LCAP or key_state == RCAP then
    --Fetch notes single notecolumn
    save_undo_state('Fetched notes from pattern column')
    area_to_fetch = OPTION_COLUMN_IN_PATTERN

  elseif key_state == LCMD or key_state == RCMD then
    --Fetch note/vol/pan single/multiple notecolumns
    save_undo_state('Fetched note/vol/pan from pattern track')
    area_to_fetch = OPTION_TRACK_IN_PATTERN
    columns_to_fetch = 3

  elseif key_state == LALT or key_state == RALT then
    --Fetch selected notes single/multiple notecolumns
    save_undo_state('Fetched notes from pattern selection')
    area_to_fetch = OPTION_SELECTION_IN_TRACK

  elseif key_state == (LCMD + LALT) or key_state == (RCMD + RALT) or
         key_state == (RCMD + LALT) or key_state == (LCMD + RALT) then
    --Fetch selected note/vol/pan single/multiple notecolumns
    save_undo_state('Fetched note/vol/pan from pattern selection')
    area_to_fetch = OPTION_SELECTION_IN_TRACK
    columns_to_fetch = 3
    
  elseif key_state == (LCMD + LCAP) or key_state == (RCMD + RCAP) or
         key_state == (RCMD + LCAP) or key_state == (LCMD + RCAP) then
    --Fetch note/vol/pan single notecolumn
    save_undo_state('Fetched note/vol/pan from pattern column')
    area_to_fetch = OPTION_COLUMN_IN_PATTERN
    columns_to_fetch = 3
    
  elseif key_state == 0 then
    save_undo_state('Fetched notes from pitch envelope')
    fetch_pitch_envelope(false)
    return

  end

  note_freq_type = FREQ_TYPE_FREEFORM
  
  fetch_pattern_contents(ENV_NOTE_COLUMN)
  prepare_note_tables(ENV_NOTE_COLUMN)
  if columns_to_fetch == 3 then
    prepare_note_tables(ENV_VOL_COLUMN)
    prepare_note_tables(ENV_PAN_COLUMN)
  end
  set_cursor_location()
end

---------------------------------------------------------------------------------------

function vol_fetcher()
  columns_to_fetch = 1

  if key_state == LCAP or key_state == RCAP then
    --Fetch volume single notecolumn
    save_undo_state('Fetched volumes from pattern column')
    area_to_fetch = OPTION_COLUMN_IN_PATTERN

  elseif key_state == LALT or key_state == RALT then
    --Fetch selected volume single/multiple notecolumns
    save_undo_state('Fetched volumes from pattern selection')
    area_to_fetch = OPTION_SELECTION_IN_TRACK

  elseif key_state == 0 then
    save_undo_state('Fetched volumes from volume envelope')
    fetch_volume_envelope(false)
    return
  end
  vol_freq_type = FREQ_TYPE_FREEFORM
  
  fetch_pattern_contents(ENV_VOL_COLUMN)
  prepare_note_tables(ENV_VOL_COLUMN)
  set_cursor_location()      

end

---------------------------------------------------------------------------------------

function pan_fetcher()
  columns_to_fetch = 1

  if key_state == LCAP or key_state == RCAP then
    --Fetch panning single notecolumn
    save_undo_state('Fetched panning from pattern column')
    area_to_fetch = OPTION_COLUMN_IN_PATTERN

  elseif key_state == LALT or key_state == RALT then
    --Fetch selected panning single/multiple notecolumns
    save_undo_state('Fetched panning from pattern selection')
    area_to_fetch = OPTION_SELECTION_IN_TRACK

  elseif key_state == 0 then
    save_undo_state('Fetched panning from volume envelope')
    fetch_panning_envelope(false)
    return
  end
  pan_freq_type = FREQ_TYPE_FREEFORM
  
  fetch_pattern_contents(ENV_PAN_COLUMN)
  prepare_note_tables(ENV_PAN_COLUMN)
  set_cursor_location()      

end

---------------------------------------------------------------------------------------

function pitch_sanitizer(note_column, note_value)
  --Pitch value perimeter check
  local note_string = tostring(note_value)
  
  if note_value < -12 or note_value > 12 then
    note_string = '['..tostring(note_value)..']'
  end
  if note_column.note_string == '---' then
    note_string = tostring(EMPTY_CELL)
  end
  if note_column.note_string == 'OFF' then
    note_string = tostring(NOTE_OFF)
  end
  
  return note_string

end

---------------------------------------------------------------------------------------

function volume_sanitizer(note_column, vol_value)
  --Volume factor calculation:00 = 0%, 128/255 = 100%
  local vol_string = ''
  
  if vol_value == 128 or vol_value == 255 then
    vol_string = "100"
  elseif vol_value <128 then
    vol_string = tostring(math.round(vol_value/1.28))
  end
  if note_column.note_string == 'OFF' then
    vol_string = tostring(ea_gui.views['vol_assist_low_val'].value)
  end
  if note_column.note_string == '---' and vol_value == 255 then
    vol_string = tostring(EMPTY_CELL)
  end 
  
  return vol_string
  
end

---------------------------------------------------------------------------------------

function panning_sanitizer(note_column, pan_value)
  --panning direction calculation:00 = -50, 64 = 0, 128 = +50, 255 = unchanged
  local pan_string = ''
  local pan_pos_val = 0
  
  if pan_value>64 and pan_value <=128 then
    pan_pos_val = ((pan_value - 64) / .64)*.5
  elseif pan_value<64 then
    pan_pos_val = ((pan_value / .64)*.5)-50
  end
  if pan_value ~= 255 then
    pan_string = tostring(math.round(pan_pos_val))
  else
    pan_string = tostring(EMPTY_CELL)
  end
  
  return pan_string
end

---------------------------------------------------------------------------------------

function serialize_val_point_tables(column_table, bound, offset, column_type, multicolumn)
--This routine splits out the note/vol/pan values and their positions into two
--serialized strings. It will also figure out if multi-column chords have been
--fetched from the pattern or whether we are dealing with single notes.
--If we have chords, how many points should they fill until the next note or noteoff?
  if bound == -1 or bound == nil then
    return '9999,9999,9999,9999,9999,2222','0,1,2,3,4,5',-1
  end

  local position = 0
  local val_scheme = ''
  local point_scheme = ''
  local first_pos_filled = false
  local lowest_pos = -1
  local start = 0
  local selected_contents = {}
  local table = {}
  selected_contents['columns'] = {}
  if column_type == ENV_NOTE_COLUMN then
    table = column_table.note
  elseif column_type == ENV_VOL_COLUMN then
    table = column_table.vol
  elseif column_type == ENV_PAN_COLUMN then
    table = column_table.pan
  end
  for t = 1, 12 do
    selected_contents['c'..tostring(t)] = {}
  end

  --Offset is the starting point from the selection of the column that has the first item.
  if offset ~= -1 then
    start = start + offset
  end
  --change selected_contents[x] into selected_contents[x][y]
  --This way you can translate multiple columns directly without having to worry
  --about positioning on point mode here.
  --though take care that if a splitted table contains only one value and a nil value
  --that the nil value never ends up in the selected_contents[x][y]
  --#selected_contents[x] should either always be 1 or higher when more content is in there
  for t = start, bound do
    
    if table[t] ~= nil then
      local split_var = table[t] 
      local multinode = split_var:split("[^,%s]+")
      selected_contents['columns'][position] = #multinode
      for _ = 1, #multinode do
        if multinode[_] ~= nil then
          selected_contents['c'..tostring(_)][position] = multinode[_]
        end
      end

      if lowest_pos == -1 then
        lowest_pos = t
      end

      first_pos_filled = true
    end

    if first_pos_filled then
      position = position + 1
    end
                
  end

  position = 0

  local first_chord_note = false
  local freq_type = row_frequency_step

  if multicolumn then
    freq_type = FREQ_TYPE_LINES
  end
  
  for _ = 0, bound do
    local line_empty = check_note_row(selected_contents, _)

    if not line_empty then
      selected_contents = convert_note_off(selected_contents, _)
      local count = get_chord_count(_,bound, selected_contents)
      
      if not multicolumn then
        count = 1
      end
      
      if position == 0 then
        val_scheme = selected_contents['c1'][_]
        if selected_contents['columns'][_] >= 2 and multicolumn then
          local offset = 2
          --How many chords to fill up the empty space with?
          --fill her up (the same routine is applied for pan and volume columns!
          for u = 1, count do
            for v = offset, selected_contents['columns'][_] do
              val_scheme = val_scheme..","..selected_contents['c'..tostring(v)][_]
            end
            offset = 1
          end
        end
      else
        --val_scheme = val_scheme..","..selected_contents['c1'][_]
        local tcolumns = selected_contents['columns'][_]
        if selected_contents['columns'][_] == 1 or not multicolumn then
          count = 1
          tcolumns = 1
        end
        for u = 1, count do
          for v = 1, tcolumns do
            val_scheme = val_scheme..","..selected_contents['c'..tostring(v)][_]
          end
        end
      end

      local point_pos = _

      --If multimode, then freq_type is always lines, period.
      --yet if [y] of selected_contents[x][y] is higher than 2 (more columns filled)
      --then we sneaky fill in the note_chord_spacing distance.
      
      if freq_type == FREQ_TYPE_LINES then
        point_pos = _*sample_envelope_line_sync()
      end
               
      if position == 0 then
        point_scheme = tostring(point_pos)
        if selected_contents['columns'][_] >= 2 and multicolumn then
          local sub_pos = point_pos + ea_gui.views['note_chord_spacing'].value
          local offset = 2
          for u = 1, count do
            for v = offset, selected_contents['columns'][_] do
              point_scheme = point_scheme..","..tostring(sub_pos)
              sub_pos = sub_pos + ea_gui.views['note_chord_spacing'].value
            end
            offset = 1
          end          
        end
        position = 1
      else
--        point_scheme = point_scheme..","..tostring(point_pos)
--        if selected_contents['columns'][_] >= 2 then
        local sub_pos = point_pos + ea_gui.views['note_chord_spacing'].value
        if not multicolumn then
          sub_pos = point_pos
        end
        local tcolumns = selected_contents['columns'][_]
        if selected_contents['columns'][_] == 1 or not multicolumn then
          count = 1
          tcolumns = 1
        end
          for u = 1, count do
            for v = 1, tcolumns do
              point_scheme = point_scheme..","..tostring(sub_pos)
              sub_pos = sub_pos + ea_gui.views['note_chord_spacing'].value
            end
            offset = 1
          end          
        --end
      end

    end
  end
  
  return val_scheme, point_scheme, lowest_pos
end

---------------------------------------------------------------------------------------

function get_chord_count(cur_pos,lines, selected_contents)
--Here is where the chord calculation magic happens.
--How many lines till a next note or note-off value?
--And how many points do these represent?
--this complete amount of lines should be filled with chords

  local chord_range_size = 1
  local chord_notes = selected_contents['columns'][cur_pos] --How many notes (points) in one chord?
  local chord_start = cur_pos  --Where do we start?
  local chord_end = cur_pos
  local points_per_chord = ea_gui.views['note_chord_spacing'].value
  
  for s =  cur_pos+1, lines do
    if not check_note_row(selected_contents, s) then 
      chord_end = s 
      break
    end
  end
  chord_range_size = ((chord_end - chord_start)+1)*sample_envelope_line_sync()
--  print('position:',cur_pos,'/',(cur_pos*sample_envelope_line_sync()),'points per chord:',
--         points_per_chord,'chord_size:',chord_range_size,'chord_count:',chord_range_size / (points_per_chord*chord_notes),
--         'next line:',chord_end)

  return math.ceil(chord_range_size / (points_per_chord*chord_notes))
end

---------------------------------------------------------------------------------------

function check_note_row(note_row,position)
  if note_row['columns'][position] == nil then
    return true
  end
  
  for _ = 1, note_row['columns'][position] do
    if string.sub(note_row['c'..tostring(_)][position],1,1) ~= '[' then
      if tonumber(note_row['c'..tostring(_)][position]) < EMPTY_CELL then
        return false
      end
    else
      return false
    end
  end
  
  return true
end

---------------------------------------------------------------------------------------

function convert_note_off(note_row,position)
  
  for _ = 1, note_row['columns'][position] do
    
    if note_row['c'..tostring(_)][position] == tostring(NOTE_OFF) then
      note_row['c'..tostring(_)][position] = tostring(EMPTY_CELL)
    end
  end
  return note_row
end

--------------------------------------------------------------------------------

function fetch_pattern_contents(content_type)
  local song = renoise.song()     
  local pattern_lines = song.selected_pattern.number_of_lines
  local pattern_index = song.selected_pattern_index
  local track_index = song.selected_track_index
  local track_type = song.selected_track.type
  local visible_note_columns = song.tracks[track_index].visible_note_columns
  local iter, pos, multi_column, count=0
  local table = {note={},vol={},pan={}}
  local pan_pos_val, last_fetched_pos
  local lowest_pos = 0
  column_offset = song.selected_note_column_index 
  env_pitch_scheme = ''
  note_point_scheme = ''
  env_vol_scheme = ''
  volume_point_scheme = ''
  env_pan_scheme = ''
  panning_point_scheme = ''
  if song.patterns[pattern_index].tracks[track_index].is_empty then
    return
  end
  --Correct the spacing value if LPB has changed
  if ea_gui.views['note_chord_spacing'].value > sample_envelope_line_sync(false)-1 then
    ea_gui.views['note_chord_spacing'].value = sample_envelope_line_sync(false)-1
    note_chord_spacing = sample_envelope_line_sync(false)-1
  end
    
  if track_type ~= renoise.Track.TRACK_TYPE_MASTER and
  track_type ~= renoise.Track.TRACK_TYPE_SEND and 
  track_type ~= renoise.Track.TRACK_TYPE_GROUP then

    iter = song.pattern_iterator:lines_in_pattern_track(pattern_index, track_index)
    renoise.app():show_status("Fetching contents from pattern-track")
      
    for pos,line in iter do
      count = 0
      for cur_column,note_column in ipairs(line.note_columns) do
        if cur_column <= visible_note_columns then
          local note_value = note_column.note_value - 48
          local note_string = tostring(note_value)
          local vol_value = note_column.volume_value
          local pan_value = note_column.panning_value
          local vol_string, pan_string

          if area_to_fetch == OPTION_SELECTION_IN_TRACK and note_column.is_selected or 
            area_to_fetch == OPTION_TRACK_IN_PATTERN then
            --Selection can contain chords, track can contain chords!
            
            note_string = pitch_sanitizer(note_column, note_value)                  
            vol_string = volume_sanitizer(note_column, vol_value)
            pan_string = panning_sanitizer(note_column, pan_value)
            if count == 0 then
              table.note[pos.line -1] = note_string
              table.vol[pos.line -1] = vol_string
              table.pan[pos.line -1] = pan_string
              count = 1
            else
              multi_column = 1
              table.note[pos.line -1] = table.note[pos.line -1]..','..note_string
              table.vol[pos.line -1] = table.vol[pos.line -1]..','..vol_string
              table.pan[pos.line -1] = table.pan[pos.line -1]..','..pan_string
            end
            last_fetched_pos = pos.line - 1
            
          elseif area_to_fetch == OPTION_COLUMN_IN_PATTERN and cur_column == column_offset then
            --Only content in the column is gathered
            note_string = pitch_sanitizer(note_column, note_value)                  
            vol_string = volume_sanitizer(note_column, vol_value)
            pan_string = panning_sanitizer(note_column, pan_value)
            table.note[pos.line -1] = note_string
            table.vol[pos.line -1] = vol_string
            table.pan[pos.line -1] = pan_string
            last_fetched_pos = pos.line - 1
          end
        end
      end
    end
    lowest_pos = last_fetched_pos

      -- the actual xxx_point_scheme is filled this way:
      --startpoint = 0, next point is next non-nil table value position - previous non-nil table value
      --First figure out if any of the line_table has more notes than one
      --This way we can tell if we need to force line mode or we can stay with points mode if that is currently
      --the selection. If we have to go to line mode, then fill out the single notes and the multi-notes
      --according to the note_chord_spacing as much as we can. If the next single note is residing within the 
      --generated chord perimeters, the rest of the chord is not produced.
      local selected_contents = {}
      local first_pos_filled = false
      
        if columns_to_fetch == 1 then

          if content_type == ENV_NOTE_COLUMN then
            env_pitch_scheme, note_point_scheme = serialize_val_point_tables(table, last_fetched_pos, -1,
                                                                             ENV_NOTE_COLUMN, multi_column)


          elseif content_type == ENV_VOL_COLUMN then
            env_vol_scheme, volume_point_scheme = serialize_val_point_tables(table, last_fetched_pos, -1, 
                                                                              ENV_VOL_COLUMN, multi_column)

          elseif content_type == ENV_PAN_COLUMN then
            env_pan_scheme, panning_point_scheme = serialize_val_point_tables(table, last_fetched_pos, -1, 
                                                                              ENV_PAN_COLUMN, multi_column)
          end
        else
          if lowest_pos == nil then
            return
          end
          local low_return = 0
          local position = 0
          local dmy
          dmy, dmy, low_return =  serialize_val_point_tables(table, last_fetched_pos, -1, 
                                                             ENV_NOTE_COLUMN, multi_column)       
          if low_return < lowest_pos then
            lowest_pos = low_return
          end
          dmy, dmy, low_return =  serialize_val_point_tables(table, last_fetched_pos, -1, 
                                                             ENV_VOL_COLUMN, multi_column)
          if low_return < lowest_pos then
            lowest_pos = low_return
          end
          dmy, dmy, low_return =  serialize_val_point_tables(table, last_fetched_pos, -1, 
                                                             ENV_PAN_COLUMN, multi_column)

          if low_return < lowest_pos then
            lowest_pos = low_return
          end
          --lowest_pos = -1
          
          env_pitch_scheme, note_point_scheme =  serialize_val_point_tables(table, last_fetched_pos, lowest_pos, 
                                                                            ENV_NOTE_COLUMN, multi_column)
          env_vol_scheme, volume_point_scheme =  serialize_val_point_tables(table, last_fetched_pos, lowest_pos, 
                                                                            ENV_VOL_COLUMN, multi_column)
          env_pan_scheme, panning_point_scheme =  serialize_val_point_tables(table, last_fetched_pos, lowest_pos, 
                                                                             ENV_PAN_COLUMN, multi_column)
         
        end
      
      end

     --Build volume tables, follow the notes if they exist (we have to check from the existing note_point_scheme if
     --the position is populated) when multi-volume entries are seen. If no note exists, ignore the extra column values
end

--------------------------------------------------------------------------------
--      End of teh road...
--------------------------------------------------------------------------------

  
