--[[--------------------------------------------------------------------------
TestTrackDevices.lua
--------------------------------------------------------------------------]]--

do

  ----------------------------------------------------------------------------
  -- tools
  
  local function assert_error(statement)
    assert(pcall(statement) == false, "expected function error")
  end
  
  
  -- shortcuts
  
  local song = renoise.song()
  
  song.selected_track_index = 1 -- make sure its a player track
  local selected_track = song.tracks[song.selected_track_index]
  
  
  ----------------------------------------------------------------------------
  -- insert/delete/swap
  
  local avail_devices = selected_track.available_devices
  
  local new_device_name, new_device_name2
  
  repeat
    new_device_name = avail_devices[math.random(1, #avail_devices)]
    new_device_name2 = avail_devices[math.random(1, #avail_devices)]
  until
    -- avoid plugins, cause they may fail to load and pop up dialogs
    not string.find(new_device_name, "VST") and
    not string.find(new_device_name, "AU") and
    not string.find(new_device_name2, "VST") and
    not string.find(new_device_name2, "AU")
  
  assert_error(function()
    selected_track:insert_device_at("InvalidDeviceName#234", #selected_track.devices + 1)
  end)
  
  assert_error(function()
    selected_track:insert_device_at(new_device_name, 1)
  end)
  
  assert_error(function()
    selected_track:delete_device_at(1)
  end)
  
  local device_count = #selected_track.devices
  
  local new_device = selected_track:insert_device_at(new_device_name, 2)
  device_count = device_count + 1
  assert(device_count == #selected_track.devices)
  
  local found_device = false
  
  for _,device in ipairs(selected_track.devices) do
    if device.name == new_device.name then
       found_device = true
    end
  end
  
  assert(found_device)
  
  selected_track:delete_device_at(2)
  device_count = device_count - 1
  assert(device_count == #selected_track.devices)
  
  selected_track:insert_device_at(new_device_name, 
    #selected_track.devices + 1)
  
  selected_track:insert_device_at(new_device_name2, 
    #selected_track.devices + 1)
  
  device_count = device_count + 2
  assert(device_count == #selected_track.devices)
  
  
  selected_track:swap_devices_at(
    #selected_track.devices, 
    #selected_track.devices - 1)
  
  assert(device_count == #selected_track.devices)
  
  
  selected_track:delete_device_at(2)
  selected_track:delete_device_at(2)
  
  device_count = device_count - 2
  assert(device_count == #selected_track.devices)
  
  
  -- preset handing
  
  local trackvolpan = selected_track.devices[1]
  assert(#trackvolpan.presets == 1) -- init
  
  selected_track:insert_device_at(new_device_name, 
    #selected_track.devices + 1)
    
  local new_device = selected_track.devices[#selected_track.devices]
  
  assert(#new_device.presets >= 1)
  assert(new_device.active_preset >= 1)

  local new_preset = math.random(#new_device.presets)
  new_device.active_preset = new_preset
  assert(new_device.active_preset == new_preset)
  
  assert_error(function()
    new_device.active_preset = 0
  end)
  assert_error(function()
    new_device.active_preset = #new_device.presets + 1
  end)

end


------------------------------------------------------------------------------
-- test finalizers

collectgarbage()


--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--
