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

  0.99.4
    - Support for Renoise 3 trigger options (hold/mono modes)
    - Custom grid layouts (harmonic, isomorphic layout and piano emulation)

  0.99.2
    - Adapted to UIKey changes 
    - New mapping: mod_wheel

  0.98.32
    - TWEAK: velocity now is set to an explicit value, or synced to Renoise keyboard 
      velocity will output a fixed velocity (previously it was relative to messages)

  0.98.16
    - Display message on how to enable OSC server (first time only)

  0.98.15
    - New option: “Keyboard Mode”, choose which notes (if any) to trigger

  0.98 
    - First release 

--]]

--==============================================================================

-- include the supporting classes
require("Duplex/Applications/Keyboard/GridLayout")

local layout_class_names = table.create()
for _, filename in pairs(os.filenames("./Duplex/Applications/Keyboard/Layouts", "*.lua")) do
  local layout_name = split_filename(filename)
  require("Duplex/Applications/Keyboard/Layouts/" .. layout_name)
  layout_class_names:insert(layout_name)
end


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
    label = "Target Instr.",
    description = "Choose which instrument to control",
    on_change = function(app)

      local rns = renoise.song()
      local val = app.options.instr_index.value
      if (val>1) then
        app:set_instr(val-1,true)
      else
        app:set_instr(rns.selected_instrument_index,true)
      end
    end,
    items = {
      "Follow selection"
    },
    value = 1,
  },
  track_index = {
    label = "Target Track",
    description = "Choose which track to use ",
    on_change = function(app)
    	local rns = renoise.song()
      local val = app.options.track_index.value
      if (val>1) then
        app:set_track(val-1,true)
      else
        app:set_track(rns.selected_track_index,true)
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
    label = "Volume",
    description = "Determine how to control keyboard volume",
    on_change = function(app)
    	local rns = renoise.song()
      local val = app.options.base_volume.value
      if (val>1) then
        app:set_volume(val-2,true)
      else
        app:set_volume(rns.transport.keyboard_velocity,true)
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
      "Broadcast as Pitch bend",
    },
    value = 1,
  },
  mod_wheel = {
    label = "Mod Wheel",
    description = "Determine how to treat incoming mod wheel messages",
    items = {
      "Ignore",
      "Broadcast as Mod Wheel (CC#1)",
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
    label = "Octave",
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
  grid_layout = {
    label = "Grid Layout",
    description = "Specify a keyboard layout for the grid",
    on_change = function(app)
      local val = app.options.grid_layout.value
      app:set_grid_layout(val)
    end,
    custom_dialog = function(app)

    end,
    items = layout_class_names,
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
    orientation = ORIENTATION.HORIZONTAL,
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
  cycle_layout = {
    description = "Keyboard: cycle between available layouts"
  },
  all_notes_off = {
    description = "Keyboard: stop all playing notes"
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
  slider_on             = { color = {0xFF,0xC0,0xFF}, val=true, text = "▪" },
  slider_off            = { color = {0xC0,0x80,0x80}, val=false,text = "·" },
  cycle_layout_1        = { text = "⋮"},
  cycle_layout_2        = { text = "⋰"},
  cycle_layout_3        = { text = "⋯"},
  cycle_layout_on       = { color = {0xFF,0xFF,0xFF}, val=true},
  cycle_layout_off      = { color = {0x00,0x00,0x00}, val=false},
  all_notes_on          = { color = {0xFF,0xFF,0xFF}, val=true, text = "⚡" },
  all_notes_off         = { color = {0x00,0x00,0x00}, val=false,text = "⚡" },


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
  
  --- instrument scale
  self.scale_mode = nil

  --- instrument scale
  self.scale_key = nil

  --- lower note
  self.lower_note = nil  

  --- upper note
  self.upper_note = nil  

  --- grid width
  self.grid_w = nil
  
  --- grid height
  self.grid_h = nil

  --- voice manager
  self.voice_mgr = nil

  --- control-map parameters
  self._key_args = nil

  -- class to handle grid layout 
  self._layout = nil

  --- instrument observables
  self._instr_observables = table.create()

  self._update_grid_requested = false
  self._track_update_requested = false

  --- table of currently playing, hold-mode triggered notes
  self.held_notes = table.create()

  --- table of pressed buttons
  self.pressed_buttons = table.create()

  --- the various UIComponents
  self._controls = {}
  self._controls.grid = table.create()

  Application.__init(self,...)

end

--------------------------------------------------------------------------------

--- Trigger notes using the internal voice manager (OSC server)
-- @param note_on (bool), whether to send note-on/off
-- @param instr_idx (int)
-- @param pitch (int) 0-120
-- @param velocity (int) 0-127
-- @param grid_index (bool), when triggered from grid (optional)
-- @return true when note was triggered 
-- @return instr_idx the target instrument

function Keyboard:trigger(note_on,instr_idx,pitch,velocity,grid_index)
  TRACE("Keyboard:trigger()",note_on,instr_idx,pitch,velocity,grid_index)

	--local rns = renoise.song()

  if (self.options.keyboard_mode.value == KEYBOARD_TRIGGER_NONE) then
    LOG("Cannot trigger note, keyboard has been disabled")
    return false
  end

  --local voice_mgr = self._process.browser._voice_mgr
  --assert(voice_mgr,"Internal Error. Please report: " ..
  --  "expected OSC voice-manager to be present")

  -- reject notes that are outside valid range
  if note_on and (pitch>UPPER_NOTE) or (pitch<LOWER_NOTE) then
    LOG("Cannot trigger note, pitch is outside valid range")
    return false
  end

  -- notes outside user-defined range are sent as MIDI
  local is_midi = not self:inside_note_range(pitch)

  pitch = pitch+12 -- fix Renoise octave difference 

  local track = self:get_track_index()

  -- reject notes if target instr. or track is missing
  --[[
  local instr_idx,matched_instr = self:get_instrument_index() 
  if not matched_instr then
    LOG("Cannot trigger note, target instrument is missing")
    return false
  end
  ]]
  

  -- clip/clamp velocity
  if velocity then
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
    if (self.options.velocity_mode.value == VELOCITY_CLAMP) then
      velocity = clamp_value(velocity,key_min,key_max)
    elseif note_on and (self.options.velocity_mode.value == VELOCITY_CLIP) then
      if (velocity<key_min) or
        (velocity>key_max) 
      then
        return false
      end
    end
    -- scale velocity from device range to keyboard range (0-127),
    -- and apply user-specified volume 
    velocity = scale_value(velocity,0,key_max,0,127)
    velocity = math.floor(velocity * (self.curr_volume/KEYBOARD_VELOCITIES))
  end

  local voice_count = #self.voice_mgr.playing

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
      self.voice_mgr:trigger(self,instr_idx,track,pitch,velocity,keep,is_midi)
    end
  else
    --print("*** release note,is_midi",is_midi)
    transp = self.voice_mgr:release(self,instr_idx,track,pitch,velocity,is_midi)
  end

  self:_maintain_held_notes(voice_count,instr_idx,grid_index,velocity)

  -- update the keyboard's visual representation 
  if self._controls.keyboard then
    self._controls.keyboard:set_key_pressed(pitch,note_on)
  end

  -- return false if the note is already playing
  if not transp then
    if not note_on and keep then
      --rprint(voice_mgr.playing)
      local is_active = self.voice_mgr:note_is_active(instr_idx,pitch)
      --print("Keyboard:trigger() - is_active",is_active)
      if is_active then
        return false
      end
    end
  end

  return true,instr_idx

end

--------------------------------------------------------------------------------

--- stop all playing voices

function Keyboard:all_notes_off()

  self.voice_mgr:remove_all_voices()

end


--------------------------------------------------------------------------------

--- Test whether a given pitch is inside the specified note-range
-- @param pitch (int) note pitch

function Keyboard:inside_note_range(pitch)
  --TRACE("Keyboard:inside_note_range()",pitch)

  --print("Keyboard:inside_note_range() - self.upper_note",self.upper_note)
  --print("Keyboard:inside_note_range() - self.lower_note",self.lower_note)

  if (pitch>self.upper_note) or (pitch<self.lower_note) then
    return false
  end
  return true
end

--------------------------------------------------------------------------------

--- Retrieve the number of semitones for the note in the current scale
-- @param idx (int)

function Keyboard:get_nth_note(idx)
  --print("Keyboard:get_nth_note()",idx)

  local scale = HARMONIC_SCALES[self.scale_mode]
  local oct = 0
  if (idx > scale.count) then
    oct = math.floor(idx/scale.count)
    --print("get_nth_note - oct",oct)
    idx = idx%scale.count
    if (idx == 0) then
      idx = scale.count
      oct = oct-1
    end
    --print("get_nth_note - idx",idx)
  end

  local count = 0
  for k,v in ipairs(scale.keys) do
    if (v == 1) then
      count = count+1
    end
    if (count == idx) then
      --print("get nth note",idx,(k + (oct*12)))
      return k + (oct*12)
    end
  end

end

--------------------------------------------------------------------------------

--- Restrict pitches to the ones allowed by the scale
-- (for example, when playing E in natural minor it becomes D#)

function Keyboard:restrict_pitch_to_scale(pitch)
  TRACE("Keyboard:restrict_pitch_to_scale()",pitch)

  if (self.scale_mode ~= "None") then

    local scale = HARMONIC_SCALES[self.scale_mode]
    assert(scale,"Internal Error. Please report: " ..
      "unexpected instrument scale")
    
    local subtract = 0
    local has_representation = 0
    local nth_key = (pitch%12)+1 
    while (has_representation == 0) do
      local check = (nth_key - self.scale_key - subtract) %12 +1
      has_representation = scale.keys[check]
      subtract = subtract+1
    end   
    pitch = pitch-subtract+1

  end

  return pitch

end

--------------------------------------------------------------------------------

--- Call this function immediately after triggering or releasing notes
-- it will keep a record of notes triggered with the "hold" option
-- @param voice_count (int) the number of voices prior to the trigger/release 
-- @param instr_idx (int)
-- @param grid_index (int, optional) remove only notes triggered by this button
-- @param velocity (int)

function Keyboard:_maintain_held_notes(voice_count,instr_idx,grid_index,velocity)
  TRACE("Keyboard:_maintain_held_notes()",voice_count,instr_idx,grid_index,velocity)

  local rns = renoise.song()

  -- if hold mode, compare number of voices
  local hold_mode = (renoise.API_VERSION < 5) and
    rns.instruments[instr_idx].trigger_options.hold or false

  if hold_mode then 
    local voice_diff = #self.voice_mgr.playing - voice_count
    --print("*** Keyboard:trigger - held notes PRE",rprint(self.held_notes))
    --print("*** Keyboard:trigger - voice_diff",voice_diff)
    --print("*** Keyboard:trigger - voice_count",voice_count)
    --print("*** Keyboard:trigger - #self.voice_mgr.playing",#self.voice_mgr.playing)
    if voice_diff > 0 then
      -- adding new held notes
      for k = 1,voice_diff do
        self.held_notes:insert({
          grid_index = grid_index,
          velocity = velocity,
          instr_idx = instr_idx
        })
      end
    elseif voice_diff < 0 then
      -- removing held notes
      for k,v in ripairs(self.held_notes) do
        if grid_index then
          -- remove note triggered by a specific button
          if (v.grid_index == grid_index) then
            self.held_notes:remove(k)
          end
        else
          -- remove any note
          self.held_notes:remove(k)
        end
      end 
    end
    --print("*** Keyboard:trigger - held notes POST",rprint(self.held_notes))
    
  end

end

--------------------------------------------------------------------------------

--- Invoked by our voice manager

function Keyboard:voicemgr_callback() 
  TRACE("Keyboard:voicemgr_callback()")

  self._update_grid_requested = true

end

--------------------------------------------------------------------------------

--- Rebuild & retrigger (held) notes when changing the scale ...

function Keyboard:on_scale_change() 
  TRACE("Keyboard:on_scale_change()")

  local held_notes = table.rcopy(self.held_notes)

  if (self.scale_mode == 0) then
    self.scale_key = 1
  end

  -- remove from this instrument only
  local instr_idx = self:get_instrument_index()
  local voice_count = #self.voice_mgr.playing

  self.voice_mgr:remove_voices(self,instr_idx)

  self:_maintain_held_notes(voice_count,instr_idx)

  -- rebuild layout
  self:cache_grid()

  -- retrigger notes
  for k,v in ipairs(held_notes) do
    local grid_notes = self._layout:get_pitches_from_index(v.grid_index)
    --print("grid_notes",rprint(grid_notes))
    for k2,v2 in ipairs(grid_notes) do
      self:trigger(true,instr_idx,v2,v.velocity,v.grid_index)
    end
  end

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

	local rns = renoise.song()

  self.voice_mgr = self._process.browser._voice_mgr
  assert(self.voice_mgr,"Internal Error. Please report: " ..
    "expected OSC voice-manager to be present")

  -- register to receive voice notifications 
  -- (events triggered by other applications)
  self.voice_mgr:register_callback(self,self.voicemgr_callback)

  -- obtain values that (may) have been defined in options,
  -- should happen before constructing the application 
  self:obtain_octave()
  self:obtain_volume()
  self:obtain_track()
  self:obtain_instr()

  if not Application.start_app(self) then
    return
  end

  self.lower_note = self.options.lower_note.value-13
  self.upper_note = self.options.upper_note.value-13

  self:set_octave(self.curr_octave)
  self:set_volume(self.curr_volume)
  self:set_track(self.curr_track)
  self:set_instr(self.curr_instr)

  self:set_boundaries()
  self:update_cycle_controls()


end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.stop_app

function Keyboard:stop_app()
  TRACE("Keyboard:stop_app()")
  
  if self.voice_mgr then
    -- stop any active voices that originate from this app
    -- TODO add unregister function 
    self.voice_mgr:remove_voices(self)
  end

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

  if self._update_grid_requested then
    --print("Keyboard: _update_grid_requested")
    self._update_grid_requested = false
    self:update_grid()
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
      local instr_idx = self:get_instrument_index() 
      local triggered = self:trigger(true,instr_idx,pitch,velocity)
      return triggered
    end
    c.on_release = function(obj,pitch,velocity)
      local instr_idx = self:get_instrument_index() 
      local released = self:trigger(false,instr_idx,pitch,velocity)
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

    local orientation = map.orientation

    -- (only defined for distributed layouts)
    local distributed_group = false
    local group_size,col_count,unit_x,unit_y 

    --print("*** Keyboard.build_app - map.group_name",map.group_name)

    if string.find(map.group_name,"*") then

      distributed_group = true

      -- determine size, columns from first group
      group_size = cm:get_group_size(key_params[1].xarg.group_name)
      col_count = cm:count_columns(key_params[1].xarg.group_name)

      self.grid_w = #key_params
      self.grid_h = 1

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

      self.grid_w = cm:count_columns(key_params[1].xarg.group_name)
      self.grid_h = cm:count_rows(key_params[1].xarg.group_name)
      if (orientation == ORIENTATION.HORIZONTAL) then
        self.grid_w,self.grid_h = self.grid_h,self.grid_w
      end

    end

    --print("*** Keyboard.build_app #B - unit_x,unit_y",unit_x,unit_y)
    --print("*** Keyboard.build_app - grid_w,self.grid_h",grid_w,self.grid_h)

    local skip = nil

    for x = 1,self.grid_w do

      skip = false
      if (unit_w>1) then
        skip = (x%unit_w)~=1
      end
      if not skip then
        for y = 1,self.grid_h do

          skip = false
          if (unit_h>1) then
            skip = (y%unit_h)~=1
          end

          if not skip then

            local ctrl_idx = #self._controls.grid+1
            local param = key_params[ctrl_idx]
            local c = UIButton(self)
            --c:set(self.palette.key_released)
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
            c.on_press = function(obj)

            	local rns = renoise.song()
              local msg = self.display.device.message_stream.current_msg
              --local pitch = ctrl_idx+(self.curr_octave*12)-1

              -- velocity either comes from the midi message itself, 
              -- or min/max values specified in the control-map 
              local velocity = nil
              if msg.midi_msgs and msg.midi_msgs[1] then
                velocity = msg.midi_msgs[1][3]
              else
                velocity = scale_value(msg.xarg.maximum,msg.xarg.minimum,msg.xarg.maximum,0,127)
              end
              
              local instr_idx = self:get_instrument_index() 

              -- grid style triggering: ask our layout for notes,
              -- then loop through matches (can be more than one)
              local grid_notes = self._layout:get_pitches_from_index(ctrl_idx)
              --print("on_press() - grid_notes",rprint(grid_notes))
              for k,note_pitch in ipairs(grid_notes) do

                local triggered,instr_idx = self:trigger(true,instr_idx,note_pitch,velocity,ctrl_idx)

                -- if mono, clear pressed buttons
                if triggered then
                  local is_mono = rns.instruments[instr_idx].trigger_options.monophonic
                  if is_mono then
                    self.pressed_buttons = table.create()
                  end
                end

                self.pressed_buttons[ctrl_idx] = {
                  grid_index = ctrl_idx,
                  pitch = note_pitch,
                  velocity = velocity,
                  instr_idx = instr_idx,
                }
                self:update_grid()

              end
              --return triggered
            end

            c.on_release = function(obj)

              local instr_idx = self:get_instrument_index() 
              --print("*** on_release - instr_idx",instr_idx)

              -- if we switched instrument while pressing the button, 
              -- release on the originating instrument 
              if (self.pressed_buttons[ctrl_idx]) and
                self.pressed_buttons[ctrl_idx].instr_idx and
                (self.pressed_buttons[ctrl_idx].instr_idx~= instr_idx)
              then
                instr_idx = self.pressed_buttons[ctrl_idx].instr_idx
                --print("*** changed instr_idx into",instr_idx)
              end

              local grid_notes = self._layout:get_pitches_from_index(ctrl_idx)
              for k,note_pitch in ipairs(grid_notes) do

                local released,instr_idx = self:trigger(false,instr_idx,note_pitch,0,ctrl_idx)
                --print("*** Keyboard: key_grid released",released)
                if released then
                  self.pressed_buttons[ctrl_idx] = nil
                  self:update_grid()
                end
              end
              --return released
            end
            self._controls.grid:insert(c)

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
      if (self.options.mod_wheel.value == BROADCAST_MODWHEEL) then
        msg = {176,1,obj.value}
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

    	local rns = renoise.song()
      if (self.options.base_octave.value == OCTAVE_FOLLOW) then
        rns.transport.octave = math.max(0,rns.transport.octave - 1)
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

    	local rns = renoise.song()
      if (self.options.base_octave.value == OCTAVE_FOLLOW) then
        rns.transport.octave = math.min(8,rns.transport.octave + 1)
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
	
      local rns = renoise.song()
      if (self.options.base_octave.value == OCTAVE_FOLLOW) then
        rns.transport.octave = obj.index
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

    	local rns = renoise.song()
      local val = nil
      if (self.options.base_octave.value == OCTAVE_FOLLOW) then
        val = rns.transport.octave+2
      else
        val = OCTAVE_FOLLOW
      end
      self:_set_option("base_octave",val,self._process)
      self:set_octave(rns.transport.octave,true)
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

    	local rns = renoise.song()
      local val = nil
      if (self.options.track_index.value == TRACK_FOLLOW) then
        val = rns.selected_track_index+1
      else
        val = TRACK_FOLLOW
        self:set_track(rns.selected_track_index,true)
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

    	local rns = renoise.song()
      local val = nil
      if (self.options.instr_index.value == INSTR_FOLLOW) then
        val = rns.selected_instrument_index+2
      else
        val = TRACK_FOLLOW
        self:set_instr(rns.selected_instrument_index,true)
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

      local rns = renoise.song()
      if (self.options.base_volume.value == VOLUME_FOLLOW) then
        -- do not allow setting volume if velocity is disabled
        local enabled = rns.transport.keyboard_velocity_enabled
        if not enabled then
          obj:set_value(KEYBOARD_VELOCITIES,true)
          return false
        else
          rns.transport.keyboard_velocity = obj.value
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
      --print("volume_sync.on_press")
    	local rns = renoise.song()
      local val = nil
      if (self.options.base_volume.value == VOLUME_FOLLOW) then
        val = rns.transport.keyboard_velocity
      else
        val = VOLUME_FOLLOW
        self:set_volume(rns.transport.keyboard_velocity,true)
      end
      self:_set_option("base_volume",val,self._process)
    end
    self._controls.volume_sync = c
  end

  -- cycle layout

  local map = self.mappings.cycle_layout
  if map.group_name then
    local c = UIButton(self,map)
    c:set(self.palette.cycle_layout_off)
    c.on_press = function()

      -- forward until end (== off) 
      local layout_idx = nil
      for k,v in ipairs(layout_class_names) do
        if (k == self.options.grid_layout.value) then
          layout_idx = k+1
          break
        end
      end

      layout_idx = layout_class_names[layout_idx] and 
        layout_idx or 1
      self:set_grid_layout(layout_idx)


      self:_set_option("grid_layout",layout_idx,self._process)

    end
    self._controls.cycle_layout = c
  end


  -- all_notes_off

  local map = self.mappings.all_notes_off
  if map.group_name then
    local c = UIButton(self,map)
    c:set(self.palette.all_notes_off)
    c.on_press = function()
      self:all_notes_off()
      c:flash(
        0.1,self.palette.all_notes_on,self.palette.all_notes_off)
    end
    self._controls.all_notes_off = c
  end


  -- attach to song at first run
  self:_attach_to_song()

  return true

end

--------------------------------------------------------------------------------

--- called when application is first started

function Keyboard:obtain_octave()
  TRACE("Keyboard:obtain_octave()")

  local rns = renoise.song()

  if (self.options.base_octave.value == OCTAVE_FOLLOW) then
    self.curr_octave = rns.transport.octave
  else
    self.curr_octave = self.options.base_octave.value-2
  end

end

--- called when application is first started

function Keyboard:obtain_track()
  TRACE("Keyboard:obtain_track()")

	local rns = renoise.song()

  if (self.options.track_index.value == TRACK_FOLLOW) then
    self.curr_track = rns.selected_track_index
  else
    self.curr_track = self.options.track_index.value-2
  end

end

--- called when application is first started

function Keyboard:obtain_instr()
  TRACE("Keyboard:obtain_instr()")

	local rns = renoise.song()

  if (self.options.instr_index.value == INSTR_FOLLOW) then
    self.curr_instr = rns.selected_instrument_index
  else
    self.curr_instr = self.options.instr_index.value-2
  end

end

--- called when application is first started

function Keyboard:obtain_volume()
  TRACE("Keyboard:obtain_volume()")

	local rns = renoise.song()

  if (self.options.base_volume.value == VOLUME_FOLLOW) then
    self.curr_volume = rns.transport.keyboard_velocity
  else
    self.curr_volume = self.options.base_volume.value-1
  end

end

--------------------------------------------------------------------------------

--- set_grid_layout() - choose between available layout classes
-- @param val (int), the index of the layout (as listed in options)
-- @return bool, false when initialization of class failed

function Keyboard:set_grid_layout(val)
  TRACE("Keyboard:set_grid_layout()",val)

  if (#self._controls.grid == 0) then
    return false
  end

  local class_name = layout_class_names[val]

  if (not rawget(_G, class_name)) then
    renoise.app():show_warning(
      ("Whoops! Cannot instantiate layout with " ..
       "unknown class: '%s'"):format(class_name))

    return false      
  end

  
  self._layout = _G[class_name](self)
  self._update_grid_requested = true

  self:update_cycle_controls()

  -- momentarily flash button
  if self._controls.cycle_layout then
    self._controls.cycle_layout:flash(
      0.1,self.palette.cycle_layout_on,self.palette.cycle_layout_off)
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
  local semitones = (self.curr_octave-val)*12
  self.voice_mgr:transpose(self,semitones)

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

  -- ask our layout to update it's cache 
  self:cache_grid()


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
-- @param instr_idx (int)
-- @param skip_option (bool) set this to skip setting option

function Keyboard:set_instr(instr_idx,skip_option)
  TRACE("Keyboard:set_instr()",instr_idx,skip_option)

  if (not self.active) then
    return
  end

  self.curr_instr = instr_idx
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

  self._update_grid_requested = true
  --self:update_grid()

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

  --self._update_grid_requested = true

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

--- update display of layout cycler

function Keyboard:update_cycle_controls()
  TRACE("Keyboard:update_cycle_controls()")

  if (not self.active) then
    return
  end

  --local symbols = {"⋮","⋰","⋯",}
  local ctrl = self._controls.cycle_layout
  if ctrl then
    --local symbol = symbols[self.options.grid_layout.value] 
    local symbol = self.palette[
      string.format("cycle_layout_%s",self.options.grid_layout.value)]
      or {text=self.options.grid_layout.value}
    ctrl:set(symbol)
  end
  --print("*** update_cycle_controls - ctrl",ctrl)

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

-- called after switching octave, instrument

function Keyboard:update_grid()
  TRACE("Keyboard:update_grid()")

  if (not self.active) then
    return
  end

  if (#self._controls.grid>0) then
    self._layout:update_grid()
  end

end

--------------------------------------------------------------------------------

--- preprocess/cache the grid 
-- @see Duplex.Applications.Keyboard.GridLayout

function Keyboard:cache_grid()
  TRACE("Keyboard:update_grid()")

  if (#self._controls.grid>0) then
    self._layout:cache()
    self._update_grid_requested = true
  end

end

--------------------------------------------------------------------------------

--- obtain the current instrument 
-- this method should ALWAYS be able to produce an instrument
-- (fall back on the currently selected instrument if none was matched)
-- return int,bool

function Keyboard:get_instrument_index()
  TRACE("Keyboard:get_instrument_index()")

  local instr_index = nil
  local matched = true

	local rns = renoise.song()

  if (self.options.instr_index.value == INSTR_FOLLOW) then
    instr_index = rns.selected_instrument_index
  else
    instr_index = self.options.instr_index.value - 1
    if not rns.instruments[instr_index] then
      LOG("Notice from Duplex Keyboard: appointed instrument does not exist")
      instr_index = rns.selected_instrument_index
      matched = false
    end
  end
  
  return instr_index,matched

end

--------------------------------------------------------------------------------

--- obtain the current track
-- this method should ALWAYS be able to produce a valid track index
-- (fall back on the currently selected track if none was matched)
-- return int

function Keyboard:get_track_index()
  TRACE("Keyboard:get_track_index()")

  local track_index = nil
	local rns = renoise.song()

  if (self.options.track_index.value == TRACK_FOLLOW) then
    track_index = rns.selected_track_index
  else
    track_index = self.options.track_index.value - 1
    if not rns.tracks[track_index] then
      LOG("Notice from Duplex Keyboard: appointed track does not exist")
      track_index = rns.selected_track_index
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

	local rns = renoise.song()

  rns.transport.octave_observable:add_notifier(
    function()
      --print("octave_observable fired...")
      if (self.options.base_octave.value == OCTAVE_FOLLOW) then
        self:set_octave(renoise.song().transport.octave)
      end
    end
  )

  rns.selected_instrument_observable:add_notifier(
    function()
      --print("selected_instrument_observable fired...")
      if (self.options.instr_index.value == INSTR_FOLLOW) then
        self._update_grid_requested = true
        self:attach_to_instrument()
        self:set_instr(renoise.song().selected_instrument_index)
      end
    end
  )

  rns.selected_track_observable:add_notifier(
    function()
      --print("selected_track_observable fired...")
      if (self.options.track_index.value == TRACK_FOLLOW) then
        self:set_track(renoise.song().selected_track_index)
      end
    end
  )

  rns.transport.keyboard_velocity_observable:add_notifier(
    function()
      --print("keyboard_velocity_observable fired...")
      if (self.options.base_volume.value == VOLUME_FOLLOW) then
        self:set_volume(renoise.song().transport.keyboard_velocity)
      end
    end
  )

  rns.transport.keyboard_velocity_enabled_observable:add_notifier(
    function()
      --print("keyboard_velocity_enabled_observable fired...")
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

  rns.transport.playing_observable:add_notifier(
    function()
      --print("playing_observable fired...")
  
    -- bug
    -- http://forum.renoise.com/index.php/topic/42963-notes-with-hold-trigger-are-not-properly-released/

      self.voice_mgr:purge_voices(self)
      self.held_notes = table.create()

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

	local rns = renoise.song()
  local instr_index = self:get_instrument_index()
  local instr = rns.instruments[instr_index]

  -- update when keyzones are removed/added
  self:_remove_notifiers(self._instr_observables)
  self._instr_observables:insert(instr.sample_mappings_observable[1])
  instr.sample_mappings_observable[1]:add_notifier(
    function(notifier)
      --print("sample_mappings_observable fired...")
      self._instr_update_requested = true
      self._update_grid_requested = true
    end
  )

  -- update when keyzone note-ranges are modified
  for ___,s_map in ipairs(instr.sample_mappings[1]) do
    self._instr_observables:insert(s_map.note_range_observable) 
    s_map.note_range_observable:add_notifier(
      function(notifier)
        --print("note_range_observable fired...")
        self._update_grid_requested = true
      end
    )
  end

  -- update when selected sample changes
  rns.selected_sample_observable:add_notifier(
    function(notifier)
      --print("selected_sample_observable fired...")
      self._update_grid_requested = true
    end
  )

  -- update when selected scale changes
  instr.trigger_options.scale_mode_observable:add_notifier(
    function(notifier)
      --print("scale_mode_observable fired...")
      self.scale_mode = instr.trigger_options.scale_mode
      self:on_scale_change()
    end
  )
  self.scale_mode = instr.trigger_options.scale_mode

  -- update when selected scale changes
  instr.trigger_options.scale_key_observable:add_notifier(
    function(notifier)
      --print("scale_key_observable fired...")
      self.scale_key = instr.trigger_options.scale_key
      self:on_scale_change()
    end
  )
  self.scale_key = instr.trigger_options.scale_key

  -- update when scale mode is enabled/disabled
  if (renoise.API_VERSION < 5) then
    instr.trigger_options.hold_observable:add_notifier(
      function(notifier)
        --print("hold_observable fired...")
        if not instr.trigger_options.hold then
          -- turn off held voices 
          local instr_idx = self:get_instrument_index() 
          for k,v in ipairs(self.held_notes) do
            local grid_notes = self._layout:get_pitches_from_index(v.grid_index)
            for k2,v2 in ipairs(grid_notes) do
              self:trigger(false,instr_idx,v2,v.velocity,v.grid_index)
            end
          end
          self.held_notes = table.create()

          self._update_grid_requested = true
        end
      end
    )
  end

  self:set_grid_layout(self.options.grid_layout.value)

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
