--[[ 

  Testcase for xSongPos

--]]

do

  print("xSongPos: starting unit-test...")

  require (xLib_dir.."xSongPos")
  require (xLib_dir.."xBlockLoop")


  -- create temporary patterns
  if (#renoise.song().sequencer.pattern_sequence < 3) then
    local str_msg = "The xSongPos unit-test requires three patterns to be"
                  .."created during the test - do you want to proceed?"
    local choice = renoise.app():show_prompt("Create patterns",str_msg,{"OK","Cancel"})
    if (choice == "OK") then
      print("xSongPos: creating patterns...")
      renoise.song().sequencer:insert_new_pattern_at(1)
      renoise.song().sequencer:insert_new_pattern_at(1)
    else
      print("xSongPos: aborted unit-test...")
    end

  end

  local seq1_num_lines = xSongPos.get_pattern_num_lines(1)
  local seq2_num_lines = xSongPos.get_pattern_num_lines(2)
  local seq3_num_lines = xSongPos.get_pattern_num_lines(3)
  local total_lines = seq1_num_lines+seq2_num_lines+seq3_num_lines
  local seq_count = #rns.sequencer.pattern_sequence
  local edit_pos = xSongPos(rns.transport.playback_pos)
  local play_pos = xSongPos(rns.transport.edit_pos)

  local new_pos, new_pos_2

  -- comparison operators

  new_pos = xSongPos({sequence=1,line=1})
  new_pos_2 = xSongPos({sequence=1,line=1})

  new_pos_2 = xSongPos({sequence=1,line=1})
  assert((new_pos == new_pos_2),"expected new_pos to be equal to new_pos_2")
  assert(not (new_pos > new_pos_2),"expected new_pos to be *not* greater than new_pos_2")
  assert(not (new_pos < new_pos_2),"expected new_pos to be *not* less than new_pos_2")
  assert((new_pos <= new_pos_2),"expected new_pos to be less than or equal to new_pos_2")
  assert((new_pos >= new_pos_2),"expected new_pos to be greater than or equal to new_pos_2")

  new_pos_2 = xSongPos({sequence=2,line=1})
  assert((new_pos ~= new_pos_2),"expected pos to be not equal")
  assert(not (new_pos > new_pos_2),"expected new_pos to be *not* greater than new_pos_2")
  assert((new_pos < new_pos_2),"expected new_pos_2 to be greater than new_pos")
  assert(not (new_pos >= new_pos_2),"expected new_pos to be *not* greather than or equal to new_pos_2")
  assert((new_pos <= new_pos_2),"expected new_pos to be les than or equal to new_pos_2")

  new_pos = xSongPos({sequence=2,line=1})
  new_pos_2 = xSongPos({sequence=1,line=1})
  assert((new_pos ~= new_pos_2),"expected pos to be not equal")
  assert((new_pos > new_pos_2),"expected new_pos to be greater than new_pos_2")
  assert(not (new_pos < new_pos_2),"expected new_pos_2 to be *not* greater than new_pos")
  assert((new_pos >= new_pos_2),"expected new_pos to be greater than or equal to new_pos_2")
  assert(not (new_pos <= new_pos_2),"expected new_pos to be *not* less than or equal to new_pos_2")

  new_pos = xSongPos({sequence=1,line=1})

  -- increase

  new_pos = xSongPos({sequence=1,line=1})
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==1),"expected line to be 1")

  new_pos:increase_by_lines(1)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==2),"expected line to be 2")

  new_pos:increase_by_lines(1)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==3),"expected line to be 3")

  new_pos:increase_by_lines(1)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==4),"expected line to be 4")

  new_pos = xSongPos({sequence=1,line=seq1_num_lines})
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==seq1_num_lines),("expected line to be %d"):format(seq1_num_lines))

  new_pos:increase_by_lines(1)
  assert((new_pos.sequence==2),"expected sequence to be 2")
  assert((new_pos.line==1),"expected line to be 1")

  new_pos:increase_by_lines(1)
  assert((new_pos.sequence==2),"expected sequence to be 2")
  assert((new_pos.line==2),"expected line to be 2")

  new_pos:increase_by_lines(1)
  assert((new_pos.sequence==2),"expected sequence to be 2")
  assert((new_pos.line==3),"expected line to be 3")

  new_pos:increase_by_lines(seq2_num_lines)
  assert((new_pos.sequence==3),"expected sequence to be 3")
  assert((new_pos.line==3),"expected line to be 3")

  new_pos:increase_by_lines(seq3_num_lines-3)
  assert((new_pos.sequence==3),"expected sequence to be 3")
  assert((new_pos.line==seq3_num_lines),("expected line to be %d"):format(seq3_num_lines))

  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.CAP
  new_pos:increase_by_lines(1)
  assert((new_pos.sequence==3),"expected sequence to be 3")
  assert((new_pos.line==seq3_num_lines),("expected line to be %d"):format(seq3_num_lines))

  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP
  new_pos:increase_by_lines(10)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==10),"expected line to be 10")

  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.NULL
  new_pos:increase_by_lines(total_lines)
  assert((new_pos.sequence==nil),"expected sequence to be NULL")

  -- decrease

  new_pos = xSongPos({sequence=3,line=2})
  assert((new_pos.sequence==3),"expected sequence to be 3")
  assert((new_pos.line==2),"expected line to be 2")

  new_pos:decrease_by_lines(seq2_num_lines+seq1_num_lines)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==2),"expected line to be 2")

  new_pos:decrease_by_lines(1)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==1),"expected line to be 1")

  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.CAP
  new_pos:decrease_by_lines(seq1_num_lines)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==1),"expected line to be 1")

  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP
  new_pos:decrease_by_lines(seq1_num_lines)
  assert((new_pos.sequence==seq_count),("expected sequence to be %d"):format(seq_count))
  assert((new_pos.line==seq3_num_lines-seq1_num_lines+1),("expected line to be %d"):format(seq3_num_lines-seq1_num_lines+1))

  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.NULL
  new_pos:decrease_by_lines(total_lines)
  assert((new_pos.sequence==nil),"expected sequence to be NULL")

  -- normalize

  new_pos = xSongPos({sequence=1,line=(seq1_num_lines+seq2_num_lines)})
  new_pos:normalize()
  assert((new_pos.sequence==2),"expected sequence to be 2")
  assert((new_pos.line==seq2_num_lines),("expected line to be %d"):format(seq2_num_lines),new_pos)

  new_pos = xSongPos({sequence=3,line=total_lines})
  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.CAP
  new_pos:normalize()
  assert((new_pos.sequence==3),"expected sequence to be 3")
  assert((new_pos.line==seq3_num_lines),("expected line to be %d"):format(seq3_num_lines),new_pos)

  new_pos = xSongPos({sequence=3,line=(total_lines)})
  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP
  new_pos:normalize()
  local expected = total_lines - (seq1_num_lines + seq2_num_lines)
  assert((new_pos.sequence==2),("expected sequence to be 3 (%s)"):format(tostring(new_pos)))
  assert((new_pos.line==expected),("expected line to be %d (%s)"):format(expected,tostring(new_pos)))

  new_pos = xSongPos({sequence=3,line=(total_lines)})
  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.NULL
  new_pos:normalize()
  assert((new_pos.sequence==nil),"expected sequence to be NULL")
  assert((new_pos.line==nil),"expected line to be NULL")

  new_pos = xSongPos({sequence=3,line=seq3_num_lines+1})
  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP
  new_pos:normalize()
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==1),"expected line to be 1")

  -- get_line_diff

  local pos1 = xSongPos({sequence=1,line=1})
  local pos2 = xSongPos({sequence=2,line=1})
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

  local pos1 = xSongPos({sequence=1,line=1})
  local pos2 = xSongPos({sequence=1,line=1})
  assert((xSongPos.get_line_diff(pos1,pos2)==0),"expected line_diff to be 0")

  local pos1 = xSongPos({sequence=3,line=seq3_num_lines})
  local pos2 = xSongPos({sequence=1,line=1})
  local expected = seq1_num_lines+seq2_num_lines+seq3_num_lines-1
  assert((xSongPos.get_line_diff(pos1,pos2)==expected),("expected line_diff to be %d"):format(expected))

  local pos1 = xSongPos({sequence=1,line=seq1_num_lines})
  local pos2 = xSongPos({sequence=2,line=1})
  assert((xSongPos.get_line_diff(pos1,pos2)==1),"expected line_diff to be 1")

  local pos1 = xSongPos({sequence=2,line=1})
  local pos2 = xSongPos({sequence=1,line=seq1_num_lines})
  assert((xSongPos.get_line_diff(pos1,pos2)==1),"expected line_diff to be 1")

  local pos1 = xSongPos({sequence=3,line=1})
  local pos2 = xSongPos({sequence=2,line=seq2_num_lines})
  assert((xSongPos.get_line_diff(pos1,pos2)==1),"expected line_diff to be 1")


  print("xSongPos: OK - passed all tests")


end
