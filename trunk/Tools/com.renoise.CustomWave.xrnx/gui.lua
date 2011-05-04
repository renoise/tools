--[[============================================================================
gui.lua
============================================================================]]--

-- notifiers

function instruments_list_changed()

  -- reset all WAVE operators
  for int_operator = 1, OPERATORS do
  
    array_instrument_number[int_operator] = 0
    array_sample_number[int_operator] = 0
    
    if array_waves[int_operator] == WAVE_WAVETABLE then

      change_wave(int_operator,WAVE_NONE)
    
    end
  
  end
  
  renoise.app():show_status(
    "All operators of type 'Wave' have been reset because of a change in " ..
    "instruments list"
  )
  
end



--------------------------------------------------------------------------------

function new_song_loaded()

  if dialog.visible then
    dialog:close()
    if renoise.tool().app_new_document_observable:has_notifier(new_song_loaded)
    then
      renoise.tool().app_new_document_observable:add_notifier(new_song_loaded)
    end
  end

end


--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local MARGIN_DEFAULT = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN

vb = nil 
dialog = nil


--------------------------------------------------------------------------------

function show_operator_parameters(int_wave_type)

  vb.views.rowWidth.visible = 
    int_wave_type == WAVE_PULSE or int_wave_type == WAVE_TANGENT
  vb.views.colWaveTable.visible = int_wave_type == WAVE_WAVETABLE
  vb.views.rowInvert.visible = int_wave_type ~= WAVE_NOISE
  vb.views.rowMultiplier.visible = (int_wave_type ~= WAVE_NOISE and 
    int_wave_type ~= WAVE_MORPHER)
  vb.views.rowSources.visible = int_wave_type == WAVE_MORPHER
  vb.views.rowMorphingTime.visible = int_wave_type == WAVE_MORPHER
  
  if int_wave_type == WAVE_VARIATOR then
    vb.views.txtMultiplier.min = 0
    vb.views.txtMultiplier.max = 1  
  else
    vb.views.txtMultiplier.min = 0
    vb.views.txtMultiplier.max = 10    
  end

end


--------------------------------------------------------------------------------


function change_tab(int_operator_number)

  int_operator_selected = int_operator_number
  
  if not wave_is_set(int_operator_number) then
    initialize_wave(int_operator_number)
    --print('init'..tostring(int_operator_number))
  end

  local real_amplitude = array_real_amplitudes[int_operator_number]
  local real_width = array_variant_parameters[int_operator_number]
  local int_wave_type = array_waves[int_operator_number]
  local real_frequency_multiplier = 
    array_real_frequency_multipliers[int_operator_number]

  int_wave_type_selected = int_wave_type

  vb.views.txtOperator.text = "Operator " .. tostring(int_operator_number)  
  vb.views.sldAmplitude.value = real_amplitude
  
  if int_wave_type ~= WAVE_WAVETABLE then
    if 
      real_width ~= nil and 
      int_wave_type ~= WAVE_VARIATOR and 
      int_wave_type ~= WAVE_MORPHER 
    then
      vb.views.sldWidth.value = real_width
    else
      vb.views.sldWidth.value = 0.5
    end
  else  
    if vb.views.cmbInstruments then    
      vb.views.cmbInstruments.value = array_instrument_number[int_operator_number] + 1
      vb.views.cmbSamples.value = array_sample_number[int_operator_number] + 1
    end
  end
  
  vb.views.cmbWave.value = int_wave_type_selected
  vb.views.txtMultiplier.value = real_frequency_multiplier
  vb.views.chkInvert.value = array_boolean_inverts[int_operator_number]
  
  show_operator_parameters(int_wave_type)

  vb.views.cmbModulate.items = generate_modulator_matrix()
  vb.views.cmbSources1.items = generate_modulator_matrix()
  vb.views.cmbSources2.items = generate_modulator_matrix()

  if array_int_modulators[int_operator_number] > 0 then
    --print("OP#" ..int_operator_number .. " modulates OP#" .. array_int_modulators[int_operator_number])
    vb.views.cmbModulate.value = array_int_modulators[int_operator_number] + 1
  else
    --print("OP#" .. int_operator_number .. " does not modulate")
    vb.views.cmbModulate.value = 1
  end
  
  if (int_wave_type_selected == WAVE_MORPHER) then
  
    local bool_is_modulated, arr_int_modulators, 
      int_modulators = is_modulated(int_operator_number)
  
  
    if bool_is_modulated then
    if arr_int_modulators[1] ~= nil then
        vb.views.cmbSources1.value = arr_int_modulators[1] + 1
    end
    if arr_int_modulators[2] ~= nil then
        vb.views.cmbSources2.value = arr_int_modulators[2] + 1
    end
  end
  
  end
  
  vb.views.cmbModulate.active = can_modulate(int_operator_number) or 
    is_modulator(int_operator_number)
  
end


--------------------------------------------------------------------------------

function change_wave(int_wave_number,int_wave_type_new)
  int_wave_type_selected = int_wave_type_new
  vb.views.cmbWave.value = int_wave_type_selected
  if not wave_is_set(int_wave_number) then
    initialize_wave(int_wave_number)
  end
  array_waves[int_operator_selected] = int_wave_type_new
  
  show_operator_parameters(int_wave_type_new)
  
  if int_wave_type_new == WAVE_NONE then
  
    -- the operator has been disabled
  local bool_is_modulated, arr_modulators, 
    int_modulators = is_modulated(int_wave_number)
  
  if bool_is_modulated then
  
    for int_modulator = 1, int_modulators do
    
      --print("OP#" .. int_wave_number .. " is modulated by OP#" .. arr_modulators[int_modulator]);
      array_int_modulators[arr_modulators[int_modulator]] = 0 
      --print("modulation of OP#" .. arr_modulators[int_modulator] .. " changed to NONE")    
    
    end
  
  end
    
  elseif int_wave_type_new == WAVE_WAVETABLE then
    if array_instrument_number[int_wave_number] == 0 then
      generate_instrument_matrix()
      generate_sample_matrix(0)
    end
    vb.views.cmbInstruments.value = array_instrument_number[int_wave_number] + 1
    vb.views.cmbSamples.value = array_sample_number[int_wave_number] + 1
  end
end


--------------------------------------------------------------------------------


function generate_modulator_matrix()

  local array_string_modulators = {}
  local int_operator
  local int_count = 2
  
  array_string_modulators[1] = "-NONE-"
  
  for int_operator = 1, OPERATORS do
  
    local int_wave = 1
    
    if array_waves[int_operator] then
      int_wave = array_waves[int_operator]  
    end
  
    array_string_modulators[int_count] = "Op " .. 
      tostring(int_operator) .. 
      " (" .. array_string_operators[int_wave] .. ")"
      
     int_count = int_count + 1
  
    end
    
  return array_string_modulators
end


--------------------------------------------------------------------------------

function generate_instrument_matrix()

  local int_instruments = table.getn(renoise.song().instruments)
  local int_count
  local array_string_return = {}

  for int_count = 1, int_instruments do
    local string_name = renoise.song().instruments[int_count].name
    if string_name == "" then
      string_name = "Instrument #" .. tostring(int_count-1)
    end

    array_string_return[int_count+1] = string_name
  end

  array_string_return[1] = "-- Select --"

  return array_string_return
end


--------------------------------------------------------------------------------

function generate_sample_matrix(int_instrument)
  
  if int_instrument <= 0 then
    return 
  end
    
  local int_samples = 
    table.getn(renoise.song().instruments[int_instrument].samples)
  local int_count
  local array_string_return = {}
  
  for int_count = 1, int_samples do
    local string_name = 
      renoise.song().instruments[int_instrument].samples[int_count].name
    if string_name == "" then
      string_name = "Sample #" .. tostring(int_count-1)
    end
    array_string_return[int_count+1] = string_name
  end  
  
  array_string_return[1] = "-- Select --"
  return array_string_return
end


--------------------------------------------------------------------------------

function note_number_to_string(int_note)

  local string_note = ""

  local int_remainder = int_note % 12
  
  if int_remainder == 1 then
    string_note = string_note .. "C-"
  elseif int_remainder == 2 then
    string_note = string_note .. "C#"
  elseif int_remainder == 3 then
    string_note = string_note .. "D-"
  elseif int_remainder == 4 then
    string_note = string_note .. "D#"
  elseif int_remainder == 5 then
    string_note = string_note .. "E-"
  elseif int_remainder == 6 then
    string_note = string_note .. "F-"
  elseif int_remainder == 7 then
    string_note = string_note .. "F#"
  elseif int_remainder == 8 then
    string_note = string_note .. "G-"
  elseif int_remainder == 9 then
    string_note = string_note .. "G#"
  elseif int_remainder == 10 then
    string_note = string_note .. "A-"
  elseif int_remainder == 11 then
    string_note = string_note .. "A#"
  elseif int_remainder == 0 then
    string_note = string_note .. "B-"
  end
  
  local string_octave = tostring(math.floor(int_note / 12))

  return string_note .. string_octave

end

function generate_note_matrix(int_start, int_end)

  local array_string_notes = {}
  local int_count = 1
  
  for int_start_note = int_start, int_end do
  
    array_string_notes[int_count] = note_number_to_string(int_start_note)    
    int_count = int_count + 1
    
  end
  
  return array_string_notes

end


--------------------------------------------------------------------------------

function reset_gui()
  array_real_amplitudes = {}
  array_variant_parameters = {}
  array_boolean_inverts = {}
  array_int_modulators = {}
  array_real_frequency_multipliers = {}
  array_waves = {}
  int_start_note = 58
  real_amplification = 1.0
  int_operator_selected = 1
  int_wave_type_selected = 5
  vb.views.switchTabs.value = 1
  vb.views.chkInvert.value = false
  vb.views.chkAutoGenerate.value = false
end


--------------------------------------------------------------------------------

function show_dialog()

  if not 
    renoise.song().instruments_observable:has_notifier(instruments_list_changed)
  then
    renoise.song().instruments_observable:add_notifier(instruments_list_changed)
  end
  
  if not 
    renoise.tool().app_new_document_observable:has_notifier(new_song_loaded) 
  then
    renoise.tool().app_new_document_observable:add_notifier(new_song_loaded)
  end

  if (dialog and dialog.visible) then
    -- already showing a dialog. bring it to front:
    dialog:show()
    return
  end

  local MARGIN_DEFAULT = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local SPACING_DEFAULT = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING

  local TEXT_LABEL_WIDTH = 80
  local CONTROL_WIDTH = 100
  local CONTENT_WIDTH = TEXT_LABEL_WIDTH + CONTROL_WIDTH

  local DIALOG_BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
  local CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT

  vb = renoise.ViewBuilder()


  -- create_global_properties

  local function create_global_properties()

    local row_start_note = vb:row {
      vb:text {
        text = "First note",
        width = TEXT_LABEL_WIDTH
      },
      vb:popup {
      id = "cmbStartNote",
        width = CONTROL_WIDTH,
        value = int_start_note,
        items = generate_note_matrix(1,120),
        notifier = function(new_index)
          if(new_index > int_end_note) then
            vb.views.cmbEndNote.value = new_index
          end
          int_start_note = new_index
          int_frames = SAMPLE_FREQUENCY / note_to_frequency(new_index)
          if toggle_auto_generate then
            generate()
          end
        end,
        width = CONTROL_WIDTH
      }
    }
  
    local row_end_note = vb:row {
      vb:text {
        text = "Last note",
        width = TEXT_LABEL_WIDTH
      },
      vb:popup {
      id = "cmbEndNote",
        width = CONTROL_WIDTH,
        value = int_end_note,
        items = generate_note_matrix(1,120),
        notifier = function(new_index)
          if (new_index < int_start_note) then
            vb.views.cmbStartNote.value = new_index
          end
          int_end_note = new_index
          int_frames = SAMPLE_FREQUENCY / note_to_frequency(new_index)
          if toggle_auto_generate then
            generate()
          end
        end,
        width = CONTROL_WIDTH
      }
    }
  
    local row_cycles = vb:row {
      vb:text {
        text = "Cycles" ,
        width = TEXT_LABEL_WIDTH
      },
      vb:valuefield {
        width = CONTROL_WIDTH,
        id = "valCycles",
        value = 1,
        min = 0.5,
        max = SAMPLE_FREQUENCY/100,
        notifier = function(new_text)
          renoise.app():show_status(tostring(SAMPLE_FREQUENCY));
          real_cycles = tonumber(new_text)
          vb.views.sldCycles.value = real_cycles
          if toggle_auto_generate then
            generate()
          end
        end
      }
    }

  local slider_cycles = vb:slider {
    width = CONTROL_WIDTH + TEXT_LABEL_WIDTH,
    min = 0.5,
    id = "sldCycles",
    max = SAMPLE_FREQUENCY/100,  --- to allow for finer tweaking, big values are too sluggish
    value = 1,
    notifier = function(value)
      real_cycles = value
      vb.views.valCycles.value = real_cycles
      if toggle_auto_generate then
        generate()
      end
     end
    }
  

    local row_label = vb:row {
      vb:text {
        text = "Amplification",
        width = TEXT_LABEL_WIDTH
      },
      vb:text {
        id = "txtDbValue",
        text = "0 dB",
        width = TEXT_LABEL_WIDTH
      }
    }
  
    local slider_volume = vb:slider {
      width = CONTROL_WIDTH + TEXT_LABEL_WIDTH,
      min = 0, -- -INF using log scale
      max = 1, -- 0 Decibels using log scale
      value = 1,
      notifier = function(value)
        real_amplification = math.pow(value,2)
        if (real_amplification==0) then
          vb.views.txtDbValue.text = "-INF dB"
        else
          vb.views.txtDbValue.text = 
          string.format("%.2f dB",convert_linear_to_db(real_amplification))
        end
        if toggle_auto_generate then
          generate()
        end
      end
    }
  
    local array_string_buttons = {}
    for i = 1, OPERATORS do
      array_string_buttons[i] = tostring(i)
    end
  
    local switch_tabs = vb:switch {
      id = "switchTabs",
      width = CONTENT_WIDTH,
      items = array_string_buttons,
      notifier = function(int_index_new)
        change_tab(int_index_new)
      end
    }
  
    local column_global_properties = vb:column {
      style = "group",
      margin = MARGIN_DEFAULT,
      row_start_note,
      row_end_note,
      row_cycles,
      slider_cycles,
      row_label,
      slider_volume,
      switch_tabs
    }
    
    return column_global_properties
    
  end
  
    
  --- create operator GUI
  
  local function create_operator_gui()
  
    local text_operator = vb:text {
      id = "txtOperator",
      text = "Operator",
      font = "bold",
      align = "center",
      width = CONTENT_WIDTH,
    }
  
    local row_wave = vb:row {
      vb:text {
        text = "Wave",
        width = TEXT_LABEL_WIDTH
      },
      vb:popup {
        id = "cmbWave",
        width = CONTROL_WIDTH,
        value = int_wave_type_selected,
        items = array_string_operators,
        notifier = function(int_wave_type)
          change_wave(int_operator_selected,int_wave_type)
          if toggle_auto_generate then
            generate()
          end
        end
      }
    }
  
    local row_amplitude = vb:row {
      vb:text {
        text = "Amplitude",
        width= TEXT_LABEL_WIDTH
      },
      vb:slider {
        id = "sldAmplitude",
        width = CONTROL_WIDTH,
        min = 0,
        max = 1,
        value = 1,
        notifier = function(real_value)
          array_real_amplitudes[int_operator_selected] = real_value
          if toggle_auto_generate then
            generate()
          end
        end
      }
    }
  
    local row_width = vb:row {
      id = "rowWidth",
      vb:text {
        text = "Width",
        width = TEXT_LABEL_WIDTH
      },
      vb:slider {
        id = "sldWidth",
        width = CONTROL_WIDTH,
        min = 0,
        max = 0.5,
        value = 0.5,
        notifier = function(real_value)
          if real_value ~= nil then
            array_variant_parameters[int_operator_selected] = real_value
             if toggle_auto_generate then
               generate()
             end
          end
        end
      }
    }
  
    local row_invert = vb:row {
      id = "rowInvert",
      vb:text {
        text = "Invert wave",
        width= TEXT_LABEL_WIDTH
      },
      vb:checkbox {
        id = "chkInvert",
        value = false,
        notifier = function(boolean_value)
          array_boolean_inverts[int_operator_selected] = boolean_value
          if toggle_auto_generate then
            generate()
          end
        end
      }
    }
  
    local row_modulate = vb:row {
      vb:text {
        text = "Mod.Ampl. of",
        width = TEXT_LABEL_WIDTH
      },
      vb:popup {
        id = "cmbModulate",
        width = CONTROL_WIDTH,
        items = generate_modulator_matrix(),
        value = 1,
        notifier = function(new_index)
        
          local int_new_wannabe_modulated = new_index - 1
          
          if 
            not can_be_modulated(int_new_wannabe_modulated) and 
            not is_modulated_by(int_new_wannabe_modulated,int_operator_selected) 
          then
            renoise.app():show_status("An invalid operator has been selected. "..
              "Selection will be reset.");
            int_new_wannabe_modulated = 0
			
			--the row below has been commented out because notifier loops are no more supported in 
			--Renoise 2.7. The comboBox value will simply be reset the next time the operator tab will
			--be refreshed
            --vb.views.cmbModulate.value = 1      
			
            return
          end
        
          --print("now OP#" .. int_operator_selected .. " modulates OP#" .. int_new_wannabe_modulated);
          array_int_modulators[int_operator_selected] = int_new_wannabe_modulated
          
          local bool_is_modulator, int_modulated = is_modulator(int_new_wannabe_modulated)
          if (bool_is_modulator) then
            array_int_modulators[int_modulated] = 0
            --print("now OP#" .. int_modulated .. " is no more modulated by OP#" .. int_new_wannabe_modulated)
          end
        
          if toggle_auto_generate then
            generate()
          end
        end
      }
    }
  
    local dropdown_instruments = vb:popup {
      id = "cmbInstruments",
      width = CONTENT_WIDTH,
      items = generate_instrument_matrix(),
      value = 1,
      notifier = function(new_index)
    
        local instrument_index = new_index - 1
          
        local last_instrument = array_instrument_number[int_operator_selected]
        local last_sample = array_sample_number[int_operator_selected]
    
        if instrument_index > 0 and vb.views.cmbSamples then
          vb.views.cmbSamples.visible = true
          vb.views.cmbSamples.items = generate_sample_matrix(instrument_index)
        else
          vb.views.cmbSamples.visible = false
        end
  
        -- generate notifier name associated with the 
        -- previously and newly selected instrument
        local samples_notifier_name = 
          ("sample_list_changed_in_instrument_%d"):format(instrument_index)
        local last_samples_notifier_name = 
          ("sample_list_changed_in_instrument_%d"):format(last_instrument)
      
        -- notifier for changes in samples list
        if instrument_index > 0 then
      
          notifiers[samples_notifier_name] = function ()
  
          -- the currently visible operator is a wavetable using 
          -- the changed instrument as wavetable
          if 
            array_waves[int_operator_selected] == WAVE_WAVETABLE and 
            array_instrument_number[int_operator_selected] == instrument_index 
          then
            -- rebuild samples list
            array_sample_number[int_operator_selected] = 0
            vb.views.cmbSamples.items = generate_sample_matrix(instrument_index)
            vb.views.cmbSamples.value = 1
          end
          
          -- we will use this to warn the user about what is happening
          local string_warning = ' ' 
          
          -- loop over all operators to reset all the operators which have 
          -- the changed isntrument as wavetable
          for int_operator = 1, OPERATORS do
          
            if 
              array_waves[int_operator] and 
              array_waves[int_operator] == WAVE_WAVETABLE and 
              array_instrument_number[int_operator] == instrument_index 
            then
              array_sample_number[int_operator] = 0
              string_warning = string_warning .. tostring(int_operator) .. ', '
            end
            
          end
            
          if string.len(string_warning) > 1 then
            renoise.app():show_status(
              ("The following operators have been reset because of changes in" ..
               " sample list of instrument %d: "):format(instrument_index-1) ..
               string.sub(string_warning,1,string.len(string_warning)-2)
            )
          end
  
        end
  
        if toggle_auto_generate then
          generate()
        end
  
      end
  
      --remove any notifier from the previously selected sample
      if 
        last_instrument > 0 and 
          (renoise.song().instruments[last_instrument].samples_observable:has_notifier(
            notifiers[last_samples_notifier_name])) 
      then
        renoise.song().instruments[last_instrument].samples_observable:remove_notifier(
          notifiers[last_samples_notifier_name])
      end
  
      -- only add notifier if there is no yet another
      if 
        instrument_index > 0 and 
        not (renoise.song().instruments[instrument_index].samples_observable:has_notifier(
          notifiers[samples_notifier_name])) 
      then
        renoise.song().instruments[instrument_index].samples_observable:add_notifier(
          notifiers[samples_notifier_name])
      end
          
      array_instrument_number[int_operator_selected] = instrument_index
      array_sample_number[int_operator_selected] = 1 -- default sample
      
      end
    }
  
    local dropdown_samples = vb:popup {
      id = "cmbSamples",
      width = CONTENT_WIDTH,
      items = generate_sample_matrix(0),
      value = 1,
      notifier = function(new_index)
        array_sample_number[int_operator_selected] = new_index - 1
        if toggle_auto_generate then
          generate()
        end
      end
    }
  
    local column_wavetable = vb:column {
      id = "colWaveTable",
      dropdown_instruments,
      dropdown_samples
    }
  
    local row_frequency_multiplier = vb:row {
      id = "rowMultiplier",
      vb:text {
        text = "Freq. Multiplier",
        width = TEXT_LABEL_WIDTH
      },
      vb:valuefield {
        id = "txtMultiplier",
        width = CONTROL_WIDTH,
        min = 0,
        max = 10,
        value = 1,
        notifier = function(new_value)
          array_real_frequency_multipliers[int_operator_selected] = new_value
          if toggle_auto_generate then
            generate()
          end
        end
      }
    }
  
  local row_sources = vb:row {
  
    id = "rowSources",
    width = CONTENT_WIDTH,
    vb:popup {
      id = "cmbSources1",
      items = generate_modulator_matrix(),
      notifier = function(new_index)
        local bool_is_modulator, int_modulator = is_modulator(new_index-1)
    
        -- print("1",new_index == vb.views.cmbSources2.value, new_index - 1 == int_operator_selected, bool_is_modulator,int_modulator ~= (new_index-1))
      
        if 
          new_index == vb.views.cmbSources2.value or 
          new_index - 1 == int_operator_selected or
          (bool_is_modulator and int_modulator ~= (int_operator_selected)) 
        then
          renoise.app():show_status("An invalid operator has been selected. Selection will be reset.");
          vb.views.cmbSources1.value = 1      
        end
        
        array_int_modulators[vb.views.cmbSources1.value-1] = int_operator_selected
      end
    },
    
    vb:text {
      text = "=>"
    },

    vb:popup {
      id = "cmbSources2",
      items = generate_modulator_matrix(),
      notifier = function(new_index)
        local bool_is_modulator, int_modulator = is_modulator(new_index-1)
      
        --print("2",new_index == vb.views.cmbSources1.value, new_index - 1 == int_operator_selected, bool_is_modulator,int_modulator ~= (new_index-1))
    
        if 
          new_index == vb.views.cmbSources1.value or 
          new_index - 1 == int_operator_selected or
          (bool_is_modulator and int_modulator ~= (int_operator_selected)) 
        then
          renoise.app():show_status("An invalid operator has been selected. Selection will be reset.");
          vb.views.cmbSources2.value = 1      
        end
        
        array_int_modulators[vb.views.cmbSources2.value-1] = int_operator_selected
        
      end
    }
  }
  
  local label_morphing_time = vb:text {
    id = "lblMorphingTime",
    text = "Morph. time",
    width = TEXT_LABEL_WIDTH
  }
  
  local slider_morphing_time = vb:slider {
    id = "sldMorphingTime",
    min = 0,
    max = 1,
    value = 1,
    width = CONTROL_WIDTH,
    notifier = function(real_new_value)
      array_morphing_times[int_operator_selected] = real_new_value
    end
  }
  
  local row_morphing_time = vb:row {
    id = "rowMorphingTime",
    width = CONTENT_WIDTH,
    label_morphing_time,
    slider_morphing_time
  }
  
    local column_gui = vb:column {
      id = "columnGui",
      style = "group",
      margin = MARGIN_DEFAULT,
      text_operator,
      row_wave,
      column_wavetable,
      row_amplitude,
      row_width,
      row_invert,
      row_frequency_multiplier,
      row_sources,
      row_morphing_time,
      row_modulate
    }
  
    return column_gui
  end
  

  -- main layout

  local row_autogenerate = vb:horizontal_aligner {
    id = "rowAutoGenerate",
    mode = "justify",
    
    vb:button {
      text = "Generate",
      tooltip = "Generate a custom wave with the specified features.",
      height = DIALOG_BUTTON_HEIGHT,
      notifier = function()
        generate()
      end
    },
    
    vb:row { 
      margin = (DIALOG_BUTTON_HEIGHT - CONTROL_HEIGHT) / 2,
      vb:checkbox {
        id = "chkAutoGenerate",
        value = toggle_auto_generate,
        notifier = function(boolean_value)
          toggle_auto_generate = boolean_value
          if toggle_auto_generate then
            generate()
          end
        end
      },
      vb:text {
        text = "auto update?"
      },
    },
    
    vb:button {
      text = "Reset",
      height = DIALOG_BUTTON_HEIGHT,
      tooltip = "Reset all data",
      notifier = function()

        if renoise.app():show_prompt(
          "Parameters Reset",
            "Are you sure you want to reset all parameters data?",{"Yes","No"}
          ) == "Yes" 
        then
          reset_gui()
          if toggle_auto_generate then
            generate()
          end
        end
      
      end
    }
  }


  local dialog_content = vb:column {
    id = "colContainer",
    margin = MARGIN_DEFAULT,
    spacing = SPACING_DEFAULT,
    create_global_properties(),
    create_operator_gui(),
    row_autogenerate
  }

  change_tab(1)

  if dialog == nil then
    change_wave(1,WAVE_SINE)
  end

  dialog = renoise.app():show_custom_dialog (
    "Custom Wave Generator",
    dialog_content
  )

end

