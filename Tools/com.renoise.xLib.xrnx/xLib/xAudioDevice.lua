class 'xAudioDevice'

--------------------------------------------------------------------------------
-- determine if a device is linked to different fx-chains/tracks
-- (detection not solid if the destination is automated - rare case!)
-- @param device (renoise.AudioDevice)
-- @return table (linked fx-chains/tracks)

function xDevice.get_device_routings(device)
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
-- @param device (renoise.AudioDevice)
-- @return bool 

function xDevice.is_send_device(device)
  --TRACE("xDevice.is_send_device(device)",device)

  local send_devices = {"#Send","#Multiband Send"}
  return table.find(send_devices,device.name)

end

