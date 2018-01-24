--[[===============================================================================================
  Testcase for xSelection
===============================================================================================]]--

_xlib_tests:insert({
  name = "xSelection",
  fn = function()
  
    LOG(">>> xSelection: starting unit-test...")
  
    require (_xlibroot.."xSelection")
    require (_xlibroot.."xPatternSequencer")
    _trace_filters = {"^xSelection"}
      
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

    local str_msg = "The xSelection test will modify the song - do you want to proceed?"
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

    seq_range = xSelection.get_entire_sequence()

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

    within = xSelection.within_sequence_range(seq_range,{sequence = 1,line = 16})
    assert(not within,tostring(within))

    within = xSelection.within_sequence_range(seq_range,{sequence = 1,line = 17})
    assert(within,tostring(within))

    within = xSelection.within_sequence_range(seq_range,{sequence = 2,line = 48})
    assert(within,tostring(within))
    
    within = xSelection.within_sequence_range(seq_range,{sequence = 2,line = 64})
    assert(not within,tostring(within))
    
    -- retrieve the line range from a specific sequence-index 
    from_line,to_line = xSelection.get_lines_in_range(seq_range,1)
    assert(from_line==17)
    assert(to_line==64)
    
    from_line,to_line = xSelection.get_lines_in_range(seq_range,2)
    assert(from_line==1)
    assert(to_line==48)
    

    -- TODO get the selection in the sequence 
    
    -- TODO check if given song-pos is within the selection 

    
  
    LOG(">>> xSelection: OK - passed all tests")
  
  end
  })
  