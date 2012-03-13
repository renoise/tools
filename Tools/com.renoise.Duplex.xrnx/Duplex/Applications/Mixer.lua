--[[----------------------------------------------------------------------------
-- Duplex.Mixer
-- Inheritance: Application > Mixer
----------------------------------------------------------------------------]]--

--[[

About

  The Mixer is a generic class for controlling the Renoise mixer

Mappings

  levels  - (UISlider...)       volume *
  mute    - (UIButton...) track mute *
  solo    - (UIButton...) track solo *
  master  - (UISlider)          master volume *
  panning - (UISlider...)       track panning
  page    - (UISpinner)         paged track navigation
  mode    - (UIButton)    PRE/POST fx toggle

  *  Automatic layout when using a grid controller


Options

  pre_post      - decide if Mixer should start in PRE or POST fx mode
  mute_mode     - decide if mute means MUTE or OFF
  offset_track  - specify how many tracks to offset the mixer by
  follow_track  - align with the selected track in Renoise
  page_size     - specify step size when using paged navigation

Automatic grid controller layout

  Assigning the levels, mute and/or solo mapping to the same group
  (the grid) will automaticaly produce the following layout:

  +---- - --- - --- - --- +    +---- +  The master track 
  |mute1|mute2|mute3|mute4| -> |  m  |  will, when specified, 
  +---- - --- - --- - --- +    +  a  +  show up in the 
  |solo1|solo2|solo3|solo4| -> |  s  |  rightmost side 
  +---- - --- - --- - --- +    +  t  +  and use full height
  |  l  |  l  |  l  |  l  | -> |  e  |  
  +  e  +  e  +  e  +  e  +    +  r  +  
  |  v  |  v  |  v  |  v  |    |     |  
  +  e  +  e  +  e  +  e  +    +     +  
  |  l  |  l  |  l  |  l  |    |     |
  +     +     +     +     +    +     +
  |  1  |  2  |  3  |  4  |    |     |
  +---- - --- - --- - --- +    +---- +
  

Notes

  The Mixer will automatically check on startup, to 
  see if all specified groups have an identical size


Changes (equal to Duplex version number)

  0.97  - Renoise's 2.7 multi-solo mode supported/visualized
        - Main display updates now happen in on_idle loop
        - Ability to embed both mute & solo mappings into grid
        - New option: "sync_pre_post" (Renoise 2.7+)

  0.96  - Option: paged navigation features (page_size)
        - Option: offset tracks by X (for the Ohm64 configuration)

  0.95  - Dependancies are gone for the various mappings. For example, it's
          possible to run a Mixer instance without the "levels" specified
        - Feature: hold mute button to toggle solo state for the given track
        - Applied feedback fix (cascading mutes when solo'ing)
        - Options: follow_track, mute_mode

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
    label = "Pre/Post mode",
    description = "Change if either Pre or Post FX volume/pan is controlled",
    on_change = function(inst)
      inst._postfx_mode = (inst.options.pre_post.value==inst.MODE_POSTFX) and 
        true or false
      inst._update_requested = true
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
  page_size = {
    label = "Page size",
    description = "Specify the step size when using paged navigation",
    on_change = function(inst)
      inst:_attach_to_tracks()
    end,
    items = {
      "Automatic: use available width",
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
      inst._update_requested = true
    end,
    items = {"0","1","2","3","4","5","6","7"},
    value = 1,
  },
  take_over_volumes = {
    label = "Soft takeover",
    description = "Enables soft take-over for volume: useful if faders of the device are not motorized. "
                .."\nThis feature will not take care of the position of the fader until"
                .."\nthe volume value is reached. "
                .."\nExample: you are playing a song A and you finish it by fading out the master volume."
                .."\nWhen you load a song B, the master volume will not jump to 0 "
                .."\nwhen you move again the fader of master volume.",
    items = {
      "Disabled",
      "Enabled",
    },
    value = 1,
  },
  record_method = {
    label = "Automation rec.",
    description = "Determine how to record automation ",
    items = {
      "Disabled, do not record automation",
      "Touch, record only when touched",
      "Latch record (experimental)",
    },
    value = 1,
    on_change = function(inst)
      inst.automation.latch_record = (inst.options.record_method.value==inst.RECORD_LATCH) 
      inst:update_record_mode()
    end
  }

}

-- add Renoise 2.7+ specific options
if (renoise.API_VERSION >=2) then
  Mixer.default_options["sync_pre_post"] = {
    label = "Pre/Post sync",
    description = "Decide if switching Pre/Post is reflected "
              .."\nboth in Renoise and on the controller",
    items = {
      "Pre/Post sync is enabled",
      "Pre/Post sync is disabled",
    },
    value = 1,
  }
end


function Mixer:__init(process,mappings,options,cfg_name,palette)
  TRACE("Mixer:__init",process,mappings,options,cfg_name,palette)

  self.MODE_PREFX = 1
  self.MODE_POSTFX = 2

  self.MODE_PREPOSTSYNC_ON = 1
  self.MODE_PREPOSTSYNC_OFF = 2

  self.MUTE_MODE_OFF = 1
  self.MUTE_MODE_MUTE = 2

  self.FOLLOW_TRACK_ON = 1
  self.FOLLOW_TRACK_OFF = 2

  self.TRACK_PAGE_AUTO = 1

  self.TAKE_OVER_VOLUME_OFF = 1
  self.TAKE_OVER_VOLUME_ON = 2
  
  self.RECORD_NONE = 1
  self.RECORD_TOUCH = 2
  self.RECORD_LATCH = 3

  self.mappings = {
    master = {
      description = "Mixer: Master volume",
    },
    levels = {
      description = "Mixer: Track volume",
    },
    panning = {
      description = "Mixer: Track panning",
    },
    mute = {
      description = "Mixer: Mute track",
    },
    solo = {
      description = "Mixer: Solo track",
    },
    page = {
      description = "Mixer: Track navigator",
      orientation = HORIZONTAL,
    },
    mode = {
      description = "Mixer: Pre/Post FX mode",
    },
  }

  self.palette = {
    background        = { color={0x00,0x00,0x00}, val = false,text="·",},
    -- normal tracks
    normal_tip = {        color={0x00,0xff,0xff}, val = true, },
    normal_tip_dimmed = { color={0x00,0x40,0xff}, val = true, },
    normal_lane       = { color={0x00,0x81,0xff}, val = true, },
    normal_lane_dimmed = {color={0x00,0x40,0xff}, val = true, },
    normal_mute_on    = { color={0x40,0xff,0x40}, val = true, text ="M"},
    normal_mute_off   = { color={0x00,0x00,0x00}, val = false,text ="M",},
    -- master track
    master_tip        = { color={0xff,0xff,0xff}, val = true, },
    master_lane       = { color={0x80,0x80,0xff}, val = true, },
    master_mute_on    = { color={0xff,0xff,0x40}, val = true, text ="M",},
    -- send tracks
    send_tip          = { color={0xff,0x40,0x00}, val = true, },
    send_tip_dimmed   = { color={0x40,0x00,0xff}, val = true, },
    send_lane         = { color={0x81,0x00,0xff}, val = true, },
    send_lane_dimmed  = { color={0x40,0x00,0xff}, val = true, },
    send_mute_on      = { color={0xff,0x40,0x00}, val = true, text = "M", },
    send_mute_off     = { color={0x00,0x00,0x00}, val = false,text = "M", },
    -- pre/post buttons
    mixer_mode_pre    = { color={0xff,0xff,0xff}, val = true, text = "Pre",},
    mixer_mode_post   = { color={0x00,0x00,0x00}, val = false,text = "Post",},
    -- solo buttons
    solo_on           = { color={0xff,0x40,0x00}, val = true, text = "S",},
    solo_off          = { color={0x00,0x00,0x00}, val = false,text = "S", },

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
  self._width = 0

  -- offset of the track, as controlled by the track navigator
  -- (not to be confused with the option with the same name)
  self._track_offset = nil
  self._track_page = nil

  -- current track properties we are listening to
  self._attached_track_observables = table.create()

  self._update_requested = false

  -- use Automation class to record movements
  self.automation = Automation()

  -- set while recording automation
  self._record_mode = false

  -- list of takeover volumes
  self._take_over_volumes = {}

  -- apply arguments
  Application.__init(self,process,mappings,options,cfg_name,palette)

  -- toggle, which defines if we're controlling the pre or post fx vol/pans
  self._postfx_mode = (self.options.pre_post.value == self.MODE_POSTFX)

  -- possible after options have been set
  self.automation.latch_record = (self.options.record_method.value==self.RECORD_LATCH)

end

--------------------------------------------------------------------------------

-- set pre/post mode
--[[
function Mixer:_set_pre_post(bool,skip_event)



end
]]

--------------------------------------------------------------------------------

-- perform periodic updates

function Mixer:on_idle()

  if (not self.active) then 
    return 
  end
  if(self._update_requested) then
    self._update_requested = false
    self:_attach_to_tracks()
    self:update()
  end

  if self._record_mode then
    self.automation:update()
  end

end



--------------------------------------------------------------------------------

-- volume level changed from Renoise

function Mixer:set_track_volume(control_index, value)
  TRACE("Mixer:set_track_volume", control_index, value)

  if not self.active then
    return
  end

  local skip_event = true

  if (self._volume ~= nil) then

    -- update track control
    self._volume[control_index]:set_value(value, skip_event)
    
    -- reset the takeover hook (when not recording, as automation recording  
    -- output a stream of new values, and we would get caught in a "reset-loop")
    if not self._record_mode then
      if self._take_over_volumes[control_index] then
        self._take_over_volumes[control_index].hook = true
      end
    end

    -- update the master as well, if it has its own UI representation
    if (self._master ~= nil) and 
       (control_index + self._track_offset == get_master_track_index()) 
    then
      self._master:set_value(value, skip_event)
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

function Mixer:set_track_mute(control_index, state)
  TRACE("Mixer:set_track_mute", control_index, state)

  if (self.active and self._mutes ~= nil) then
    local muted = (state == MUTE_STATE_ACTIVE)
    local master_track_index = get_master_track_index()
    local track_index = self._track_offset+control_index
    local button = self._mutes[control_index]
    if (track_index > master_track_index) then
      if muted then
        button:set(self.palette.send_mute_on)
      else
        button:set(self.palette.send_mute_off)
      end
    elseif (track_index == master_track_index) then
      button:set(self.palette.master_mute_on)
    else
      if muted then
        button:set(self.palette.normal_mute_on)
      else
        button:set(self.palette.normal_mute_off)
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
    if state then
      self._solos[control_index]:set(self.palette.solo_on)
    else
      self._solos[control_index]:set(self.palette.solo_off)
    end
  end
end


--------------------------------------------------------------------------------

-- return true if any track is soloed

function Mixer:_any_track_is_soloed()

  for v,track in ipairs(renoise.song().tracks) do
    if track.solo_state then
      return true
    end
  end
  return false
end

--------------------------------------------------------------------------------

-- set dimmed state of slider - will only happen when:
-- - the controller has a color display
-- - when the control is unsolo'ed or unmuted

function Mixer:set_dimmed(control_index)
  TRACE("Mixer:set_dimmed()",control_index)


  local track_index = self._track_offset + control_index
  local track = renoise.song().tracks[track_index]
  if (track) then

    local dimmed = false
    local any_solo = self:_any_track_is_soloed()

    if any_solo then
      dimmed = (not track.solo_state)
    else
      dimmed = (track.mute_state~=MUTE_STATE_ACTIVE)
    end

    local monochrome = is_monochrome(self.display.device.colorspace)
    if not monochrome then
      if self._volume and 
        self._volume[control_index] 
      then
        self._volume[control_index]:set_dimmed(dimmed)
      end
      if self._panning and 
        self._panning[control_index] 
      then
        self._panning[control_index]:set_dimmed(dimmed)
      end
    end

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
    if (track_type==TRACK_TYPE_SEQUENCER) then
      track_palette.tip           = self.palette.normal_tip
      track_palette.tip_dimmed    = self.palette.normal_tip_dimmed
      track_palette.track         = self.palette.normal_lane
      track_palette.track_dimmed  = self.palette.normal_lane_dimmed
    elseif (track_type==TRACK_TYPE_MASTER) then
      track_palette.tip           = self.palette.master_tip
      track_palette.track         = self.palette.master_lane
    elseif (track_type==TRACK_TYPE_SEND) then
      track_palette.tip           = self.palette.send_tip
      track_palette.tip_dimmed    = self.palette.send_tip_dimmed
      track_palette.track         = self.palette.send_lane
      track_palette.track_dimmed  = self.palette.send_lane_dimmed
    end

    -- assign values, update appearance
    if (track_index <= #tracks) then
      
      if valid_level then
        local value = (self._postfx_mode) and
          track.postfx_volume.value or track.prefx_volume.value
        self:set_track_volume(control_index, value)
        self._volume[control_index]:set_palette(track_palette)
      end

      if valid_panning then
        local value = (self._postfx_mode) and 
          track.postfx_panning.value or track.prefx_panning.value
        self:set_track_panning(control_index, value)
        self._panning[control_index]:set_palette(track_palette)
      end

      if valid_mute then
        local mute_state = (track_index == master_track_index) and
          MUTE_STATE_ACTIVE or track.mute_state
        self:set_track_mute(control_index, mute_state)
      end

      if valid_solo then
        self:set_track_solo(control_index, track.solo_state)
      end

    else
      -- deactivate, reset controls which have no track
      self:set_track_volume(control_index, 0)
      self:set_track_panning(control_index, 0)
      self:set_track_mute(control_index, MUTE_STATE_OFF)
      self:set_track_solo(control_index, false)

    end

    -- update the dimmed state 
    self:set_dimmed(control_index)

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
    local page_width = self:_get_page_width()
    local page = math.floor(self._track_offset/page_width)
    self._page_control:set_index(page,skip_event)
  end

  -- mode controls
  if (self._mode_control) then
    if self._postfx_mode then
      self._mode_control:set(self.palette.mixer_mode_pre)
    else
      self._mode_control:set(self.palette.mixer_mode_post)
    end
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

  self:_init_take_over_volume()
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
  
  --TRACE("Mixer:slider_grid_mode",slider_grid_mode)

  local embed_mutes = (self.mappings.mute.group_name == 
    self.mappings.levels.group_name)
  local embed_solos = (self.mappings.solo.group_name == 
    self.mappings.levels.group_name)
  local embed_master = (self.mappings.master.group_name == 
    self.mappings.levels.group_name)

  --TRACE("Mixer:embed_mutes",embed_mutes)
  --TRACE("Mixer:embed_master",embed_master)

  -- check that embedded controls are for grid controller
  --[[
  if not slider_grid_mode and
    (embed_mutes or embed_solos) 
  then
    local msg = "Message from Mixer: embedded mappings are only "
              .."available for a grid controller (please read the "
              .."Mixer.lua file for more information)"
    renoise.app():show_warning(msg)
    return false
  end
  ]]

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
    if slider_grid_mode then
      if embed_solos then
        solos_count = (embed_master) and grid_w-1 or grid_w
      else
        solos_count = volume_count
      end
    else
      solos_count = #group
    end
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
  self._width = 0
  if volume_count then
    self._width = volume_count
  elseif mutes_count then
    self._width = mutes_count
  elseif solos_count then
    self._width = solos_count
  elseif pannings_count then
    self._width = pannings_count
  end

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
      local y_pos = (embed_mutes) and ((embed_solos) and 3 or 2) or 1
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

        -- when take-over is enabled, this can return false 
        return self:_set_volume(volume,track_index,obj)
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
          
          if self._record_mode then
            self.automation:add_automation(track_index,panning,obj.value)
          end

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
      local c = UIButton(self.display)
      c.group_name = self.mappings.mute.group_name
      c.tooltip = self.mappings.mute.description
      c:set_pos(control_index)
      c.active = false

      -- mute state changed from controller
      -- (update the slider.dimmed property)
      c.on_press = function(obj) 
        local track_index = self._track_offset + control_index

        if (not self.active) then
          return false
        
        elseif (track_index == get_master_track_index()) then
          -- can't mute the master track
          return 
        
        elseif (track_index > #renoise.song().tracks) then
          -- track is outside bounds
          return 
        end
        
        local track = renoise.song().tracks[track_index]
        local track_is_muted = (track.mute_state ~= MUTE_STATE_ACTIVE)

        if (track_is_muted) then
          track:unmute()
        else 
          track:mute()
          local mute_state = (self.options.mute_mode.value==self.MUTE_MODE_MUTE)
            and MUTE_STATE_MUTED or MUTE_STATE_OFF
          track.mute_state = mute_state
        end

        self:set_dimmed(control_index)

      end

      -- secondary feature: hold mute button to solo track
      --[[
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
      ]]
      
      self:_add_component(c)
      self._mutes[control_index] = c    

    end
  end

  -- solo buttons -----------------------------------

  if self._solos then
    for control_index = 1,solos_count do
      TRACE("Mixer:adding solo#",control_index)
      local c = UIButton(self.display)
      c.group_name = self.mappings.solo.group_name
      c.tooltip = self.mappings.solo.description
      if embed_solos then
        local y_pos = (embed_mutes) and 2 or 1
        c:set_pos(control_index,y_pos)
      else
        c:set_pos(control_index)
      end
      c.active = false

      -- mute state changed from controller
      -- (update the slider.dimmed property)
      c.on_press = function(obj) 

        if (not self.active) then
          return false
        end

        local track_index = self._track_offset + control_index
        if (track_index > #renoise.song().tracks) then
          -- track is outside bounds
          return 
        end
        
        local track = renoise.song().tracks[track_index]
        track.solo_state = not track.solo_state

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
    c:set_palette({
      tip=self.palette.master_tip,
      track=self.palette.master_lane,
    })
    c.on_change = function(obj) 
      if (not self.active) then
        return false
      else
        local track_index = get_master_track_index()
        local control_index = track_index - self._track_offset
        if (self._volume and 
            control_index > 0 and 
            control_index <= volume_count) 
        then
          -- update visible master level slider
          self._volume[control_index]:set_value(obj.value,true)
        end
        local track = get_master_track()

        local volume = (self._postfx_mode) and 
          track.postfx_volume or track.prefx_volume

        local was_set = self:_set_volume(volume,track_index,obj)

        -- when take-over is enabled, this can return false 
        return was_set
        
      end
    end 
    
    self:_add_component(c)
    self._master = c

  end
  
  
  -- track scrolling ---------------------------
  if (self.mappings.page.group_name) then
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

      local page_width = self:_get_page_width()
      local track_idx = (obj.index*page_width)
      if (self.options.follow_track.value == self.FOLLOW_TRACK_ON) then
        -- set track index and let the _follow_track() method handle it
        renoise.song().selected_track_index = 1+track_idx
      else
        self._track_offset = track_idx
        self._update_requested = true

      end
      self:_init_take_over_volume()
      return true
    end
    
    self:_add_component(c)
    self._page_control = c

  end


  -- Pre/Post FX mode ---------------------------

  if (self.mappings.mode.group_name) then
    TRACE("Mixer:adding Pre/Post FX mode")
    local c = UIButton(self.display)
    c.group_name = self.mappings.mode.group_name
    c.tooltip = self.mappings.mode.description
    c:set_pos(self.mappings.mode.index or 1)
    c.active = false

    -- mode state changed from controller
    c.on_press = function(obj) 
      if (not self.active) then
        return false
      end
      
      self._postfx_mode = not self._postfx_mode
      self._update_requested = true
      self:_init_take_over_volume()

      if self.options.sync_pre_post and
        (self.options.sync_pre_post.value == self.MODE_PREPOSTSYNC_ON) 
      then
        renoise.app().window.mixer_view_post_fx = self._postfx_mode
        end


    end
    
    self:_add_component(c)
    self._mode_control = c

  end
    
  Application._build_app(self)
  return true

end

--------------------------------------------------------------------------------

-- set volume with support for automation recording and soft takeover
-- @return boolean (true when volume has been set)

function Mixer:_set_volume(parameter,track_index,obj)
  TRACE("Mixer:_set_volume()",parameter,track_index,obj)

  local value_set = false
  if self.options.take_over_volumes.value == self.TAKE_OVER_VOLUME_ON then
    value_set = self:_set_take_over_volume(parameter, obj, track_index)
  else
    parameter.value = obj.value
    value_set = true
  end
  if value_set and self._record_mode then
    -- scale back value to 0-1 range
    self.automation:add_automation(
      track_index,parameter,obj.value/RENOISE_DECIBEL)
  end

  return value_set

end


--------------------------------------------------------------------------------

-- update the record mode (when editmode or record_method has changed)

function Mixer:update_record_mode()
  TRACE("Mixer:update_record_mode")
  if (self.options.record_method.value ~= self.RECORD_NONE) then
    self._record_mode = renoise.song().transport.edit_mode 
  else
    self._record_mode = false
  end
end

--------------------------------------------------------------------------------

-- adds notifiers to song
-- invoked when a new document becomes available

function Mixer:_attach_to_song()
  TRACE("Mixer:_attach_to_song")
  
  local song = renoise.song()

  -- attach to mixer PRE/POST 
  if (renoise.API_VERSION >=2) then
    renoise.app().window.mixer_view_post_fx_observable:add_notifier(
      function()
        TRACE("Mixer:mixer_view_post_fx_observable fired...")
        if (self.options.sync_pre_post.value == self.MODE_PREPOSTSYNC_ON) then
          self._postfx_mode = renoise.app().window.mixer_view_post_fx
          self._update_requested = true
        end
      end
    )
  end

  self._track_offset = self.options.track_offset.value-1
  -- update on track changes in the song
  song.tracks_observable:add_notifier(
    function()
      TRACE("Mixer:tracks_changed fired...")
      self._update_requested = true
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

  -- track edit_mode, and set record_mode accordingly
  renoise.song().transport.edit_mode_observable:add_notifier(
    function()
      TRACE("Mixer:edit_mode_observable fired...")
        self:update_record_mode()
    end
  )
  self:update_record_mode()

  -- attach Automation class
  self.automation:attach_to_song(new_song)

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
  if (page~=self._track_page) then
    self._track_page = page
    self._track_offset = page*self:_get_page_width()
    self._update_requested = true
    self:_init_take_over_volume()

  end

end

--------------------------------------------------------------------------------

-- figure out the active "track page" based on the supplied track index
-- @param track_idx, renoise track number
-- return integer (0-number of pages)

function Mixer:_get_track_page(track_idx)

  local page_width = self:_get_page_width()
  return math.floor((track_idx-1)/page_width)

end


--------------------------------------------------------------------------------

function Mixer:_get_page_width()

  return (self.options.page_size.value==self.TRACK_PAGE_AUTO)
    and self._width or self.options.page_size.value-1

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
            if not self._record_mode and
              not compare(self._volume[control_index].value, value, 1000) then
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
            self._update_requested = true

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

-- Sets the volume of a track when a Controller's fader hooks the actual
-- volume of the track.
-- @param p_volume (DeviceParameter)
-- @param p_obj (UIComponent) the control that contain the value
-- @param p_track_index (number) look for / remember by this index 
-- @return (boolean) true when value was set
function Mixer:_set_take_over_volume(p_volume, p_obj, p_track_index)
  TRACE("Mixer:_set_take_over_volume()",p_volume, p_obj, p_track_index)

  local p_from_master = (p_track_index == get_master_track_index())

  -- If a fader is not registered into the table, we init it
  if not self._take_over_volumes[p_track_index] then
    self._take_over_volumes[p_track_index] = {hook = true, last_value = nil}
  end

  local take_over = self._take_over_volumes[p_track_index]
  local value_set = false

  -- Master volume can be controlled by 2 sliders at the same time.
  -- Need to determinated if the hook system must be reset depending on which
  -- fader control it.
  if p_from_master ~= nil then
    if take_over.master_move ~= p_from_master then
      take_over.hook = true
      take_over.last_value = p_obj.value
    end
    take_over.master_move = p_from_master
  end
      
  -- If hook is activated, fader will have no effect on track volume
  if take_over.hook then
    if not take_over.last_value then
      take_over.last_value = p_obj.value
    end

    -- determines if fader has reached/crossed the track volume
    -- first, see if the volume is within threshold ("sticky")
    local reached = compare(p_volume.value,p_obj.value,5)
    if not reached then
      local x1 = p_volume.value - take_over.last_value 
      local x2 = p_volume.value - p_obj.value
      reached = (sign(x1) ~= sign(x2))
    end
    
    if reached then 
      p_volume.value = p_obj.value
      take_over.hook = false
      value_set = true
    end
  else
    -- hook is deactivated, Mixer reacts normally
    p_volume.value = p_obj.value
    take_over.last_value = p_obj.value
    --print("change take-over to this value",p_track_index,p_obj.value)
    value_set = true
  end

  --rprint(self._take_over_volumes)
  return value_set

end

-- Init (or re-init) hook system. For instance, when a new song is loaded or
-- when user moves among tracks.
function Mixer:_init_take_over_volume()
  TRACE("Mixer:_init_take_over_volume()")
  for _, v in pairs(self._take_over_volumes) do 
    v.hook = true
    v.last_value = nil
  end
end
