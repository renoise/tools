--[[============================================================================
xLib
============================================================================]]--

--[[--

Static methods for dealing with Audio Devices
.
#

]]


class 'xAudioDevice'

--==============================================================================
-- Static Methods
--==============================================================================

--- Resolve the device/parameter indices based on a parameter
-- (TODO: API5 has built-in functionality)
-- @param param, renoise.DeviceParameter 
-- @param track_idx, restrict search to this track
-- @param device_idx, restrict search to this device
-- @return int, parameter index
-- @return int, device index
-- @return int, track index

function xAudioDevice.resolve_parameter(param,track_idx,device_idx)

  if not param then
    return
  end

  local search_device = function(device,device_idx,track_idx)
    for k,v in ipairs(device.parameters) do
      if rawequal(v,param) then
        return k,device_idx,track_idx
      end
    end
  end

	local search_track = function(track,device_idx,track_idx)
		if device_idx then
      local device = track.devices[device_idx]
			if not device then
				return 
			end
      return search_device(device,device_idx,track_idx)
    else
      --print("search devices...")
      for _,device in ipairs(track.devices) do
        local param_idx = search_device(device,device_idx,track_idx)
        if param_idx then
          return param_idx,device_idx,track_idx
        end
      end
		end
	end


  if track_idx and device_idx then
    --print("search single device - track_idx",track_idx,"device_idx",device_idx)
		local track = rns.tracks[track_idx]
		if not track then
			return
		end
    local device = track.devices[device_idx]
    if not device then
      return 
    end
    return search_device()

  elseif track_idx then
    --print("search single track - track_idx",track_idx)
		local track = rns.tracks[track_idx]
		if not track then
			return
		end
		return search_track(track,device_idx,track_idx)
	else
    --print("search all tracks")
		for _,track in ipairs(rns.tracks) do
      local param_idx = search_track(track,device_idx,track_idx)
      if param_idx then
        return param_idx,device_idx,track_idx
      end 
		end
	end

end

--------------------------------------------------------------------------------

--- Determine if a device is linked to different fx-chains/tracks
-- (detection not solid if the destination is automated - rare case!)
-- @param device (renoise.AudioDevice)
-- @return table (linked fx-chains/tracks)

function xAudioDevice.get_device_routings(device)
  --TRACE("xDevice.get_device_routings(device)",device)

  local routings = {}
  for k,param in ipairs(device.parameters) do
    if (param.name:match("Out%d Track")) or
      (param.name:match("Receiver %d")) or
      (param.name == "Dest. Track") or
      (param.name == "Receiver")          
    then
      --print("found a possible linked device",device.name,param.name,param.value)
      if (param.value ~= 0) then
        routings[param.value+1] = true
      end
    end
  end

  return routings

end

--------------------------------------------------------------------------------

--- Check if provided device is a send device
-- @param device (renoise.AudioDevice)
-- @return bool 

function xAudioDevice.is_send_device(device)
  --TRACE("xAudioDevice.is_send_device(device)",device)

  local send_devices = {"#Send","#Multiband Send"}
  return table.find(send_devices,device.name)

end

