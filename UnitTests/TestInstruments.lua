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
  -- plugin properties
  
  local instrument = song:insert_instrument_at(#song.instruments + 1)
  local plugin_properties = instrument.plugin_properties
  
  local available_plugins = plugin_properties.available_plugins
  
  assert(plugin_properties.plugin_name == "")
  assert(plugin_properties.plugin_loaded == false)
  
  assert(plugin_properties:load_plugin("audio/generators/VST/doesnotexist") == false)
  
  local new_plugin = available_plugins[math.random(#available_plugins)]

  -- plugin may fail to load. do not assert
  if (plugin_properties:load_plugin(new_plugin)) then
    assert(plugin_properties.plugin_name == new_plugin)
    assert(plugin_properties.plugin_loaded == true)
    assert(plugin_properties.external_editor_visible == false)
    
    plugin_properties.external_editor_visible = true
    assert(plugin_properties.external_editor_visible == true)
    plugin_properties.external_editor_visible = false
    assert(plugin_properties.external_editor_visible == false)
    
    -- can't assert parameters and presets, cause they may not be present
    -- simply access them to test...
    local parameters = plugin_properties.plugin_device.parameters
    local presets = plugin_properties.plugin_device.presets
  end

  song:delete_instrument_at(#song.instruments)
end


------------------------------------------------------------------------------
-- test finalizers

collectgarbage()


--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--
