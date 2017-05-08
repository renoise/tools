--[[============================================================================
-- Duplex.Application.Mlrx
============================================================================]]--

--[[--

Mlrx - construct the view (assign mappings)

]]

--==============================================================================

class 'Mlrx_view' 

--------------------------------------------------------------------------------

function Mlrx_view._build_app(mlrx)

  local cm = mlrx.display.device.control_map
  local tool = renoise.tool()

  -- check for required mappings
  local map = mlrx.mappings.triggers
  if not map.group_name then
    local msg = "Warning: a required mapping ('triggers') for the application 'mlrx' is missing."
    renoise.app():show_warning(msg)
    return false
  end

  local orientation = map.orientation or ORIENTATION.HORIZONTAL

  -- determine the number of tracks
  local num_tracks = nil
  if (orientation == ORIENTATION.HORIZONTAL) then
    num_tracks = cm:count_rows(map.group_name)
  else
    num_tracks = cm:count_columns(map.group_name)
  end
  --print("num_tracks",num_tracks)

  -- determine the number of triggers
  if (orientation == ORIENTATION.HORIZONTAL) then
    mlrx._num_triggers = cm:count_columns(map.group_name)
  else
    mlrx._num_triggers = cm:count_rows(map.group_name)
  end

  -- create the logical groups ----------------------------

  for idx=1,Mlrx.NUM_GROUPS do
    mlrx.groups[idx] = Mlrx_group(mlrx)

    local color = nil
    local color_dimmed = nil

    if (idx==1) then
      color = mlrx.palette.group_a.color
      color_dimmed = mlrx.palette.group_a_dimmed.color
    elseif (idx==2) then
      color = mlrx.palette.group_b.color
      color_dimmed = mlrx.palette.group_b_dimmed.color
    elseif (idx==3) then
      color = mlrx.palette.group_c.color
      color_dimmed = mlrx.palette.group_c_dimmed.color
    elseif (idx==4) then
      color = mlrx.palette.group_d.color
      color_dimmed = mlrx.palette.group_d_dimmed.color
    else
      color = mlrx.palette.group_default.color
      color_dimmed = mlrx.palette.group_default_off.color
    end

    mlrx.groups[idx].color = color
    mlrx.groups[idx].color_dimmed = color_dimmed

  end

  -- add special 'void' group 
  local void_grp = Mlrx_group(mlrx)
  void_grp.color = mlrx.palette.enabled.color
  void_grp.color_dimmed = mlrx.palette.disabled.color
  void_grp.void_mutes = true
  mlrx.groups[#mlrx.groups+1] = void_grp


  -- create the logical tracks ----------------------------

  for track_idx = 1, num_tracks do
    local trk = Mlrx_track(mlrx)
    trk._num_triggers = mlrx._num_triggers
    trk.self_idx = track_idx
    trk.rns_instr_idx = track_idx
    mlrx.tracks[track_idx] = trk
  end


  -- add trigger buttons ----------------------------------

  for track_idx = 1, num_tracks do

    for trigger_idx = 1, mlrx._num_triggers do
      local c = UIButton(mlrx)
      c.group_name = map.group_name
      c.tooltip = map.description
      if (map.orientation == ORIENTATION.HORIZONTAL) then
        c:set_pos(trigger_idx,track_idx)
      else
        c:set_pos(track_idx,trigger_idx)
      end
      c.on_press = function() 
        local trk = mlrx.tracks[track_idx]
        local trigger_is_registered = false
        for _,v in ipairs(trk._held_triggers) do
          if (v == trigger_idx) then
            trigger_is_registered = true
          end
        end
        if not trigger_is_registered then
          trk._held_triggers:insert(trigger_idx)
          --print("*** inserted trigger",trigger_idx)
        end
        trk:trigger_press(trigger_idx)
        mlrx:trigger_feedback(track_idx,trigger_idx)
      end
      c.on_release = function() 
        local trk = mlrx.tracks[track_idx]
        for k,v in pairs(trk._held_triggers) do
          if (v == trigger_idx) then
            trk._held_triggers:remove(k)
            --print("*** removed trigger",k)
          end
        end
        mlrx.tracks[track_idx]:trigger_release(trigger_idx)
      end
      mlrx._controls.triggers:insert(c)
      
    end
  end

  -- group assign (matrix) ---------------------------------
  -- TODO confirm required size for group

  local map = mlrx.mappings.matrix
  local ctrl_idx = 1
  for track_idx = 1, #mlrx.tracks do
    for group_index = 1, Mlrx.NUM_GROUPS do
      local c = UIButton(mlrx)
      c.group_name = map.group_name
      c.tooltip = map.description
      c:set_pos(ctrl_idx)
      c.on_press = function() 
        mlrx:assign_track(group_index,track_idx)
        mlrx:update_matrix()
        mlrx:update_track_selector()
      end
      c.on_release = function() 
        --print("matrix on_release")

      end
      mlrx._controls.matrix:insert(c)
      
      ctrl_idx = ctrl_idx+1
    end
  end

  -- track levels ---------------------------------------

  local map = mlrx.mappings.track_levels
  for track_index = 1, num_tracks do

    local midi_map_name = string.format("Global:Tools:Duplex:Mlrx:Track %d Level [Set]",track_index)

    if map.group_name then
      local c = UISlider(mlrx)
      c.group_name = map.group_name
      c.tooltip = map.description
      c.ceiling = Mlrx.INT_7BIT
      c.midi_mapping = midi_map_name
      c:set_pos(track_index)
      c.on_change = function() 
        local trk = mlrx.tracks[track_index]
        trk:set_trk_velocity(c.value)
      end
      mlrx._controls.track_levels:insert(c)
      
    end

    if not tool:has_midi_mapping(midi_map_name) then
      tool:add_midi_mapping({
        name = midi_map_name,
        invoke = function(msg)
          if msg:is_abs_value() then
            local trk = mlrx.tracks[track_index]
            trk:set_trk_velocity(msg.int_value)
            mlrx:update_track_levels(trk)
          end
        end
      })
    end

  end

  -- track panning ---------------------------------------

  local map = mlrx.mappings.track_panning
  for track_index = 1, num_tracks do

    local midi_map_name = string.format("Global:Tools:Duplex:Mlrx:Track %d Panning [Set]",track_index)
    if map.group_name then
      local c = UISlider(mlrx)
      c.group_name = map.group_name
      c.midi_mapping = midi_map_name
      c.tooltip = map.description
      c.ceiling = Mlrx.INT_7BIT
      c:set_pos(track_index)
      c.on_change = function() 
        local trk = mlrx.tracks[track_index]
        trk:set_trk_panning(c.value)
      end
      mlrx._controls.track_panning:insert(c)
      
    end

    if not tool:has_midi_mapping(midi_map_name) then
      tool:add_midi_mapping({
        name = midi_map_name,
        invoke = function(msg)
          if msg:is_abs_value() then
            local trk = mlrx.tracks[track_index]
            trk:set_trk_panning(msg.int_value)
            mlrx:update_track_levels(trk)
          end
        end
      })
    end

  end

  -- track selector ---------------------------------------
  -- TODO support slider and not just grid mode
  -- if grid-based, check if group is equal to number of tracks

  local map = mlrx.mappings.select_track
   --local midi_map_name = "Global:Tools:Duplex:Mlrx:Select Track [Set]"
  if map.group_name then
    for track_idx = 1, #mlrx.tracks do

      local midi_map_name = string.format("Global:Tools:Duplex:Mlrx:Select Track %d [Set]",track_idx)

      local c = UIButton(mlrx)
      c.group_name = map.group_name
      c.midi_mapping = midi_map_name
      c.tooltip = map.description
      c:set_pos(track_idx)
      c.on_press = function() 
        mlrx._track_reassign_mode = true
        mlrx:select_track(track_idx)
      end
      c.on_release = function() 
        mlrx._track_reassign_mode = false
      end
      c.on_hold = function()
        -- TODO import instr. from track 
      end
      mlrx._controls.select_track[track_idx] = c
      

      if not tool:has_midi_mapping(midi_map_name) then
        tool:add_midi_mapping({
          name = midi_map_name,
          invoke = function(msg)
            if not mlrx.active then return false end
            if msg:is_abs_value() then
              --local track_index = math.floor((msg.int_value / Mlrx.INT_7BIT)*#mlrx.tracks)
              --track_index = cLib.clamp_value(track_index,1,#mlrx.tracks)
              if (track_idx ~= mlrx.selected_track) then
                mlrx:select_track(track_idx)
              end
            end
          end
        })
      end

    end


  end


  -- group toggles ----------------------------------------

  local map = mlrx.mappings.group_toggles
  for group_index = 1, Mlrx.NUM_GROUPS do
    local c = UIButton(mlrx)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(group_index)
    c.on_press = function() 
      if mlrx._track_reassign_mode then
        mlrx:assign_track(group_index,mlrx.selected_track)
        mlrx:update_matrix()
        mlrx:update_track_selector()
      else
        local grp = mlrx.groups[group_index]
        grp:toggle()
        mlrx:update_group_toggles()
      end
    end
    mlrx._controls.group_toggles:insert(c)
    
  end

  -- group levels -----------------------------------------

  local map = mlrx.mappings.group_levels
  for group_index = 1, Mlrx.NUM_GROUPS do

    local midi_map_name = string.format("Global:Tools:Duplex:Mlrx:Group %d Level [Set]",group_index)
    if map.group_name then
      local c = UISlider(mlrx)
      c.group_name = map.group_name
      c.tooltip = map.description
      c.midi_mapping = midi_map_name
      c.ceiling = Mlrx.INT_8BIT
      c:set_pos(group_index)
      c.on_change = function() 
        local grp = mlrx.groups[group_index]
        grp:set_grp_velocity(c.value)
      end
      mlrx._controls.group_levels:insert(c)
      
    end
    if not tool:has_midi_mapping(midi_map_name) then
      tool:add_midi_mapping({
        name = midi_map_name,
        invoke = function(msg)
          if not mlrx.active then return false end
          if msg:is_abs_value() then
            local grp = mlrx.groups[group_index]
            grp:set_grp_velocity(msg.int_value * 2)
            mlrx:update_group_levels(grp)
          end
        end
      })
    end

  end

  -- group panning -----------------------------------------

  local map = mlrx.mappings.group_panning
  for group_index = 1, Mlrx.NUM_GROUPS do

    local midi_map_name = string.format("Global:Tools:Duplex:Mlrx:Group %d Pan [Set]",group_index)
    if map.group_name then
      local c = UISlider(mlrx)
      c.group_name = map.group_name
      c.tooltip = map.description
      c:set_pos(group_index)
      c.midi_mapping = midi_map_name
      c.ceiling = Mlrx.INT_8BIT
      c.on_change = function() 
        local grp = mlrx.groups[group_index]
        grp:set_grp_panning(c.value)
      end
      mlrx._controls.group_panning:insert(c)
      
    end

    if not tool:has_midi_mapping(midi_map_name) then
      tool:add_midi_mapping({
        name = midi_map_name,
        invoke = function(msg)
          if not mlrx.active then return false end
          if msg:is_abs_value() then
            local grp = mlrx.groups[group_index]
            grp:set_grp_panning(msg.int_value * 2)
            mlrx:update_group_panning(grp)
          end
        end
      })
    end

  end

  -- automation mode --------------------------------------

  local map = mlrx.mappings.automation
  if map.group_name then
    local c = UIButton(mlrx,map)
    c.on_press = function() 
      mlrx:cycle_automation_mode()
    end
    mlrx._controls.automation = c
    

  end

  -- erase modifier ---------------------------------------

  local map = mlrx.mappings.erase
  if map.group_name then
    local c = UIButton(mlrx,map)
    c.on_press = function() 

    end
    c:set({text="ERASE"})
    c.on_release = function() 
      mlrx:erase_pattern()      
    end
    mlrx._controls.erase = c
  end


  -- clone modifier ---------------------------------------

  local map = mlrx.mappings.clone
  if map.group_name then
    local c = UIButton(mlrx,map)
    c.on_press = function() 
    end
    c:set({text="CLONE"})
    c.on_release = function() 
      local playpos = Mlrx_pos()
      local migrate_playpos = true
      mlrx:clone_pattern(playpos.sequence,migrate_playpos)
    end
    mlrx._controls.clone = c
    

  end

  -- track summary ----------------------------------------

  local map = mlrx.mappings.track_labels
  if map.group_name then
    for track_idx = 1, #mlrx.tracks do
      local c = UILabel(mlrx)
      c.group_name = map.group_name
      c.tooltip = map.description
      c:set_pos(track_idx)
      mlrx._controls.track_labels:insert(c)
      
    end
  end

  -- track: sound mode ----------------------------------

  local map = mlrx.mappings.set_source_slice
  if map.group_name then
    local c = UIButton(mlrx,map)
    c:set({text="SLICE"})
    c.on_press = function() 
      mlrx.tracks[mlrx.selected_track]:toggle_slicing()
    end
    c.on_hold = function() 
      mlrx.tracks[mlrx.selected_track]:toggle_slicing(true)
    end
    mlrx._controls.set_source_slice = c
    
  end

  local map = mlrx.mappings.set_source_phrase
  if map.group_name then
    local phrase_button_held = false
    local c = UIButton(mlrx,map)
    c:set({text="PHRASE"})
    c.on_release = function() 
      if phrase_button_held then
        phrase_button_held = false
        return
      end
      local trk = mlrx.tracks[mlrx.selected_track]
      if trk.phrase_recording then
        trk:stop_phrase_recording()
        mlrx:update_sound_source()
      elseif trk.phrase_record_armed then
        trk.phrase_record_armed = false
        mlrx:update_sound_source()
      else
        trk:toggle_phrase_mode()
      end
    end
    c.on_hold = function()
      local trk = mlrx.tracks[mlrx.selected_track]
      if rns.transport.playing then
        trk:prepare_phrase_recording()
      else
        trk:capture_phrase()
        c:flash(0.2,mlrx.palette.enabled,mlrx.palette.disabled)
      end
      phrase_button_held = true
    end
    mlrx._controls.set_source_phrase = c
  end


  -- track: trigger mode ----------------------------------

  local map = mlrx.mappings.set_mode_hold
  if map.group_name then
    local c = UIButton(mlrx,map)
    c:set({text="HOLD"})
    c.on_press = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:set_trig_mode(Mlrx_track.TRIG_HOLD)
      mlrx:update_track()
    end
    mlrx._controls.set_mode_hold = c
  end

  local map = mlrx.mappings.set_mode_toggle
  if map.group_name then
    local c = UIButton(mlrx,map)
    c:set({text="TOGGLE"})
    c.on_press = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:set_trig_mode(Mlrx_track.TRIG_TOGGLE)
      mlrx:update_track()
    end
    mlrx._controls.set_mode_toggle = c
    
  end

  local map = mlrx.mappings.set_mode_write
  if map.group_name then
    local c = UIButton(mlrx,map)
    c:set({text="WRITE"})
    c.on_press = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:set_trig_mode(Mlrx_track.TRIG_WRITE)
      mlrx:update_track()
    end
    mlrx._controls.set_mode_write = c
    
  end

  local map = mlrx.mappings.set_mode_touch
  if map.group_name then
    local c = UIButton(mlrx,map)
    c:set({text="TOUCH"})
    c.on_press = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:set_trig_mode(Mlrx_track.TRIG_TOUCH)
      mlrx:update_track()
    end
    mlrx._controls.set_mode_touch = c
    
  end


  -- track: arpeggiator ----------------------------------

  local map = mlrx.mappings.toggle_arp
  if map.group_name then
    local c = UIButton(mlrx,map)
    c:set({text="ARP"})
    c.on_press = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      trk.arp_enabled = not trk.arp_enabled
      mlrx.initiate_settings_requested = true
      mlrx:update_arp_mode()
    end
    mlrx._controls.toggle_arp = c
    
  end

  local map = mlrx.mappings.arp_mode
  if map.group_name then
    local c = UIButton(mlrx,map)
    --c:set({text="RND"})
    c.on_press = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:cycle_arp_mode()
      mlrx:update_arp_mode()
    end
    mlrx._controls.arp_mode = c
    
  end

  -- track: loop mode ----------------------------------

  local map = mlrx.mappings.toggle_loop
  if map.group_name then
    local c = UIButton(mlrx,map)
    --c:set({text="RND"})
    c.on_press = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:toggle_loop()
      mlrx:update_toggle_loop(trk)
    end
    mlrx._controls.toggle_loop = c
    
  end

  -- track: shuffle amount ----------------------------------

  local map = mlrx.mappings.shuffle_label
  if map.group_name then
    local c = UILabel(mlrx)
    c.group_name = map.group_name
    c.tooltip = map.description
    mlrx._controls.shuffle_label = c
    
  end

  local map = mlrx.mappings.shuffle_amount
  local midi_map_name = "Global:Tools:Duplex:Mlrx:Track Shuffle Amount [Set]"
  if map.group_name then
    local c = UISlider(mlrx,map)
    c.midi_mapping = midi_map_name
    c.ceiling = Mlrx.INT_8BIT
    c.on_change = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:set_shuffle_amount(c.value)
    end
    mlrx._controls.shuffle_amount = c
  end

  if not tool:has_midi_mapping(midi_map_name) then
    tool:add_midi_mapping({
      name = midi_map_name,
      invoke = function(msg)
        if not mlrx.active then return false end
        if msg:is_abs_value() then
          local trk = mlrx.tracks[mlrx.selected_track]
          trk:set_shuffle_amount(msg.int_value * 2)
        end
      end
    })
  end

  local map = mlrx.mappings.toggle_shuffle_cut
  if map.group_name then
    local c = UIButton(mlrx,map)
    c:set({text="Cxx"})
    c.on_press = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:toggle_shuffle_cut()
    end
    mlrx._controls.toggle_shuffle_cut = c
  end

  -- track: offset drifting ----------------------------------

  local map = mlrx.mappings.drift_label
  if map.group_name then
    local c = UILabel(mlrx)
    c.group_name = map.group_name
    c.tooltip = map.description
    mlrx._controls.drift_label = c
  end

  local map = mlrx.mappings.drift_amount
  local midi_map_name = "Global:Tools:Duplex:Mlrx:Track Drift Amount [Set]"
  if map.group_name then
    local c = UISlider(mlrx,map)
    c.midi_mapping = midi_map_name
    c.ceiling = Mlrx.DRIFT_RANGE
    c:set_value(Mlrx.DRIFT_RANGE/2) 
    c.on_change = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:set_drift_amount(c.value - (Mlrx.DRIFT_RANGE/2))
    end
    mlrx._controls.drift_amount = c
    
  end
  if not tool:has_midi_mapping(midi_map_name) then
    tool:add_midi_mapping({
      name = midi_map_name,
      invoke = function(msg)
        if not mlrx.active then return false end
        if msg:is_abs_value() then
          local trk = mlrx.tracks[mlrx.selected_track]
          trk:set_drift_amount((msg.int_value * 2) - 127)
        end
      end
    })
  end
  local map = mlrx.mappings.drift_enable
  if map.group_name then
    local c = UIButton(mlrx,map)
    --c:set({text="ON"})
    c.on_press = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:cycle_drift_mode()
    end
    mlrx._controls.drift_enable = c
  end


  -- track: note output ----------------------------------

  local map = mlrx.mappings.toggle_note_output
  if map.group_name then
    local c = UIButton(mlrx,map)
    c:set({text="---"})
    c.on_press = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:toggle_note_output()
    end
    mlrx._controls.toggle_note_output = c
  end

  -- track: offset modes ----------------------------------

  local map = mlrx.mappings.toggle_sxx_output
  if map.group_name then
    local c = UIButton(mlrx,map)
    c:set({text="Sxx"})
    c.on_press = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:toggle_sxx_output()
    end
    mlrx._controls.toggle_sxx_output = c
  end

  local map = mlrx.mappings.toggle_exx_output
  if map.group_name then
    local c = UIButton(mlrx,map)
    c:set({text="Exx"})
    c.on_press = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:toggle_exx_output()
    end
    mlrx._controls.toggle_exx_output = c
  end



  -- track: transpose_up/down -----------------------------

  local map = mlrx.mappings.transpose_up
  local tu_triggered = false
  if map.group_name then
    local c = UIButton(mlrx,map)
    c:set({text="♪+"})
    c.on_release = function() 
      if tu_triggered then
        tu_triggered = false
        return
      end
      c:flash(0.2,mlrx.palette.enabled,mlrx.palette.disabled)
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:set_transpose(1)
      mlrx:update_track()
    end
    c.on_hold = function() 
      c:flash(0.2,mlrx.palette.enabled,mlrx.palette.disabled)
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:set_transpose(12)
      mlrx:update_track()
      tu_triggered = true
    end
    mlrx._controls.transpose_up = c
    
  end

  local map = mlrx.mappings.transpose_down
  local td_triggered = false
  if map.group_name then
    local c = UIButton(mlrx,map)
    c:set({text="♪-"})
    c.on_release = function() 
      if td_triggered then
        td_triggered = false
        return
      end
      c:flash(0.2,mlrx.palette.enabled,mlrx.palette.disabled)
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:set_transpose(-1)
      mlrx:update_track()
    end
    c.on_hold = function() 
      c:flash(0.2,mlrx.palette.enabled,mlrx.palette.disabled)
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:set_transpose(-12)
      mlrx:update_track()
      td_triggered = true
    end
    mlrx._controls.transpose_down = c
    
  end

  -- track: tempo_up/down -----------------------------

  local map = mlrx.mappings.tempo_up
  local tempo_up_triggered = false
  if map.group_name then
    local c = UIButton(mlrx,map)
    c:set({text="∆+"})
    c.on_release = function() 
      if tempo_up_triggered then
        tempo_up_triggered = false
        return
      end
      local trk = mlrx.tracks[mlrx.selected_track]
      if trk.phrase then
        trk:set_phrase_lpb(1)
      elseif trk.sample and trk.sample.beat_sync_enabled then
        trk:set_beat_sync(1)
      end
      mlrx:update_track()
    end
    c.on_hold = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      if trk.phrase then
        trk:set_double_lpb()
      elseif trk.sample and trk.sample.beat_sync_enabled then
        trk:set_half_sync()
      end
      mlrx:update_track()
      tempo_up_triggered = true
    end
    mlrx._controls.tempo_up = c
    
  end

  local map = mlrx.mappings.tempo_down
  local tempo_down_triggered = false
  if map.group_name then
    local c = UIButton(mlrx,map)
    c:set({text="∆-"})
    c.on_release = function() 
      if tempo_down_triggered then
        tempo_down_triggered = false
        return
      end
      local trk = mlrx.tracks[mlrx.selected_track]
      if trk.phrase then
        trk:set_phrase_lpb(-1)
      elseif trk.sample and trk.sample.beat_sync_enabled then
        trk:set_beat_sync(-1)
      end
      mlrx:update_track()

    end
    c.on_hold = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      if trk.phrase then
        trk:set_half_lpb()
      elseif trk.sample and trk.sample.beat_sync_enabled then
        trk:set_double_sync()
      end
      mlrx:update_track()
      tempo_down_triggered = true

    end
    mlrx._controls.tempo_down = c
    
  end


  -- track: instrument sync -------------------------------

  local map = mlrx.mappings.toggle_sync
  local beatsync_applied = false
  if map.group_name then
    local c = UIButton(mlrx,map)
    --c:set({text="BEAT\nSYNC"})
    c.on_release = function() 
      if beatsync_applied then
        beatsync_applied = false
        return
      end
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:toggle_sync()
      mlrx:update_track()
    end
    c.on_hold = function()
      local trk = mlrx.tracks[mlrx.selected_track]
      if trk.phrase and xInstrument.get_phrase_playback_enabled(trk.instr) then
        -- align transpose with phrase basenote 
        trk.note_pitch = trk.phrase.mapping.base_note
      elseif trk.sample then
        if trk.sample.beat_sync_enabled then
          trk:apply_beatsync_to_tuning()
        else
          -- apply_tuning_to_beatsync
          trk.sample.beat_sync_lines = trk.sync_to_lines
          trk.sample.beat_sync_enabled = true
        end
        beatsync_applied = true
        mlrx:update_summary(trk.self_idx)
      end
    end
    mlrx._controls.toggle_sync = c
    
  end


  -- track: cycle_length ----------------------------------

  local map = mlrx.mappings.set_cycle_2
  if map.group_name then
    local c = UIButton(mlrx,map)
    c:set({text="1/2"})
    c.on_press = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:set_cycle_length(Mlrx_track.CYCLE.HALF)
      mlrx:update_track()
    end
    mlrx._controls.set_cycle_2 = c
    
  end

  local map = mlrx.mappings.set_cycle_4
  if map.group_name then
    local c = UIButton(mlrx,map)
    c:set({text="1/4"})
    c.on_press = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:set_cycle_length(Mlrx_track.CYCLE.FOURTH)
      mlrx:update_track()
    end
    mlrx._controls.set_cycle_4 = c
    
  end

  local map = mlrx.mappings.set_cycle_8
  if map.group_name then
    local c = UIButton(mlrx,map)
    c:set({text="1/8"})
    c.on_press = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:set_cycle_length(Mlrx_track.CYCLE.EIGHTH)
      mlrx:update_track()
    end
    mlrx._controls.set_cycle_8 = c
    
  end

  local map = mlrx.mappings.set_cycle_16
  if map.group_name then
    local c = UIButton(mlrx,map)
    c:set({text="1/16"})
    c.on_press = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:set_cycle_length(Mlrx_track.CYCLE.SIXTEENTH)
      mlrx:update_track()
    end
    mlrx._controls.set_cycle_16 = c
    
  end

  local map = mlrx.mappings.set_cycle_es
  if map.group_name then
    local c = UIButton(mlrx,map)
    c:set({text="Step"})
    c.on_press = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:set_cycle_length(Mlrx_track.CYCLE.EDITSTEP)
      mlrx:update_track()
    end
    mlrx._controls.set_cycle_es = c
    
  end

  local map = mlrx.mappings.set_cycle_custom
  if map.group_name then
    local c = UIButton(mlrx,map)
    c:set({text="-"})
    c.on_press = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:set_cycle_length(Mlrx_track.CYCLE.CUSTOM)
      mlrx:update_track()
    end
    mlrx._controls.set_cycle_custom = c
    
  end

  local map = mlrx.mappings.increase_cycle
  if map.group_name then
    local c = UIButton(mlrx,map)
    c:set({text="+"})
    c.on_press = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:increase_cycle()
      mlrx:update_track()
    end
    mlrx._controls.increase_cycle = c
    
  end

  local map = mlrx.mappings.decrease_cycle
  if map.group_name then
    local c = UIButton(mlrx,map)
    c:set({text="-"})
    c.on_press = function() 
      local trk = mlrx.tracks[mlrx.selected_track]
      trk:decrease_cycle()
      mlrx:update_track()
    end
    mlrx._controls.decrease_cycle = c
    
  end

  -- special input assignments ----------------------------

  local map = mlrx.mappings.xy_pad
  if map.group_name then

    -- initially set the value to the center
    local param = cm:get_param_by_index(map.index,map.group_name)

    local c = UIPad(mlrx,map)
    c.on_change = function(obj)
      local val = {
        cLib.scale_value(obj.value[1],obj.floor,obj.ceiling,0,1),
        cLib.scale_value(obj.value[2],obj.floor,obj.ceiling,0,1)
      }
      mlrx:input_xy(val)
    end
    mlrx._controls.xy_pad = c
    

    local midi_map_name = "Global:Tools:Duplex:Mlrx:XYPad X-Axis [Set]"
    if not tool:has_midi_mapping(midi_map_name) then
      tool:add_midi_mapping({
        name = midi_map_name,
        invoke = function(msg)
          if not mlrx.active then return false end
          if msg:is_abs_value() then
            local val_x = cLib.scale_value(msg.int_value,0,Mlrx.INT_7BIT,param.xarg.minimum,param.xarg.maximum)
            local val_y = mlrx._controls.xy_pad.value[2]
            mlrx._controls.xy_pad:set_value(val_x,val_y)
          end
        end
      })
    end

    local midi_map_name = "Global:Tools:Duplex:Mlrx:XYPad Y-Axis [Set]"
    if not tool:has_midi_mapping(midi_map_name) then
      tool:add_midi_mapping({
        name = midi_map_name,
        invoke = function(msg)
          if not mlrx.active then return false end
          if msg:is_abs_value() then
            local val_x = mlrx._controls.xy_pad.value[1]
            local val_y = cLib.scale_value(msg.int_value,0,Mlrx.INT_7BIT,param.xarg.minimum,param.xarg.maximum)
            mlrx._controls.xy_pad:set_value(val_x,val_y)
          end
        end
      })
    end

  end

  return true

end

