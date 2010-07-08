--[[----------------------------------------------------------------------------
-- Duplex.MixConsole
----------------------------------------------------------------------------]]--

--[[

  About

  MixConsole is a generic class for controlling the Renoise mixer
  - supported on a wide variety of hardware
  - supports faders, buttons or dials for input

  
  ---------------------------------------------------------

  Control-map assignments 

  "master"  - specify this to control the master track seperately
  "controls" - specify this to control the track offset

  [][][][] []  [][][]     |
  |||||||| []  [][][]     |
  |||||||| []  [][][]   "levels" (optional)
  |||||||| []  [][][]     |
  [][][][] []  [][][]     |
                   
  [][][][] []  [][][]   "mute" (optional)
                   
  [][][][] []  [][][]   "panning" (optional)

  normal  mst   send
  tracks track tracks


  ---------------------------------------------------------
  
  Navigation features

  The mixer will automatically follow the global position
  if the option is enabled. It is displayed like this:

  Four-track mixer, where we select track 2/8:
  The mixer is divided into two "pages"

     Page#1    |    Page#2
  [1][2][3][4] | [5][6][7][8] <-- tracks
      x        |           x  <-- track offset (2/8)

  Eight-track mixer, where we select track 2/8:
  there is enough room for all tracks at once

     Page#1
  [1][2][3][4][5][6][7][8]    <-- tracks
      x                 x     <-- track offset (2/8)



--]]


--==============================================================================

class 'MixConsole' (Application)

function MixConsole:__init(display,mappings,options)
  TRACE("MixConsole:__init",display,mappings,options)

  -- constructor 
  Application.__init(self)

  self.display = display

    -- define the options (with defaults)

  self.ALL_TRACKS = "Include all tracks"
  self.NORMAL = "Normal tracks only"
  self.NORMAL_MASTER = "Normal + master tracks"
  self.MASTER = "Master track only"
  self.MASTER_SEND = "Master + send tracks"
  self.SEND = "Send tracks only"

  self.options = {
    include_tracks = {
      label = "Tracks",
      description = "Select any combination of tracks that you want to include: normal, master and send tracks.",
      items = {
        self.ALL_TRACKS,
        self.NORMAL,
        self.NORMAL_MASTER,
        self.MASTER,
        self.MASTER_SEND,
        self.SEND,
      },
      default = 1,
    },
    track_offset = {
      label = "Offset",
      description = "Change the offset if you want this Mixer to begin with a different track",
      items = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16},
      default = 1,
    },
    sync_position = {
      label = "Sync to global position",
      description = "Set to true if you want the Mixer to align with the selected track in Renoise",
      items = {true,false},
      default = 1,
    },
  }

  -- apply control-maps groups 
  self.mappings = {
    master = {
      group_name = nil,
      description = "Master level - assign to a dial, fader or group of buttons",
      required = false,
      index = nil,
    },
    levels = {
      group_name = nil,
      description = "Track levels - assign to a dial, fader or group of buttons",
      required = false,
      index = nil,
    },
    panning = {
      group_name = nil,
      description = "Panning - assign to a dial, fader or group of buttons",
      required = false,
      index = nil,
    },
    mute = {
      group_name = nil,
      description = "Mute - assign to a dial, fader or button",
      required = false,
      index = nil,
    },
    page = {
      group_name = nil,
      description = "Page navigator - assign to a fader, dial or two buttons",
      required = false,
      index = nil,
    },
  }

  -- default palette: launchpad settings, should degrade nicely...

  self.palette = {
    background = {
      color={0xff,0x00,0xff},
      text="·",
    },
      -- normal tracks are green
    normal_tip = {
      color={0x00,0xff,0x00},
      text="■",
    },
    normal_tip_dimmed = {
      color={0x00,0x40,0x00},
      text="□",
    },
    normal_lane = {
      color={0x00,0x80,0x00},
      text="▪",
    },
    normal_lane_dimmed = {
      color={0x00,0x40,0x00},
      text="▫",
    },
    normal_mute = {
      color={0x00,0xff,0x00},
      text="■",
    },
      -- master track is yellow
    master_tip = {
      color={0xff,0xff,0x00},
      text="■",
    },
    master_lane = {
      color={0x80,0x80,0x00},
      text="▪",
    },
    -- send tracks are red
    send_tip = {
      color={0xff,0x00,0x00},
      text="■",
    },
    send_tip_dimmed = {
      color={0x40,0x00,0x00},
      text="□",
    },
    send_lane = {
      color={0x80,0x00,0x00},
      text="▪",
    },
    send_lane_dimmed = {
      color={0x40,0x00,0x00},
      text="▫",
    },
    send_mute = {
      color={0xff,0x00,0x00},
      text="■",
    },
  }

  -- the various controls
  self.__master = nil
  self.__levels = nil
  self.__mutes = nil
  self.__panning = nil
  self.__track_navigator = nil

  self.__width = 4
  self.__height = 1

  -- todo: extract this from options
  self.__include_normal = true
  self.__include_master = true
  self.__include_send = true

  -- offset of the whole track mapping, controlled by the track navigator
  self.__track_offset = 0
  
  -- apply arguments
  self:__apply_options(options)
  self:__apply_mappings(mappings)

end


--------------------------------------------------------------------------------

-- volume level changed from Renoise

function MixConsole:set_track_volume(control_index, value)
  TRACE("MixConsole:set_track_volume", control_index, value)

  if (self.active) then
    self.__levels[control_index]:set_value(value)
    
    -- update the master as well, if it has its own UI representation
    if (self.__master ~= nil) and 
       (control_index + self.__track_offset == get_master_track_index()) 
    then
      self.__master:set_value(value)
    end
  end
end


--------------------------------------------------------------------------------

-- panning changed from Renoise

function MixConsole:set_track_panning(control_index, value)
  TRACE("MixConsole:set_track_panning", control_index, value)

  if (self.active) then
    self.__panning[control_index]:set_value(value)
  end
end


--------------------------------------------------------------------------------

-- mute state changed from Renoise

function MixConsole:set_track_mute(control_index, state)
  TRACE("MixConsole:set_track_mute", control_index, state)

  if (self.active) then
    -- set mute state to the button
    local active = (state == MUTE_STATE_ACTIVE)
    self.__mutes[control_index]:set(active)

    -- make controls appear dimmed, to show that the track is inactive
    self.__levels[control_index]:set_dimmed(not active)
    self.__panning[control_index]:set_dimmed(not active)
  end
end


--------------------------------------------------------------------------------

-- update: set all controls to current values from renoise

function MixConsole:update()  
  TRACE("MixConsole:update()")

  local master_track_index = get_master_track_index()
  local tracks = renoise.song().tracks

  for control_index=1, self.__width do
    local track_index = self.__track_offset + control_index
    local track = tracks[track_index]
      
    -- set default values
  
    if (track_index <= #tracks) then
      
      -- update component states from the track
      self:set_track_volume(control_index, track.prefx_volume.value)
      self:set_track_panning(control_index, track.prefx_panning.value)
      
      -- show that we can't change the master mute state
      if (track_index == get_master_track_index()) then
        self:set_track_mute(control_index, MUTE_STATE_ACTIVE)
      else
        self:set_track_mute(control_index, track.mute_state)
      end
      
    else
      -- deactivate, reset controls which have no track
      self:set_track_volume(control_index, 0)
      self:set_track_panning(control_index, 0)
      self:set_track_mute(control_index, MUTE_STATE_OFF)
    end

    -- apply palette to controls

    local track_palette = {}
    local mute_palette = {}

    if (track_index < master_track_index) then
      -- normal tracks
      track_palette.tip           = self.palette.normal_tip
      track_palette.tip_dimmed    = self.palette.normal_tip_dimmed
      track_palette.track         = self.palette.normal_lane
      track_palette.track_dimmed  = self.palette.normal_lane_dimmed
      mute_palette.foreground     = self.palette.normal_mute
    elseif (track_index == master_track_index) then
      -- master track
      track_palette.tip           = self.palette.master_tip
      track_palette.track         = self.palette.master_lane
      mute_palette.foreground     = self.palette.background
    elseif (track_index <= #tracks) then
      -- send tracks
      track_palette.tip           = self.palette.send_tip
      track_palette.tip_dimmed    = self.palette.send_tip_dimmed
      track_palette.track         = self.palette.send_lane
      track_palette.track_dimmed  = self.palette.send_lane_dimmed
      mute_palette.foreground     = self.palette.send_mute

    else 
      -- unmapped tracks are black
      --[[
      track_palette.tip = table.rcopy(self.palette.background)
      track_palette.tip_dimmed = table.rcopy(self.palette.background)
      track_palette.track = table.rcopy(self.palette.background)
      track_palette.track_dimmed = table.rcopy(self.palette.background)
      --mute_palette.foreground_dec = table.rcopy(self.palette.background)
      mute_palette.foreground_dec = table.rcopy(self.palette.background)
      ]]
    end

    self.__levels[control_index]:set_palette(track_palette)
    self.__panning[control_index]:set_palette(track_palette)
    self.__mutes[control_index]:set_palette(mute_palette)

  end
  -- update the master as well, if it has its own UI representation
  if (self.__master ~= nil) then
     self.__master:set_value(get_master_track().prefx_volume.value)
  end
end


--------------------------------------------------------------------------------

-- build_app: create a grid or fader/encoder layout

function MixConsole:build_app()
  TRACE("MixConsole:build_app(")

  Application.build_app(self)

  -- check if the control-map describes a grid controller
  -- (slider is composed from individual buttons in grid mode)
  
  local slider_grid_mode = false
  
  local control_map_groups = self.display.device.control_map.groups 
  local levels_group = control_map_groups[self.mappings.levels.group_name]

  if (levels_group) then
    for attr, param in pairs(levels_group) do
      if (attr == "xarg" and param["columns"]) then
        slider_grid_mode = true
        self.__width = tonumber(param["columns"])
        self.__height = math.ceil(#levels_group / self.__width)
        break
      end
    end
  end
  
  local embed_mutes = (self.mappings.mute.group_name == 
    self.mappings.levels.group_name)
  
  local embed_master = (self.mappings.master.group_name == 
    self.mappings.levels.group_name)

  if (slider_grid_mode) then
    if (embed_master) then
      self.__width = self.__width-1
    end

  else
    -- extend width to the number of parameters in the levels group
    if (levels_group) then
      self.__width = #levels_group
    end
  end

  
  -- construct the display
  
  self.__levels = {}
  self.__panning = {}
  self.__mutes = {}
  self.__master = nil

  for control_index = 1,self.__width do

    -- sliders --------------------------------------------

    local y_pos = (embed_mutes) and 2 or 1
    local c = UISlider(self.display)
    c.group_name = self.mappings.levels.group_name
    c.x_pos = control_index
    c.y_pos = y_pos
    c.toggleable = true
    c.flipped = false
    c.ceiling = RENOISE_DECIBEL
    c.orientation = VERTICAL
    c:set_size(self.__height-(y_pos-1))

    -- slider changed from controller
    c.on_change = function(obj) 
      local track_index = self.__track_offset + control_index

      if (not self.active) then
        return false
      elseif (track_index == get_master_track_index()) then
        if (self.__master) then
          -- this will cause another event...
          self.__master:set_value(obj.value)
        else
          local track = renoise.song().tracks[track_index]
          track.prefx_volume.value = obj.value
        end
        return true
      elseif (track_index > #renoise.song().tracks) then
        -- track is outside bounds
        return false
      else
        local track = renoise.song().tracks[track_index]
        track.prefx_volume.value = obj.value
        return true
      end
    end
    
    self.display:add(c)
    self.__levels[control_index] = c


    -- encoders -------------------------------------------

    local c = UISlider(self.display)
    c.group_name = self.mappings.panning.group_name
    c.x_pos = control_index
    c.y_pos = 1
    c.toggleable = true
    c.flipped = false
    c.ceiling = 1.0
    c.orientation = VERTICAL
    c:set_size(1)
    
    -- slider changed from controller
    c.on_change = function(obj) 
      local track_index = self.__track_offset + control_index

      if (not self.active) then
        return false

      elseif (track_index > #renoise.song().tracks) then
        -- track is outside bounds
        return false

      else
        local track = renoise.song().tracks[track_index]
        track.prefx_panning.value = obj.value
        return true
      end
    end
    
    self.display:add(c)
    self.__panning[control_index] = c
    
    
    -- buttons --------------------------------------------

    local c = UIToggleButton(self.display)
    c.group_name = self.mappings.mute.group_name
    c.x_pos = control_index
    c.y_pos = 1
    c.inverted = true
    c.active = false

    -- mute state changed from controller
    -- (update the slider.dimmed property)
    c.on_change = function(obj) 
      local track_index = self.__track_offset + control_index
      
      if (not self.active) then
        return false
      
      elseif (track_index == get_master_track_index()) then
        -- can't mute the master track
        return false
      
      elseif (track_index > #renoise.song().tracks) then
        -- track is outside bound
        return false
      end
      
      local track = renoise.song().tracks[track_index]
      
      local mute_state = obj.active and 
        MUTE_STATE_ACTIVE or MUTE_STATE_OFF
      
      local dimmed = not obj.active
      
      track.mute_state = mute_state
      
      self.__levels[control_index]:set_dimmed(dimmed)
      self.__panning[control_index]:set_dimmed(dimmed)
      
      return true
    end
    
    self.display:add(c)
    self.__mutes[control_index] = c    
  end


  -- master fader (optional) ------------------------------

  if (self.mappings.master.group_name) then
    
    local x_pos = (embed_master) and (self.__width+1) or 1
    local c = UISlider(self.display)
    c.group_name = self.mappings.master.group_name
    c.x_pos = x_pos
    c.y_pos = 1
    c.toggleable = true
    c.ceiling = RENOISE_DECIBEL
    c:set_size(self.__height)
    
    c.on_change = function(obj) 
      if (not self.active) then
        return false
      else
        local master_control_index = 
          get_master_track_index() - self.__track_offset
        
        if (self.__levels and 
            master_control_index > 0 and 
            master_control_index <= self.__width) 
        then
          -- this will cause another event...
          self.__levels[master_control_index]:set_value(obj.value)
        else
          get_master_track().prefx_volume.value = obj.value
        end
        
        return true
      end
    end 
     
    self.display:add(c)
    self.__master = c
  end
  
  
  -- track scrolling (optional) ---------------------------

  if (self.mappings.page.group_name) then
    self.__track_navigator = UISpinner(self.display)
    self.__track_navigator.group_name = self.mappings.page.group_name
    self.__track_navigator.index = 0
    self.__track_navigator.step_size = self.__width
    self.__track_navigator.minimum = 0
    self.__track_navigator.maximum = math.max(0, 
      #renoise.song().tracks - self.__width)
    self.__track_navigator.x_pos = 1
    self.__track_navigator.palette.foreground_dec.text = "◄"
    self.__track_navigator.palette.foreground_inc.text = "►"
    self.__track_navigator.on_change = function(obj) 

      if (not self.active) then
        return false
      end

      self.__track_offset = obj.index
      self:__attach_to_tracks()
      self:update()
      return true

    end
    
    self.display:add(self.__track_navigator)
  end

  -- the finishing touch
  self:__attach_to_song(renoise.song())
end


--------------------------------------------------------------------------------

-- start/resume application

function MixConsole:start_app()
  TRACE("MixConsole.start_app()")

  if not (self.created) then 
    self:build_app()
  end

  Application.start_app(self)
  self:update()
end


--------------------------------------------------------------------------------

function MixConsole:destroy_app()
  TRACE("MixConsole:destroy_app")

  if (self.__levels) then
    for _,obj in ipairs(self.__levels) do
      obj.remove_listeners(obj)
    end
  end
  if (self.__panning) then  
    for _,obj in ipairs(self.__panning) do
      obj.remove_listeners(obj)
    end
  end
  if (self.__mutes) then
    for _,obj in ipairs(self.__mutes) do
      obj.remove_listeners(obj)
    end
  end
  if (self.__master) then
    self.__master:remove_listeners()
  end
  
  Application.destroy_app(self)
end


--------------------------------------------------------------------------------

function MixConsole:on_new_document()
  TRACE("MixConsole:on_new_document")
  
  self:__attach_to_song(renoise.song())
  
  if (self.active) then
    self:update()
  end
end


--------------------------------------------------------------------------------

-- adds notifiers to song
-- invoked when a new document becomes available

function MixConsole:__attach_to_song(song)
  TRACE("MixConsole:__attach_to_song()")
  
  -- update on track changes in the song
  song.tracks_observable:add_notifier(
    function()
      TRACE("MixConsole:tracks_changed fired...")
      self:__attach_to_tracks()
      
      if (self.active) then
        self:update()
      end
    end
  )

  -- and immediately attach to the current track set
  self:__attach_to_tracks()
end


--------------------------------------------------------------------------------

-- add notifiers to parameters
-- invoked when tracks are added/removed/swapped

function MixConsole:__attach_to_tracks()
  TRACE("MixConsole:__attach_to_tracks()")

  local tracks = renoise.song().tracks

  -- validate and update the sequence/track offset
  if (self.__track_navigator) then
    self.__track_navigator:set_range(nil,math.max(0, 
      #renoise.song().tracks - self.__width))
  end
    
  -- detach all previously added notifiers first
  for _,track in pairs(tracks) do
    track.prefx_volume.value_observable:remove_notifier(self)
    track.prefx_panning.value_observable:remove_notifier(self)
    track.mute_state_observable:remove_notifier(self) 
  end 
  
  -- attach to the new ones in the order we want them
  local master_done = false
  local master_idx = get_master_track_index()
  for control_index=1,math.min(#tracks, self.__width) do
    local track_index = self.__track_offset + control_index
    local track = tracks[track_index]

    if(track_index == master_idx)then
      master_done = true
    end
    
    -- track volume level 
    track.prefx_volume.value_observable:add_notifier(
      self, 
      function()
        if (self.active) then
          local value = track.prefx_volume.value
          -- compensate for potential loss of precision 
          if not compare(self.__levels[control_index].value, value, 1000) then
            self:set_track_volume(control_index, value)
          end
        end
      end 
    )

    -- track panning level 
    track.prefx_panning.value_observable:add_notifier(
      self, 
      function()
        if (self.active) then
          local value = track.prefx_panning.value
          -- compensate for potential loss of precision 
          if not compare(self.__panning[control_index].value, value, 1000) then
            self:set_track_panning(control_index, value)
          end
        end
      end 
    )
    
    -- track mute-state 
    track.mute_state_observable:add_notifier(
      self, 
      function()
        if (self.active) then
          self:set_track_mute(control_index, track.mute_state)
        end
      end 
    )
  end

  -- if master wasn't already mapped just before
  if (not master_done) and 
    (self.mappings.master.group_name) and 
    (self.__include_master) then
    local track = renoise.song().tracks[master_idx]
    track.prefx_volume.value_observable:add_notifier(
      self, 
      function()
        if (self.active) then
          local value = track.prefx_volume.value
          -- compensate for potential loss of precision 
          if not compare(self.__master.value, value, 1000) then
            self.__master:set_value(value)
          end
        end
      end 
    )
  end

end

