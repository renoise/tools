--[[===============================================================================================
  Testcase for xSequencerSelection
===============================================================================================]]--

_xlib_tests:insert({
  name = "xSequencerSelection",
  fn = function()
  
    LOG(">>> xSequencerSelection: starting unit-test...")
  
    cLib.require (_xlibroot.."xPatternSequencer")
    cLib.require (_xlibroot.."xSequencerSelection")
    _trace_filters = {
      "^xSequencerSelection*",
      "^xSequencerSelection*",
    }
      
    -----------------------------------------------------------------------------------------------
    -- prepare 
    -----------------------------------------------------------------------------------------------
    
    local prepare = function ()

      -- create two patterns 
      local patt1_idx = rns.sequencer:insert_new_pattern_at(1)
      local patt2_idx = rns.sequencer:insert_new_pattern_at(2)
      local patt1 = rns.patterns[patt1_idx]
      local patt2 = rns.patterns[patt2_idx]
      patt1.name = "xAudioDeviceAutomation test #1"
      patt2.name = "xAudioDeviceAutomation test #2"
      patt2.number_of_lines = 128
      
    end

    local str_msg = "The xSequencerSelection test will modify the song - do you want to proceed?"
    local choice = renoise.app():show_prompt("Unit test",str_msg,{"OK","Cancel"})
    if (choice == "OK") then
      prepare()
    else
      return
    end
      
    -----------------------------------------------------------------------------------------------
    -- run tests
    -----------------------------------------------------------------------------------------------

    local seq_range = nil
    local seq_count = #rns.sequencer.pattern_sequence
    local last_patt_idx = rns.sequencer.pattern_sequence[seq_count]
    local last_patt = xPatternSequencer.get_pattern_at_index(last_patt_idx)

    local within,from_line,to_line = nil,nil

    -- select entire sequence

    seq_range = xSequencerSelection.get_entire_range()

    assert(seq_range.start_sequence,1)
    assert(seq_range.start_line,1)
    assert(seq_range.end_sequence,#rns.sequencer.pattern_sequence)
    assert(seq_range.end_line,last_patt.number_of_lines)

    -- create a custom range 
    seq_range = {
      start_sequence = 1,
      start_line = 17,
      end_sequence = 2,
      end_line = 48,
    }
    
    -- check if given song-pos is within the selection 

    within = xSequencerSelection.within_range(seq_range,{sequence = 1,line = 16})
    assert(not within,tostring(within))

    within = xSequencerSelection.within_range(seq_range,{sequence = 1,line = 17})
    assert(within,tostring(within))

    within = xSequencerSelection.within_range(seq_range,{sequence = 2,line = 48})
    assert(within,tostring(within))
    
    within = xSequencerSelection.within_range(seq_range,{sequence = 2,line = 64})
    assert(not within,tostring(within))
    
    -- retrieve the line range from a specific sequence-index 
    from_line,to_line = xSequencerSelection.pluck_from_range (seq_range,1)
    assert(from_line==17)
    assert(to_line==64)
    
    from_line,to_line = xSequencerSelection.pluck_from_range (seq_range,2)
    assert(from_line==1)
    assert(to_line==48)
    

    -- TODO get the selection in the sequence 
    
    -- TODO check if given song-pos is within the selection 

    
  
    LOG(">>> xSequencerSelection: OK - passed all tests")
  
  end
  })
  