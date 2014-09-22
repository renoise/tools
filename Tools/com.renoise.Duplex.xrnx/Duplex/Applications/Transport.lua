--[[============================================================================
-- Duplex.Application.Transport
============================================================================]]--

--[[--
The Transport application offers transport controls for Renoise.
Inheritance: @{Duplex.Application} > Duplex.Application.Transport

     _______ _______ ______ ______ ______ ______ ________ _______
    |       |       |      |      |      |      |        |       |
    |  |◄   |   ►   |  ►|  | ∞/═  |  ■   |  ●   |   ↓    |   ∆   |
    | Prev  | Play  | Next | Loop | Stop | Edit | Follow | Metro |
    |_______|_______|______|______|______|______|________|_______|
     _______________ ______ ______ ______
    |               |      |      |      |
    |   01:04.25    |  +   | 95.2 |  -   |
    |  Song playpos | BPM  | BPM  | BPM  |
    |_______________|______|______|______|


### Changes
  
  0.98  
    - New mapping: "metronome_toggle", minor optimizations
  0.96  
    - Fixed: Option "pattern_switch" didn't switch instantly
  0.92  
    - New option: "stop playback" (playback toggle button)
  0.91  
    - Fixed: always turn off "start" when hitting "stop"
  0.90  
    - Follow player option
  0.81  
    - First release

--]]

--==============================================================================

-- constants

local SWITCH_MODE_SWITCH = 1
local SWITCH_MODE_SCHEDULE = 2

local PLAY_MODE_RETRIG = 1
local PLAY_MODE_SCHEDULE = 2
local PLAY_MODE_STOP = 3

local STOP_MODE_PANIC = 1
local STOP_MODE_JUMP = 2

local JUMP_MODE_NORMAL = 1
local JUMP_MODE_BLOCK = 2

local BPM_MINIMUM = 32
local BPM_MAXIMUM = 999

--==============================================================================

class 'Transport' (Application)

--- These are the default options for the application
--
-- @field pattern_switch Choose how next/previous buttons will work
-- @field pattern_play When play is pressed, choose an action
-- @field pattern_stop When stop is pressed *twice*, choose an action
-- @field jump_mode Choose between standard pattern or hybrid pattern/block-loop control
-- @table default_options
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

--- These are the available mappings for the application
--
Transport.available_mappings = {
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
    description = "Transport: toggle on/off",
  },
  bpm_increase = {
    description = "Transport: increase BPM",
  },
  bpm_decrease = {
    description = "Transport: decrease BPM",
  },
  bpm_display = {
    description = "Transport: display current BPM",
  },
  songpos_display = {
    description = "Transport: display song-position",
  }
}

Transport.default_palette = {
  edit_mode_off = {     color = {0x00,0x00,0x00}, text = "●", val = false,},
  edit_mode_on = {      color = {0xff,0x40,0x40}, text = "●", val = true, },
  follow_player_off = { color = {0x00,0x00,0x00}, text = "↓", val = false },
  follow_player_on = {  color = {0x40,0xff,0x40}, text = "↓", val = true  },
  loop_block_off = {    color = {0x00,0x00,0x00}, text = "═", val = false,},
  loop_block_on = {     color = {0xff,0xff,0xff}, text = "═", val = true  },
  loop_pattern_off = {  color = {0x00,0x00,0x00}, text = "∞", val = false,},
  loop_pattern_on = {   color = {0x80,0xff,0x40}, text = "∞", val = true  },
  metronome_off = {     color = {0x00,0x00,0x00}, text = "∆", val = false,},
  metronome_on = {      color = {0x80,0x80,0x80}, text = "∆", val = true, },
  next_patt_dimmed = {  color = {0x80,0x80,0x80}, text = "►|",val = false,},
  next_patt_off = {     color = {0x00,0x00,0x00}, text = "►|",val = false,},
  next_patt_on = {      color = {0xff,0xff,0xff}, text = "►|",val = true, },
  playing_off = {       color = {0x00,0x00,0x00}, text = "►", val = false,},
  playing_on = {        color = {0xff,0xff,0xff}, text = "►", val = true  },
  prev_patt_dimmed = {  color = {0x80,0x80,0x80}, text = "|◄",val = false,},
  prev_patt_off = {     color = {0x00,0x00,0x00}, text = "|◄",val = false,},
  prev_patt_on = {      color = {0xff,0xff,0xff}, text = "|◄",val = true, },
  stop_playback_off = { color = {0x00,0x00,0x00}, text = "■", val = false,},
  stop_playback_on = {  color = {0xff,0xff,0xff}, text = "□", val = true, },
  bpm_increase_off = {  color = {0x00,0x00,0x00}, text = "+", val = false,},
  bpm_increase_on = {   color = {0xff,0xff,0xff}, text = "+", val = true, },
  bpm_decrease_off = {  color = {0x00,0x00,0x00}, text = "-", val = false,},
  bpm_decrease_on = {   color = {0xff,0xff,0xff}, text = "-", val = true, },
}


--------------------------------------------------------------------------------

--- Constructor method
-- @param (VarArg)
-- @see Duplex.Application

function Transport:__init(...)
  TRACE("Transport:__init(",...)


  -- private stuff

  -- (int), scheduled target sequence index 
  self._scheduled_pattern = nil

  -- (int), scheduled source sequence index 
  self._source_pattern = nil

  -- (number) copy of playback_pos_beats
  self._pos_beats = nil

  -- (bool) current status of the block loop
  self._block_loop = nil

  -- the various UIComponents
  self.controls = {}

  Application.__init(self,...)


end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.start_app
-- @return bool or nil

function Transport:start_app()
  TRACE("Transport.start_app()")

  if not Application.start_app(self) then
    return
  end

  self:update_everything()

end

--------------------------------------------------------------------------------

--- periodic updates: check if any of the "un-observable" 
-- properties have changed (block loop and schedule pattern)

function Transport:on_idle()

  if not self.active then 
    return 
  end

  local loop_block_enabled = renoise.song().transport.loop_block_enabled
  local loop_pattern = renoise.song().transport.loop_pattern

  -- update 'block_loop' status
  if (self._block_loop ~= loop_block_enabled) then
    self:update_block_loop()
    self._block_loop = loop_block_enabled
  end

  -- check if we have arrived at the scheduled pattern
  if (self._scheduled_pattern)then
    local pos = renoise.song().transport.playback_pos.sequence
    if(self._scheduled_pattern == pos) or
      (pos~=self._source_pattern) then
      
      self:clear_schedule()
    elseif (self._scheduled_button) then
      self:update_scheduled_buttons()
    end

  end

  -- update song-position display
  if self.controls.songpos_display then
    local pos_beats = renoise.song().transport.playback_pos_beats
    if pos_beats ~= self._pos_beats then
      --print("*** pos_beats",pos_beats)
      self._pos_beats = pos_beats
      -- format output like this: bars:beats.fraction (16:03.2)
      local lpb = renoise.song().transport.lpb
      local bars = math.floor(pos_beats/lpb)
      local beats = (math.floor(pos_beats)%lpb)
      local fraction = select(2,math.modf(pos_beats))*100
      local str_songpos = ("%.02d:%.02d.%.1s"):format(bars,beats,fraction)
      --print("*** str_songpos",str_songpos)
      self.controls.songpos_display:set_text(str_songpos)
    end
  end

end

--------------------------------------------------------------------------------

--- control periodic blinking by the playback line number 

function Transport:update_scheduled_buttons()

    local playing = renoise.song().transport.playing
    local lpb = renoise.song().transport.lpb
    local pos = playing 
      and renoise.song().transport.playback_pos 
      or renoise.song().transport.edit_pos
    -- 'blink' when we have moved a certain distance
    local is_prev = (self._scheduled_button == self.controls.previous)
    local blink = (math.floor((((pos.line-1)/lpb))%2) == 0)
    if blink then
      if is_prev then
        self.controls.previous:set(self.palette.prev_patt_off)
      else
        self.controls.next:set(self.palette.next_patt_off)
      end
    else
      if is_prev then
        self.controls.previous:set(self.palette.prev_patt_on)
      else
        self.controls.next:set(self.palette.next_patt_on)
      end
    end

end

--------------------------------------------------------------------------------

--- set the schedule buttons to default state, and tell the application that
-- no pattern has been scheduled (note that if the current pattern has been 
-- scheduled, it is not considered as we can't access the schedule list)

function Transport:clear_schedule()

  self._scheduled_pattern = nil

  local bt_next = self.controls.next
  local bt_prev = self.controls.previous
  if bt_next then
    bt_next:set(self.palette.next_patt_off)
  end
  if bt_prev then
    bt_prev:set(self.palette.prev_patt_off)
  end

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_new_document

function Transport:on_new_document()
  TRACE("Transport.on_new_document()")

  self:_attach_to_song()

end

--------------------------------------------------------------------------------

--- add notifiers to song, initialize certain properties

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
      if not renoise.song().transport.playing then
        self:clear_schedule()
      end

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

  song.transport.bpm_observable:add_notifier(
    function()
      TRACE("Transport.bpm_observable fired...")
      self:update_bpm_display()
    end
  )
  self:update_bpm_display()

end

--------------------------------------------------------------------------------

--- Update display of the BPM 

function Transport:update_bpm_display()
  TRACE("Transport:update_bpm_display()")

  --print("*** self.controls.bpm_display",self.controls.bpm_display)
  if self.controls.bpm_display then
    self.controls.bpm_display:set_text(renoise.song().transport.bpm)
  end

end

--------------------------------------------------------------------------------

--- Update display of the metronome 

function Transport:update_metronome_enabled()
  TRACE("Transport:update_metronome_enabled()")
  if not self.active then 
    return false 
  end
  if self.controls.metronome_toggle then
    if (renoise.song().transport.metronome_enabled) then
      self.controls.metronome_toggle:set(self.palette.metronome_on)
    else
      self.controls.metronome_toggle:set(self.palette.metronome_off)
    end
  end
end

--------------------------------------------------------------------------------

--- Update display of play-follow 

function Transport:update_follow_player()
  if not self.active then 
    return false 
  end
  if self.controls.follow_player then
    if (renoise.song().transport.follow_player) then
      self.controls.follow_player:set(self.palette.follow_player_on)
    else
      self.controls.follow_player:set(self.palette.follow_player_off)
    end
  end
end

--------------------------------------------------------------------------------

--- Update display of the play button 

function Transport:update_playing()
  if not self.active then 
    return false 
  end
  if self.controls.play then
    if renoise.song().transport.playing then
      self.controls.play:set(self.palette.playing_on)
    else
      self.controls.play:set(self.palette.playing_off)
    end
  end
end

--------------------------------------------------------------------------------

--- Update display of the loop button 

function Transport:update_loop_pattern()
  if not self.active then 
    return false 
  end
  if self.controls.loop then
    if renoise.song().transport.loop_pattern then
      self.controls.loop:set(self.palette.loop_pattern_on)
    else
      self.controls.loop:set(self.palette.loop_pattern_off)
    end
  end
end

--------------------------------------------------------------------------------

--- Update display of the edit-mode button 

function Transport:update_edit_mode()
  if not self.active then 
    return false 
  end
  if self.controls.edit then
    if renoise.song().transport.edit_mode then
      self.controls.edit:set(self.palette.edit_mode_on)
    else
      self.controls.edit:set(self.palette.edit_mode_off)
    end
  end
end

--------------------------------------------------------------------------------

--- Update display of the block-loop button 

function Transport:update_block_loop()
  if not self.active then 
    return false 
  end
  if self.controls.block then
    if renoise.song().transport.loop_block_enabled then
      self.controls.block:set(self.palette.loop_block_on)
    else
      self.controls.block:set(self.palette.loop_block_off)
    end
  end
end

--------------------------------------------------------------------------------

-- Update display of everything

function Transport:update_everything()
  TRACE("Transport:update_everything()")

  self:update_metronome_enabled()
  self:update_follow_player()
  self:update_playing()
  self:update_loop_pattern()
  self:update_edit_mode()
  self:update_block_loop()

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application._build_app
-- @return bool

function Transport:_build_app()
  TRACE("Transport:_build_app()")

  local map = self.mappings.stop_playback
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c:set(self.palette.stop_playback_off)
    c.on_press = function(obj)
      self:_stop_playback()
      obj:flash(0.1,
        self.palette.stop_playback_on,
        self.palette.stop_playback_off)
    end
    self.controls.stop = c
  end

  local map = self.mappings.start_playback
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function(obj)
      self:_start_playback()
    end
    self.controls.play = c
  end

  local map = self.mappings.loop_pattern
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function(obj)
      local loop_pattern = renoise.song().transport.loop_pattern
      renoise.song().transport.loop_pattern = not loop_pattern
    end
    self.controls.loop = c
  end

  local map = self.mappings.edit_mode
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function(obj)
      local edit_mode = renoise.song().transport.edit_mode
      renoise.song().transport.edit_mode = not edit_mode
    end
    self.controls.edit = c
  end

  local map = self.mappings.goto_next
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c:set(self.palette.next_patt_off)
    c.on_press = function(obj)
      self:_next()
    end
    self.controls.next = c
  end

  local map = self.mappings.goto_previous
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c:set(self.palette.prev_patt_off)
    c.on_press = function(obj)
      self:_previous()
    end
    self.controls.previous = c
  end

  local map = self.mappings.block_loop
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function(obj)
      local block_enabled = renoise.song().transport.loop_block_enabled
      renoise.song().transport.loop_block_enabled = not block_enabled
    end
    self.controls.block = c
  end

  local map = self.mappings.follow_player
  if map.group_name then
   local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function(obj)
      local active = renoise.song().transport.follow_player
      renoise.song().transport.follow_player = not active
    end
    self.controls.follow_player = c
  end

  local map = self.mappings.metronome_toggle
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function(obj)
      local metronome_enabled = renoise.song().transport.metronome_enabled
      renoise.song().transport.metronome_enabled = not metronome_enabled
    end
    self.controls.metronome_toggle = c
  end

  local map = self.mappings.bpm_increase
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c:set(self.palette.bpm_increase_off)
    c.on_press = function(obj)
      local bpm = math.min(BPM_MAXIMUM,renoise.song().transport.bpm+1)
      if (bpm~=renoise.song().transport.bpm) then
        renoise.song().transport.bpm = bpm
        self.controls.bpm_increase:flash(0.1,
          self.palette.bpm_increase_on,
          self.palette.bpm_increase_off)
      end
    end
    self.controls.bpm_increase = c
  end

  local map = self.mappings.bpm_decrease
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c:set(self.palette.bpm_decrease_off)
    c.on_press = function(obj)
      local bpm = math.max(BPM_MINIMUM,renoise.song().transport.bpm-1)
      if (bpm~=renoise.song().transport.bpm) then
        renoise.song().transport.bpm = bpm
        self.controls.bpm_decrease:flash(0.1,
          self.palette.bpm_decrease_on,
          self.palette.bpm_decrease_off)
      end
    end
    self.controls.bpm_decrease = c
  end

  local map = self.mappings.bpm_display
  if map.group_name then
    local c = UILabel(self)
    c.group_name = map.group_name
    c:set_pos(map.index)
    self.controls.bpm_display = c
  end

  local map = self.mappings.songpos_display
  if map.group_name then
    local c = UILabel(self)
    c.group_name = map.group_name
    c:set_pos(map.index)
    self.controls.songpos_display = c
  end

  -- the finishing touches --
  self:_attach_to_song()
  Application._build_app(self)
  return true

end

--------------------------------------------------------------------------------

--- when "play" button is pressed

function Transport:_start_playback()
  TRACE("Transport:_start_playback()")

  if renoise.song().transport.playing then
    -- retriggered
    if (self.options.pattern_play.value == PLAY_MODE_RETRIG) then
      self:_retrigger_pattern()
    elseif (self.options.pattern_play.value == PLAY_MODE_SCHEDULE) then
      self:_reschedule_pattern()
    elseif (self.options.pattern_play.value == PLAY_MODE_STOP) then
      self:_stop_playback()
    end
  else
    -- we started playing
    local pos = renoise.song().transport.playback_pos.sequence
    renoise.song().transport:trigger_sequence(pos)

  end

end

--------------------------------------------------------------------------------

--- when "stop" button is pressed

function Transport:_stop_playback()
  TRACE("Transport:_stop_playback()")

  if (not renoise.song().transport.playing) then
    if (self.options.pattern_stop.value == STOP_MODE_PANIC) then
      renoise.song().transport:panic()
    elseif (self.options.pattern_stop.value == STOP_MODE_JUMP) then
      self:_jump_to_beginning()
    end
  end

  self:clear_schedule()

  renoise.song().transport.playing = false

  if(self.controls.play)then
    self.controls.play:set(self.palette.playing_off)
  end

end

--------------------------------------------------------------------------------

--- when "next" button is pressed

function Transport:_next()
  TRACE("Transport:_next()")

  local block_mode = (self.options.jump_mode.value == JUMP_MODE_BLOCK)
  if self._block_loop and block_mode then
    -- move to next block loop
    renoise.song().transport:loop_block_move_forwards()
  else
    if (self.options.pattern_switch.value == SWITCH_MODE_SWITCH) then
      -- switch instantly
      local new_pos = renoise.song().transport.playback_pos
      self:_switch_to_seq_index(new_pos.sequence+1)
      if self.controls.next then
        self.controls.next:flash(0.1,
          self.palette.next_patt_on,
          self.palette.next_patt_dimmed,
          self.palette.next_patt_off)
      end
    else
      -- schedule
      local pos = self._scheduled_pattern or 
        renoise.song().transport.playback_pos.sequence
      local seq_count = #renoise.song().sequencer.pattern_sequence
      if(pos < seq_count)then
        pos = pos+1
      end
      self:_schedule_pattern(pos,self.controls.next)
    end
  end

end

--------------------------------------------------------------------------------

--- when "previous" button is pressed

function Transport:_previous()
  TRACE("Transport:_previous()")

  local block_mode = (self.options.jump_mode.value == JUMP_MODE_BLOCK)
  if self._block_loop and block_mode then
    -- move to previous block loop
    renoise.song().transport:loop_block_move_backwards()
  else
    if (self.options.pattern_switch.value == SWITCH_MODE_SWITCH) then
      -- switch instantly
      local new_pos = renoise.song().transport.playback_pos
      self:_switch_to_seq_index(new_pos.sequence-1)
      if self.controls.previous then
        self.controls.previous:flash(0.1,
          self.palette.prev_patt_on,
          self.palette.prev_patt_dimmed,
          self.palette.prev_patt_off)
      end
    else
      -- schedule
      local pos = self._scheduled_pattern or 
        renoise.song().transport.playback_pos.sequence
      if(pos > 1)then
        pos = pos-1
      end
      self:_schedule_pattern(pos,self.controls.previous)
    end
  end

end

--------------------------------------------------------------------------------

--- schedule the provided pattern index
-- @param idx  - the pattern to schedule
-- @param button UIButton, the pressed button (next or previous)

function Transport:_schedule_pattern(idx,button)
  TRACE("Transport:_schedule_pattern()",idx)

  self._scheduled_pattern = idx
  self._scheduled_button = button
  self._source_pattern = renoise.song().transport.playback_pos.sequence
  renoise.song().transport:set_scheduled_sequence(idx)

end

--------------------------------------------------------------------------------

--- re-trigger the current pattern

function Transport:_retrigger_pattern()
  TRACE("Transport:_retrigger_pattern()")

  local pos = renoise.song().transport.playback_pos
  renoise.song().transport:trigger_sequence(pos.sequence)

end

--------------------------------------------------------------------------------

--- re-schedule the current pattern

function Transport:_reschedule_pattern()
  TRACE("Transport:_reschedule_pattern()")

  self:clear_schedule()
  local pos = renoise.song().transport.playback_pos.sequence
  renoise.song().transport:set_scheduled_sequence(pos)

end

--------------------------------------------------------------------------------

--- instantly switch to specified sequence index
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

--- jump to beginning of song

function Transport:_jump_to_beginning()
  TRACE("Transport:_jump_to_beginning()")

  local new_pos = renoise.song().transport.playback_pos
  new_pos.sequence = 1
  new_pos.line = 1
  renoise.song().transport.playback_pos = new_pos

end

