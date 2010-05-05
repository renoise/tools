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
-- pattern_line_song_iter

function renoise.Song:pattern_line_song_iter()
  local start_pos = { pattern = 1, track = 1, line = 1 }
  local pos = { pattern = 1, track = 1, line = 1 }

  local patterns = self.patterns
  local pattern = patterns[pos.pattern]
  local pattern_tracks = pattern.tracks
  local pattern_track = pattern_tracks[pos.track]
  local pattern_track_lines = pattern_track.lines

  -- we start by increasing the line
  start_pos.line = start_pos.line - 1
  pos.line = pos.line - 1

  local function line_iter()
    pos.line = pos.line + 1

    if pos.line > #pattern_track_lines then
      pos.line = 1; pos.track = pos.track + 1

      if pos.track > #pattern_tracks then
        pos.track = 1; pos.pattern = pos.pattern + 1

        if pos.pattern > #patterns then
          -- completed: reset and stop
          pos.pattern = start_pos.pattern
          pos.track = start_pos.track
          pos.line = start_pos.line

          pattern = patterns[pos.pattern]
          pattern_tracks = pattern.tracks
          pattern_track = pattern_tracks[pos.track]
          pattern_track_lines = pattern_track.lines

          return nil

        else
          -- new pattern
          pattern = patterns[pos.pattern]
          pattern_tracks = pattern.tracks
          pattern_track = pattern_tracks[pos.track]
          pattern_track_lines = pattern_track.lines
        end

      else
        -- new track
        pattern_track = pattern_tracks[pos.track]
        pattern_track_lines = pattern_track.lines
      end

    else
      -- new line
    end

    return pos, pattern_track_lines[pos.line]
  end

return line_iter, self
end


------------------------------------------------------------------------------
-- pattern_line_pattern_iter

function renoise.Song:pattern_line_pattern_iter(pattern_index)
  local start_pos = { pattern = pattern_index, track = 1, line = 1 }
  local pos = { pattern = pattern_index, track = 1, line = 1 }

  local pattern = self.patterns[pos.pattern]
  local pattern_tracks = pattern.tracks
  local pattern_track = pattern_tracks[pos.track]
  local pattern_track_lines = pattern_track.lines

  -- we start by increasing the line
  start_pos.line = start_pos.line - 1
  pos.line = pos.line - 1

  local function line_iter()
    pos.line = pos.line + 1

    if pos.line > #pattern_track_lines then
      pos.line = 1; pos.track = pos.track + 1

      if pos.track > #pattern_tracks then
        -- completed: reset and stop
        pos.track = start_pos.track
        pos.line = start_pos.line

        pattern_track = pattern_tracks[pos.track]
        pattern_track_lines = pattern_track.lines

        return nil

      else
        -- new track
        pattern_track = pattern_tracks[pos.track]
        pattern_track_lines = pattern_track.lines
      end

    else
      -- new line
    end

    return pos, pattern_track_lines[pos.line]
  end

return line_iter, self
end


------------------------------------------------------------------------------
-- pattern_line_track_iter

function renoise.Song:pattern_line_track_iter(track_index)
  local start_pos = { pattern = 1, track = track_index, line = 1 }
  local pos = { pattern = 1, track = track_index, line = 1 }

  local patterns = self.patterns
  local pattern = patterns[pos.pattern]
  local pattern_tracks = pattern.tracks
  local pattern_track = pattern_tracks[pos.track]
  local pattern_track_lines = pattern_track.lines

  -- we start by increasing the line
  start_pos.line = start_pos.line - 1
  pos.line = pos.line - 1

  local function line_iter()
    pos.line = pos.line + 1

    if pos.line > #pattern_track_lines then
      pos.line = 1;
      pos.pattern = pos.pattern + 1

      if pos.pattern > #patterns then
        -- completed: reset and stop
        pos.pattern = start_pos.pattern
        pos.line = start_pos.line

        pattern = patterns[pos.pattern]
        pattern_tracks = pattern.tracks
        pattern_track = pattern_tracks[pos.track]
        pattern_track_lines = pattern_track.lines

        return nil

      else
        -- new pattern
        pattern = patterns[pos.pattern]
        pattern_tracks = pattern.tracks
        pattern_track = pattern_tracks[pos.track]
        pattern_track_lines = pattern_track.lines
      end

    else
      -- new line
    end

    return pos, pattern_track_lines[pos.line]
  end

return line_iter, self
end


------------------------------------------------------------------------------
-- pattern_line_pattern_track_iter

function renoise.Song:pattern_line_pattern_track_iter(pattern_index, track_index)
  local start_pos = { pattern = pattern_index, track = track_index, line = 1 }
  local pos = { pattern = pattern_index, track = track_index, line = 1 }

  local pattern = self.patterns[pos.pattern]
  local pattern_tracks = pattern.tracks
  local pattern_track = pattern_tracks[pos.track]
  local pattern_track_lines = pattern_track.lines

  -- we start by increasing the line
  start_pos.line = start_pos.line - 1
  pos.line = pos.line - 1

  local function line_iter()
    pos.line = pos.line + 1

    if pos.line > #pattern_track_lines then
      -- completed: reset and stop
      pos.line = start_pos.line
      return nil

    else
      -- new line
    end

    return pos, pattern_track_lines[pos.line]
  end

return line_iter, self
end


--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--
