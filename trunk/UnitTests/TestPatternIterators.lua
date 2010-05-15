--[[--------------------------------------------------------------------------
TestPatternIterators.lua
--------------------------------------------------------------------------]]--

--[[

The following iter functions are the ones that are defined in 
Renoise - exactly as provided below. They are copy & pasted for more
finetuning & testing, cause the internal LUA scripts are hard to
change and debug. Once you run this file, you'll override the internal
versions with the ones specified here...

--]]



------------------------------------------------------------------------------
-- make_note_column_iter

local function make_note_column_iter(song, line_iter, visible_columns_only)
  assert(type(line_iter) == 'function')
  visible_columns_only = visible_columns_only or false

  local pos, line = line_iter()

  if (pos == nil or line == nil) then
    return nil
  end

  local columns = line.note_columns
  local column_count = #columns

  if visible_columns_only then
    column_count = song.tracks[
      pos.track].visible_note_columns
  end


  -- we start by increasing the column
  pos.column = 0

  return function()
    pos.column = pos.column + 1

    if (pos.column <= column_count) then
      return pos, columns[pos.column]
    end

    -- loop until we found a line with visible columns
    while true do
      pos, line = line_iter()

      if (pos == nil or line == nil) then
        return nil
      end

      columns = line.note_columns
      column_count = #columns

      if visible_columns_only then
        column_count = song.tracks[
          pos.track].visible_note_columns
      end

      if (column_count > 0) then
        pos.column = 1
        return pos, columns[pos.column]
      end
    end

    return nil
  end
end


-- make_effect_column_iter

local function make_effect_column_iter(song, line_iter, visible_columns_only)
  assert(type(line_iter) == 'function')
  visible_columns_only = visible_columns_only or false
  
  local pos, line = line_iter()

  if (pos == nil or line == nil) then
    return nil
  end

  local columns = line.effect_columns
  local column_count = #columns

  if visible_columns_only then
    column_count = song.tracks[
      pos.track].visible_effect_columns
  end

  -- we start by increasing the column
  pos.column = 0

  return function()
    pos.column = pos.column + 1

    if (pos.column <= column_count) then
      return pos, columns[pos.column]
    end

    -- loop until we found a line with visible columns
    while true do
      pos, line = line_iter()

      if (pos == nil or line == nil) then
        return nil
      end

      columns = line.effect_columns
      column_count = #columns

      if visible_columns_only then
        column_count = song.tracks[
          pos.track].visible_effect_columns
      end

      if (column_count > 0) then
        pos.column = 1
        return pos, columns[pos.column]
      end
    end

    return nil
  end
end


------------------------------------------------------------------------------
-- renoise.PatternIterator:lines_in_song
------------------------------------------------------------------------------

function renoise.PatternIterator:lines_in_song(visible_patterns_only)
  visible_patterns_only = visible_patterns_only or true

  local pattern_order = {}
  if visible_patterns_only then
    local pattern_sequence = self.song.sequencer.pattern_sequence
    local referenced_patterns = {}

    for seq_index, pattern_index in pairs(pattern_sequence) do 
      if not referenced_patterns[pattern_index] then
        referenced_patterns[pattern_index] = true
        pattern_order[#pattern_order + 1] = pattern_index
      end
    end
  else
   for pattern_index = 1,#self.song.patterns do
     pattern_order[#pattern_order + 1] = pattern_index
   end
  end

  local pattern_order_index = 1
  local start_pos = { pattern = pattern_order[1], track = 1, line = 1 }
  local pos = { pattern = pattern_order[1], track = 1, line = 1 }

  local patterns = self.song.patterns
  local pattern = patterns[pos.pattern]
  local pattern_tracks = pattern.tracks
  local pattern_track = pattern_tracks[pos.track]

  -- we start by increasing the line
  start_pos.line = start_pos.line - 1
  pos.line = pos.line - 1

  local function line_iter()
    pos.line = pos.line + 1

    if pos.line > pattern.number_of_lines then
      pos.line = 1; pos.track = pos.track + 1

      if pos.track > #pattern_tracks then
        pos.track = 1; pattern_order_index = pattern_order_index + 1 

        if pattern_order_index > #pattern_order then
          -- completed: reset and stop
          pattern_order_index = 1
          pos.pattern = start_pos.pattern
          pos.track = start_pos.track
          pos.line = start_pos.line

          pattern = patterns[pos.pattern]
          pattern_tracks = pattern.tracks
          pattern_track = pattern_tracks[pos.track]
          return nil

        else
          -- new pattern
          pos.pattern = pattern_order[pattern_order_index]

         pattern = patterns[pos.pattern]
          pattern_tracks = pattern.tracks
          pattern_track = pattern_tracks[pos.track]
        end

      else
        -- new track
        pattern_track = pattern_tracks[pos.track]
      end

    else
      -- new line
    end

    return pos, pattern_track:line(pos.line)
  end

  return line_iter, self
end


-- note_columns_in_song

function renoise.PatternIterator:note_columns_in_song(visible_only)
  return make_note_column_iter(self.song, self:lines_in_song(
    visible_only), visible_only)
end


-- effect_columns_in_song

function renoise.PatternIterator:effect_columns_in_song(visible_only)
  return make_effect_column_iter(self.song, self:lines_in_song(
    visible_only), visible_only)
end


------------------------------------------------------------------------------
-- renoise.PatternIterator:lines_in_pattern
------------------------------------------------------------------------------

function renoise.PatternIterator:lines_in_pattern(pattern_index)
  assert(type(pattern_index) == 'number', ('pattern_index parameter: ' ..
    'expected an index (a number), got a \'%s\' object'):format(type(pattern_index)))

  local start_pos = { pattern = pattern_index, track = 1, line = 1 }
  local pos = { pattern = pattern_index, track = 1, line = 1 }

  local pattern = self.song.patterns[pos.pattern]
  local pattern_tracks = pattern.tracks
  local pattern_track = pattern_tracks[pos.track]

  -- we start by increasing the line
  start_pos.line = start_pos.line - 1
  pos.line = pos.line - 1

  local function line_iter()
    pos.line = pos.line + 1

    if pos.line > pattern.number_of_lines then
      pos.line = 1; pos.track = pos.track + 1

      if pos.track > #pattern_tracks then
        -- completed: reset and stop
        pos.track = start_pos.track
        pos.line = start_pos.line
        
        pattern_track = pattern_tracks[pos.track]
        return nil

      else
        -- new track
        pattern_track = pattern_tracks[pos.track]
      end

    else
      -- new line
    end

    return pos, pattern_track:line(pos.line)
  end

  return line_iter, self
end


-- note_columns_in_pattern

function renoise.PatternIterator:note_columns_in_pattern(pattern_index, visible_only)
  return make_note_column_iter(self.song, self:lines_in_pattern(
    pattern_index), visible_only)
end


-- effect_columns_in_pattern

function renoise.PatternIterator:effect_columns_in_pattern(pattern_index, visible_only)
  return make_effect_column_iter(self.song, self:lines_in_pattern(
    pattern_index), visible_only)
end


------------------------------------------------------------------------------
-- renoise.PatternIterator:lines_in_track
------------------------------------------------------------------------------

function renoise.PatternIterator:lines_in_track(track_index, visible_patterns_only)
  assert(type(track_index) == 'number', ('track_index parameter: ' ..
    'expected an index (a number), got a \'%s\' object'):format(type(track_index)))

  visible_patterns_only = visible_patterns_only or true
  
  local pattern_order = {}
  if visible_patterns_only then
    local pattern_sequence = self.song.sequencer.pattern_sequence
    local referenced_patterns = {}

    for seq_index, pattern_index in pairs(pattern_sequence) do 
      if not referenced_patterns[pattern_index] then
        referenced_patterns[pattern_index] = true
        pattern_order[#pattern_order + 1] = pattern_index
      end
    end
  else
   for pattern_index = 1,#self.song.patterns do
     pattern_order[#pattern_order + 1] = pattern_index
   end
  end

  local pattern_order_index = 1
  local start_pos = { pattern = pattern_order[1], track = track_index, line = 1 }
  local pos = { pattern = pattern_order[1], track = track_index, line = 1 }

  local patterns = self.song.patterns
  local pattern = patterns[pos.pattern]
  local pattern_tracks = pattern.tracks
  local pattern_track = pattern_tracks[pos.track]

  -- we start by increasing the line
  start_pos.line = start_pos.line - 1
  pos.line = pos.line - 1

  local function line_iter()
    pos.line = pos.line + 1

    if pos.line > pattern.number_of_lines then
      pos.line = 1; pattern_order_index = pattern_order_index + 1 

      if pattern_order_index > #pattern_order then
        -- completed: reset and stop
        pattern_order_index = 1
        pos.pattern = start_pos.pattern
        pos.line = start_pos.line

        pattern = patterns[pos.pattern]
        pattern_tracks = pattern.tracks
        pattern_track = pattern_tracks[pos.track]
        return nil

      else
        -- new pattern
        pos.pattern = pattern_order[pattern_order_index]

        pattern = patterns[pos.pattern]
        pattern_tracks = pattern.tracks
        pattern_track = pattern_tracks[pos.track]
      end

    else
      -- new line
    end

    return pos, pattern_track:line(pos.line)
  end

  return line_iter, self
end


-- note_columns_in_track

function renoise.PatternIterator:note_columns_in_track(track_index, visible_only)
  return make_note_column_iter(self.song, self:lines_in_track(
    track_index, visible_only), visible_only)
end


-- effect_columns_in_track

function renoise.PatternIterator:effect_columns_in_track(track_index, visible_only)
  return make_effect_column_iter(self.song, self:lines_in_track(
    track_index, visible_only), visible_only)
end


------------------------------------------------------------------------------
-- renoise.PatternIterator:lines_in_pattern_track
------------------------------------------------------------------------------

function renoise.PatternIterator:lines_in_pattern_track(pattern_index, track_index)
  assert(type(pattern_index) == 'number', ('pattern_index parameter: ' ..
    'expected an index (a number), got a \'%s\' object'):format(type(pattern_index)))
  assert(type(track_index) == 'number', ('track_index parameter: ' ..
    'expected an index (a number), got a \%s\ object'):format(type(track_index)))

  local start_pos = { pattern = pattern_index, track = track_index, line = 1 }
  local pos = { pattern = pattern_index, track = track_index, line = 1 }

  local pattern = self.song.patterns[pos.pattern]
  local pattern_tracks = pattern.tracks
  local pattern_track = pattern_tracks[pos.track]

  -- we start by increasing the line
  start_pos.line = start_pos.line - 1
  pos.line = pos.line - 1

  local function line_iter()
    pos.line = pos.line + 1

    if pos.line > pattern.number_of_lines then
      -- completed: reset and stop
      pos.line = start_pos.line
      return nil

    else
      -- new line
    end

    return pos, pattern_track:line(pos.line)
  end

  return line_iter, self
end


-- note_columns_in_pattern_track

function renoise.PatternIterator:note_columns_in_pattern_track(
    pattern_index, track_index, visible_only)
  return make_note_column_iter(self.song, self:lines_in_pattern_track(
    pattern_index, track_index), visible_only)
end


-- effect_columns_in_pattern_track

function renoise.PatternIterator:effect_columns_in_pattern_track(
 pattern_index, track_index, visible_only)
  return make_effect_column_iter(self.song, self:lines_in_pattern_track(
    pattern_index, track_index), visible_only)
end


--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--
