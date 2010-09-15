--[[----------------------------------------------------------------------------
-- Duplex.Transport
----------------------------------------------------------------------------]]--

--[[

About

The Transport application is aimed at controlling the playback position


Mappings 

stop_playback     (trigger)   short blink
start_playback    (toggle)    on/off (listener) 
loop_pattern      (toggle)    on/off (listener)
edit_mode         (toggle)    on/off (listener)
goto_next         (triggers)  instant/scheduled blink
goto_previous     (triggers)  instant/scheduled blink
block_loop        (toggle)    on/off (listener)
follow_player     (toogle)    on/off (listener)

Options

pattern_switch    switch / schedule 
pattern_play      retrigger / schedule 
pattern_stop      panic / rewind
bpm_range         32-160 / 72-200 / 112-240 / 152-280


--]]

--==============================================================================


class 'Transport' (Application)

function Transport:__init(display,mappings,options)
  TRACE("Transport:__init(",display,mappings,options)

  Application.__init(self)

  self.display = display

  -- define the options (with defaults)

  self.PLAY_MODE_RETRIG = 1
  self.PLAY_MODE_SCHEDULE = 2
  self.PLAY_MODE_STOP = 3

  self.SWITCH_MODE_SWITCH = 1
  self.SWITCH_MODE_SCHEDULE = 2

  self.STOP_MODE_PANIC = 1
  self.STOP_MODE_JUMP = 2


  self.options = {
    pattern_switch = {
      label = "Next/previous pattern",
      items = {"Switch instantly","Schedule pattern"},
      default = 1,
    },
    pattern_play = {
      label = "Play pressed twice",
      items = {"Retrigger current pattern","Schedule current pattern","Stop playback"},
      default = 1,
    },
    pattern_stop = {
      label = "Stop pressed twice",
      items = {"Panic (stop all)","Jump to beginning"},
      default = 1,
    },
    --[[
    bpm_range = {
      label = "Range of BPM control",
      items = {"32-160","72-200","112-240","152-280"},
      default = 2,
    },
    ]]
  }

  self.mappings = {
    stop_playback = {
      description = "Stop playback",
      ui_component = UI_COMPONENT_PUSHBUTTON,
    },
    start_playback = {
      description = "Start playback",    
      ui_component = UI_COMPONENT_TOGGLEBUTTON,
    },
    loop_pattern = {
      description = "Toggle pattern looping",
      ui_component = UI_COMPONENT_TOGGLEBUTTON,
    },
    edit_mode = {
      description = "Toggle edit-mode",
      ui_component = UI_COMPONENT_TOGGLEBUTTON,
    },
    follow_player = {
      description = "Toggle play-follow mode",
      ui_component = UI_COMPONENT_TOGGLEBUTTON,
    },
    goto_next = {
      description = "Goto next pattern/block",    
      ui_component = UI_COMPONENT_PUSHBUTTON,
    },
    goto_previous = {
      description = "Goto previous pattern/block",    
      ui_component = UI_COMPONENT_PUSHBUTTON,
    },
    block_loop = {
      description = "Toggle block-loop mode",    
      ui_component = UI_COMPONENT_TOGGLEBUTTON,
    },
    --[[
    -- TODO
    set_bpm = {
      description = "Adjust the BPM rate. Assign to a dial or fader",    
    },
    ]]
  
  }


  -- private stuff

  -- number, set when not yet arrived at the scheduled pattern 
  self.__scheduled_pattern = nil
  self.__source_pattern = nil

  self.__playing = nil
  self.__pattern_loop = nil
  self.__block_loop = nil
  self.__edit_mode = nil
  self.__follow_player = nil


  -- the various UIComponents
  self.controls = {}

  -- apply arguments
  self:__apply_options(options)
  self:__apply_mappings(mappings)


end

--------------------------------------------------------------------------------

function Transport:start_app()
  TRACE("Transport.start_app()")

  if not (self.__created) then 
    self:__build_app()
  end

  Application.start_app(self)

end

--------------------------------------------------------------------------------

-- periodic updates: this is where we check if any of the watched 
-- properties have changed (most are not observable)

function Transport:on_idle()

  if (not self.active) then return end

  local playing = renoise.song().transport.playing
  local loop_block_enabled = renoise.song().transport.loop_block_enabled
  local loop_pattern = renoise.song().transport.loop_pattern
  local edit_mode = renoise.song().transport.edit_mode
  local follow_player = renoise.song().transport.follow_player

  -- update 'play' status
  if (playing ~= self.__playing) then
    if self.controls.play then
      self.controls.play:set(playing,true)
    end
    self.__playing = playing
  end

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
  if (self.__block_loop ~= loop_block_enabled) then
    if self.controls.block then
      self.controls.block:set(loop_block_enabled,true)
    end
    self.__block_loop = loop_block_enabled
  end

  -- update 'pattern_loop' status
  if (self.__pattern_loop ~= loop_pattern) then
    if self.controls.loop then
      self.controls.loop:set(loop_pattern,true)
    end
    self.__pattern_loop = loop_pattern
  end

  -- update 'edit_mode' status
  if (self.__edit_mode ~= edit_mode) then
    if self.controls.edit then
      self.controls.edit:set(edit_mode,true)
    end
    self.__edit_mode = edit_mode
  end

  -- update 'follow_player' status
  if (self.__follow_player ~= follow_player) then
    if self.controls.follow_player then
      self.controls.follow_player:set(follow_player,true)
    end
    self.__follow_player = follow_player
  end

  -- check if we have arrived at the scheduled pattern
  if (self.__scheduled_pattern)then
    local pos = renoise.song().transport.playback_pos.sequence
    if(self.__scheduled_pattern==pos) or
      (pos~=self.__source_pattern) then
      self.__scheduled_pattern = nil
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

function Transport:__build_app()
  TRACE("Transport:__build_app()")

  if self.mappings.stop_playback.group_name then
    local c = UIPushButton(self.display)
    c.group_name = self.mappings.stop_playback.group_name
    c.tooltip = self.mappings.stop_playback.description
    c:set_pos(self.mappings.stop_playback.index)
    c.on_press = function(obj)
      if not self.active then return false end
      self:__stop_playback()
      if(self.controls.play)then
        self.controls.play:set(false,true)
      end
    end
    self:__add_component(c)
    self.controls.stop = c
  end

  if self.mappings.start_playback.group_name then
    local c = UIToggleButton(self.display)
    c.group_name = self.mappings.start_playback.group_name
    c.tooltip = self.mappings.start_playback.description
    c:set_pos(self.mappings.start_playback.index)
    c.palette.foreground.color = {0xff,0xff,0x40} -- bright yellow
    c.palette.foreground.text = "►"
    c.on_change = function(obj)
      if not self.active then return false end
      local is_playing = renoise.song().transport.playing
      self:__start_playback()
      obj:set(true,true)
      -- update only when switching ON:
      -- this tricks it into being 'always on'
      return (not is_playing) and (self.__playing)
    end
    self:__add_component(c)
    self.controls.play = c
  end

  if self.mappings.loop_pattern.group_name then
    local c = UIToggleButton(self.display)
    c.group_name = self.mappings.loop_pattern.group_name
    c.tooltip = self.mappings.loop_pattern.description
    c:set_pos(self.mappings.loop_pattern.index)
    c.palette.foreground.color = {0x80,0xff,0x40} -- bright green
    c.palette.foreground.text = "○"
    c.on_change = function(obj)
      if not self.active then return false end
      renoise.song().transport.loop_pattern = obj.active
    end
    self:__add_component(c)
    self.controls.loop = c
  end

  if self.mappings.edit_mode.group_name then
    local c = UIToggleButton(self.display)
    c.group_name = self.mappings.edit_mode.group_name
    c.tooltip = self.mappings.edit_mode.description
    c:set_pos(self.mappings.edit_mode.index)
    c.palette.foreground.color = {0xff,0x40,0x40} -- red
    c.palette.foreground.text = "●"
    c.on_change = function(obj)
      if not self.active then return false end
      renoise.song().transport.edit_mode = obj.active
    end
    self:__add_component(c)
    self.controls.edit = c
  end

  if self.mappings.goto_next.group_name then
    local c = UIPushButton(self.display)
    c.group_name = self.mappings.goto_next.group_name
    c.tooltip = self.mappings.goto_next.description
    c:set_pos(self.mappings.goto_next.index)
    c.interval = 0.5
    c.sequence = {
      {color={0xff,0xff,0xff},text="►"},
      {color={0x00,0x00,0x00},text=" "},
    }
    c.on_press = function(obj)
      if not self.active then return false end
      self:__next()
    end
    self:__add_component(c)
    self.controls.next = c
  end

  if self.mappings.goto_previous.group_name then
    local c = UIPushButton(self.display)
    c.group_name = self.mappings.goto_previous.group_name
    c.tooltip = self.mappings.goto_previous.description
    c:set_pos(self.mappings.goto_previous.index)
    c.interval = 0.5
    c.sequence = {
      {color={0xff,0xff,0xff},text="◄"},
      {color={0x00,0x00,0x00},text=" "},
    }
    c.on_press = function(obj)
      if not self.active then return false end
      self:__previous()
    end
    self:__add_component(c)
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
    self:__add_component(c)
    self.controls.block = c
  end

  if self.mappings.follow_player.group_name then
    local c = UIToggleButton(self.display)
    c.group_name = self.mappings.follow_player.group_name
    c.tooltip = self.mappings.follow_player.description
    c:set_pos(self.mappings.follow_player.index)
    c.palette.foreground.color = {0x40,0xff,0x40} -- green
    c.palette.foreground.text = "▬"
    c.on_change = function(obj)
      if not self.active then return false end
      --renoise.song().transport.loop_block_enabled = obj.active
      renoise.song().transport.follow_player = obj.active
    end
    self:__add_component(c)
    self.controls.follow_player = c
  end

  Application.__build_app(self)

end

--------------------------------------------------------------------------------

function Transport:__start_playback()

  if self.__playing then
    -- retriggered
    if (self.options.pattern_play.value == self.PLAY_MODE_RETRIG) then
      self:__retrigger_pattern()
    elseif (self.options.pattern_play.value == self.PLAY_MODE_SCHEDULE) then
      self:__reschedule_pattern()
    elseif (self.options.pattern_play.value == self.PLAY_MODE_STOP) then
      self:__stop_playback()
    end
  else
    -- we started playing
    local pos = renoise.song().transport.playback_pos.sequence
    renoise.song().transport:trigger_sequence(pos)

  end

  self.__playing = true

end

--------------------------------------------------------------------------------

function Transport:__stop_playback()

  if (not self.__playing) then
    if (self.options.pattern_stop.value == self.STOP_MODE_PANIC) then
      renoise.song().transport:panic()
    elseif (self.options.pattern_stop.value == self.STOP_MODE_JUMP) then
      self:__jump_to_beginning()
    end

  end

  self.__scheduled_pattern = nil
  if self.controls.next then
    self.controls.next.loop = false
  end
  if self.controls.previous then
    self.controls.previous.loop = false
  end
  renoise.song().transport.playing = false
  self.__playing = false

end

--------------------------------------------------------------------------------

-- goto next pattern/block

function Transport:__next()

  if renoise.song().transport.loop_block_enabled then
    renoise.song().transport:loop_block_move_forwards()
  else

    local pos = self.__scheduled_pattern or 
      renoise.song().transport.playback_pos.sequence
    local seq_count = #renoise.song().sequencer.pattern_sequence
    if(pos < seq_count)then
      pos = pos+1
    end
    self:__schedule_pattern(pos)
    if self.controls.previous then
      self.controls.previous.loop = false
    end
    if self.controls.next then
      self.controls.next.loop = true
    end

  end


end

--------------------------------------------------------------------------------

-- goto previous pattern/block

function Transport:__previous()

  if renoise.song().transport.loop_block_enabled then
    renoise.song().transport:loop_block_move_backwards()
  else
    local pos = self.__scheduled_pattern or 
      renoise.song().transport.playback_pos.sequence
    if(pos > 1)then
      pos = pos-1
    end
    self:__schedule_pattern(pos)
    if self.controls.previous then
      self.controls.previous.loop = true
    end
    if self.controls.next then
      self.controls.next.loop = false
    end

  end

end

--------------------------------------------------------------------------------

-- schedule the provided pattern index
-- @idx  - the pattern to schedule

function Transport:__schedule_pattern(idx)
  self.__scheduled_pattern = idx
  self.__source_pattern = renoise.song().transport.playback_pos.sequence
  renoise.song().transport:set_scheduled_sequence(idx)

end

--------------------------------------------------------------------------------

-- re-trigger the current pattern

function Transport:__retrigger_pattern()

  local pos = renoise.song().transport.playback_pos
  renoise.song().transport:trigger_sequence(pos.sequence)

end

--------------------------------------------------------------------------------

-- re-schedule the current pattern

function Transport:__reschedule_pattern()

  local pos = renoise.song().transport.playback_pos.sequence
  renoise.song().transport:set_scheduled_sequence(pos)

end

--------------------------------------------------------------------------------

-- jump to beginning of song

function Transport:__jump_to_beginning()

  local new_pos = renoise.song().transport.playback_pos
  new_pos.sequence = 1
  new_pos.line = 1
  renoise.song().transport.playback_pos = new_pos

end

