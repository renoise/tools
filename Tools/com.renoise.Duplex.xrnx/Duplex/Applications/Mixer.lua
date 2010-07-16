--[[----------------------------------------------------------------------------
-- Duplex.Mixer
----------------------------------------------------------------------------]]--

--[[

  About

  Mixer is a generic class for controlling the Renoise mixer
  - supported on a wide variety of hardware
  - supports faders, buttons or dials for input

  
  ---------------------------------------------------------

  Control-map assignments 

  "master"  - specify this to control the master track seperately
  "page" - specify this to control the track offset
  "mode" - specify this to control if pre of post fx values are mapped

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


  ---------------------------------------------------------
  
  Pre/Post FX Volume/Pan
  
  The mixer allows controlling both, pre and post FX values. 
  By default its configured to use post FX values. 
  
  You can either change the default via the controller options,
  or by mapping something to the "mode" group, in order to 
  change the mode dynamically from the controller
  
--]]


--==============================================================================

class 'Mixer' (Application)

function Mixer:__init(display,mappings,options)
  TRACE("Mixer:__init",display,mappings,options)

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

  self.MODE_PREFX = "Pre FX volume and panning"
  self.MODE_POSTFX = "Post FX volume and panning"

  self.options = {
    include_tracks = {
      label = "Tracks",
      description = "Select any combination of tracks that you want to " ..
        "include: normal, master and send tracks.",
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
      description = "Change the offset if you want this Mixer to begin " .. 
        "with a different track",
      items = {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16},
      default = 1,
    },
    mode = {
      label = "Mode",
      description = "Change if either Pre or Post FX volume/pan is controlled",
      items = {
        self.MODE_PREFX,
        self.MODE_POSTFX,
      },
      default = self.MODE_POSTFX
    },
    sync_position = {
      label = "Sync to global position",
      description = "Set to true if you want the Mixer to align with the " ..
        "selected track in Renoise",
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
    solo = {
      group_name = nil,
      description = "Solo - assign to a dial, fader or button",
      required = false,
      index = nil,
    },
    page = {
      group_name = nil,
      description = "Page navigator - assign to a fader, dial or two buttons",
      required = false,
      index = nil,
    },
    mode = {
      group_name = nil,
      description = "Pre/Post FX mode control - assign to a fader, dial or button",
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
  self.__panning = nil
  self.__mutes = nil
  self.__solos = nil
  self.__track_navigator = nil
  self.__mode_control = nil

  self.__width = 4
  self.__height = 1

  -- todo: extract this from options
  self.__include_normal = true
  self.__include_master = true
  self.__include_send = true

  -- offset of the whole track mapping, controlled by the track navigator
  self.__track_offset = 0
  
  -- toggle, which defines if we're controlling the pre or post fx vol/pans
  self.__postfx_mode = true
   
  -- current track properties we are listening to
  self.__attached_track_observables = table.create()

  -- apply arguments
  self:__apply_options(options)
  self:__apply_mappings(mappings)
end


--------------------------------------------------------------------------------

-- volume level changed from Renoise

function Mixer:set_track_volume(control_index, value)
  TRACE("Mixer:set_track_volume", control_index, value)

  if (self.active) then
    if (self.__levels ~= nil) then
      self.__levels[control_index]:set_value(value)
      
      -- update the master as well, if it has its own UI representation
      if (self.__master ~= nil) and 
         (control_index + self.__track_offset == get_master_track_index()) 
      then
        self.__master:set_value(value)
      end
    end
  end
end


--------------------------------------------------------------------------------

-- panning changed from Renoise

function Mixer:set_track_panning(control_index, value)
  TRACE("Mixer:set_track_panning", control_index, value)

  if (self.active and self.__panning ~= nil) then
    self.__panning[control_index]:set_value(value)
  end
end


--------------------------------------------------------------------------------

-- mute state changed from Renoise

function Mixer:set_track_mute(control_index, state)
  TRACE("Mixer:set_track_mute", control_index, state)

  if (self.active and self.__mutes ~= nil) then
    -- set mute state to the button
    local active = (state == MUTE_STATE_ACTIVE)
    self.__mutes[control_index]:set(active)

    -- make controls appear dimmed, to show that the track is inactive
    if (self.__levels) then
      self.__levels[control_index]:set_dimmed(not active)
    end
    
    if (self.__panning) then
      self.__panning[control_index]:set_dimmed(not active)
    end
  end
end


--------------------------------------------------------------------------------

-- solo state changed from Renoise

function Mixer:set_track_solo(control_index, state)
  TRACE("Mixer:set_track_solo", control_index, state)

  if (self.active and self.__solos ~= nil) then
    -- set mute state to the button
    self.__solos[control_index]:set(state)
  end
end


--------------------------------------------------------------------------------

-- update: set all controls to current values from renoise

function Mixer:update()  
  TRACE("Mixer:update()")

  local master_track_index = get_master_track_index()
  local tracks = renoise.song().tracks

  -- track volume/panning/mute and solo
  
  for control_index = 1,self.__width do
  
    local track_index = self.__track_offset + control_index
    local track = tracks[track_index]
      
    -- set default values
    if (track_index <= #tracks) then
      
      -- update component states from the track
      if (self.__postfx_mode) then
        self:set_track_volume(control_index, track.postfx_volume.value)
        self:set_track_panning(control_index, track.postfx_panning.value)
      else
        self:set_track_volume(control_index, track.prefx_volume.value)
        self:set_track_panning(control_index, track.prefx_panning.value)
      end
      
      -- show that we can't change the master mute state
      if (track_index == master_track_index) then
        self:set_track_mute(control_index, MUTE_STATE_ACTIVE)
      else
        self:set_track_mute(control_index, track.mute_state)
      end
      
       self:set_track_solo(control_index, track.solo_state)
    else
      -- deactivate, reset controls which have no track
      self:set_track_volume(control_index, 0)
      self:set_track_panning(control_index, 0)
      self:set_track_mute(control_index, MUTE_STATE_OFF)
      self:set_track_solo(control_index, false)
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

    if (self.__levels) then
      self.__levels[control_index]:set_palette(track_palette)
    end
    
    if (self.__panning) then
      self.__panning[control_index]:set_palette(track_palette)
    end

    if (self.__mutes) then
      self.__mutes[control_index]:set_palette(mute_palette)
    end

    if (self.__solos) then
      self.__solos[control_index]:set_palette(mute_palette)
    end
  end
  
  
  -- master volume
  
  if (self.__master ~= nil) then
     if (self.__postfx_mode) then
       self.__master:set_value(get_master_track().postfx_volume.value)
     else
       self.__master:set_value(get_master_track().prefx_volume.value)
     end
  end
  
  
  -- page controls

  if (self.__track_navigator) then
    self.__track_navigator.index = self.__track_offset
  end


  -- mode controls

  if (self.__mode_control) then
    self.__mode_control.active = self.__postfx_mode
  end

end


--------------------------------------------------------------------------------

-- start/resume application

function Mixer:start_app()
  TRACE("Mixer.start_app()")

  if not (self.__created) then 
    self:__build_app()
  end

  Application.start_app(self)
  self:update()
end


--------------------------------------------------------------------------------

function Mixer:destroy_app()
  TRACE("Mixer:destroy_app")

  if (self.__levels) then
    for _,obj in pairs(self.__levels) do
      obj.remove_listeners(obj)
    end
  end
  if (self.__panning) then  
    for _,obj in pairs(self.__panning) do
      obj.remove_listeners(obj)
    end
  end
  if (self.__mutes) then
    for _,obj in pairs(self.__mutes) do
      obj.remove_listeners(obj)
    end
  end
  if (self.__solos) then
    for _,obj in pairs(self.__solos) do
      obj.remove_listeners(obj)
    end
  end
  if (self.__master) then
    self.__master:remove_listeners()
  end
  
  Application.destroy_app(self)
end


--------------------------------------------------------------------------------

function Mixer:on_new_document()
  TRACE("Mixer:on_new_document")
  
  self:__attach_to_song()
  
  if (self.active) then
    self:update()
  end
end


--------------------------------------------------------------------------------

-- build_app: create a grid or fader/encoder layout

function Mixer:__build_app()
  TRACE("Mixer:__build_app(")

  Application.__build_app(self)

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
  
  self.__levels = (self.mappings.levels.group_name) and {} or nil
  self.__panning = (self.mappings.panning.group_name) and {} or nil
  self.__mutes = (self.mappings.mute.group_name) and {} or nil
  self.__solos = (self.mappings.solo.group_name) and {} or nil
  
  self.__master = nil
  self.__track_navigator = nil
  self.__mode_control = nil
  
  for control_index = 1,self.__width do

    -- sliders --------------------------------------------

    if (self.mappings.levels.group_name) then

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
            
            local volume = (self.__postfx_mode) and 
              track.postfx_volume or track.prefx_volume
        
            volume.value = obj.value
          end
          return true
        
        elseif (track_index > #renoise.song().tracks) then
          -- track is outside bounds
          return false

        else
          local track = renoise.song().tracks[track_index]
          
          local volume = (self.__postfx_mode) and 
            track.postfx_volume or track.prefx_volume
        
          volume.value = obj.value
        end
      end
      
      self.display:add(c)
      self.__levels[control_index] = c
    end
    

    -- encoders -------------------------------------------

    if (self.mappings.panning.group_name) then
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
          
          local panning = (self.__postfx_mode) and 
            track.postfx_panning or track.prefx_panning
        
          panning.value = obj.value
          
          return true
        end
      end
      
      self.display:add(c)
      self.__panning[control_index] = c
    end
        
     
    -- mute buttons -----------------------------------
    
    if (self.mappings.mute.group_name) then
      local c = UIToggleButton(self.display)
      c.group_name = self.mappings.mute.group_name
      c.x_pos = control_index
      c.y_pos = 1
      c.inverted = false
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

        if (obj.active) then
          track:unmute()
        else 
          track:mute()
        end

        if (self.__levels) then
          self.__levels[control_index]:set_dimmed(not obj.active)
        end
        
        if (self.__panning) then
          self.__panning[control_index]:set_dimmed(not obj.active)
        end
        
        return true
      end
      
      self.display:add(c)
      self.__mutes[control_index] = c    
    end
    

    -- solo buttons -----------------------------------

    if (self.mappings.solo.group_name) then
      local c = UIToggleButton(self.display)
      c.group_name = self.mappings.solo.group_name
      c.x_pos = control_index
      c.y_pos = 1
      c.inverted = false
      c.active = false
  
      -- mute state changed from controller
      -- (update the slider.dimmed property)
      c.on_change = function(obj) 
        local track_index = self.__track_offset + control_index
        
        if (not self.active) then
          return false
        
        elseif (track_index > #renoise.song().tracks) then
          -- track is outside bound
          return false
        end
        
        local track = renoise.song().tracks[track_index]
        track.solo_state = obj.active
  
        return true
      end
      
      self.display:add(c)
      self.__solos[control_index] = c    
    end
  end
  

  -- master fader ------------------------------

  if (self.mappings.master.group_name) then
    
    local c = UISlider(self.display)
    c.group_name = self.mappings.master.group_name
    c.x_pos = (embed_master) and (self.__width + 1) or 1
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
          local volume = (self.__postfx_mode) and 
            get_master_track().postfx_volume or 
            get_master_track().prefx_volume
        
          volume.value = obj.value
        end
        
        return true
      end
    end 
     
    self.display:add(c)
    self.__master = c
  end
  
  
  -- track scrolling ---------------------------

  if (self.mappings.page.group_name) then
  
    self.__track_navigator = UISpinner(self.display)
    self.__track_navigator.group_name = self.mappings.page.group_name
    self.__track_navigator.index = 0
    self.__track_navigator.step_size = self.__width
    self.__track_navigator.minimum = 0
    self.__track_navigator.maximum = math.max(0, 
      #renoise.song().tracks - self.__width)
    self.__track_navigator.x_pos = 1 + (self.mappings.page.index or 0)
    self.__track_navigator.text_orientation = HORIZONTAL

    self.__track_navigator.on_change = function(obj) 
      if (not self.active) then
        return false
      end

      self.__track_offset = obj.index
      
      local new_song = false
      self:__attach_to_tracks(new_song)
      
      self:update()

      return true
    end
    
    self.display:add(self.__track_navigator)
  end


  -- Pre/Post FX mode ---------------------------

  if (self.mappings.mode.group_name) then
    self.__mode_control = UIToggleButton(self.display)
    self.__mode_control.group_name = self.mappings.mode.group_name
    self.__mode_control.x_pos = 1 + (self.mappings.mode.index or 0)
    self.__mode_control.y_pos = 1
    self.__mode_control.inverted = false
    self.__mode_control.active = false

    -- mode state changed from controller
    self.__mode_control.on_change = function(obj) 
      if (not self.active) then
        return false
      end
      
      if (self.__postfx_mode ~= obj.active) then
        self.__postfx_mode = obj.active
        
        local new_song = false
        self:__attach_to_tracks(new_song)
        
        self:update()
      end

      return true
    end
    
    self.display:add(self.__mode_control)
  end
    
  -- the finishing touch
  self:__attach_to_song()
end


--------------------------------------------------------------------------------

-- adds notifiers to song
-- invoked when a new document becomes available

function Mixer:__attach_to_song()
  TRACE("Mixer:__attach_to_song")
  
  -- update on track changes in the song
  renoise.song().tracks_observable:add_notifier(
    function()
      TRACE("Mixer:tracks_changed fired...")
      
      local new_song = false
      self:__attach_to_tracks(new_song)
      
      if (self.active) then
        self:update()
      end
    end
  )

  -- and immediately attach to the current track set
  local new_song = true
  self:__attach_to_tracks(new_song)
end


--------------------------------------------------------------------------------

-- add notifiers to parameters
-- invoked when tracks are added/removed/swapped

function Mixer:__attach_to_tracks(new_song)
  TRACE("Mixer:__attach_to_tracks", new_song)

  local tracks = renoise.song().tracks

  -- validate and update the sequence/track offset
  if (self.__track_navigator) then
    self.__track_navigator:set_range(nil,math.max(0, 
      #renoise.song().tracks - self.__width))
  end
    
  -- detach all previously added notifiers first
  -- but don't even try to detach when a new song arrived. old observables
  -- will no longer be alive then...
  if (not new_song) then
    for _,observable in pairs(self.__attached_track_observables) do
      observable:remove_notifier(self)
    end
  end
  
  self.__attached_track_observables:clear()
  
  
  -- attach to the new ones in the order we want them
  local master_done = false
  local master_idx = get_master_track_index()
  
  for control_index = 1,math.min(#tracks, self.__width) do
    local track_index = self.__track_offset + control_index
    local track = tracks[track_index]

    if (track_index == master_idx) then
      master_done = true
    end
    
    -- track volume level 
    if (self.__levels) then
      local volume = (self.__postfx_mode) and 
        track.postfx_volume or track.prefx_volume
      
      self.__attached_track_observables:insert(
        volume.value_observable)
      
      volume.value_observable:add_notifier(
        self, 
        function()
          if (self.active) then
            local value = volume.value
            -- compensate for potential loss of precision 
            if not compare(self.__levels[control_index].value, value, 1000) then
              self:set_track_volume(control_index, value)
            end
          end
        end 
      )
    end
    
    -- track panning level 
    if (self.__panning) then
      local panning = (self.__postfx_mode) and 
         track.postfx_panning or track.prefx_panning
      
      self.__attached_track_observables:insert(
        panning.value_observable)

      panning.value_observable:add_notifier(
        self, 
        function()
          if (self.active) then
            local value = panning.value
            -- compensate for potential loss of precision 
            if not compare(self.__panning[control_index].value, value, 1000) then
              self:set_track_panning(control_index, value)
            end
          end
        end 
      )
    end
    
    -- track mute-state 
    if (self.__mutes) then
      self.__attached_track_observables:insert(track.mute_state_observable)

      track.mute_state_observable:add_notifier(
        self, 
        function()
          if (self.active) then
            self:set_track_mute(control_index, track.mute_state)
          end
        end 
      )
    end
    
    -- track solo-state 
    if (self.__solos) then
      self.__attached_track_observables:insert(track.solo_state_observable)

      track.solo_state_observable:add_notifier(
        self, 
        function()
          if (self.active) then
            self:set_track_solo(control_index, track.solo_state)
          end
        end 
      )
    end
  end

  -- if master wasn't already mapped just before
  if (not master_done and self.__master) and 
    (self.__include_master) then
    local track = renoise.song().tracks[master_idx]
    
    local volume = (self.__postfx_mode) and 
      track.postfx_volume or track.prefx_volume

    self.__attached_track_observables:insert(
      volume.value_observable)
  
    volume.value_observable:add_notifier(
      self, 
      function()
        if (self.active) then
          local value = volume.value
          -- compensate for potential loss of precision 
          if not compare(self.__master.value, value, 1000) then
            self.__master:set_value(value)
          end
        end
      end 
    )
  end

end

