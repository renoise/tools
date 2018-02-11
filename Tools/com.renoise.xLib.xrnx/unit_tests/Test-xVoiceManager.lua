--[[ 

  Testcase for xVoiceManager

--]]


_xlib_tests:insert({
name = "xVoiceManager",
fn = function()

  LOG(">>> xVoiceManager: starting unit-test...")

  cLib.require (_xlibroot.."xVoiceManager")
  --require (_xlibroot.."xMessage")
  --require (_xlibroot.."xMidiMessage")
  --require (_xlibroot.."xTrack")
  _trace_filters = {"^xVoiceManager*"}


  local scheduled_fn = nil
  local scheduled_at = nil

  -----------------------------------------------------------------------------
  -- prepare
  -- make sure we have two instruments and two sequencer tracks

  local str_msg = "The xVoiceManager unit-test will create and remove instruments/tracks during the test - do you want to proceed?"
  local choice = renoise.app():show_prompt("Unit test",str_msg,{"OK","Cancel"})
  if (choice == "OK") then
    rns:insert_instrument_at(2)
    rns:insert_track_at(2)
  else
    return
  end

  local voicemgr = xVoiceManager()

  -----------------------------------------------------------------------------
  -- test steps (in reverse order)

  --[[
  local test_step_5 = function()
    LOG("test_step_5 - voices...",rprint(voicemgr.voices))
    assert(#voicemgr.voices==0,"Expected #voices to be 0")

    -- TODO test polyphonic limits
    -- (from now on, we should keep the most recent voices only)
    voicemgr.duration = 0
    voicemgr.voice_limit = 2

    local xmsg = xMidiMessage{
      message_type = xMidiMessage.TYPE.NOTE_ON,
      channel = 1,
      track_index = 2,
      instrument_index = 2,
      values = {0x60,0x7F},
    }
    local rslt,idx = voicemgr:input_message(xmsg)
    assert(#voicemgr.voices==1,"Expected #voices to be 1")

    local xmsg = xMidiMessage{
      message_type = xMidiMessage.TYPE.NOTE_ON,
      channel = 1,
      track_index = 2,
      instrument_index = 2,
      values = {0x62,0x7F},
    }
    local rslt,idx = voicemgr:input_message(xmsg)
    assert(#voicemgr.voices==2,"Expected #voices to be 2")

    local idx = voicemgr:get_voice_index(xmsg)
    assert(idx==2,"Expected idx to be 2")

    -- add message (should release oldest voice)
    local xmsg = xMidiMessage{
      message_type = xMidiMessage.TYPE.NOTE_ON,
      channel = 1,
      track_index = 2,
      instrument_index = 2,
      values = {0x64,0x7F},
    }
    local rslt,idx = voicemgr:input_message(xmsg)
    assert(#voicemgr.voices==2,"Expected #voices to be 2")

    local idx = voicemgr:get_voice_index(xmsg)
    assert(idx==2,"Expected idx to be 2")

    -- test for first message (should be gone)
    local xmsg = xMidiMessage{
      message_type = xMidiMessage.TYPE.NOTE_ON,
      channel = 1,
      track_index = 2,
      instrument_index = 2,
      values = {0x60,0x7F},
    }
    local idx = voicemgr:get_voice_index(xmsg)
    assert(idx==nil,"Expected idx to be nil")


    scheduled_fn = nil
    LOG(">>> xVoiceManager: OK - passed all tests")

  end
  ]]

  -- test column allocation
  local test_step_4 = function()
    LOG("test_step_4 - voices...",rprint(voicemgr.voices))

    -- release leftover voices
    voicemgr:release_all()
    assert(#voicemgr.voices==0,"Expected #voices to be 0")

    voicemgr.column_allocation = true

    -- trigger twice in same column, second will be raised
    local rslt,idx = voicemgr:input_message(xMidiMessage{
      message_type = xMidiMessage.TYPE.NOTE_ON,
      channel = 1,
      track_index = 1,
      instrument_index = 1,
      note_column_index = 1,
      values = {0x60,0x7F},
    })
    local rslt,idx = voicemgr:input_message(xMidiMessage{
      message_type = xMidiMessage.TYPE.NOTE_ON,
      channel = 1,
      track_index = 1,
      instrument_index = 2,
      note_column_index = 1,
      values = {0x60,0x7F},
    })
    assert(#voicemgr.voices==2,"Expected #voices to be 2")
    assert(voicemgr.voices[1].note_column_index==1,"Expected note_column_index to be 2")
    assert(voicemgr.voices[2].note_column_index==2,"Expected note_column_index to be 2")

    voicemgr:release_all()

    -- trigger twice in column 1 and 3, third should occupy 2
    local rslt,idx = voicemgr:input_message(xMidiMessage{
      message_type = xMidiMessage.TYPE.NOTE_ON,
      channel = 1,
      track_index = 1,
      instrument_index = 1,
      note_column_index = 1,
      values = {0x60,0x7F},
    })
    local rslt,idx = voicemgr:input_message(xMidiMessage{
      message_type = xMidiMessage.TYPE.NOTE_ON,
      channel = 1,
      track_index = 1,
      instrument_index = 2,
      note_column_index = 3,
      values = {0x60,0x7F},
    })
    local rslt,idx = voicemgr:input_message(xMidiMessage{
      message_type = xMidiMessage.TYPE.NOTE_ON,
      channel = 1,
      track_index = 1,
      instrument_index = 3,
      note_column_index = nil,
      values = {0x60,0x7F},
    })
    assert(#voicemgr.voices==3,"Expected #voices to be 3")
    assert(voicemgr.voices[1].note_column_index==1,"Expected note_column_index to be 2")
    assert(voicemgr.voices[2].note_column_index==3,"Expected note_column_index to be 3")
    assert(voicemgr.voices[3].note_column_index==2,"Expected note_column_index to be 2")

    voicemgr:release_all()

    -- trigger voices until we reach the last column
    -- (then, we will start dropping voices)
    voicemgr.voice_limit = 12
    for k = 1,14 do
      local rslt,idx = voicemgr:input_message(xMidiMessage{
        message_type = xMidiMessage.TYPE.NOTE_ON,
        channel = 1,
        track_index = 1,
        instrument_index = k,
        --note_column_index = 1,
        values = {0x60,0x7F},
      })
    end
    assert(#voicemgr.voices==12,"Expected #voices to be 12")

    voicemgr:release_all()

    scheduled_fn = nil
    LOG(">>> xVoiceManager: OK - passed all tests")

  end

  local test_step_3 = function()
    LOG("test_step_3 - voices...",rprint(voicemgr.voices))
    assert(#voicemgr.voices==1,"Expected #voices to be 1")

    -- release leftover voices
    voicemgr:release_all()

    -- TODO test duration (expiring voices)
    voicemgr.duration = 0 -- infinite

    -- input note: middle C, track #1, instr #1
    local xmsg = xMidiMessage{
      message_type = xMidiMessage.TYPE.NOTE_ON,
      channel = 1,
      track_index = 1,
      instrument_index = 1,
      values = {0x60,0x7F},
    }
    local rslt,idx = voicemgr:input_message(xmsg)
    assert(rslt,"Expected voice to be added")
    assert(idx==1,"Expected voice index to be 1")

    local xmsg = xMidiMessage{
      message_type = xMidiMessage.TYPE.NOTE_ON,
      channel = 2,
      track_index = 2,
      instrument_index = 2,
      values = {0x62,0x7F},
    }
    local rslt,idx = voicemgr:input_message(xmsg)
    assert(rslt,"Expected voice to be added")
    assert(idx==2,"Expected voice index to be 2")

    assert(#voicemgr.voices==2,"Expected #voices to be 2")

    voicemgr.duration = 1

    assert(#voicemgr.voices==2,"Expected #voices to be 2")

    scheduled_fn = test_step_4
    scheduled_at = os.clock() + 2

  end

  local test_step_2 = function()
    LOG("test_step_2 - voices...",rprint(voicemgr.voices))
    assert(#voicemgr.voices==2,"Expected #voices to be 2")

    -- TODO delete instr #2 while voice is playing
    -- (should release one voice)
    rns:delete_instrument_at(2)
    
    scheduled_fn = test_step_3

  end

  local test_step_1 = function()
    LOG("test_step_1 - voices...",rprint(voicemgr.voices))

    -- release leftover voices from previous tests (if any)
    voicemgr:release_all()

    -- check if empty
    assert(#voicemgr.voices==0,"Expected #voices to be 0")

    -- input note: middle C, track #1, instr #1
    local xmsg = xMidiMessage{
      message_type = xMidiMessage.TYPE.NOTE_ON,
      channel = 1,
      track_index = 1,
      instrument_index = 1,
      values = {0x60,0x7F},
    }
    local rslt,idx = voicemgr:input_message(xmsg)
    assert(rslt,"Expected voice to be added")
    assert(idx==1,"Expected voice index to be 1")

    -- trigger a note (middle C) similar to the first one
    -- (should be ignored)
    local rslt,idx = voicemgr:input_message(xmsg)
    --print("rslt,idx",rslt,idx)
    assert(not rslt,"Expected voice to be ignored")
    assert(idx==1,"Expected voice index to be 1")

    -- input another note, middle D, track #1, instr #1
    local xmsg = xMidiMessage{
      message_type = xMidiMessage.TYPE.NOTE_ON,
      channel = 1,
      track_index = 1,
      instrument_index = 1,
      values = {0x62,0x7F},
    }
    local rslt,idx = voicemgr:input_message(xmsg)
    --print("rslt,idx",rslt,idx)
    assert(rslt,"Expected voice to be added")
    assert(idx==2,"Expected voice index to be 2")

    -- input a third note, middle E, track #1, instr #1
    local xmsg = xMidiMessage{
      message_type = xMidiMessage.TYPE.NOTE_ON,
      channel = 1,
      track_index = 1,
      instrument_index = 1,
      values = {0x64,0x7F},
    }
    local rslt,idx = voicemgr:input_message(xmsg)
    --print("rslt,idx",rslt,idx)
    assert(rslt,"Expected voice to be added")
    assert(idx==3,"Expected voice index to be 3")

    -- get the voice index of the second note
    local xmsg = xMidiMessage{
      message_type = xMidiMessage.TYPE.NOTE_ON,
      channel = 1,
      track_index = 1,
      instrument_index = 1,
      values = {0x62,0x7F},
    }
    local idx = voicemgr:get_voice_index(xmsg)
    assert(idx==2,"Expected voice index to be 2")

    -- release the second note
    -- (two notes left)
    local xmsg = xMidiMessage{
      message_type = xMidiMessage.TYPE.NOTE_OFF,
      channel = 1,
      track_index = 1,
      instrument_index = 1,
      values = {0x62,0x7F},
    }
    local rslt,idx = voicemgr:input_message(xmsg)
    --print("rslt,idx",rslt,idx)
    --print("voices...",rprint(voicemgr.voices))
    assert(rslt,"Expected voice to be released")
    assert(idx==nil,"Expected voice index to be nil")

    assert(#voicemgr.voices==2,"Expected #voices to be 2")

    -- release the third note
    -- (one note left)
    local xmsg = xMidiMessage{
      message_type = xMidiMessage.TYPE.NOTE_OFF,
      channel = 1,
      track_index = 1,
      instrument_index = 1,
      values = {0x64,0x7F},
    }
    local rslt,idx = voicemgr:input_message(xmsg)
    assert(rslt,"Expected voice to be released")
    assert(idx==nil,"Expected voice index to be nil")

    assert(#voicemgr.voices==1,"Expected #voices to be 1")

    -- input a note, middle C, track #1, instr #2
    local xmsg = xMidiMessage{
      message_type = xMidiMessage.TYPE.NOTE_ON,
      channel = 1,
      track_index = 1,
      instrument_index = 2,
      values = {0x60,0x7F},
    }
    local rslt,idx = voicemgr:input_message(xmsg)
    assert(rslt,"Expected voice to be added")
    assert(idx==2,"Expected voice index to be 2")

    assert(#voicemgr.voices==2,"Expected #voices to be 2")

    -- input a note, middle C, track #1, instr #2
    -- (should be ignored)
    local xmsg = xMidiMessage{
      message_type = xMidiMessage.TYPE.NOTE_ON,
      channel = 1,
      track_index = 1,
      instrument_index = 2,
      values = {0x60,0x7F},
    }
    local rslt,idx = voicemgr:input_message(xmsg)
    assert(not rslt,"Expected voice to be ignored")
    assert(idx==2,"Expected voice index to be 2")

    -- input a note, middle C, track #2, instr #1
    local xmsg = xMidiMessage{
      message_type = xMidiMessage.TYPE.NOTE_ON,
      channel = 1,
      track_index = 2,
      instrument_index = 1,
      values = {0x60,0x7F},
    }
    local rslt,idx = voicemgr:input_message(xmsg)
    assert(rslt,"Expected voice to be added")
    assert(idx==3,"Expected voice index to be 3")

    -- input a note, middle C, track #2, instr #2
    local xmsg = xMidiMessage{
      message_type = xMidiMessage.TYPE.NOTE_ON,
      channel = 1,
      track_index = 2,
      instrument_index = 2,
      values = {0x60,0x7F},
    }
    local rslt,idx = voicemgr:input_message(xmsg)
    assert(rslt,"Expected voice to be added")
    assert(idx==4,"Expected voice index to be 4")

    -- delete track #2 while voice is playing
    -- (should release two voices)
    rns:delete_track_at(2)

    scheduled_fn = test_step_2

  end

  -----------------------------------------------------------------------------
  -- execute steps via idle notifier

  scheduled_fn = test_step_1

  renoise.tool().app_idle_observable:add_notifier(function()
    if scheduled_fn then
      if scheduled_at then
        if (os.clock() > scheduled_at) then
          scheduled_fn()
        end
      else  
        scheduled_fn()
      end
    end
  end)

end
})
