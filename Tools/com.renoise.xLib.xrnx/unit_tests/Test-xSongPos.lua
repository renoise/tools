--[[ 

  Testcase for xSongPos

--]]

_xlib_tests:insert({
name = "xSongPos",
fn = function()

  print(">>> xSongPos: starting unit-test...")

  require (_xlibroot.."xSongPos")
  require (_xlibroot.."xPatternSequencer")
  require (_xlibroot.."xBlockLoop")
  _trace_filters = {"^xSongPos*"}


  -- create temporary patterns
  if (#rns.sequencer.pattern_sequence < 3) then
    local str_msg = "The xSongPos unit-test requires three patterns to be"
                  .."created during the test - do you want to proceed?"
    local choice = renoise.app():show_prompt("Create patterns",str_msg,{"OK","Cancel"})
    if (choice == "OK") then
      print("xSongPos: creating patterns...")
      rns.sequencer:insert_new_pattern_at(1)
      rns.sequencer:insert_new_pattern_at(1)

      rns.transport.playing = false
      
    else
      print("xSongPos: aborted unit-test...")
    end

  end

  local seq1_num_lines = xPatternSequencer.get_number_of_lines(1)
  local seq2_num_lines = xPatternSequencer.get_number_of_lines(2)
  local seq3_num_lines = xPatternSequencer.get_number_of_lines(3)
  local total_lines = seq1_num_lines+seq2_num_lines+seq3_num_lines
  local seq_count = #rns.sequencer.pattern_sequence
  local edit_pos = rns.transport.playback_pos
  local play_pos = rns.transport.edit_pos

  local new_pos, new_pos_2

  -- comparison operators
  --[[
  new_pos = {sequence=1,line=1}
  new_pos_2 = {sequence=1,line=1}

  new_pos_2 = {sequence=1,line=1}
  assert((new_pos == new_pos_2),"expected new_pos to be equal to new_pos_2")
  assert(not (new_pos > new_pos_2),"expected new_pos to be *not* greater than new_pos_2")
  assert(not (new_pos < new_pos_2),"expected new_pos to be *not* less than new_pos_2")
  assert((new_pos <= new_pos_2),"expected new_pos to be less than or equal to new_pos_2")
  assert((new_pos >= new_pos_2),"expected new_pos to be greater than or equal to new_pos_2")

  new_pos_2 = {sequence=2,line=1}
  assert((new_pos ~= new_pos_2),"expected pos to be not equal")
  assert(not (new_pos > new_pos_2),"expected new_pos to be *not* greater than new_pos_2")
  assert((new_pos < new_pos_2),"expected new_pos_2 to be greater than new_pos")
  assert(not (new_pos >= new_pos_2),"expected new_pos to be *not* greather than or equal to new_pos_2")
  assert((new_pos <= new_pos_2),"expected new_pos to be les than or equal to new_pos_2")

  new_pos = {sequence=2,line=1}
  new_pos_2 = {sequence=1,line=1}
  assert((new_pos ~= new_pos_2),"expected pos to be not equal")
  assert((new_pos > new_pos_2),"expected new_pos to be greater than new_pos_2")
  assert(not (new_pos < new_pos_2),"expected new_pos_2 to be *not* greater than new_pos")
  assert((new_pos >= new_pos_2),"expected new_pos to be greater than or equal to new_pos_2")
  assert(not (new_pos <= new_pos_2),"expected new_pos to be *not* less than or equal to new_pos_2")

  new_pos = {sequence=1,line=1}
  ]]

  -- increase (lines)

  new_pos = {sequence=1,line=1}
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==1),"expected line to be 1")

  xSongPos.increase_by_lines(1,new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==2),"expected line to be 2")

  xSongPos.increase_by_lines(1,new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==3),"expected line to be 3")

  xSongPos.increase_by_lines(1,new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1 - "..new_pos.sequence)
  assert((new_pos.line==4),"expected line to be 4 - "..new_pos.line)

  new_pos = {sequence=1,line=seq1_num_lines}
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==seq1_num_lines),("expected line to be %d"):format(seq1_num_lines))

  xSongPos.increase_by_lines(1,new_pos)
  assert((new_pos.sequence==2),"expected sequence to be 2")
  assert((new_pos.line==1),"expected line to be 1")

  xSongPos.increase_by_lines(1,new_pos)
  assert((new_pos.sequence==2),"expected sequence to be 2")
  assert((new_pos.line==2),"expected line to be 2")

  xSongPos.increase_by_lines(1,new_pos)
  assert((new_pos.sequence==2),"expected sequence to be 2")
  assert((new_pos.line==3),"expected line to be 3")

  xSongPos.increase_by_lines(seq2_num_lines,new_pos)
  assert((new_pos.sequence==3),"expected sequence to be 3")
  assert((new_pos.line==3),"expected line to be 3")

  xSongPos.increase_by_lines(seq3_num_lines-3,new_pos)
  assert((new_pos.sequence==3),"expected sequence to be 3")
  assert((new_pos.line==seq3_num_lines),("expected line to be %d"):format(seq3_num_lines))

  xSongPos.increase_by_lines(1,new_pos,xSongPos.OUT_OF_BOUNDS.CAP)
  assert((new_pos.sequence==3),"expected sequence to be 3")
  assert((new_pos.line==seq3_num_lines),("expected line to be %d"):format(seq3_num_lines))

  xSongPos.increase_by_lines(10,new_pos,xSongPos.OUT_OF_BOUNDS.LOOP)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==10),"expected line to be 10")

  xSongPos.increase_by_lines(total_lines,new_pos,xSongPos.OUT_OF_BOUNDS.NULL)
  assert((new_pos.sequence==nil),"expected sequence to be NULL")

  -- increase (beat)

  rns.transport.lpb = 4
  rns.transport.metronome_beats_per_bar = 4

  new_pos = {sequence=1,line=0}
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==0),"expected line to be 0")

  xSongPos.next_beat(new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==1),"expected line to be 1")

  xSongPos.next_beat(new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==5),"expected line to be 5")

  new_pos = {sequence=1,line=1}
  xSongPos.next_beat(new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==5),"expected line to be 5")

  new_pos = {sequence=1,line=2}
  xSongPos.next_beat(new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==5),"expected line to be 5")

  new_pos = {sequence=1,line=3}
  xSongPos.next_beat(new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==5),"expected line to be 5")

  new_pos = {sequence=1,line=4}
  xSongPos.next_beat(new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==5),"expected line to be 5")

  new_pos = {sequence=1,line=5}
  xSongPos.next_beat(new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==9),"expected line to be 9")

  -- increase (bar)

  rns.transport.lpb = 4
  rns.transport.metronome_beats_per_bar = 4

  new_pos = {sequence=1,line=0}
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==0),"expected line to be 0")

  xSongPos.next_bar(new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==1),"expected line to be 1")

  xSongPos.next_bar(new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==17),"expected line to be 17")

  xSongPos.next_bar(new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==33),"expected line to be 33")

  xSongPos.next_bar(new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==49),"expected line to be 49")

  xSongPos.next_bar(new_pos)
  assert((new_pos.sequence==2),"expected sequence to be 2")
  assert((new_pos.line==1),"expected line to be 1")

  new_pos = {sequence=1,line=1}
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==1),"expected line to be 1")
  xSongPos.next_bar(new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==17),"expected line to be 17")

  new_pos = {sequence=1,line=16}
  xSongPos.next_bar(new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==17),"expected line to be 17")

  new_pos = {sequence=1,line=17}
  xSongPos.next_bar(new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==33),"expected line to be 33")

  new_pos = {sequence=1,line=64}
  xSongPos.next_bar(new_pos)
  assert((new_pos.sequence==2),"expected sequence to be 2")
  assert((new_pos.line==1),"expected line to be 1")

  rns.transport.lpb = 4
  rns.transport.metronome_beats_per_bar = 3

  new_pos = {sequence=1,line=0}
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==0),"expected line to be 0")

  xSongPos.next_bar(new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==1),"expected line to be 1")

  xSongPos.next_bar(new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==13),"expected line to be 13")

  new_pos = {sequence=3,line=64}
  xSongPos.next_block(new_pos,xSongPos.OUT_OF_BOUNDS.LOOP  )
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==1),"expected line to be 1")
  
  new_pos = {sequence=3,line=60}
  xSongPos.next_block(new_pos,xSongPos.OUT_OF_BOUNDS.CAP)
  assert((new_pos.sequence==3),"expected sequence to be 3")
  assert((new_pos.line==64),"expected line to be 64")
  
  new_pos = {sequence=3,line=60}
  xSongPos.next_block(new_pos,xSongPos.OUT_OF_BOUNDS.NULL)
  assert((new_pos.sequence==nil),"expected sequence to be nil")
  assert((new_pos.line==nil),"expected line to be nil")
  

  -- increase (block)

  rns.transport.lpb = 3
  rns.transport.metronome_beats_per_bar = 3

  new_pos = {sequence=1,line=0}
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==0),"expected line to be 0")

  xSongPos.next_block(new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==1),"expected line to be 1")
  
  xSongPos.next_block(new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==17),"expected line to be 17")
  
  new_pos = {sequence=1,line=64}
  xSongPos.next_block(new_pos)
  assert((new_pos.sequence==2),"expected sequence to be 2")
  assert((new_pos.line==1),"expected line to be 1")

  new_pos = {sequence=3,line=64}
  xSongPos.next_block(new_pos,xSongPos.OUT_OF_BOUNDS.LOOP)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==1),"expected line to be 1")
  
  new_pos = {sequence=3,line=60}
  xSongPos.next_block(new_pos,xSongPos.OUT_OF_BOUNDS.CAP)
  assert((new_pos.sequence==3),"expected sequence to be 3")
  assert((new_pos.line==64),"expected line to be 64")
  
  new_pos = {sequence=3,line=60}
  xSongPos.next_block(new_pos,xSongPos.OUT_OF_BOUNDS.NULL)
  assert((new_pos.sequence==nil),"expected sequence to be nil")
  assert((new_pos.line==nil),"expected line to be nil")
  
  
  -- increase (pattern)

  new_pos = {sequence=1,line=0}
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==0),"expected line to be 0")

  xSongPos.next_pattern(new_pos)
  assert((new_pos.sequence==2),"expected sequence to be 2")
  assert((new_pos.line==1),"expected line to be 1")
  
  xSongPos.next_pattern(new_pos)
  assert((new_pos.sequence==3),"expected sequence to be 3")
  assert((new_pos.line==1),"expected line to be 1")

  new_pos = {sequence=3,line=1}
  xSongPos.next_pattern(new_pos,xSongPos.OUT_OF_BOUNDS.CAP)
  assert((new_pos.sequence==3),"expected sequence to be 3:"..new_pos.sequence)
  assert((new_pos.line==64),"expected line to be 64:"..new_pos.line)
  
  new_pos = {sequence=3,line=64}
  xSongPos.next_pattern(new_pos,xSongPos.OUT_OF_BOUNDS.CAP)
  assert((new_pos.sequence==3),"expected sequence to be 3:"..new_pos.sequence)
  assert((new_pos.line==64),"expected line to be 64:"..new_pos.line)
  
  new_pos = {sequence=3,line=64}
  xSongPos.next_pattern(new_pos,xSongPos.OUT_OF_BOUNDS.LOOP)
  assert((new_pos.sequence==1),"expected sequence to be 1:"..new_pos.sequence)
  assert((new_pos.line==1),"expected line to be 1:"..new_pos.line)

  new_pos = {sequence=3,line=64}
  xSongPos.next_pattern(new_pos,xSongPos.OUT_OF_BOUNDS.NULL)
  assert((new_pos.sequence==nil),"expected sequence to be nil")
  assert((new_pos.line==nil),"expected line to be nil")

  -- decrease (lines)

  new_pos = {sequence=3,line=2}
  assert((new_pos.sequence==3),"expected sequence to be 3")
  assert((new_pos.line==2),"expected line to be 2")

  xSongPos.decrease_by_lines(seq2_num_lines+seq1_num_lines,new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==2),"expected line to be 2")

  xSongPos.decrease_by_lines(1,new_pos)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==1),"expected line to be 1")

  xSongPos.decrease_by_lines(seq1_num_lines,new_pos,xSongPos.OUT_OF_BOUNDS.CAP)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==1),"expected line to be 1")

  xSongPos.decrease_by_lines(seq1_num_lines,new_pos,xSongPos.OUT_OF_BOUNDS.LOOP)
  assert((new_pos.sequence==seq_count),("expected sequence to be %d"):format(seq_count))
  assert((new_pos.line==seq3_num_lines-seq1_num_lines+1),("expected line to be %d"):format(seq3_num_lines-seq1_num_lines+1))

  xSongPos.decrease_by_lines(total_lines,new_pos,xSongPos.OUT_OF_BOUNDS.NULL)
  assert((new_pos.sequence==nil),"expected sequence to be NULL")

  -- normalize

  new_pos = {sequence=1,line=(seq1_num_lines+seq2_num_lines)}
  xSongPos.normalize(new_pos)
  assert((new_pos.sequence==2),"expected sequence to be 2")
  assert((new_pos.line==seq2_num_lines),("expected line to be %d"):format(seq2_num_lines),new_pos)

  new_pos = {sequence=3,line=total_lines}
  xSongPos.normalize(new_pos,xSongPos.OUT_OF_BOUNDS.CAP)
  assert((new_pos.sequence==3),"expected sequence to be 3")
  assert((new_pos.line==seq3_num_lines),("expected line to be %d"):format(seq3_num_lines),new_pos)

  new_pos = {sequence=3,line=(total_lines)}
  xSongPos.normalize(new_pos,xSongPos.OUT_OF_BOUNDS.LOOP)
  local expected = total_lines - (seq1_num_lines + seq2_num_lines)
  assert((new_pos.sequence==2),("expected sequence to be 3 (%s)"):format(tostring(new_pos)))
  assert((new_pos.line==expected),("expected line to be %d (%s)"):format(expected,tostring(new_pos)))

  new_pos = {sequence=3,line=(total_lines)}
  xSongPos.normalize(new_pos,xSongPos.OUT_OF_BOUNDS.NULL)
  assert((new_pos.sequence==nil),"expected sequence to be NULL")
  assert((new_pos.line==nil),"expected line to be NULL")

  new_pos = {sequence=3,line=seq3_num_lines+1}
  xSongPos.normalize(new_pos,xSongPos.OUT_OF_BOUNDS.LOOP)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==1),"expected line to be 1")

  -- get_line_diff

  local pos1 = {sequence=1,line=1}
  local pos2 = {sequence=2,line=1}
  local expected = xSongPos.get_line_diff(pos1,pos2)
  assert(expected==seq1_num_lines,("expected line_diff to be %d, was %d"):format(seq1_num_lines,expected))

  -- using renoise.SongPos as arguments... 
  local pos1 = rns.transport.playback_pos
  pos1.sequence=1
  pos1.line=1
  local pos2 = rns.transport.playback_pos
  pos2.sequence=2
  pos2.line=1
  local expected = xSongPos.get_line_diff(pos1,pos2)
  assert((expected==seq1_num_lines),("expected line_diff to be %d, was %d"):format(seq1_num_lines,expected))

  local pos1 = {sequence=1,line=1}
  local pos2 = {sequence=1,line=1}
  assert((xSongPos.get_line_diff(pos1,pos2)==0),"expected line_diff to be 0")

  local pos1 = {sequence=3,line=seq3_num_lines}
  local pos2 = {sequence=1,line=1}
  local expected = seq1_num_lines+seq2_num_lines+seq3_num_lines-1
  assert((xSongPos.get_line_diff(pos1,pos2)==expected),("expected line_diff to be %d"):format(expected))

  local pos1 = {sequence=1,line=seq1_num_lines}
  local pos2 = {sequence=2,line=1}
  assert((xSongPos.get_line_diff(pos1,pos2)==1),"expected line_diff to be 1")

  local pos1 = {sequence=2,line=1}
  local pos2 = {sequence=1,line=seq1_num_lines}
  assert((xSongPos.get_line_diff(pos1,pos2)==1),"expected line_diff to be 1")

  local pos1 = {sequence=3,line=1}
  local pos2 = {sequence=2,line=seq2_num_lines}
  assert((xSongPos.get_line_diff(pos1,pos2)==1),"expected line_diff to be 1")


  print(">>> xSongPos: OK - passed all tests")


end
})
