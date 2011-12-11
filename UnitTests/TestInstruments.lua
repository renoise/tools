--[[--------------------------------------------------------------------------
TestInstruments.lua
--------------------------------------------------------------------------]]--

do
  
  ----------------------------------------------------------------------------
  -- tools
  
  local function assert_error(statement)
    assert(pcall(statement) == false, "expected function error")
  end
  
  
  -- shortcuts
  
  local song = renoise.song()
  
  local selected_instrument = song.instruments[
    song.selected_instrument_index]
  
  
  
  ----------------------------------------------------------------------------
  -- insert/delete/swap
  
  local new_instr = song:insert_instrument_at(#song.instruments + 1)
  new_instr.name = "New Instrument!"
  
  song.selected_instrument_index = #song.instruments
  assert(song.selected_instrument.name == "New Instrument!")
  
  song:insert_instrument_at(#song.instruments + 1)
  song:delete_instrument_at(#song.instruments)
  
  assert_error(function()
    song:insert_instrument_at(#song.instruments + 2)
  end)
  
  assert_error(function()
    song:insert_instrument_at(0)
  end)
  
  song:insert_instrument_at(1)
  song:delete_instrument_at(1)
  
  song.instruments[1].name = "1"
  song.instruments[2].name = "2"
  song:swap_instruments_at(1, 2)
  
  assert(song.instruments[1].name == "2")
  assert(song.instruments[2].name == "1")
  
  song:swap_instruments_at(1, 2)
  assert(song.instruments[1].name == "1")
  assert(song.instruments[2].name == "2")
  
  song:delete_instrument_at(#song.instruments)


  ----------------------------------------------------------------------------
  -- midi input properties
    
  local midi_input_devices = table.create(renoise.Midi.available_input_devices())
  
  if (#midi_input_devices > 0) then
     
    local instrument = song:insert_instrument_at(#song.instruments + 1)
    local midi_input_properties = instrument.midi_input_properties
    
    assert(midi_input_properties ~= nil)
    
    -- Test device name
    
    local num_input_device_changes = 0
    function input_device_changed()
      num_input_device_changes = num_input_device_changes + 1
    end
    
    midi_input_properties.device_name_observable:add_notifier(
      input_device_changed)
    
    assert(midi_input_properties.device_name == "")
    
    assert_error(function()
      midi_input_properties.device_name = "__Some_Invalid_Device_Name__"
    end)
    
    for _, device_name in ipairs(midi_input_devices) do
      midi_input_properties.device_name = device_name
      assert(midi_input_properties.device_name == device_name)
    end
    
    midi_input_properties.device_name = ""
    assert(midi_input_properties.device_name == "")
    
    assert(num_input_device_changes == #midi_input_devices + 1)
    
    
    -- Test channel
    
    local num_input_channel_changes = 0
    function input_channel_changed()
      num_input_channel_changes = num_input_channel_changes + 1
    end
    
    midi_input_properties.channel_observable:add_notifier(
      input_channel_changed)
    
    for channel = 1, 16 do
      midi_input_properties.channel = channel
      assert(midi_input_properties.channel == channel)
    end
    
    midi_input_properties.channel = 0
    assert(midi_input_properties.channel == 0)
    
    assert_error(function()
      midi_input_properties.channel = -1
    end)
    
    assert_error(function()
      midi_input_propertier.channel = 17
    end)
    
    assert(num_input_channel_changes == 17)
    
    
    -- Test assigned track
    
    local num_input_assigned_track_changes = 0
    function input_assigned_track_changed()
      num_input_assigned_track_changes = 
        num_input_assigned_track_changes + 1
    end
    
    midi_input_properties.assigned_track_observable:add_notifier(
      input_assigned_track_changed)
    
    for track = 1, renoise.song().sequencer_track_count do
      midi_input_properties.assigned_track = track
      assert(midi_input_properties.assigned_track == track)
    end
    
    midi_input_properties.assigned_track = 0
    assert(midi_input_properties.assigned_track == 0)
    
    assert_error(function()
      midi_input_properties.assigned_track = -1
    end)
    
    assert_error(function()
      midi_input_properties.assigned_track = 
        renoise.song().sequencer_track_count + 1
    end)
    
    assert(num_input_assigned_track_changes == 
      renoise.song().sequencer_track_count + 1)
    
    
    -- Remove all test observables
    
    midi_input_properties.device_name_observable:remove_notifier(input_device_changed)
    midi_input_properties.channel_observable:remove_notifier(input_channel_changed)
    midi_input_properties.assigned_track_observable:remove_notifier(input_assigned_track_changed)
    
    song:delete_instrument_at(#song.instruments)

  end

  ----------------------------------------------------------------------------
  -- midi output properties
  
  local midi_outputs = table.create(renoise.Midi.available_output_devices())
  

  ----------------------------------------------------------------------------
  -- plugin properties

  local instrument = song:insert_instrument_at(#song.instruments + 1)
  local plugin_properties = instrument.plugin_properties
  
  local available_plugins = plugin_properties.available_plugins

  assert(plugin_properties.plugin_loaded == false)
  
  assert(plugin_properties:load_plugin("audio/generators/VST/doesnotexist") == false)
  
  local new_plugin_path = available_plugins[math.random(#available_plugins)]

  -- plugin may fail to load. do not assert
  if (plugin_properties:load_plugin(new_plugin_path)) then
    assert(plugin_properties.plugin_loaded == true)
    assert(plugin_properties.plugin_device.device_path == new_plugin_path)
    
    local plugin_device = plugin_properties.plugin_device
     
    assert(plugin_device.external_editor_visible == false)
    plugin_device.external_editor_visible = true
    assert(plugin_device.external_editor_visible == true)
    plugin_device.external_editor_visible = false
    assert(plugin_device.external_editor_visible == false)
    
    -- can't assert parameters and presets, cause they may not be present
    -- simply access them to test...
    local parameters = plugin_device.parameters
    local presets = plugin_device.presets
  end

  song:delete_instrument_at(#song.instruments)

end


------------------------------------------------------------------------------
-- test finalizers

collectgarbage()


--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--
