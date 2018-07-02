--[[ 

  Testcase for xNoteColumn

--]]

_xlib_tests:insert({
name = "xCursorPos",
fn = function()

  --require (_xlibroot.."xLine")
  cLib.require (_xlibroot.."xCursorPos")
  _trace_filters = {"^xCursorPos*"}

  LOG(">>> xCursorPos: starting unit-test...")

  -- prepare ----------------------------------------------- 

  -- insert a few patterns/tracks with some notes

  -- first pattern

  rns.sequencer:insert_new_pattern_at(1)
  rns.sequencer:insert_new_pattern_at(1)
  rns:insert_track_at(1)
  rns:insert_track_at(1)

  local patt_idx = rns.sequencer:pattern(1)
  local patt = rns.patterns[patt_idx]
  patt.number_of_lines = 16
  local track = rns.tracks[1]
  track.visible_note_columns = 2
  track.visible_effect_columns = 2
  local track = rns.tracks[2]
  track.visible_note_columns = 2
  track.visible_effect_columns = 2
  
  local ptrack = patt:track(1)
  local line = ptrack:line(1)
  local column = line.note_columns[1]
  column.note_value = 1
  column.volume_value = 1

  local ptrack = patt:track(2)
  local line = ptrack:line(16)
  local column = line.note_columns[2]
  column.note_value = 2
  column.volume_value = 2

  local ptrack = patt:track(2)
  local line = ptrack:line(1)
  local column = line.effect_columns[1]
  column.number_value = 11
  column.amount_value = 11

  -- second pattern

  local patt_idx = rns.sequencer:pattern(2)
  local patt = rns.patterns[patt_idx]
  patt.number_of_lines = 16

  local ptrack = patt:track(1)
  local line = ptrack:line(16)
  local column = line.note_columns[1]
  column.note_value = 3
  column.volume_value = 3

  local ptrack = patt:track(2)
  local line = ptrack:line(16)
  local column = line.note_columns[2]
  column.note_value = 4
  column.volume_value = 4

  -- run tests ----------------------------------------------- 

  local notepos = xCursorPos{
    sequence = 1,
    track = 1,
    line = 1,
    column = 1,
  }

	assert(notepos.sequence == 1)
	assert(notepos.track == 1)
	assert(notepos.line == 1)
	assert(notepos.column == 1)

  local column,err = notepos:get_column()
  assert(column,"NoteColumn",err)
  assert(column.note_value == 1)
  assert(column.volume_value == 1)

  local notepos = xCursorPos{
    sequence = 1,
    track = 2,
    line = 16,
    column = 2,
  }

  local column,err = notepos:get_column()
  assert(column,"NoteColumn",err)
  assert(column.note_value == 2)
  assert(column.volume_value == 2)

  local notepos = xCursorPos{
    sequence = 1,
    track = 2,
    line = 1,
    column = 3,
  }

  local column,err = notepos:get_column()
  assert(column,"EffectColumn",err)
  assert(column.number_value == 11)
  assert(column.amount_value == 11)

  local notepos = xCursorPos{
    sequence = 2,
    track = 1,
    line = 16,
    column = 1,
  }
  local column,err = notepos:get_column()
  assert(column,"NoteColumn",err)
  assert(column.note_value == 3)
  assert(column.volume_value == 3)

  local notepos = xCursorPos{
    sequence = 2,
    track = 2,
    line = 16,
    column = 2,
  }
  local column,err = notepos:get_column()
  assert(column,"NoteColumn",err)
  assert(column.note_value == 4)
  assert(column.volume_value == 4)

  -- bad positions

  local notepos = xCursorPos{
    sequence = cLib.HUGE_INT,
    track = 2,
    line = 16,
    column = 2,
  }
  local column,err = notepos:get_column()
  assert(not column,"Unexpected match")

  local notepos = xCursorPos{
    sequence = 1,
    track = cLib.HUGE_INT,
    line = 16,
    column = 2,
  }
  local column,err = notepos:get_column()
  assert(not column,"Unexpected match")

  local notepos = xCursorPos{
    sequence = 1,
    track = 1,
    line = cLib.HUGE_INT,
    column = 2,
  }
  local column,err = notepos:get_column()
  assert(not column,"Unexpected match")

  local notepos = xCursorPos{
    sequence = 1,
    track = 1,
    line = 1,
    column = cLib.HUGE_INT, 
  }
  local column,err = notepos:get_column()
  assert(not column,"Unexpected match")


  -- copy via constructor  

  local notepos = xCursorPos{
    sequence = 1,
    track = 1,
    line = 1,
    column = 1,
  }

  local notepos = xCursorPos(notepos)

	assert(notepos.sequence == 1)
	assert(notepos.track == 1)
	assert(notepos.line == 1)
	assert(notepos.column == 1)

  local column,err = notepos:get_column()
  assert(column,"NoteColumn",err)
  assert(column.note_value == 1)
  assert(column.volume_value == 1)
  

  -- clean up -----------------------------------------------

  rns.sequencer:delete_sequence_at(1)
  rns.sequencer:delete_sequence_at(1)
  rns:delete_track_at(1)
  rns:delete_track_at(1)


  LOG(">>> xCursorPos: OK - passed all tests")

end
})
