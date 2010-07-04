--[[----------------------------------------------------------------------------

  Script        : It-Alien_custom_wave.lua
  Creation Date : 2009/10/23
  Last modified : 2010/07/04
  Version       : 0.4

----------------------------------------------------------------------------]]--


-------------------------------------------------------------------------------
-- BEGIN: global constants
-------------------------------------------------------------------------------

local SAMPLE_BIT_DEPTH = 32
local SAMPLE_FREQUENCY = 44100 --this should be set to the driver' sample rate
local SAMPLE_CHANS = 1
  
local OPERATORS = 6

local WAVE_NONE = 1
local WAVE_ARCCOSINE = WAVE_NONE + 1
local WAVE_ARCSINE = WAVE_ARCCOSINE + 1
local WAVE_COSINE = WAVE_ARCSINE + 1
local WAVE_NOISE = WAVE_COSINE + 1
local WAVE_PULSE = WAVE_NOISE + 1
local WAVE_SAW = WAVE_PULSE + 1
local WAVE_SINE =  WAVE_SAW + 1
local WAVE_SQUARE = WAVE_SINE + 1
local WAVE_TANGENT = WAVE_SQUARE + 1
local WAVE_TRIANGLE = WAVE_TANGENT + 1
local WAVE_WAVETABLE = WAVE_TRIANGLE + 1
local WAVE_NUMBER = WAVE_WAVETABLE

local EPSILON = 1e-12
local MINUSINFDB = -200.0

local real_amplification = 1.0
local int_note = 58 --A-4
local int_wave_type_selected = 5 --Sine
local int_operator_selected = 1
local int_frames
local real_cycles = 1

local MARGIN_DEFAULT = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN

local TWOPI = 2*math.pi
local PI = math.pi
local HALFPI = PI * 0.5
local NOTE_BASE = math.pow(2,1/12)

-------------------------------------------------------------------------------
-- END: global constants
-------------------------------------------------------------------------------



-------------------------------------------------------------------------------
-- BEGIN: menu registration
-------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Sample Editor:Generate Custom Wave...",
  invoke = function() show_dialog() end
}

-------------------------------------------------------------------------------
-- END: menu registration
-------------------------------------------------------------------------------



-------------------------------------------------------------------------------
-- BEGIN: operator functions
-------------------------------------------------------------------------------

function arccosine(real_amplification, real_unused, real_x)
  return real_amplification * (-1 + 2 * math.acos(-1 + 2 * real_x) / PI)
end
  
function arcsine(real_amplification, real_unused, real_x)
  return real_amplification * math.asin(-1 + 2 * real_x) / HALFPI
end

function cosine(real_amplification, real_unused, real_x)
  return real_amplification * math.cos(TWOPI*real_x)
end

function noise(real_amplification, real_unused1, real_unused2)
  return real_amplification - 2 * real_amplification * math.random()
end

function pulse(real_amplification, real_width, real_x)
	print(tostring(real_x))
	print(tostring(real_width))
  if real_x > real_width then return -real_amplification else return real_amplification end
end

function saw(real_amplification, real_unused, real_x)
  return real_amplification*(2*real_x-1)
end

function sine(real_amplification, real_unused, real_x)
  return real_amplification * math.sin(TWOPI*real_x)
end

function square(real_amplification, real_unused, real_x)
  return pulse(real_amplification, 0.5, real_x)
end

function tangent(real_amplification, real_width, real_x)
  return real_amplification * math.tan(PI*real_x)*real_width
end

function triangle(real_amplification, real_unused, real_x)
  if real_x < 0.5 then
    return real_amplification*(-1+2*real_x/0.5)
  else
    return triangle(real_amplification,real_unused,1-real_x)
  end
end

function wave(real_amplification, buffer, real_x)
  local int_chan
  local real_value = 0
  if not buffer or not buffer.has_sample_data then
	return 0
  end
  for int_chan = 1, buffer.number_of_channels do
    real_value = real_value + real_amplification * buffer:sample_data(int_chan,(buffer.number_of_frames-1)*real_x+1)
  end
  real_value = real_value / buffer.number_of_channels
  return real_value  
end

function none(real_unused1, real_unused2, real_unused3)
  return 0
end

-------------------------------------------------------------------------------
-- END: operator functions
-------------------------------------------------------------------------------



-------------------------------------------------------------------------------
-- BEGIN: global variables 
-------------------------------------------------------------------------------

notifiers = {}

local array_string_operators = {"-NONE-","Arc Cosine", "Arc Sine", "Cosine", "Noise", "Pulse", "Saw", "Sine", "Square", "Tangent","Triangle", "Wave"}
local array_function_operators = {none,arccosine,arcsine,cosine,noise,pulse,saw,sine,square,tangent,triangle,wave}
local array_real_amplitudes = {}
local array_variant_parameters = {}
local array_instrument_number = {} -- to be used with WAVE operator
local array_sample_number = {} -- to be used with WAVE operator
local array_boolean_inverts = {}
local array_int_modulators = {}
local array_real_frequency_multipliers = {}
local array_waves = {}

local vb = nil 
local dialog = nil

-------------------------------------------------------------------------------
-- END: global variables 
-------------------------------------------------------------------------------




function note_to_frequency(int_note)
  return 440 * math.pow(NOTE_BASE,(int_note-58))
end

function convert_linear_to_db(real_value)
   if (real_value > EPSILON) then
    return math.log10(real_value) * 20.0
  else
    return MINUSINFDB
  end
end

function convert_db_to_linear(real_value)
  if (real_value > MINUSINFDB) then
    return math.pow(10.0, real_value * 0.05)
  else
    return 0.0
  end
end




-------------------------------------------------------------------------------
-- BEGIN: observable notifiers
-------------------------------------------------------------------------------

function instruments_list_changed()

	-- reset all WAVE operators
	for int_operator = 1, OPERATORS do
	
		array_instrument_number[int_operator] = 0
		array_sample_number[int_operator] = 0
		
		if array_waves[int_operator] == WAVE_WAVETABLE then

			change_wave(int_operator,WAVE_NONE)
		
		end
	
	end
	
	renoise.app():show_status("All operators of type 'Wave' have been reset because of a change in instruments list")
  
end

function new_song_loaded()

	if dialog.visible then
		dialog:close();
		if renoise.tool().app_new_document_observable:has_notifier(new_song_loaded) then
			renoise.tool().app_new_document_observable:add_notifier(new_song_loaded)
		end
	end

end

-------------------------------------------------------------------------------
-- END: observable notifiers
-------------------------------------------------------------------------------



-------------------------------------------------------------------------------
-- BEGIN: GUI functions
-------------------------------------------------------------------------------

function show_operator_parameters(int_wave_type)

  vb.views.rowWidth.visible = int_wave_type == WAVE_PULSE or int_wave_type == WAVE_TANGENT
  vb.views.colWaveTable.visible = int_wave_type == WAVE_WAVETABLE
  vb.views.rowInvert.visible = int_wave_type ~= WAVE_NOISE
  vb.views.rowMultiplier.visible = int_wave_type ~= WAVE_NOISE

end

function change_tab(int_operator_number)

  int_operator_selected = int_operator_number
  
  if not wave_is_set(int_operator_number) then
    initialize_wave(int_operator_number)
  end

  local real_amplitude = array_real_amplitudes[int_operator_number]
  local real_width = array_variant_parameters[int_operator_number]
  local int_wave_type = array_waves[int_operator_number]
  local real_frequency_multiplier = array_real_frequency_multipliers[int_operator_number]

  int_wave_type_selected = int_wave_type

  vb.views.txtOperator.text = "Operator " .. tostring(int_operator_number)  
  vb.views.sldAmplitude.value = real_amplitude
  
  if int_wave_type ~= WAVE_WAVETABLE then
	  if real_width ~= nil then
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
  
  show_operator_parameters(int_wave_type)

  vb.views.cmbModulate.items = generate_modulator_matrix()
  if array_int_modulators[int_operator_number] then
    vb.views.cmbModulate.value = array_int_modulators[int_operator_number] + 1
  else
    vb.views.cmbModulate.value = 1
  end
end

function change_wave(int_wave_number,int_wave_type_new)
  int_wave_type_selected = int_wave_type_new
  vb.views.cmbWave.value = int_wave_type_selected
  if not wave_is_set(int_wave_number) then
    initialize_wave(int_wave_number)
  end
  array_waves[int_operator_selected] = int_wave_type_new

  show_operator_parameters(int_wave_type_new)
  
  if int_wave_type_new == WAVE_WAVETABLE then
	  if array_instrument_number[int_wave_number] == 0 then
		generate_instrument_matrix()
		generate_sample_matrix(0)
	  end
	  vb.views.cmbInstruments.value = array_instrument_number[int_wave_number] + 1
	  vb.views.cmbSamples.value = array_sample_number[int_wave_number] + 1
  end
end

function generate_modulator_matrix()
  local array_string_modulators = {}
  local int_operator
  local int_count = 2
  array_string_modulators[1] = "-NONE-"
  for int_operator = 1, OPERATORS do
    if int_operator ~= int_operator_selected and wave_is_set(int_operator) and array_waves[int_operator] ~= WAVE_NONE and not is_modulator(int_operator) then
      array_string_modulators[int_count] = "Op " .. tostring(int_operator) .. "(" .. array_string_operators[array_waves[int_operator]] .. ")"
      int_count = int_count + 1
    end
  end
  return array_string_modulators
end

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

function generate_sample_matrix(int_instrument)
	
	if int_instrument <= 0 then
		return 
	end
		
	local int_samples = table.getn(renoise.song().instruments[int_instrument].samples)
	local int_count
	local array_string_return = {}
	
	for int_count = 1, int_samples do
		local string_name = renoise.song().instruments[int_instrument].samples[int_count].name
		if string_name == "" then
		string_name = "Sample #" .. tostring(int_count-1)
		end
		array_string_return[int_count+1] = string_name
	end  
	
	array_string_return[1] = "-- Select --"
	return array_string_return
end

function generate_note_matrix(int_start, int_end)

  local array_string_notes = {}
  local int_count = 1
  for int_note = int_start, int_end do
  
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

    array_string_notes[int_count] = string_note .. string_octave
    
    int_count = int_count + 1
    
  end
  
  return array_string_notes

end

function reset_gui()
  array_real_amplitudes = {}
  array_variant_parameters = {}
  array_boolean_inverts = {}
  array_int_modulators = {}
  array_real_frequency_multipliers = {}
  array_waves = {}
  int_note = 58
  real_amplification = 1.0
  int_operator_selected = 1
  int_wave_type_selected = 5
  vb.views.switchTabs.value = 1
  vb.views.chkInvert.value = false
end

function show_dialog()

	if not renoise.song().instruments_observable:has_notifier(instruments_list_changed) then
		renoise.song().instruments_observable:add_notifier(instruments_list_changed)	
	end
	
	if not renoise.tool().app_new_document_observable:has_notifier(new_song_loaded) then
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

  vb = renoise.ViewBuilder()

  -- create_global_properties

  local function create_global_properties()

  local row_note = vb:row {
    vb:text {
      text = "Note",
      width = TEXT_LABEL_WIDTH
    },
    vb:popup {
      width = CONTROL_WIDTH,
      value = int_note,
      items = generate_note_matrix(1,120),
      notifier = function(new_index)
        int_note = new_index
        int_frames = SAMPLE_FREQUENCY / note_to_frequency(new_index)
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
      value = 1,
      min = 0.5,
      max = SAMPLE_FREQUENCY,
      notifier = function(new_text)
        real_cycles = tonumber(new_text)
      end
    }
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
    if(real_amplification==0) then
      vb.views.txtDbValue.text = "-INF dB"
    else
      vb.views.txtDbValue.text = string.format("%.2f dB",convert_linear_to_db(real_amplification))
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
    row_note,
    row_cycles,
    row_label,
    slider_volume,
    switch_tabs
  }
  
  return column_global_properties
  
end


-- operator_gui

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
        array_int_modulators[int_operator_selected] = new_index - 1
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

		-- generate notifier name associated with the previously and newly selected instrument
		local samples_notifier_name = ("sample_list_changed_in_instrument_%d"):format(instrument_index)
		local last_samples_notifier_name = ("sample_list_changed_in_instrument_%d"):format(last_instrument)
		
		-- notifier for changes in samples list
		if instrument_index > 0 then
			notifiers[samples_notifier_name] = function ()

				-- the currently visible operator is a wavetable using the changed instrument as wavetable
				if array_waves[int_operator_selected] == WAVE_WAVETABLE and array_instrument_number[int_operator_selected] == instrument_index then
					-- rebuild samples list
					array_sample_number[int_operator_selected] = 0
					vb.views.cmbSamples.items = generate_sample_matrix(instrument_index)
					vb.views.cmbSamples.value = 1
				end
				
				local string_warning = ' ' -- we will use this to warn the user about what is happening
				
				-- loop over all operators to reset all the operators which have the changed isntrument as wavetable
				for int_operator = 1, OPERATORS do
				
					if array_waves[int_operator] and array_waves[int_operator] == WAVE_WAVETABLE and array_instrument_number[int_operator] == instrument_index then
						array_sample_number[int_operator] = 0
						string_warning = string_warning .. tostring(int_operator) .. ', '
					end
					
				end
					
				if string.len(string_warning) > 1 then
					renoise.app():show_status(("The following operators have been reset because of changes in sample list of instrument %d: "):format(instrument_index-1) .. string.sub(string_warning,1,string.len(string_warning)-2))
				end

			end
			
		end

		--remove any notifier from the previously selected sample
		if last_instrument > 0 and (renoise.song().instruments[last_instrument].samples_observable:has_notifier(notifiers[last_samples_notifier_name])) then
			renoise.song().instruments[last_instrument].samples_observable:remove_notifier(notifiers[last_samples_notifier_name])
		end

		-- only add notifier if there is no yet another
		if instrument_index > 0 and not (renoise.song().instruments[instrument_index].samples_observable:has_notifier(notifiers[samples_notifier_name])) then
			renoise.song().instruments[instrument_index].samples_observable:add_notifier(notifiers[samples_notifier_name])
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
      end
    }
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
    row_modulate
  }

  return column_gui
end


  -- main layout

  local button_generate = vb:button {
    text = "Generate",
    tooltip = "Hit this button to generate a custom wave with the specified features.",
    width = "100%",
    height = DIALOG_BUTTON_HEIGHT,
    notifier = function()
      generate()
    end
  }

  local button_reset = vb:button {
    text = "Reset",
    width = "100%",
    height = DIALOG_BUTTON_HEIGHT,
    tooltip = "Reset all data",
    notifier = function()
      if renoise.app():show_prompt("Parameters Reset",
      "Are you sure you want to reset all parameters data?",{"Yes","No"}) == "Yes" then
      reset_gui()
      end
    end
  }

  local dialog_content = vb:column {
    id = "colContainer",
    margin = MARGIN_DEFAULT,
    spacing = SPACING_DEFAULT,
    create_global_properties(),
    create_operator_gui(),
    button_generate,
    button_reset
  }

  change_wave(1,WAVE_SINE)
  change_tab(1)

  dialog = renoise.app():show_custom_dialog (
  "Custom Wave Generator",
  dialog_content
  )

end

-------------------------------------------------------------------------------
-- END: GUI functions
-------------------------------------------------------------------------------



-------------------------------------------------------------------------------
-- BEGIN: data processing functions
-------------------------------------------------------------------------------

function wave_is_set(int_wave)

	return
		array_waves[int_wave] and 
		array_real_amplitudes[int_wave] and 
		(array_variant_parameters[int_wave] ~= nil or array_instrument_number[int_wave]) and 
		array_waves[int_wave] ~= WAVE_NONE
		
end

function initialize_wave(int_wave_number)
	array_waves[int_wave_number] = WAVE_NONE
	array_real_amplitudes[int_wave_number] = 1
	array_variant_parameters[int_wave_number] = 0.5
	array_boolean_inverts[int_wave_number] = false
	array_real_frequency_multipliers[int_wave_number] = 1.0
	array_int_modulators[int_wave_number] = 0
	array_instrument_number[int_wave_number] = 0
	array_sample_number[int_wave_number] = 0
end

function is_modulated(int_operator)

  local int_count
  local int_mod = 0
  local array_int_return = {}
  for int_count = 1,OPERATORS do
    if array_int_modulators[int_count] == int_operator then
      int_mod = int_mod + 1
      array_int_return[int_mod] = int_count
    end
  end
  
  return array_int_return, int_mod
  
end

function is_modulator(int_operator)

  return array_int_modulators[int_operator] and array_int_modulators[int_operator] > 0

end

function operate(int_wave,real_x)

  local real_phase = real_x

  if array_real_frequency_multipliers[int_wave] then real_phase = math.fmod(real_phase * array_real_frequency_multipliers[int_wave],1.0) end

  local real_amplitude = array_real_amplitudes[int_wave]
  local variant_parameter = array_variant_parameters[int_wave]
  
  local real_operator_value
  if array_waves[int_wave] then  
     real_operator_value = array_function_operators[array_waves[int_wave]](real_amplitude,variant_parameter,real_phase)
  else
    real_operator_value = 0
  end

  if array_boolean_inverts[int_wave] then real_operator_value = -1 * real_operator_value end
  
  return real_operator_value
  
end

function process_data(real_amplification,real_x)

  local int_waves = table.getn(array_waves)
  local int_wave
  local int_valid_waves = 0
  local real_frame_value = 0
  for int_wave = 1, int_waves do
  
    if array_waves[int_wave] == WAVE_WAVETABLE and array_instrument_number[int_wave] > 0 and array_sample_number[int_wave] > 0 then
	-- for WAVE mode, get the latest sample buffer
		array_variant_parameters[int_wave] = renoise.song().instruments[array_instrument_number[int_wave]].samples[array_sample_number[int_wave]].sample_buffer
    end

  
    if wave_is_set(int_wave) and array_waves[int_wave] > 0 and is_modulator(int_wave) == false then
    
      local real_modulator = 0.0

      local array_modulators, int_modulators = is_modulated(int_wave)
      if int_modulators > 0 then
        --modulate the amplitude of the current operator by the operators which are assigned to it 
        local int_modulator
        local array_real_modulators = {}
        local int_count = 0
        for int_modulator = 1, int_modulators do
   
          int_count = int_count + 1
          local int_wave = array_modulators[int_modulator]
          array_real_modulators[int_count] = array_real_amplitudes[int_wave] * operate(int_wave,real_x)
          
        end

        for int_modulator = 1, int_modulators do
          real_modulator = real_modulator + array_real_modulators[int_modulator]
        end
        real_modulator = real_modulator / int_modulators

      end
    
      local real_operator_value = operate(int_wave,real_x)
        
      real_frame_value = real_frame_value + real_operator_value * (1 + real_modulator)
        
      int_valid_waves = int_valid_waves + 1
            
    end
  
  end
  
  if int_valid_waves > 0 then
    real_frame_value = real_amplification * real_frame_value / int_valid_waves
  end
  
  return real_frame_value, int_valid_waves

end

function generate()

  local instrument = renoise.song().selected_instrument
  local int_sample_index = renoise.song().selected_sample_index
  local int_samples = table.getn(instrument.samples)
  
  local buffer_new,sample_new
  if(int_samples == 0) then 
    sample_new = instrument:insert_sample_at(int_sample_index) 
  else
    sample_new = renoise.song().selected_sample
  end
  buffer_new = sample_new.sample_buffer
  
  if int_frames == nil then int_frames = SAMPLE_FREQUENCY / note_to_frequency(int_note) end
  
  --create the new sample
  if int_frames > 0 and not buffer_new:create_sample_data(SAMPLE_FREQUENCY, SAMPLE_BIT_DEPTH, SAMPLE_CHANS, real_cycles*int_frames) then
    renoise.app():show_error("Error during sample creation!")
    renoise.song():undo()
    return
  end
  
  local int_chan,int_frame,real_frame_value,int_valid_waves
  for int_chan = 1, SAMPLE_CHANS do
    for int_frame = 1, buffer_new.number_of_frames do
      real_frame_value, int_valid_waves = process_data(real_amplification,int_frame/int_frames)
      buffer_new:set_sample_data(int_chan,int_frame,real_frame_value)
    end
  end
  
  buffer_new:finalize_sample_data_changes()
  
  sample_new.base_note = int_note-1
  instrument.split_map[int_note] = int_sample_index

end

-------------------------------------------------------------------------------
-- END: data processing functions
-------------------------------------------------------------------------------
