--[[============================================================================
xMidiInput unit test
============================================================================]]--
--[[

  ## About

  Create an instance of xMidiInput and feed it messages, using a different callback function for each test. In the callback we confirm that the resulting xMidiMessage is interpreted correctly, and then convert it back into its original form

  (doubles as test of xMidiMessage)


]]

  require (xLib_dir.."xMidiInput")
  require (xLib_dir.."xMessage")
  require (xLib_dir.."xMidiMessage")

do

  print(">>> xMidiInput: starting unit-test...")


  local x_input = xMidiInput{
    callback_fn = function() 
      -- this is just a placeholder...
    end
  }

  x_input.multibyte_enabled = true
  x_input.nrpn_enabled = true
  x_input.terminate_nrpns = true


  -- NOTE_ON (channel 1) ------------------------------------------------------
  x_input.callback_fn = function(x_msg)
    print("got here NOTE_ON:1")
    assert(x_msg.message_type == xMidiMessage.TYPE.NOTE_ON)
    assert(x_msg.channel == 1)
    assert(x_msg.values[1] == 0x3C)
    assert(x_msg.values[2] == 0x7F)
    assert(x_msg.bit_depth == 7)
    local midi_msgs = x_msg:create_raw_message()
    assert(xLib.table_compare(midi_msgs[1],{0x90,0x3C,0x7F}))
  end
  x_input:input({0x90,0x3C,0x7F})


  -- NOTE_ON (channel 16) -----------------------------------------------------
  x_input.callback_fn = function(x_msg)
    print("got here NOTE_ON:16")
    assert(x_msg.message_type == xMidiMessage.TYPE.NOTE_ON)
    assert(x_msg.channel == 16)
    assert(x_msg.values[1] == 0x3C)
    assert(x_msg.values[2] == 0x7F)
    assert(x_msg.bit_depth == 7)
    local midi_msgs = x_msg:create_raw_message()
    assert(xLib.table_compare(midi_msgs[1],{0x9F,0x3C,0x7F}))
  end
  x_input:input({0x9F,0x3C,0x7F})


  -- NOTE_ON with zero velocity (translates to NOTE_OFF) ----------------------
  x_input.callback_fn = function(x_msg)
    print("got here NOTE_ON:NOTE_OFF")
    assert(x_msg.message_type == xMidiMessage.TYPE.NOTE_OFF)
    assert(x_msg.channel == 1)
    assert(x_msg.values[1] == 0x3C)
    assert(x_msg.values[2] == 0x00)
    assert(x_msg.bit_depth == 7)
    local midi_msgs = x_msg:create_raw_message()
    assert(xLib.table_compare(midi_msgs[1],{0x80,0x3C,0x00}))
  end
  x_input:input({0x90,0x3C,0x00})


  -- NOTE_OFF with >0 velocity ------------------------------------------------
  x_input.callback_fn = function(x_msg)
    print("got here NOTE_OFF")
    assert(x_msg.message_type == xMidiMessage.TYPE.NOTE_OFF)
    assert(x_msg.channel == 1)
    assert(x_msg.values[1] == 0x3C)
    assert(x_msg.values[2] == 0x20)
    assert(x_msg.bit_depth == 7)
    local midi_msgs = x_msg:create_raw_message()
    assert(xLib.table_compare(midi_msgs[1],{0x80,0x3C,0x20}))
  end
  x_input:input({0x80,0x3C,0x20})


  -- KEY_AFTERTOUCH -----------------------------------------------------------
  x_input.callback_fn = function(x_msg)
    print("got here KEY_AFTERTOUCH")
    assert(x_msg.message_type == xMidiMessage.TYPE.KEY_AFTERTOUCH)
    assert(x_msg.channel == 1)
    assert(x_msg.values[1] == 0x60)
    assert(x_msg.values[2] == 0x22)
    assert(x_msg.bit_depth == 7)
    local midi_msgs = x_msg:create_raw_message()
    assert(xLib.table_compare(midi_msgs[1],{0xA0,0x60,0x22}))
  end
  x_input:input({0xA0,0x60,0x22})

  x_input.multibyte_enabled = true


  -- CONTROLLER_CHANGE (7bit), channel 1 --------------------------------------
  local msg = {0xB0,0x07,0x40}
  -- exempt message (or we would be initiating a 14-bit message)
  x_input:add_multibyte_exempt(xMidiMessage.TYPE.CONTROLLER_CHANGE,{msg})
  x_input.callback_fn = function(x_msg)
    print("got here CONTROLLER_CHANGE")
    assert(x_msg.message_type == xMidiMessage.TYPE.CONTROLLER_CHANGE)
    assert(x_msg.channel == 1)
    assert(x_msg.values[1] == 0x07)
    assert(x_msg.values[2] == 0x40)
    assert(x_msg.bit_depth == 7)
    local midi_msgs = x_msg:create_raw_message()
    assert(xLib.table_compare(midi_msgs[1],{0xB0,0x07,0x40}))
  end
  x_input:input(msg)


  -- CONTROLLER_CHANGE (7bit), channel 16 -------------------------------------
  --  not exempted (no message as input initiates a 14-bit message)
  x_input.callback_fn = function(x_msg)
	  assert(x_msg == nil)
  end
  x_input:input({0xBF,0x07,0x40})
  --  repeat the message - now, the prior message should appear as 
  --  the second return-value (repeating a message cancels out any
  --  14-bit message which was waiting for the second part to arrive)
  local msg_count = 0
  x_input.callback_fn = function(x_msg)
    print("got here CONTROLLER_CHANGE - msg_count",msg_count)
    msg_count = msg_count+1
    if (msg_count == 1) then
      assert(x_msg.message_type == xMidiMessage.TYPE.CONTROLLER_CHANGE)
      assert(x_msg.channel == 16)
      assert(x_msg.values[1] == 0x07)
      assert(x_msg.values[2] == 0x40)
      assert(x_msg.bit_depth == 7)
      local midi_msgs = x_msg:create_raw_message()
      assert(xLib.table_compare(midi_msgs[1],{0xBF,0x07,0x40}))
    elseif (msg_count == 2) then
      assert(x_msg.message_type == xMidiMessage.TYPE.CONTROLLER_CHANGE)
      assert(x_msg.channel == 16)
      assert(x_msg.values[1] == 0x07)
      assert(x_msg.values[2] == 0x40)
      assert(x_msg.bit_depth == 7)
      local midi_msgs = x_msg:create_raw_message()
      assert(xLib.table_compare(midi_msgs[1],{0xBF,0x07,0x40}))
    end
  end
  x_input:input({0xBF,0x07,0x40})


  -- CONTROLLER_CHANGE (multibyte disabled) -----------------------------------
  x_input.callback_fn = function(x_msg)
    print("got here CONTROLLER_CHANGE")
    assert(x_msg.message_type == xMidiMessage.TYPE.CONTROLLER_CHANGE)
    assert(x_msg.channel == 1)
    assert(x_msg.values[1] == 0x22) 
    assert(x_msg.values[2] == 0x0F) 
    assert(x_msg.bit_depth == 7)
    local midi_msgs = x_msg:create_raw_message()
    assert(xLib.table_compare(midi_msgs[1],{0xB0,0x22,0x0F}))
  end
  x_input:input({0xB0,0x22,0x0F})

  x_input.multibyte_enabled = true


  -- PROGRAM_CHANGE -----------------------------------------------------------
  x_input.callback_fn = function(x_msg)
    print("got here PROGRAM_CHANGE")
    assert(x_msg.message_type == xMidiMessage.TYPE.PROGRAM_CHANGE)
    assert(x_msg.channel == 1)
    assert(x_msg.values[1] == 0x60)
    assert(x_msg.values[2] == 0x00)
    assert(x_msg.bit_depth == 7)
    local midi_msgs = x_msg:create_raw_message()
    assert(xLib.table_compare(midi_msgs[1],{0xC0,0x60,0x00}))
  end
  x_input:input({0xC0,0x60,0x00})


  -- CH_AFTERTOUCH -------------------------------------------------------
  --  (note the 0x22 which is ignored/set to 0)
  x_input.callback_fn = function(x_msg)
    print("got here CH_AFTERTOUCH")
    assert(x_msg.message_type == xMidiMessage.TYPE.CH_AFTERTOUCH)
    assert(x_msg.channel == 1)
    assert(x_msg.values[1] == 0x60)
    assert(x_msg.values[2] == 0x00)
    assert(x_msg.bit_depth == 7)
    local midi_msgs = x_msg:create_raw_message()
    assert(xLib.table_compare(midi_msgs[1],{0xD0,0x60,0x00}))
  end
  x_input:input({0xD0,0x60,0x22})

  -- SONG_POSITION ------------------------------------------------------------
  x_input.callback_fn = function(x_msg)
    print("got here SONG_POSITION")
    assert(x_msg.message_type == xMidiMessage.TYPE.SONG_POSITION)
    assert(x_msg.channel == nil)
    assert(x_msg.values[1] == 0x06)
    assert(x_msg.values[2] == 0x22)
    local midi_msgs = x_msg:create_raw_message()
    assert(xLib.table_compare(midi_msgs[1],{0xF2,0x06,0x22}))
  end
  x_input:input({0xF2,0x06,0x22})


  -- PITCH_BEND (status,LSB,MSB) ----------------------------------------------
  x_input.callback_fn = function(x_msg)
    print("got here PITCH_BEND")
    assert(x_msg.message_type == xMidiMessage.TYPE.PITCH_BEND)
    assert(x_msg.channel == 1)
    assert(x_msg.values[1] == 0x00)
    assert(x_msg.values[2] == 0x40)
    assert(x_msg.bit_depth == 7)
    local midi_msgs = x_msg:create_raw_message()
    assert(xLib.table_compare(midi_msgs[1],{0xE0,0x00,0x40}))
  end
  x_input:input({0xE0,0x00,0x40}) -- middle position


  -- PITCH_BEND (status,LSB,MSB) ----------------------------------------------
  x_input.callback_fn = function(x_msg)
    print("got here PITCH_BEND")
    assert(x_msg.message_type == xMidiMessage.TYPE.PITCH_BEND)
    assert(x_msg.channel == 1)
    assert(x_msg.values[1] == 0x7F)
    assert(x_msg.values[2] == 0x7F)
    assert(x_msg.bit_depth == 7)
    local midi_msgs = x_msg:create_raw_message()
    assert(xLib.table_compare(midi_msgs[1],{0xE0,0x7F,0x7F}))
  end
  x_input:input({0xE0,0x7F,0x7F}) -- max position

  -- CONTROLLER_CHANGE (14bit) ------------------------------------------------
  -- check if     0xBX,0xYY,0xZZ (X = Channel, YY = Number,   ZZ = Data MSB)
  -- followed by  0xBX,0xYY,0xZZ (X = Channel, YY = Number+32,ZZ = Data LSB)
  x_input.callback_fn = function(x_msg)
    error("got here CONTROLLER_CHANGE")
  	assert(x_msg == nil)
  end
  x_input:input({0xB0,0x02,0x3F})
  x_input.callback_fn = function(x_msg)
    print("got here CONTROLLER_CHANGE")
    assert(x_msg.message_type == xMidiMessage.TYPE.CONTROLLER_CHANGE)
    assert(x_msg.channel == 1)
    assert(x_msg.values[1] == 2) 
    assert(x_msg.values[2] == 0x1F8F) -- 8079
    assert(x_msg.bit_depth == 14)
    local midi_msgs = x_msg:create_raw_message()
    assert(xLib.table_compare(midi_msgs[1],{0xB0,0x02,0x3F}))
    assert(xLib.table_compare(midi_msgs[2],{0xB0,0x22,0x0F}))
  end
  x_input:input({0xB0,0x22,0x0F})


  -- PITCH_BEND (14-bit) ------------------------------------------------------
  -- check if     0xEX,0x00,0x00 (initiate)
  -- followed by  0xEX,0xYY,0x00 (MSB byte)
  -- and          0xEX,0xYY,0x00 (LSB byte, final value)
  x_input.callback_fn = function(x_msg)
    error("got here PITCH_BEND")
  	assert(x_msg == nil)
  end
  x_input:input({0xE0,0x00,0x00})
  x_input:input({0xE0,0x40,0x00})
  x_input.callback_fn = function(x_msg)
    assert(x_msg.message_type == xMidiMessage.TYPE.PITCH_BEND)
    assert(x_msg.channel == 1)
    assert(x_msg.values[1] == 0x2004)
    assert(x_msg.values[2] == 0x00)
    assert(x_msg.bit_depth == 14)
    local midi_msgs = x_msg:create_raw_message()
    assert(xLib.table_compare(midi_msgs[1],{0xE0,0x00,0x00}))
    assert(xLib.table_compare(midi_msgs[2],{0xE0,0x40,0x00}))
    assert(xLib.table_compare(midi_msgs[3],{0xE0,0x04,0x00}))
  end
  x_input:input({0xE0,0x04,0x00})

  -- TODO test whether 7bit pitchbend could get mistaken for 14bit? 

  -- 7bit NRPN (MSB only, non-terminated)--------------------------------------
  -- check if     0xBX,0x63,0xYY  (X = Channel, Y = NRPN Number MSB)
  -- and          0xBX,0x06,0xYY  (X = Channel, Y = Data Entry MSB)
  --[[
  x_input.callback_fn = function(x_msg)
    error("got here NRPN: MSB only")
  	assert(x_msg == nil)
  end
  x_input:input({0xB1,0x63,0x7E})
  x_input.callback_fn = function(x_msg)
    print("got here NRPN - non-terminated message")
    assert(x_msg.message_type == xMidiMessage.TYPE.NRPN)
    assert(x_msg.channel == 1)
    assert(x_msg.values[1] == 16191) 
    assert(x_msg.values[2] == 827)  -- 780 + 47
    local midi_msgs = x_msg:create_raw_message()
    assert(xLib.table_compare(midi_msgs[1],{0xB1,0x63,0x7E}))
    assert(xLib.table_compare(midi_msgs[1],{0xB1,0x62,0x3F}))
    assert(xLib.table_compare(midi_msgs[1],{0xB1,0x06,0x0F}))
    assert(xLib.table_compare(midi_msgs[1],{0xB1,0x26,0x2F}))
  end
  x_input:input({0xB1,0x06,0x0F})
  -- simulate idle time to force the non-terminated message out
  x_input:on_idle()
  ]]

  -- 14bit NRPN (non-terminated)-----------------------------------------------
  -- check if     0xBX,0x63,0xYY  (X = Channel, Y = NRPN Number MSB)
  -- followed by  0xBX,0x62,0xYY  (X = Channel, Y = NRPN Number LSB)
  -- and          0xBX,0x06,0xYY  (X = Channel, Y = Data Entry MSB)
  -- and          0xBX,0x26,0xYY  (X = Channel, Y = Data Entry LSB)
  x_input.callback_fn = function(x_msg)
    error("got here NRPN")
  	assert(x_msg == nil)
  end
  x_input:input({0xB1,0x63,0x7E})
  x_input:input({0xB1,0x62,0x3F})
  x_input:input({0xB1,0x06,0x0F})
  x_input.callback_fn = function(x_msg)
    print("got here NRPN - non-terminated message")
    assert(x_msg.message_type == xMidiMessage.TYPE.NRPN)
    assert(x_msg.channel == 1)
    assert(x_msg.values[1] == 16191) 
    assert(x_msg.values[2] == 827)  -- 780 + 47
    local midi_msgs = x_msg:create_raw_message()
    assert(xLib.table_compare(midi_msgs[1],{0xB1,0x63,0x7E}))
    assert(xLib.table_compare(midi_msgs[1],{0xB1,0x62,0x3F}))
    assert(xLib.table_compare(midi_msgs[1],{0xB1,0x06,0x0F}))
    assert(xLib.table_compare(midi_msgs[1],{0xB1,0x26,0x2F}))
  end
  x_input:input({0xB1,0x26,0x2F})

  -- TODO simulate idle time to force the non-terminated message out
  x_input:on_idle()

  -- TODO test scenario where different ports submit messages
  --  (challenge: tell apart messages, only combine multibytes from same origin)

  -- 14bit NRPN (terminated) --------------------------------------------------
  -- check if     0xBX,0x63,0xYY  (X = Channel, Y = NRPN Number MSB)
  -- followed by  0xBX,0x62,0xYY  (X = Channel, Y = NRPN Number LSB)
  -- and          0xBX,0x06,0xYY  (X = Channel, Y = Data Entry MSB)
  -- and          0xBX,0x26,0xYY  (X = Channel, Y = Data Entry LSB)
  -- (terminate...)
  -- and          0xBX,0x65,0x7F  (X = Channel)
  -- and          0xBX,0x64,0x7F  (X = Channel)
  --[[
  x_input.callback_fn = function(x_msg)
    error("got here NRPN:terminated")
  	assert(x_msg == nil)
  end
  x_input:input({0xB1,0x63,0x7E})
  x_input:input({0xB1,0x62,0x3F})
  x_input:input({0xB1,0x06,0x0F})
  x_input:input({0xB1,0x26,0x2F})
  x_input:input({0xB1,0x65,0x7F})
  x_input.callback_fn = function(x_msg)
    print("got here NRPN - terminated message",x_msg)
    assert(x_msg.message_type == xMidiMessage.TYPE.NRPN)
    assert(x_msg.channel == 1)
    assert(x_msg.values[1] == 16191) 
    assert(x_msg.values[2] == 827)  -- 780 + 47
    local midi_msgs = x_msg:create_raw_message()
    assert(xLib.table_compare(midi_msgs[1],{0xB1,0x63,0x7E}))
    assert(xLib.table_compare(midi_msgs[1],{0xB1,0x62,0x3F}))
    assert(xLib.table_compare(midi_msgs[1],{0xB1,0x06,0x0F}))
    assert(xLib.table_compare(midi_msgs[1],{0xB1,0x26,0x2F}))
  end
  x_input:input({0xB1,0x64,0x7F})
  ]]


  -- TODO timed test CC#99 (0x63) which look like an NRPN but may well be a 
  -- normal CC message - this will be figured out once the message
  -- is picked up in the idle loop


  -- TODO process timed-out NRPN message without LSB part


  print(">>> xMidiInput: OK - passed all tests")

end