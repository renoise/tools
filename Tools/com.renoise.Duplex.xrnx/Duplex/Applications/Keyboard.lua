--[[============================================================================
-- Duplex.Application.Keyboard
============================================================================]]--

--[[--
A replacement of the standard Renoise keyboard, supporting for MIDI and OSC.
Inheritance: @{Duplex.Application} > Duplex.Application.Keyboard 

### Features

* Integrate with standard MIDI Keyboard or Pad/Grid controller
* Produce keyboard splits and customize the behaviour
* Route specific splits to specific instruments and/or tracks

### In more details

The Keyboard application can be used as a standard keyboard (visulized as black & white keys in the virtual control surface), or as individually-mapped keys/pads, suitable for grid and pad controllers.

When you are using the application in the standard keyboard mode, it might receive pitch bend and channel pressure information from the device, which can then be A) ignored, B) broadcast as MIDI (unchanged), C) or routed internally to any MIDI CC message (this in turn means that you can easily use the native MIDI mapping in Renoise to map the pitch bend to any parameter) 

In grid mode, the Keyboard application is able to visualize the currently selected instrument's keyzone/sample mappings in realtime. This makes it a lot easier to see exactly where each sound is located, and even works as you are moving mappings around, or transposing the keyboard (octave up/down). Also, all of the UISlider mappings (volume, octave, pitch bend, etc.) support grid mode, as their mappings can be mapped to buttons just as easily as they can be mapped to a physical slider or fader. 

Furthermore, since we are using internally-triggered notes we have the ability to trigger notes inside a specific track, using a specific instrument. 
The default setting is identical to the standard behaviour in Renoise, and simply uses the currently selected track/instrument. But it's possible to select any track or instrument using the options "Active track/instr.", choosing any number between 1-64 (a planned feature is to "lock" the track or instrument by assigning a special name to it, something which has not made it into this initial release).

Finally, you can stack multiple Keyboard applications to control/trigger multiple instruments with a single master keyboard. The "MIDI-Keyboard" device comes with a configuration that demonstrate this ("Stacked Keys"), in which three instrument are triggered, each with different velocity settings.


### Prerequisites

  The Keyboard application will not work unless you have enabled the internal OSC server in Renoise (Renoise prefereces -> OSC settings). It should be set to "UPD" protocol, and use the same port as specified in Duplex/Globals.lua (by default, this is set to the same value as Renoise, "8000").


### Discuss

Tool discussion is located on the [Renoise forum][1]
[1]: http://forum.renoise.com/index.php?/topic/33806-new-tool-duplex-keyboard/


### Changes

  0.99
    - Adapted to UIKey changes 
    - New mapping: mod_wheel

  0.98 - First release 


--]]

--==============================================================================

-- constants 

local VELOCITY_CLAMP = 1
local VELOCITY_CLIP = 2

local KEYBOARD_TRIGGER_RANGE = 1
local KEYBOARD_TRIGGER_ALL = 2
local KEYBOARD_TRIGGER_NONE = 3

local IGNORE_PRESSURE = 1
local BROADCAST_PRESSURE = 2

local IGNORE_MODWHEEL = 1
local BROADCAST_MODWHEEL = 2

local IGNORE_PITCHBEND = 2
local BROADCAST_PITCHBEND = 2

local RELEASE_TYPE_WAIT = 1
local TRACK_FOLLOW = 1
local INSTR_FOLLOW = 1
local OCTAVE_FOLLOW = 1
local VOLUME_FOLLOW = 1
local KEYBOARD_VELOCITIES = 127
local MAX_OCTAVE = 8


--==============================================================================

class 'Keyboard' (Application)

Keyboard.default_options = {
  instr_index = {
    label = "Active Instr.",
    description = "Choose which instrument to control",
    on_change = function(app)
      local val = app.options.instr_index.value
      if (val>1) then
        app:set_instr(val-1,true)
      else
        app:set_instr(renoise.song().selected_instrument_index,true)
      end
    end,
    items = {
      "Follow selection"
    },
    value = 1,
  },
  track_index = {
    label = "Active Track",
    description = "Choose which track to use ",
    on_change = function(app)
      local val = app.options.track_index.value
      if (val>1) then
        app:set_track(val-1,true)
      else
        app:set_track(renoise.song().selected_track_index,true)
      end
    end,
    items = {
      "Follow selection"
    },
    value = 1,
  },
  velocity_mode = {
    label = "Velocity Mode",
    description = "Determine how to act on velocity range (the range specified in the control-map)",
    items = {
      "Clamp (restrict to range)",
      "Clip (within range only)",
    },
    value = 1,
  },
  keyboard_mode = {
    label = "Keyboard Mode",
    description = "Determine how notes should be triggered",
    items = {
      "Trigger notes in range (OSC)",
      "Trigger all (range as OSC, others as MIDI)",
      "Trigger nothing (disable)",
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
  mod_wheel = {
    label = "Pitch Bend",
    description = "Determine how to treat incoming mod wheel messages",
    items = {
      "Ignore",
      "Broadcast as MIDI",
    },
    value = 1,
  },
  release_type = {
    label = "Key-release",
    description = "Determine how to respond when the same key is triggered"
                .."\nmultiple times without being released inbetween hits: "
                .."\n'wait' means to wait until all pressed keys are released, "
                .."\n'release when possible' will use the first opportunity to "
                .."\n release the note (enable if you experience stuck notes)",
    items = {
      "Wait for all keys",
      "Release when possible",
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
  },
  upper_note = {
    label = "Upper note",
    description = "Specify a note as upper boundary",
    on_change = function(app)
      local val = app.options.upper_note.value
      app:set_upper_boundary(val-13,true)
    end,
    items = {},
    value = 120,
  },
  lower_note = {
    label = "Lower note",
    description = "Specify a note as lower boundary",
    on_change = function(app)
      local val = app.options.lower_note.value
      app:set_lower_boundary(val-13,true)
    end,
    items = {},
    value = 1,
  },

}

-- populate some options dynamically
for i = 0,127 do
  local str_val = ("Route to CC#%i"):format(i)
  Keyboard.default_options.channel_pressure.items[i+3] = str_val
  Keyboard.default_options.pitch_bend.items[i+3] = str_val
  Keyboard.default_options.mod_wheel.items[i+3] = str_val
  local str_val = ("Set volume to %i"):format(i)
  Keyboard.default_options.base_volume.items[i+2] = str_val
end
for i = 1,64 do
  local str_val = ("Instrument #%i"):format(i-1)
  Keyboard.default_options.instr_index.items[i+1] = str_val
  local str_val = ("Track #%i"):format(i)
  Keyboard.default_options.track_index.items[i+1] = str_val
end
for i = LOWER_NOTE,UPPER_NOTE do
  local str_val = note_pitch_to_value(i+12)
  Keyboard.default_options.upper_note.items[i+13] = str_val
  Keyboard.default_options.lower_note.items[i+13] = str_val
end


Keyboard.available_mappings = {
  keys = {
    description = "Keyboard: trigger notes using keyboard"
  },
  key_grid = {
    description = "Keyboard: trigger notes using buttons or pads",
    distributable = true,
    greedy = true,
  },
  pitch_bend = {
    description = "Keyboard: pitch-bend wheel"
  },
  mod_wheel = {
    description = "Keyboard: mod wheel"
  },
  pressure = {
    description = "Keyboard: channel pressure"
  },
  volume = {
    description = "Keyboard: volume control",
    orientation = ORIENTATION.VERTICAL,
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
    orientation = ORIENTATION.VERTICAL,
    flipped = false,
    toggleable = true,
  },
  octave_sync = {
    description = "Keyboard: sync octave with Renoise"
  },
  track_set = {
    description = "Keyboard: set active keyboard track",
    orientation = ORIENTATION.VERTICAL,
    flipped = false,
    toggleable = true,
  },
  track_sync = {
    description = "Keyboard: sync track with Renoise"
  },
  instr_set = {
    description = "Keyboard: set active keyboard instrument",
    orientation = ORIENTATION.VERTICAL,
    flipped = false,
    toggleable = true,
  },
  instr_sync = {
    description = "Keyboard: sync instrument with Renoise"
  },
}

Keyboard.default_palette = {
  key_pressed           = { color = {0xFF,0xFF,0xFF}, val=true, text="·", },
  key_pressed_content   = { color = {0xFF,0xFF,0xFF}, val=true, text="·", },
  key_released          = { color = {0x00,0x00,0x00}, val=false, text="·", },
  key_released_content  = { color = {0x40,0x40,0x40}, val=false,text="·", },
  key_released_selected = { color = {0x80,0x80,0x40}, val=false,text="·", },
  key_out_of_bounds     = { color = {0x00,0x00,0x00}, val=false,text="·", },
  instr_sync_on         = { color = {0xFF,0xFF,0xFF}, val=true, text="■", },
  instr_sync_off        = { color = {0x00,0x00,0x00}, val=false,text="·", },
  track_sync_on         = { color = {0xFF,0xFF,0xFF}, val=true, text="■", },
  track_sync_off        = { color = {0x00,0x00,0x00}, val=false,text="·", },
  volume_sync_on        = { color = {0xFF,0xFF,0xFF}, val=true, text="■", },
  volume_sync_off       = { color = {0x00,0x00,0x00}, val=false,text="·", },
  octave_down_on        = { color = {0xFF,0xFF,0xFF}, val=true, text="-12", },
  octave_down_off       = { color = {0x00,0x00,0x00}, val=false,text="-12", },
  octave_up_on          = { color = {0xFF,0xFF,0xFF}, val=true, text="+12", },
  octave_up_off         = { color = {0x00,0x00,0x00}, val=false,text="+12", },
  octave_sync_on        = { color = {0xFF,0xFF,0xFF}, val=true, text="■", },
  octave_sync_off       = { color = {0x00,0x00,0x00}, val=false,text="·", },
  slider_on             = { color = {0xFF,0xFF,0xFF}, val=true, text = "▪" },
  slider_off            = { color = {0x00,0x00,0x00}, val=false,text = "·" },

}


--------------------------------------------------------------------------------

--- Constructor method
-- @param (VarArg)
-- @see Duplex.Application

function Keyboard:__init(...)
  TRACE("Keyboard:__init()")

  --- octave
  self.curr_octave = nil 

  --- volume
  self.curr_volume = nil 

  --- track index
  self.curr_track = nil  

  --- instrument index
  self.curr_instr = nil  

  --- lower note
  self.lower_note = nil  

  --- upper note
  self.upper_note = nil  

  --- control-map parameters
  self._key_args = nil

  --- instrument observables
  self._instr_observables = table.create()

  self._grid_update_requested = false
  self._track_update_requested = false

  self.pressed_buttons = table.create()

  --- the various UIComponents
  self._controls = {}
  self._controls.grid = table.create()

  Application.__init(self,...)

end

--------------------------------------------------------------------------------

--- trigger notes using the internal voice manager (OSC server)
-- @param note_on (bool), whether to send trigger or release
-- @param pitch (int) 0-120
-- @param velocity (int) 0-127
-- @param grid_index (int), when using individual buttons as triggers
-- @return true when originating control should update

function Keyboard:trigger(note_on,pitch,velocity,grid_index)
  TRACE("Keyboard:trigger()",note_on,pitch,velocity,grid_index)

  if (self.options.keyboard_mode.value == KEYBOARD_TRIGGER_NONE) then
    LOG("Cannot trigger note, keyboard has been disabled")
    return false
  end

  local voice_mgr = self._process.browser._voice_mgr
  assert(voice_mgr,"Internal Error. Please report: " ..
    "expected OSC voice-manager to be present")

  -- reject notes that are outside valid range
  if note_on and (pitch>UPPER_NOTE) or (pitch<LOWER_NOTE) then
    LOG("Cannot trigger note, pitch is outside valid range")
    return false
  end

  -- notes outside user-defined range are sent as MIDI
  local is_midi = not self:inside_note_range(pitch)

  pitch = pitch+12 -- fix Renoise octave difference 

  local instr,matched_instr = self:get_instrument_index() 
  local track = self:get_track_index()

  -- reject notes if target instr. or track is missing
  if not matched_instr then
    LOG("Cannot trigger note, target instrument is missing")
    return false
  end

  local key_min = nil
  local key_max = nil
  if self._key_args and not grid_index then
    key_min = self._key_args.minimum
    key_max = self._key_args.maximum
  else
    local msg = self.display.device.message_stream.current_msg
    key_min = msg.xarg.minimum
    key_max = msg.xarg.maximum
  end

  if velocity then
    -- clip/clamp velocity
    if (self.options.velocity_mode.value == VELOCITY_CLAMP) then
      velocity = clamp_value(velocity,key_min,key_max)
    elseif note_on and (self.options.velocity_mode.value == VELOCITY_CLIP) then
      if (velocity<key_min) or
        (velocity>key_max) 
      then
        return false
      end
    end
    -- scale velocity from device range to keyboard range (0-127)
    velocity = scale_value(velocity,0,key_max,0,127)
    -- apply user-specified volume 
    velocity = math.floor(velocity * (self.curr_volume/KEYBOARD_VELOCITIES))
  end

  --print("trigger note_on,instr,track,pitch,velocity",note_on,instr,track,pitch,velocity)
  local transp = 0
  local keep = (self.options.release_type.value == RELEASE_TYPE_WAIT)
  --if note_on and not release_only then
  if note_on then
    --print("*** trigger note,is_midi",is_midi)
    local do_trigger = true
    if is_midi and (self.options.keyboard_mode.value ~= KEYBOARD_TRIGGER_ALL) then
      do_trigger = false
    end
    if do_trigger then
      voice_mgr:trigger(self,instr,track,pitch,velocity,keep,is_midi)
    end
  else
    --print("*** release note,is_midi",is_midi)
    transp = voice_mgr:release(self,instr,track,pitch,velocity,is_midi)
  end

  -- update the keyboard's visual representation 
  if self._controls.keyboard then
    self._controls.keyboard:set_key_pressed(pitch,note_on)
  end

  -- detect if we still have active notes playing
  -- (to connect a button's lit state with the voice manager)
  --if not transp then
    if not note_on and keep then
      --rprint(voice_mgr.playing)
      local is_active = voice_mgr:note_is_active(self,instr,pitch)
      --print("Keyboard:trigger() - is_active",is_active)
      if is_active then
        return false
      end
    end
  --end

  return true

end

--------------------------------------------------------------------------------

--- test whether a given pitch is inside the specified note-range
-- @param pitch (int) note pitch

function Keyboard:inside_note_range(pitch)
  TRACE("Keyboard:inside_note_range()",pitch)

  --print("Keyboard:inside_note_range() - self.upper_note",self.upper_note)
  --print("Keyboard:inside_note_range() - self.lower_note",self.lower_note)

  if (pitch>self.upper_note) or (pitch<self.lower_note) then
    return false
  end
  return true
end

--------------------------------------------------------------------------------

--- send MIDI message using the internal OSC server
-- @param msg (table) MIDI message with three bytes

function Keyboard:send_midi(msg)
  TRACE("Keyboard:send_midi(msg)",msg)

  local osc_client = self._process.browser._osc_client
  if not osc_client:trigger_midi(msg) then
    LOG("Cannot send MIDI, the internal OSC server was not started")
  end

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.start_app
-- @return bool or nil

function Keyboard:start_app()
  TRACE("Keyboard:start_app()")

  -- obtain values that (may) have been defined in options,
  -- should happen before constructing the application 
  self:obtain_octave()
  self:obtain_volume()
  self:obtain_track()
  self:obtain_instr()

  if not Application.start_app(self) then
    return
  end

  self:set_octave(self.curr_octave)
  self:set_volume(self.curr_volume)
  self:set_track(self.curr_track)
  self:set_instr(self.curr_instr)

  self.lower_note = self.options.lower_note.value-13
  self.upper_note = self.options.upper_note.value-13
  self:set_boundaries()


end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.stop_app

function Keyboard:stop_app()
  TRACE("Keyboard:stop_app()")

  -- stop any active voices that originate from this app
  local voice_mgr = self._process.browser._voice_mgr
  voice_mgr:remove_app(self)
  self:_remove_notifiers(self._instr_observables)
  Application.stop_app(self)

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_idle

function Keyboard:on_idle()
  --TRACE("Keyboard:on_idle()")

  if not self.active then
    return false
  end

  if self._instr_update_requested then
    self._instr_update_requested = false
    -- clear, and re-attach all instrument notifiers
    self:attach_to_instrument()
  end

  if self._grid_update_requested then
    --print("Keyboard: _grid_update_requested")
    self._grid_update_requested = false
    self:visualize_sample_mappings()
  end

  if self._track_update_requested then
    --print("Keyboard: _track_update_requested")
    self._track_update_requested = false
    self:update_track_controls()
  end


end


--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application._build_app
-- @return bool

function Keyboard:_build_app()
  TRACE("Keyboard:_build_app()")

  local cm = self.display.device.control_map

  -- a virtual keyboard on the screen
  
  if (self.mappings.keys.group_name) then

    local key_group = self.mappings.keys.group_name
    local key_index = self.mappings.keys.index or 1
    local param = cm:get_param_by_index(key_index,key_group)
    self._key_args = param.xarg

    local c = UIKey(self)
    c.group_name = self.mappings.keys.group_name
    c.on_press = function(obj,pitch,velocity)
      local triggered = self:trigger(true,pitch,velocity)
      return triggered
    end
    c.on_release = function(obj,pitch,velocity)
      local released = self:trigger(false,pitch,velocity)
      return released
    end
    self._controls.keyboard = c

  end

  -- add grid keys (for buttons/pads)

  local map = self.mappings.key_grid
  local key_params = cm:get_params(map.group_name,map.index)
  if key_params then

    local unit_w = self.options.button_width.value or 1
    local unit_h = self.options.button_height.value or 1

    local grid_w,grid_h 
    local orientation = map.orientation or ORIENTATION.HORIZONTAL

    -- (only defined for distributed layouts)
    local distributed_group = false
    local group_size,col_count,unit_x,unit_y 

    --print("*** Keyboard.build_app - map.group_name",map.group_name)

    if string.find(map.group_name,"*") then

      distributed_group = true

      -- determine size, columns from first group
      group_size = cm:get_group_size(key_params[1].xarg.group_name)
      col_count = cm:count_columns(key_params[1].xarg.group_name)

      grid_w = #key_params
      grid_h = 1

      if map.index then
        if (orientation == ORIENTATION.HORIZONTAL) then
          unit_x = map.index
          unit_y = 1
        else
          unit_x = 1
          unit_y = map.index
        end

      end

      --print("*** Keyboard.build_app - #key_params",#key_params)

    else

      -- standard grid layout

      grid_w = cm:count_columns(key_params[1].xarg.group_name)
      grid_h = cm:count_rows(key_params[1].xarg.group_name)
      if (orientation == ORIENTATION.HORIZONTAL) then
        grid_w,grid_h = grid_h,grid_w
      end

    end

    --print("*** Keyboard.build_app #B - unit_x,unit_y",unit_x,unit_y)
    --print("*** Keyboard.build_app - grid_w,grid_h",grid_w,grid_h)

    local skip = nil

    for x = 1,grid_w do

      skip = false
      if (unit_w>1) then
        skip = (x%unit_w)~=1
      end
      if not skip then
        for y = 1,grid_h do

          skip = false
          if (unit_h>1) then
            skip = (y%unit_h)~=1
          end

          if not skip then

            local ctrl_idx = #self._controls.grid+1
            local param = key_params[ctrl_idx]
            local c = UIButton(self)
            c:set(self.palette.key_released)
            c.group_name = param.xarg.group_name

            if distributed_group then
              if unit_x then
                -- distr. group with index
                c:set_pos(unit_x,unit_y)
              else
                -- distr. group without index
                -- figure out the position within the current group
                local ctrl_index = ((x-1)%group_size)+1
                local ctrl_col = ((ctrl_index-1)%col_count)+1
                local ctrl_row = math.floor((ctrl_index-1)/col_count)+1
                if (orientation == ORIENTATION.HORIZONTAL) then
                  c:set_pos(ctrl_row,ctrl_col)
                else
                  c:set_pos(ctrl_col,ctrl_row)
                end
              end
            else

              if (orientation == ORIENTATION.HORIZONTAL) then
                c:set_pos(y,x)
              else
                c:set_pos(x,y)
              end
              --print("*** Keyboard - build_app - x,y",x,y)

            end

            c:set_size(unit_w,unit_h)
            c.on_press = function(obj,msg)
              local pitch = ctrl_idx+(self.curr_octave*12)-1
              local velocity = nil
              if msg.midi_msg then
                velocity = msg.midi_msg[3] -- support pressure sensitive pads 
              else
                velocity = scale_value(msg.xarg.maximum,msg.xarg.minimum,msg.xarg.maximum,0,127)
              end
              local triggered = self:trigger(true,pitch,velocity,ctrl_idx)
              --print("*** Keyboard: key_grid triggered",triggered)
              if triggered then
                self.pressed_buttons[ctrl_idx] = true
                self:visualize_sample_mappings()
              end
              return triggered
            end

            c.on_release = function(obj,msg)
              local pitch = ctrl_idx+(self.curr_octave*12)-1
              local released = self:trigger(false,pitch,0,ctrl_idx)
              --print("*** Keyboard: key_grid released",released)
              if released then
                self.pressed_buttons[ctrl_idx] = false
                self:visualize_sample_mappings()
              end
              return released
            end
            self._controls.grid:insert(c)
            --count = count + 1

          end
        end
      end
    end
  end


  -- handle channel pressure

  local map = self.mappings.pressure
  if (map.group_name) then
    local c = UIKeyPressure(self)
    c.group_name = map.group_name
    c.ceiling = 127
    c.value = 0
    c.on_change = function(obj)
      local msg = nil
      if (self.options.channel_pressure.value == BROADCAST_PRESSURE) then
        msg = {208,obj.value,0}
      elseif (self.options.channel_pressure.value > BROADCAST_PRESSURE) then
        local cc_num = self.options.channel_pressure.value-3
        msg = {176,cc_num,obj.value}
      end
      if msg then
        self:send_midi(msg)
      end
    end
    self._controls.ch_pressure = c
  end


  -- add pitch bend

  local map = self.mappings.pitch_bend
  if (map.group_name) then
    local c = UIPitchBend(self,map)
    c.value = 64
    c.ceiling = 127
    c.on_change = function(obj)
      local msg = nil
      --print(obj.value)
      if (self.options.pitch_bend.value == BROADCAST_PITCHBEND) then
        msg = {224,0,obj.value}
      elseif (self.options.pitch_bend.value > BROADCAST_PITCHBEND) then
        local cc_num = self.options.pitch_bend.value-3
        msg = {176,cc_num,obj.value}
      end
      if msg then
        self:send_midi(msg)
      end
    end
    self._controls.pitch_bend = c
  end

  -- add mod wheel

  local map = self.mappings.mod_wheel
  if (map.group_name) then
    local c = UIPitchBend(self,map)
    c.ceiling = 127
    c.on_change = function(obj)
      local msg = nil
      --print(obj.value)
      if (self.options.mod_wheel.value == BROADCAST_MODWHEEL) then
        --msg = {224,0,obj.value} -- TODO
      elseif (self.options.mod_wheel.value > BROADCAST_MODWHEEL) then
        local cc_num = self.options.mod_wheel.value-3
        msg = {176,cc_num,obj.value}
      end
      if msg then
        self:send_midi(msg)
      end
    end
    self._controls.mod_wheel = c
  end

  -- octave down

  local map = self.mappings.octave_down
  if map.group_name then
    local c = UIButton(self,map)
    c:set(self.palette.octave_down_off)
    c.on_press = function(obj)
      if (self.options.base_octave.value == OCTAVE_FOLLOW) then
        renoise.song().transport.octave = math.max(0,renoise.song().transport.octave - 1)
      else
        if (self.curr_octave > 0) then
          self:set_octave(self.curr_octave-1)
        end
      end
    end
    self._controls.oct_down = c
  end

  -- octave up

  local map = self.mappings.octave_up
  if map.group_name then
    local c = UIButton(self,map)
    c:set(self.palette.octave_up_off)
    c.on_press = function(obj)
      if (self.options.base_octave.value == OCTAVE_FOLLOW) then
        renoise.song().transport.octave = math.min(8,renoise.song().transport.octave + 1)
      else
        if ((self.curr_octave+1) <= MAX_OCTAVE) then
          self:set_octave(self.curr_octave+1)
        end
      end
    end
    self._controls.oct_up = c
  end

  -- octave set (slider, supports grid mode)

  local map = self.mappings.octave_set
  if map.group_name then
    -- check for pad/grid style mapping
    local slider_size = 1
    local grid_mode = cm:is_grid_group(map.group_name,map.index)
    if grid_mode then
      if (map.orientation == ORIENTATION.HORIZONTAL) then
        slider_size = cm:count_columns(map.group_name)
      else
        slider_size = cm:count_rows(map.group_name)
      end
    end
    local c = UISlider(self,map)
    c.ceiling = MAX_OCTAVE
    c:set_size(slider_size)
    c:set_palette({
      tip = self.palette.slider_on,
      track = self.palette.slider_off,
    })
    c.value = self.curr_octave
    c.on_change = function(obj)
      if (self.options.base_octave.value == OCTAVE_FOLLOW) then
        renoise.song().transport.octave = obj.index
      else
        self:set_octave(obj.index)
      end
    end
    self._controls.oct_set = c

  end

  -- octave sync

  local map = self.mappings.octave_sync
  if map.group_name then
    local c = UIButton(self,map)
    c:set(self.palette.octave_sync_off)
    c.on_press = function()
      local val = nil
      if (self.options.base_octave.value == OCTAVE_FOLLOW) then
        val = renoise.song().transport.octave+2
      else
        val = OCTAVE_FOLLOW
      end
      self:_set_option("base_octave",val,self._process)
      self:set_octave(renoise.song().transport.octave,true)
    end
    self._controls.oct_sync = c
  end


  -- track set (slider, supports grid mode)

  local map = self.mappings.track_set
  if map.group_name then
    -- check for pad/grid style mapping
    local slider_size = 1
    local grid_mode = cm:is_grid_group(map.group_name,map.index)
    if grid_mode then
      if (map.orientation == ORIENTATION.HORIZONTAL) then
        slider_size = cm:count_columns(map.group_name)
      else
        slider_size = cm:count_rows(map.group_name)
      end
    end
    local c = UISlider(self,map)
    c:set_size(slider_size)
    c:set_palette({
      tip = self.palette.slider_on,
      track = self.palette.slider_off,
    })
    c.value = self.curr_track
    c.on_change = function(obj)
      if (self.options.track_index.value == TRACK_FOLLOW) then
        return false 
      else
        self:set_track(obj.index)
      end
    end
    self._controls.track_set = c

  end

  -- track sync

  local map = self.mappings.track_sync
  if map.group_name then
    local c = UIButton(self,map)
    c:set(self.palette.track_sync_off)
    c.on_press = function()
      local val = nil
      if (self.options.track_index.value == TRACK_FOLLOW) then
        val = renoise.song().selected_track_index+1
      else
        val = TRACK_FOLLOW
        self:set_track(renoise.song().selected_track_index,true)
      end
      self:_set_option("track_index",val,self._process)
    end
    self._controls.track_sync = c
  end


  -- instr set (slider, supports grid mode)

  local map = self.mappings.instr_set
  if map.group_name then
    -- check for pad/grid style mapping
    local slider_size = 1
    local grid_mode = cm:is_grid_group(map.group_name,map.index)
    if grid_mode then
      if (map.orientation == ORIENTATION.HORIZONTAL) then
        slider_size = cm:count_columns(map.group_name)
      else
        slider_size = cm:count_rows(map.group_name)
      end
    end
    local c = UISlider(self,map)
    c:set_size(slider_size)
    c:set_palette({
      tip = self.palette.slider_on,
      track = self.palette.slider_off,
    })
    c.value = self.curr_instr
    c.on_change = function(obj)
      if (self.options.instr_index.value == TRACK_FOLLOW) then
        return false 
      else
        self:set_instr(obj.index)
      end
    end
    self._instr_set = c

  end

  -- instr sync

  local map = self.mappings.instr_sync
  if map.group_name then
    local c = UIButton(self,map)
    c:set(self.palette.instr_sync_off)
    c.on_press = function()
      local val = nil
      if (self.options.instr_index.value == INSTR_FOLLOW) then
        val = renoise.song().selected_instrument_index+2
      else
        val = TRACK_FOLLOW
        self:set_instr(renoise.song().selected_instrument_index,true)
      end
      self:_set_option("instr_index",val,self._process)
    end
    self._instr_sync = c
  end


  -- volume set (slider, supports grid mode)

  local map = self.mappings.volume
  if map.group_name then

    -- check for pad/grid style mapping
    local slider_size = 1
    local grid_mode = cm:is_grid_group(map.group_name,map.index)
    if grid_mode then
      if (map.orientation == ORIENTATION.HORIZONTAL) then
        slider_size = cm:count_columns(map.group_name)
      else
        slider_size = cm:count_rows(map.group_name)
      end
    end
    --print("self._controls.volume - slider_size",slider_size)
    --print("self._controls.volume - map.orientation",map.orientation)

    local c = UISlider(self,map)
    c:set_size(slider_size)
    c:set_palette({
      tip = self.palette.slider_on,
      track = self.palette.slider_off,
    })
    c.value = self.curr_volume
    c.ceiling = KEYBOARD_VELOCITIES
    c.on_change = function(obj)
      if (self.options.base_volume.value == VOLUME_FOLLOW) then
        -- do not allow setting volume if velocity is disabled
        local enabled = renoise.song().transport.keyboard_velocity_enabled
        if not enabled then
          obj:set_value(KEYBOARD_VELOCITIES,true)
          return false
        else
          renoise.song().transport.keyboard_velocity = obj.value
        end
      else
        self:set_volume(obj.value)
      end

    end
    self._controls.volume = c

  end

  -- volume sync 

  local map = self.mappings.volume_sync
  if map.group_name then
    local c = UIButton(self,map)
    c:set(self.palette.volume_sync_off)
    c.on_press = function()
      local val = nil
      if (self.options.base_volume.value == VOLUME_FOLLOW) then
        val = renoise.song().transport.keyboard_velocity
      else
        val = VOLUME_FOLLOW
        self:set_volume(renoise.song().transport.keyboard_velocity,true)
      end
      self:_set_option("base_volume",val,self._process)
    end
    self._controls.volume_sync = c
  end

  -- attach to song at first run
  self:_attach_to_song()

  return true

end

--------------------------------------------------------------------------------

--- called when application is first started

function Keyboard:obtain_octave()
  TRACE("Keyboard:obtain_octave()")

  if (self.options.base_octave.value == OCTAVE_FOLLOW) then
    self.curr_octave = renoise.song().transport.octave
  else
    self.curr_octave = self.options.base_octave.value-2
  end

end

--- called when application is first started

function Keyboard:obtain_track()
  TRACE("Keyboard:obtain_track()")

  if (self.options.track_index.value == TRACK_FOLLOW) then
    self.curr_track = renoise.song().selected_track_index
  else
    self.curr_track = self.options.track_index.value-2
  end

end

--- called when application is first started

function Keyboard:obtain_instr()
  TRACE("Keyboard:obtain_instr()")

  if (self.options.instr_index.value == INSTR_FOLLOW) then
    self.curr_instr = renoise.song().selected_instrument_index
  else
    self.curr_instr = self.options.instr_index.value-2
  end

end

--- called when application is first started

function Keyboard:obtain_volume()
  TRACE("Keyboard:obtain_volume()")

  if (self.options.base_volume.value == VOLUME_FOLLOW) then
    self.curr_volume = renoise.song().transport.keyboard_velocity
  else
    self.curr_volume = self.options.base_volume.value-1
  end

end

--------------------------------------------------------------------------------

--- set_octave() - sets the current octave 
-- @param val (int), between 0 and 8
-- @param skip_option (bool) set this to skip setting option

function Keyboard:set_octave(val,skip_option)
  TRACE("Keyboard:set_octave()",val,skip_option)

  if (not self.active) then
    return
  end

  -- voice manager needs to know the difference
  local voice_mgr = self._process.browser._voice_mgr
  if voice_mgr then
    local semitones = (self.curr_octave-val)*12
    voice_mgr:transpose(self,semitones)
  end

  self.curr_octave = val
  
  if self._controls.keyboard then
    self._controls.keyboard:set_octave(self.curr_octave)
  end

  self:update_octave_controls()
  if not skip_option and 
    (self.options.base_octave.value ~= OCTAVE_FOLLOW) 
  then
    self:_set_option("base_octave",self.curr_octave+2,self._process)
  end

end

--------------------------------------------------------------------------------

--- switch to the selected track, optionally update options
-- @param val (int), track index
-- @param skip_option (bool) set this to skip setting option

function Keyboard:set_track(val,skip_option)
  TRACE("Keyboard:set_track()",val,skip_option)

  if (not self.active) then
    return
  end

  self.curr_track = val
  self:update_track_controls()
  if not skip_option and 
    (self.options.track_index.value ~= TRACK_FOLLOW) 
  then
    self:_set_option("track_index",self.curr_track+2,self._process)
  end

end

--------------------------------------------------------------------------------

--- switch to the selected instrument, optionally update options
-- @param val (int), track index
-- @param skip_option (bool) set this to skip setting option

function Keyboard:set_instr(val,skip_option)
  TRACE("Keyboard:set_instr()",val,skip_option)

  if (not self.active) then
    return
  end

  self.curr_instr = val
  self:update_instr_controls()
  if not skip_option and 
    (self.options.instr_index.value ~= INSTR_FOLLOW) 
  then
    self:_set_option("instr_index",self.curr_instr+2,self._process)
  end

end

--------------------------------------------------------------------------------

--- set the upper note on the keyboard
-- @param pitch (int) note pitch

function Keyboard:set_upper_boundary(pitch)
  TRACE("Keyboard:set_upper_boundary()",pitch)

  self.upper_note = pitch
  self:set_boundaries()

end

--------------------------------------------------------------------------------

--- set the lower note on the keyboard
-- @param pitch (int) note pitch

function Keyboard:set_lower_boundary(pitch)
  TRACE("Keyboard:set_lower_boundary()",pitch)

  self.lower_note = pitch
  self:set_boundaries()

end

--------------------------------------------------------------------------------

--- update the upper/lower boundaries of the virtual keyboard

function Keyboard:set_boundaries()
  TRACE("Keyboard:set_boundaries()")

  -- update keyboard
  if self._controls.keyboard then
    for i=LOWER_NOTE, UPPER_NOTE do
      local disabled = false
      if (i > self.upper_note) or (i < self.lower_note) then
        disabled = true
      end
      self._controls.keyboard:set_key_disabled(i,disabled)
    end
  end

  -- update grid
 self:visualize_sample_mappings()

end

--------------------------------------------------------------------------------

--- set_octave() - sets the current volume 
-- @param val (int), between 0 and 127
-- @param skip_option (bool) set this to skip setting option

function Keyboard:set_volume(val,skip_option)
  TRACE("Keyboard:set_volume()",val,skip_option)

  if (not self.active) then
    return
  end

  self.curr_volume = val
  if self._controls.volume then
    local skip_event = true
    self._controls.volume:set_value(self.curr_volume,skip_event)
  end
  if not skip_option and 
    (self.options.base_volume.value ~= OCTAVE_FOLLOW) 
  then
    -- modify the persistent settings
    self:_set_option("base_volume",self.curr_volume+1,self._process)
  end
  self:update_volume_controls()

end

--------------------------------------------------------------------------------

--- update display of octave controls

function Keyboard:update_octave_controls()
  TRACE("Keyboard:update_octave_controls()")

  if (not self.active) then
    return
  end

  if self._controls.oct_down then
    --local lit = (renoise.song().transport.octave>0)
    local lit = (self.curr_octave>0)
    if lit then
      self._controls.oct_down:set(self.palette.octave_down_on)
    else
      self._controls.oct_down:set(self.palette.octave_down_off)
    end
  end
  if self._controls.oct_up then
    local lit = (self.curr_octave<8)
    if lit then
      self._controls.oct_up:set(self.palette.octave_up_on)
    else
      self._controls.oct_up:set(self.palette.octave_up_off)
    end
  end
  if self._controls.oct_set then
    local skip_event = true
    self._controls.oct_set:set_index(self.curr_octave,skip_event)
  end
  if self._controls.oct_sync then
    local synced = (self.options.base_octave.value == OCTAVE_FOLLOW)
    if synced then
      self._controls.oct_sync:set(self.palette.octave_sync_on)
    else
      self._controls.oct_sync:set(self.palette.octave_sync_off)
    end
  end

  self._grid_update_requested = true

end

--------------------------------------------------------------------------------

--- update display of track controls

function Keyboard:update_track_controls()
  TRACE("Keyboard:update_track_controls()")

  if (not self.active) then
    return
  end

  if self._controls.track_set then
    local skip_event = true
    self._controls.track_set:set_index(self.curr_track-1,skip_event)
  end
  if self._controls.track_sync then
    local synced = (self.options.track_index.value == TRACK_FOLLOW)
    if synced then
      self._controls.track_sync:set(self.palette.track_sync_on)
    else
      self._controls.track_sync:set(self.palette.track_sync_off)
    end
  end

end

--------------------------------------------------------------------------------

--- update display of instrument controls

function Keyboard:update_instr_controls()
  TRACE("Keyboard:update_instr_controls()")

  if (not self.active) then
    return
  end

  if self._instr_set then
    local skip_event = true
    self._instr_set:set_index(self.curr_instr-1,skip_event)
  end
  if self._instr_sync then
    local synced = (self.options.instr_index.value == INSTR_FOLLOW)
    if synced then
      self._instr_sync:set(self.palette.instr_sync_on)
    else
      self._instr_sync:set(self.palette.instr_sync_off)
    end
  end

end

--------------------------------------------------------------------------------

--- update display of volume controls

function Keyboard:update_volume_controls()
  TRACE("Keyboard:update_volume_controls()")

  if (not self.active) then
    return
  end

  if self._controls.volume_sync then
    local synced = (self.options.base_volume.value == VOLUME_FOLLOW)
    if synced then
      self._controls.volume_sync:set(self.palette.volume_sync_on)
    else
      self._controls.volume_sync:set(self.palette.volume_sync_off)
    end
  end

end

--------------------------------------------------------------------------------

--- visualize sample mappings in the grid
-- called after switching octave, instrument

function Keyboard:visualize_sample_mappings()
  TRACE("Keyboard:visualize_sample_mappings()")

  if (not self.active) then
    return
  end

  --rprint(self.pressed_buttons)

  if (#self._controls.grid>0) then
    local instr_idx = self:get_instrument_index()
    local instr = renoise.song().instruments[instr_idx]
    --[[
    ]]
    for idx = 1,#self._controls.grid do
      local palette = nil
      local ui_obj = self._controls.grid[idx]
      local pitch = idx + (self.curr_octave*12)+11
      local inside_range = self:inside_note_range(pitch-12)
      if inside_range then
        if self.pressed_buttons[idx] then
          palette = self.palette.key_pressed
          --print("key_pressed",palette.color[1],palette.color[2],palette.color[3])
        else
          palette = self.palette.key_released
        end
      else
        palette = self.palette.key_out_of_bounds
      end
      ui_obj:set(palette)
    end
    for s_index,s_map in ipairs(instr.sample_mappings[1]) do
      --print("s_map",s_map)
      --rprint(s_map)
      --oprint(s_map)
      for idx = 1,#self._controls.grid do

        local pitch = idx + (self.curr_octave*12)+11
        if (s_map.note_range[1]<=pitch) and
          (s_map.note_range[2]>=pitch) 
        then
          local inside_range = self:inside_note_range(pitch-12)
          if inside_range then
            local palette = nil
            local ui_obj = self._controls.grid[idx]
            local sample_index = renoise.song().selected_sample_index
            if self.pressed_buttons[idx] then
              palette = self.palette.key_pressed_content
            elseif (sample_index == s_index) then
              palette = self.palette.key_released_selected
            else
              palette = self.palette.key_released_content
            end
            ui_obj:set(palette)
          end
        end
      end
    end
  end

end

--------------------------------------------------------------------------------

--- obtain the current instrument 
-- this method should ALWAYS be able to produce an instrument
-- (fall back on the currently selected instrument if none was matched)

function Keyboard:get_instrument_index()
  TRACE("Keyboard:get_instrument_index()")

  local instr_index = nil
  local matched = true

  if (self.options.instr_index.value == INSTR_FOLLOW) then
    instr_index = renoise.song().selected_instrument_index
  else
    instr_index = self.options.instr_index.value - 1
    if not renoise.song().instruments[instr_index] then
      LOG("Notice from Duplex Keyboard: appointed instrument does not exist")
      instr_index = renoise.song().selected_instrument_index
      matched = false
    end
  end
  
  return instr_index,matched

end

--------------------------------------------------------------------------------

--- obtain the current track
-- this method should ALWAYS be able to produce a valid track index
-- (fall back on the currently selected track if none was matched)

function Keyboard:get_track_index()
  TRACE("Keyboard:get_track_index()")

  local track_index = nil

  if (self.options.track_index.value == TRACK_FOLLOW) then
    track_index = renoise.song().selected_track_index
  else
    track_index = self.options.track_index.value - 1
    if not renoise.song().tracks[track_index] then
      LOG("Notice from Duplex Keyboard: appointed track does not exist")
      track_index = renoise.song().selected_track_index
    end
  end
  
  return track_index

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_new_document

function Keyboard:on_new_document()
  TRACE("Keyboard:on_new_document()")

  self:_attach_to_song()

end

--------------------------------------------------------------------------------

--- attach notifier to the song, handle changes

function Keyboard:_attach_to_song()
  TRACE("Keyboard:_attach_to_song()")

  renoise.song().transport.octave_observable:add_notifier(
    function()
      --print("octave_observable fired...")
      if (self.options.base_octave.value == OCTAVE_FOLLOW) then
        self:set_octave(renoise.song().transport.octave)
      end
    end
  )

  renoise.song().selected_instrument_observable:add_notifier(
    function()
      if (self.options.instr_index.value == INSTR_FOLLOW) then
        self._grid_update_requested = true
        self:attach_to_instrument()
        self:set_instr(renoise.song().selected_instrument_index)
      end
    end
  )

  renoise.song().selected_track_observable:add_notifier(
    function()
      if (self.options.track_index.value == TRACK_FOLLOW) then
        self:set_track(renoise.song().selected_track_index)
      end
    end
  )

  renoise.song().transport.keyboard_velocity_observable:add_notifier(
    function()
      if (self.options.base_volume.value == VOLUME_FOLLOW) then
        self:set_volume(renoise.song().transport.keyboard_velocity)
      end
    end
  )

  renoise.song().transport.keyboard_velocity_enabled_observable:add_notifier(
    function()
      local enabled = renoise.song().transport.keyboard_velocity_enabled

      if (self.options.base_volume.value == VOLUME_FOLLOW) then
        if enabled then
          self:set_volume(renoise.song().transport.keyboard_velocity)
        else
          self:set_volume(KEYBOARD_VELOCITIES)
        end
      end

    end
  )

  -- immediately attach to instrument 
  self:attach_to_instrument()

end


--------------------------------------------------------------------------------

--- attach notifiers to selected instrument 
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
      --print("sample_mappings_observable fired...")
      self._instr_update_requested = true
      self._grid_update_requested = true
    end
  )

  -- update when keyzone note-ranges are modified
  for ___,s_map in ipairs(instr.sample_mappings[1]) do
    self._instr_observables:insert(s_map.note_range_observable) 
    s_map.note_range_observable:add_notifier(
      function(notifier)
        --print("note_range_observable fired...")
        self._grid_update_requested = true
      end
    )
  end

  -- update when selected sample changes
  renoise.song().selected_sample_observable:add_notifier(
    function(notifier)
      --print("selected_sample_observable fired...")
      self._grid_update_requested = true
    end
  )

end

--------------------------------------------------------------------------------

--- brute force method for removing observables
-- @param observables - list of observables

function Keyboard:_remove_notifiers(observables)
  TRACE("Keyboard:_remove_notifiers()",observables)

  for _,observable in pairs(observables) do
    pcall(function() observable:remove_notifier(self) end)
  end
  observables:clear()

end
