--[[--------------------------------------------------------------------------
TestPatterns.lua
--------------------------------------------------------------------------]]--

-- tools

local function assert_error(statement)
  assert(pcall(statement) == false, "expected function error")
end


-- shortcuts

local song = renoise.song()


------------------------------------------------------------------------------
-- Pattern

assert(renoise.Pattern.MAX_NUMBER_OF_LINES == 512)

assert(#song.patterns > 0)
local first_pattern = song.patterns[1]

first_pattern.name = "first pattern"
assert(first_pattern.name == "first pattern")

first_pattern.number_of_lines = 1
assert(first_pattern.number_of_lines == 1)

first_pattern.number_of_lines = 0x40

assert_error(function()
  first_pattern.number_of_lines = 0x0
end)

assert_error(function()
  first_pattern.number_of_lines = 1024
end)

song.selected_pattern_index = 1
assert(song.selected_pattern.name == first_pattern.name)


------------------------------------------------------------------------------
-- PatternTrack

local first_pattern_track = first_pattern.tracks[1]
assert(#first_pattern.tracks == #song.tracks)

song.selected_pattern_index = 1
song.selected_track_index = 1

first_pattern.tracks[1].lines[2].note_columns[1].note_value = 67
assert(song.selected_pattern_track.lines[2].note_columns[1].note_value == 67)


------------------------------------------------------------------------------
-- PatternLine

local first_line = first_pattern_track.lines[1]
assert(#first_pattern_track.lines == first_pattern.number_of_lines)

assert(first_pattern_track:line(1) == first_line)

assert(first_pattern_track:lines_in_range(1, 1)[1] == first_line)
assert(#first_pattern_track:lines_in_range(1, 2) == 2)

assert_error(function()
  first_pattern_track:line(renoise.Pattern.MAX_NUMBER_OF_LINES + 1)
end)
assert_error(function()
  first_pattern_track:line()
end)

assert_error(function()
  first_pattern_track:lines_in_range(2, 1)
end)
assert_error(function()
  first_pattern_track:lines_in_range(1, renoise.Pattern.MAX_NUMBER_OF_LINES + 1)
end)


-- notecolumn access

first_line.note_columns[1].note_value = 48
assert(first_pattern_track.lines[1].note_columns[1].note_value == 48)

first_line.note_columns[1].note_value = renoise.PatternTrackLine.NOTE_OFF
assert_error(function()
  first_line.note_columns[1].note_value = renoise.PatternTrackLine.EMPTY_NOTE + 1
end)

local first_note_column = first_line.note_columns[1]
first_note_column.note_value = 49
assert(first_pattern_track.lines[1].note_columns[1].note_value == 49)

first_line.note_columns[1].instrument_value = 0x2
assert(first_pattern_track.lines[1].note_columns[1].instrument_value == 0x2)
assert_error(function()
  first_line.note_columns[1].instrument_value = 257
end)

first_line.note_columns[1].volume_value = 0x40
assert(first_pattern_track.lines[1].note_columns[1].volume_value == 0x40)
assert_error(function()
  first_line.note_columns[1].volume_value = -1
end)

first_line.note_columns[1].panning_value = 0x80
assert(first_pattern_track.lines[1].note_columns[1].panning_value == 0x80)
assert_error(function()
  first_line.note_columns[1].panning_value = "abc"
end)

song.tracks[1].visible_note_columns = 2
song.selected_line_index = 8
song.selected_note_column_index = 2


-- notecolumn serialization

first_note_column.note_value = 88
first_note_column.note_string = "---"
assert(first_note_column.note_value == 
  renoise.PatternTrackLine.EMPTY_NOTE)

first_note_column.note_string = "C#4"
assert(first_note_column.note_string == "C#4")
assert(first_note_column.note_value == 49)
assert_error(function()
  first_note_column.note_string = "C94"
end)

first_note_column.instrument_value = 0x02
first_note_column.instrument_string = ".."
assert(first_note_column.instrument_value == 
  renoise.PatternTrackLine.EMPTY_INSTRUMENT)
first_note_column.instrument_string = ""
assert(first_note_column.instrument_value == 
  renoise.PatternTrackLine.EMPTY_INSTRUMENT)
  
first_note_column.instrument_string = "01"
assert(first_note_column.instrument_string == "01")
assert(first_note_column.instrument_value == 0x1)

first_note_column.volume_value = 0xF8
first_note_column.volume_string = ".."
assert(first_note_column.volume_value ==
  renoise.PatternTrackLine.EMPTY_VOLUME)
assert_error(function()
  first_note_column.volume_string = "JJ"
end)

first_note_column.volume_string = "2F"
assert(first_note_column.volume_string == "2F")

first_note_column.panning_value = 0x66
first_note_column.panning_string = ".."
assert(first_note_column.panning_value ==
  renoise.PatternTrackLine.EMPTY_PANNING)
assert_error(function()
  first_note_column.panning_string = "1"
end)

first_note_column.panning_string = "F2"
assert(first_note_column.panning_string == "F2")

first_note_column.delay_value = 0x23
first_note_column.delay_string = ".."
assert(first_note_column.delay_value ==
  renoise.PatternTrackLine.EMPTY_DELAY)
assert_error(function()
  first_note_column.delay_string = "--"
end)
  
first_note_column.delay_string = "a1"
assert(first_note_column.delay_string == "A1")
  
  
-- effectcolumn access

first_line.effect_columns[1].number_value = 0x66
assert(first_pattern_track.lines[1].effect_columns[1].number_value == 0x66)

first_line.effect_columns[1].amount_value = 0x55
assert(first_pattern_track.lines[1].effect_columns[1].amount_value == 0x55)


-- effectcolumn serialization

first_line.effect_columns[1].number_value = 0x12
first_line.effect_columns[1].number_string = ".."
assert(first_line.effect_columns[1].number_value == 
  renoise.PatternTrackLine.EMPTY_EFFECT_NUMBER)
first_line.effect_columns[1].number_string = "42"
assert(first_line.effect_columns[1].number_string == "42")
assert(first_line.effect_columns[1].number_value == 0x42)
assert_error(function()
  first_line.effect_columns[1].number_string = "8"
end)

first_line.effect_columns[1].amount_value = 0x99
first_line.effect_columns[1].amount_string = ".."
assert(first_line.effect_columns[1].amount_value == 
  renoise.PatternTrackLine.EMPTY_EFFECT_AMOUNT)
first_line.effect_columns[1].amount_string = "FF"
assert(first_line.effect_columns[1].amount_string == "FF")
assert(first_line.effect_columns[1].amount_value == 0xFF)
assert_error(function()
  first_line.effect_columns[1].amount_string = "123"
end)


-- empty / clear

assert(not first_line.is_empty)
assert(not first_line.note_columns[1].is_empty)
assert(not first_line.effect_columns[1].is_empty)

first_line:clear()

assert(first_line.is_empty)
assert(first_line.note_columns[1].is_empty)
assert(first_line.effect_columns[1].is_empty)


assert(first_line.note_columns[1].note_value ==
  renoise.PatternTrackLine.EMPTY_NOTE)
assert(first_line.note_columns[1].instrument_value ==
  renoise.PatternTrackLine.EMPTY_INSTRUMENT)
assert(first_line.note_columns[1].volume_value ==
  renoise.PatternTrackLine.EMPTY_VOLUME)
assert(first_line.note_columns[1].panning_value ==
  renoise.PatternTrackLine.EMPTY_PANNING)
assert(first_line.note_columns[1].delay_value ==
  renoise.PatternTrackLine.EMPTY_DELAY)

assert(first_line.effect_columns[1].number_value ==
  renoise.PatternTrackLine.EMPTY_EFFECT_NUMBER)
assert(first_line.effect_columns[1].amount_value ==
  renoise.PatternTrackLine.EMPTY_EFFECT_AMOUNT)


-- unlinked column creation

assert_error(function() -- not allowed
  new_effect_column = renoise.EffectColumn()
end)


-- iteration

for i,line in ipairs(first_pattern_track.lines) do
  if (i % 4 == 0) then
    line.note_columns[1].note_value = 48 + i
    line.note_columns[1].instrument_value = math.random(0, 128)
    line.note_columns[1].volume_value = math.random(0, 128)
  end

  line.effect_columns[1].number_value = math.random(0, 255)
  line.effect_columns[1].amount_value = i
end

first_line.note_columns[1].note_value = 48
first_line.note_columns[1].volume_value = 0x20


-- master/send track column limits

local sequence_track_index = 1
local master_track_index = -1
local send_track_index = -1

for index,track in ipairs(song.tracks) do
  if track.type == renoise.Track.TRACK_TYPE_MASTER then
    master_track_index = index
  elseif track.type == renoise.Track.TRACK_TYPE_SEND then
    send_track_index = index
  end
end

assert(#first_pattern.tracks[sequence_track_index].lines[1].effect_columns ==
  song.tracks[sequence_track_index].max_effect_columns)
assert(#first_pattern.tracks[sequence_track_index].lines[1].note_columns ==
  song.tracks[sequence_track_index].max_note_columns)

assert(#first_pattern.tracks[master_track_index].lines[1].effect_columns ==
  song.tracks[master_track_index].max_effect_columns)
assert(#first_pattern.tracks[master_track_index].lines[1].note_columns ==
  song.tracks[master_track_index].max_note_columns)

if send_track_index ~= -1 then
  assert(#first_pattern.tracks[send_track_index].lines[1].effect_columns ==
    song.tracks[send_track_index].max_effect_columns)
  assert(#first_pattern.tracks[send_track_index].lines[1].note_columns ==
     song.tracks[send_track_index].max_note_columns)
end


------------------------------------------------------------------------------
-- Pattern copy

song.sequencer.pattern_sequence = {1, 2}
song.patterns[1]:clear()
song.patterns[2]:clear()

assert(song.patterns[1].is_empty and song.patterns[1].is_empty)

song.patterns[1].tracks[2].lines[8].effect_columns[1].number_value = 22
song.patterns[1].tracks[2].lines[5].effect_columns[1].amount_value = 22

song.patterns[1].tracks[1].lines[2].note_columns[2].note_value = 32
song.patterns[1].tracks[1].lines[19].note_columns[2].instrument_value = 12

assert(not song.patterns[1].is_empty and song.patterns[2].is_empty)

song.patterns[2].tracks[2]:copy_from(song.patterns[1].tracks[2])

assert(not song.patterns[1].is_empty and not song.patterns[2].is_empty)
song.patterns[2]:clear()
assert(not song.patterns[1].is_empty and song.patterns[2].is_empty)

song.patterns[2]:copy_from(song.patterns[1])
assert(not song.patterns[1].is_empty and not song.patterns[2].is_empty)



------------------------------------------------------------------------------
-- test finalizers

collectgarbage()


--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--
