--[[ 

  Testcase for 
    xSample
    xSampleBuffer
    xSampleBufferOperation
    xSampleMapping

--]]


_xlib_tests:insert({
  name = "xSample",
  fn = function()
  
    LOG(">>> xSample: starting unit-test...")
  
    cLib.require (_clibroot.."cWaveform")
    cLib.require (_xlibroot.."xSample")
    cLib.require (_xlibroot.."xSampleBuffer")
    cLib.require (_xlibroot.."xSampleBufferOperation")
    cLib.require (_xlibroot.."xSampleMapping")
    --_trace_filters = {"^xSample*"}
    
    local instr_idx = 1
    local instr = nil

    local sample_count = 0
    
    -----------------------------------------------------------------------------------------------
    -- ask for permission before running test 
    -----------------------------------------------------------------------------------------------
    
    local str_msg = "The xSample unit-test will create an instrument - do you want to proceed?"
    local choice = renoise.app():show_prompt("Create instrument",str_msg,{"OK","Cancel"})
    if (choice == "OK") then
      LOG("xSample: creating instrument...")
      instr = rns:insert_instrument_at(instr_idx)
      instr.name = "xSample test instrument"
    else
      LOG("xSample: aborted unit-test...")
    end
    
    -----------------------------------------------------------------------------------------------
    -- initialize 
    -----------------------------------------------------------------------------------------------
    
    -- create sample with buffer 
    
    sample_count = sample_count + 1
    local sample_idx = sample_count
    local sample = instr:insert_sample_at(sample_idx)
    sample.name = "Test sample"
        
    local sample_rate = 44100
    local bit_depth = 24
    local num_channels = 1
    local num_frames = 10000
    local buffer = sample.sample_buffer:create_sample_data(sample_rate,bit_depth,num_channels,num_frames)

    assert(type(xSample.get_sample_buffer(sample)) == "SampleBuffer")

    -- create "empty" sample without buffer, name etc. 
    
    sample_count = sample_count + 1
    local empty_sample_idx = sample_count
    local empty_sample = instr:insert_sample_at(empty_sample_idx)
    
    -----------------------------------------------------------------------------------------------
    -- xSampleMapping
    -----------------------------------------------------------------------------------------------
    
    -- newly created sample should have full note range 
    assert(xSampleMapping.has_full_note_range(sample.sample_mapping))
    
    assert(xSampleMapping.within_note_range(0,sample.sample_mapping))
    assert(xSampleMapping.within_note_range(119,sample.sample_mapping))
    assert(not xSampleMapping.within_note_range(120,sample.sample_mapping))
    assert(not xSampleMapping.within_note_range(-1,sample.sample_mapping))
    
    -----------------------------------------------------------------------------------------------
    -- xSampleBuffer/Operation
    -----------------------------------------------------------------------------------------------
    
    -- create basic waveforms 
    
    local sample_rate = 44100
    local bit_depth = 24
    local num_channels = 1
    local num_frames = 10000
    
    local mod_cycle = 1
    local mod_shift = 0
    local mod_duty_onoff 
    local mod_duty = 50
    local mod_duty_var = 0
    local mod_duty_var_frq = 1
    local band_limited = false
    
    -- sinewave 
    
    local sine_fn = cWaveform.wave_fn(cWaveform.FORM.SIN,
      mod_cycle,mod_shift,mod_duty_onoff,mod_duty,
      mod_duty_var,mod_duty_var_frq,band_limited,num_frames)
    
    sample_count = sample_count + 1 
    local sine_sample_idx = sample_count 
    local sine_sample = instr:insert_sample_at(sine_sample_idx)
    sine_sample.name = "Test (sine)"
        
    local buffer = sine_sample.sample_buffer:create_sample_data(sample_rate,bit_depth,num_channels,num_frames)
    
    xSampleBufferOperation.run({
      instrument_index = instr_idx,
      sample_index = sine_sample_idx,
      operations = {
        xSampleBuffer.create_wave_fn{
          buffer = sine_sample.sample_buffer,
          fn = sine_fn,
        },
      },
      on_complete = function(rslt)
        -- update reference (sample has been replaced)
        sine_sample = rslt.sample
      end 
    })
    
    -----------------------------------------------------------------------------------------------
    -- xSample
    -----------------------------------------------------------------------------------------------
    
    -- CONVERT
    
    -- copy sine_sample to next slot 
    sample_count = sample_count + 1 
    local sine_sample_copy_idx = sample_count
    local sine_sample_copy = instr:insert_sample_at(sine_sample_copy_idx)
    sine_sample_copy:copy_from(sine_sample)
    
    local convert_args = {
      bit_depth = 24,
      channel_action = xSample.SAMPLE_CONVERT.MONO_LEFT,
      --range = {start_frame=1,end_frame=5000}  
    }
    
    -- convert to 8 bit 
    convert_args.bit_depth = 8
    xSample.convert_sample(instr_idx,sine_sample_copy_idx,convert_args,function(rslt)
      print("convert to 8 bit done",rslt)
      sine_sample_copy = rslt
      assert(sine_sample_copy.sample_buffer.bit_depth == 8)
    end)
    
    -- scale up to 24 bit 
    convert_args.bit_depth = 24
    xSample.convert_sample(instr_idx,sine_sample_copy_idx,convert_args,function(rslt)
      print("scale up to 24 bit done",rslt)
      sine_sample_copy = rslt
      assert(sine_sample_copy.sample_buffer.bit_depth == 24)
      -- _actual_ bit depth should be 8
      assert(xSampleBuffer.get_bit_depth(sine_sample_copy.sample_buffer) == 8)
    end)

    
    -- LOOPING
    
    -- set_loop_pos (simple)
    
    xSample.set_loop_pos(sample,500,1500)
    assert(sample.loop_start == 500) 
    assert(sample.loop_end == 1500)

    xSample.set_loop_pos(sample,1000,2500)
    assert(sample.loop_start == 1000) 
    assert(sample.loop_end == 2500)

    xSample.set_loop_pos(sample,500,1500)
    assert(sample.loop_start == 500) 
    assert(sample.loop_end == 1500)

    xSample.set_loop_pos(sample,2000,2500)
    assert(sample.loop_start == 2000) 
    assert(sample.loop_end == 2500)

    xSample.set_loop_pos(sample,500,1000)
    assert(sample.loop_start == 500) 
    assert(sample.loop_end == 1000)
    
    -- clear_loop (set to full)
    xSample.clear_loop(sample)
    assert(sample.loop_start == 1) 
    assert(sample.loop_end == 10000)
    assert(sample.loop_mode == renoise.Sample.LOOP_MODE_OFF)

    -- set_loop_pos with out-of-range values 
    -- (should fit within range)
    
    xSample.set_loop_pos(sample,-5000,5000)
    assert(sample.loop_start == 1) 
    assert(sample.loop_end == 5000)

    xSample.set_loop_pos(sample,5000,15000)
    assert(sample.loop_start == 5000) 
    assert(sample.loop_end == 10000)
    
    -- set_loop_pos, flipped start/end 
    
    xSample.set_loop_pos(sample,5000,1)
    assert(sample.loop_start == 1)
    assert(sample.loop_end == 5000)
    
    -- set_loop_all/is_fully_looped
    
    xSample.set_loop_all(sample)
    assert(xSample.is_fully_looped(sample))
    
    xSample.set_loop_all(sample,renoise.Sample.LOOP_MODE_PING_PONG)
    assert(sample.loop_start == 1) 
    assert(sample.loop_end == 10000)
    assert(sample.loop_mode == renoise.Sample.LOOP_MODE_PING_PONG)
    
    -- NAMES
    
    assert(xSample.get_display_name(sample,sample_idx) == "Test sample")
    assert(xSample.get_display_name(empty_sample,empty_sample_idx) == "Sample 01")
    
    -- test with Renoise-generated names 
    -- (as they might result from rendering a plugin...)
    
    -- VST plugin, with underscores in name
    local tokens = xSample.get_name_tokens("VST: Synth1 VST (Honky Piano)_0x7F_C-5")
    assert(type(tokens)=="table")
    assert(tokens.plugin_name == "Synth1 VST")
    assert(tokens.preset_name == "Honky Piano")
    assert(tokens.velocity == "0x7F")
    assert(tokens.note == "C-5")
    
    -- VST plugin, without underscores in name
    tokens = xSample.get_name_tokens("VST: Synth1 VST (Honky Piano) 0x7F C-5")
    assert(type(tokens)=="table")
    assert(tokens.plugin_name == "Synth1 VST")
    assert(tokens.preset_name == "Honky Piano")
    assert(tokens.velocity == "0x7F")
    assert(tokens.note == "C-5")
    
    -- VST plugin, no note layer
    tokens = xSample.get_name_tokens("VST: Synth1 VST (Honky Piano)_0x7F")
    assert(type(tokens)=="table")
    assert(tokens.plugin_name == "Synth1 VST")
    assert(tokens.preset_name == "Honky Piano")
    assert(tokens.velocity == "0x7F")
    assert(tokens.note == nil)
      
    -- VST plugin, no velocity layer
    -- FIXME note is assigned to velocity 
    tokens = xSample.get_name_tokens("VST: Synth1 VST (Honky Piano)_C-5")
    assert(type(tokens)=="table")
    rprint(tokens)
    assert(tokens.plugin_name == "Synth1 VST")
    assert(tokens.preset_name == "Honky Piano")
    assert(tokens.velocity == nil)
    assert(tokens.note == "C-5")
    
    -- VST plugin, no note/velocity layer
    -- FIXME velocity is "", but note is nil
    tokens = xSample.get_name_tokens("VST: Synth1 VST (Honky Piano)")
    rprint(tokens)
    assert(type(tokens)=="table")
    assert(tokens.plugin_name == "Synth1 VST")
    assert(tokens.preset_name == "Honky Piano")
    assert(tokens.velocity == nil)
    assert(tokens.note == nil)
    
    
    
    -----------------------------------------------------------------------------------------------
    -- shut down 
    -----------------------------------------------------------------------------------------------

    -- remove test instrument 
    if instr then 
      rns:delete_instrument_at(instr_idx)
    end
  
  
    LOG(">>> xSample: OK - passed all tests")
  
  end
  })
  