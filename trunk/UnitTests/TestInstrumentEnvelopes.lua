--[[--------------------------------------------------------------------------
TestInstrumentEnvelopes.lua
--------------------------------------------------------------------------]]--

do
  
  ----------------------------------------------------------------------------
  -- tools
  
  local function assert_error(statement)
    assert(pcall(statement) == false, "expected function error")
  end
  
  
  -- shortcuts
  
  local song = renoise.song()
  
  local instrument = song:insert_instrument_at(1)
  instrument.name = "Test Tone"
  
  local instrument2 = song:insert_instrument_at(2)
  instrument2.name = "Other Instrument"
  
  
    
  ----------------------------------------------------------------------------
  -- generate a new sample that we can apply some envelopes to
  
  local sample = instrument.samples[1]
  local sample_buffer = sample.sample_buffer
  local sample_rate = 44100
  local num_channels = 1
  local bit_depth = 32
  local num_frames = 168
  
  sample_buffer:create_sample_data(sample_rate, bit_depth, num_channels, num_frames)
  sample_buffer:prepare_sample_data_changes()
  for channel = 1, num_channels do
    local mid_point = (num_frames / 2)
    for frame = 1, mid_point do
      local s = frame / mid_point
      sample_buffer:set_sample_data(channel, frame, s)
      sample_buffer:set_sample_data(channel, frame + mid_point, s - 1)
    end
  end
  sample_buffer:finalize_sample_data_changes()
  sample.loop_mode = renoise.Sample.LOOP_MODE_FORWARD
  sample.loop_start = 1
  sample.loop_end = num_frames
  
  
  ----------------------------------------------------------------------------
  -- test envelopes
  
  local envelopes = instrument.sample_envelopes
  local volume = envelopes.volume
  local pan = envelopes.pan
  local pitch = envelopes.pitch
  local cutoff = envelopes.cutoff
  local resonance = envelopes.resonance
  
  envelopes.filter_type = renoise.InstrumentSampleEnvelopes.FILTER_MOOG_LP
  
  -- volume envelope
  
  volume.enabled = true
  volume.length = 24
  volume:clear_points()
  volume:add_point_at(1, 0.25)
  volume:add_point_at(3, 1.0)
  volume:add_point_at(6, 0.8)
  volume:add_point_at(12, 0.25)
  volume:add_point_at(24, 0.0)
  volume.sustain_enabled = true
  volume.sustain_position = 8
  volume.fade_amount = 256
  
  -- pan envelope
  
  pan.enabled = true
  pan.length = 48
  pan:clear_points()
  pan.play_mode = renoise.InstrumentEnvelope.PLAYMODE_LINEAR
  pan:add_point_at(1, 0.5)
  pan:add_point_at(13, 0.8)
  pan:add_point_at(25, 0.2)
  pan:add_point_at(37, 0.8)
  pan:add_point_at(48, 0.5)
  pan.loop_mode = renoise.InstrumentEnvelope.LOOP_MODE_FORWARD
  pan.loop_start = 13
  pan.loop_end = 37
  
  -- pitch
  
  pitch.enabled = true
  pitch.length = 25
  pitch.play_mode = renoise.InstrumentEnvelope.PLAYMODE_POINTS
  pitch:clear_points()
  pitch:add_point_at(1, 0.5)
  pitch:add_point_at(7, 0.5 + (0.5 / 12) * 3)
  pitch:add_point_at(13, 0.5 + (0.5 / 12) * 7)
  pitch:add_point_at(19, 1.0)
  pitch.loop_mode = renoise.InstrumentEnvelope.LOOP_MODE_FORWARD
  pitch.loop_start = 1
  pitch.loop_end = 25  
  pitch.lfo1.mode = renoise.InstrumentEnvelopeLfo.MODE_RANDOM
  pitch.lfo1.phase = 45
  pitch.lfo1.frequency = 30
  pitch.lfo1.amount = 5
  
  -- cutoff
  
  cutoff.enabled = true
  cutoff.length = 12
  cutoff:clear_points()
  cutoff:copy_points_from(volume)
  cutoff:add_point_at(9, 0.5)
  cutoff.sustain_enabled = true
  cutoff.sustain_position = 9
  cutoff.lfo.mode = renoise.InstrumentEnvelopeLfo.MODE_SIN
  cutoff.lfo.frequency = 30
  cutoff.lfo.amount = 15
  cutoff.follower.enabled = true
  cutoff.follower.attack = 32
  cutoff.follower.release = 64
  cutoff.follower.amount = 99
  
  -- resonance
  
  resonance:copy_from(cutoff)
  resonance.lfo:copy_from(pitch.lfo1)
  resonance:add_point_at(1, 0.0)


  ----------------------------------------------------------------------------
  -- test copy_from
  
  local envelopes2 = instrument2.sample_envelopes
  local volume2 = envelopes2.volume
  local pan2 = envelopes2.pan
  local pitch2 = envelopes2.pitch
  local cutoff2 = envelopes2.cutoff
  local resonance2 = envelopes2.resonance
  
  function test_points()
    assert(volume2.length == volume.length)
    assert(volume2.play_mode == volume.play_mode)
    for i = 1, #volume.points, 1 do
      assert(volume2.points[i].time == volume.points[i].time)
      assert(volume2.points[i].value == volume.points[i].value)
    end
  end
  
  function test_generic()
    assert(volume2.enabled == volume.enabled)
    assert(volume2.loop_mode == volume.loop_mode)
    assert(volume2.loop_start == volume.loop_start)
    assert(volume2.loop_end == volume.loop_end)
    assert(volume2.sustain_enabled == volume.sustain_enabled)
    assert(volume2.sustain_position == volume.sustain_position)
    assert(volume2.fade_amount == volume.fade_amount)
  end
    
  function test_mixer()
    assert(volume2.lfo1.mode == volume.lfo1.mode)
    assert(volume2.lfo1.phase == volume.lfo1.phase)
    assert(volume2.lfo1.frequency == volume.lfo1.frequency)
    assert(volume2.lfo1.amount == volume.lfo1.amount)
    assert(volume2.lfo2.mode == volume.lfo2.mode)
    assert(volume2.lfo2.phase == volume.lfo2.phase)
    assert(volume2.lfo2.frequency == volume.lfo2.frequency)
    assert(volume2.lfo2.amount == volume.lfo2.amount)
  end
  
  function test_filter() 
    assert(cutoff2.lfo.mode == cutoff.lfo.mode)
    assert(cutoff2.lfo.phase == cutoff.lfo.phase)
    assert(cutoff2.lfo.frequency == cutoff.lfo.frequency)
    assert(cutoff2.lfo.amount == cutoff.lfo.amount)
    assert(cutoff2.follower.enabled == cutoff.follower.enabled)
    assert(cutoff2.follower.attack == cutoff.follower.attack)
    assert(cutoff2.follower.release == cutoff.follower.release)
    assert(cutoff2.follower.amount == cutoff.follower.amount)
  end
  
  envelopes2:init()
  envelopes2:copy_from(envelopes)
  test_generic()
  test_points()
  test_mixer()
  test_filter()
  
  envelopes2:init()
  envelopes2.volume:copy_points_from(envelopes.volume)
  test_points()
  
  envelopes2:init()
  volume2:copy_from(volume)
  cutoff2:copy_from(cutoff)
  test_mixer()
  test_filter()
  
  envelopes2:init()
  volume2.lfo1:copy_from(volume.lfo1)
  volume2.lfo2:copy_from(volume.lfo2)
  cutoff2.lfo:copy_from(cutoff.lfo)
  cutoff2.follower:copy_from(cutoff.follower)
  test_mixer()
  test_filter()
  

  ----------------------------------------------------------------------------
  -- test errors
  
  assert_error(function()
    local bogus = envelopes.bogus
  end)
  
  assert_error(function()
    volume.length = 0
  end)
  
  assert_error(function()
    pitch.length = 1001
  end)
  
  assert_error(function()
    envelopes.filter_type = 666
  end)
  
  assert_error(function()
    volume.play_mode = 999
  end)
  
  assert_error(function()
    volume.fade_amount = 99999
  end)
  
  assert_error(function()
    volume.loop_mode = 999
  end)
  
  assert_error(function()
    volume.loop_start = 0
  end)
  
  assert_error(function()
    volume.loop_end = 9999
  end)
  
  assert_error(function()
    volume2:copy_from(cutoff)
  end)
  
  assert_error(function()
    resonance:copy_from(pitch2)
  end)

end


------------------------------------------------------------------------------
-- test finalizers

collectgarbage()


--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--
