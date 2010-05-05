--[[--------------------------------------------------------------------------
TestMidi.lua
--------------------------------------------------------------------------]]--

-- tools

local function assert_error(statement)
  assert(pcall(statement) == false, "expected function error")
end


------------------------------------------------------------------------------
-- device enumeration

local inputs = table.create(renoise.Midi.available_input_devices())
local outputs = table.create(renoise.Midi.available_output_devices())


------------------------------------------------------------------------------
-- output device

if (#outputs > 0) then
  assert_error(function()
    renoise.Midi.create_output_device("Foo!")
  end)

  -- test monitoring with LoopBe if possible
  local device_name = outputs:find("LoopBe Internal MIDI") and
    "LoopBe Internal MIDI" or outputs[1]

  local device = renoise.Midi.create_output_device(device_name)
  assert(device)

  assert(device.is_open)
  assert(device.name == device_name)

  -- test raw messages
  device:send({0x90, 0x10, 0x7F})

  assert_error(function()
    device:send({0x90, 0x10, 0x7F, 0x20})
  end)

  assert_error(function()
    device:send({0x100})
  end)

  assert_error(function()
    device:send({-1})
  end)

  -- test sysex
  device:send({0xF0, 0x10, 0x11, 0x12, 0xF7})

  assert_error(function()
    device:send({0xF0, 0x10, 0x11, 0x12})
  end)

  assert_error(function()
    device:send({0xF0, 0x10, 0x11, 0x100, 0xF7})
  end)

  -- close
  device:close()
  assert(not device.is_open)
  assert(device.name == "")

  assert_error(function()
    device:send({0x90, 0x10, 0x7F})
  end)
end


------------------------------------------------------------------------------
-- input device

-- keep the last one running for testing
local input_device = nil
local midi_dumper = nil

if (#inputs > 0) then
  -- test monitoring with LoopBe if possible
  local device_name = inputs:find("LoopBe Internal MIDI") and
    "LoopBe Internal MIDI" or inputs[1]

  -- local function callbacks
  local function midi_callback(message)
    assert(#message == 3)
    assert(message[1] >= 0 and message[1] <= 0xff)
    assert(message[2] >= 0 and message[2] <= 0xff)
    assert(message[3] >= 0 and message[3] <= 0xff)

    print(("%s: func got MIDI %X %X %X"):format(device_name,
      message[1], message[2], message[3]))
  end

  local function sysex_callback(message)
    assert(message[1] == 0xF0 and message[#message] == 0xF7)

    local message_string = "["
    table.foreach(message, function(k, v)
      message_string = message_string .. string.format("%.2X", v)
      if k ~= #message then
        message_string = message_string .. ", "
      end
    end)
    message_string = message_string .. "]"

    print(("%s: func got SYSEX with %d bytes: %s"):format(
      device_name, #message, message_string))
  end

  -- class callbacks
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

    function MidiDumper:midi_callback(message)
      print(("%s: MidiDumper got MIDI %X %X %X"):format(
        self.device_name, message[1], message[2], message[3]))
    end

    function MidiDumper:sysex_callback(message)
      print(("%s: MidiDumper got SYSEX with %d bytes"):format(
        self.device_name, #message))
    end

  -- test
  assert_error(function()
    renoise.Midi.create_input_device(
      device_name, nil, nil)
  end)

  input_device = renoise.Midi.create_input_device(
    device_name, midi_callback)

  input_device = renoise.Midi.create_input_device(
    device_name, midi_callback, nil)

  input_device = renoise.Midi.create_input_device(
    device_name, nil, sysex_callback)

  input_device = renoise.Midi.create_input_device(
    device_name, midi_callback, sysex_callback)

  midi_dumper = MidiDumper(device_name)
  midi_dumper:start()
end


------------------------------------------------------------------------------
-- test finalizers

collectgarbage()


--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--

