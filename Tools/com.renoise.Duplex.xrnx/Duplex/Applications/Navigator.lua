--[[===============================================================================================
-- Duplex.Application.Navigator 
===============================================================================================]]--

--[[--

Take control of the pattern/block-loop and playback position

#

[View the README.md](https://github.com/renoise/xrnx/blob/master/Tools/com.renoise.Duplex.xrnx/Docs/Applications/Navigator.md) (github)

]]

--=================================================================================================

-- constants

local LOOP_BLOCK = 1
local LOOP_SEQUENCE = 2
local LOOP_CUSTOM = 3

local MODE_POSITION = 1
local MODE_POSITION_RANGE = 2

local LOOP_CARRY_ON = 1
local LOOP_CARRY_OFF = 2

local VALID_COEFF_ALL = 1
local VALID_COEFF_FOUR = 2
local VALID_COEFF_THREE = 3

local SELECT_NONE = 1
local SELECT_PATTERN = 2
local SELECT_TRACK = 3
local SELECT_COLUMN = 4


--=================================================================================================

class 'Navigator' (Application)

Navigator.default_options = {
  operation = {
    label = "Operating mode",
    description = "Here you can choose if you want to be able to"
                .."\ncontrol both the position and looped range,"
                .."\nor just the position. Note that setting the"
                .."\nrange will require that your controller is "
                .."\ncapable of transmitting 'release' events.",
    items = {
      "Control position only",
      "Control position + range",
    },
    value = 2,
  },
  loop_carry = {
    label = "Loop carry-over",
    description = "Enable this feature to have the looped range"
                .."\n'carried over' when a new position is set",
    items = {
      "Enabled",
      "Disabled",
    },
    value = 1,
  },
  valid_coeffs = {
    label = "Coefficients",
    description = "Select the set of coefficients that best "
                .."\nfit your particular musical content ",
    items = {
      "Allow all",
      "Fourths: 2/4/8/16",
      "Thirds: 2/3/6/12",
    },
    value = 2,
  },
  pattern_select = {
    label = "Pattern select",
    description = "Match the pattern selection with the loop",
    items = {
      "Do no select anything",
      "Select all tracks",
      "Select active track",
      "Select active column",
    },
    value = 1,
  },
  
}

Navigator.available_mappings = {
  blockpos = {
    description = "Navigator: Pattern position/blockloop"
                .."\nPress and release to change position/block"
                .."\nPress and hold to enable/disable loop"
                .."\nPress multiple buttons to define blockloop"
                .."\nControl-map value: ",
    orientation = ORIENTATION.VERTICAL,
  },
  prev_block = {
    description = "Navigator: Move the blockloop backwards"
  },
  next_block = {
    description = "Navigator: Move the blockloop forward"
  },
}
Navigator.default_palette = {
  blockpos_index      = {color = {0xFF,0xFF,0xFF}, text="▪", val = true },
  blockpos_range      = {color = {0X80,0X80,0X80}, text="▫", val = true },
  blockpos_background = {color = {0X00,0X00,0X00}, text="·", val = true },
  prev_block_on       = {color = {0xFF,0xFF,0xFF}, text="▲", val = true },
  prev_block_off      = {color = {0X00,0X00,0X00}, text="▲", val = false },
  next_block_on       = {color = {0xFF,0xFF,0xFF}, text="▼", val = true },
  next_block_off      = {color = {0X00,0X00,0X00}, text="▼", val = false },
}


---------------------------------------------------------------------------------------------------

--- Constructor method
-- @param (VarArg), 
-- @see Duplex.Application

function Navigator:__init(...)

  --- bool, true when we are playing the selected pattern
  self._inside_pattern = nil

  --- (int), the current control index as determined by the playback 
  -- position within the pattern, quantized against the number of steps
  -- Note: a value of 0 means "no index is selected"
  self._active_index = nil

  --- (int), the current line in the edited pattern
  self._edit_line = nil

  --- (int), the size of the blockpos control in units
  self._blockpos_size = nil

  --- bool, true when we need to update the blockpos index
  self._index_update_requested = nil

  --- bool, true when we need to update the blockpos range
  self._range_update_requested = nil

  --- enum, one of the LOOP_xxx constants
  self._loop_mode = nil

  --- renoise.SongPos, where the loop starts
  self._loop_start = nil

  --- renoise.SongPos, where the loop ends
  self._loop_end = nil

  --- (int), the first pressed index
  self._first_idx = nil

  --- bool, true when a loop_range is waiting to be applied 
  -- (wait until inside the actual pattern to avoid side effects)
  self._apply_when_in_seq = nil

  --- (int), the buttons that the user has pressed
  self._loop_start_idx = nil
  self._loop_end_idx = nil

  --- bool, true once the blockpos hold event has fired
  self._held_event_fired = nil

  --- UIComponents
  self._prev_block = nil
  self._next_block = nil
  self._blockpos = nil

  Application.__init(self,...)
  --self:list_mappings_and_options(Navigator)

end

---------------------------------------------------------------------------------------------------
-- @see Duplex.Application.start_app
-- @return bool or nil

function Navigator:start_app()
  TRACE("Navigator.start_app()")

  if not Application.start_app(self) then
    return
  end
  self:_attach_to_song()

end

---------------------------------------------------------------------------------------------------
-- @see Duplex.Application.on_new_document

function Navigator:on_new_document()
  TRACE("Navigator:on_new_document()")

  self:_attach_to_song()

end


---------------------------------------------------------------------------------------------------
-- @see Duplex.Application._build_app
-- @return bool

function Navigator:_build_app()
  TRACE("Navigator:_build_app()")

  local cm = self.display.device.control_map

  -- create the pattern position/length control 
  local map = self.mappings.blockpos
  if (map.group_name) then

    if (map.orientation == ORIENTATION.VERTICAL) then
      self._blockpos_size = cm:count_rows(map.group_name)
    else
      self._blockpos_size = cm:count_columns(map.group_name)
    end
    local c = UIButtonStrip(self)
    c.mode = UIButtonStrip.MODE_BASIC 
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_orientation(map.orientation)
    c.monochrome = is_monochrome(self.display.device.colorspace)
    c.flipped = true
    c:set_size(self._blockpos_size)
    c:set_palette({
      index = self.palette.blockpos_index,
      range = self.palette.blockpos_range,
      background = self.palette.blockpos_background
    })
    c.on_press = function(obj,idx)
      --print("blockpos on_press",obj,idx)
      if (self.options.operation.value == MODE_POSITION) then
        self:_jump_to_index(idx)
      elseif (self.options.operation.value == MODE_POSITION_RANGE) then
        if not self._first_idx then
          self._first_idx = idx
          self._loop_start_idx = idx
          self._held_event_fired = false
        else -- additional button presses
          self._loop_end_idx = idx
          self:_set_looped_range()
          self._held_event_fired = true
        end
      else
        error("Unexpected MODE")
      end
    end
    c.on_release = function(obj,idx)
      if (self.options.operation.value == MODE_POSITION) then return end
      if (idx == self._first_idx) then
        --print("released the first pressed button")
        if not self._held_event_fired then
          self._held_event_fired = true
          local seq_idx = rns.selected_sequence_index
          self:_jump_to_index(idx)
        end
        self._first_idx = nil
      end
    end
    c.on_hold = function(obj,idx)
      if (self.options.operation.value == MODE_POSITION) then return end
      if self._held_event_fired then return end
      -- only the first pressed button can be held
      if (self._first_idx ~= idx) then return end
      local rng = c:get_range()
      if c:_in_range(idx) then
        self:_clear_looped_range()
      else
        -- establish a single-unit range
        local seq_idx = rns.transport.edit_pos.sequence
        self._loop_start_idx = idx
        self._loop_end_idx = idx
        self._apply_when_in_seq = seq_idx
        if (self.options.loop_carry.value == LOOP_CARRY_ON) then
          self:_jump_to_index(idx)
        end
      end
    end
    self._blockpos = c

  end

  local map = self.mappings.prev_block
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c:set_pos(map.index)
    c.tooltip = map.description
    c.palette.foreground = self.palette.prev_block_off
    c.on_press = function()
      if self:_goto_prev_block() then
        self._prev_block:flash(0.1,
          self.palette.prev_block_on,
          self.palette.prev_block_off)
      end
    end
    self._prev_block = c
  end

  local map = self.mappings.next_block
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c:set_pos(map.index)
    c.tooltip = map.description
    c.palette.foreground = self.palette.next_block_off
    c.on_press = function()
      if self:_goto_next_block() then
        self._next_block:flash(0.1,
          self.palette.next_block_on,
          self.palette.next_block_off)
      end
    end
    self._next_block = c
  end

  -- final steps
  Application._build_app(self)
  return true

end

---------------------------------------------------------------------------------------------------
-- Add notifiers to song, set essential values

function Navigator:_attach_to_song()
  TRACE("Navigator:_attach_to_song")

  -- initialize important stuff
  self._playing = rns.transport.playing
  self._index_update_requested = true
  self._range_update_requested = true
  self._held_event_fired = false
  self._apply_when_in_seq = nil
  self._first_idx = nil

  rns.selected_sequence_index_observable:add_notifier(
    function()
      self._index_update_requested = true
      self._range_update_requested = true
    end
  )

  rns.transport.playing_observable:add_notifier(
    function()
      local playing = rns.transport.playing
      if playing ~= self._playing then
        self._index_update_requested = true
      end
      self._playing = playing
    end
  )


end

---------------------------------------------------------------------------------------------------

function Navigator:_goto_prev_block()
  TRACE("Navigator:_goto_prev_block")

  local prev_line_idx = xBlockLoop.get_previous_line_index()
  if prev_line_idx and (prev_line_idx >= 1) then
    local idx = self:_get_index_from_line(new_pos,self._loop_start.sequence)
    self:_jump_to_index(idx)
    return true
  end

  return false

end

---------------------------------------------------------------------------------------------------

function Navigator:_goto_next_block()
  TRACE("Navigator:_goto_next_block")

  local prev_line_idx = xBlockLoop.get_next_line_index()
  local num_lines = rns.selected_pattern.number_of_lines
  if (prev_line_idx < num_lines) then
    local idx = self:_get_index_from_line(new_pos,self._loop_end.sequence)
    self:_jump_to_index(idx)
    return true
  end
  return false

end

---------------------------------------------------------------------------------------------------
-- Update the blockpos control to reflect the currently set loop

function Navigator:_update_blockpos_range()
  TRACE("Navigator:_update_blockpos_range")

  if not self._loop_start then
    self._blockpos:set_range(0,0,true)
  else

    local seq_idx = rns.selected_sequence_index

    -- a sequence loop will include the first line in the next pattern
    local seq_end_fix = 0
    if (self._loop_mode == LOOP_SEQUENCE) then
      if (self._loop_end.line == 1) and 
        ((self._loop_end.sequence-1) ~= seq_idx)
      then
        seq_end_fix = -1
      end
    end

    if (self._loop_start.sequence <= seq_idx) and
      (self._loop_end.sequence+seq_end_fix >= seq_idx) 
    then
      -- the loop is covering our pattern, at least partially
      local start_index,end_index = nil,nil
      if (self._loop_start.sequence < seq_idx) then
        start_index = 1
      else
        start_index = self:_get_index_from_line(self._loop_start.line,self._loop_start.sequence)
      end

      if (self._loop_end.sequence+seq_end_fix > seq_idx) then
        end_index = self._blockpos_size
      else
        end_index = self:_get_index_from_line(self._loop_end.line-1,self._loop_end.sequence)
      end
      self._blockpos:set_range(start_index,end_index,true)
    else
      -- the loop is somewhere else in the song
      self._blockpos:set_range(0,0,true)
    end
  end
end


---------------------------------------------------------------------------------------------------
-- @see Duplex.Application.on_idle

function Navigator:on_idle()

  if not self.active then 
    return 
  end

  --== handle changes to loop/range ==--

  local loop_has_changed = false
  local pos = (self._playing) and 
    rns.transport.playback_pos or rns.transport.edit_pos

  if self._apply_when_in_seq 
    and (self._apply_when_in_seq == pos.sequence)
  then
    --print(">>> time to apply the looped range!")
    self:_set_looped_range()
    self._apply_when_in_seq = nil
  end

  local has_looped_range, loop_mode = self:_determine_loop_type()
  if not has_looped_range then
    if self._loop_start and not self._first_idx then
      --print("loop has been disabled")
      self._loop_mode = nil
      self._loop_start = nil
      self._loop_end = nil
      loop_has_changed = true
    end
  else
    if not self._loop_start then
      --print("loop was enabled")
      self._loop_start = rns.transport.loop_start
      self._loop_end = rns.transport.loop_end
      loop_has_changed = true
    elseif self._loop_start then
      --print("detect changes to loop ")
      local loop_start = rns.transport.loop_start
      local loop_end = rns.transport.loop_end
      if not xSongPos.equal(loop_start,self._loop_start) 
        or not xSongPos.equal(loop_end,self._loop_end) 
      then
        loop_has_changed = true
        self._loop_start = loop_start
        self._loop_end = loop_end
      end
    end
  end

  if loop_has_changed or self._range_update_requested then
    --print(">>> loop_has_changed")
    self._loop_mode = loop_mode
    self._range_update_requested = false
    self:_update_blockpos_range()
  end

  --== handle changes to position/index ==--

  local active_index = nil
  if self._playing then
    self._index_update_requested = true
  else
    -- check if edit-pos line has changed
    local edit_pos = rns.transport.edit_pos
    if (self._edit_line~= edit_pos.line) then
      self._edit_line = edit_pos.line
      active_index = self:_get_index_from_line(edit_pos.line,edit_pos.sequence)
      if (active_index ~= self._active_index) then
        self._index_update_requested = true
      end
    end
  end

  if self._index_update_requested then
    self._index_update_requested = false
    self._inside_pattern = self:_is_inside_pattern()
    if (active_index == nil) then
      active_index = self:_obtain_active_index()
    end
    if (active_index ~= self._active_index) then
      self._active_index = active_index
      self._blockpos:set_index(self._active_index,true)
    end

  end


end

---------------------------------------------------------------------------------------------------
-- Obtain the current play/editpos, quantized to the number of steps
-- @return int (0 to display "no index")

function Navigator:_obtain_active_index()
  --TRACE("Navigator:_obtain_active_index()")

  if self._inside_pattern then
    local pos = (self._playing) and 
      rns.transport.playback_pos or rns.transport.edit_pos
    return self:_get_index_from_line(pos.line,pos.sequence)
  else
    if self._playing then
      return 0
    else
      local pos =  rns.transport.edit_pos
      return self:_get_index_from_line(pos.line,pos.sequence)
    end
  end

end

---------------------------------------------------------------------------------------------------
-- Calculate the control index from the provided line

function Navigator:_get_index_from_line(line_idx,seq_idx)
  --TRACE("Navigator:_get_index_from_line(line_idx,seq_idx)",line_idx,seq_idx)

  local lines_per_unit = self:_get_lines_per_unit(seq_idx)
  local active_index = math.floor((line_idx-1)/lines_per_unit)+1
  return active_index

end

---------------------------------------------------------------------------------------------------
-- Return the line number for the provided index
-- @param idx (int), 0-blockpos_size
-- @return int (0-number of lines)

function Navigator:_get_line_from_index(idx,seq_idx)
  TRACE("Navigator:_get_line_from_index(idx,seq_idx)",idx,seq_idx)

  local lines_per_unit = self:_get_lines_per_unit(seq_idx)
  local active_line = (idx * lines_per_unit)+1
  return active_line,lines_per_unit

end

---------------------------------------------------------------------------------------------------
-- Obtain the number of lines per "unit" (blockpos size)
-- @param seq_idx (int)
-- @return int (lines per unit), number of lines in pattern

function Navigator:_get_lines_per_unit(seq_idx)
  --TRACE("Navigator:_get_lines_per_unit(seq_idx)",seq_idx)

  assert(type(seq_idx)=="number")

  local num_lines = xPatternSequencer.get_number_of_lines(seq_idx)
  local lines_per_unit = math.floor(num_lines/self._blockpos_size)
  return lines_per_unit,num_lines
  
end

---------------------------------------------------------------------------------------------------
-- Check if edit-pos and play-pos is the same? 
-- note: when not playing, this will always return true

function Navigator:_is_inside_pattern()
  --TRACE("Navigator:_is_inside_pattern()")

  if not self._playing then
    return true
  end

  local edit_pos = rns.transport.edit_pos.sequence
  local playback_pos = rns.transport.playback_pos.sequence
  return (edit_pos == playback_pos) 

end

---------------------------------------------------------------------------------------------------
-- Navigate to the line indicated by the index
-- * If playing in a different pattern, will take us to the selected one
-- * Will carry over loops (when enabled)
-- @param ctrl_idx (int), 1-blockpos_size

function Navigator:_jump_to_index(ctrl_idx)
  TRACE("Navigator:_jump_to_index(ctrl_idx)",ctrl_idx)

  -- skip, if the index is inside the range,
  -- and the range is no larger than one unit  
  local rng = self._blockpos:get_range()
  local range_size = rng[2]-rng[1]
  local inside_range = false
  if (ctrl_idx >= rng[1]) and (ctrl_idx <= rng[2]) then
    inside_range = true
  end
  if inside_range and (range_size == 0) and 
    (self._active_index == ctrl_idx) 
  then
    return
  end

  -- the new SongPos to apply 
  local new_pos = nil
  local active_line,lpu = self:_get_line_from_index(ctrl_idx-1,rns.transport.edit_pos.sequence)
  
  -- perform the actual jump - 
  -- when not playing, things are simple - but in realtime, 
  if not self._playing then
    new_pos = rns.transport.edit_pos
    new_pos.sequence = rns.selected_sequence_index
    new_pos.line = active_line
    rns.transport.edit_pos = new_pos
  else
    new_pos = rns.transport.playback_pos
    if self._loop_end and (self._loop_end.sequence ~= rns.transport.edit_pos.sequence) then
      --print("jumping to a different pattern ")
      new_pos.sequence = rns.transport.edit_pos.sequence
    end
  
    local lines_per_unit,num_lines = self:_get_lines_per_unit(new_pos.sequence)
    --print(">>> lines_per_unit,num_lines",lines_per_unit,num_lines)
    local playback_line = nil
    local block_enabled = rns.transport.loop_block_enabled
    local block_lines = block_enabled and xBlockLoop.get_block_lines(new_pos.sequence)
    
    -- distinguish between jumps "inside" or "outside" of the looped range:
    if block_lines and not inside_range then -- 
      local coeff = rns.transport.loop_block_range_coeff
      local line_offset = (new_pos.line%block_lines)
      local section_line = math.floor(((ctrl_idx-1)/self._blockpos_size)*coeff)*block_lines
      playback_line = section_line+line_offset
    else -- no block loop or outside range
      local line_offset = (new_pos.line%lines_per_unit)-1
      playback_line = active_line+line_offset
    end    
    if (playback_line < 1) then
      -- at boundary - "wrap" position 
      new_pos.line = 1
      xSongPos.decrease_by_lines(1,new_pos)
    else
      new_pos.line = playback_line
      --new_pos.sequence = rns.selected_sequence_index
    end
    --print("jump from/to",rns.transport.playback_pos,new_pos)
    rns.transport.playback_pos = new_pos
  end

  -- carry over loop when outside range, and not having 
  -- a looped range which is waiting to be applied ..
  if self._loop_start and self._loop_end 
    and (self.options.loop_carry.value == LOOP_CARRY_ON) 
    and not inside_range 
    and not self._apply_when_in_seq
  then
    self:_carry_over_loop(new_pos)
  end

end

---------------------------------------------------------------------------------------------------
-- Carry over: change the looped range to contain our new position 

function Navigator:_carry_over_loop(new_pos)
  TRACE("Navigator:_carry_over_loop(new_pos)",new_pos)
    
  local coeff = rns.transport.loop_block_range_coeff
  local start_idx = self:_get_index_from_line(new_pos.line,new_pos.sequence)
  local block_indices = math.floor(self._blockpos_size/coeff)
  local mul = self._blockpos_size/coeff
  local div = coeff/self._blockpos_size
  self._loop_start_idx =  -mul+1+(math.ceil(start_idx*div)*mul)
  self._loop_end_idx = self._loop_start_idx+block_indices-1
  -- don't apply range immediately - avoid side-effects
  self._apply_when_in_seq = new_pos.sequence

end

---------------------------------------------------------------------------------------------------
-- Set the looped range - ensure valid start/stop/coefficient 
-- also: maintain the pattern selection

function Navigator:_set_looped_range()
  TRACE("Navigator:_set_looped_range")

  if not self._loop_start_idx or not self._loop_end_idx then
    LOG("Can't set looped range without positions")
    return 
  end

  -- swap start/end if needed
  if (self._loop_start_idx > self._loop_end_idx) then
    self._loop_start_idx,self._loop_end_idx = self._loop_end_idx,self._loop_start_idx
  end

  local lines_per_unit = nil
  self._loop_start = rns.transport.edit_pos
  self._loop_end = rns.transport.edit_pos
  local seq_idx = rns.transport.edit_pos.sequence
  self._loop_start.line,lines_per_unit = self:_get_line_from_index(self._loop_start_idx-1,seq_idx)
  self._loop_end.line = self:_get_line_from_index(self._loop_end_idx-1,seq_idx) + lines_per_unit

  self:normalize_range()

  -- should be safe to apply the loop by now... 
  rns.transport.loop_range = {self._loop_start,self._loop_end}
  self._loop_mode = LOOP_CUSTOM

  self._range_update_requested = true

  self:maintain_selection()

end

---------------------------------------------------------------------------------------------------
-- Normalize the loop range to something that Renoise can select

function Navigator:normalize_range()

  local coeffs = self:get_coeffs()
  
  --print(">>> pre-normalized range",self._loop_start,self._loop_end)
  local num_lines = xPatternSequencer.get_number_of_lines(self._loop_end.sequence)
  local start_line,end_line = 
    xBlockLoop.normalize_line_range(self._loop_start.line,self._loop_end.line,num_lines,coeffs)
  --print(">>> post-normalized range",self._loop_start,self._loop_end)
    
  self._loop_start.line = start_line
  self._loop_end.line = end_line

end

---------------------------------------------------------------------------------------------------
-- Provide a set of coefficients (for normalizing)
-- @return xBlockLoop.COEFFS

function Navigator:get_coeffs()

  if (self.options.valid_coeffs.value == xBlockLoop.COEFF_MODE.ALL) then
    return xBlockLoop.COEFFS_ALL
  elseif (self.options.valid_coeffs.value == xBlockLoop.COEFF_MODE.FOUR) then
    return xBlockLoop.COEFFS_FOUR
  elseif (self.options.valid_coeffs.value == xBlockLoop.COEFF_MODE.THREE) then
    return xBlockLoop.COEFFS_THREE
  else
    error("Unexpected xBlockLoop.COEFF_MODE")
  end 

end

---------------------------------------------------------------------------------------------------

function Navigator:maintain_selection()
  -- maintain the pattern selection
  if (self.options.pattern_select.value ~=  SELECT_NONE) then
    local num_lines = xPatternSequencer.get_number_of_lines(self._loop_start.sequence)
    if (self.options.pattern_select.value == SELECT_PATTERN) then
      rns.selection_in_pattern = { 
        start_line = self._loop_start.line, 
        end_line = math.min(num_lines,self._loop_end.line)
      } 
    elseif (self.options.pattern_select.value == SELECT_TRACK) then
      rns.selection_in_pattern = { 
        start_track = rns.selected_track_index,
        end_track = rns.selected_track_index,
        start_line = self._loop_start.line, 
        end_line = math.min(num_lines,self._loop_end.line)
      } 
    elseif (self.options.pattern_select.value == SELECT_COLUMN) then
      local track_idx = rns.selected_track_index
      local column_idx = rns.selected_note_column_index > 0 and 
        rns.selected_note_column_index or
        rns.selected_effect_column_index + 
          rns.tracks[track_idx].visible_note_columns
      rns.selection_in_pattern = { 
        start_column = column_idx,
        end_column = column_idx,
        start_track = rns.selected_track_index,
        end_track = rns.selected_track_index,
        start_line = self._loop_start.line, 
        end_line = math.min(num_lines,self._loop_end.line)
      } 
    end
  end
end

---------------------------------------------------------------------------------------------------
-- Clear the looped range 
-- note: clearing a block loop should not affect the sequence loop 

function Navigator:_clear_looped_range()
  --TRACE("Navigator:_clear_looped_range")

  local has_sequence_range,cached_seq = false,nil
  if (rns.transport.loop_sequence_range[1] ~= 0) and
    (rns.transport.loop_sequence_range[2] ~= 0) 
  then
    has_sequence_range = true
    cached_seq = rns.transport.loop_sequence_range
  end

  rns.transport.loop_range_beats = {0,rns.transport.song_length_beats}

  if (self._loop_mode == LOOP_SEQUENCE) then
    --print("avoid that the sequence range expands")
    rns.transport.loop_sequence_range = {}
  elseif has_sequence_range then
    --print("restore the sequence range")
    rns.transport.loop_sequence_range = cached_seq
  else
    --print("clear sequence range")
    rns.transport.loop_sequence_range = {}
  end

  self._held_event_fired = true
  self._first_idx = nil

  -- clear the pattern selection
  if (self.options.pattern_select.value ~=  SELECT_NONE) then
    rns.selection_in_pattern = {}
  end

end

---------------------------------------------------------------------------------------------------
-- Determine if the song contains a loop, and which type of loop
-- @return bool, enum (Navigator.LOOP_xxx)

function Navigator:_determine_loop_type()
  --TRACE("Navigator:_determine_loop_type")

  -- check if block loop is active
  if rns.transport.loop_block_enabled then
    return true,LOOP_BLOCK
  end

  -- check sequence range
  local range = rns.transport.loop_sequence_range
  if (range[1] == 0) and (range[2] == 0) then
    -- check custom range
    local range = rns.transport.loop_range_beats
    if (range[1] == 0) and
      (range[2] == rns.transport.song_length_beats)
    then
      return false
    else
      if rns.transport.loop_pattern then
        -- we ignore the pattern loop!
        return false
      else
        return true,LOOP_CUSTOM
      end
    end
  else
    return true,LOOP_SEQUENCE
  end

end

