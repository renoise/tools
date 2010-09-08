--[[--------------------------------------------------------------------------
TestParameters.lua
--------------------------------------------------------------------------]]--

do

  ----------------------------------------------------------------------------
  -- shortcuts
  
  local song = renoise.song()
  local selected_track = song.tracks[song.selected_track_index]
  
  
  ----------------------------------------------------------------------------
  -- default track parameters & device parameter iteration
  
  local found_prefx_volume_parameter = false
  local found_prefx_panning_parameter = false
  local found_prefx_width_parameter = false
  local found_postfx_volume_parameter = false
  local found_postfx_panning_parameter = false
  
  local track_device_parameters = selected_track.devices[1].parameters
  
  for _,param in ipairs(track_device_parameters) do
  
    if param.name == selected_track.prefx_volume.name then
      found_prefx_volume_parameter = true
  
    elseif param.name == selected_track.prefx_panning.name then
      found_prefx_panning_parameter = true
  
    elseif param.name == selected_track.prefx_width.name then
      found_prefx_width_parameter = true
  
    elseif param.name == selected_track.postfx_volume.name then
      found_postfx_volume_parameter = true
  
    elseif param.name == selected_track.postfx_panning.name then
      found_postfx_panning_parameter = true
    end
  
  end
  
  assert(found_prefx_volume_parameter)
  assert(found_prefx_panning_parameter)
  assert(found_prefx_width_parameter)
  assert(found_postfx_volume_parameter)
  assert(found_postfx_panning_parameter)
  
  
  ----------------------------------------------------------------------------
  -- parameter ranges & values
  
  assert(selected_track.prefx_volume.value_min <
    selected_track.prefx_volume.value_max)
  
  local new_value = math.random(selected_track.prefx_width.value_min,
    selected_track.prefx_width.value_max)
  
  selected_track.prefx_width.value = new_value
  assert(selected_track.prefx_width.value == new_value)
  
  selected_track.prefx_volume.value_string = "1.0 dB"
  assert(selected_track.prefx_volume.value_string == "1.000 dB")
  
  selected_track.postfx_volume.value_string = "3.0 dB"

 
  ----------------------------------------------------------------------------
  -- parameter automation flags
 
  assert(selected_track.prefx_volume.is_automatable)
  assert(not selected_track.postfx_volume.is_automatable)
 
end
  

------------------------------------------------------------------------------
-- test finalizers

collectgarbage()


--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--
