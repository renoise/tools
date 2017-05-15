--[[===============================================================================================
xStream
===============================================================================================]]--

--[[--

This class can track playback progression in a song
.
#

### How to use

Create an instance, and supply it with a steady flow of song-position changes (idle loop). 

See also:
@{xPlayPos}
@{xSongPos}
@{xBlockLoop}

]]


class 'xStreamPos'

xStreamPos.WRITEAHEAD_FACTOR = 300

---------------------------------------------------------------------------------------------------
-- [Constructor] does not accept any arguments

function xStreamPos:__init()
  TRACE("xStreamPos:__init()")

  --- (xPlayPos) precise playback position
  self.playpos = xPlayPos()

  --- (SongPos) the current stream position 
  self.pos = rns.transport.playback_pos

  --- number, represents the total number of lines since streaming started
  self.xinc = 0

  --- bool, track changes to loop_block_enabled
  -- TODO refactor into xBlockloop
  self.block_enabled = rns.transport.loop_block_enabled
  --self.block_start_pos = rns.transport.loop_block_start_pos
  self.block_range_coeff = rns.transport.loop_block_range_coeff

  --- number, 0 for 'false'
  -- this is a short-lived timestamp indicating that we should ignore 
  -- changes to the playback position, right after playback has started
  -- (the fuzziness is due to API living in separate thread)
  self.just_started_playback = 0

  --- function, define a function to call when it's time for output
  self.callback_fn = nil

  --- function, called when we need fresh content
  -- (i.e. when the position has been changed by the user, and 
  -- previously produced content no longer would be valid...)
  self.refresh_fn = nil

  --== notifiers ==--

  renoise.tool().app_new_document_observable:add_notifier(function()
    TRACE("*** xStream - app_new_document_observable fired...")
    self:attach_to_song()
  end)

  renoise.tool().app_idle_observable:add_notifier(function()    
    self:update()
  end)
  

end

---------------------------------------------------------------------------------------------------
-- Start streaming - preferable to calling renoise transport.start()
-- @param playmode, renoise.Transport.PLAYMODE

function xStreamPos:start(playmode)
  print("xStreamPos:start(playmode)",playmode)

  self:reset()
  rns.transport:start(playmode)

end

---------------------------------------------------------------------------------------------------
-- [Class] Initialize position - called as a last resort, when current position is deemed 
-- unreliable due to 'crazy navigation' 

function xStreamPos:reset()
  TRACE("xStreamPos:reset()")

  self.playpos = xPlayPos()
  if rns.transport.playing then
    self.pos = rns.transport.playback_pos
  else
    self.pos = rns.transport.edit_pos
  end
  self.xinc = 0

end

---------------------------------------------------------------------------------------------------

function xStreamPos:_increase_by(lines)
  TRACE("xStreamPos:_increase_by(lines)",lines)
  TRACE(">>> self.pos",self.pos)
  local xinc = xSongPos.increase_by_lines(lines,self.pos)
  self.xinc = self.xinc + xinc
end 

---------------------------------------------------------------------------------------------------

function xStreamPos:_decrease_by(lines)
  TRACE("xStreamPos:_decrease_by(lines)",lines)
  TRACE(">>> self.pos",self.pos)
  local xinc = xSongPos.decrease_by_lines(lines,self.pos)
  self.xinc = self.xinc + xinc
end 

---------------------------------------------------------------------------------------------------
-- [Class] Update the stream-position as a result of a changed playback position.
-- Most of the time we want the stream to continue smoothly forward - this is
-- true for any kind of pattern, sequence or block loop. However, when we
-- detect 'user events', the position can also jump backwards
-- @param pos (renoise.SongPos), the current playback position

function xStreamPos:_set_pos(pos)
  TRACE("xStreamPos:_set_pos(pos)",pos)

  --print(">>> set pos PRE",pos)
  local writeahead = xStreamPos.determine_writeahead()

  local near_patt_top = function(line)
    return (line <= writeahead) and true or false
  end
  local near_patt_end = function(line,patt_lines)
    return (line >= (patt_lines-writeahead))
  end

  local near_block_top = function(line)
    return (line <= xBlockLoop.get_start()+writeahead) 
  end
  local near_block_end = function(line)
    return (line >= xBlockLoop.get_end()-writeahead)
  end

  if rns.transport.loop_block_enabled then
    self.xblock = xBlockLoop()
  end

  if (pos.sequence == self.playpos.sequence) then
    -- within same pattern
    if (pos.line < self.playpos.line) then

      local patt_num_lines = xPatternSequencer.get_number_of_lines(self.playpos.sequence)
      if near_patt_top(pos.line) 
        and near_patt_end(self.playpos.line,patt_num_lines) 
      then
        print(">>> conclusion: pattern loop")
        local num_lines = (patt_num_lines-self.playpos.line) + pos.line
        self:_increase_by(num_lines)
      elseif rns.transport.loop_block_enabled 
        and near_block_top(pos.line)  
        and near_block_end(self.playpos.line) 
      then 
        print(">>> conclusion: block loop (enabled)")
        local num_lines = (self.xblock.end_line-self.playpos.line) + (pos.line-self.xblock.start_line) + 1
        self:_increase_by(num_lines)
      elseif not rns.transport.loop_block_enabled 
        and near_block_end(self.playpos.line)  
      then 
        print(">>> conclusion: block loop (disabled)")
      else
        print(">>> conclusion: crazy navigation")
        self:reset()
        if self.refresh_fn then
          self.refresh_fn()
        end
      end

    elseif (pos.line > self.playpos.line) then

      -- forward progression through pattern - 
      -- figure out how many lines we have progressed
      local line_diff = pos.line - self.playpos.line

      -- always update write-pos 
      self:_increase_by(line_diff)

      -- more than writeahead indicates gaps or forward navigation 
      -- (such as when pressing page down while streaming...)
      if (line_diff >= writeahead) then
        self:_increase_by(line_diff-writeahead)
        if self.refresh_fn then
          self.refresh_fn()
        end
      end

    end
  elseif (pos.sequence < self.playpos.sequence) then
    --print(">>> earlier pattern, usually caused by seq-loop or song boundary")
    -- special case: if the pattern was deleted from the song, the cached
    -- playpos is referring to a non-existing pattern - in such a case,
    -- we re-initialize the cached playpos to the current position
    if not rns.sequencer.pattern_sequence[self.playpos.sequence] then
      self.playpos:set(rns.transport.playback_pos)
    end

    local patt_num_lines = xPatternSequencer.get_number_of_lines(self.playpos.sequence)
    -- the old position is near the end of the pattern
    -- use the writeahead as the basis for this calculation
    if (self.playpos.line >= (patt_num_lines-writeahead)) then
      print(">>> conclusion: we've reached the end of the former pattern ")
      -- difference is the remaning lines in old position plus the current line 
      local num_lines = (patt_num_lines-self.playpos.line)+pos.line
      self:_increase_by(num_lines)
      self.pos.sequence = pos.sequence
    else
      print(">>> conclusion: we've changed the position manually, somehow")
      -- disregard the sequence and just use the lines
      local num_lines = pos.line-self.playpos.line
      self:_increase_by(num_lines)
      self.pos.sequence = pos.sequence
      if not self.pos then
        -- ?? why does this happen 
        self.pos = rns.transport.playback_pos
      end
      self.pos.sequence = pos.sequence
      self.xinc = self.xinc-writeahead
      if self.refresh_fn then
        self.refresh_fn()
      end
    end

  else
    -- later pattern
    local num_lines = xSongPos.get_line_diff(pos,self.playpos)
    self:_increase_by(num_lines)
  end
  
  --print(">>> set pos POST",pos)
  
  if self.callback_fn then
    self.callback_fn()
  end

  self.playpos:set(pos)

end

---------------------------------------------------------------------------------------------------
-- [Class] This function is designed to be called in an idle loop

function xStreamPos:update()
  TRACE("xStreamPos:update()")

  if not rns.transport.playing then
    return
  end 

  local playpos = rns.transport.playback_pos
  --[[
  local prev_block = function()
    print(">>> move read-pos back to block start point")
    local xinc = self.xinc 
    self:_decrease_by(self.xblock.length)

    -- can result in negative value ??? 
    local line_idx = self.pos.line,-self.writeahead
    local seq_idx = self.pos.sequence
    self.pos.line = xSongPos.enforce_block_boundary("decrease",{line=line_idx,sequencer=seq_idx})
    self.xinc = xinc-self.writeahead
    if self.refresh_fn then
      self.refresh_fn()
    end

  end

  local next_block = function()
    print(">>> next_block - move read-pos forward")
    if self.pos then
      local xinc = self.xinc
      self:_increase_by(self.xblock.length-self.writeahead)
      self.xinc = xinc-self.writeahead
      if self.refresh_fn then
        self.refresh_fn()
      end
    end
  end

  -- track when blockloop changes (update scheduling)
  if (self.block_enabled ~= rns.transport.loop_block_enabled) then
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
        prev_block()
      elseif self.xblock then
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
        next_block()
      elseif (prev_block_start_line == rns.transport.loop_block_start_pos.line) then
        prev_block()
        -- update pos, as Renoise changes the cursor when 
        -- moving to previous loop block ... 
        self.pos.line = self.pos.line-(self.playpos.line-playpos.line)
      end
    end
    self.block_start_pos = rns.transport.loop_block_start_pos
  end

  if (self.block_range_coeff ~= rns.transport.loop_block_range_coeff) then
    -- TODO refresh read buffer if affected by size change
    self.block_range_coeff = rns.transport.loop_block_range_coeff
  end
  ]]
  -- after this point, content can be written -------------

  if (self.just_started_playback > 0) then
    if (0.2 > (os.clock() - self.just_started_playback)) then
      self.just_started_playback = 0
    end
  elseif (self.just_started_playback == 0) then
    if not xSongPos.equal(playpos,self.playpos) then
      self:_set_pos(playpos)
    end
  end


end

---------------------------------------------------------------------------------------------------
-- [Class] Call when a new document becomes available

function xStreamPos:attach_to_song()
  TRACE("xStreamPos:attach_to_song()")

  -- handling changes via observable is quicker than idle notifier
  local pattern_notifier = function()
    self:update()
  end  

  -- track when song is started and stopped
  local playing_notifier = function()
    if rns.transport.playing then
      self.just_started_playback = os.clock()
      self:update()
    end
  end

  cObservable.attach(rns.selected_pattern_index_observable,pattern_notifier)
  cObservable.attach(rns.transport.playing_observable,playing_notifier)

end

---------------------------------------------------------------------------------------------------
-- [Class] Decide the writeahead amount, depending on the song tempo

function xStreamPos.determine_writeahead()
  TRACE("xStream:determine_writeahead()")

  local bpm = rns.transport.bpm
  local lpb = rns.transport.lpb
  return math.ceil(math.max(2,(bpm*lpb)/xStreamPos.WRITEAHEAD_FACTOR))

end

---------------------------------------------------------------------------------------------------

function xStreamPos:__tostring()

  return type(self)
    .. ", playpos=" ..tostring(self.playpos)
    .. ", pos=" ..tostring(self.pos)

end