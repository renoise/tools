--[[============================================================================
mididevice.lua
============================================================================]]--

class "MidiDumper"
  function MidiDumper:__init(device_name)
    self.device_name = device_name
  end
  
  function MidiDumper:start()
    self.device = renoise.Midi.create_input_device(
      self.device_name, 
      { self, MidiDumper.midi_callback }, 
      { MidiDumper.sysex_callback, self }
    )
  end
  
  function MidiDumper:stop()
    if self.device then 
      self.device:close()
      self.device = nil
    end
  end
  
  function MidiDumper:midi_callback(message)
--    print(("%s: MidiDumper got MIDI %X %X %X"):format(
--      self.device_name, message[1], message[2], message[3]))
      process_messages(message)
  end

  function MidiDumper:sysex_callback(message)
    print(("%s: MidiDumper got SYSEX with %d bytes"):format(
      self.device_name, #message))
  end

