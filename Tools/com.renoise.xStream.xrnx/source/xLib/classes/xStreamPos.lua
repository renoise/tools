--[[============================================================================
xStream
============================================================================]]--

--[[--

This class can track playback progression in a song
.
#

### How to use

Create an instance, and supply it with a steady flow of song-position changes (idle loop). 

### Requires
@{xPlayPos}
@{xSongPos}
@{xBlockLoop}

]]


class 'xStreamPos'

-------------------------------------------------------------------------------

function xStreamPos:__init()
  TRACE("xStreamPos:__init()")

  --- (xPlayPos) precise playback position
  self.playpos = xPlayPos()

  --- (xSongPos) overall progression of the stream 
  self.writepos = xSongPos(rns.transport.playback_pos)

  --- (xSongPos) where we most recently read from the pattern
  self.readpos = xSongPos(rns.transport.playback_pos)

  --- (xBlockLoop)
  self.xblock = nil

  --- bool, track changes to loop_block_enabled
  -- TODO refactor into xBlockloop
  self.block_enabled = rns.transport.loop_block_enabled
  self.block_start_pos = rns.transport.loop_block_start_pos
  self.block_range_coeff = rns.transport.loop_block_range_coeff

  --- int, decrease this if you are experiencing dropouts during heavy UI
  -- operations in Renoise (such as opening a plugin GUI) 
  self.writeahead_factor = property(self.get_writeahead_factor,self.set_writeahead_factor)
  self.writeahead_factor_observable = renoise.Document.ObservableNumber(300)

  --- (int) 0 if undefined
  -- implementation should supply this number - used for deciding when 
  -- we are approaching the boundary of a pattern/block 
  self.writeahead = property(self.get_writeahead,self.set_writeahead)
  self.writeahead_observable = renoise.Document.ObservableNumber(0)

  --- number, or 0 if undefined
  -- this is a short-lived timestamp indicating that we should ignore 
  -- changes to the playback position, right after playback has started
  -- (the fuzziness is due to API living in separate thread)
  self.just_started_playback = property(self.get_just_started_playback,self.set_just_started_playback)
  self.just_started_playback_observable = renoise.Document.ObservableNumber(0)

  --- function, define a function to call when it's time for output
  self.callback_fn = nil

  --- function, called when we need fresh content
  -- (i.e. when the position has been changed by the user, and 
  -- previously produced content no longer would be valid...)
  self.refresh_fn = nil

end

-------------------------------------------------------------------------------

function xStreamPos:reset()
  TRACE("xStreamPos:reset()")

  self.playpos = xPlayPos()
  if rns.transport.playing then
    self.readpos = xSongPos(rns.transport.playback_pos)
    self.writepos = xSongPos(rns.transport.playback_pos)
  else
    self.readpos = xSongPos(rns.transport.edit_pos)
    self.writepos = xSongPos(rns.transport.edit_pos)
  end
  --print("xStreamPos reset() - self.writepos",self.writepos)

end

-------------------------------------------------------------------------------

function xStreamPos:start()
  TRACE("xStreamPos:start()")

  self:reset()

  if rns.transport.playing then
    if not self.just_started_playback then
      --print(">>> xStreamPos:start - already playing")
      self.writepos.lines_travelled = -1
      self.writepos:increase_by_lines(1)
      self.readpos:increase_by_lines(1)
    else
      --print(">>> xStreamPos:start - playback just started ")
      self.readpos:increase_by_lines(1)
    end
  else
    --print(">>> xStreamPos:start - from stopped state")
    self.readpos:increase_by_lines(1)
  end

end


-------------------------------------------------------------------------------

function xStreamPos:play()
  TRACE("xStreamPos:play()")

  if not rns.transport.playing then
    rns.transport:start_at(self.writepos.line)
  end
  self.just_started_playback = os.clock()

end


-------------------------------------------------------------------------------

function xStreamPos:get_writeahead()
  return self.writeahead_observable.value
end

function xStreamPos:set_writeahead(val)
  self.writeahead_observable.value = val
  if self.xblock then
    self.xblock.writeahead = val
  end
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
-- detect 'user events', the position can also jump backwards
-- @param pos (renoise.SongPos), the playback position

function xStreamPos:_set_pos(pos)
  TRACE("xStreamPos:_set_pos(pos)",pos)

  local near_patt_top = function(line)
    return (line <= self.writeahead) and true or false
  end
  local near_patt_end = function(line,patt_lines)
    return (line >= (patt_lines-self.writeahead))
  end

  if rns.transport.loop_block_enabled then
    self:create_xblock()
  end

  if (pos.sequence == self.playpos.sequence) then
    -- within same pattern
    if (pos.line < self.playpos.line) then
      --print("*** earlier line in pattern --",pos,self.playpos)

      local patt_num_lines = xSongPos.get_pattern_num_lines(self.playpos.sequence)
      if near_patt_top(pos.line) 
        and near_patt_end(self.playpos.line,patt_num_lines) 
      then
        -- conclusion: pattern loop
        local num_lines = (patt_num_lines-self.playpos.line) + pos.line
        self.writepos:increase_by_lines(num_lines)
        --print("*** same pattern, wrap around - pattern loop",num_lines)
      elseif rns.transport.loop_block_enabled 
        and self.xblock 
        and self.xblock:pos_near_top(pos.line)  
        and self.xblock:pos_near_end(self.playpos.line) 
      then -- conclusion: block loop (enabled)
        local num_lines = (self.xblock.end_line-self.playpos.line) + (pos.line-self.xblock.start_line) + 1
        self.writepos:increase_by_lines(num_lines)
        --print("*** same pattern, wrap around - loop block (ON)",self.xblock.length,self.writepos)
      elseif not rns.transport.loop_block_enabled 
        and self.xblock 
        and self.xblock:pos_near_end(self.playpos.line)  
      then -- conclusion: block loop (disabled)
        --print("*** same pattern, wrap around - loop block (OFF)",self.xblock.length,self.writepos)
      else
        -- conclusion: "crazy navigation"
        --print("*** same pattern, wrap around - user navigation")
        self:reset()
        if self.refresh_fn then
          self.refresh_fn()
        end
      end

    elseif (pos.line > self.playpos.line) then
      --print("*** forward progression -- pos,self.playpos",pos,self.playpos)

      -- forward progression through pattern - 
      -- figure out how many lines we have progressed
      local line_diff = pos.line - self.playpos.line
      --print("*** line_diff",line_diff,pos,"playpos",self.playpos,"writepos",self.writepos,"readpos",self.readpos)

      -- always update write-pos 
      self.writepos:increase_by_lines(line_diff)

      -- more than writeahead indicates gaps or forward navigation 
      -- (such as when pressing page down while streaming...)
      if (line_diff >= self.writeahead) then
        --print("*** xStreamPos - gap or forward navigation, line_diff=",line_diff)
        self.readpos:increase_by_lines(line_diff-self.writeahead)
        if self.refresh_fn then
          self.refresh_fn()
        end
      end

    end
  elseif (pos.sequence < self.playpos.sequence) then
    -- earlier pattern, usually caused by seq-loop or song boundary
    --print("*** earlier pattern ------------------------------------------")

    -- special case: if the pattern was deleted from the song, the cached
    -- playpos is referring to a non-existing pattern - in such a case,
    -- we re-initialize the cached playpos to the current position
    if not rns.sequencer.pattern_sequence[self.playpos.sequence] then
      --print("*** xStreamPos - missing pattern sequence - was removed from song?")
      self.playpos:set(rns.transport.playback_pos)
    end

    local patt_num_lines = xSongPos.get_pattern_num_lines(self.playpos.sequence)
    -- the old position is near the end of the pattern
    -- use the writeahead as the basis for this calculation
    if (self.playpos.line >= (patt_num_lines-self.writeahead)) then
      -- conclusion: we've reached the end of the former pattern 
      -- difference is the remaning lines in old position plus the current line 
      local num_lines = (patt_num_lines-self.playpos.line)+pos.line
      self.writepos:increase_by_lines(num_lines)
      --self.writepos.sequence = pos.sequence-1
      --print("*** earlier pattern - end of former pattern - increase by lines",num_lines,pos,self.playpos)
    else
      -- conclusion: we've changed the position manually, somehow
      -- disregard the sequence and just use the lines
      local num_lines = pos.line-self.playpos.line
      self.writepos:increase_by_lines(num_lines)
      self.writepos.sequence = pos.sequence
      if not self.readpos then
        -- ?? why does this happen 
        --print("*** xStreamPos - missing readpos in _set_pos()")
        self.readpos = xSongPos(rns.transport.playback_pos)
      end
      self.readpos.sequence = pos.sequence
      self.readpos.lines_travelled = self.readpos.lines_travelled-self.writeahead
      --print("*** earlier pattern - changed manually - increase by lines",num_lines,pos,self.playpos)
      if self.refresh_fn then
        self.refresh_fn()
      end
    end

  else
    -- later pattern
    --print("*** next pattern, pos,self.playpos",pos,self.playpos)
    local num_lines = xSongPos.get_line_diff(pos,self.playpos:get())
    self.writepos:increase_by_lines(num_lines)
  end
  
  if self.callback_fn then
    self.callback_fn()
  end

  self.playpos:set(pos)

end

-------------------------------------------------------------------------------

function xStreamPos:create_xblock()
  TRACE("xStreamPos:create_xblock()")

  self.xblock = xBlockLoop{
    writeahead = self.writeahead
  }

end

-------------------------------------------------------------------------------
-- This function is designed to be called in an idle loop

function xStreamPos:track_pos()
  TRACE("xStreamPos:track_pos()")

  local playpos = rns.transport.playback_pos

  local prev_block = function()
    --print(">>> prev_block")
    -- move read-pos back to block start point
    local travelled = self.readpos.lines_travelled
    self.readpos:decrease_by_lines(self.xblock.length)
    --print(">>> block loop ON - self.readpos #2",self.readpos)

    -- can result in negative value ??? 
    self.readpos.line = self.readpos:enforce_block_boundary("decrease",self.readpos.line,-self.writeahead)
    --print(">>> block loop ON - self.readpos #3",self.readpos)

    self.readpos.lines_travelled = travelled-self.writeahead
    if self.refresh_fn then
      self.refresh_fn()
    end

  end

  local next_block = function()
    --print(">>> next_block")
    if self.readpos then
      local travelled = self.readpos.lines_travelled
      self.readpos:increase_by_lines(self.xblock.length-self.writeahead)
      self.readpos.lines_travelled = travelled-self.writeahead
      if self.refresh_fn then
        self.refresh_fn()
      end
    end
  end

  -- track when blockloop changes (update scheduling)
  if (self.block_enabled ~= rns.transport.loop_block_enabled) then
    --print("*** xStreamPos - block_enabled changed...")
    self.block_enabled = rns.transport.loop_block_enabled

    if self.block_enabled then
      self:create_xblock()
    end

    local within = false
    if self.xblock then
      within = (self.playpos.line >= self.xblock.start_line) and 
        (self.playpos.line <= self.xblock.end_line) 
    end

    if within and self.xblock:pos_near_end(self.playpos.line) then
      if self.block_enabled then
        --print(">>> block loop ON - self.readpos #1",self.readpos)
        prev_block()
      elseif self.xblock then
        --print(">>> block loop OFF ")
        next_block()
      end
    end

    if not self.block_enabled and self.xblock then
      self.xblock = nil
    end

  end

  if (self.block_start_pos ~= rns.transport.loop_block_start_pos) then
    if rns.transport.loop_block_enabled and
      self.xblock --and self.xblock:pos_near_end(self.playpos.line) 
    then
      local next_block_start_line = (self.block_start_pos.line+self.xblock.length)
      local prev_block_start_line = (self.block_start_pos.line-self.xblock.length)
      if (next_block_start_line == rns.transport.loop_block_start_pos.line) then
        --print("next block")
        next_block()
      elseif (prev_block_start_line == rns.transport.loop_block_start_pos.line) then
        --print("previous block")
        prev_block()
        -- update writepos, as Renoise changes the cursor when 
        -- moving to previous loop block ... 
        self.writepos.line = self.writepos.line-(self.playpos.line-playpos.line)
      end
    end
    self.block_start_pos = rns.transport.loop_block_start_pos
  end

  if (self.block_range_coeff ~= rns.transport.loop_block_range_coeff) then
    --print(">>> xStreamPos - block_range_coeff changed...")
    -- TODO refresh read buffer if affected by size change
    self.block_range_coeff = rns.transport.loop_block_range_coeff
  end

  -- after this point, content can be written -------------

  if rns.transport.playing then
    if (self.just_started_playback > 0) then
      if (0.2 > (os.clock() - self.just_started_playback)) then
        self.just_started_playback = 0
      end
    end
  end

  if (self.just_started_playback == 0) then
    if (playpos ~= self.playpos:get()) then
      self:_set_pos(playpos)
    end
  end


end

-------------------------------------------------------------------------------
-- call when a new document becomes available

function xStreamPos:attach_to_song()
  TRACE("xStreamPos:attach_to_song()")

  -- handling changes via observable is quicker than idle notifier
  rns.selected_pattern_index_observable:add_notifier(function()
    --print("pattern_index_notifier fired...")
    self:track_pos()
  end)

  -- track when song is started and stopped
  rns.transport.playing_observable:add_notifier(function()
    --print("xStreamPos playing_notifier fired... playback_pos",rns.transport.playback_pos)
    if rns.transport.playing then
      self.just_started_playback = os.clock()
      self:track_pos()
    end
  end)

end


--------------------------------------------------------------------------------
-- [app] decide the writeahead amount, depending on the song tempo

function xStreamPos:determine_writeahead()
  TRACE("xStream:determine_writeahead()")

  local bpm = rns.transport.bpm
  local lpb = rns.transport.lpb

  -- less than 3 will cause problems with scheduling
  self.writeahead = math.ceil(math.max(2,(bpm*lpb)/self.writeahead_factor))

end


-------------------------------------------------------------------------------

function xStreamPos:get_writeahead_factor()
  return self.writeahead_factor_observable.value
end

function xStreamPos:set_writeahead_factor(val)
  TRACE("xStream:set_writeahead_factor(val)",val)
  self.writeahead_factor_observable.value = val
  self:determine_writeahead()
end

-------------------------------------------------------------------------------

function xStreamPos:__tostring()

  return type(self)
    .. ", playpos=" ..tostring(self.playpos)
    .. ", writepos="..tostring(self.writepos)
    .. ", readpos=" ..tostring(self.readpos)

end