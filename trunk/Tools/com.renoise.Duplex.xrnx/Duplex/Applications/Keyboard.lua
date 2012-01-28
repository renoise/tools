--[[----------------------------------------------------------------------------
-- Duplex.Keyboard
-- Inheritance: Application > Keyboard
----------------------------------------------------------------------------]]--

--[[

About

  The Keyboard application is designed as a drop-in replacement of the standard Renoise keyboard, with support for both MIDI and OSC devices.

  Essentially, the Keyboard application can be used in two ways: as a standard keyboard (visulized as black & white keys in the virtual control surface), and as individually-mapped keys/pads, suitable for grid and pad controllers.

  When you are using the application in the standard keyboard mode, it might receive pitch bend and channel pressure information from the device, which can then be A) ignored, B) broadcast as MIDI (unchanged), C) or routed internally to any MIDI CC message (this in turn means that you can easily use the native MIDI mapping in Renoise to map the pitch bend to any parameter) 

  In grid mode, the Keyboard application is able to visualize the currently selected instrument's keyzone/sample mappings in realtime. This makes it a lot easier to see exactly where each sound is located, and even works as you are moving mappings around, or transposing the keyboard (octave up/down). Also, all of the UISlider mappings (volume, octave, pitch bend, etc.) support grid mode, as their mappings can be mapped to buttons just as easily as they can be mapped to a physical slider or fader. 

  Furthermore, since we are using internally-triggered notes we have the ability to trigger notes inside a specific track, using a specific instrument. 
  The default setting is identical to the standard behaviour in Renoise, and simply uses the currently selected track/instrument. But it's possible to select any track or instrument using the options "Active track/instr.", choosing any number between 1-64 (a planned feature is to "lock" the track or instrument by assigning a special name to it, something which has not made it into this initial release).

  Finally, you can stack multiple Keyboard applications to control/trigger multiple instruments with a single master keyboard. The "MIDI-Keyboard" device comes with a configuration that demonstrate this ("Stacked Keys"), in which three instrument are triggered, each with different velocity settings.

How to add Keyboard to your control-map:

  ...



Prerequisites

  The Keyboard application will not work unless you have enabled the internal
  OSC server in Renoise (Renoise prefereces -> OSC settings). It should be set
  to "UPD" protocol, and use the same port as specified in Duplex/Globals.lua
  (by default, this is set to the same value as Renoise, "8000").


Changes (equal to Duplex version number)

  0.98 - First release 


--]]

--==============================================================================


class 'Keyboard' (Application)

Keyboard.default_options = {

  instr_index = {
    label = "Active Instr.",
    description = "Choose which instrument to control",
    items = {
      "Follow selection"
    },
    value = 1,
  },
  track_index = {
    label = "Active Track",
    description = "Choose which track to use ",
    items = {
      "Follow selection"
    },
    value = 1,
  },
  velocity = {
    label = "Velocity Mode",
    description = "Determine how to act on velocity range (specified in control-map)",
    items = {
      "Clamp (restrict to range)",
      "Clip (within range only)",
    },
    value = 1,
  },
  base_volume = {
    label = "Base Volume",
    description = "Determine how to control keyboard volume",
    on_change = function(app)
      local val = app.options.base_volume.value
      if (val>1) then
        app:set_volume(val-2,true)
      else
        app:set_volume(renoise.song().transport.keyboard_velocity,true)
      end
    end,
    items = {
      "Sync with Renoise"
    },
    value = 1,
  },
  channel_pressure = {
    label = "Ch. Pressure",
    description = "Determine how to treat incoming channel pressure",
    items = {
      "Ignore",
      "Broadcast as MIDI",
    },
    value = 1,
  },
  pitch_bend = {
    label = "Pitch Bend",
    description = "Determine how to treat incoming pitch bend messages",
    items = {
      "Ignore",
      "Broadcast as MIDI",
    },
    value = 1,
  },
  button_width = {
    label = "Grid Button-W",
    on_change = function(app)
      local msg = "This change will be applied the next time Duplex is started"
      renoise.app():show_message(msg)
    end,
    description = "Specify the button width (when in grid mode)",
    items = {
      "1","2","3","4","5","6","7","8"
    },
    value = 1,
  },
  button_height = {
    label = "Grid Button-H",
    on_change = function(app)
      local msg = "This change will be applied the next time Duplex is started"
      renoise.app():show_message(msg)
    end,
    description = "Specify the button height (when in grid mode)",
    items = {
      "1","2","3","4","5","6","7","8"
    },
    value = 1,
  },
  base_octave = {
    label = "Base octave",
    description = "Specify the default starting octave",
    on_change = function(app)
      local val = app.options.base_octave.value
      if (val>1) then
        app:set_octave(val-2,true)
      end
    end,
    items = {
      "Sync with Renoise","0","1","2","3","4","5","6","7","8",
    },
    value = 1,
  }

}

-- populate some options dynamically
for i = 0,127 do
  local str_val = ("Route to CC#%i"):format(i)
  Keyboard.default_options.channel_pressure.items[i+3] = str_val
  Keyboard.default_options.pitch_bend.items[i+3] = str_val
  local str_val = ("Set volume to %i"):format(i)
  Keyboard.default_options.base_volume.items[i+2] = str_val
end
for i = 1,64 do
  local str_val = ("Instrument #%i"):format(i-1)
  Keyboard.default_options.instr_index.items[i+1] = str_val
  local str_val = ("Track #%i"):format(i-1)
  Keyboard.default_options.track_index.items[i+1] = str_val
end

function Keyboard:__init(process,mappings,options,cfg_name,palette)

  self.mappings = {
    keys = {
      description = "Keyboard: trigger notes using keyboard"
    },
    key_grid = {
      description = "Keyboard: trigger notes using buttons or pads"
    },
    pitch_bend = {
      description = "Keyboard: pitch-bend wheel"
    },
    volume = {
      description = "Keyboard: volume control",
      orientation = VERTICAL,
      flipped = false,
      toggleable = true,
    },
    volume_sync = {
      description = "Keyboard: sync volume with Renoise",
    },
    octave_down = {
      description = "Keyboard: transpose keyboard down"
    },
    octave_up = {
      description = "Keyboard: transpose keyboard up"
    },
    octave_set = {
      description = "Keyboard: set active keyboard octave",
      orientation = VERTICAL,
      flipped = false,
      toggleable = true,
    },
    octave_sync = {
      description = "Keyboard: sync octave to Renoise"
    },
  }

  self.palette = {
    key_pressed = {
      color = {0xFF,0xFF,0xFF},
      text="■",
    },
    key_pressed_content = {
      color = {0xFF,0xFF,0xFF},
      text="■",
    },
    key_released = {
      color = {0x00,0x00,0x00},
      text="□",
    },
    key_released_content = {
      color = {0x40,0x40,0x40},
      text="□",
    },
    key_released_selected = {
      color = {0x80,0x80,0x40},
      text="□",
    },
  }

  self.VELOCITY_CLAMP = 1
  self.VELOCITY_CLIP = 2

  self.IGNORE_PRESSURE = 1
  self.BROADCAST_PRESSURE = 2
  -- + CC messages...

  self.IGNORE_PITCHBEND = 2
  self.BROADCAST_PITCHBEND = 2
  -- + CC messages...

  self.TRACK_FOLLOW = 1
  self.INSTR_FOLLOW = 1
  self.OCTAVE_FOLLOW = 1
  self.VOLUME_FOLLOW = 1

  self.KEYBOARD_VELOCITIES = 127
  self.MAX_OCTAVE = 8

  -- reference to process
  -- (access the internal OSC server, modify options in realtime)
  self._process = process

  -- this is set once the application is started
  self.curr_octave = nil
  self.curr_volume = nil

  -- the various UIComponents
  self._grid = table.create()
  self._keymatcher = nil
  self._channel_pressure = nil
  self._pitch_bend = nil
  self._octave_down = nil
  self._octave_up = nil
  self._octave_sync = nil
  self._octave_set = nil
  self._volume = nil
  self._volume_sync = nil

  -- control-map parameters
  self._key_args = nil

  Application.__init(self,process,mappings,options,cfg_name,palette)

  self._instr_observables = table.create()

  self._grid_update_requested = false

end

--------------------------------------------------------------------------------

-- trigger notes using the internal OSC server
-- @param note_on (boolean), whether to send trigger or release
-- @param pitch (number)
-- @param velocity (number)
-- @param grid_index (number), when using individual buttons as triggers
-- @return true when note was succesfully sent

function Keyboard:trigger(note_on,pitch,velocity,grid_index)
  TRACE("Keyboard:trigger()",note_on,pitch,velocity,grid_index)

  local osc_client = self._process.browser._osc_client
  assert(osc_client,"Internal Error. Please report: " ..
    "expected internal OSC client to be present")

  -- reject notes that are outside valid range
  if (pitch>107) or (pitch<-12) then
    print("Cannot trigger note, pitch is outside valid range")
    return false
  end

  pitch = pitch+12 -- fix Renoise octave difference 

  local instr = self:get_instrument_index()-1
  local track = self:get_track_index()-1

  local key_min = nil
  local key_max = nil
  local msg = self.display.device.message_stream.current_message
  if self._key_args and not grid_index then
    key_min = self._key_args.minimum
    key_max = self._key_args.maximum
  else
    key_min = msg.min
    key_max = msg.max
  end

  -- clip/clamp velocity
  if (self.options.velocity.value == self.VELOCITY_CLAMP) then
    velocity = clamp_value(velocity,key_min,key_max)
  elseif note_on and (self.options.velocity.value == self.VELOCITY_CLIP) then
    if (velocity<key_min) or
      (velocity>key_max) 
    then
      return false
    end
  end

  -- scale velocity from device range to keyboard range (0-127)
  velocity = scale_value(velocity,0,key_max,0,127)

  -- apply user-specified volume 
  velocity = math.floor(velocity * (self.curr_volume/self.KEYBOARD_VELOCITIES))

  --print("trigger note_on,instr,track,pitch,velocity",note_on,instr,track,pitch,velocity)
  if not osc_client:_trigger_instrument(note_on,instr,track,pitch,velocity) then
    print("Cannot trigger notes, the internal OSC server was not started")
  end

  return true

end

--------------------------------------------------------------------------------

-- send MIDI message using the internal OSC server

function Keyboard:send_midi(msg)
  TRACE("Keyboard:send_midi(msg)",msg)

  local osc_client = self._process.browser._osc_client
  local val = math.floor(msg[1])+
             (math.floor(msg[2])*256)+
             (math.floor(msg[3])*65536)
  if not osc_client:_trigger_midi(val) then
    print("Cannot send MIDI, the internal OSC server was not started")
  end

end

--------------------------------------------------------------------------------

-- check configuration, build & start the application

function Keyboard:start_app()
  TRACE("Keyboard:start_app()")

  self:obtain_octave()
  self:obtain_volume()
  if not Application.start_app(self) then
    return
  end
  self:set_octave(self.curr_octave)
  self:set_volume(self.curr_volume)
end

--------------------------------------------------------------------------------

-- perform periodic updates

function Keyboard:on_idle()
  --TRACE("Keyboard:on_idle()")

  if self._grid_update_requested then
    self._grid_update_requested = false
    self:visualize_sample_mappings()
  end

end


--------------------------------------------------------------------------------

-- construct the user interface
-- @return boolean, false if condition was not met

function Keyboard:_build_app()
  TRACE("Keyboard:_build_app()")

  local cm = self.display.device.control_map

  if (self.mappings.keys.group_name) then

    -- add keyboard

    local key_group = self.mappings.keys.group_name
    local key_index = self.mappings.keys.index or 1
    self._key_args = cm:get_indexed_element(key_index,key_group)

    -- keymatcher: a single UIKey will match all incoming notes...
    
    local c = UIKey(self.display)
    c.group_name = self.mappings.keys.group_name
    c.match_any_note = true
    c.on_press = function(obj)
      if not self.active then
        return false
      end
      local msg = self.display.device.message_stream.current_message
      local note_on = true
      local velocity = obj.velocity
      local pitch = self:translate_pitch(obj,msg)
      local triggered = self:trigger(note_on,pitch,velocity)
      return (not msg.is_virtual) and triggered or false
    end
    c.on_release = function(obj)
      if not self.active then
        return false
      end
      local msg = self.display.device.message_stream.current_message
      local note_on = false
      local velocity = obj.velocity
      local pitch = self:translate_pitch(obj,msg)
      local triggered = self:trigger(note_on,pitch,velocity)
      return (not msg.is_virtual) and triggered or false
    end
    self:_add_component(c)
    self._keymatcher = c


    -- handle channel pressure

    local c = UIKeyPressure(self.display)
    c.group_name = self.mappings.keys.group_name
    c.ceiling = 127
    c.on_change = function(obj)
      if not self.active then
        return
      end
      local msg = nil
      if (self.options.channel_pressure.value == self.BROADCAST_PRESSURE) then
        msg = {208,obj.value,0}
      elseif (self.options.channel_pressure.value > self.BROADCAST_PRESSURE) then
        local cc_num = self.options.channel_pressure.value-3
        msg = {176,cc_num,obj.value}
      end
      if msg then
        self:send_midi(msg)
      end
    end
    self:_add_component(c)
    self._channel_pressure = c

  end

  if (self.mappings.key_grid.group_name) then

    -- add grid keys (for buttons/pads)

    local map = self.mappings.key_grid
    -- determine width and height of grid
    local grid_w = cm:count_columns(map.group_name)
    local grid_h = cm:count_rows(map.group_name)
    local unit_w = self.options.button_width.value
    local unit_h = self.options.button_height.value

    -- adapt to grid orientation 
    local orientation = self.mappings.key_grid.orientation or HORIZONTAL
    if (orientation == HORIZONTAL) then
      grid_w,grid_h = grid_h,grid_w
    end

    local count = 1
    local skip = nil

    for x = 1,grid_w do
      skip = false
      if (unit_w>1) then
        skip = (x%unit_w)~=1
      end
      if skip then
        count = count + grid_w
      else
        for y = 1,grid_h do
          skip = false
          if (unit_h>1) then
            skip = (y%unit_h)~=1
          end
          if not skip then
            local ctrl_idx = #self._grid+1
            local args = cm:get_indexed_element(ctrl_idx,map.group_name)
            -- determine if we are dealing with fixed-value keys (MIDI),
            -- or OSC (which doesn't need pitch, as it is using the 
            -- assigned row/column value for matching the notes)
            local pitch = nil 
            if (self.display.device.protocol==DEVICE_MIDI_PROTOCOL) then
              pitch = value_to_midi_pitch(args.value)
            end
            local c = UIKey(self.display)
            c.group_name = map.group_name
            c.pitch = pitch
            c.palette.pressed = self.palette.key_pressed
            c.palette.released = self.palette.key_released
            if (orientation == HORIZONTAL) then
              c:set_pos(y,x)
            else
              c:set_pos(x,y)
            end
            c:set_size(unit_w,unit_h)
            c.on_press = function(obj)
              if not self.active then
                return false
              end
              local note_on = true
              local pitch = ctrl_idx+(self.curr_octave*12)-1
              local msg = self.display.device.message_stream.current_message
              local velocity = obj.velocity
              return self:trigger(note_on,pitch,velocity,ctrl_idx)
            end
            c.on_release = function(obj)
              if not self.active then
                return false
              end
              local note_on = false
              local pitch = ctrl_idx+(self.curr_octave*12)-1
              local msg = self.display.device.message_stream.current_message
              local velocity = obj.velocity
              return self:trigger(note_on,pitch,velocity,ctrl_idx)
            end
            self:_add_component(c)
            self._grid:insert(c)
          end
          count = count + 1
        end
      end
    end
  end

  -- add pitch bend

  local mapping = self.mappings.pitch_bend
  if (mapping.group_name) then
    local c = UIPitchBend(self.display)
    local c_args = cm:get_indexed_element(mapping.index,mapping.group_name)
    c.group_name = mapping.group_name
    c.value = (c_args.maximum-c_args.minimum)/2
    c.ceiling = c_args.maximum
    c:set_pos(mapping.index or 1)
    c.on_change = function(obj)
      if not self.active then
        return
      end
      local msg = nil
      if (self.options.pitch_bend.value == self.BROADCAST_PITCHBEND) then
        msg = {224,0,obj.value}
      elseif (self.options.pitch_bend.value > self.BROADCAST_PITCHBEND) then
        local cc_num = self.options.pitch_bend.value-3
        msg = {176,cc_num,obj.value}
      end
      if msg then
        self:send_midi(msg)
      end
    end
    self:_add_component(c)
    self._pitch_bend = c
  end

  -- octave down

  local map = self.mappings.octave_down
  if map.group_name then
    local c = UIToggleButton(self.display)
    c.group_name = map.group_name
    c.tooltip = map.description
    c.palette.background.text = "-12"
    c.palette.foreground.text = "-12"
    c:set_pos(map.index)
    c.on_press = function(obj)
      if not self.active then 
        return false 
      end
      if (self.options.base_octave.value == self.OCTAVE_FOLLOW) then
        renoise.song().transport.octave = math.max(0,renoise.song().transport.octave - 1)
      else
        if (self.curr_octave > 0) then
          self:set_octave(self.curr_octave-1)
        end
      end
      return false -- do not toggle
    end
    self:_add_component(c)
    self._octave_down = c
  end

  -- octave up

  local map = self.mappings.octave_up
  if map.group_name then
    local c = UIToggleButton(self.display)
    c.group_name = map.group_name
    c.tooltip = map.description
    c.palette.background.text = "+12"
    c.palette.foreground.text = "+12"
    c:set_pos(map.index)
    c.on_press = function(obj)
      if not self.active then 
        return false 
      end
      if (self.options.base_octave.value == self.OCTAVE_FOLLOW) then
        renoise.song().transport.octave = math.min(8,renoise.song().transport.octave + 1)
      else
        if ((self.curr_octave+1) <= self.MAX_OCTAVE) then
          self:set_octave(self.curr_octave+1)
        end
      end
      return false -- do not toggle
    end
    self:_add_component(c)
    self._octave_up = c
  end

  -- octave set (supports grid mode)

  local map = self.mappings.octave_set
  if map.group_name then
    -- check for pad/grid style mapping
    local slider_size = 1
    local grid_mode = cm:is_grid_group(map.group_name,map.index)
    if grid_mode then
      if (map.orientation == HORIZONTAL) then
        slider_size = cm:count_columns(map.group_name)
      else
        slider_size = cm:count_rows(map.group_name)
      end
    end
    local c = UISlider(self.display)
    c.group_name = map.group_name
    c:set_pos(map.index)
    c.flipped = map.flipped
    c.toggleable = map.toggleable
    c.ceiling = self.MAX_OCTAVE
    c:set_size(slider_size)
    c:set_orientation(map.orientation)
    c.tooltip = map.description
    c.palette.track = table.rcopy(self.display.palette.background)
    c.value = self.curr_octave
    c.on_change = function(obj)
      if not self.active then 
        return false 
      end
      if (self.options.base_octave.value == self.OCTAVE_FOLLOW) then
        renoise.song().transport.octave = obj.index
      else
        self:set_octave(obj.index)
      end
    end
    self:_add_component(c)
    self._octave_set = c

  end

  -- octave sync

  local map = self.mappings.octave_sync
  if map.group_name then
    local c = UIToggleButton(self.display)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.active = (self.options.base_octave.value == self.OCTAVE_FOLLOW)
    c.on_change = function(obj)
      if not self.active then 
        return false 
      end
      local val = nil
      if (self.options.base_octave.value == self.OCTAVE_FOLLOW) then
        val = renoise.song().transport.octave+2
      else
        val = self.OCTAVE_FOLLOW
        self:set_octave(renoise.song().transport.octave,true)
      end
      self:_set_option("base_octave",val,self._process)
    end
    self:_add_component(c)
    self._octave_sync = c
  end


  -- volume

  local map = self.mappings.volume
  if map.group_name then
    -- check for pad/grid style mapping
    local slider_size = 1
    local grid_mode = cm:is_grid_group(map.group_name,map.index)
    if grid_mode then
      if (map.orientation == HORIZONTAL) then
        slider_size = cm:count_columns(map.group_name)
      else
        slider_size = cm:count_rows(map.group_name)
      end
    end
    local c = UISlider(self.display)
    c.group_name = map.group_name
    c:set_pos(map.index)
    c.flipped = map.flipped
    c.toggleable = map.toggleable
    c:set_orientation(map.orientation)
    c:set_size(slider_size)
    c.ceiling = self.KEYBOARD_VELOCITIES
    c.tooltip = map.description
    c.value = self.curr_volume
    c.on_change = function(obj)
      if not self.active then 
        return false 
      end
      if (self.options.base_volume.value == self.VOLUME_FOLLOW) then
        -- do not allow setting volume if velocity is disabled
        local enabled = renoise.song().transport.keyboard_velocity_enabled
        if not enabled then
          obj:set_value(self.KEYBOARD_VELOCITIES,true)
          return false
        else
          renoise.song().transport.keyboard_velocity = obj.value
        end
      else
        self:set_volume(obj.value)
      end

    end
    self:_add_component(c)
    self._volume = c

  end

  -- volume sync 

  local map = self.mappings.volume_sync
  if map.group_name then
    local c = UIToggleButton(self.display)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.active = (self.options.base_volume.value == self.VOLUME_FOLLOW)
    c.on_change = function(obj)
      if not self.active then 
        return false 
      end
      local val = nil
      if (self.options.base_volume.value == self.VOLUME_FOLLOW) then
        val = renoise.song().transport.keyboard_velocity+1
      else
        val = self.VOLUME_FOLLOW
        self:set_volume(renoise.song().transport.keyboard_velocity,true)
      end
      self:_set_option("base_volume",val,self._process)
    end
    self:_add_component(c)
    self._volume_sync = c
  end

  -- attach to song at first run
  self:_attach_to_song()

  return true

end

--------------------------------------------------------------------------------

-- called when application is first started, sets the current base octave

function Keyboard:obtain_octave()
  TRACE("Keyboard:obtain_octave()")

  if (self.options.base_octave.value == self.OCTAVE_FOLLOW) then
    self.curr_octave = renoise.song().transport.octave
  else
    self.curr_octave = self.options.base_octave.value-2
  end

end

--------------------------------------------------------------------------------

-- called when application is first started, sets the current base volume

function Keyboard:obtain_volume()
  TRACE("Keyboard:obtain_volume()")

  if (self.options.base_volume.value == self.VOLUME_FOLLOW) then
    self.curr_volume = renoise.song().transport.keyboard_velocity
  else
    self.curr_volume = self.options.base_volume.value-1
  end

end

--------------------------------------------------------------------------------

-- translate_pitch() - use this method to determine the correct pitch 
-- @param obj (UIKey)
-- @param msg (Message)
-- @return pitch (Number)

function Keyboard:translate_pitch(obj,msg)
  TRACE("Keyboard:translate_pitch()",obj,msg)
  
  local pitch = nil
  if msg.is_virtual then
    pitch = obj.pitch + (self.curr_octave*12) - 12
  elseif (msg.is_osc_msg) then
    pitch = obj.pitch + obj.transpose - 13 -- OSC message
  else
    pitch = obj.pitch + obj.transpose -- actual MIDI keyboard
  end
  return pitch

end

--------------------------------------------------------------------------------

-- set_octave() - sets the current octave 
-- @param val (Integer), between 0 and 8
-- @param skip_option (Boolean) set this to skip setting option

function Keyboard:set_octave(val,skip_option)
  TRACE("Keyboard:set_octave()",val,skip_option)

  self.curr_octave = val
  if self._keymatcher then
    self._keymatcher.transpose = (self.curr_octave)*12 
  end
  self:update_octave_controls()
  if not skip_option and 
    (self.options.base_octave.value ~= self.OCTAVE_FOLLOW) 
  then
    -- modify the persistent settings
    local oct = self.curr_octave
    self:_set_option("base_octave",oct+2,self._process)
  end

end

--------------------------------------------------------------------------------

-- set_octave() - sets the current volume 
-- @param val (Integer), between 0 and 127
-- @param skip_option (Boolean) set this to skip setting option

function Keyboard:set_volume(val,skip_option)
  TRACE("Keyboard:set_volume()",val,skip_option)

  self.curr_volume = val
  if self._volume then
    local skip_event = true
    self._volume:set_value(self.curr_volume,skip_event)
  end
  if not skip_option and 
    (self.options.base_volume.value ~= self.OCTAVE_FOLLOW) 
  then
    -- modify the persistent settings
    self:_set_option("base_volume",self.curr_volume+2,self._process)
  end

end

--------------------------------------------------------------------------------

-- update_octave_controls() 
-- called when a new document becomes available, or the octave has changed

function Keyboard:update_octave_controls()
  TRACE("Keyboard:update_octave_controls()")

  local skip_event = true
  if self._octave_down then
    --local lit = (renoise.song().transport.octave>0)
    local lit = (self.curr_octave>0)
    self._octave_down:set(lit,skip_event)
  end
  if self._octave_up then
    --local lit = (renoise.song().transport.octave<8)
    local lit = (self.curr_octave<8)
    self._octave_up:set(lit,skip_event)
  end
  if self._octave_set then
    self._octave_set:set_index(self.curr_octave,skip_event)
  end

  self._grid_update_requested = true

end

--------------------------------------------------------------------------------

-- visualize sample mappings in the grid
-- called after switching octave, instrument or track

function Keyboard:visualize_sample_mappings()
  TRACE("Keyboard:visualize_sample_mappings()")

  if (#self._grid>0) then
    local instr_idx = self:get_instrument_index()
    local instr = renoise.song().instruments[instr_idx]
    for idx = 1,#self._grid do
      local ui_obj = self._grid[idx]
      ui_obj.palette.pressed = self.palette.key_pressed
      ui_obj.palette.released = self.palette.key_released
      ui_obj:invalidate()
    end
    for k,s_map in ipairs(instr.sample_mappings[1]) do
      for idx = 1,#self._grid do
        local ui_obj = self._grid[idx]
        local pitch = idx + (self.curr_octave*12)+11
        if (s_map.note_range[1]<=pitch) and
          (s_map.note_range[2]>=pitch) 
        then
          local s_index = renoise.song().selected_sample_index
          ui_obj.palette.pressed = self.palette.key_pressed_content
          if (s_index == s_map.sample_index) then
            ui_obj.palette.released = self.palette.key_released_selected
          else
            ui_obj.palette.released = self.palette.key_released_content
          end
          ui_obj:invalidate()
        end
      end
    end
  end

end

--------------------------------------------------------------------------------

-- obtain the current instrument 
-- this method should ALWAYS be able to produce an instrument
-- (fall back on the currently selected instrument if none was matched)

function Keyboard:get_instrument_index()
  TRACE("Keyboard:get_instrument_index()")

  local instr_index = nil

  if (self.options.instr_index.value == self.INSTR_FOLLOW) then
    instr_index = renoise.song().selected_instrument_index
  else
    instr_index = self.options.instr_index.value - 1
    if not renoise.song().instruments[instr_index] then
      print("Notice from Duplex Keyboard: appointed instrument does not exist")
      instr_index = renoise.song().selected_instrument_index
    end
  end
  
  return instr_index

end

--------------------------------------------------------------------------------

-- obtain the current track
-- this method should ALWAYS be able to produce a valid track index
-- (fall back on the currently selected track if none was matched)

function Keyboard:get_track_index()
  TRACE("Keyboard:get_track_index()")

  local track_index = nil

  if (self.options.track_index.value == self.TRACK_FOLLOW) then
    track_index = renoise.song().selected_track_index
  else
    track_index = self.options.track_index.value - 1
    if not renoise.song().tracks[track_index] then
      print("Notice from Duplex Keyboard: appointed track does not exist")
      track_index = renoise.song().selected_track_index
    end
  end
  
  return track_index

end

--------------------------------------------------------------------------------

-- called whenever a new document becomes available

function Keyboard:on_new_document()
  TRACE("Keyboard:on_new_document()")

  self:_attach_to_song()

end

--------------------------------------------------------------------------------

-- attach notifier to the song, handle changes

function Keyboard:_attach_to_song()
  TRACE("Keyboard:_attach_to_song()")

  renoise.song().transport.octave_observable:add_notifier(
    function()
      if (self.options.base_octave.value == self.OCTAVE_FOLLOW) then
        self:set_octave(renoise.song().transport.octave)
      end
    end
  )

  renoise.song().selected_instrument_observable:add_notifier(
    function()
      if (self.options.instr_index.value == self.INSTR_FOLLOW) then
        self._grid_update_requested = true
        self:attach_to_instrument()
      end
    end
  )

  renoise.song().transport.keyboard_velocity_observable:add_notifier(
    function()
      if (self.options.base_volume.value == self.VOLUME_FOLLOW) then
        self:set_volume(renoise.song().transport.keyboard_velocity)
      end
    end
  )

  renoise.song().transport.keyboard_velocity_enabled_observable:add_notifier(
    function()
      local skip_event = true
      local enabled = renoise.song().transport.keyboard_velocity_enabled

      if (self.options.base_volume.value == self.VOLUME_FOLLOW) then
        if enabled then
          -- when enabled, set to current velocity
          self:set_volume(renoise.song().transport.keyboard_velocity)
        else
          -- when disabled, we set volume to max
          self:set_volume(self.KEYBOARD_VELOCITIES)
        end
      end

    end
  )

  -- immediately attach to instrument 
  self:attach_to_instrument()

end


--------------------------------------------------------------------------------

-- attach notifiers to selected instrument 
-- (watch for swapped keyzones, keyzone note-ranges)

function Keyboard:attach_to_instrument()
  TRACE("Keyboard:attach_to_instrument()")

  local instr_index = self:get_instrument_index()
  local instr = renoise.song().instruments[instr_index]

  -- update when keyzones are removed/added
  self:_remove_notifiers(self._instr_observables)
  self._instr_observables:insert(instr.sample_mappings_observable[1])
  instr.sample_mappings_observable[1]:add_notifier(
    function(notifier)
      -- clear, and re-attach all instrument notifiers
      self:attach_to_instrument()
      self._grid_update_requested = true
    end
  )

  -- update when keyzone note-ranges are modified
  for ___,s_map in ipairs(instr.sample_mappings[1]) do
    self._instr_observables:insert(s_map.note_range_observable) 
    s_map.note_range_observable:add_notifier(
      function(notifier)
        self._grid_update_requested = true
      end
    )
  end

  -- update when selected sample changes
  renoise.song().selected_sample_observable:add_notifier(
    function(notifier)
      self._grid_update_requested = true
    end
  )

end

--------------------------------------------------------------------------------

-- @param observables - list of observables
function Keyboard:_remove_notifiers(observables)
  TRACE("Keyboard:_remove_notifiers()",observables)

  for _,observable in pairs(observables) do
    pcall(function() observable:remove_notifier(self) end)
  end
  observables:clear()

end
