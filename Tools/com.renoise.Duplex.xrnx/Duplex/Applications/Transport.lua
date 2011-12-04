--[[----------------------------------------------------------------------------
-- Duplex.Transport
-- Inheritance: Application > Transport
----------------------------------------------------------------------------]]--

--[[

About

  The Transport application is aimed at controlling the playback position


Changes (equal to Duplex version number)
  
  0.98  New mapping: "metronome_toggle", minor optimizations
  0.96  Fixed: Option "pattern_switch" didn't switch instantly
  0.92  New option: "stop playback" (playback toggle button)
  0.91  Fixed: always turn off "start" when hitting "stop"
  0.90  Follow player option
  0.81  First release

--]]

--==============================================================================



class 'Transport' (Application)

Transport.default_options = {
    pattern_switch = {
      label = "Next/previous",
      description = "Choose how next/previous buttons will work",
      items = {
        "Switch instantly",
        "Schedule pattern"
      },
      value = 1,
    },
    pattern_play = {
      label = "Press play",
      description = "When play is pressed, choose an action",
      items = {
        "Retrigger current pattern",
        "Schedule current pattern",
        "Toggle start/stop"
      },
      value = 1,
    },
    pattern_stop = {
      label = "Press stop x2",
      description = "When stop is pressed *twice*, choose an action",
      items = {
        "Panic (stop all)",
        "Jump to beginning"
      },
      value = 1,
    },
    jump_mode = {
      label = "Loop mode",
      description = "Choose between standard pattern or optional" 
                  .."\nhybrid pattern/block-loop control ",
      items = {
        "Control the pattern only",
        "Control pattern or block-loop (when block-loop is active)"
      },
      value = 1,
    },


}

function Transport:__init(browser_process,mappings,options,config_name)
  TRACE("Transport:__init(",browser_process,mappings,options,config_name)

  -- define the options (with defaults)

  self.SWITCH_MODE_SWITCH = 1
  self.SWITCH_MODE_SCHEDULE = 2

  self.PLAY_MODE_RETRIG = 1
  self.PLAY_MODE_SCHEDULE = 2
  self.PLAY_MODE_STOP = 3

  self.STOP_MODE_PANIC = 1
  self.STOP_MODE_JUMP = 2

  self.JUMP_MODE_NORMAL = 1
  self.JUMP_MODE_BLOCK = 2

  self.mappings = {
    stop_playback = {
      description = "Transport: Stop playback"
                  .."\nControl value: ",
    },
    start_playback = {
      description = "Transport: Start playback"    
                  .."\nControl value: ",
    },
    loop_pattern = {
      description = "Transport: Toggle pattern looping"
                  .."\nControl value: ",
    },
    edit_mode = {
      description = "Transport: Toggle edit-mode"
                   .."\nControl value: ",
    },
    follow_player = {
      description = "Transport: Toggle play-follow mode"
                  .."\nControl value: ",
    },
    goto_next = {
      description = "Transport: Goto next pattern/block"    
                  .."\nControl value: ",
    },
    goto_previous = {
      description = "Transport: Goto previous pattern/block"    
                  .."\nControl value: ",
    },
    block_loop = {
      description = "Transport: Toggle block-loop mode"    
                  .."\nControl value: ",
    },
    metronome_toggle = {
      description = "Metronome: toggle on/off",
    },
    --[[
    -- TODO
    set_bpm = {
      description = "Adjust the BPM rate. Assign to a dial or fader",    
    },
    increase_bpm = {
      description = "Increase BPM (hold to repeat)",
    },
    decrease_bpm = {
      description = "Decrease BPM (hold to repeat)",
    },
    ]]
  }


  -- private stuff

  -- number, set when not yet arrived at the scheduled pattern 
  self._scheduled_pattern = nil
  self._source_pattern = nil

  -- current status of the block loop
  self._block_loop = nil

  -- the various UIComponents
  self.controls = {}

  Application.__init(self,browser_process,mappings,options,config_name)


end

--------------------------------------------------------------------------------

function Transport:start_app()
  TRACE("Transport.start_app()")

  if not Application.start_app(self) then
    return
  end

  self:update_everything()

end

--------------------------------------------------------------------------------

-- periodic updates: check if any of the "un-observable" 
-- properties have changed (block loop and schedule pattern)

function Transport:on_idle()

  if not self.active then 
    return 
  end

  local loop_block_enabled = renoise.song().transport.loop_block_enabled
  local loop_pattern = renoise.song().transport.loop_pattern

  -- never blink when we enter block mode
  if loop_block_enabled and (not loop_block_enabled) then
    if self.controls.next then
      self.controls.next.loop = false
    end
    if self.controls.previous then
      self.controls.previous.loop = false
    end
  end

  -- update 'block_loop' status
  if (self._block_loop ~= loop_block_enabled) then
    if self.controls.block then
      self.controls.block:set(loop_block_enabled,true)
    end
    self._block_loop = loop_block_enabled
  end

  -- check if we have arrived at the scheduled pattern
  if (self._scheduled_pattern)then
    local pos = renoise.song().transport.playback_pos.sequence
    if(self._scheduled_pattern==pos) or
      (pos~=self._source_pattern) then
      self._scheduled_pattern = nil
      -- stop the blinking
      if self.controls.next then
        self.controls.next.loop = false
      end
      if self.controls.previous then
        self.controls.previous.loop = false
      end
    end

  end

end

--------------------------------------------------------------------------------

function Transport:on_new_document()
  TRACE("Transport.on_new_document()")

  self:_attach_to_song()

end

--------------------------------------------------------------------------------

-- adds notifiers to song, initialize certain properties
-- invoked when a new document becomes available

function Transport:_attach_to_song()
  TRACE("Transport._attach_to_song()")

  local song = renoise.song()

  -- metronome --
  song.transport.metronome_enabled_observable:add_notifier(
    function()
      TRACE("Transport.metronome_enabled_observable fired...")
      self:update_metronome_enabled()
    end
  )

  -- follow player --
  song.transport.follow_player_observable:add_notifier(
    function()
      TRACE("Transport.follow_player_observable fired...")
      self:update_follow_player()
    end
  )

  -- playing --
  song.transport.playing_observable:add_notifier(
    function()
      TRACE("Transport.playing_observable fired...")
      self:update_playing()
    end
  )

  -- loop pattern -- 
  song.transport.loop_pattern_observable:add_notifier(
    function()
      TRACE("Transport.loop_pattern_observable fired...")
      self:update_loop_pattern()
    end
  )

  -- edit mode --
  song.transport.edit_mode_observable:add_notifier(
    function()
      TRACE("Transport.edit_mode_observable fired...")
      self:update_edit_mode()
    end
  )

end


--------------------------------------------------------------------------------

-- update methods for the various UIComponents

function Transport:update_metronome_enabled()
  if not self.active then return false end
  if self.controls.metronome_toggle then
    self.controls.metronome_toggle:set(renoise.song().transport.metronome_enabled,true)
  end
end

function Transport:update_follow_player()
  if not self.active then return false end
  if self.controls.follow_player then
    self.controls.follow_player:set(renoise.song().transport.follow_player,true)
  end
end

function Transport:update_playing()
  if not self.active then return false end
  if self.controls.play then
    self.controls.play:set(renoise.song().transport.playing,true)
  end
end

function Transport:update_loop_pattern()
  if not self.active then return false end
  if self.controls.loop then
    self.controls.loop:set(renoise.song().transport.loop_pattern,true)
  end
end

function Transport:update_edit_mode()
  if not self.active then return false end
  if self.controls.edit then
    self.controls.edit:set(renoise.song().transport.edit_mode,true)
  end
end

--------------------------------------------------------------------------------

-- update all UIComponents to the present state

function Transport:update_everything()
  TRACE("Transport:update_everything()")

  self:update_metronome_enabled()
  self:update_follow_player()
  self:update_playing()
  self:update_loop_pattern()
  self:update_edit_mode()

end

--------------------------------------------------------------------------------

function Transport:_build_app()
  TRACE("Transport:_build_app()")

  if self.mappings.stop_playback.group_name then
    local c = UIPushButton(self.display)
    c.group_name = self.mappings.stop_playback.group_name
    c.tooltip = self.mappings.stop_playback.description
    c:set_pos(self.mappings.stop_playback.index)
    c.on_press = function(obj)
      if not self.active then return false end
      self:_stop_playback()
      if(self.controls.play)then
        self.controls.play:set(false,true)
      end
    end
    self:_add_component(c)
    self.controls.stop = c
  end

  if self.mappings.start_playback.group_name then
    local c = UIToggleButton(self.display)
    c.group_name = self.mappings.start_playback.group_name
    c.tooltip = self.mappings.start_playback.description
    c:set_pos(self.mappings.start_playback.index)
    c.palette.foreground.color = {0xff,0xff,0xff} -- bright yellow
    c.palette.foreground.text = "►"
    c.on_change = function(obj)
      if not self.active then return false end
      local is_playing = renoise.song().transport.playing
      self:_start_playback()
      obj:set(true,true)
      -- trick control into being 'always on'
      return (not is_playing)
    end
    self:_add_component(c)
    self.controls.play = c
  end

  if self.mappings.loop_pattern.group_name then
    local c = UIToggleButton(self.display)
    c.group_name = self.mappings.loop_pattern.group_name
    c.tooltip = self.mappings.loop_pattern.description
    c:set_pos(self.mappings.loop_pattern.index)
    c.palette.foreground.color = {0x80,0xff,0xff} -- bright green
    c.palette.foreground.text = "○"
    c.on_change = function(obj)
      if not self.active then return false end
      renoise.song().transport.loop_pattern = obj.active
    end
    self:_add_component(c)
    self.controls.loop = c
  end

  if self.mappings.edit_mode.group_name then
    local c = UIToggleButton(self.display)
    c.group_name = self.mappings.edit_mode.group_name
    c.tooltip = self.mappings.edit_mode.description
    c:set_pos(self.mappings.edit_mode.index)
    c.palette.foreground.color = {0xff,0x40,0xff} -- red
    c.palette.foreground.text = "●"
    c.on_change = function(obj)
      if not self.active then return false end
      renoise.song().transport.edit_mode = obj.active
    end
    self:_add_component(c)
    self.controls.edit = c
  end

  if self.mappings.goto_next.group_name then
    local c = UIPushButton(self.display)
    c.group_name = self.mappings.goto_next.group_name
    c.tooltip = self.mappings.goto_next.description
    c:set_pos(self.mappings.goto_next.index)
    c.interval = 0.5
    c.palette.background.text = "►|"
    c.sequence = {
      {color={0xff,0xff,0xff},text="►|"},
    }
    c.on_press = function(obj)
      if not self.active then return false end
      self:_next()
    end
    --c.on_hold = function(obj)
    --end
    self:_add_component(c)
    self.controls.next = c
  end

  if self.mappings.goto_previous.group_name then
    local c = UIPushButton(self.display)
    c.group_name = self.mappings.goto_previous.group_name
    c.tooltip = self.mappings.goto_previous.description
    c:set_pos(self.mappings.goto_previous.index)
    c.interval = 0.5
    c.palette.background.text = "|◄"
    c.sequence = {
      {color={0xff,0xff,0xff},text="|◄"},
    }
    c.on_press = function(obj)
      if not self.active then return false end
      self:_previous()
    end
    --c.on_hold = function(obj)
    --end
    self:_add_component(c)
    self.controls.previous = c
  end

  if self.mappings.block_loop.group_name then
    local c = UIToggleButton(self.display)
    c.group_name = self.mappings.block_loop.group_name
    c.tooltip = self.mappings.block_loop.description
    c:set_pos(self.mappings.block_loop.index)
    c.palette.foreground.text = "□"
    c.on_change = function(obj)
      if not self.active then return false end
      renoise.song().transport.loop_block_enabled = obj.active
    end
    self:_add_component(c)
    self.controls.block = c
  end

  if self.mappings.follow_player.group_name then
   local c = UIToggleButton(self.display)
    c.group_name = self.mappings.follow_player.group_name
    c.tooltip = self.mappings.follow_player.description
    c:set_pos(self.mappings.follow_player.index)
    c.palette.foreground.color = {0x40,0xff,0xff} -- green
    c.palette.foreground.text = "▬"
    c.on_change = function(obj)
      if not self.active then return false end
      renoise.song().transport.follow_player = obj.active
    end
    self:_add_component(c)
    self.controls.follow_player = c
  end

  if self.mappings.metronome_toggle.group_name then
    local c = UIToggleButton(self.display)
    c.group_name = self.mappings.metronome_toggle.group_name
    c.tooltip = self.mappings.metronome_toggle.description
    c:set_pos(self.mappings.metronome_toggle.index)
    c.palette.foreground.text = "∆"
    c.on_change = function(obj)
      if not self.active then return false end
      renoise.song().transport.metronome_enabled = obj.active
    end
    self:_add_component(c)
    self.controls.metronome_toggle = c
  end

  -- the finishing touches --
  self:_attach_to_song()
  Application._build_app(self)
  return true

end

--------------------------------------------------------------------------------

function Transport:_start_playback()
  TRACE("Transport:_start_playback()")

  if renoise.song().transport.playing then
    -- retriggered
    if (self.options.pattern_play.value == self.PLAY_MODE_RETRIG) then
      self:_retrigger_pattern()
    elseif (self.options.pattern_play.value == self.PLAY_MODE_SCHEDULE) then
      self:_reschedule_pattern()
    elseif (self.options.pattern_play.value == self.PLAY_MODE_STOP) then
      self:_stop_playback()
    end
  else
    -- we started playing
    local pos = renoise.song().transport.playback_pos.sequence
    renoise.song().transport:trigger_sequence(pos)

  end

end

--------------------------------------------------------------------------------

function Transport:_stop_playback()
  TRACE("Transport:_stop_playback()")

  if (not renoise.song().transport.playing) then
    if (self.options.pattern_stop.value == self.STOP_MODE_PANIC) then
      renoise.song().transport:panic()
    elseif (self.options.pattern_stop.value == self.STOP_MODE_JUMP) then
      self:_jump_to_beginning()
    end
  end

  self._scheduled_pattern = nil
  if self.controls.next then
    self.controls.next.loop = false
  end
  if self.controls.previous then
    self.controls.previous.loop = false
  end
  renoise.song().transport.playing = false

end

--------------------------------------------------------------------------------

-- goto next pattern/block

function Transport:_next()
  TRACE("Transport:_next()")

  local block_mode = (self.options.jump_mode.value == self.JUMP_MODE_BLOCK)
  if self._block_loop and block_mode then
    -- move to next block loop
    renoise.song().transport:loop_block_move_forwards()
  else
    if (self.options.pattern_switch.value == self.SWITCH_MODE_SWITCH) then
      -- switch instantly
      local new_pos = renoise.song().transport.playback_pos
      self:_switch_to_seq_index(new_pos.sequence+1)
    else
      -- schedule
      local pos = self._scheduled_pattern or 
        renoise.song().transport.playback_pos.sequence
      local seq_count = #renoise.song().sequencer.pattern_sequence
      if(pos < seq_count)then
        pos = pos+1
      end
      self:_schedule_pattern(pos)
      if self.controls.previous then
        self.controls.previous.loop = false
      end
      if self.controls.next then
        self.controls.next.loop = true
      end

    end

  end


end

--------------------------------------------------------------------------------

-- goto previous pattern/block

function Transport:_previous()
  TRACE("Transport:_previous()")

  local block_mode = (self.options.jump_mode.value == self.JUMP_MODE_BLOCK)
  if self._block_loop and block_mode then
    -- move to previous block loop
    renoise.song().transport:loop_block_move_backwards()
  else
    if (self.options.pattern_switch.value == self.SWITCH_MODE_SWITCH) then
      -- switch instantly
      local new_pos = renoise.song().transport.playback_pos
      self:_switch_to_seq_index(new_pos.sequence-1)
    else
      -- schedule
      local pos = self._scheduled_pattern or 
        renoise.song().transport.playback_pos.sequence
      if(pos > 1)then
        pos = pos-1
      end
      self:_schedule_pattern(pos)
      if self.controls.previous then
        self.controls.previous.loop = true
      end
      if self.controls.next then
        self.controls.next.loop = false
      end
    end
  end

end

--------------------------------------------------------------------------------

-- schedule the provided pattern index
-- @idx  - the pattern to schedule

function Transport:_schedule_pattern(idx)
  TRACE("Transport:_schedule_pattern()",idx)

  self._scheduled_pattern = idx
  self._source_pattern = renoise.song().transport.playback_pos.sequence
  renoise.song().transport:set_scheduled_sequence(idx)

end

--------------------------------------------------------------------------------

-- re-trigger the current pattern

function Transport:_retrigger_pattern()
  TRACE("Transport:_retrigger_pattern()")

  local pos = renoise.song().transport.playback_pos
  renoise.song().transport:trigger_sequence(pos.sequence)

end

--------------------------------------------------------------------------------

-- re-schedule the current pattern

function Transport:_reschedule_pattern()
  TRACE("Transport:_reschedule_pattern()")

  local pos = renoise.song().transport.playback_pos.sequence
  renoise.song().transport:set_scheduled_sequence(pos)

end

--------------------------------------------------------------------------------

-- instantly switch to specified sequence index
-- if the line in the target pattern does not exist,start from the beginning

function Transport:_switch_to_seq_index(seq_index)
  TRACE("Transport:_switch_to_seq_index()",seq_index)

  local song = renoise.song()
  local new_pos = song.transport.playback_pos
  local patt_idx = song.sequencer.pattern_sequence[seq_index]
  local patt = song.patterns[patt_idx]
  if patt then
    local num_lines = song.patterns[patt_idx].number_of_lines
    if(new_pos.line>num_lines)then
      new_pos.line = 1
    end
    new_pos.sequence = seq_index
    song.transport.playback_pos = new_pos
  end

end

--------------------------------------------------------------------------------

-- jump to beginning of song

function Transport:_jump_to_beginning()
  TRACE("Transport:_jump_to_beginning()")

  local new_pos = renoise.song().transport.playback_pos
  new_pos.sequence = 1
  new_pos.line = 1
  renoise.song().transport.playback_pos = new_pos

end

