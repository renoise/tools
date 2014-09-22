--[[============================================================================
-- Duplex.Application.Navigator 
============================================================================]]--

--[[--
The "Navigator" application allows you to take control of the pattern/block-loop and playback position. 
Inheritance: @{Duplex.Application} > Duplex.Application.Navigator 

### Usage 

  * Single press & release to move playback to the indicated position
  * When stopped, press & release will cause the edit-pos to move 
  * Pressing two buttons will create a block-loop with that approximate size
  * When a loop has been created, hold any button to cleared it again

### Suggested configuration

To take advantage of this application, you need to assign a number of buttons to the "blockpos" - the more buttons, the higher precision you will get. Generally speaking, you want to map either 4, 8 or 16 buttons for music which is based on a 4/4 measure. 

### Changes

  0.98.32
    - FIXME When jumping back in pattern, and briefly going to the previous pattern,
      the navigator would break if the previous pattern hadn’t same number of lines
  
  0.98.27
    - Should be more solid and support off-pattern updates
    - New mappings: “prev_block”,”next_block”

  0.98.21
    - Fixed: issue when loading a new song while Navigator was displaying nothing
     (playback happening in a different pattern)

  0.98
    - Reset on new song
    - Listen for changes to block-loop size
    - Follow block loop enable

  0.96
    - Fixed: holding button while playback is stopped cause error 

  0.95
    - Interactively control the blockloop position and size

  0.9
    - First release

]]

--==============================================================================

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


--==============================================================================

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


--------------------------------------------------------------------------------

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

  --- renoise.SongPos, disallow multiple playback_pos jumps
  self._jump_pos = nil

  --- renoise.SongPos, the first pressed button 
  self._first_pos = nil

  --- (int), the first pressed index
  self._first_idx = nil

  --- renoise.SongPos, the second pressed button 
  self._second_pos = nil

  --- bool, true once the blockpos hold event has fired
  self._held_event_fired = nil

  --- UIComponents
  self._prev_block = nil
  self._next_block = nil
  self._blockpos = nil

  Application.__init(self,...)

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.start_app
-- @return bool or nil

function Navigator:start_app()
  TRACE("Navigator.start_app()")

  if not Application.start_app(self) then
    return
  end
  self:_attach_to_song()

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_new_document

function Navigator:on_new_document()
  TRACE("Navigator:on_new_document()")

  self:_attach_to_song()

end


--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application._build_app
-- @return bool

function Navigator:_build_app()
  TRACE("Navigator:_build_app()")

  local rns = renoise.song()
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

      local rns = renoise.song()

      if (self.options.operation.value == MODE_POSITION) then
        self:_jump_to_index(idx)
      else
        if not self._first_pos then
          --print("remember this pressed button")
          local first_pos = rns.transport.edit_pos
          first_pos.line = self:_get_line_from_index(idx-1)
          self._first_pos = first_pos
          self._first_idx = idx
          self._held_event_fired = false
        else
          --print("the second pressed button",self._first_idx)
          self._second_pos = rns.transport.edit_pos
          self._second_pos.line = self:_get_line_from_index(idx-1)
          self:_set_looped_range()
          --self._held_event_fired = true

        end
      end

    end
    c.on_release = function(obj,idx)
      
      if (self.options.operation.value == MODE_POSITION) then
        return
      end

      local rns = renoise.song()

      if (idx == self._first_idx) then
        --print("released the first pressed button")
        if not self._held_event_fired then
          self._held_event_fired = true
          local seq_idx = rns.selected_sequence_index
          if (self._first_pos.sequence == seq_idx) then
            --print("within the same pattern",idx)
            self:_jump_to_index(idx)
          else
            --print("within a different pattern")
          end
        end
        self._first_pos = nil
        self._first_idx = nil

      end

    end
    c.on_hold = function(obj,idx)

      if (self.options.operation.value == MODE_POSITION) then
        return
      end

      if self._held_event_fired then
        return
      end

      local rns = renoise.song()

      -- only the first pressed button can be held
      if (self._first_idx ~= idx) then
       --print("not the first pressed button",self._first_idx,idx)
       return
      end

      local rng = c:get_range()
      local inside_range = false
      if (idx >= rng[1]) and (idx <= rng[2]) then
        inside_range = true
      end
      if inside_range then
        self:_clear_looped_range()
      else
        -- establish a single-unit range
        self._second_pos = rns.transport.edit_pos
        self._second_pos.line = self:_get_line_from_index(idx-1)
        self:_set_looped_range()
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

--------------------------------------------------------------------------------

-- adds notifiers to song, set essential values

function Navigator:_attach_to_song()
  TRACE("Navigator:_attach_to_song")

  local rns = renoise.song()

  -- initialize important stuff
  self._playing = rns.transport.playing
  self._index_update_requested = true
  self._range_update_requested = true
  self._held_event_fired = false
  self._first_pos = nil
  self._first_idx = nil
  self._jump_pos = nil

  rns.selected_sequence_index_observable:add_notifier(
    function()
      self._index_update_requested = true
      self._range_update_requested = true
      if self._first_pos then
        -- allow pattern-spanning loops
        self._held_event_fired = true
      end

    end
  )

  rns.transport.playing_observable:add_notifier(
    function()
      local rns = renoise.song()
      local playing = rns.transport.playing
      if playing ~= self._playing then
        self._index_update_requested = true
      end
      self._playing = playing
    end
  )


end

--------------------------------------------------------------------------------

function Navigator:_goto_prev_block()
  TRACE("Navigator:_goto_prev_block")

  local rns = renoise.song()
  if rns.transport.loop_block_enabled then
    local coeff = rns.transport.loop_block_range_coeff
    local block_start = rns.transport.loop_block_start_pos.line
    local num_lines = rns.selected_pattern.number_of_lines
    local shift_lines = math.floor(num_lines/coeff)
    local new_pos = block_start-shift_lines
    if (new_pos >= 1) then
      local idx = self:_get_index_from_line(new_pos)
      self:_jump_to_index(idx)
      return true
    end
  end

  return false

end

--------------------------------------------------------------------------------

function Navigator:_goto_next_block()
  TRACE("Navigator:_goto_next_block")

  local rns = renoise.song()
  if rns.transport.loop_block_enabled then
    local coeff = rns.transport.loop_block_range_coeff
    local block_start = rns.transport.loop_block_start_pos.line
    local num_lines = rns.selected_pattern.number_of_lines
    local shift_lines = math.floor(num_lines/coeff)
    local new_pos = block_start+shift_lines
    if (new_pos < num_lines) then
      local idx = self:_get_index_from_line(new_pos)
      self:_jump_to_index(idx)
      return true
    end
  end

  return false

end

--------------------------------------------------------------------------------

--- update the looped range of the blockpos control

function Navigator:_update_blockpos_range()
  TRACE("Navigator:_update_blockpos_range")

  local rns = renoise.song()

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
        start_index = self:_get_index_from_line(self._loop_start.line)
      end

      if (self._loop_end.sequence+seq_end_fix > seq_idx) then
        end_index = self._blockpos_size
      else
        end_index = self:_get_index_from_line(self._loop_end.line-1)
      end
      self._blockpos:set_range(start_index,end_index,true)
    else
      -- the loop is somewhere else in the song
      self._blockpos:set_range(0,0,true)
    end
  end
end


--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_idle

function Navigator:on_idle()

  if (not self.active) then 
    return 
  end

  local rns = renoise.song()

  -- prevent loop from migrating into a new pattern when
  -- it shouldn't 
  ---------------------------------------------------------

  if self._jump_pos then
    local rns = renoise.song()
    local seq_count = #rns.sequencer.pattern_sequence
    local start_pos = rns.transport.loop_range[1]
    local end_pos = rns.transport.loop_range[2]
    if (self._jump_pos.sequence == seq_count) then
      -- if last pattern, restore to first pattern
      start_pos.sequence = 1
      end_pos.sequence = 1
    else
      -- move to next pattern
      start_pos.sequence = self._jump_pos.sequence+1
      end_pos.sequence = self._jump_pos.sequence+1
    end
    --print("disallowed, move range here",start_pos,end_pos)
    rns.transport.loop_range = {start_pos,end_pos}
    self._jump_pos = nil
  end

  --  handle changes to loop/range
  ---------------------------------------------------------

  local loop_has_changed = false
  local has_looped_range, loop_mode = self:_has_looped_range()
  if not self:_has_looped_range() then
    if self._loop_start then
      -- loop has been disabled
      self._loop_mode = nil
      self._loop_start = nil
      self._loop_end = nil
      loop_has_changed = true
    end
  else
    if not self._loop_start then
      -- loop was enabled
      self._loop_start = rns.transport.loop_start
      self._loop_end = rns.transport.loop_end
      loop_has_changed = true
    elseif self._loop_start then
      -- detect changes to loop 
      local loop_start = rns.transport.loop_start
      local loop_end = rns.transport.loop_end
      if (loop_start.sequence ~= self._loop_start.sequence) or
        (loop_end.sequence ~= self._loop_end.sequence) or
        (loop_start.line ~= self._loop_start.line) or
        (loop_end.line ~= self._loop_end.line) 
      then
        loop_has_changed = true
        self._loop_start = loop_start
        self._loop_end = loop_end
      end
    end
  end

  if loop_has_changed or self._range_update_requested then
    self._loop_mode = loop_mode
    self._range_update_requested = false
    self:_update_blockpos_range()
  end

  --  handle changes to position/index
  ---------------------------------------------------------

  local active_index = nil
  if self._playing then
    self._index_update_requested = true
  else
    -- check if edit-pos line has changed
    local edit_pos = rns.transport.edit_pos
    if (self._edit_line~= edit_pos.line) then
      self._edit_line = edit_pos.line
      active_index = self:_get_index_from_line(edit_pos.line)
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

--------------------------------------------------------------------------------

--- obtain the current play/editpos, quantized to the number of steps
-- @return int (0 to display "no index")

function Navigator:_obtain_active_index()
  --TRACE("Navigator:_obtain_active_index()")

  local rns = renoise.song()
  if self._inside_pattern then
    local active_line =  (self._playing) and 
      rns.transport.playback_pos.line or rns.transport.edit_pos.line
    return self:_get_index_from_line(active_line)
  else
    if self._playing then
      return 0
    else
      local active_line =  rns.transport.edit_pos.line
      return self:_get_index_from_line(active_line)
    end
  end

end

--------------------------------------------------------------------------------

--- calculate the control index from the provided line
-- using the selected pattern as the basis for the calculation

function Navigator:_get_index_from_line(line)
  TRACE("Navigator:_get_index_from_line()",line)

  local lines_per_unit = self:_get_lines_per_unit()
  local active_index = math.floor((line-1)/lines_per_unit)+1
  return active_index

end

--------------------------------------------------------------------------------

--- return the line number for the provided index
-- @param idx (int), 0-blockpos_size
-- @return int (0-number of lines)

function Navigator:_get_line_from_index(idx)
  TRACE("Navigator:_get_line_from_index(idx)",idx)

  local lines_per_unit = self:_get_lines_per_unit()
  local active_line = (idx * lines_per_unit)+1
  return active_line

end

--------------------------------------------------------------------------------

--- obtain the number of lines per "unit" (blockpos size)
-- using the selected pattern as the basis for the calculation
-- @param seq_idx (int)
-- @return int (lines per unit), number of lines in pattern

function Navigator:_get_lines_per_unit(seq_idx)
  --TRACE("Navigator:_get_lines_per_unit(seq_idx)",seq_idx)

  local rns = renoise.song()
  seq_idx = seq_idx or rns.selected_sequence_index

  local patt_idx = rns.sequencer:pattern(seq_idx)
  local num_lines = rns.patterns[patt_idx].number_of_lines
  local lines_per_unit = math.floor(num_lines/self._blockpos_size)
  return lines_per_unit,num_lines
  
end

--------------------------------------------------------------------------------

--- check if edit-pos and play-pos is the same? 
-- note: when not playing, this will always return true

function Navigator:_is_inside_pattern()
  --TRACE("Navigator:_is_inside_pattern()")

  if not self._playing then
    return true
  end

  local rns = renoise.song()
  local edit_pos = rns.transport.edit_pos.sequence
  local playback_pos = rns.transport.playback_pos.sequence
  return (edit_pos == playback_pos) 

end

--------------------------------------------------------------------------------

--- navigate to the line indicated by the index¨
-- also: carry over loop, if this option has been enabled
-- @param ctrl_idx (int), 1-blockpos_size

function Navigator:_jump_to_index(ctrl_idx)
  TRACE("Navigator:_jump_to_index(ctrl_idx)",ctrl_idx)

  local rns = renoise.song()
  local active_line = self:_get_line_from_index(ctrl_idx-1)
  local rng = self._blockpos:get_range()
  local line_count = nil
  local coeff = nil
  
  local inside_range = false
  if (ctrl_idx >= rng[1]) and (ctrl_idx <= rng[2]) then
    inside_range = true
  end

  -- skip, if the index is inside the range,
  -- and the range is no larger than one unit
  local range_size = rng[2]-rng[1]
  if inside_range and (range_size == 0) and 
    (self._active_index == ctrl_idx) 
  then
    --print("skip jump within single-unit range")
    return
  end

  if self._loop_start and
    (self.options.loop_carry.value == LOOP_CARRY_ON) 
  then
    
    if not inside_range then
      if (self._loop_start.sequence == self._loop_end.sequence) or
        ((self._loop_start.sequence == self._loop_end.sequence-1)  and
        (self._loop_end.line == 1))
      then

        local lines_per_unit,num_lines = 
          self:_get_lines_per_unit(self._loop_start.sequence)
        -- fix for when end line is first line in next pattern
        local end_line = self._loop_end.line
        if (end_line==1) then
          end_line = num_lines+1
        end
        line_count = end_line - self._loop_start.line
        coeff = num_lines/line_count

        local new_line = 1+ math.floor((active_line/num_lines)*coeff)*(num_lines/coeff)

        self._first_pos = rns.transport.edit_pos
        self._first_pos.sequence = self._loop_start.sequence
        self._first_pos.line = new_line
        self._second_pos = rns.transport.edit_pos
        self._second_pos.sequence = self._loop_start.sequence
        self._second_pos.line = new_line + line_count - lines_per_unit

        self:_set_looped_range()
        self._range_update_requested = true

      end

    end

  end

  if self._playing then

    local play_pos = rns.transport.playback_pos

    -- make sure we can't jump multiple times 
    local skip_jump = false
    if self._jump_pos then
      if (self._jump_pos.sequence == play_pos.sequence) and
        (self._jump_pos.line == play_pos.line)
      then
        skip_jump = true
      else
        self._jump_pos = nil
      end
    end

    if not skip_jump then
      -- to have continuous playback, we need to apply the current line offset
      -- to the resulting value. If the resulting value is < 1, we either 
      -- go the end of the last/previous pattern, or the current pattern 
      -- (if the pattern is looped)
      local lines_per_unit,num_lines = self:_get_lines_per_unit()
      local playback_line = nil
      if line_count then
        local line_offset = (play_pos.line%line_count)
        local section_line = math.floor(((ctrl_idx-1)/self._blockpos_size)*coeff)*line_count
        playback_line = section_line+line_offset
      else
        local line_offset = (play_pos.line%lines_per_unit)-1
        playback_line = active_line+line_offset
      end
      
      if (playback_line < 1) then
        play_pos.line = num_lines
        if rns.transport.loop_pattern then -- use current pattern
          play_pos.sequence = rns.selected_sequence_index
        elseif (rns.selected_sequence_index == 1) then -- use last pattern
          play_pos.sequence = #rns.sequencer.pattern_sequence
        else -- use previous pattern
          local prev_seq_idx = rns.selected_sequence_index-1
          local prev_patt_idx = rns.sequencer.pattern_sequence[prev_seq_idx]
          play_pos.sequence = prev_seq_idx
          play_pos.line = rns.patterns[prev_patt_idx].number_of_lines
        end
        self._jump_pos = play_pos
      else
        play_pos.line = playback_line
        play_pos.sequence = rns.selected_sequence_index
      end
      rns.transport.playback_pos = play_pos
    end

  else
    local edit_pos = rns.transport.edit_pos
    edit_pos.sequence = rns.selected_sequence_index
    edit_pos.line = active_line
    rns.transport.edit_pos = edit_pos
  end


end

--------------------------------------------------------------------------------

--- set the looped range using controller input
-- also: maintain the pattern selection, if this feature has been enabled

function Navigator:_set_looped_range()
  TRACE("Navigator:_set_looped_range")

  local rns = renoise.song()

  -- figure out which of the positions that should come first
  local swap_pos = false
  if (self._first_pos.sequence > self._second_pos.sequence) then
    swap_pos = true
  elseif (self._first_pos.sequence == self._second_pos.sequence) then
    if (self._first_pos.line > self._second_pos.line) then
      swap_pos = true
    end
  end
  if swap_pos then
    self._first_pos,self._second_pos = self._second_pos,self._first_pos
  end

  -- add one "unit" to the length of the end position
  local lines_per_unit,num_lines = 
    self:_get_lines_per_unit(self._second_pos.sequence)
  self._second_pos.line = self._second_pos.line + lines_per_unit


  if (self._first_pos.sequence == self._second_pos.sequence) then

    -- the following will enforece a valid coefficient range

    local line_count = self._second_pos.line - self._first_pos.line
    local coeff = num_lines/line_count
    local matched_coeff = false
    local valid_coeffs = nil
    if (self.options.valid_coeffs.value == VALID_COEFF_ALL) then
      valid_coeffs = {1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16}
    elseif (self.options.valid_coeffs.value == VALID_COEFF_FOUR) then
      valid_coeffs = {1,2,4,8,16}
    elseif (self.options.valid_coeffs.value == VALID_COEFF_THREE) then
      valid_coeffs = {1,2,3,6,12}
    end
    local closest_match = nil
    for k,v in ipairs(valid_coeffs) do
      if (v == coeff) then
        matched_coeff = true
      elseif (v > coeff) then
        if (math.ceil(coeff) == v) then
          closest_match = valid_coeffs[k]
        else
          closest_match = valid_coeffs[k-1]
        end
        break
      end
    end

    -- if not a valid coefficient, expand the size
    if not matched_coeff then
      matched_coeff = closest_match
      line_count = math.floor(num_lines/closest_match)
      self._second_pos.line = self._first_pos.line+line_count
    end

    -- if result goes beyond boundary, move back
    if (self._second_pos.line > num_lines+1) then
      local offset = num_lines-self._second_pos.line+1
      self._first_pos.line = self._first_pos.line + offset
      self._second_pos.line = self._second_pos.line + offset
    end

  end

  rns.transport.loop_range = {self._first_pos,self._second_pos}

  self._loop_mode = LOOP_CUSTOM

  -- maintain the pattern selection
  if (self.options.pattern_select.value ~=  SELECT_NONE) then

    if (self.options.pattern_select.value == SELECT_PATTERN) then
      rns.selection_in_pattern = { 
        start_line = self._first_pos.line, 
        end_line = math.min(num_lines,self._second_pos.line)
      } 
    elseif (self.options.pattern_select.value == SELECT_TRACK) then
      rns.selection_in_pattern = { 
        start_track = rns.selected_track_index,
        end_track = rns.selected_track_index,
        start_line = self._first_pos.line, 
        end_line = math.min(num_lines,self._second_pos.line)
      } 
    elseif (self.options.pattern_select.value == SELECT_COLUMN) then
      local track_idx = rns.selected_track_index
      local column_idx = rns.selected_note_column_index > 0 and 
        rns.selected_note_column_index or
        rns.selected_effect_column_index + 
          renoise.song().tracks[track_idx].visible_note_columns
      rns.selection_in_pattern = { 
        start_column = column_idx,
        end_column = column_idx,
        start_track = rns.selected_track_index,
        end_track = rns.selected_track_index,
        start_line = self._first_pos.line, 
        end_line = math.min(num_lines,self._second_pos.line)
      } 
    end

  end

  -- prepare for a new selection
  self._held_event_fired = true
  self._first_pos = nil
  self._first_idx = nil


end

--------------------------------------------------------------------------------

--- clear the looped range using controller input
-- if you clear a block loop, the sequence loop should remain unaffected

function Navigator:_clear_looped_range()
  --TRACE("Navigator:_clear_looped_range")

  local rns = renoise.song()

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
  self._first_pos = nil
  self._first_idx = nil

  -- clear the pattern selection
  if (self.options.pattern_select.value ~=  SELECT_NONE) then
    rns.selection_in_pattern = {}
  end

end

--------------------------------------------------------------------------------

--- determine if the song contain a looped range
-- (this can be a sequence loop, a block loop or a custom looped range)
-- @return bool, enum (Navigator.LOOP_xxx)

function Navigator:_has_looped_range()
  --TRACE("Navigator:_has_looped_range")

  local rns = renoise.song()

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

