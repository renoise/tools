--[[ 

  Testcase for xSongPos

--]]

_xlib_tests:insert({
name = "xSongPos",
fn = function()

  LOG(">>> xSongPos: starting unit-test...")

  cLib.require (_xlibroot.."xSongPos")
  _trace_filters = {"^xSongPos*"}

  local pattern_lengths = {
    64,1,44,   -- at start 
    512,12      -- at end 
  }
  

  local temp_pattern_count = 0
  
  local prep_pattern = function(patt)
    temp_pattern_count = temp_pattern_count + 1
    local patt_length = pattern_lengths[temp_pattern_count]
    local patt_name = string.format("xSongPos-test #%d (%d lines)",temp_pattern_count,patt_length)
    patt.name = patt_name
    patt.number_of_lines = patt_length
  end
  
  local remove_temp_patterns = function()
    for k,v in ripairs(rns.sequencer.pattern_sequence) do 
      local patt = xPatternSequencer.get_pattern_at_index(k)
      if cString.starts_with(patt.name,"xSongPos-test") then 
        rns.sequencer:delete_sequence_at(k)
      end
    end
  end
  
  local create_temp_patterns = function()    
    LOG("xSongPos: creating patterns...")
    
    remove_temp_patterns()
    
    local patt
    
    -- insert at start 
    rns.sequencer:insert_new_pattern_at(1)
    rns.sequencer:insert_new_pattern_at(1)
    rns.sequencer:insert_new_pattern_at(1)
    prep_pattern(xPatternSequencer.get_pattern_at_index(1))
    prep_pattern(xPatternSequencer.get_pattern_at_index(2))
    prep_pattern(xPatternSequencer.get_pattern_at_index(3))
    
    -- insert at end 
    rns.sequencer:insert_new_pattern_at(#rns.sequencer.pattern_sequence+1)
    rns.sequencer:insert_new_pattern_at(#rns.sequencer.pattern_sequence+1)
    prep_pattern(xPatternSequencer.get_pattern_at_index(#rns.sequencer.pattern_sequence-1))
    prep_pattern(xPatternSequencer.get_pattern_at_index(#rns.sequencer.pattern_sequence))
    
  end
  
  local get_first_pos = function()
    return {sequence=1,line=1}
  end  
  
  local get_total_lines = function()
    local total_lines = 0
    for k,v in ipairs(rns.sequencer.pattern_sequence) do 
      total_lines = total_lines + xPatternSequencer.get_number_of_lines(v)
    end
    return total_lines
  end

  local reset_transport = function()
    rns.transport.playing = false
    rns.transport.loop_pattern = false
    rns.transport.loop_sequence_range = {}
  end

  local str_msg = "The xSongPos unit-test requires temporary patterns to be"
    .."created during the test - do you want to proceed?"
  local choice = renoise.app():show_prompt("Create patterns",str_msg,{"OK","Cancel"})
  if (choice == "OK") then
    create_temp_patterns()
  else
    LOG("xSongPos: aborted unit-test...")
    return
  end
 
  local total_lines = get_total_lines()  
  local xpos, xpos_2, new_xpos, travelled, num_beats, sequence, line, done, args
  local last_xpos = xSongPos.get_last_line_in_song()
  
  reset_transport()
  
  -- START TESTS ----------------------------------------------------------------------------------
  
  -- comparison
  print(">>> comparison")
  
  xpos = {sequence=1,line=1}
  xpos_2 = {sequence=1,line=1}
  assert(xSongPos.equal(xpos,xpos_2),"expected xpos to be equal to xpos_2")
  assert(not xSongPos.less_than(xpos, xpos_2),"expected xpos to be *not* less than xpos_2")
  assert(not xSongPos.less_than(xpos_2,xpos),"expected xpos to be *not* less than xpos_2")
  assert(xSongPos.less_than_or_equal(xpos,xpos_2),"expected xpos to be less than or equal to xpos_2")
  assert(xSongPos.less_than_or_equal(xpos_2,xpos),"expected xpos_2 to be greater than or equal to xpos")

  xpos_2 = {sequence=2,line=1}
  assert(not xSongPos.equal(xpos,xpos_2),"expected pos to be not equal")
  assert(xSongPos.less_than(xpos,xpos_2),"expected xpos to be less than xpos_2")
  assert(not xSongPos.less_than(xpos_2,xpos),"expected xpos_2 to be greater than xpos")
  assert(xSongPos.less_than_or_equal(xpos,xpos_2),"expected xpos to be *not* greather than or equal to xpos_2")
  assert(not xSongPos.less_than_or_equal(xpos_2,xpos),"expected xpos to be les than or equal to xpos_2")

  -- create_from_beats
  
  args = {lines_per_beat = 4}
  
  new_xpos = xSongPos.create_from_beats(0,args)
  assert(new_xpos.sequence == 1,"expected new_xpos.sequence to be 1"..", was"..new_xpos.sequence)
  assert(new_xpos.line == 1,"expected new_xpos.line to be 1"..", was"..new_xpos.line)
  
  new_xpos = xSongPos.create_from_beats(1,args)
  assert(new_xpos.sequence == 1,"expected new_xpos.sequence to be 1"..", was"..new_xpos.sequence)
  assert(new_xpos.line == 5,"expected new_xpos.line to be 5"..", was"..new_xpos.line)
  
  new_xpos = xSongPos.create_from_beats(16,args)
  assert(new_xpos.sequence == 2,"expected new_xpos.sequence to be 2"..", was"..new_xpos.sequence)
  assert(new_xpos.line == 1,"expected new_xpos.line to be 1"..", was"..new_xpos.line)
  
  new_xpos = xSongPos.create_from_beats(-1,args)
  assert(new_xpos.sequence == 1,"expected new_xpos.sequence to be 1"..", was"..new_xpos.sequence)
  assert(new_xpos.line == -3,"expected new_xpos.line to be -3"..", was"..new_xpos.line)
  
  args = {lines_per_beat = 3}
  
  new_xpos = xSongPos.create_from_beats(0,args)
  assert(new_xpos.sequence == 1,"expected new_xpos.sequence to be 1"..", was"..new_xpos.sequence)
  assert(new_xpos.line == 1,"expected new_xpos.line to be 1"..", was"..new_xpos.line)
  
  new_xpos = xSongPos.create_from_beats(1,args)
  assert(new_xpos.sequence == 1,"expected new_xpos.sequence to be 1"..", was"..new_xpos.sequence)
  assert(new_xpos.line == 4,"expected new_xpos.line to be 4"..", was"..new_xpos.line)
  
  new_xpos = xSongPos.create_from_beats(21,args)
  assert(new_xpos.sequence == 1,"expected new_xpos.sequence to be 2"..", was"..new_xpos.sequence)
  assert(new_xpos.line == 64,"expected new_xpos.line to be 7"..", was"..new_xpos.line)
  
  -- get_number_of_beats
  
  args = {lines_per_beat = 4}
  
  num_beats = xSongPos.get_number_of_beats({sequence = 1, line = 1},args)
  assert(num_beats == 0,"expected num_beats to be 0"..", was"..num_beats)
  
  num_beats = xSongPos.get_number_of_beats({sequence = 1, line = 5},args)
  assert(num_beats == 1,"expected num_beats to be 1"..", was"..num_beats)

  num_beats = xSongPos.get_number_of_beats({sequence = 2, line = 1},args)
  assert(num_beats == 16,"expected num_beats to be 16"..", was"..num_beats)

  args = {lines_per_beat = 3}
  
  num_beats = xSongPos.get_number_of_beats({sequence = 1, line = 1},args)
  assert(num_beats == 0,"expected num_beats to be 0"..", was"..num_beats)
  
  num_beats = xSongPos.get_number_of_beats({sequence = 1, line = 4},args)
  assert(num_beats == 1,"expected num_beats to be 1"..", was"..num_beats)

  num_beats = xSongPos.get_number_of_beats({sequence = 1, line = 64},args)
  assert(num_beats == 21,"expected num_beats to be 21"..", was"..num_beats)
  
  -- within_bounds
  
  assert(xSongPos.within_bounds({sequence=1,line=1}))
  assert(xSongPos.within_bounds({sequence=last_xpos.sequence,line=last_xpos.line}))
  assert(not xSongPos.within_bounds({sequence=0,line=1}))
  assert(not xSongPos.within_bounds({sequence=1,line=0}))
  assert(not xSongPos.within_bounds({sequence=last_xpos.sequence,line=last_xpos.line+1}))
  assert(not xSongPos.within_bounds({sequence=last_xpos.sequence+1,line=last_xpos.line}))
  
  -- enforce_boundary
  
  xpos = {sequence=1,line=1}
  sequence,line,done = xSongPos.enforce_boundary("increase",xpos)
  assert(sequence == 1,sequence)
  assert(line == 1,line)
  assert(done == false)
  
  xpos = {sequence=last_xpos.sequence,line=last_xpos.line+1}
  sequence,line,done = xSongPos.enforce_boundary("increase",xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.CAP})
  assert(sequence == last_xpos.sequence,"expected sequence to be "..last_xpos.sequence)
  assert(line == last_xpos.line,"expected line to be "..last_xpos.line)
  assert(done == true)
  
  xpos = {sequence=last_xpos.sequence,line=last_xpos.line+1}
  sequence,line,done = xSongPos.enforce_boundary("increase",xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.ALLOW})
  assert(sequence == last_xpos.sequence,"expected sequence to be "..last_xpos.sequence)
  assert(line == nil,"expected line to be nil")
  assert(done == true)
  
  sequence,line,done = xSongPos.enforce_boundary("increase",xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.NULL})
  assert(sequence == nil,"expected sequence to be nil")
  assert(line == nil,"expected line to be nil")
  assert(done == true)
  
  xpos = last_xpos
  sequence,line,done = xSongPos.enforce_boundary("decrease",xpos)
  print("sequence,line,done",sequence,line,done)
  assert(sequence == last_xpos.sequence,"expected sequence to be "..last_xpos.sequence)
  assert(line == last_xpos.line,"expected line to be "..last_xpos.line)
  assert(done == false)
  
  xpos = {sequence=0,line=16}
  sequence,line,done = xSongPos.enforce_boundary("decrease",xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.CAP})
  assert(sequence == 1,"expected sequence to be 1")
  assert(line == 1,"expected line to be 1")
  assert(done == true)
  
  sequence,line,done = xSongPos.enforce_boundary("decrease",xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.ALLOW})
  assert(sequence == 1,"expected sequence to be 1")
  assert(line == nil,"expected line to be nil")
  assert(done == true)
  
  sequence,line,done = xSongPos.enforce_boundary("decrease",xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.NULL})
  assert(sequence == nil,"expected sequence to be nil")
  assert(line == nil,"expected line to be nil")
  assert(done == true)
  
  -- enforce_boundary with LOOP_BOUNDARY
  args = {
    loop_sequence_range = {1,3},
    loop_boundary = xSongPos.LOOP_BOUNDARY.HARD
  }
  
  xpos = {sequence = 3,line = pattern_lengths[3]}
  sequence,line,done = xSongPos.enforce_boundary("increase",xpos,args)
  assert(sequence == 3,"expected sequence to be 3, was "..sequence)
  assert(line == pattern_lengths[3],"expected line to be "..pattern_lengths[3])
  assert(done == false)

  xpos = {sequence = 4,line = pattern_lengths[3]}
  sequence,line,done = xSongPos.enforce_boundary("increase",xpos,args)
  assert(sequence == 1,"expected sequence to be 1, was "..sequence)
  assert(line == pattern_lengths[3],"expected line to be "..pattern_lengths[3]..", was "..line)
  assert(done == false)

  xpos = {sequence = 4,line = pattern_lengths[3]}
  sequence,line,done = xSongPos.enforce_boundary("decrease",xpos,args)
  assert(sequence == 3,"expected sequence to be 3, was "..sequence)
  assert(line == pattern_lengths[3],"expected line to be "..pattern_lengths[3]..", was "..line)
  assert(done == false)

  
  reset_transport()
  
  -- increase (lines)
  print(">>> increase (lines) -------------------------------------------------------------------")

  xpos = {sequence=1,line=1}
  
  assert((xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((xpos.line==1),"expected new_xpos.line to be 1")

  new_xpos = xSongPos.increase_by_lines(1,xpos)
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1"..", was"..new_xpos.sequence)
  assert((new_xpos.line==2),"expected new_xpos.line to be 2"..", was"..new_xpos.line)

  new_xpos = xSongPos.increase_by_lines(pattern_lengths[1],xpos)
  assert((new_xpos.sequence==2),"expected new_xpos.sequence to be 2"..", was"..new_xpos.sequence)
  assert((new_xpos.line==1),"expected new_xpos.line to be 1"..", was"..new_xpos.line)

  new_xpos = xSongPos.increase_by_lines(total_lines-1,xpos)
  assert((new_xpos.sequence==last_xpos.sequence),"expected new_xpos.sequence to be "..last_xpos.sequence..", was"..new_xpos.sequence)
  assert((new_xpos.line==last_xpos.line),"expected new_xpos.line to be "..last_xpos.line..", was"..new_xpos.line)

  -- don't do anything 
  new_xpos = xSongPos.increase_by_lines(0,xpos)
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line==1),"expected new_xpos.line to be 1")
    
  xpos = {sequence=1,line=pattern_lengths[1]}
  
  assert((xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((xpos.line==pattern_lengths[1]),("expected new_xpos.line to be %d"):format(pattern_lengths[1]))
  
  -- work on same position 
  new_xpos = xSongPos.increase_by_lines(1,xpos)
  assert((new_xpos.sequence==2),"expected new_xpos.sequence to be 2")
  assert((new_xpos.line==1),"expected new_xpos.line to be 1")

  new_xpos = xSongPos.increase_by_lines(1,new_xpos)
  assert((new_xpos.sequence==3),"expected new_xpos.sequence to be 3")
  assert((new_xpos.line==1),"expected new_xpos.line to be 1")

  new_xpos = xSongPos.increase_by_lines(1,new_xpos)
  assert((new_xpos.sequence==3),"expected new_xpos.sequence to be 3")
  assert((new_xpos.line==2),"expected new_xpos.line to be 2")

  -- test OUT_OF_BOUNDS
  
  new_xpos = xSongPos.increase_by_lines(1,last_xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP})
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1:"..xpos.sequence)
  assert((new_xpos.line==1),"expected new_xpos.line to be 1:"..xpos.line)
  
  print(">>> got here A")
  
  new_xpos = xSongPos.increase_by_lines(total_lines,last_xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP})
  assert((new_xpos.sequence==last_xpos.sequence),"expected new_xpos.sequence to be "..last_xpos.sequence)
  assert((new_xpos.line==last_xpos.line),"expected new_xpos.line to be "..last_xpos.line)
  
  print(">>> got here B")
  
  new_xpos = xSongPos.increase_by_lines(1,last_xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.ALLOW})
  assert((new_xpos.sequence == last_xpos.sequence),"expected new_xpos.sequence to be "..last_xpos.sequence..", was "..new_xpos.sequence)
  assert((new_xpos.line == last_xpos.line+1),"expected new_xpos.line to be "..(last_xpos.line+1)..", was"..new_xpos.line)
  
  print(">>> got here C")
  
  new_xpos = xSongPos.increase_by_lines(1,last_xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.CAP})
  assert(new_xpos.sequence == last_xpos.sequence,"expected new_xpos.sequence to be "..last_xpos.sequence)
  assert(new_xpos.line == last_xpos.line,"expected new_xpos.sequence to be "..last_xpos.line)
  
  print(">>> got here D")
  
  new_xpos = xSongPos.increase_by_lines(1,last_xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.NULL})
  assert((type(new_xpos) == "nil"),"expected new_xpos to be nil")
  
  print(">>> got here E")
  
  -- check increase_by_lines with LOOP_BOUNDARY
  
  xpos = {sequence=3,line=pattern_lengths[3]}
  args = {
    loop_boundary = xSongPos.LOOP_BOUNDARY.HARD,
    loop_sequence_range = {1,3}
  }
  
  new_xpos = xSongPos.increase_by_lines(16,xpos,args)
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1"..", was"..new_xpos.sequence)
  assert((new_xpos.line==16),"expected new_xpos.line to be 16"..", was"..new_xpos.line)
  
  new_xpos = xSongPos.increase_by_lines(65,xpos,args)
  assert((new_xpos.sequence==2),"expected new_xpos.sequence to be 2"..", was"..new_xpos.sequence)
  assert((new_xpos.line==1),"expected new_xpos.line to be 1"..", was"..new_xpos.line)
  
  
  -- TODO check next_beat with BLOCK_BOUNDARY

  
  -- next/previous (beat)
  print(">>> increase (beat)")

  args = {
    lines_per_beat = 4,
    beats_per_bar = 4,
  }
  
  xpos = {sequence=1,line=0}
  assert((xpos.sequence==1),"expected sequence to be 1")
  assert((xpos.line==0),"expected line to be 0")

  new_xpos,travelled = xSongPos.next_beat(xpos,args)
  assert((travelled == 1),"expected travelled to be 4")
  assert((new_xpos.sequence == 1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line == 1),"expected new_xpos.line to be 1")

  xpos = {sequence=1,line=1}
  new_xpos,travelled = xSongPos.next_beat(xpos,args)
  assert((travelled == 4),"expected travelled to be 4")
  assert((new_xpos.sequence == 1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line == 5),"expected new_xpos.line to be 5")

  xpos = {sequence=1,line=2}
  new_xpos,travelled = xSongPos.next_beat(xpos,args)
  assert((travelled == 3),"expected travelled to be 3")
  assert((new_xpos.sequence == 1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line == 5),"expected new_xpos.line to be 5")

  xpos = {sequence=1,line=3}
  new_xpos,travelled = xSongPos.next_beat(xpos,args)
  assert((travelled == 2),"expected travelled to be 2")
  assert((new_xpos.sequence == 1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line == 5),"expected new_xpos.line to be 5")
  
  xpos = {sequence=1,line=4}
  new_xpos,travelled = xSongPos.next_beat(xpos,args)
  assert((travelled == 1),"expected travelled to be 1")
  assert((new_xpos.sequence == 1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line == 5),"expected new_xpos.line to be 5")
  
  xpos = {sequence=1,line=5}
  new_xpos,travelled = xSongPos.next_beat(xpos,args)
  assert((travelled == 4),"expected travelled to be 4")
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line==9),"expected new_xpos.line to be 9")
  
  xpos = {sequence=1,line=61}
  new_xpos,travelled = xSongPos.next_beat(xpos,args)
  assert((travelled == 4),"expected travelled to be 4")
  assert((new_xpos.sequence==2),"expected new_xpos.sequence to be 2")
  assert((new_xpos.line==1),"expected new_xpos.line to be 1")
  
  -- TODO check next_beat with OUT_OF_BOUNDS
  -- TODO check next_beat with LOOP_BOUNDARY
  -- TODO check next_beat with BLOCK_BOUNDARY

  -- increase (bar)
  print(">>> increase (bar)")

  args = {
    lines_per_beat = 4,
    beats_per_bar = 4,
  }

  xpos = {sequence=1,line=0}
  assert((xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((xpos.line==0),"expected new_xpos.line to be 0")

  new_xpos,travelled = xSongPos.next_bar(xpos,args)
  assert((travelled == 1),"expected travelled to be 1: "..travelled)
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1: "..new_xpos.sequence)
  assert((new_xpos.line==1),"expected new_xpos.line to be 1: "..new_xpos.line)

  xpos = {sequence=1,line=1}
  new_xpos,travelled = xSongPos.next_bar(xpos,args)
  assert((travelled == 16),"expected travelled to be 16: "..travelled)
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line==17),"expected new_xpos.line to be 17")

  xpos = {sequence=1,line=9}
  new_xpos,travelled = xSongPos.next_bar(xpos,args)
  assert((travelled == 8),"expected travelled to be 8: "..travelled)
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line==17),"expected new_xpos.line to be 17")

  xpos = {sequence=1,line=17}
  new_xpos,travelled = xSongPos.next_bar(xpos,args)
  assert((travelled == 16),"expected travelled to be 16: "..travelled)
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line==33),"expected new_xpos.line to be 33")

  xpos = {sequence=1,line=33}
  new_xpos,travelled = xSongPos.next_bar(xpos,args)
  assert((travelled == 16),"expected travelled to be 16: "..travelled)
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line==49),"expected new_xpos.line to be 49")

  xpos = {sequence=1,line=63}
  new_xpos,travelled = xSongPos.next_bar(xpos,args)
  assert((travelled == 2),"expected travelled to be 2: "..travelled)
  assert((new_xpos.sequence==2),"expected new_xpos.sequence to be 2")
  assert((new_xpos.line==1),"expected new_xpos.line to be 1")

  xpos = {sequence=1,line=1}
  assert((xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((xpos.line==1),"expected new_xpos.line to be 1")
  
  new_xpos,travelled = xSongPos.next_bar(xpos,args)
  assert((travelled == 16),"expected travelled to be 16: "..travelled)
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line==17),"expected new_xpos.ine to be 17")

  xpos = {sequence=1,line=16}
  new_xpos,travelled = xSongPos.next_bar(xpos,args)
  assert((travelled == 1),"expected travelled to be 1: "..travelled)
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line==17),"expected new_xpos.line to be 17")

  xpos = {sequence=1,line=17}
  new_xpos,travelled = xSongPos.next_bar(xpos,args)
  assert((travelled == 16),"expected travelled to be 16: "..travelled)
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line==33),"expected new_xpos.line to be 33")

  xpos = {sequence=1,line=64}
  new_xpos,travelled = xSongPos.next_bar(xpos,args)
  assert((travelled == 1),"expected travelled to be 1: "..travelled)
  assert((new_xpos.sequence==2),"expected new_xpos.sequence to be 2")
  assert((new_xpos.line==1),"expected new_xpos.line to be 1")

  args = {
    lines_per_beat = 4,
    beats_per_bar = 3,
  }

  xpos = {sequence=1,line=0}
  assert((xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((xpos.line==0),"expected new_xpos.line to be 0")

  new_xpos,travelled = xSongPos.next_bar(xpos,args)
  assert((travelled == 1),"expected travelled to be 1: "..travelled)
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line==1),"expected new_xpos.line to be 1")

  xpos = {sequence=1,line=1}
  new_xpos,travelled = xSongPos.next_bar(xpos,args)
  assert((travelled == 12),"expected travelled to be 12: "..travelled)
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line==13),"expected new_xpos.line to be 13")
  
  args.bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP
  new_xpos,travelled = xSongPos.next_bar(last_xpos,args)
  assert((travelled == 1),"expected travelled to be 1: "..travelled)
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line==1),"expected new_xpos.line to be 1")
  
  args.bounds_mode = xSongPos.OUT_OF_BOUNDS.CAP
  new_xpos,travelled = xSongPos.next_bar(last_xpos,args)
  assert((travelled == 0),"expected travelled to be 0: "..travelled)
  assert((new_xpos.sequence==last_xpos.sequence),"expected new_xpos.sequence to be "..last_xpos.sequence)
  assert((new_xpos.line==last_xpos.line),"expected new_xpos.line to be "..last_xpos.line)
  
  args.bounds_mode = xSongPos.OUT_OF_BOUNDS.NULL
  new_xpos,travelled = xSongPos.next_bar(last_xpos,args)
  assert(type(travelled) == "nil","expected travelled to be nil")
  assert(type(new_xpos) == "nil","expected new_xpos to be nil")
  
  -- increase (block)
  print(">>> increase (block)")

  xpos = {sequence=1,line=0}
  assert((xpos.sequence==1),"expected sequence to be 1")
  assert((xpos.line==0),"expected line to be 0")

  new_xpos,travelled = xSongPos.next_block(xpos)
  assert((travelled == 1),"expected travelled to be 1: "..travelled)
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line==1),"expected new_xpos.line to be 1")
  assert((xpos.sequence == 1),"expected xpos.sequence to be 1:"..xpos.sequence)
  assert((xpos.line == 0),"expected xpos.line to be 0:"..xpos.line)

  new_xpos,travelled = xSongPos.next_block(new_xpos)
  assert((travelled == 16),"expected travelled to be 16: "..travelled)
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line==17),"expected new_xpos.line to be 17")
  
  xpos = {sequence=1,line=64}
  new_xpos,travelled = xSongPos.next_block(xpos)
  assert((travelled == 1),"expected travelled to be 1: "..travelled)
  assert((new_xpos.sequence==2),"expected new_xpos.sequence to be 2")
  assert((new_xpos.line==1),"expected new_xpos.line to be 1")

  new_xpos,travelled = xSongPos.next_block(last_xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP})
  assert((travelled == 1),"expected travelled to be 1: "..travelled)
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line==1),"expected new_xpos.line to be 1")
  
  new_xpos,travelled = xSongPos.next_block(last_xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.CAP})
  assert((travelled == 0),"expected travelled to be 0: "..travelled)
  assert((new_xpos.sequence==last_xpos.sequence),"expected new_xpos.sequence to be "..last_xpos.sequence)
  assert((new_xpos.line==last_xpos.line),"expected new_xpos.line to be "..last_xpos.line)
  
  new_xpos,travelled = xSongPos.next_block(last_xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.NULL})
  assert(type(travelled) == "nil","expected travelled to be nil")
  assert(type(new_xpos) == "nil","expected new_xpos to be nil")
  
  -- TODO test spanning pattern with different sizes 
  -- 
  
  -- increase (pattern)
  print(">>> increase (block)")

  xpos = {sequence=1,line=0}
  assert((xpos.sequence==1),"expected sequence to be 1")
  assert((xpos.line==0),"expected line to be 0")

  new_xpos,travelled = xSongPos.next_pattern(xpos)
  assert((travelled == pattern_lengths[1]+1),"expected travelled to be "..(pattern_lengths[1]+1)..","..travelled)
  assert((new_xpos.sequence==2),"expected new_xpos.sequence to be 2")
  assert((new_xpos.line==1),"expected new_xpos.line to be 1")
  assert((xpos.sequence == 1),"expected xpos.sequence to be 1:"..xpos.sequence)
  assert((xpos.line == 0),"expected xpos.line to be 0:"..xpos.line)

  new_xpos,travelled = xSongPos.next_pattern(new_xpos)
  assert((travelled == pattern_lengths[2]),"expected travelled to be "..pattern_lengths[2]..","..travelled)
  assert((new_xpos.sequence==3),"expected new_xpos.sequence to be 3")
  assert((new_xpos.line==1),"expected new_xpos.line to be 1")

  new_xpos,travelled = xSongPos.next_pattern(last_xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.CAP})
  assert((travelled == 0),"expected travelled to be 0"..travelled)
  assert((new_xpos.sequence==last_xpos.sequence),"expected new_xpos.sequence to be 3:"..last_xpos.sequence)
  assert((new_xpos.line==last_xpos.line),"expected new_xpos.line to be 64:"..last_xpos.line)
  
  new_xpos,travelled = xSongPos.next_pattern(last_xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.ALLOW})
  assert((travelled == 1),"expected travelled to be 1:"..travelled)
  assert((new_xpos.sequence==last_xpos.sequence),"expected new_xpos.sequence to be "..last_xpos.sequence)
  assert((new_xpos.line==last_xpos.line+1),"expected new_xpos.line to be "..last_xpos.line+1)
  
  new_xpos,travelled = xSongPos.next_pattern(last_xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP})
  assert((travelled == 1),"expected travelled to be 1"..travelled)
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1:"..xpos.sequence)
  assert((new_xpos.line==1),"expected new_xpos.line to be 1:"..xpos.line)

  new_xpos,travelled = xSongPos.next_pattern(last_xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.NULL})
  assert(type(travelled) == "nil","expected travelled to be nil")
  assert(type(new_xpos) == "nil","expected new_xpos to be nil")

  -- decrease (lines)
  print(">>> decrease (lines)")

  xpos = {sequence=3,line=2}
  assert((xpos.sequence==3),"expected new_xpos.sequence to be 3")
  assert((xpos.line==2),"expected new_xpos.line to be 2")

  new_xpos = xSongPos.decrease_by_lines(pattern_lengths[2]+pattern_lengths[1],xpos)
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line==2),"expected new_xpos.line to be 2")

  new_xpos = xSongPos.decrease_by_lines(1,new_xpos)
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line==1),"expected new_xpos.line to be 1")

  new_xpos = xSongPos.decrease_by_lines(0,xpos)
  assert((new_xpos.sequence==3),"expected new_xpos.sequence to be 3")
  assert((new_xpos.line==2),"expected new_xpos.line to be 2")
  
  xpos = {sequence=1,line=1}
  new_xpos = xSongPos.decrease_by_lines(pattern_lengths[1],xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.CAP})
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line==1),"expected new_xpos.line to be 1")
  assert((xpos.sequence == 1),"expected xpos.sequence to be 1:"..xpos.sequence)
  assert((xpos.line == 1),"expected xpos.line to be 1:"..xpos.line)

  new_xpos = xSongPos.decrease_by_lines(1,xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP})
  assert((new_xpos.sequence==last_xpos.sequence),("expected new_xpos.sequence to be %d"):format(last_xpos.sequence))
  assert((new_xpos.line==last_xpos.line),("expected new_xpos.line to be %d"):format(last_xpos.line))
  assert((xpos.sequence == 1),"expected xpos.sequence to be 1:"..xpos.sequence)
  assert((xpos.line == 1),"expected xpos.line to be 1:"..xpos.line)

  new_xpos = xSongPos.decrease_by_lines(16,xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.ALLOW})
  assert((new_xpos.sequence == 1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line == -15),"expected new_xpos.line to be -15")

  new_xpos = xSongPos.decrease_by_lines(total_lines,xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.NULL})
  assert(type(new_xpos) == "nil","expected new_xpos to be nil")
  assert((xpos.sequence == 1),"expected xpos.sequence to be 1:"..xpos.sequence)
  assert((xpos.line == 1),"expected xpos.line to be 1:"..xpos.line)

  print(">>> previous_beat")
  
  args = {
    lines_per_beat = 4,
    beats_per_bar = 4,    
  }
  
  xpos = {sequence = 1, line = pattern_lengths[1]}
  new_xpos,travelled = xSongPos.previous_beat(xpos,args)
  assert((travelled == 3),"expected travelled to be 3:"..travelled)
  assert((new_xpos.sequence == 1),"expected new_xpos.sequence to be 1:"..new_xpos.sequence)
  assert((new_xpos.line == 61),"expected new_xpos.line to be 61:"..new_xpos.line)

  xpos = {sequence = 2, line = 1}
  new_xpos,travelled = xSongPos.previous_beat(xpos,args)
  assert((travelled == 4),"expected travelled to be 4:"..travelled)
  assert((new_xpos.sequence == 1),"expected new_xpos.sequence to be 1:"..new_xpos.sequence)
  assert((new_xpos.line == 61),"expected new_xpos.line to be 61:"..new_xpos.line)
  assert((xpos.sequence == 2),"expected xpos.sequence to be 2:"..xpos.sequence)
  assert((xpos.line == 1),"expected xpos.line to be 1:"..xpos.line)

  xpos = {sequence = 1, line = 1}
  args.bounds_mode = xSongPos.OUT_OF_BOUNDS.CAP
  new_xpos,travelled = xSongPos.previous_beat(xpos,args)
  assert((travelled == 0),"expected travelled to be 0:"..travelled)
  assert((new_xpos.sequence == 1),"expected new_xpos.sequence to be 1:"..new_xpos.sequence)
  assert((new_xpos.line == 1),"expected new_xpos.line to be 1:"..new_xpos.line)
  assert((xpos.sequence == 1),"expected xpos.sequence to be 1:"..xpos.sequence)
  assert((xpos.line == 1),"expected xpos.line to be 1:"..xpos.line)

  -- note: can't assert travelled & line, since only the 
  -- first & last patterns are known to the unit test
  args.bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP
  new_xpos,travelled = xSongPos.previous_beat(xpos,args)
  assert(type(travelled) == "number","expected travelled to be a number")
  assert((new_xpos.sequence == last_xpos.sequence),"expected new_xpos.sequence to be "..last_xpos.sequence)
  --assert((new_xpos.line == 1),"expected line to be 1:"..last_xpos.line - rns.transport.lpb)
  assert((xpos.sequence == 1),"expected xpos.sequence to be 1:"..xpos.sequence)
  assert((xpos.line == 1),"expected xpos.line to be 1:"..xpos.line)

  args.bounds_mode = xSongPos.OUT_OF_BOUNDS.ALLOW
  new_xpos,travelled = xSongPos.previous_beat(xpos,args)
  assert((travelled == 4),"expected travelled to be 4:"..travelled)
  assert((new_xpos.sequence == 1),"expected new_xpos.sequence to be 1:"..new_xpos.sequence)
  assert((new_xpos.line == -3),"expected new_xpos.line to be -3:"..new_xpos.line)
  assert((xpos.sequence == 1),"expected xpos.sequence to be 1:"..xpos.sequence)
  assert((xpos.line == 1),"expected xpos.line to be 1:"..xpos.line)

  args.bounds_mode = xSongPos.OUT_OF_BOUNDS.NULL
  new_xpos,travelled = xSongPos.previous_beat(xpos,args)
  assert(type(travelled) == "nil","expected travelled to be nil")
  assert(type(new_xpos) == "nil","expected new_xpos to be nil")
  assert((xpos.sequence == 1),"expected xpos.sequence to be 1:"..xpos.sequence)
  assert((xpos.line == 1),"expected xpos.line to be 1:"..xpos.line)

  -- previous_bar
  args = {
    lines_per_beat = 4,
    beats_per_bar = 4,    
  }

  xpos = {sequence = 1, line = pattern_lengths[1]}
  new_xpos,travelled = xSongPos.previous_bar(xpos,args)
  assert((travelled == 15),"expected travelled to be 15:"..travelled)
  assert((new_xpos.sequence == 1),"expected new_xpos.sequence to be 1:"..new_xpos.sequence)
  assert((new_xpos.line == 49),"expected new_xpos.line to be 49:"..new_xpos.line)
  assert((xpos.sequence == 1),"expected xpos.sequence to be 1:"..xpos.sequence)
  assert((xpos.line == pattern_lengths[1]),"expected xpos.line to be :"..pattern_lengths[1]..","..xpos.line)

  new_xpos,travelled = xSongPos.previous_bar(new_xpos,args)
  assert((travelled == 16),"expected travelled to be 16:"..travelled)
  assert((new_xpos.sequence == 1),"expected new_xpos.sequence to be 1:"..new_xpos.sequence)
  assert((new_xpos.line == 33),"expected new_xpos.line to be 33:"..new_xpos.line)

  xpos = {sequence = 2, line = 1}
  new_xpos,travelled = xSongPos.previous_bar(xpos,args)
  assert((travelled == 16),"expected travelled to be 16:"..travelled)
  assert((new_xpos.sequence == 1),"expected new_xpos.sequence to be 1:"..new_xpos.sequence)
  assert((new_xpos.line == 49),"expected new_xpos.line to be 49:"..new_xpos.line)
  assert((xpos.sequence == 2),"expected xpos.sequence to be 2:"..xpos.sequence)
  assert((xpos.line == 1),"expected xpos.line to be 1:"..xpos.line)

  xpos = {sequence = 1, line = 1}
  args.bounds_mode = xSongPos.OUT_OF_BOUNDS.CAP
  new_xpos,travelled = xSongPos.previous_bar(xpos,args)
  assert((travelled == 0),"expected travelled to be 0:"..travelled)
  assert((new_xpos.sequence == 1),"expected new_xpos.sequence to be 1:"..new_xpos.sequence)
  assert((new_xpos.line == 1),"expected new_xpos.line to be 1:"..new_xpos.line)
  assert((xpos.sequence == 1),"expected xpos.sequence to be 1:"..xpos.sequence)
  assert((xpos.line == 1),"expected xpos.line to be 1:"..xpos.line)

  args.bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP
  new_xpos,travelled = xSongPos.previous_bar(xpos,args)
  assert(type(travelled) == "number","expected travelled to be a number")
  assert((new_xpos.sequence == last_xpos.sequence),"expected sequence to be "..last_xpos.sequence)
  --assert((new_xpos.line == 1),"expected line to be 1:"..new_xpos.line)
  assert((xpos.sequence == 1),"expected xpos.sequence to be 1:"..xpos.sequence)
  assert((xpos.line == 1),"expected xpos.line to be 1:"..xpos.line)

  args.bounds_mode = xSongPos.OUT_OF_BOUNDS.ALLOW
  new_xpos,travelled = xSongPos.previous_bar(xpos,args)
  assert((travelled == 16),"expected travelled to be 16:"..travelled)
  assert((new_xpos.sequence == 1),"expected new_xpos.sequence to be 1:"..new_xpos.sequence)
  assert((new_xpos.line == -15),"expected new_xpos.line to be -15:"..new_xpos.line)
  assert((xpos.sequence == 1),"expected xpos.sequence to be 1:"..xpos.sequence)
  assert((xpos.line == 1),"expected xpos.line to be 1:"..xpos.line)

  args.bounds_mode = xSongPos.OUT_OF_BOUNDS.NULL
  new_xpos,travelled = xSongPos.previous_bar(xpos,args)
  assert(type(travelled) == "nil","expected travelled to be nil")
  assert(type(new_xpos) == "nil","expected new_xpos to be nil")
  assert((xpos.sequence == 1),"expected xpos.sequence to be 1:"..xpos.sequence)
  assert((xpos.line == 1),"expected xpos.line to be 1:"..xpos.line)

  -- previous_block
  
  xpos = {sequence = 1, line = pattern_lengths[1]}
  new_xpos,travelled = xSongPos.previous_block(xpos)
  assert((travelled == 15),"expected travelled to be 15:"..travelled)
  assert((new_xpos.sequence == 1),"expected new_xpos.sequence to be 1:"..new_xpos.sequence)
  assert((new_xpos.line == 49),"expected new_xpos.line to be 49:"..new_xpos.line)
  assert((xpos.sequence == 1),"expected xpos.sequence to be 1:"..xpos.sequence)
  assert((xpos.line == pattern_lengths[1]),"expected xpos.line to be :"..pattern_lengths[1]..","..xpos.line)

  new_xpos,travelled = xSongPos.previous_block(new_xpos)
  assert((travelled == 16),"expected travelled to be 16:"..travelled)
  assert((new_xpos.sequence == 1),"expected new_xpos.sequence to be 1:"..new_xpos.sequence)
  assert((new_xpos.line == 33),"expected new_xpos.line to be 33:"..new_xpos.line)

  xpos = {sequence = 1, line = 1}
  new_xpos,travelled = xSongPos.previous_block(xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.CAP})
  assert((travelled == 0),"expected travelled to be 0:"..travelled)
  assert((new_xpos.sequence == 1),"expected new_xpos.sequence to be 1:"..new_xpos.sequence)
  assert((new_xpos.line == 1),"expected new_xpos.line to be 1:"..new_xpos.line)
  assert((xpos.sequence == 1),"expected xpos.sequence to be 1:"..xpos.sequence)
  assert((xpos.line == 1),"expected xpos.line to be 1:"..xpos.line)

  xpos = {sequence = 3, line = 23} -- 44 lines
  new_xpos,travelled = xSongPos.previous_block(xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.CAP})
  assert((travelled == 11),"expected travelled to be 11:"..travelled)
  assert((new_xpos.sequence == 3),"expected new_xpos.sequence to be 3:"..new_xpos.sequence)
  assert((new_xpos.line == 12),"expected new_xpos.line to be 12:"..new_xpos.line)
  assert((xpos.sequence == 3),"expected xpos.sequence to be 3:"..xpos.sequence)
  assert((xpos.line == 23),"expected xpos.line to be 23:"..xpos.line)

  xpos = {sequence = 1, line = 1}
  new_xpos,travelled = xSongPos.previous_block(xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP})
  print(new_xpos,travelled)
  assert((travelled == 4),"expected travelled to be 4:"..travelled)
  assert((new_xpos.sequence == last_xpos.sequence),"expected new_xpos.sequence to be "..last_xpos.sequence..","..new_xpos.sequence)
  assert((new_xpos.line == 10),"expected new_xpos.line to be 10:"..new_xpos.line) -- pattern_lengths[5] = 12
  assert((xpos.sequence == 1),"expected xpos.sequence to be 1:"..xpos.sequence)
  assert((xpos.line == 1),"expected xpos.line to be 1:"..xpos.line)

  xpos = {sequence = 1, line = 1}
  new_xpos,travelled = xSongPos.previous_block(xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.ALLOW})
  assert((travelled == 16),"expected travelled to be 16:"..travelled)
  assert((new_xpos.sequence == 1),"expected new_xpos.sequence to be "..last_xpos.sequence..","..new_xpos.sequence)
  assert((new_xpos.line == -15),"expected new_xpos.line to be -15:"..new_xpos.line) -- pattern_lengths[1] = 64
  assert((xpos.sequence == 1),"expected xpos.sequence to be 1:"..xpos.sequence)
  assert((xpos.line == 1),"expected xpos.line to be 1:"..xpos.line)

  xpos = {sequence = 1, line = 1}
  new_xpos,travelled = xSongPos.previous_block(xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.NULL})
  assert(type(travelled) == "nil","expected travelled to be nil")
  assert(type(new_xpos) == "nil","expected new_xpos to be nil")
  assert((xpos.sequence == 1),"expected xpos.sequence to be 1:"..xpos.sequence)
  assert((xpos.line == 1),"expected xpos.line to be 1:"..xpos.line)

  -- TODO previous_pattern
  
  
  -- normalize
  --[[
  print(">>> normalize")

  xpos = {sequence=1,line=(pattern_lengths[1]+pattern_lengths[2])}
  new_xpos = xSongPos.normalize(xpos)
  assert((new_xpos.sequence==2),"expected new_xpos.sequence to be 2")
  assert((new_xpos.line==pattern_lengths[2]),("expected new_xpos.line to be %d"):format(pattern_lengths[2]),new_xpos)

  xpos = last_xpos
  new_xpos = xSongPos.normalize(last_xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.CAP})
  assert((new_xpos.sequence==last_xpos.sequence),"expected new_xpos.sequence to be "..last_xpos.sequence)
  assert((new_xpos.line==last_xpos.line),("expected new_xpos.line to be %d"):format(last_xpos.line),new_xpos)

  xpos = {sequence=last_xpos.sequence,line=last_xpos.line+1}
  new_xpos = xSongPos.normalize(xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.NULL})
  assert(type(new_xpos) == "nil","expected new_xpos to be nil")

  xpos = {sequence=last_xpos.sequence,line=last_xpos.line+1}
  new_xpos = xSongPos.normalize(xpos,{bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP})
  assert((new_xpos.sequence==1),"expected new_xpos.sequence to be 1")
  assert((new_xpos.line==1),"expected new_xpos.line to be 1")
  ]]

  -- get_line_diff
  print(">>> get_line_diff")

  local pos1 = {sequence=1,line=1}
  local pos2 = {sequence=2,line=1}
  local expected = xSongPos.get_line_diff(pos1,pos2)
  assert(expected==pattern_lengths[1],("expected line_diff to be %d, was %d"):format(pattern_lengths[1],expected))

  -- using renoise.SongPos as arguments... 
  local pos1 = rns.transport.playback_pos
  pos1.sequence=1
  pos1.line=1
  local pos2 = rns.transport.playback_pos
  pos2.sequence=2
  pos2.line=1
  local expected = xSongPos.get_line_diff(pos1,pos2)
  assert((expected==pattern_lengths[1]),("expected line_diff to be %d, was %d"):format(pattern_lengths[1],expected))

  local pos1 = {sequence=1,line=1}
  local pos2 = {sequence=1,line=1}
  assert((xSongPos.get_line_diff(pos1,pos2)==0),"expected line_diff to be 0")

  local pos1 = {sequence=3,line=pattern_lengths[3]}
  local pos2 = {sequence=1,line=1}
  local expected = pattern_lengths[1]+pattern_lengths[2]+pattern_lengths[3]-1
  assert((xSongPos.get_line_diff(pos1,pos2)==expected),("expected line_diff to be %d"):format(expected))

  local pos1 = {sequence=1,line=pattern_lengths[1]}
  local pos2 = {sequence=2,line=1}
  assert((xSongPos.get_line_diff(pos1,pos2)==1),"expected line_diff to be 1")

  local pos1 = {sequence=2,line=1}
  local pos2 = {sequence=1,line=pattern_lengths[1]}
  assert((xSongPos.get_line_diff(pos1,pos2)==1),"expected line_diff to be 1")

  local pos1 = {sequence=3,line=1}
  local pos2 = {sequence=2,line=pattern_lengths[2]}
  assert((xSongPos.get_line_diff(pos1,pos2)==1),"expected line_diff to be 1")
 
  -- END TESTS ------------------------------------------------------------------------------------

  remove_temp_patterns()

  LOG(">>> xSongPos: OK - passed all tests")


end
})
