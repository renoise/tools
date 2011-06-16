--[[----------------------------------------------------------------------------
-- Duplex.Navigator
-- Inheritance: Application > Navigator
----------------------------------------------------------------------------]]--

--[[

About

  The Navigator controls the pattern playback & blockloop size/position
  It is designed to work a bit like the pattern-trigger from the Matrix, but
  using block-loops as sections, instead of a pattern sequence


How to use
  
  - When a button is pressed, and there's no active block-loop, the playback
    will instantly move to that position
  - When a button is pressed and blockloop is active, the block-loop will
    instantly be moved to that position 
  - When multiple buttons are pressed, the Navigator will create a block-loop
    range which is approximately the same size, and in the same position
    as the pressed buttons (the range/pos is determined by the coefficient)
  - When a button is pressed and held, and there's no active block-loop,
    a block-loop range of one unit is created. 
  - When a button is pressed and held, and block-loop is active, tbe current
    block-loop is disabled and playback will continue throughout the pattern

Notes     

    The Navigator is always working on the currently displayed pattern. This
    means that any position changes while in decoupled playback mode will cause
    the playback to return to the current pattern. If this is not what you 
    desire, simple enable "playback follow mode" in Renoise.

    Just like block-loops in Renoise, the Navigator works best for ranges 
    that are power-of-two, such as 1,2 or 4. This is the reason why some 
    combinations of ranges and positions work better than others. 
  
    Navigator attempts to avoid breaking the tempo, even if this sometimes 
    involves jumping to the last bit of the (previous) pattern. For example,
    if we are jumping to the very start of a pattern, we actually need to 
    jump to the line *before* that


Mappings

  blockpos  - (UIButtonStrip) control playback + block-loop


Options

  This application has no options


Changes (equal to Duplex version number)

  0.95  - First release


--]]

--==============================================================================


class 'Navigator' (Application)

Navigator.default_options = {}

function Navigator:__init(display,mappings,options,config_name)
  TRACE("Navigator:__init(",display,mappings,options,config_name)

  self.mappings = {
    blockpos = {
      description = "Navigator: Pattern position/blockloop"
                  .."\nPress and release to change position/block"
                  .."\nPress and hold to enable/disable loop"
                  .."\nPress multiple buttons to define blockloop"
                  .."\nControl-map value: ",
      orientation = VERTICAL,
      ui_component = UI_COMPONENT_BUTTONSTRIP,
    },
  }

  self.palette = {}

  -- (boolean) keep track of the playing state
  self._playing = nil

  -- (number) blockloop starting line
  -- (used for checking if start has been changed from Renoise)
  self._loop_block_start_line = nil

  -- (number, 2-16) blockloop coefficient 
  -- (used for checking if coeff has been changed from Renoise)
  self._loop_block_range_coeff = nil

  -- (boolean or nil) change block-loop state during idle loop
  -- true: enable loop when possible
  -- false: disable loop when possible
  -- nil: ignore
  self._pending_loop = nil

  -- (integer or nil) change to this index during idle loop
  self._pending_index = nil

  -- (boolean or nil) change to this coeff during idle loop
  self._pending_coeff = nil

  -- (integer) the visible pattern index
  self._editing_idx = nil

  -- (boolean) true when sequence play_pos==edit_pos
  self._active_pattern = nil

  -- (integer) line position adjusted to fit control
  self._fit_line_pos = nil

  -- (UIButtonStrip) the UIComponent instance
  self._blockpos = nil

  -- (integer) the number of steps within the buttonstrip
  self._steps = nil

  -- (boolean) true when number of lines has changed
  self._changed_num_lines = false

  Application.__init(self,display,mappings,options,config_name)


end

--------------------------------------------------------------------------------

function Navigator:start_app()
  TRACE("Navigator.start_app()")

  if not Application.start_app(self) then
    return
  end
  self:_attach_to_song(renoise.song())

end

--------------------------------------------------------------------------------

-- periodic updates: check if properties have changed

function Navigator:on_idle()

  if (not self.active) then 
    return 
  end

  local skip_event = true
  local playing = renoise.song().transport.playing
  local line =  renoise.song().transport.playback_pos.line
  local patt = renoise.song().patterns[self._editing_idx]
  local actual_coeff = renoise.song().transport.loop_block_range_coeff

  -- detect if we've entered/exited the active pattern
  local active_pattern = self:_is_active_seq_index()
  if active_pattern then
    if not self._active_pattern then
      TRACE("Navigator: ** enter active pattern")
      self._active_pattern = true
    end
  else
    if self._active_pattern then
      TRACE("Navigator: ** exit active pattern")
      self._blockpos:set_index(0,skip_event)
      self._active_pattern = false
    end
  end

  -- update number of lines?
  if self._changed_num_lines then
    self:_get_num_lines()
    self._changed_num_lines = false
  end

  -- update pattern position?
  if active_pattern and self._playing then
    local fit_line = math.ceil((line)/patt.number_of_lines*self._steps)
    if (fit_line~=self._fit_line_pos) then
      --TRACE("Navigator: ** changed position")
      self._blockpos:set_index(fit_line,skip_event)
      self._fit_line_pos = fit_line
    end
  end

  -- check if playback is stopped/started
  if (playing ~= self._playing) then
    self._playing = playing
    if (not self._playing) then
      TRACE("Navigator: ** stopped playing")
      self._blockpos:set_index(0,skip_event)
    else 
      TRACE("Navigator: ** started playing")
      self._blockpos:set_index(self._fit_line_pos,skip_event)
    end
  end

  -- try to enable/disable blockloop 
  if (self._pending_loop==true) then
   TRACE("Navigator: ** pending loop")
    if self._pending_coeff or self._pending_loop then
      if self._pending_coeff and (actual_coeff~=self._pending_coeff) then
        TRACE("Navigator: ** set coeff")
        renoise.song().transport.loop_block_range_coeff = self._pending_coeff
      else
        if renoise.song().transport.loop_block_enabled then
          TRACE("Navigator: ** set range")
          self._pending_coeff = nil
          self._pending_loop = nil
          self:_set_blockloop_range(self._blockpos)
        else
          -- try to enable loop (again)
          renoise.song().transport.loop_block_enabled = true
          TRACE("Navigator: ** try to enable loop (again)")
        end
      end
    end
  elseif (self._pending_loop==false) then 
    if not renoise.song().transport.loop_block_enabled then
      TRACE("Navigator: ** exit pending_loop ")
      self._pending_loop = nil
    else
      -- try to disable loop (again)
      renoise.song().transport.loop_block_enabled = false
      TRACE("Navigator: ** try to disable loop (again)")
    end
  end

  -- update index
  if self._pending_index and 
    renoise.song().transport.loop_block_enabled 
  then
    TRACE("Navigator: ** set pending index",self._pending_index)
    self._blockpos:set_range(self._pending_index,self._pending_index,true)
    self:_set_blockloop_range(self._blockpos)
    self._pending_index = nil
  end

  -- track changes to the blockloop coeff, update when needed
  if (self._loop_block_range_coeff~=actual_coeff) then
    TRACE("Navigator: ** coeff changed",actual_coeff,self._loop_block_range_coeff)
    self._loop_block_range_coeff = actual_coeff
    self:_update()
  end

  -- track changes to the blockloop start_pos, update when needed
  local actual_start_line = renoise.song().transport.loop_block_start_pos.line
  if (self._loop_block_start_line~=actual_start_line) then
    TRACE("Navigator: ** start_pos changed",actual_start_line,self._loop_block_start_line)
    self._loop_block_start_line = actual_start_line
    self:_update()
  end

end

--------------------------------------------------------------------------------

-- called when a new document becomes available

function Navigator:on_new_document()
  TRACE("Navigator:on_new_document()")

  self:_attach_to_song(renoise.song())

end

--------------------------------------------------------------------------------

-- adds notifiers to song, set essential values

function Navigator:_attach_to_song(song)
  TRACE("Navigator:_attach_to_song",song)

  self:_get_num_lines()
  self._active_pattern = self:_is_active_seq_index()
  self._playing = song.transport.playing
  self._editing_idx = song.selected_pattern_index
  self._loop_block_range_coeff = song.transport.loop_block_range_coeff
  self._loop_block_start_line = song.transport.loop_block_start_pos.line

  song.selected_pattern_index_observable:add_notifier(
    function()
      TRACE("Navigator:selected_pattern_index_observable fired...")
      self._editing_idx = song.selected_pattern_index
      self:_update_num_lines_notifier()
    end
  )

  self:_update_num_lines_notifier()

end

--------------------------------------------------------------------------------

function Navigator:_update_num_lines_notifier()
  TRACE("Navigator:_update_num_lines_notifier()")

  local song = renoise.song()
  local patt = song.patterns[self._editing_idx]
  local observable = patt.number_of_lines_observable
  if not (observable:has_notifier(Navigator._changed_num_lines,self))then
    observable:add_notifier(Navigator._changed_num_lines,self)
  end

end

--------------------------------------------------------------------------------

function Navigator:_changed_num_lines()
  TRACE("Navigator:_changed_num_lines()")
  self._changed_num_lines = true

end

--------------------------------------------------------------------------------

-- TODO set to values from Renoise

function Navigator:_update()

end

--------------------------------------------------------------------------------

-- set the active blockloop based the index of the button
-- @obj: UIButtonStrip

function Navigator:_set_blockloop_index(idx)
  TRACE("Navigator:_set_blockloop_index(",idx,")")

  local rng = self._blockpos:get_range()

  -- if the index is within the range
  if (idx>=rng[1]) and (idx<=rng[2]) then
    self:_set_playback_index(idx)
    return
  end

  local line =  renoise.song().transport.playback_pos.line
  local num_lines = self:_get_num_lines()
  local coeff = self:_get_control_coeff()
  local target_section = math.ceil((idx/self._steps)*coeff)
  local block_start = renoise.song().transport.loop_block_start_pos.line-1
  local curr_section = math.ceil((block_start/num_lines)*coeff)+1

  -- move blockloop to the desired location
  local block_moves = math.floor(target_section-curr_section)
  self:_move_block_loop(block_moves)

  -- update the displayed range
  local rng_len = math.ceil(self._steps/coeff)
  local rng_start = ((target_section-1)*rng_len)+1
  local rng_end = rng_start+rng_len-1
  self._blockpos:set_range(rng_start,rng_end,true)

  -- determine the line
  local block_lines = num_lines/coeff
  local start_pos = 1+math.floor(block_lines*(target_section-1))
  self._loop_block_start_line = start_pos

  -- adjust line number
  local mod = line%block_lines
  local play_pos = math.floor(((target_section-1)*block_lines)+mod)
  self:_set_playback_pos(play_pos)

  -- apply the new coefficient
  --renoise.song().transport.loop_block_range_coeff = coeff
  self._loop_block_range_coeff = coeff

end

--------------------------------------------------------------------------------

-- set the active blockloop range based on controller input/range
-- (this function should not be called before the on_idle loop has set the
-- proper coefficient and enabled the loop)
-- @obj: UIButtonStrip

function Navigator:_set_blockloop_range(obj)
  TRACE("Navigator:_set_blockloop_range(",obj,")")

  local rng = obj:get_range()
  local idx = obj:get_index()
  if not idx then
    idx = rng[1]
  end
  local line =  renoise.song().transport.playback_pos.line
  local num_lines = self:_get_num_lines()
  local coeff = self:_get_control_coeff()
  local rng_len = math.ceil(self._steps/coeff)
  local block_start = renoise.song().transport.loop_block_start_pos.line-1
  local curr_section = math.ceil((block_start/num_lines)*coeff)+1
  local playing_section = math.ceil((idx/self._steps)*coeff)
  local start_section = math.ceil((rng[1]/self._steps)*coeff)
  local end_section = math.ceil((rng[2]/self._steps)*coeff)

  -- check if playing section is outside range
  local outside = false
  if not (playing_section>=start_section) or
     not (playing_section<=end_section) 
  then
    outside = true
  end

  local section = (outside) and start_section or playing_section

  -- spanning multiple sections, adjust the range on-the-fly
  -- and choose the one where playback is currently at
  if (start_section~=end_section) then
    local rng_start = ((section-1)*rng_len)+1
    local rng_end = rng_start+rng_len-1
    obj:set_range(rng_start,rng_end,true)
  end

  local block_lines = num_lines/coeff

  -- blockloop start
  local block_moves = nil
  if (curr_section<start_section) then 
    block_moves = math.floor(start_section-curr_section) -- forwards
  else 
    block_moves = -math.floor(curr_section-start_section) -- backwards
  end
  self:_move_block_loop(block_moves)
  self._loop_block_start_line = 1+((section-1)*block_lines)

  if outside then
    -- adjust playback position
    local mod = line%block_lines
    local play_pos = math.floor(((section-1)*block_lines)+mod)
    if (block_lines==1) then
      -- don't jump to previous line when block is a single line
      play_pos = play_pos+1
    end
    self:_set_playback_pos(play_pos)
  end

  -- apply the new coefficient
  --renoise.song().transport.loop_block_range_coeff = coeff
  self._loop_block_range_coeff = coeff

end

--------------------------------------------------------------------------------

function Navigator:_move_block_loop(block_moves)
  TRACE("Navigator:_move_block_loop(",block_moves,")")

  if (block_moves<0) then
    for i=1,math.abs(block_moves) do
      renoise.song().transport:loop_block_move_backwards()
    end
  else
    for i=1,block_moves do
      renoise.song().transport:loop_block_move_forwards()
    end
  end
end

--------------------------------------------------------------------------------

-- foolproof method for setting playback position:
-- - for continuous playback, we always go to the previous line
-- - if that line does not exist, we go to the last line instead
-- - also attempt to use the previous pattern if pattern-loop is disabled

function Navigator:_set_playback_pos(line)
  TRACE("Navigator:_set_playback_pos(",line,")")

  local seq_idx = renoise.song().selected_sequence_index
  local num_lines = self:_get_num_lines()
  if (line==0) then
    if (renoise.song().transport.loop_pattern) then
      line = num_lines
    else
      line = num_lines
      if (seq_idx>1) then
        seq_idx = seq_idx-1
      end
    end
  end
  -- just to be on the safe side, restrict to valid range
  line = math.max(1,math.min(num_lines,line))
  local new_pos = renoise.song().transport.playback_pos
  new_pos.line = line
  new_pos.sequence = seq_idx
  renoise.song().transport.playback_pos = new_pos

end

--------------------------------------------------------------------------------

-- set the playback to the specified index from the controller
-- @idx - the index 

function Navigator:_set_playback_index(idx)
  TRACE("Navigator:_set_playback_index(",idx,")")

  local line =  renoise.song().transport.playback_pos.line
  local num_lines = self:_get_num_lines()
  local block_lines = math.ceil(num_lines/self._blockpos:get_steps())
  local mod = line%block_lines
  local jump_line = (block_lines*(idx-1))+mod
  self:_set_playback_pos(jump_line)

end


--------------------------------------------------------------------------------

-- toggle blockloop on/off: wait for idle mode to do the actual work
-- (since the blockloop needs a slight delay to activate)
-- @obj: UIButtonStrip

function Navigator:_toggle_blockloop(obj)
  TRACE("Navigator:_toggle_blockloop(",obj,")")

  local rng = obj:get_range()

  if (rng[1]==0) and (rng[2]==0) then
    TRACE("Navigator: ** blockloop disabled **")
    renoise.song().transport.loop_block_enabled = false
    self._pending_loop = false
  else
    -- activating the loop will make it seek the current edit position,
    -- so we check if we need to enable the blockloop 
    local coeff = self:_get_control_coeff()
    local num_lines = self:_get_num_lines()
    local block_start = renoise.song().transport.loop_block_start_pos.line-1
    local idx = obj:get_index()
    local playing_section = math.ceil((idx/self._steps)*coeff)
    local curr_section = math.ceil((block_start/num_lines)*coeff)+1
    if not renoise.song().transport.loop_block_enabled or 
      (playing_section~=curr_section) 
    then
      TRACE("Navigator: ** blockloop enabled **")
      renoise.song().transport.loop_block_enabled = true
    end
    self._pending_loop = true
    if (renoise.song().transport.loop_block_range_coeff~=coeff) then
      renoise.song().transport.loop_block_range_coeff = coeff
      self._loop_block_range_coeff = coeff
      TRACE("Navigator:_toggle_blockloop - coeff = ",coeff)
      -- wait in idle loop for this to be set...
      self._pending_coeff = coeff
    end
  end

end

--------------------------------------------------------------------------------

-- this function performs double-duty: it will return the number of lines
-- in the current pattern, and at the same time, update the blockpos control
-- if the number of lines is less than the size of the control

function Navigator:_get_num_lines()
  TRACE("Navigator:_get_num_lines()")

  local patt_idx = renoise.song().selected_pattern_index
  local num_lines = renoise.song().patterns[patt_idx].number_of_lines
  if (num_lines<self._blockpos._size) then
    self._steps = num_lines
  else
    self._steps = self._blockpos._size
  end
  self._blockpos:set_steps(self._steps)
  return num_lines

end

--------------------------------------------------------------------------------

-- get coefficient based on the range on the controller
-- @return integer (2-16)

function Navigator:_get_control_coeff()

  local rng = self._blockpos:get_range()
  local coeff = math.ceil(self._steps/(rng[2]-(rng[1]-1)))
  return math.max(2,math.min(16,coeff)) -- fit within range

end

--------------------------------------------------------------------------------

-- check if the sequence play-pos match the edit-pos
-- @return boolean

function Navigator:_is_active_seq_index()

  local seq_pos = renoise.song().transport.playback_pos.sequence
  local edit_pos = renoise.song().transport.edit_pos.sequence
  return (seq_pos == edit_pos)

end

--------------------------------------------------------------------------------

-- build the application, 
-- @return boolean (false if requirements were not met)

function Navigator:_build_app()
  TRACE("Navigator:_build_app()")

  local cm = self.display.device.control_map

  -- create the pattern position/length control
  if (self.mappings.blockpos.group_name) then
    local c = UIButtonStrip(self.display)
    c.mode = 1 -- "position+range" mode
    c.group_name = self.mappings.blockpos.group_name
    c.tooltip = self.mappings.blockpos.description
    c:set_orientation(self.mappings.blockpos.orientation)
    c.monochrome = is_monochrome(self.display.device.colorspace)
    c.flipped = true
    if (self.mappings.blockpos.orientation == VERTICAL) then
      c:set_size(cm:count_rows(self.mappings.blockpos.group_name))
    else
      c:set_size(cm:count_columns(self.mappings.blockpos.group_name))
    end
    c.on_range_change = function(obj)

      if not self.active then
        return false
      end
      -- wait for idle loop to set the range
      self:_toggle_blockloop(obj)

    end

    c.on_index_change = function(obj)

      if not self.active then
        return false
      end

      local idx = obj:get_index()
      local rng = obj:get_range()

      if (rng[1]==rng[2]) then
        if not renoise.song().transport.loop_block_enabled then
          -- jump to position, cancel the range
          self:_set_playback_index(idx)
          obj:set_range(0,0,true)
          if not self._playing then
            -- update control when not playing
            return true
          end
        else
          -- wait for idle loop to set the range
          self._pending_index = idx
          renoise.song().transport.loop_block_enabled = true
        end

      else
        -- switch to this position
        self:_set_blockloop_index(idx)
      end

      return false

    end
    self:_add_component(c)
    self._blockpos = c

  end


  -- final steps
  Application._build_app(self)
  return true

end


