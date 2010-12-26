--[[----------------------------------------------------------------------------
-- Duplex.Mixer
-- Inheritance: Application > Mixer
----------------------------------------------------------------------------]]--

--[[

About

  The Mixer is a generic class for controlling the Renoise mixer
  Assign a mapping for "levels", and Renoise tracks will automatically
  become available on your controller. Assign the "page" mapping, and you'll
  be able to flip through all tracks.

Mappings

  levels  - (UISlider...)       volume, assignable to grid controller
  mute    - (UIToggleButton...) track mute state, embeddable*
  solo    - (UIToggleButton...) track solo state
  master  - (UISlider)          the master volume, embeddable**
  panning - (UISlider...)       track panning
  master  - (UISlider)          control the master track seperately
  page    - (UISpinner)         paged track navigation***
  mode    - (UIToggleButton)    PRE/POST fx toggle

  *   See the notes on "Grid controller layout" for details
  **  In any controller, if volume are assigned. The volume will be
      placed leftmost in the array of sliders


Options

  pre_post      - decide if Mixer should start in PRE or POST fx mode
  invert_mute   - toggle inverted mute state (on when off)
  mute_mode     - decide if mute means MUTE or OFF
  follow_track  - enable this to align with the selected track in Renoise
  offset_track  - specify how many tracks to offset the mixer by


Grid controller mode

  +-----+-----+-----+-----+
  |mute1|mute2|mute3|mute4|
  +-----+-----+-----+-----|
  |  t  |  t  |  t  |  m  |
  |  r  |  r  |  r  |  a  |
  |  a  |  a  |  a  |  s  |
  |  c  |  c  |  c  |  t  |
  |  k  |  k  |  k  |  e  |
  |  1  |  2  |  3  |  r  |
  +-----------------------+

  Assign "levels" to a grid in order to activate grid mode
  The master volume, mute & solo buttons can be embedded into the
  grid by specifying the "levels" control-map 


Notes

  The page size is determined by the actual assignements (checked in this order: 
  volume/mute/solo/panning). The Mixer will automatically check on startup, to 
  see if all specified groups have an identical size.


Changes (equal to Duplex version number)

  0.95  - Dependancies are gone for the various mappings. For example, it's
          possible to run a Mixer instance without the "levels" specified
        - Feature: hold mute button to toggle solo state for the given track
        - Applied feedback fix (cascading mutes when solo'ing)
        - Options: follow_track, mute_mode and track_offset

  0.92  - Remove the destroy_app() method (not needed anymore)
        - Assign tooltips to the virtual control surface

  0.90  - Use the new UIComponent.set_pos() method throughout the class
        - Adjusted colors to degrade better on various devices

  0.81  - First release


--]]


--==============================================================================

class 'Mixer' (Application)

Mixer.default_options = {
  pre_post = {
    label = "Mode",
    description = "Change if either Pre or Post FX volume/pan is controlled",
    on_change = function(inst)
      inst._postfx_mode = (inst.options.pre_post.value==inst.MODE_POSTFX) and 
        true or false
      local new_song = false
      inst:_attach_to_tracks(new_song)
      inst:update()
    end,
    items = {
      "Pre FX volume and panning",
      "Post FX volume and panning",
    },
    value = 1,
  },
  mute_mode = {
    label = "Mute mode",
    description = "Decide if pressing mute will MUTE or OFF the track",
    items = {
      "Use OFF",
      "Use MUTE",
    },
    value = 1,
  },
  invert_mute = {
    label = "Invert display",
    description = "Decide how to display muted tracks",
    items = {
      "Button is lit when track is muted",
      "Button is lit when track is active",
    },
    value = 2,
  },
  follow_track = {
    label = "Follow track",
    description = "Enable this if you want the Mixer to align with " 
                .."\nthe selected track in Renoise",
    on_change = function(inst)
      inst:_follow_track()
    end,
    items = {"Follow track enabled","Follow track disabled"},
    value = 2,
  },
  track_increment = {
    label = "Track increment",
    description = "Specify the step size when flipping through tracks",
    on_change = function(inst)
      inst:_attach_to_tracks()
    end,
    items = {
      "Automatic: use mixer width",
      "1","2","3","4",
      "5","6","7","8",
      "9","10","11","12",
      "13","14","15","16",
    },
    value = 1,
  },
  track_offset = {
    label = "Track offset",
    description = "Change the offset if you want the Mixer to begin " 
                .."\nwith a different track. This is mostly useful if you "
                .."\nwant to run two Mixer instances simultaneously, with "
                .."\none of them being offset by a number of tracks",
    on_change = function(inst)
      inst._track_offset = inst.options.track_offset.value-1
      local new_song = false
      inst:_attach_to_tracks(new_song)        
      inst:update()
    end,
    items = {"0","1","2","3","4","5","6","7"},
    value = 1,
  },
  --[[
  -- TODO
  include_tracks = {
    label = "Tracks",
    description = "Select any combination of tracks that you want to " ..
      "include: normal, master and send tracks.",
    items = {
      "Include all tracks",
      "Normal tracks only",
      "Normal + master tracks",
      "Master track only",
      "Master + send tracks",
      "Send tracks only",
    },
    value = 1,
  },
  ]]

}

function Mixer:__init(display,mappings,options,config_name)
  TRACE("Mixer:__init",display,mappings,options,config_name)



  -- constructor 
  Application.__init(self,config_name)

  self.display = display

    -- define the options (with defaults)
  --[[
  self.ALL_TRACKS = 1
  self.NORMAL = 2
  self.NORMAL_MASTER = 3
  self.MASTER = 4
  self.MASTER_SEND = 5
  self.SEND = 6
  ]]

  self.MODE_PREFX = 1
  self.MODE_POSTFX = 2

  self.MUTE_NORMAL = 1
  self.MUTE_INVERTED = 2

  self.MUTE_MODE_OFF = 1
  self.MUTE_MODE_MUTE = 2

  self.FOLLOW_TRACK_ON = 1
  self.FOLLOW_TRACK_OFF = 2

  self.TRACK_PAGE_AUTO = 1

  self.options = {}

  -- define control-maps groups 
  self.mappings = {
    master = {
      description = "Mixer: Master volume",
      ui_component = UI_COMPONENT_SLIDER,
    },
    levels = {
      description = "Mixer: Track volume",
      ui_component = UI_COMPONENT_SLIDER,
      greedy = true,
    },
    panning = {
      description = "Mixer: Track panning",
      ui_component = UI_COMPONENT_SLIDER,
      greedy = true,
    },
    mute = {
      description = "Mixer: Mute track, hold to solo",
      ui_component = UI_COMPONENT_TOGGLEBUTTON,
      greedy = true,
    },
    solo = {
      description = "Mixer: Solo track",
      ui_component = UI_COMPONENT_TOGGLEBUTTON,
      greedy = true,
    },
    page = {
      description = "Mixer: Track navigator",
      ui_component = UI_COMPONENT_SPINNER,
      orientation = HORIZONTAL,
    },
    mode = {
      description = "Mixer: Pre/Post FX mode",
      ui_component = UI_COMPONENT_TOGGLEBUTTON,
    },
  }

  -- default palette: should degrade nicely for all supported devices

  self.palette = {
    background = {
      color={0,0,0},
      text="·",
    },
      -- normal tracks are green
    normal_tip = {
      color={0x00,0xff,0xff},
      text="■",
    },
    normal_tip_dimmed = {
      color={0x00,0x40,0xff},
      text="□",
    },
    normal_lane = {
      color={0x00,0x81,0xff},
      text="▪",
    },
    normal_lane_dimmed = {
      color={0x00,0x40,0xff},
      text="▫",
    },
    normal_mute = {
      color={0x00,0xff,0xff},
      text="■",
    },
      -- master track is yellow
    master_tip = {
      color={0xff,0xff,0xff},
      text="■",
    },
    master_lane = {
      color={0x80,0x80,0xff},
      text="▪",
    },
    -- send tracks are red
    send_tip = {
      color={0xff,0x00,0xff},
      text="■",
    },
    send_tip_dimmed = {
      color={0x40,0x00,0xff},
      text="□",
    },
    send_lane = {
      color={0x81,0x00,0xff},
      text="▪",
    },
    send_lane_dimmed = {
      color={0x40,0x00,0xff},
      text="▫",
    },
    send_mute = {
      color={0xff,0x00,0xff},
      text="■",
    },
  }

  -- the various controls
  self._master = nil
  self._volume = nil
  self._panning = nil
  self._mutes = nil
  self._solos = nil
  self._page_control = nil
  self._mode_control = nil

  -- the observed width of the mixer, and the step size for
  -- scrolling tracks (the value is derived from one of the
  -- available mappings: volume, mute, solo and panning)
  self._width = nil

  -- offset of the track, as controlled by the track navigator
  -- (not to be confused with the option with the same name)
  self._track_offset = nil
  self._track_page = nil

  -- current track properties we are listening to
  self._attached_track_observables = table.create()

  -- apply arguments
  self.options = options
  self:_apply_mappings(mappings)

  -- toggle, which defines if we're controlling the pre or post fx vol/pans
  self._postfx_mode = (self.options.pre_post.value == self.MODE_POSTFX)

end


--------------------------------------------------------------------------------

-- volume level changed from Renoise

function Mixer:set_track_volume(control_index, value, skip_event_handler)
  TRACE("Mixer:set_track_volume", control_index, value, skip_event_handler)

  if (not skip_event_handler) then
    skip_event_handler = true
  end

  if (self.active) then
    if (self._volume ~= nil) then
      self._volume[control_index]:set_value(value, skip_event_handler)
      
      -- update the master as well, if it has its own UI representation
      if (self._master ~= nil) and 
         (control_index + self._track_offset == get_master_track_index()) 
      then
        self._master:set_value(value, skip_event_handler)
      end
    end
  end
end


--------------------------------------------------------------------------------

-- panning changed from Renoise

function Mixer:set_track_panning(control_index, value, skip_event_handler)
  TRACE("Mixer:set_track_panning", control_index, value, skip_event_handler)

  if (not skip_event_handler) then
    skip_event_handler = true
  end
  if (self.active and self._panning ~= nil) then
    self._panning[control_index]:set_value(value, skip_event_handler)
  end
end


--------------------------------------------------------------------------------

-- mute state changed from Renoise

function Mixer:set_track_mute(control_index, state, skip_event_handler)
  TRACE("Mixer:set_track_mute", control_index, state, skip_event_handler)

  if (not skip_event_handler) then
    skip_event_handler = true
  end
  if (self.active and self._mutes ~= nil) then
    -- set mute state to the button
    local active = (state == MUTE_STATE_ACTIVE)
    self._mutes[control_index]:set(active, skip_event_handler)

    local monochrome = is_monochrome(self.display.device.colorspace)
    if not monochrome then
      if self._volume and 
        self._volume[control_index] 
      then
        self._volume[control_index]:set_dimmed(not active)
      end
      if self._panning and 
        self._panning[control_index] 
      then
        self._panning[control_index]:set_dimmed(not active)
      end
    end

  end
end


--------------------------------------------------------------------------------

-- solo state changed from Renoise

function Mixer:set_track_solo(control_index, state, skip_event_handler)
  TRACE("Mixer:set_track_solo", control_index, state, skip_event_handler)

  if (not skip_event_handler) then
    skip_event_handler = true
  end
  if (self.active and self._solos ~= nil) then
    -- set mute state to the button
    self._solos[control_index]:set(state, skip_event_handler)
  end
end

--------------------------------------------------------------------------------

-- update: set all controls to current values from renoise

function Mixer:update()  
  TRACE("Mixer:update()")

  if (not self.active) then
    return false
  end

  local skip_event = true
  local master_track_index = get_master_track_index()
  local tracks = renoise.song().tracks

  -- track volume/panning/mute and solo
  for control_index = 1,self._width do
  
    local track_index = self._track_offset+control_index
    local track = tracks[track_index]
    local track_type = determine_track_type(track_index)
    local valid_level   = (self._volume  and (control_index<=#self._volume))
    local valid_mute    = (self._mutes   and (control_index<=#self._mutes))
    local valid_solo    = (self._solos   and (control_index<=#self._solos))
    local valid_panning = (self._panning and (control_index<=#self._panning))
    
    -- define palette 
    local track_palette = {}
    local mute_palette = {}
    if (track_type==TRACK_TYPE_SEQUENCER) then
      track_palette.tip           = self.palette.normal_tip
      track_palette.tip_dimmed    = self.palette.normal_tip_dimmed
      track_palette.track         = self.palette.normal_lane
      track_palette.track_dimmed  = self.palette.normal_lane_dimmed
      mute_palette.foreground     = self.palette.normal_mute
    elseif (track_type==TRACK_TYPE_MASTER) then
      track_palette.tip           = self.palette.master_tip
      track_palette.track         = self.palette.master_lane
      mute_palette.foreground     = self.palette.background
    elseif (track_type==TRACK_TYPE_SEND) then
      track_palette.tip           = self.palette.send_tip
      track_palette.tip_dimmed    = self.palette.send_tip_dimmed
      track_palette.track         = self.palette.send_lane
      track_palette.track_dimmed  = self.palette.send_lane_dimmed
      mute_palette.foreground     = self.palette.send_mute
    else
      -- out of bounds
      mute_palette.foreground     = self.palette.background
    end

    -- set default values
    if (track_index <= #tracks) then
      
      if valid_level then
        if (self._postfx_mode) then
          self:set_track_volume(control_index, track.postfx_volume.value)
        else
          self:set_track_volume(control_index, track.prefx_volume.value)
        end
        self._volume[control_index]:set_palette(track_palette)
      end

      if valid_panning then
        if (self._postfx_mode) then
          self:set_track_panning(control_index, track.postfx_panning.value)
        else
          self:set_track_panning(control_index, track.prefx_panning.value)
        end
        self._panning[control_index]:set_palette(track_palette)
      end

      if valid_mute then
        if (track_index == master_track_index) then
          self:set_track_mute(control_index, MUTE_STATE_ACTIVE)
        else
          self:set_track_mute(control_index, track.mute_state)
        end
        self._mutes[control_index]:set_palette(mute_palette)
      end

      if valid_solo then
         self:set_track_solo(control_index, track.solo_state)
        self._solos[control_index]:set_palette(mute_palette)
      end

    else
      -- deactivate, reset controls which have no track
      self:set_track_volume(control_index, 0)
      self:set_track_panning(control_index, 0)
      self:set_track_mute(control_index, MUTE_STATE_OFF)
      self:set_track_solo(control_index, false)
      if self._mutes then
        self._mutes[control_index]:set_palette(mute_palette)
      end

    end

  end

  -- master volume
  if (self._master ~= nil) then
     if (self._postfx_mode) then
       self._master:set_value(get_master_track().postfx_volume.value)
     else
       self._master:set_value(get_master_track().prefx_volume.value)
     end
  end
  
  -- page controls
  if (self._page_control) then
    --local page = math.floor(self._track_offset/self._width)
    local page_width = self:_get_page_width()
    local page = math.floor(self._track_offset/page_width)
    self._page_control:set_index(page,skip_event)
  end

  -- mode controls
  if (self._mode_control) then
    self._mode_control:set(self._postfx_mode)
  end

end


--------------------------------------------------------------------------------

-- start/resume application

function Mixer:start_app()
  TRACE("Mixer.start_app()")

  if not Application.start_app(self) then
    return
  end

  self:_attach_to_song()
  self:update()


end


--------------------------------------------------------------------------------

function Mixer:on_new_document()
  TRACE("Mixer:on_new_document")
  
  self:_attach_to_song()
  
  if (self.active) then
    self:update()
  end
end


--------------------------------------------------------------------------------

-- build_app
-- @return boolean (false if requirements were not met)

function Mixer:_build_app()
  TRACE("Mixer:_build_app(")

  local volume_count = nil
  local mutes_count = nil
  local pannings_count = nil
  local solos_count = nil
  local volume_size = nil
  local master_size = nil
  local grid_w = nil
  local grid_h = nil

  -- check if the control-map describes a grid controller
  local cm = self.display.device.control_map
  local slider_grid_mode = cm:is_grid_group(self.mappings.levels.group_name)
  
  TRACE("Mixer:slider_grid_mode",slider_grid_mode)

  local embed_mutes = (self.mappings.mute.group_name == 
    self.mappings.levels.group_name)
  local embed_master = (self.mappings.master.group_name == 
    self.mappings.levels.group_name)

  TRACE("Mixer:embed_mutes",embed_mutes)
  TRACE("Mixer:embed_master",embed_master)

  -- check that embedded controls are for grid controller
  if not slider_grid_mode and
    embed_mutes 
  then
    local msg = "Message from Mixer: the device configuration specifies "
              .."embedded mute buttons - however, this is only supported when "
              .."the level & mute mappings are assigned to a button grid"
    renoise.app():show_warning(msg)
    return false
  end

  -- determine the size of each group of controls
  local group = cm.groups[self.mappings.levels.group_name]
  if group then
    if slider_grid_mode then
      grid_w,grid_h = cm:get_group_dimensions(self.mappings.levels.group_name)
    end
    if slider_grid_mode then
      volume_count = (embed_master) and grid_w-1 or grid_w
      volume_size = grid_h
    else
      volume_count = #group
      volume_size = 1
    end
  end

  local group = cm.groups[self.mappings.panning.group_name]
  if group then
    pannings_count = #group
  end

  local group = cm.groups[self.mappings.solo.group_name]
  if group then
    solos_count = #group
  end

  local group = cm.groups[self.mappings.mute.group_name]
  if group then
    if slider_grid_mode then
      if embed_mutes then
        mutes_count = (embed_master) and grid_w-1 or grid_w
      else
        mutes_count = volume_count
      end
    else
      mutes_count = #group
    end
  end

  local group = cm.groups[self.mappings.master.group_name]
  if group then
    if slider_grid_mode then
      if embed_master then
        master_size = volume_size
      else
        master_size = #group
      end
    else
      master_size = 1
    end
  end

  -- set the overall mixer size from our groups
  if volume_count then
    self._width = volume_count
  elseif mutes_count then
    self._width = mutes_count
  elseif solos_count then
    self._width = solos_count
  elseif pannings_count then
    self._width = pannings_count
  end

  TRACE("Mixer:established mixer width",self._width)

  -- confirm that the various groups have the same size
  local identical_size = true
  if volume_count and not (self._width==volume_count) then
    identical_size = false
    TRACE("Mixer:volume_count has wrong size",self._width,volume_count)
  end
  if mutes_count and not (self._width==mutes_count) then
    identical_size = false
    TRACE("Mixer:mutes_count has wrong size",self._width,mutes_count)
  end
  if pannings_count and not (self._width==pannings_count) then
    identical_size = false
    TRACE("Mixer:pannings_count has wrong size",self._width,pannings_count)
  end
  if solos_count and not (self._width==solos_count) then
    identical_size = false
    TRACE("Mixer:solos_count has wrong size",self._width,solos_count)
  end
  if not identical_size then
    local msg = "Could not start Duplex Mixer - mappings for volume, "
              .."mutes, solo and panning mappings need to be the same size"
    renoise.app():show_warning(msg)
    return false
  end

  -- create tables to hold the controls
  
  self._volume = (self.mappings.levels.group_name) and {} or nil
  self._panning = (self.mappings.panning.group_name) and {} or nil
  self._mutes = (self.mappings.mute.group_name) and {} or nil
  self._solos = (self.mappings.solo.group_name) and {} or nil

    -- sliders --------------------------------------------

  if self._volume then
    for control_index = 1,volume_count do
      TRACE("Mixer:adding level#",control_index)
      local y_pos = (embed_mutes) and 2 or 1
      local c = UISlider(self.display)
      c.group_name = self.mappings.levels.group_name
      c.tooltip = self.mappings.levels.description
      if (slider_grid_mode) then
        c:set_pos(control_index,y_pos)
      else
        c:set_pos(control_index)
      end
      c.toggleable = true
      c.flipped = false
      c.ceiling = RENOISE_DECIBEL
      c:set_orientation(VERTICAL)
      c:set_size(volume_size-(y_pos-1))
      -- slider changed from controller
      c.on_change = function(obj) 

        if (not self.active) then
          return false
        end

        local track_index = self._track_offset+control_index

        if (track_index == get_master_track_index()) then
          if (self._master) then
            -- update separate master level
            self._master:set_value(obj.value,true)
          end
        elseif (track_index > #renoise.song().tracks) then
          -- track is outside bounds
          return false
        end

        local track = renoise.song().tracks[track_index]
        local volume = (self._postfx_mode) and 
          track.postfx_volume or track.prefx_volume
        volume.value = obj.value

        --return true
  
      end
      
      self:_add_component(c)
      self._volume[control_index] = c

    end
  end
    


    -- encoders -------------------------------------------

  if self._panning then
    for control_index = 1,pannings_count do
      TRACE("Mixer:adding panning#",control_index)
      local c = UISlider(self.display)
      c.group_name = self.mappings.panning.group_name
      c.tooltip = self.mappings.panning.description
      c:set_pos(control_index)
      c.toggleable = true
      c.flipped = false
      c.ceiling = 1.0
      c:set_orientation(VERTICAL)
      c:set_size(1)
      
      -- slider changed from controller
      c.on_change = function(obj) 
        local track_index = self._track_offset + control_index

        if (not self.active) then
          return false

        elseif (track_index > #renoise.song().tracks) then
          -- track is outside bounds
          return false

        else
          local track = renoise.song().tracks[track_index]
          
          local panning = (self._postfx_mode) and 
            track.postfx_panning or track.prefx_panning
        
          panning.value = obj.value
          
          return true
        end
      end
      
      self:_add_component(c)
      self._panning[control_index] = c

    end
  end
        

    -- mute buttons -----------------------------------
    
  if self._mutes then
    for control_index = 1,mutes_count do
      TRACE("Mixer:adding mute#",control_index)
      local c = UIToggleButton(self.display)
      c.group_name = self.mappings.mute.group_name
      c.tooltip = self.mappings.mute.description
      c:set_pos(control_index)
      c.inverted = (self.options.invert_mute.value == self.MUTE_NORMAL) or false
      c.active = false

      -- mute state changed from controller
      -- (update the slider.dimmed property)
      c.on_change = function(obj) 
        local track_index = self._track_offset + control_index

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
          local mute_state
          if (self.options.mute_mode.value == self.MUTE_MODE_MUTE) then
            mute_state = MUTE_STATE_MUTED
          else
            mute_state = MUTE_STATE_OFF
          end
          track.mute_state = mute_state
        end

        local monochrome = is_monochrome(self.display.device.colorspace)
        if not monochrome then
          if (self._volume) then
            self._volume[control_index]:set_dimmed(not obj.active)
          end
          if (self._panning) then
            self._panning[control_index]:set_dimmed(not obj.active)
          end
        end
        
        return true

      end

      -- secondary feature: hold mute button to solo track
      c.on_hold = function(obj)

        local track_index = self._track_offset + control_index

        if (not self.active) then
          return false
        elseif (track_index > #renoise.song().tracks) then
          -- track is outside bounds
          return false
        end
        
        local track = renoise.song().tracks[track_index]
        track.solo_state = not track.solo_state

      end
      
      self:_add_component(c)
      self._mutes[control_index] = c    

    end
  end

  -- solo buttons -----------------------------------

  if self._solos then
    for control_index = 1,solos_count do
      TRACE("Mixer:adding solo#",control_index)
      local c = UIToggleButton(self.display)
      c.group_name = self.mappings.solo.group_name
      c.tooltip = self.mappings.solo.description
      c:set_pos(control_index)
      c.inverted = false
      c.active = false

      -- mute state changed from controller
      -- (update the slider.dimmed property)
      c.on_change = function(obj) 

        local track_index = self._track_offset + control_index

        if (not self.active) then
          return false
        
        elseif (track_index > #renoise.song().tracks) then
          -- track is outside bounds
          return false
        end
        
        local track = renoise.song().tracks[track_index]
        track.solo_state = obj.active

        return true
      end
      
      self:_add_component(c)
      self._solos[control_index] = c    

    end

  end
    

  -- master fader ------------------------------

  if (self.mappings.master.group_name) then
    TRACE("Mixer:adding master")
    local master_pos = self.mappings.master.index or 1
    local c = UISlider(self.display)
    c.group_name = self.mappings.master.group_name
    c.tooltip = self.mappings.master.description
    c:set_pos((embed_master) and (volume_count + 1) or master_pos)
    c.toggleable = true
    c.ceiling = RENOISE_DECIBEL
    c:set_size(master_size)
    c:set_orientation(VERTICAL)
    c.on_change = function(obj) 
      if (not self.active) then
        return false
      else
        local master_control_index = 
          get_master_track_index() - self._track_offset
        if (self._volume and 
            master_control_index > 0 and 
            master_control_index <= volume_count) 
        then
          -- update visible master level slider
          self._volume[master_control_index]:set_value(obj.value,true)
        end
        
        local volume = (self._postfx_mode) and 
          get_master_track().postfx_volume or 
          get_master_track().prefx_volume
        volume.value = obj.value
        
        --return true
      end
    end 
    
    self:_add_component(c)
    self._master = c

  end
  
  
  -- track scrolling ---------------------------
  if (self.mappings.page.group_name) then
    TRACE("Mixer:adding track scrolling")
    local c = UISpinner(self.display)
    c.group_name = self.mappings.page.group_name
    c.tooltip = self.mappings.page.description
    c.index = 0
    c.step_size = 1
    c.minimum = 0
    c.maximum = math.max(0,#renoise.song().tracks-self._width)
    c:set_pos(self.mappings.page.index or 1)
    c:set_orientation(self.mappings.page.orientation)
    c.text_orientation = HORIZONTAL

    c.on_change = function(obj) 
      if (not self.active) then
        return false
      end

     --local track_idx = (obj.index*self._width)
      local page_width = self:_get_page_width()
      local track_idx = (obj.index*page_width)
      if (self.options.follow_track.value == self.FOLLOW_TRACK_ON) then
        -- if the follow_track option is specified, we set the
        -- track index and let the _follow_track() method handle it
        renoise.song().selected_track_index = 1+track_idx
      else
        self._track_offset = track_idx
        local new_song = false
        self:_attach_to_tracks(new_song)
        self:update()
      end
    end
    
    self:_add_component(c)
    self._page_control = c

  end


  -- Pre/Post FX mode ---------------------------

  if (self.mappings.mode.group_name) then
    TRACE("Mixer:adding Pre/Post FX mode")
    local c = UIToggleButton(self.display)
    c.group_name = self.mappings.mode.group_name
    c.tooltip = self.mappings.mode.description
    c:set_pos(self.mappings.mode.index or 1)
    c.inverted = false
    c.active = false

    -- mode state changed from controller
    c.on_change = function(obj) 
      if (not self.active) then
        return false
      end
      
      if (self._postfx_mode ~= obj.active) then
        self._postfx_mode = obj.active
        
        local new_song = false
        self:_attach_to_tracks(new_song)
        
        self:update()
      end

      return true
    end
    
    self:_add_component(c)
    self._mode_control = c

  end
    
  Application._build_app(self)
  return true

end

--------------------------------------------------------------------------------

-- test if the provided track offset is currently being displayed
-- @return boolean
--[[
function Mixer:_track_within_range(track_idx)
  TRACE("Mixer:_track_within_range(",track_idx,")")

  if (track_idx > (self._track_offset+self._width)) 
    or (track_idx <= self._track_offset) 
  then
    return false
  else
    return true
  end

end
]]

--------------------------------------------------------------------------------

-- adds notifiers to song
-- invoked when a new document becomes available

function Mixer:_attach_to_song()
  TRACE("Mixer:_attach_to_song")
  
  local song = renoise.song()

  self._track_offset = self.options.track_offset.value-1
  -- update on track changes in the song
  song.tracks_observable:add_notifier(
    function()
      TRACE("Mixer:tracks_changed fired...")
      
      local new_song = false
      self:_attach_to_tracks(new_song)
      
      if (self.active) then
        self:update()
      end
    end
  )

  -- and immediately attach to the current track set
  local new_song = true
  self:_attach_to_tracks(new_song)

  -- follow active track in Renoise
  song.selected_track_index_observable:add_notifier(
    function()
      TRACE("Mixer:selected_track_observable fired...")
      self:_follow_track()
    end
  )

  self:_follow_track()

end


--------------------------------------------------------------------------------

-- when following the active track in Renoise, we call this method

function Mixer:_follow_track()
  TRACE("Mixer:_follow_track()")

  if (self.options.follow_track.value == self.FOLLOW_TRACK_OFF) then
    return
  end

  local song = renoise.song()
  local track_idx = song.selected_track_index+self.options.track_offset.value-1
  local page = self:_get_track_page(track_idx)
  local page_width = self:_get_page_width()
  if (page~=self._track_page) then
    self._track_page = page
    self._track_offset = page*page_width
    local new_song = false
    self:_attach_to_tracks(new_song)        
    self:update()
  end

end

--------------------------------------------------------------------------------

-- figure out the active "track page" based on the supplied track index
-- @param track_idx (1-number of tracks)
-- return integer (0-number of pages)

function Mixer:_get_track_page(track_idx)

  local page_width = self:_get_page_width()
  local page = math.floor((track_idx-1)/page_width)
  return page

end


--------------------------------------------------------------------------------

function Mixer:_get_page_width()

  return (self.options.track_increment.value==self.TRACK_PAGE_AUTO)
    and self._width or self.options.track_increment.value-1

end

--------------------------------------------------------------------------------

-- add notifiers to parameters
-- invoked when tracks are added/removed/swapped

function Mixer:_attach_to_tracks(new_song)
  TRACE("Mixer:_attach_to_tracks", new_song)

  local tracks = renoise.song().tracks

  -- validate and update the sequence/track offset
  if (self._page_control) then
    local page_width = self:_get_page_width()
    local pages = math.floor((#renoise.song().tracks-1)/page_width)
    self._page_control:set_range(nil,math.max(0,pages))
  end
    
  -- detach all previously added notifiers first
  -- but don't even try to detach when a new song arrived. old observables
  -- will no longer be alive then...
  if (not new_song) then
    for _,observable in pairs(self._attached_track_observables) do
      -- temp security hack. can also happen when removing tracks
      pcall(function() observable:remove_notifier(self) end)
    end
  end
  
  self._attached_track_observables:clear()
  
  
  -- attach to the new ones in the order we want them
  local master_idx = get_master_track_index()
  local master_done = false
  
  -- track volume level 
  if self._volume then
    for control_index = 1,math.min(#tracks, #self._volume) do
      local track_index = self._track_offset + control_index
      local track = tracks[track_index]
      if not track then
        break
      end
      local volume = (self._postfx_mode) and 
        track.postfx_volume or track.prefx_volume
      self._attached_track_observables:insert(
        volume.value_observable)
      volume.value_observable:add_notifier(
        self, 
        function()
          if (self.active) then
            local value = volume.value
            -- compensate for potential loss of precision 
            if not compare(self._volume[control_index].value, value, 1000) then
              self:set_track_volume(control_index, value)
            end
          end
        end 
      )
      if (track_index == master_idx) then
        master_done = true
      end
    end
  end

  -- track panning 
  if self._panning then
    for control_index = 1,math.min(#tracks, #self._panning) do
      local track_index = self._track_offset + control_index
      local track = tracks[track_index]
      if not track then
        break
      end
      local panning = (self._postfx_mode) and 
         track.postfx_panning or track.prefx_panning
      
      self._attached_track_observables:insert(
        panning.value_observable)

      panning.value_observable:add_notifier(
        self, 
        function()
          if (self.active) then
            local value = panning.value
            -- compensate for potential loss of precision 
            if not compare(self._panning[control_index].value, value, 1000) then
              self:set_track_panning(control_index, value)
            end
          end
        end 
      )
    end
  end

  -- track mute-state 
  if self._mutes then
    for control_index = 1,math.min(#tracks, #self._mutes) do
      local track_index = self._track_offset + control_index
      local track = tracks[track_index]
      if not track then
        break
      end
      self._attached_track_observables:insert(track.mute_state_observable)
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

      -- track solo-state 
  if self._solos then
    for control_index = 1,math.min(#tracks, #self._solos) do
      local track_index = self._track_offset + control_index
      local track = tracks[track_index]
      if not track then
        break
      end
      self._attached_track_observables:insert(track.solo_state_observable)
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
  if (not master_done and self._master) then
    local track = renoise.song().tracks[master_idx]
    local volume = (self._postfx_mode) and 
      track.postfx_volume or track.prefx_volume

    self._attached_track_observables:insert(
      volume.value_observable)
  
    volume.value_observable:add_notifier(
      self, 
      function()
        if (self.active) then
          local value = volume.value
          -- compensate for potential loss of precision 
          if not compare(self._master.value, value, 1000) then
            self._master:set_value(value)
          end
        end
      end 
    )
  end

end

