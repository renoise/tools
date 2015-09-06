--[[
	please ensure that the xLib framework is loaded before executing this file
]]

function xsongpos_test()

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
  print("*** increase : new_pos = [1,1]",new_pos)

  new_pos:increase_by_lines(1)
  print("*** increase_by_lines : 1 line [1,2]",new_pos)

  new_pos:increase_by_lines(1)
  print("*** increase_by_lines : 1 line [1,3]",new_pos)

  new_pos:increase_by_lines(1)
  print("*** increase_by_lines : 1 line [1,4]",new_pos)

  new_pos = xSongPos({sequence=1,line=seq1_num_lines})
  print("*** increase : new_pos = [1,"..seq1_num_lines.."]",new_pos)

  new_pos:increase_by_lines(1)
  print("*** increase_by_lines : 1 line [2,1]",new_pos)

  new_pos:increase_by_lines(1)
  print("*** increase_by_lines : 1 line [2,2]",new_pos)

  new_pos:increase_by_lines(1)
  print("*** increase_by_lines : 1 line [2,3]",new_pos)

  new_pos:increase_by_lines(seq2_num_lines)
  print("*** increase_by_lines : "..seq2_num_lines.." [3,3]",new_pos)

  new_pos:increase_by_lines(seq3_num_lines-3)
  print("*** increase_by_lines : "..(seq3_num_lines-3).." [3,"..seq3_num_lines.."]",new_pos)

  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.CAP
  new_pos:increase_by_lines(1)
  print("*** increase_by_lines : 1 [3,"..seq3_num_lines.."], CAP",new_pos)

  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP
  new_pos:increase_by_lines(10)
  print("*** increase_by_lines : 10 [1,10], LOOP",new_pos)

  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.NULL
  new_pos:increase_by_lines(total_lines)
  print("*** increase_by_lines : "..(total_lines).." [nil], NULL",new_pos)

  -- decrease

  new_pos = xSongPos({sequence=3,line=2})
  print("*** decrease : new_pos = [3,2]",new_pos)

  new_pos:decrease_by_lines(seq2_num_lines+seq1_num_lines)
  print("*** decrease_by_lines : "..(seq2_num_lines+seq1_num_lines).." [1,2]",new_pos)

  new_pos:decrease_by_lines(1)
  print("*** decrease_by_lines : 1 line [1,1]",new_pos)

  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.CAP
  new_pos:decrease_by_lines(seq1_num_lines)
  print("*** decrease_by_lines : "..seq1_num_lines.." lines [1,1], CAP",new_pos)

  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP
  new_pos:decrease_by_lines(seq1_num_lines)
  print("*** decrease_by_lines : "..seq1_num_lines.." lines ["..seq_count..","..(seq3_num_lines-seq1_num_lines+1)  .."], LOOP",new_pos)

  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.NULL
  new_pos:decrease_by_lines(total_lines)
  print("*** decrease_by_lines : "..total_lines.." lines [nil], NULL",new_pos)

  -- normalize

  new_pos = xSongPos({sequence=1,line=(seq1_num_lines+seq2_num_lines)})
  print("*** normalize : new_pos - seq with [1,"..(seq1_num_lines+seq2_num_lines).."], should become [2,"..seq2_num_lines.."]",new_pos:normalize())

  new_pos = xSongPos({sequence=3,line=(total_lines)})
  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.CAP
  print("*** normalize : new_pos - seq with [3,"..(total_lines).."], should stop at end CAP",new_pos:normalize())

  new_pos = xSongPos({sequence=3,line=(total_lines)})
  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP
  print("*** normalize : new_pos - seq with [3,"..(total_lines).."], should wrap around LOOP",new_pos:normalize())

  new_pos = xSongPos({sequence=3,line=(total_lines)})
  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.NULL
  print("*** normalize : new_pos - seq with [3,"..(total_lines).."], should return NULL",new_pos:normalize())

  new_pos = xSongPos({sequence=3,line=seq3_num_lines+1})
  new_pos.bounds_mode = xSongPos.OUT_OF_BOUNDS.LOOP
  print("*** normalize : new_pos - seq with [3,"..(seq3_num_lines+1).."], should return 1,1 LOOP",new_pos:normalize())

  -- get_line_diff

  local pos1 = xSongPos({sequence=1,line=1})
  local pos2 = xSongPos({sequence=2,line=1})
  print("*** get_line_diff",pos1,pos2,xSongPos.get_line_diff(pos1,pos2))

  local pos1 = rns.transport.playback_pos
  pos1.sequence=1
  pos1.line=1
  local pos2 = rns.transport.playback_pos
  pos1.sequence=2
  pos1.line=1
  print("*** get_line_diff",pos1,pos2,xSongPos.get_line_diff(pos1,pos2))

  local pos1 = xSongPos({sequence=1,line=1})
  local pos2 = xSongPos({sequence=1,line=1})
  print("*** get_line_diff",pos1,pos2,xSongPos.get_line_diff(pos1,pos2))

  local pos1 = xSongPos({sequence=3,line=seq3_num_lines})
  local pos2 = xSongPos({sequence=1,line=1})
  print("*** get_line_diff",pos1,pos2,xSongPos.get_line_diff(pos1,pos2))

  local pos1 = xSongPos({sequence=1,line=seq1_num_lines})
  local pos2 = xSongPos({sequence=2,line=1})
  print("*** get_line_diff",pos1,pos2,xSongPos.get_line_diff(pos1,pos2))

  local pos1 = xSongPos({sequence=2,line=1})
  local pos2 = xSongPos({sequence=1,line=seq1_num_lines})
  print("*** get_line_diff",pos1,pos2,xSongPos.get_line_diff(pos1,pos2))

  local pos1 = xSongPos({sequence=3,line=1})
  local pos2 = xSongPos({sequence=2,line=seq2_num_lines})
  print("*** get_line_diff",pos1,pos2,xSongPos.get_line_diff(pos1,pos2))



end
