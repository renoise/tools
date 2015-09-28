--[[
	please ensure that the xLib framework is loaded before executing this file
]]

function xsongpos_test()

  print("xSongPos: starting unit-test...")

  -- TODO create three temporary patterns

  local seq1_num_lines = xSongPos.get_pattern_num_lines(1)
  local seq2_num_lines = xSongPos.get_pattern_num_lines(2)
  local seq3_num_lines = xSongPos.get_pattern_num_lines(3)
  local total_lines = seq1_num_lines+seq2_num_lines+seq3_num_lines
  local seq_count = #rns.sequencer.pattern_sequence
  local edit_pos = xSongPos(rns.transport.playback_pos)
  local play_pos = xSongPos(rns.transport.edit_pos)

  local new_pos

  -- comparison operators

  print("*** edit_pos.sequence,line",edit_pos)
  print("*** play_pos.sequence,line",play_pos)

  print("*** operator : edit_pos == play_pos",(edit_pos == play_pos))
  print("*** operator : edit_pos ~= play_pos",(edit_pos ~= play_pos))
  print("*** operator : edit_pos > play_pos",(edit_pos > play_pos))
  print("*** operator : edit_pos < play_pos",(edit_pos < play_pos))
  print("*** operator : edit_pos >= play_pos",(edit_pos >= play_pos))
  print("*** operator : edit_pos <= play_pos",(edit_pos <= play_pos))

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
  --print("*** decrease : new_pos = [3,2]",new_pos)

  new_pos:decrease_by_lines(seq2_num_lines+seq1_num_lines)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==2),"expected line to be 2")
  --print("*** decrease_by_lines : "..(seq2_num_lines+seq1_num_lines).." [1,2]",new_pos)

  new_pos:decrease_by_lines(1)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==1),"expected line to be 1")
  --print("*** decrease_by_lines : 1 line [1,1]",new_pos)

  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.CAP
  new_pos:decrease_by_lines(seq1_num_lines)
  assert((new_pos.sequence==1),"expected sequence to be 1")
  assert((new_pos.line==1),"expected line to be 1")
  --print("*** decrease_by_lines : "..seq1_num_lines.." lines [1,1], CAP",new_pos)

  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP
  new_pos:decrease_by_lines(seq1_num_lines)
  assert((new_pos.sequence==seq_count),("expected sequence to be %d"):format(seq_count))
  assert((new_pos.line==seq3_num_lines-seq1_num_lines+1),("expected line to be %d"):format(seq3_num_lines-seq1_num_lines+1))
  --print("*** decrease_by_lines : "..seq1_num_lines.." lines ["..seq_count..","..(seq3_num_lines-seq1_num_lines+1)  .."], LOOP",new_pos)

  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.NULL
  new_pos:decrease_by_lines(total_lines)
  assert((new_pos.sequence==nil),"expected sequence to be NULL")
  --print("*** decrease_by_lines : "..total_lines.." lines [nil], NULL",new_pos)

  -- normalize

  new_pos = xSongPos({sequence=1,line=(seq1_num_lines+seq2_num_lines)})
  new_pos:normalize()
  assert((new_pos.sequence==2),"expected sequence to be 2",new_pos)
  assert((new_pos.line==seq2_num_lines),("expected line to be %d"):format(seq2_num_lines),new_pos)
  --print("*** normalize : new_pos - seq with [1,"..(seq1_num_lines+seq2_num_lines).."], should become [2,"..seq2_num_lines.."]",new_pos:normalize())

  new_pos = xSongPos({sequence=3,line=total_lines})
  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.CAP
  new_pos:normalize()
  assert((new_pos.sequence==3),"expected sequence to be 3",new_pos)
  assert((new_pos.line==seq3_num_lines),("expected line to be %d"):format(seq3_num_lines),new_pos)

  new_pos = xSongPos({sequence=3,line=(total_lines)})
  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP
  new_pos:normalize()
  local expected = total_lines - (seq1_num_lines + seq2_num_lines)
  assert((new_pos.sequence==2),("expected sequence to be 3 (%s)"):format(tostring(new_pos)))
  assert((new_pos.line==expected),("expected line to be %d (%s)"):format(expected,tostring(new_pos)))
  --print("*** normalize : new_pos - seq with [3,"..(total_lines).."], should wrap around LOOP",new_pos:normalize())

  new_pos = xSongPos({sequence=3,line=(total_lines)})
  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.NULL
  new_pos:normalize()
  assert((new_pos.sequence==nil),"expected sequence to be NULL")
  assert((new_pos.line==nil),"expected line to be NULL")
  --print("*** normalize : new_pos - seq with [3,"..(total_lines).."], should return NULL",new_pos:normalize())

  new_pos = xSongPos({sequence=3,line=seq3_num_lines+1})
  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP
  new_pos:normalize()
  assert((new_pos.sequence==1),"expected sequence to be 1",new_pos)
  assert((new_pos.line==1),"expected line to be 1",new_pos)
  --print("*** normalize : new_pos - seq with [3,"..(seq3_num_lines+1).."], should return 1,1 LOOP",new_pos:normalize())

  -- get_line_diff

  local pos1 = xSongPos({sequence=1,line=1})
  local pos2 = xSongPos({sequence=2,line=1})
  assert((xSongPos.get_line_diff(pos1,pos2)==seq1_num_lines),("expected line_diff to be "):format(seq1_num_lines))
  --print("*** get_line_diff",pos1,pos2,xSongPos.get_line_diff(pos1,pos2))

  local pos1 = rns.transport.playback_pos
  pos1.sequence=1
  pos1.line=1
  local pos2 = rns.transport.playback_pos
  pos1.sequence=2
  pos1.line=1
  assert((xSongPos.get_line_diff(pos1,pos2)==seq1_num_lines),("expected line_diff to be "):format(seq1_num_lines))
  --print("*** get_line_diff",pos1,pos2,xSongPos.get_line_diff(pos1,pos2))

  local pos1 = xSongPos({sequence=1,line=1})
  local pos2 = xSongPos({sequence=1,line=1})
  assert((xSongPos.get_line_diff(pos1,pos2)==0),"expected line_diff to be 0")
  --print("*** get_line_diff",pos1,pos2,xSongPos.get_line_diff(pos1,pos2))

  local pos1 = xSongPos({sequence=3,line=seq3_num_lines})
  local pos2 = xSongPos({sequence=1,line=1})
  local expected = seq1_num_lines+seq2_num_lines+seq3_num_lines-1
  assert((xSongPos.get_line_diff(pos1,pos2)==expected),("expected line_diff to be %d"):format(expected))
  --print("*** get_line_diff",pos1,pos2,xSongPos.get_line_diff(pos1,pos2))

  local pos1 = xSongPos({sequence=1,line=seq1_num_lines})
  local pos2 = xSongPos({sequence=2,line=1})
  assert((xSongPos.get_line_diff(pos1,pos2)==1),"expected line_diff to be 1")
  --print("*** get_line_diff",pos1,pos2,xSongPos.get_line_diff(pos1,pos2))

  local pos1 = xSongPos({sequence=2,line=1})
  local pos2 = xSongPos({sequence=1,line=seq1_num_lines})
  assert((xSongPos.get_line_diff(pos1,pos2)==1),"expected line_diff to be 1")
  --print("*** get_line_diff",pos1,pos2,xSongPos.get_line_diff(pos1,pos2))

  local pos1 = xSongPos({sequence=3,line=1})
  local pos2 = xSongPos({sequence=2,line=seq2_num_lines})
  assert((xSongPos.get_line_diff(pos1,pos2)==1),"expected line_diff to be 1")
  --print("*** get_line_diff",pos1,pos2,xSongPos.get_line_diff(pos1,pos2))


  print("xSongPos: OK - passed all tests")


end
