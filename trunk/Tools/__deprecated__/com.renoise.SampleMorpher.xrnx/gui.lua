--[[============================================================================
gui.lua
============================================================================]]--

local last_instrument = 0
local last_sample = 0
local notifiers = {}

instrument1 = 0
instrument2 = 0
sample1 = 0
sample2 = 0
samples = 1
one_instrument_per_sample = true

local MARGIN_DEFAULT = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
local SPACING_DEFAULT = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING

vb = nil 
dialog = nil

function instruments_list_changed()

  
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

  local TEXT_LABEL_WIDTH = 80
  local CONTROL_WIDTH = 100
  local CONTENT_WIDTH = TEXT_LABEL_WIDTH + CONTROL_WIDTH

  local DIALOG_BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT
  local CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT

  vb = renoise.ViewBuilder()

  local label1 = vb:text {
    text = "Source #1",
	align = "center"
  }
  
  local dropdown_instruments1 = vb:popup {
	
    id = "cmbInstruments1",
    width = CONTENT_WIDTH,
    items = generate_instrument_matrix(),
    value = 1,
	  
    notifier = function(new_index)
    
      local instrument_index = new_index - 1
 
      if instrument_index > 0 and vb.views.cmbSamples1 then
        vb.views.cmbSamples1.visible = true
        vb.views.cmbSamples1.items = generate_sample_matrix(instrument_index)
      else
        vb.views.cmbSamples1.visible = false
      end
 
      instrument1 = instrument_index
 
    end
    
  }

  local label2 = vb:text {
    text = "Source #2",
	align = "center"
  }
  
  local dropdown_samples1 = vb:popup {
    id = "cmbSamples1",
    width = CONTENT_WIDTH,
    items = generate_sample_matrix(0),
    value = 1,
    notifier = function(new_index)

      sample1 = new_index - 1
	  
    end
  }
  
  local dropdown_instruments2 = vb:popup {
	
    id = "cmbInstruments2",
    width = CONTENT_WIDTH,
    items = generate_instrument_matrix(),
    value = 1,
	  
    notifier = function(new_index)
    
      local instrument_index = new_index - 1
 
      if instrument_index > 0 and vb.views.cmbSamples2 then
        vb.views.cmbSamples2.visible = true
        vb.views.cmbSamples2.items = generate_sample_matrix(instrument_index)
      else
        vb.views.cmbSamples2.visible = false
      end
	  
	  instrument2 = instrument_index
 
    end
    
  }
  
  local dropdown_samples2 = vb:popup {
    id = "cmbSamples2",
    width = CONTENT_WIDTH,
    items = generate_sample_matrix(0),
    value = 1,
    notifier = function(new_index)

	  sample2 = new_index - 1
	  
    end
  }
    

  local column1 = vb:column {
    id = "colContainer1",
	label1,
	dropdown_instruments1,
	dropdown_samples1,
    margin = MARGIN_DEFAULT,
    spacing = SPACING_DEFAULT,
  }

  local column2 = vb:column {
    id = "colContainer2",
	label2,
	dropdown_instruments2,
	dropdown_samples2,
    margin = MARGIN_DEFAULT,
    spacing = SPACING_DEFAULT,
  }
  
  local row_dropdowns = vb:row {
    id = "rowDropdown",
	column1,
	column2,
    margin = MARGIN_DEFAULT,
    spacing = SPACING_DEFAULT
  }
  
  local label_samples = vb:text {
    id = "lblSamples",
	text = "No. of samples to generate:"
  }

  local valuebox_samples = vb:valuebox {
    id = "vlbSamples",
	min = 1,
	max = 16,
	value = 1,
	notifier = function(new_value)
	  samples = new_value
	  vb.views.rowAction.visible = samples > 1
	end
  }
  
  local row_samples = vb:horizontal_aligner {
    id = "rowSamples",
    mode = "center",
    margin = MARGIN_DEFAULT,
    spacing = SPACING_DEFAULT,
	label_samples,
	valuebox_samples
  }
  
  local checkbox_action = vb:checkbox {
    id = "chkAction",
	notifier = function(new_index)
	  one_instrument_per_sample = new_index
	end
  }
  
  local label_action = vb:text {
    id = "lblAction",
	text = "create one instrument per sample"
  }
  
  local row_action = vb:horizontal_aligner {
    id = "rowAction",
	mode = "center",
	checkbox_action,
	label_action
  }

  local dialog_contents = vb:column {
    style = "panel",
    row_dropdowns,
	row_samples,
	row_action,
    margin = MARGIN_DEFAULT,
    spacing = SPACING_DEFAULT
  }
  
  main()
  
  if(renoise.app():show_custom_prompt (
    "Sample morpher",
	dialog_contents,
	{"Generate","Cancel"}
  )) == "Generate" then
    generate()
  end
  
end



---- dropdown generation

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
