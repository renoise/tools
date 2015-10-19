--[[============================================================================
xStream
============================================================================]]--
--[[

  This class can track playback progression in a song simply by supplying 
  a steady flow of song-position changes (idle loop)

]]


class 'xStreamPos'

-------------------------------------------------------------------------------

function xStreamPos:__init()

  -- (renoise.SongPos) monitor changes to playback 
  self.playpos = rns.transport.playback_pos

  -- (xSongPos) created by the start() method, this is where
  -- we keep the overall progression of the stream 
  self.writepos = xSongPos(rns.transport.playback_pos)

  -- (int) supply this number - it's used for deciding when we are
  -- approaching the boundary of a pattern/block 
  self.writeahead = nil

  -- number, or 0 if undefined
  -- this is a short-lived timestamp indicating that we should ignore 
  -- changes to the playback position, right after playback has started
  -- (the fuzziness is due to API living in separate thread)
  self.just_started_playback = property(self.get_just_started_playback,self.set_just_started_playback)
  self.just_started_playback_observable = renoise.Document.ObservableNumber(0)

  -- function, define a function to call when it's time for output
  self.callback_fn = nil

end

-------------------------------------------------------------------------------

function xStreamPos:start()

  if rns.transport.playing then
    if not self.just_started_playback then
      -- when already playing, start from next line
      self.writepos = xSongPos(rns.transport.playback_pos)
      self.writepos.lines_travelled = -1
      self.writepos:increase_by_lines(1)
    else
      self.writepos = xSongPos(rns.transport.playback_pos)
    end
  else
    self.writepos = xSongPos(rns.transport.edit_pos)
  end

end


-------------------------------------------------------------------------------

function xStreamPos:play()

  if not rns.transport.playing then
    rns.transport:start_at(self.writepos.line)
  end
  self.just_started_playback = os.clock()

end


-------------------------------------------------------------------------------

function xStreamPos:get_just_started_playback()
  return self.just_started_playback_observable.value
end

function xStreamPos:set_just_started_playback(val)
  self.just_started_playback_observable.value = val
end

-------------------------------------------------------------------------------
-- Update the write position as a result of a changed playback position.
-- Most of the time we want the stream to continue smoothly forward - this is
-- true for any kind of pattern, sequence or block loop. However, when we
-- detect 'user' events, the position can also jump backwards (the detection
-- of these events is not entirely reliable near loop boundaries)
-- @param pos, renoise.SongPos

function xStreamPos:set_pos(pos)
  TRACE("xStreamPos:set_pos(pos)",pos)

  local num_lines = 0
  local near_lines_def = self.writeahead

  local near_top = function(line)
    return (line <= near_lines_def) and true or false
  end

  local near_end = function(line,patt_lines)
    return (line >= (patt_lines-near_lines_def))
  end

  if (pos.sequence == self.playpos.sequence) then
    -- within same pattern
    if (pos.line < self.playpos.line) then
      -- earlier line in pattern
      --print("*** same pattern, wrap around ------------------------------------------")

      local num_lines, xblock, block_num_lines
      if rns.transport.loop_block_enabled then
        xblock = xBlockLoop.get()
        block_num_lines = xblock.end_line - xblock.start_line + 1
      end

      local patt_num_lines = xSongPos.get_pattern_num_lines(self.playpos.sequence)
      if near_top(pos.line) and near_end(self.playpos.line,patt_num_lines) then
        -- conclusion: pattern loop
        num_lines = (patt_num_lines-self.playpos.line) + pos.line
        self.writepos:increase_by_lines(num_lines)
        --print("*** *** same pattern, wrap around - pattern loop",num_lines)
      elseif rns.transport.loop_block_enabled and
        near_top(pos.line-xblock.start_line) and 
          near_end(xblock.end_line-xblock.start_line,block_num_lines)
      then
        -- conclusion: block loop
        num_lines = (xblock.end_line-self.playpos.line) + (pos.line-xblock.start_line) + 1
        self.writepos:increase_by_lines(num_lines)

        --print("*** same pattern, wrap around - loop block",block_num_lines,num_lines)
      else
        -- conclusion: user navigation
        -- will repeat/rewind to earlier position 
        num_lines = self.playpos.line - pos.line
        self.writepos:decrease_by_lines(num_lines)
        --print("*** same pattern, wrap around - user - pos",pos,"self.playpos",self.playpos)
      end

    elseif (pos.line > self.playpos.line) then
      -- normal progression through pattern
      self.writepos:increase_by_lines(pos.line - self.playpos.line)
      --print("*** same pattern, self.writepos POST",pos.line - self.playpos.line,self.writepos)
    end
  elseif (pos.sequence < self.playpos.sequence) then
    -- earlier pattern, usually caused by seq-loop or song boundary
      --print("*** earlier pattern ------------------------------------------")

    -- special case: if the pattern was deleted from the song, the cached
    -- playpos is referring to a non-existing pattern - in such a case,
    -- we re-initialize the cached playpos to the current position
    if not rns.sequencer.pattern_sequence[self.playpos.sequence] then
      LOG("Missing pattern sequence - was removed from song?")
      self.playpos = rns.transport.playback_pos
    end

    local patt_num_lines = xSongPos.get_pattern_num_lines(self.playpos.sequence)

    -- the old position is near the end of the pattern
    -- use the writeahead as the basis for this calculation

    if (self.playpos.line >= (patt_num_lines-near_lines_def)) then
      -- conclusion: we've reached the end of the former pattern 
      -- difference is the remaning lines in old position plus the current line 
      local num_lines = (patt_num_lines-self.playpos.line)+pos.line
      self.writepos:increase_by_lines(num_lines)
      self.writepos.sequence = pos.sequence
      --print("earlier pattern - end of former pattern - increase by lines",num_lines,pos,self.playpos)
    else
      -- conclusion: we've changed the position manually, somehow
      -- disregard the sequence and just use the lines
      local num_lines = pos.line-self.playpos.line
      self.writepos:increase_by_lines(num_lines)
      self.writepos.sequence = pos.sequence
      --print("earlier pattern - changed manually - increase by lines",num_lines,pos,self.playpos)
    end

  else
    -- later pattern
    --print("next pattern, pos,self.playpos",pos,self.playpos)
    local num_lines = xSongPos.get_line_diff(pos,self.playpos)
    self.writepos:increase_by_lines(num_lines)
    --print("next pattern, calculate num_lines",num_lines)

  end
  
  -- call output function - i.e. do_output(self.writepos,nil,true)
  if self.callback_fn then
    self.callback_fn()
  end

end

-------------------------------------------------------------------------------
-- This function is designed to be called in an idle loop

function xStreamPos:track_pos()
  TRACE("xStreamPos:track_pos()")

  local playpos = rns.transport.playback_pos
  local editpos = rns.transport.edit_pos
  if rns.transport.playing then
    if (self.just_started_playback > 0) then
      if (0.2 > (os.clock() - self.just_started_playback)) then
        self.just_started_playback = 0
        --print("just_started_playback gone...")
      end
    else
      if (playpos ~= self.playpos) then
        --print("on_idle - playpos changed...",playpos,self.playpos)
        self:set_pos(playpos)
      end
    end
  else
    -- paused playback, do not output 
  end
  if (self.just_started_playback == 0) then
    self.playpos = playpos
  end

end

-------------------------------------------------------------------------------
-- call when a new document becomes available

function xStreamPos:attach_to_song()

  -- handling changes via observable is quicker than idle notifier
  rns.selected_pattern_index_observable:add_notifier(function()
    --print("pattern_index_notifier fired...")
    local playpos = rns.transport.playback_pos
    self:set_pos(playpos)
    self.playpos = playpos
  end)

  -- track when song is started and stopped
  rns.transport.playing_observable:add_notifier(function()
    --print("xStream playing_notifier fired...")
    if rns.transport.playing then
      self.just_started_playback = os.clock()
      self.playpos = rns.transport.playback_pos
    end
  end)

end


