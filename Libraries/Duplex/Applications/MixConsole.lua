--[[----------------------------------------------------------------------------
-- Duplex.MixConsole
----------------------------------------------------------------------------]]--

--[[

  About

  MixConsole is a generic class for controlling the Renoise mixer
  - supported on a wide variety of hardware
  - supports faders, buttons or dials for input

  Btw: the applicetion uses colorize() to change the default colors

  
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

  Options

  -- include the following track types:

  - "include_normal_tracks"
  - "include_send_tracks"
  - "include_master_tracks"



--]]


--==============================================================================

class 'MixConsole' (Application)

function MixConsole:__init(display,mappings,options)
  TRACE("MixConsole:__init",display,mappings,options)

  -- constructor 
  Application.__init(self)

  self.display = display

  self.master = nil
  self.sliders = nil
  self.buttons = nil
  self.encoders = nil
  self.page_controls = nil

    -- define the options (with defaults)

  self.INCLUDE_TRACKS = "Include these tracks"
  self.IGNORE_TRACKS = "Ignore these tracks"
  self.INCLUDE_TRACK = "Include this track"
  self.IGNORE_TRACK = "Ignore this track"

  self.options = {
    include_normal = {
      label = "Normal tracks",
      items = {self.INCLUDE_TRACKS,self.IGNORE_TRACKS},
      default = 1,
    },
    include_send = {
      label = "Send tracks",
      items = {self.INCLUDE_TRACKS,self.IGNORE_TRACKS},
      default = 1,
    },
    include_master = {
      label = "Master track",
      items = {self.INCLUDE_TRACK,self.IGNORE_TRACK},
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
      description = "Page selector - assign to a fader, dial or two buttons",
      required = false,
      index = nil,
    },
  }
--[[
  self.master_group_name = options.master_group_name
  self.levels_group_name = options.levels_group_name
  self.mute_group_name = options.mute_group_name
  self.panning_group_name = options.panning_group_name
  self.page_controls_group_name = options.page_controls_group_name
]]

  -- the default number of tracks to display
  self.width = 4

  -- the number of units spanned vertically
  -- (more than one, if grid controller)
  self.height = 1

  -- offset of the whole track mapping, controlled by the scroller
  self.__track_offset = 0
  
  -- apply arguments

  self:apply_options(options)
  self:apply_mappings(mappings)

  -- final steps
  --self:build_app()
end


--------------------------------------------------------------------------------

-- volume level changed from Renoise

function MixConsole:set_track_volume(control_index, value)
  TRACE("MixConsole:set_track_volume", control_index, value)

  if (self.active) then
    self.sliders[control_index]:set_value(value)
    
    -- update the master as well, if it has its own UI representation
    if (self.master ~= nil) and 
       (control_index + self.__track_offset == get_master_track_index()) 
    then
      self.master:set_value(value)
    end
  end
end


--------------------------------------------------------------------------------

-- panning changed from Renoise

function MixConsole:set_track_panning(control_index, value)
  TRACE("MixConsole:set_track_panning", control_index, value)

  if (self.active) then
    self.encoders[control_index]:set_value(value)
  end
end


--------------------------------------------------------------------------------

-- mute state changed from Renoise

function MixConsole:set_track_mute(control_index, state)
  TRACE("MixConsole:set_track_mute", control_index, state)

  if (self.active) then
    -- set mute state to the button
    local active = (state == MUTE_STATE_ACTIVE)
    self.buttons[control_index]:set(active)

    -- deactivate sliders and encoders to show that the track is inactive
    self.sliders[control_index]:set_dimmed(not active)
    self.encoders[control_index]:set_dimmed(not active)
  end
end


--------------------------------------------------------------------------------

-- update: set all controls to current values from renoise

function MixConsole:update()  
  
  local master_track_index = get_master_track_index()
  local tracks = renoise.song().tracks

  for control_index=1, self.width do
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

    -- colorize: optimize this ...
    
    if (track_index < master_track_index) then
      -- normal tracks are green
      self.sliders[control_index]:colorize({0x00,0xff,0x00})
      self.encoders[control_index]:colorize({0x00,0xff,0x00})
      self.buttons[control_index]:colorize({0x00,0xff,0x00})

    elseif (track_index == master_track_index) then
      -- master track is yellow
      self.sliders[control_index]:colorize({0xff,0xff,0x00})
      self.encoders[control_index]:colorize({0xff,0xff,0x00})
      self.buttons[control_index]:colorize({0xff,0xff,0x00})      

    elseif (track_index <= #tracks) then
      -- send tracks are red
      self.sliders[control_index]:colorize({0xff,0x00,0x00})
      self.encoders[control_index]:colorize({0xff,0x00,0x00})
      self.buttons[control_index]:colorize({0xff,0x00,0x00})

    else 
      -- unmapped tracks are black
      self.sliders[control_index]:colorize({0x00,0x00,0x00})
      self.encoders[control_index]:colorize({0x00,0x00,0x00})
      self.buttons[control_index]:colorize({0x00,0x00,0x00}) 
    end
  end
  
  -- update the master as well, if it has its own UI representation
  if (self.master ~= nil) then
     self.master:set_value(get_master_track().prefx_volume.value)
  end
end


--------------------------------------------------------------------------------

-- build_app: create a grid or fader/encoder layout

function MixConsole:build_app()
  TRACE("MixConsole:build_app(")

  Application.build_app(self)

  self.sliders = {}
  self.encoders = {}
  self.buttons = {}
  self.master = nil

  -- check if the control-map describes a grid controller
  -- (slider is composed from individual buttons in grid mode)
  local grid_mode = false
  local control_map_groups = self.display.device.control_map.groups
  for group_name, group in pairs(control_map_groups) do
    for attr, param in pairs(group) do
      if (attr == "xarg" and param["columns"]) then
        grid_mode = true
        self.width = tonumber(param["columns"])
        self.height = math.ceil(#group/self.width)
      end
      if grid_mode then break end
    end
    if grid_mode then break end
  end

  local slider_offset = 0
  if grid_mode then
    -- if certain group names are left out, place them the main grid 
    if (not self.mappings.mute.group_name) then
      -- place mute buttons in the topmost row
      self.mappings.mute.group_name = self.mappings.levels.group_name
      slider_offset = slider_offset+1
    end
    -- todo: place master volume on the rightmost side
  else
    -- extend width to the number of parameters in the levels group
    local grp = control_map_groups[self.mappings.levels.group_name]
    if grp then
      self.width = #grp
    end
  end

  for control_index=1, self.width do

    -- sliders --------------------------------------------

    local slider = UISlider(self.display)
    slider.group_name = self.mappings.levels.group_name
    slider.x_pos = control_index
    slider.y_pos = 1+slider_offset
    slider.toggleable = true
    slider.flipped = false
    slider.ceiling = RENOISE_DECIBEL
    slider.orientation = VERTICAL
    slider:set_size(self.height-slider_offset)

    -- slider changed from controller
    slider.on_change = function(obj) 
      local track_index = self.__track_offset + control_index

      if (not self.active) then
        return false
      elseif (track_index == get_master_track_index()) then
        if (self.master) then
          -- this will cause another event...
          self.master:set_value(obj.value)
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
    
    self.display:add(slider)
    self.sliders[control_index] = slider


    -- encoders -------------------------------------------

    local encoder = UISlider(self.display)
    encoder.group_name = self.mappings.panning.group_name
    encoder.x_pos = control_index
    encoder.y_pos = 1
    encoder.toggleable = true
    encoder.flipped = false
    encoder.ceiling = 1.0
    encoder.orientation = VERTICAL
    encoder:set_size(1)
    
    -- slider changed from controller
    encoder.on_change = function(obj) 
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
    
    self.display:add(encoder)
    self.encoders[control_index] = encoder
    
    
    -- buttons --------------------------------------------

    local button = UIToggleButton(self.display)
    button.group_name = self.mappings.mute.group_name
    button.x_pos = control_index
    button.y_pos = 1
    button.inverted = true
    button.active = false

    -- mute state changed from controller
    -- (update the slider.dimmed property)
    button.on_change = function(obj) 
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
      
      self.sliders[control_index]:set_dimmed(dimmed)
      self.encoders[control_index]:set_dimmed(dimmed)
      
      return true
    end
    
    self.display:add(button)
    self.buttons[control_index] = button    
  end


  -- master fader (optional) ------------------------------

  if (self.mappings.master.group_name) then
    local slider = UISlider(self.display)
    slider.group_name = self.mappings.master.group_name
    slider.x_pos = 1
    slider.y_pos = 1
    slider.toggleable = true
    slider.ceiling = RENOISE_DECIBEL
    slider:set_size(self.height)
    
    slider.on_change = function(obj) 
      if (not self.active) then
        return false
      else
        local master_control_index = 
          get_master_track_index() - self.__track_offset
        
        if (self.sliders and 
            master_control_index > 0 and 
            master_control_index <= self.width) 
        then
          -- this will cause another event...
          self.sliders[master_control_index]:set_value(obj.value)
        else
          get_master_track().prefx_volume.value = obj.value
        end
        
        return true
      end
    end 
     
    self.display:add(slider)
    self.master = slider
  end
  
  
  -- track scrolling (optional) ---------------------------

  if (self.mappings.page.group_name) then
    self.page_controls = UISpinner(self.display)
    self.page_controls.group_name = self.mappings.page.group_name
    self.page_controls.index = 0
    self.page_controls.step_size = self.width
    self.page_controls.minimum = 0
    self.page_controls.maximum = math.max(0, 
      #renoise.song().tracks - self.width)
    self.page_controls.x_pos = 1
    self.page_controls.palette.foreground_dec.text = "◄"
    self.page_controls.palette.foreground_inc.text = "►"
    self.page_controls.on_press = function(obj) 

      if (not self.active) then
        return false
      end

      self.__track_offset = obj.index
      self:__attach_to_tracks()
      self:update()
      return true

    end
    
    self.display:add(self.page_controls)
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

  if (self.sliders) then
    for _,obj in ipairs(self.sliders) do
      obj.remove_listeners(obj)
    end
  end
  if (self.encoders) then  
    for _,obj in ipairs(self.encoders) do
      obj.remove_listeners(obj)
    end
  end
  if (self.buttons) then
    for _,obj in ipairs(self.buttons) do
      obj.remove_listeners(obj)
    end
  end
  if (self.master) then
    self.master:remove_listeners()
  end
  
  Application.destroy_app(self)
end


--------------------------------------------------------------------------------

function MixConsole:on_new_document()
  TRACE("MixConsole:on_new_document")
  
  self:__attach_to_song(renoise.song())
  self:update()
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
      self:update()
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

  -- validate and update the page scroller and track offset
  if (self.page_controls) then
    self.page_controls:set_maximum(math.max(0, 
      #renoise.song().tracks - self.width))
  end
    
  -- detach all previously added notifiers first
  for _,track in pairs(tracks) do
    track.prefx_volume.value_observable:remove_notifier(self)
    track.prefx_panning.value_observable:remove_notifier(self)
    track.mute_state_observable:remove_notifier(self) 
  end 
  
  -- attach to the new ones in the order we want them
  for control_index=1,math.min(#tracks, self.width) do
    local track_index = self.__track_offset + control_index
    local track = tracks[track_index]
    
    -- track volume level 
    track.prefx_volume.value_observable:add_notifier(
      self, 
      function()
        if (self.active) then
          local value = track.prefx_volume.value
          -- compensate for potential loss of precision 
          if not compare(self.sliders[control_index].value, value, 1000) then
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
          if not compare(self.encoders[control_index].value, value, 1000) then
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
end

