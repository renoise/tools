--[[----------------------------------------------------------------------------
-- Duplex.PatternMatrix
----------------------------------------------------------------------------]]--

--[[

A functional pattern-matrix (basic mute/unmute operations)

Recommended hardware: a monome/launchpad-style grid controller 

--]]

module("Duplex", package.seeall);

--==============================================================================

class 'PatternMatrix' (Application)


function PatternMatrix:__init(display)
  TRACE("PatternMatrix:__init",display)

  -- constructor 
  Application.__init(self)
  
  self.buttons = nil
  self.position = nil
  self.display = display
  self:build_app()

  self.__update_slots_requested = false
  self:__attach_to_song(renoise.song())
end


--------------------------------------------------------------------------------

function PatternMatrix:build_app()
  TRACE("PatternMatrix:build_app()")

  Application.build_app(self)

  local observable = nil

  -- TODO quick hack to make a Slider appear like a selector
  -- (make proper Selector class)
  self.position = Slider(self.display)
  self.position.group_name = "Triggers"
  self.position.x_pos = 1
  self.position.y_pos = 1
  --self.position.toggleable = true
  self.position.flipped = true
  self.position.ceiling = 8
  self.position.palette.medium.text="·"
  self.position.palette.medium.color={0x00,0x00,0x00}
  self.position:set_size(8)
  self.position.on_change = function(obj) 
    if not self.active then
      print('Application is sleeping')
    elseif obj.index==0 then
      -- turn off playback
      renoise.song().transport.stop(renoise.song().transport)
    elseif not renoise.song().sequencer.pattern_sequence[obj.index] then
      print('Pattern is out of bounds')
      return false
    else
      -- instantly change to new song pos
      local new_pos = renoise.song().transport.playback_pos
      new_pos.sequence = obj.index
      renoise.song().transport.playback_pos = new_pos

      -- start playback if not playing
      if (not renoise.song().transport.playing) then
        renoise.song().transport:start(
          renoise.Transport.PLAYMODE_RESTART_PATTERN)
      end
    end
    
    return true
  end
  self.display:add(self.position)

  self.buttons = {}

  for x=1,8 do
    self.buttons[x] = {}

    for y=1,8 do
      self.buttons[x][y] = ToggleButton(self.display)
      self.buttons[x][y].group_name = "Grid"
      self.buttons[x][y].x_pos = x
      self.buttons[x][y].y_pos = y
      self.buttons[x][y].active = false

      -- mute state changed from controller
      self.buttons[x][y].on_change = function(obj) 
        local seq = renoise.song().sequencer.pattern_sequence

        if not self.active then
          print('Application is sleeping')
          return false
        elseif not renoise.song().tracks[x] then
          print('Track is outside bounds')
          return false
        elseif not seq[y] then
          print('Pattern is outside bounds')
          return false
        else
          renoise.song().sequencer:set_track_sequence_slot_is_muted(
            x,y,(not obj.active))-- "active" is negated
        end
        return true
      end

      self.display:add(self.buttons[x][y])

    end  
  end
end



--------------------------------------------------------------------------------

-- function to update all slots' visual appeareance

function PatternMatrix:update_slots()
  if self.__update_slots_requested then
    -- do a lazy updates in idle...
    return
  end

  TRACE("PatternMatrix:update_slots()",self.__update_slots_requested)

  local sequence = renoise.song().sequencer.pattern_sequence
  local tracks = renoise.song().tracks
  
  for track_idx = 1,math.min(#tracks, 8) do
    for seq_index = 1,math.min(#sequence, 8) do
      local patt_idx = sequence[seq_index]
      
      local slot_muted = renoise.song().sequencer:track_sequence_slot_is_muted(
        track_idx, seq_index)
      
      local slot_empty = renoise.song().patterns[patt_idx].tracks[track_idx].is_empty

          -- custom palettes for toggle-buttons: 
      local button = self.buttons[track_idx][seq_index]

      if (not slot_empty) then
        button.palette.foreground.text="■"
        button.palette.foreground.color={0xff,0xff,0x00}
        button.palette.foreground_dimmed.text="■"
        button.palette.foreground_dimmed.color={0xff,0xff,0x00}
        button.palette.background.text="□"
        button.palette.background.color={0x80,0x40,0x00}
     
          else
        button.palette.foreground.text="·"
        button.palette.foreground.color={0x00,0x00,0x00}
        button.palette.foreground_dimmed.text="·"
        button.palette.foreground_dimmed.color={0x00,0x00,0x00}
        button.palette.background.text="▫"
        button.palette.background.color={0x40,0x00,0x00}
          end

      button:set_dimmed(slot_empty)
      button.active = (not slot_muted)
      end
    end
end


--------------------------------------------------------------------------------

-- playback-pos changed in renoise

function PatternMatrix:set_offset(val)
  TRACE("PatternMatrix:set_offset",val)
  self.position:set_index(val,true)
end


--------------------------------------------------------------------------------

function PatternMatrix:start_app()
  TRACE("PatternMatrix.start_app()")

  Application.start_app(self)
  self:update_slots()

end


--------------------------------------------------------------------------------

function PatternMatrix:destroy_app()
  TRACE("PatternMatrix:destroy_app")

  Application.destroy_app(self)

  self.position:remove_listeners()
  for i=1,8 do
    for o=1,8 do
      self.buttons[i][o]:remove_listeners()
    end
  end

end


--------------------------------------------------------------------------------

-- periodic updates: handle "un-observable" things here

function PatternMatrix:idle_app()
  TRACE("PatternMatrix:idle_app()",self.__update_slots_requested)
  
  if (not self.active) then 
    return false 
  end

  -- updated slots?
  if (self.__update_slots_requested) then
    self.__update_slots_requested = false
    self.update_slots(self)
  end

  -- changed pattern?
  local pos = renoise.song().transport.playback_pos
  if not (pos.sequence == self.position.index)then
    self.set_offset(self,pos.sequence)
  end

  self.playback_line = pos.line
end


--------------------------------------------------------------------------------

-- adds notifiers to slot relevant states

function PatternMatrix:__attach_to_song(song)
  TRACE("PatternMatrix:__attach_to_song()")
  
  -- song notifiers

  renoise.song().sequencer.pattern_assignments_observable:add_notifier(
    function()
      TRACE("PatternMatrix: pattern_assignments_observable fired...")
      self.__update_slots_requested = true
    end
  )
  
  song.sequencer.pattern_sequence_observable:add_notifier(
    function(e)
      TRACE("PatternMatrix: pattern_sequence_observable fired...")
      self.__update_slots_requested = true
    end
  )

  song.sequencer.pattern_slot_mutes_observable:add_notifier(
    function()
      TRACE("PatternMatrix:pattern_slot_mutes_observable fired...")
      self.__update_slots_requested = true
    end
  )

  song.tracks_observable:add_notifier(
    function()
      TRACE("PatternMatrix:tracks_observable fired...")
      self.__update_slots_requested = true
    end
  )

  song.patterns_observable:add_notifier(
    function()
      TRACE("PatternMatrix:patterns_observable fired...")
      self.__update_slots_requested = true
    end
  )

  
  -- slot notifiers
  
  local function slot_changed()
    TRACE("PatternMatrix:slot_changed fired...")
    self.__update_slots_requested = true
  end

  local function attach_slot_notifiers()
    local patterns = song.patterns

    for _,pattern in pairs(patterns) do
      local pattern_tracks = pattern.tracks
      
      for _,pattern_track in pairs(pattern_tracks) do
        local observable = pattern_track.is_empty_observable
        
        if (not observable:has_notifier(slot_changed)) then
          observable:add_notifier(slot_changed)
        end
      end
    end
  end

  -- attach to the initial slot set
  attach_slot_notifiers()
  
  -- and to new slots  
  song.tracks_observable:add_notifier(
    function()
      TRACE("PatternMatrix:tracks_changed fired...")
      self.__update_slots_requested = true
      attach_slot_notifiers()
    end
  )

  song.patterns_observable:add_notifier(
    function()
      TRACE("PatternMatrix:patterns_changed fired...")
      self.__update_slots_requested = true
      attach_slot_notifiers()
    end
  )
end

