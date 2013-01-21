--[[============================================================================
midi_control.lua, start/stop midi engine, process midi messages
============================================================================]]--

  
function midi_engine(MODE)

  local device_name = device_list[selected_device]
  
  local midi_dumper = MidiDumper(device_name)

  if MODE == 'start' then

    if device_name ~= NO_DEVICE then
      midi_dumper:start()
    end

  else
    midi_dumper:stop()
  end
  

  if MODE=='start' then
    --Take care edit mode is always being turned off when learn mode
    --gets enabled. If no midi device detected, this still has to be 
    --triggered for PC keyboard mode!
    renoise.song().transport.edit_mode = false
  end

end


--------------------------------------------------------------------------------
--Midi callback function (see midi_device.lua for origination!)

function process_messages(message)
  local nr_debug = false
  local current_octave = renoise.song().transport.octave
  
  
  if message[1] >= 0x80 and message[1] <= 0x9F then

    if message[3] ~= 0 and message[1] >= 90 then

      if nr_debug then
        print (message[1],message[2],message[3],message[4])
--        print (midi_notes[tonumber(message[2])+1])
      end 
      if current_octave == 0 and message[2]> 11 then
        message[2] = message[2] - 12
      end
      local fnote = midi_notes[message[2]]

      if selected_channel > 0 then
        if channels[message[1]] == selected_channel then
          send_midi_messages(fnote,message[2])         
        end
      else
        send_midi_messages(fnote,message[2])         
      end
--[[
      if record_mode then

        if record_destination == PATTERN_EDITOR then
          map_to_pattern_editor(message)
        else
          map_to_track(message)
        end
       
      end
--]]
    else

      --Need note-off support? then do you stuff here....
      if nr_debug then
--        print ("OFF "..string.lower(midi_notes[tonumber(message[2])+1]))
      end

    end

  end

end

