--[[============================================================================
-- Duplex.Application.NotesOnWheels 
============================================================================]]--

--[[--
Notes On Wheels (N.O.W) is an arpeggiating step sequencer. 
Inheritance: @{Duplex.Application} > Duplex.Application.NotesOnWheels 

### Features
N.O.W. allows you to create a sequence and control all aspects of each step (such as the pitch, velocity etc.) in realtime. 

As for input, N.O.W. is very flexible, as you can control it via an additional MIDI input. Also, the virtual control surface will, when focused, detect and respond to keypresses within a specific range. 

The virtual keyboard supports both ordinary transpose (one octave up/down from the middle C), and multi-step sequences (press keys while holding the SHIFT modifier). Same goes for the external MIDI keyboard, which can be set up to act upon CC messages and pitch bend. 


### Controller setup

A dedicated control surface is located in the Renoise tools menu:
Duplex > Custombuilt > Notes On Wheels
    _________________________________________________
    |  _  _  _  _  _  _  _  _  _  _  _  _   _  _    | 
    | |_||_||_||_||_||_||_||_||_||_||_||_| |_||_|   | <- Position + Line offset
    |  _  _  _  _  _  _  _  _  _  _  _  _   ______  | 
    | (_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_) |__||__| | <- Pitch controls
    |  _  _  _  _  _  _  _  _  _  _  _  _   ______  | 
    | (_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_) |__||__| | <- Velocity controls
    |  _  _  _  _  _  _  _  _  _  _  _  _   ______  | 
    | (_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_) |__||__| | <- Offset controls
    |  _  _  _  _  _  _  _  _  _  _  _  _   ______  | 
    | (_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_) |__||__| | <- Gate controls
    |  _  _  _  _  _  _  _  _  _  _  _  _   ______  | 
    | (_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_)(_) |__||__| | <- Retrigger controls
    |  _  _  _  _  _  _  _  _  _  _  _  _   _  _    | 
    | |_||_||_||_||_||_||_||_||_||_||_||_| (_)(_)   | <- Steps + Spacing/Length
    |                                               |
    | |Write| |Learn| |Fill| |Global| |Modes...|    | <- Various controls
    | ______________________________________________|

Also, check out the compact version, which use fewer controls, but still manages to contain every feature of it's bigger brother. This is possible because the sliders in that version are switching between the currently active mode (pitch, velocity etc.), and therefore, require only a small set of physical controls. Perhaps it's a more realistic starting point for your wn controller mapping than the fully expanded version? It's located here: 
Duplex > Custombuilt > Notes On Wheels (compact)


### Discuss

Tool discussion is located on the [Renoise forum][1]
[1]: http://forum.renoise.com/index.php?/topic/31136-notes-on-wheels-now/


### Changelog

  0.98  
    - First release


--]]

--==============================================================================

-- constants

local MODE_PITCH = 1
local MODE_VELOCITY = 2
local MODE_OFFSET = 3
local MODE_GATE = 4
local MODE_RETRIG = 5

local EDIT_SYNC_ON = 1
local EDIT_SYNC_OFF = 2

local GLOBAL_MODE_ON = 1
local GLOBAL_MODE_OFF = 2

local WRITE_METHOD_TOUCH = 1
local WRITE_METHOD_LATCH = 2
local WRITE_METHOD_WRITE = 3

local FILL_MODE_ON = 1
local FILL_MODE_OFF = 2

local WRAP_OFFSET_ON = 1
local WRAP_OFFSET_OFF = 2


--==============================================================================

class 'NotesOnWheels' (Application)

--- These are the default options for the application
-- 
-- @field write_method Select the desired write method 
--    WRITE_METHOD_TOUCH will only output notes while the controller is being used
--    WRITE_METHOD_LATCH will start output once the controller is being used
--    WRITE_METHOD_WRITE will output notes continously, no matter what
-- @field edit_sync Enable output when recording/edit-mode in Renoise is active
-- @field global_mode Enable this to start the application in global mode
-- @field fill_mode Enable this to start the application in fill mode
-- @field offset_quantize Adjust this to divide a sample into a number of equally sized segments when (applied when using the sample-offset controls). 
-- @field offset_wrap Enable this to wrap the sample-offset 
-- @field midi_keyboard Select among available MIDI devices
-- @table default_options
NotesOnWheels.default_options = {
  write_method = {
    label = "Write method",
    description = "Determine how to write to the pattern",
    on_change = function(inst)
      -- TODO update write button state
      if (inst.options.write_method.value ~= WRITE_METHOD_LATCH) then
        inst.touched = false
      end
    end,
    items = {
      "Touch: output when touched",
      "Latch: touch to start output",
      "Write: constant output",
    },
    value = 2,
  },
  edit_sync = {
    label = "Edit-sync",
    description = "Output to pattern while edit-mode (red border in Renoise) is active",
    items = {
      "Edit-sync enabled",
      "Edit-sync disabled",
    },
    value = 2,
  },
  global_mode = {
    label = "Global mode",
    description = "Enable to start in global mode (output all parameters/steps)",
    items = {
      "Enabled on startup",
      "Disabled on startup",
    },
    value = 1,
  },
  fill_mode = {
    label = "Fill mode",
    description = "Enable to extend output to the entire track",
    items = {
      "Enabled on startup",
      "Disabled on startup",
    },
    value = 2,
  },
  offset_quantize = {
    label = "Offset quant.",
    description = "Specifies number of possible sample-offset (9xx) commands",
    items = {
      "Free (Not quantized)","2 steps","3 steps","4 steps",
      "5 steps","6 steps","7 steps","8 steps",
      "9 steps","10 steps","11 steps","12 steps",
      "13 steps","14 steps","15 steps","16 steps",
      "17 steps","18 steps","19 steps","20 steps",
      "21 steps","22 steps","23 steps","24 steps",
      "25 steps","26 steps","27 steps","28 steps",
      "29 steps","30 steps","31 steps","32 steps",
    },
    value = 1,
  },
  offset_wrap = {
    label = "Offset wrap",
    description = "Determine adjusting the sample-offset will wrap values or not",
    items = {
      "Enable offset wrapping",
      "Disable offset wrapping",
    },
    value = 1,
  },
  midi_keyboard = {
    label = "MIDI-Keys",
    description = "Use an external MIDI keyboard to control pitch/transpose",
    items = {
      "None",
    },
    value = 1,
    on_change = function(inst)
      inst:select_midi_port(inst.options.midi_keyboard.value-1)
    end,
  },
}

--- These are the available mappings for the application
-- 
-- Note: the `set_mode_[...]` mappings allow you to assign a mode directly to a specific button. If two or more modes are assigned in this way, they will act as radio buttons.
-- As a secondary feature, hold any of these buttons for a moment, and the sequence will be written to the pattern, `fill mode`
-- @field choose_mode (UISlider) The mode determine which kind of output the 'Steps' dials will generate
--    1 = Pitch - set the pitch of each step - max/min value will clear
--    2 = Velocity - set the volume of each step
--    3 = Offset - set the sample offset of each step
--    4 = Gate - set the length of each step, max is infinite
--    5 = Retrig - set the retrig rate of each step
-- @field set_mode_pitch (UIButton) Set mode to Pitch* 
-- @field set_mode_velocity (UIButton) Set mode to Velocity*
-- @field set_mode_offset (UIButton) Set mode to Offset*
-- @field set_mode_gate (UIButton) Set mode to Gate*
-- @field set_mode_retrig (UIButton) Set mode to Gate*
-- @field multi_sliders (group of UISliders) Specifies mode-dependant input dials (can control any parameter by switching mode)
-- @field pitch_sliders (group of UISliders) Direct pitch control of each step
-- @field velocity_sliders (group of UISliders) Direct velocity control of each step
-- @field offset_sliders (group of UISliders) Direct offset control of each step
-- @field gate_sliders (group of UISliders) Direct gate control of each step
-- @field retrig_sliders (group of UISliders) Direct retrig control of each step
-- @field num_steps (UISlider, 1-12) Set the number of steps in the sequence (mode-dependant)
-- @field step_spacing (UISlider, 1-16) This value will determine the space between each note in lines (a value of 0 will output all notes simultaneously)
-- @field pitch_adjust (UISlider) global pitch adjust (affects all steps)
-- @field velocity_adjust (UISlider) global velocity adjust (affects all steps)
-- @field offset_adjust (UISlider) global offset adjust (affects all steps)
-- @field gate_adjust (UISlider) global gate adjust (affects all steps)
-- @field retrig_adjust (UISlider) global retrig adjust (affects all steps)
-- @field multi_adjust (UISlider) global adjust (affects all steps in given mode)
-- @field write (UIButton) Toggles between output and no output (if you don't have room for this, check out @edit_sync)
-- @field learn (UIButton) Import pattern editor data beginning from the cursor position
-- @field fill (UIButton) Fill the entire track with the sequence, each time something changes. Use with caution, as this might be heavy on the CPU (with long patterns and many note columns)
-- @field global (UIButton) Enable 'global' to output all parameters (pitch, velocity, etc.) at the same time. When off, only the modified parameter type is output
-- @field shift_up (UIButton) Control the line-number offset (increase offset by a single line)
-- @field shift_down (UIButton) Control the line-number offset (decrease offset by a single line)
-- @field extend (UIButton) The 'extend' button will multiply the sequence's length by two, by cloning all steps and doubling the global retrig rate. 
-- @field shrink (UIButton) Pressing 'shrink' will reduce the length of the sequence and global retrig rate by 50%
-- @field position (UIButton) Set the position of the sequence, based on the position of the edit cursor
-- @table available_mappings
NotesOnWheels.available_mappings = {

  choose_mode = {
    description = "NOW: Choose mode",
  }, 

  set_mode_pitch = {
    description = "NOW: Set mode to 'pitch'"..
                  "\nHold to write sequence to entire pattern",
  },
  set_mode_velocity = {
    description = "NOW: Set mode to 'velocity'"..
                  "\nHold to write sequence to entire pattern",
  },
  set_mode_offset = {
    description = "NOW: Set mode to 'offset'"..
                  "\nHold to write sequence to entire pattern",
  },
  set_mode_gate = {
    description = "NOW: Set mode to 'duration'"..
                  "\nHold to write sequence to entire pattern",
  },
  set_mode_retrig = {
    description = "NOW: Set mode to 'retrigger)"..
                  "\nHold to write sequence to entire pattern",
  },
  multi_sliders = {
    description = "NOW: Mode-dependant slider",
  }, 
  pitch_sliders = {
    description = "NOW: Change pitch for step ",
  },
  velocity_sliders = {
    description = "NOW: Change velocity for step ",
  },
  offset_sliders = {
    description = "NOW: Change sample-offset for step ",
  },
  gate_sliders = {
    description = "NOW: Change gate/duration for step ",
  },
  retrig_sliders = {
    description = "NOW: Change number of retrigs for step ",
  },
  num_steps = {
    description = "NOW: Number of steps",
    orientation = ORIENTATION.HORIZONTAL, -- supports grid mode
  },
  step_spacing = {
    description = "NOW: Line-space between steps",
  },
  --num_lines = {
  --  description = "NOW: Sequence length (lines)",
  --},
  pitch_adjust = {
    description = "NOW: Transpose all steps",
  },
  velocity_adjust = {
    description = "NOW: Adjust volume for all steps",
  },
  offset_adjust = {
    description = "NOW: Adjust sample-offset for all steps",
  },
  gate_adjust = {
    description = "NOW: Adjust note length for all steps",
  },
  retrig_adjust = {
    description = "NOW: Adjust retriggering for all steps",
  },
  multi_adjust = {
    description = "NOW: Adjust all steps (mode-dependant)",
  },
  write = {
    description = "NOW: Write to pattern in realtime",
  },
  learn = {
    description = "NOW: Import sequence from pattern",
  },
  fill = {
    description = "NOW: Fill entire track (can be very CPU intensive, use with caution!!)",
  },
  global = {
    description = "NOW: Toggle between global/parameter-only output",
  },
  shift_up = {
    description = "NOW: Decrease line offset",
  },
  shift_down = {
    description = "NOW: Increase line offset",
  },
  extend = {
    description = "NOW: Repeat sequence twice",
  },
  shrink = {
    description = "NOW: Reduce sequence to half the size",
  },
  position = {
    description = "NOW: Displays position within sequence",
  },
}

NotesOnWheels.default_palette = {
  position_on     = { color={0xFF,0xFF,0xFF}, val=true, text="▪", },
  position_off    = { color={0x00,0x00,0x00}, val=false, text="▫", },
  write_on        = { color={0xFF,0xFF,0xFF}, val=true, text="Write", },
  write_off       = { color={0x00,0x00,0x00}, val=false, text="Write", },
  learn_on        = { color={0xFF,0xFF,0xFF}, val=true, text="Learn", },
  learn_off       = { color={0x00,0x00,0x00}, val=false, text="Learn", },
  fill_on         = { color={0xFF,0xFF,0xFF}, val=true, text="Fill",  },
  fill_off        = { color={0x00,0x00,0x00}, val=false, text="Fill",  },
  global_on       = { color={0xFF,0xFF,0xFF}, val=true, text="Global",},
  global_off      = { color={0x00,0x00,0x00}, val=false, text="Global",},
  shift_up_on     = { color={0xFF,0xFF,0xFF}, val=true, text="↑",},
  shift_up_off    = { color={0x00,0x00,0x00}, val=false, text="↑",},
  shift_down_on   = { color={0xFF,0xFF,0xFF}, val=true, text="↓", },
  shift_down_off  = { color={0x00,0x00,0x00}, val=false, text="↓",},
  extend_on       = { color={0xFF,0xFF,0xFF}, val=true, text="x²",},
  extend_off      = { color={0x00,0x00,0x00}, val=false, text="x²",},
  shrink_on       = { color={0xFF,0xFF,0xFF}, val=true, text="½", },
  shrink_off      = { color={0x00,0x00,0x00}, val=false, text="½",},
  set_pitch_on    = { color={0xFF,0xFF,0xFF}, val=true, text="Pitch",},
  set_pitch_off   = { color={0x00,0x00,0x00}, val=false, text="Pitch", },
  set_velocity_on = { color={0xFF,0xFF,0xFF}, val=true, text="Velocity",},
  set_velocity_off= { color={0x00,0x00,0x00}, val=false, text="Velocity",},
  set_offset_on   = { color={0xFF,0xFF,0xFF}, val=true, text="Offset",  },
  set_offset_off  = { color={0x00,0x00,0x00}, val=false, text="Offset",},
  set_gate_on     = { color={0xFF,0xFF,0xFF}, val=true, text="Gate",},
  set_gate_off    = { color={0x00,0x00,0x00}, val=false, text="Gate",  },
  set_retrig_on   = { color={0xFF,0xFF,0xFF}, val=true, text="Retrig",},
  set_retrig_off  = { color={0x00,0x00,0x00}, val=false, text="Retrig",  },

}

--------------------------------------------------------------------------------

--- Constructor method
-- @param (VarArg)
-- @see Duplex.Application

function NotesOnWheels:__init(...)
  TRACE("NotesOnWheels:__init",...)

  --- the step which was last modified (used for non-global output)
  self.step_focus = nil

  --- set to something else than 0 when instrument is sliced
  -- (tracked in realtime via the sample_mappings property)
  self.number_of_slices = 0

  --- remember where the sample mappings start/end
  -- (tracked in realtime via the sample_mappings property)
  self.lower_note = nil
  self.upper_note = nil

  --- detect if sample mappings are 'white keys only'
  -- (tracked in realtime via the sample_mappings property)
  self.white_keys_only = true

  --- list of white keys
  -- @field ... lot of keys
  -- @table white_keys
  self.white_keys = {0,2,4,5,7,9,11,12,14,16,17,19,21,23,24,26,28,29,31,33,35,36,38,40,41,43,45,47,48,50,52,53,55,57,59,60,62,64,65,67,69,71,72,74,76,77,79,81,83,84,86,88,89,91,93,95,96,98,100,101,103,105,107,108,110,112,113,115,117,119}

  --- reference to the instrument observable
  --self._attached_instr_observable = nil

  --- true while the sequencer accepts incoming notes
  -- PC keyboard: when shift modifier is pressed
  self.accept_note_input = false

  --- true, once we input using shift modifier
  self.has_received_input = false

  --- MIDI keys: remember pressed keys
  self.midi_pressed_keys = table.create()

  --- MIDI keys: max number of simultaneously pressed keys
  self.midi_max_keys = 0

  --- use these for scheduled output
  -- (assign a special value to make them output first time)
  self.scheduled_step = -1
  self.scheduled_mode = -1

  --- track playback progress in 'blinks' 
  self._blink = false

  --- the lit state of buttons
  self.write_button_state = nil
  self.learn_button_state = nil

  --- track changed? check via idle loop
  self.track_changed = false

  --- when using the 'latch' write method, this will indicate
  -- that no control has yet been touched 
  self.touched = false

  --- the song is playing? check via idle loop
  self._playing = renoise.song().transport.playing

  --- realtime position 
  self.realtime_pos = nil

  --- when auto-learning is enabled
  self.autolearn = false

  --- (bool) temporary flag set when entering autolearn mode
  self.just_entered_autolearn = false

  --- (NOW_Sequence) internal sequence representation 
  self.seq = nil

  --- the pattern-line last detected by idle loop
  self.last_line = 0              
  --- the current line offset
  self.line_offset = 0            
  --- the upcoming pattern's line offset
  self.pending_line_offset = 0    
  --- sequence-pos of upcoming pattern 
  self.pending_seq_pos = nil      

  --- all UIComponent references are kept here
  -- create tables in advance, the rest ad hoc
  self._controls = {
    multi_sliders = table.create(),
    pitch_sliders = table.create(),
    velocity_sliders = table.create(),
    offset_sliders = table.create(),
    gate_sliders = table.create(),
    retrig_sliders = table.create(),
    pos_buttons = table.create(),

  }

  -- extend default options with the available midi ports
  -- ("options" is a vararg - please see Application.lua for more info)
  local input_devices = renoise.Midi.available_input_devices()
  local options = select(3,...)
  local items = NotesOnWheels.default_options.midi_keyboard.items
  for k,v in ipairs(input_devices) do
    items[k+1] = v
    options.midi_keyboard.items[k+1] = v
  end

  -- apply user-specified arguments
  Application.__init(self,...)

  -- set these values after configuration has been applied

  --- (enum) the current mode
  self.mode = MODE_PITCH

  --- (enum) write method
  self.write_method = self.options.write_method.value

  --- (bool) global mode 
  self.global_mode = (self.options.global_mode.value == GLOBAL_MODE_ON)

  --- (bool) fill mode
  self.fill_mode = (self.options.fill_mode.value == FILL_MODE_ON)

  --- (bool) write mode
  self.write_mode = false

  if (self.options.edit_sync.value == EDIT_SYNC_ON) then
    self.write_mode = renoise.song().transport.edit_mode
  end
  
  --- (renoise.Midi.MidiDevice) 
  self.midi_in = nil
  self:select_midi_port(self.options.midi_keyboard.value-1)

end

-------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.start_app
-- @return bool or nil

function NotesOnWheels:start_app()
  TRACE("NotesOnWheels.start_app()")

  if not Application.start_app(self) then
    return
  end

  self:_attach_to_song()
  self:create_empty_sequence()
  self:reset_adjustments()
  self.touched = false

end

-------------------------------------------------------------------------------

--- initialize MIDI input

function NotesOnWheels:select_midi_port(port_idx)
  TRACE("NotesOnWheels.select_midi_port()",port_idx)

  -- always close it first
  if (self.midi_in and self.midi_in.is_open) then
    self.midi_in:close()
  end
  -- when 'none' is selected
  if port_idx<1 then
    return
  end
  local input_devices = renoise.Midi.available_input_devices()
  local port_name = input_devices[port_idx]
  if port_name then
    self.midi_in = renoise.Midi.create_input_device(port_name,
      {self, NotesOnWheels.midi_callback}
    )
  end

end

-------------------------------------------------------------------------------

--- receive MIDI from device

function NotesOnWheels:midi_callback(message)
  TRACE("NotesOnWheels:midi_callback",message[1], message[2], message[3])

  -- determine the type of signal : note/cc/etc
  if (message[1]>=128) and (message[1]<=159) then
    --print("DEVICE_MESSAGE.MIDI_NOTE")
    local is_note_off = false
    if(message[1]>143)then -- on
      if (message[3]==0) then -- off
        is_note_off = true   
      else
        self.midi_pressed_keys:insert(message[2])
      end
    else  -- off
      is_note_off = true
    end
    if is_note_off then
      -- remove key from pressed keys
      for k,v in ripairs(self.midi_pressed_keys) do
        if (v==message[2]) then
          -- todo: figure out index in pitch steps,
          -- and update velocity 
          self.midi_pressed_keys:remove(k)
        end
      end
      -- when all keys have been released, update length
      if (#self.midi_pressed_keys==0) then
        self.seq:set_num_steps(self.midi_max_keys,true)
        self.midi_max_keys = 0
      end
    elseif (#self.midi_pressed_keys>0) then
      if (#self.midi_pressed_keys==1) then
        -- first note has arrived, set sequence length
        self.midi_max_keys = 0
      end
      self.midi_max_keys = self.midi_max_keys+1
      local length = math.max(self.midi_max_keys,self.seq.num_steps)
      if (length<=12) then
        -- add note to sequence
        local note = message[2]
        self.seq:set_pitch(self.midi_max_keys,message[2],true,true)
        self.seq:set_velocity(self.midi_max_keys,message[3],true,true)
        self.seq:set_num_steps(length,true)
        self.touched = true
        self:output_sequence()
      else
        local msg = string.format("Notes On Wheels: no more keys are accepted into the sequence")
        renoise.app():show_status(msg)
      end
    end
  elseif (message[1]>=176) and (message[1]<=191) then
    --print("DEVICE_MESSAGE.MIDI_CC")
    if (self.mode ~= MODE_PITCH) then
      self.seq:adjust_multi(message[3]/127,true,true)
    end
  elseif (message[1]>=224) and (message[1]<=239) then
    --print("DEVICE_MESSAGE.MIDI_PITCH_BEND")
    self.seq:adjust_pitch(message[3]/127,true)
  else
    -- unsupported message...
  end

end

-------------------------------------------------------------------------------

--- schedule output, simple way to reduce number of pattern writes:
-- remember the last step / mode - if either change, output immediately 
-- @param seq_step (int), step to output (can be nil)
-- @param mask_mode (enum), restrict to specific mode (can be nil)

function NotesOnWheels:schedule_output(seq_step,mask_mode)
  TRACE("NotesOnWheels:schedule_output",seq_step,mask_mode)

  if (seq_step~=self.scheduled_step) or (mask_mode~=self.scheduled_mode) then
    if (self.scheduled_step==-1) and (self.scheduled_mode==-1) then
      --print("first time around, output immediately")
      -- first time around, output immediately
      self:output_sequence(seq_step,mask_mode)
      self.scheduled_output = false
    else
      --print("output scheduled")
      self:output_sequence(self.scheduled_step,self.scheduled_mode)
      self.scheduled_output = true
    end
  else 
    self.scheduled_output = true
  end

  self.scheduled_step = seq_step 
  self.scheduled_mode = mask_mode

end

-------------------------------------------------------------------------------

--- output sequence to pattern 
-- @param seq_step (int), step to output (can be nil)
-- @param mask_mode (enum), restrict to specific mode (can be nil)
-- @param stream (bool), produce output in 'short bursts'
-- @param force (bool), force output (e.g. when mode buttons are held)

function NotesOnWheels:output_sequence(seq_step,mask_mode,stream,force)
  TRACE("NotesOnWheels:output_sequence",seq_step,mask_mode,stream,force)

  -- output enabled? 
	if not force and not self.write_mode then
    --print("output disabled")
		return
	end

  -- touch mode can prevent output next time
  if (self.options.write_method.value == WRITE_METHOD_TOUCH) then
    if not self.touched then
      --print("touch mode prevented output")
      return
    end
    self.touched = false
  end

  -- expand the sequence to step length
  if seq_step and (seq_step>self.seq.num_steps) then
    self.seq:set_num_steps(seq_step,true)
  end

  -- latch mode can also prevent output
  if not self.touched and
  (self.options.write_method.value == WRITE_METHOD_LATCH) then
    --print("latch prevented output")
    return
  end

  -- global mode will cancel out mode masking
  if self.global_mode then
    mask_mode = nil
  end

  local begin_line = nil
  local patt_idx = nil

  if self._playing then
    local pos = renoise.song().transport.playback_pos
    begin_line = pos.line
    patt_idx = renoise.song().sequencer.pattern_sequence[pos.sequence]
  else
    local pos = renoise.song().transport.edit_pos
    begin_line = pos.line
    patt_idx = renoise.song().selected_pattern_index
  end

  -- write sequence to pattern
  local recursive = false
  self.seq:write_to_pattern(patt_idx,begin_line,seq_step,mask_mode,stream,recursive,self.line_offset)

end


-------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_idle

function NotesOnWheels:on_idle()

  if (not self.active) then 
    return 
  end

  local has_written = false

  local ctrl = self._controls.write
  local playing = renoise.song().transport.playing
  local pos = renoise.song().transport.playback_pos

  if playing then 
    -- realtime position: check if changed
    local tmp = nil
    if (self.seq.spacing==0) then
      tmp = 1
    else
      local tmp_len = self.seq.num_steps
      tmp = math.ceil(((pos.line+self.line_offset)/self.seq.spacing)%tmp_len)
      if (tmp==0) then -- fix
        tmp = tmp_len
      end
    end
    if (tmp~=self.realtime_pos)then
      local ctrl_pos = self._controls.pos_buttons[self.realtime_pos]
      if ctrl_pos then
        ctrl_pos:set(self.palette.position_off)
      end
      self.realtime_pos = tmp
      ctrl_pos = self._controls.pos_buttons[self.realtime_pos]
      if ctrl_pos then
        ctrl_pos:set(self.palette.position_on)
      end
    end
    -- continuous mode support: we have arrived at the desired position 
    if (self.pending_seq_pos and pos.sequence==self.pending_seq_pos) then
      local arrived = true
      -- if looped, we need to check that we've played the entire pattern
      -- (we have no 'pattern playback restarted' notifier, so this is a workaround)
      if (renoise.song().transport.loop_pattern) then
        local curr_line = renoise.song().selected_line_index
        if (self.last_line<=curr_line) then
          arrived = false
        end
        self.last_line = curr_line
      end
      if arrived then
        self.line_offset = self.pending_line_offset
        self.pending_seq_pos = nil
      end
    end
  end

  -- periodic output & write button blinking is 
  -- controlled by the playback line number 
  local lpb = renoise.song().transport.lpb
  local pos = playing 
    and renoise.song().transport.playback_pos 
    or renoise.song().transport.edit_pos
  local blink = (math.floor((((pos.line-2)/lpb)+1)%2)==1)
  local changed = false
  if (blink~=self._blink) then
    changed = true
    self._blink = blink
  end
  
  if(self.write_mode) then
    local enforce_latch_delay = not self.touched and 
      (self.options.write_method.value == WRITE_METHOD_LATCH)
    if changed then
      if not enforce_latch_delay then
        self:output_sequence(self.step_focus,self.mode,playing)
        has_written = true
      end
    end
    -- toggle write button blinking
    -- (when playback is stopped, use the clock)
    if enforce_latch_delay and ctrl then
      local lit = blink
      if not playing then
        lit = (math.floor(os.clock()*2)%2==0) and true or false
      end
      if (lit~=self.write_button_state) then
        if lit then
          ctrl:set(self.palette.write_on)
        else
          ctrl:set(self.palette.write_off)
        end
        self.write_button_state = lit
      end
    elseif ctrl and (self.write_button_state==false) then
      -- make sure write button is always lit 
      ctrl:set(self.palette.write_on)
      self.write_button_state = true
    end
  end

  -- auto-learning, learn button blinking
  if self.autolearn then
    local c = self._controls.learn
    if c then
      local lit = blink
      if not playing then
        lit = (math.floor(os.clock()*2)%2==0) and true or false
      end
      if (lit~=self.learn_button_state) then
        if lit then
          c:set(self.palette.learn_on)
        else
          c:set(self.palette.learn_off)
        end
        self.learn_button_state = lit
      end
    end
    if changed or self.track_changed then
      self:reset_adjustments()
      self.seq:learn_sequence()
      self.track_changed = false
    end
  end

  -- when we start/stop playing
  if (not playing and playing ~= self._playing) then
    self._playing = false
    -- cancel any scheduled write
    self.pending_seq_pos = nil
    -- update write mode button
    if (ctrl) then
      ctrl:set(self.palette.write_on)
    end
    -- switch off realtime position
    self.realtime_pos = nil
  elseif (playing and playing ~= self._playing) then
    self._playing = true
    -- produce instant output
    self:output_sequence(self.step_focus,self.mode,true)
    has_written = true
  end


  -- write scheduled output
  if not has_written and self.scheduled_output then
  --if self.scheduled_output then
    self:output_sequence(self.scheduled_step,self.scheduled_mode,playing)
    self.scheduled_output = false
  end

end

-------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_new_document

function NotesOnWheels:on_new_document()
  TRACE("NotesOnWheels:on_new_document")
  
  self:_attach_to_song()
  self:disable_write_mode()

end

-------------------------------------------------------------------------------

--- Update display of write mode

function NotesOnWheels:disable_write_mode()
  TRACE("NotesOnWheels:disable_write_mode")

  self.write_mode = false

  local skip_event = true
  local ctrl = self._controls.write
  if ctrl then
    ctrl:set(self.palette.write_off)
  end

end

-------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_keypress
-- @param key (table)

function NotesOnWheels:on_keypress(key)
  TRACE("NotesOnWheels:on_keypress")

  -- workaround: look up character to obtain the note
  local chars = {
    {char="z",note=0},
    {char="s",note=1},
    {char="x",note=2},
    {char="d",note=3},
    {char="c",note=4},
    {char="v",note=5},
    {char="g",note=6},
    {char="b",note=7},
    {char="h",note=8},
    {char="n",note=9},
    {char="j",note=10},
    {char="m",note=11},
    {char="comma",note=12},
    {char="q",note=12},
    {char="l",note=13},
    {char="2",note=13},
    {char="period",note=14},
    {char="w",note=14},
    {char=";",note=15}, -- EN
    {char="æ",note=15}, -- DA
    {char="3",note=15},
    {char="/",note=16}, -- EN
    {char="-",note=16}, -- DA
    {char="e",note=16},
    {char="r",note=17},
    {char="5",note=18},
    {char="t",note=19},
    {char="6",note=20},
    {char="y",note=21},
    {char="7",note=22},
    {char="u",note=23},
    {char="i",note=24}
  }
  local note = key.note
  if not key.note then
    for k,v in ipairs(chars) do
      if (key.name==v.char) then
        note = v.note
        break
      end
    end
  end
  if note then
    -- we only accept keys in the range 0-24
    if (note>24) then
      return false
    end
    if not key.repeated then
      -- TODO support CTRL+shift to insert
      if (key.modifiers == "shift") then
        if not self.has_received_input then
          -- first note has arrived, set sequence length
          self.seq.num_steps = 0
          self.has_received_input = true
        end
        local length = self.seq.num_steps+1
        if (length<=12) then
          -- add note to sequence
          local oct = renoise.song().transport.octave
          local note_oct = (oct*12)+note-12
          self.seq:set_pitch(length,note_oct,true,true)
          self.seq:set_num_steps(length,true)
          self.touched = true
          self:output_sequence()
        else
          self.accept_note_input = false
          local msg = string.format("Notes On Wheels: No more keys are accepted into the sequence")
          renoise.app():show_status(msg)
        end
      else
        self.accept_note_input = false
        self.seq:adjust_pitch((note/24),true)
      end
    end
    return false
  elseif (key.name == "lshift") then
    -- prepare for new sequence
    self.accept_note_input = true
    self.has_received_input = false
  end
  
  return true

end

-------------------------------------------------------------------------------

--- create or empty sequence

function NotesOnWheels:create_empty_sequence()
  TRACE("NotesOnWheels:create_empty_sequence()")

  -- create new sequence ?
  if not self.seq then
    self.seq = NOW_Sequence(self)
  end

  local skip_event = true
  local length = self.seq.num_steps
  self.seq:set_num_steps(length)

  -- update (some) controls
  if self._controls.num_steps then
    self._controls.num_steps:set_value(length,skip_event)
  end
  if self._controls.num_lines then
    self._controls.num_lines:set_value(length,skip_event)
  end


end

-------------------------------------------------------------------------------

-- adds notifiers to song
-- invoked when a new document becomes available

function NotesOnWheels:_attach_to_song()
  TRACE("NotesOnWheels:_attach_to_song")
  
  -- edit sync 
  renoise.song().transport.edit_mode_observable:add_notifier(
    function()
      TRACE("NotesOnWheels:edit_mode_observable fired...")
        if (self.options.edit_sync.value == EDIT_SYNC_ON) then
          self.write_mode = renoise.song().transport.edit_mode
          if (self._controls.write) then
            if self.write_mode then
              self._controls.write:set(self.palette.write_off)
            else
              self._controls.write:set(self.palette.write_off)
            end
            --self._controls.write:set(self.write_mode)
          end
        end
        if not self.write_mode then
          self.touched = false
        end
    end
  )

  -- when track is changed
  renoise.song().selected_track_index_observable:add_notifier(
    function()
      TRACE("NotesOnWheels:selected_track_index_observable fired...")
      self.track_changed = true
    end
  )


  -- when instrument is changed, 
  renoise.song().selected_instrument_observable:add_notifier(
    function()
      TRACE("NotesOnWheels:selected_instrument_observable fired...")
      self:_attach_to_instrument()
    end
  )

  -- immediately attach to the current instrument
  local new_song = true
  self:_attach_to_instrument(new_song)

end

-------------------------------------------------------------------------------

--- attach to selected instrument 

function NotesOnWheels:_attach_to_instrument(new_song)
  TRACE("NotesOnWheels:_attach_to_instrument",new_song)

  local inst_idx = renoise.song().selected_instrument_index
  renoise.song().instruments[inst_idx].sample_mappings_observable[1]:add_notifier(
    function()
      TRACE("NotesOnWheels:sample_mappings_observable fired...")
      self:detect_slices()
    end
  
  )

  self:detect_slices()

end

-------------------------------------------------------------------------------

--- detect number of slices, and if using "white keys" 

function NotesOnWheels:detect_slices()
  TRACE("NotesOnWheels:detect_slices()")

  local inst_idx = renoise.song().selected_instrument_index
  local mappings = renoise.song().instruments[inst_idx].sample_mappings[1] -- Note On Layer
  if not mappings[1] or not mappings[1].read_only then
    -- not sliced
    self.number_of_slices = 0
  else
    -- count number of slices,
    -- detect if white keys only
    self.number_of_slices = #mappings
    self.white_keys_only = true
    for k,map in ipairs(mappings) do
      if not table.find(self.white_keys,map.base_note) then
        self.white_keys_only = false
      end
    end
    self.lower_note = mappings[1].base_note
    self.upper_note = mappings[#mappings].base_note
  end

end

-------------------------------------------------------------------------------

--- convert the pitch range (normally 0-121) to the sliced sample range
-- (for example, middle C and every white key for the next two octaves)
-- @param int_val (number) the value to scale
-- @param invert (bool) when the value is sent to a control
function NotesOnWheels:to_sliced_pitch_range(int_val,invert)
  TRACE("NotesOnWheels:to_sliced_pitch_range",int_val,invert)

  -- special value, leave alone...
  if (int_val==0) then
    return int_val
  end
  if (int_val==121) then
    return self.upper_note
  end
  if invert then
    int_val = math.floor(scale_value(int_val,self.lower_note,self.upper_note,1,121))
  else
    int_val = math.floor(scale_value(int_val,1,121,self.lower_note,self.upper_note))
    if self.white_keys_only then
      if not table.find(self.white_keys,int_val) then
        int_val = int_val-1
      end
    end
    int_val = clamp_value(int_val,self.lower_note,self.upper_note)
  end
  return int_val
end

-------------------------------------------------------------------------------

--- when mode has changed
-- @param mode (int, MODE_PITCH,MODE_VELOCITY,etc)

function NotesOnWheels:change_mode(mode)
  TRACE("NotesOnWheels:change_mode",mode)

  if (self.mode == mode) then
    return
  end

  self.mode = mode

  -- update buttons
  if (mode == MODE_PITCH) then
    self._controls.set_mode_pitch:set(self.palette.set_pitch_on)
  else
    self._controls.set_mode_pitch:set(self.palette.set_pitch_off)
  end
  if (mode == MODE_VELOCITY) then
    self._controls.set_mode_velocity:set(self.palette.set_velocity_on)
  else
    self._controls.set_mode_velocity:set(self.palette.set_velocity_off)
  end
  if (mode == MODE_OFFSET) then
    self._controls.set_mode_offset:set(self.palette.set_offset_on)
  else
    self._controls.set_mode_offset:set(self.palette.set_offset_off)
  end
  if (mode == MODE_GATE) then
    self._controls.set_mode_gate:set(self.palette.set_gate_on)
  else
    self._controls.set_mode_gate:set(self.palette.set_gate_off)
  end
  if (mode == MODE_RETRIG) then
    self._controls.set_mode_retrig:set(self.palette.set_retrig_on)
  else
    self._controls.set_mode_retrig:set(self.palette.set_retrig_off)
  end

  -- update the multi-controls 
  for control_index=1,math.min(#self._controls.multi_sliders,self.seq.num_steps) do
    local ctrl = self._controls.multi_sliders[control_index]
    if ctrl then
      if (self.mode == self.MODE_PITCH) then
        -- check for empty note (121)
        local int_val = self.seq.pitch_steps[control_index]
        if (int_val==121) then 
          int_val = 0 
        end
        if (self.number_of_slices>0) then
          int_val = self:to_sliced_pitch_range(int_val,true)
        end
        self.seq:update_pitch_ctrl(int_val,ctrl)
      elseif (self.mode == MODE_VELOCITY) then
        self.seq:update_velocity_ctrl(self.seq.velocity_steps[control_index],ctrl)
      elseif (self.mode == MODE_OFFSET) then
        self.seq:update_offset_ctrl(self.seq.offset_steps[control_index],ctrl)
      elseif (self.mode == MODE_GATE) then
        self.seq:update_gate_ctrl(self.seq.gate_steps[control_index],ctrl)
      elseif (self.mode == MODE_RETRIG) then
        self.seq:update_retrig_ctrl(self.seq.retrig_steps[control_index],ctrl)
      end
    end
  end

  local ctrl = self._controls.multi_adjust
  if ctrl then
    local val = nil
    if (self.mode == MODE_PITCH) then
      val = self.seq.pitch_adjust 
    elseif (self.mode == MODE_VELOCITY) then
      val = self.seq.velocity_adjust 
    elseif (self.mode == MODE_OFFSET) then
      val = self.seq.offset_adjust 
    elseif (self.mode == MODE_GATE) then
      val = self.seq.gate_adjust 
    elseif (self.mode == MODE_RETRIG) then
      val = self.seq.retrig_adjust 
    end
    ctrl:set_value(val,true)
  end
end

-------------------------------------------------------------------------------

--- shift sequence in either direction
-- if we have a pending offset, update that one as well
-- @param amount (int) 

function NotesOnWheels:shift(amount)
  TRACE("NotesOnWheels:shift()",amount)

  self.line_offset = self.line_offset+amount
  if self.pending_line_offset then
    self.pending_line_offset = self.line_offset+amount
  end
  local msg = string.format("Notes On Wheels: Sequence is offset by %d lines",self.line_offset)
  renoise.app():show_status(msg)

end


-------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application._build_app
-- @return bool

function NotesOnWheels:_build_app()
  TRACE("NotesOnWheels:_build_app()")

  local cm = self.display.device.control_map
  local group_name = nil

  -- create 'position' buttons
  group_name = self.mappings.position.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      for control_index = 1, #group do
        local c = UIButton(self)
        c.group_name = self.mappings.position.group_name
        c.tooltip = self.mappings.position.description
        c:set_pos(control_index)
        c:set(self.palette.position_off)
        c.on_press = function() 
          -- TODO do "something"
        end
        self._controls.pos_buttons[control_index] = c    
      end
    end
  end

  --  create 'pitch_sliders' group
  group_name = self.mappings.pitch_sliders.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      for control_index = 1, #group do
        local c = UISlider(self)
        c.group_name = group_name
        c:set_pos(control_index)
        c.ceiling = 1
        c.tooltip = self.mappings.pitch_sliders.description.." #"..control_index
        c:set_value(0)
        c.on_change = function(obj) 
          local int_val = math.floor(obj.value*121)

          if (self.number_of_slices>0) then
            int_val = self:to_sliced_pitch_range(int_val)
          end
          if self.seq:set_pitch(control_index,int_val) then
            self:schedule_output(control_index,MODE_PITCH)
            -- display hack: update the multi slider as well, but check
            -- if we have reached the minimum value while going downward
            local ctrl = self._controls.multi_sliders[control_index]
            local pitch_val = self.seq.pitch_steps[control_index]
            if (pitch_val==121 and compare(obj.value,0,10)) then
              pitch_val = 0
            end
            self.seq:update_pitch_ctrl(pitch_val,ctrl)
          end
          self:change_mode(MODE_PITCH)
          self.step_focus = control_index
          self.touched = true
        end 
        self._controls.pitch_sliders[control_index] = c
      end
    end
  end

  --  create 'velocity_sliders' group
  group_name = self.mappings.velocity_sliders.group_name
  if group_name then
    local group = cm.groups[self.mappings.velocity_sliders.group_name]
    if group then
      for control_index = 1, #group do
        local c = UISlider(self)
        c.group_name = group_name
        c:set_pos(control_index)
        c.ceiling = 1
        c.tooltip = self.mappings.velocity_sliders.description.." #"..control_index
        c:set_value(1)
        c.on_change = function(obj) 
          local int_val = math.floor(obj.value*127)
          if self.seq:set_velocity(control_index,int_val,nil,true) then
            self:schedule_output(control_index,MODE_VELOCITY)
          end
          self:change_mode(MODE_VELOCITY)
          self.step_focus = control_index
          self.touched = true
        end 
        self._controls.velocity_sliders[control_index] = c
      end
    end
  end
  
  --  create 'offset_sliders' group
  group_name = self.mappings.offset_sliders.group_name
  if group_name then
    local group = cm.groups[self.mappings.offset_sliders.group_name]
    if group then
      for control_index = 1, #group do
        local c = UISlider(self)
        c.group_name = group_name
        c:set_pos(control_index)
        c.ceiling = 1
        c.tooltip = self.mappings.offset_sliders.description.." #"..control_index
        c:set_value(0)
        c.on_change = function(obj) 
          local int_val = math.floor(obj.value*255)
          if self.seq:set_offset(control_index,int_val,nil,true) then
            self:schedule_output(control_index,MODE_OFFSET)
          end
          self:change_mode(MODE_OFFSET)
          self.step_focus = control_index
          self.touched = true
        end 
        self._controls.offset_sliders[control_index] = c
      end
    end
  end
  
  --  create 'gate_sliders' group
  group_name = self.mappings.gate_sliders.group_name
  if group_name then
    local group = cm.groups[self.mappings.gate_sliders.group_name]
    if group then
      for control_index = 1, #group do
        local c = UISlider(self)
        c.group_name = group_name
        c:set_pos(control_index)
        c.ceiling = 1
        c.tooltip = self.mappings.gate_sliders.description.." #"..control_index
        c:set_value(1)
        c.on_change = function(obj) 
          local int_val = math.floor(obj.value*255)
          if self.seq:set_gate(control_index,int_val,nil,true) then
            self:schedule_output(control_index,MODE_GATE)
          end
          self:change_mode(MODE_GATE)
          self.step_focus = control_index
          self.touched = true
        end 
        self._controls.gate_sliders[control_index] = c
      end
    end
  end
  
  --  create 'retrig_sliders' group
  group_name = self.mappings.retrig_sliders.group_name
  if group_name then
    local group = cm.groups[self.mappings.retrig_sliders.group_name]
    if group then
      for control_index = 1, #group do
        local c = UISlider(self)
        c.group_name = group_name
        c:set_pos(control_index)
        c.ceiling = 1
        c.tooltip = self.mappings.retrig_sliders.description.." #"..control_index
        c:set_value(0)
        c.on_change = function(obj) 
          --local int_val = math.floor(obj.value*NOW_Sequence.MAX_RETRIGS)
          local val_exp = math.floor(self.seq:scale_exp(obj.value,1,4)*NOW_Sequence.MAX_RETRIGS)
          if self.seq:set_retrig(control_index,val_exp,nil,true) then
            self:schedule_output(control_index,MODE_RETRIG)
          end
          self:change_mode(MODE_RETRIG)
          self.step_focus = control_index
          self.touched = true
        end 
        self._controls.retrig_sliders[control_index] = c
      end
    end
  end
  
  --  create 'multi_sliders' sliders
  group_name = self.mappings.multi_sliders.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      for control_index = 1, #group do
        local c = UISlider(self)
        c.group_name = group_name
        c:set_pos(control_index)
        c.ceiling = 1
        c.tooltip = self.mappings.multi_sliders.description.." #"..control_index
        c:set_value(0)
        c.on_change = function(obj) 
          -- route output to active parameter
          -- and update dedicated control (if it exists)
          local update = true
          if (self.mode == MODE_PITCH) then
            local int_val = math.floor(obj.value*121)
            if (self.number_of_slices>0) then
              int_val = self:to_sliced_pitch_range(int_val)
            end
            if self.seq:set_pitch(control_index,int_val,update) then
              self:schedule_output(control_index,MODE_PITCH)
            end
          elseif (self.mode == MODE_VELOCITY) then
            if self.seq:set_velocity(control_index,math.floor(obj.value*127),update) then
              self:schedule_output(control_index,MODE_VELOCITY)
            end
          elseif (self.mode == MODE_OFFSET) then
            if self.seq:set_offset(control_index,math.floor(obj.value*255),update) then
              self:schedule_output(control_index,MODE_OFFSET)
            end
          elseif (self.mode == MODE_GATE) then
            if self.seq:set_gate(control_index,math.floor(obj.value*255),update) then
              self:schedule_output(control_index,MODE_GATE)
            end
          elseif (self.mode == MODE_RETRIG) then
            local val_exp = math.floor(self.seq:scale_exp(obj.value,1,4)*NOW_Sequence.MAX_RETRIGS)
            if self.seq:set_retrig(control_index,val_exp,update) then
              self:schedule_output(control_index,MODE_RETRIG)
            end
          end
          self.step_focus = control_index
          self.touched = true
        end 
        self._controls.multi_sliders[control_index] = c
      end
    end
  end

  local set_multi = function(val)
    local ctrl = self._controls.multi_adjust
    if ctrl then
      ctrl:set_value(val,true)
    end
  end

  --  create 'pitch_adjust' slider
  group_name = self.mappings.pitch_adjust.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      local c = UISlider(self)
      c.group_name = group_name
      c.ceiling = 1
      c:set_pos(self.mappings.pitch_adjust.index or 1)
      c.tooltip = self.mappings.pitch_adjust.description
      c.on_change = function(obj) 
        self.touched = true
        --self:change_mode(MODE_PITCH,true)
        if self.seq:adjust_pitch(obj.value) then
          self:schedule_output(nil,MODE_PITCH)
          set_multi(obj.value)
        end
      end 
      self._controls.pitch_adjust = c
    end
  end

  --  create 'velocity_adjust' slider
  group_name = self.mappings.velocity_adjust.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      local c = UISlider(self)
      c.group_name = group_name
      c.ceiling = 1
      c:set_pos(self.mappings.velocity_adjust.index or 1)
      c.tooltip = self.mappings.velocity_adjust.description
      c.on_change = function(obj) 
        self.touched = true
        --self:change_mode(MODE_VELOCITY,true)
        if self.seq:adjust_velocity(obj.value) then
          self:schedule_output(nil,MODE_VELOCITY)
          set_multi(obj.value)
        end
      end 
      self._controls.velocity_adjust = c
    end
  end

  --  create 'offset_adjust' slider
  group_name = self.mappings.offset_adjust.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      local c = UISlider(self)
      c.group_name = group_name
      c.ceiling = 1
      c:set_pos(self.mappings.offset_adjust.index or 1)
      c.tooltip = self.mappings.offset_adjust.description
      c.on_change = function(obj) 
        self.touched = true
        --self:change_mode(MODE_OFFSET,true)
        if self.seq:adjust_offset(obj.value) then
          self:schedule_output(nil,MODE_OFFSET)
          set_multi(obj.value)
        end
      end 
      self._controls.offset_adjust = c
    end
  end

  --  create 'gate_adjust' slider
  group_name = self.mappings.gate_adjust.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      local c = UISlider(self)
      c.group_name = group_name
      c.ceiling = 1
      c.tooltip = self.mappings.gate_adjust.description
      c:set_pos(self.mappings.gate_adjust.index or 1)
      c.on_change = function(obj) 
        self.touched = true
        --self:change_mode(MODE_GATE,true)
        if self.seq:adjust_gate(obj.value) then
          self:schedule_output(nil,MODE_GATE)
          set_multi(obj.value)
        end
      end 
      self._controls.gate_adjust = c
    end
  end

  --  create 'retrig_adjust' slider
  group_name = self.mappings.retrig_adjust.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      local c = UISlider(self)
      c.group_name = group_name
      c.ceiling = 1
      c:set_pos(self.mappings.retrig_adjust.index or 1)
      c.tooltip = self.mappings.retrig_adjust.description
      c.on_change = function(obj) 
        self.touched = true
        local val_exp = self.seq:scale_exp(obj.value,1,4)
        if self.seq:adjust_retrig(val_exp) then
          self:schedule_output(nil,MODE_RETRIG)
          set_multi(val_exp)
        end
      end 
      self._controls.retrig_adjust = c
    end
  end

  --  create 'multi_adjust' slider
  group_name = self.mappings.multi_adjust.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      local c = UISlider(self)
      c.group_name = group_name
      c.ceiling = 1
      c:set_pos(self.mappings.multi_adjust.index or 1)
      c.tooltip = self.mappings.multi_adjust.description
      c:set_value(0)
      c.on_change = function(obj) 
        self.touched = true

        local update = true
        if self.seq:adjust_multi(obj.value,update) then
          self:schedule_output(nil,self.mode)
        end

      end 
      self._controls.multi_adjust = c
    end
  end

  -- create 'num_steps' slider (supports grid mode)
  group_name = self.mappings.num_steps.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      local c = UISlider(self)
      c.group_name = group_name
      c.ceiling = 12
      local gridbased = cm:is_grid_group(self.mappings.num_steps.group_name)
      if gridbased then
        local orientation = self.mappings.num_steps.orientation or ORIENTATION.HORIZONTAL
        c.flipped = true
        c:set_orientation(orientation)
        c:set_size(12)
      end
      c:set_pos(self.mappings.num_steps.index or 1)
      c.tooltip = self.mappings.num_steps.description
      c:set_value(0)
      c.on_change = function(obj) 
        self.touched = true
        if (self.seq:set_num_steps(math.floor(obj.value))) then
          self:schedule_output(self.step,self.mode)
        end
      end 
      self._controls.num_steps = c
    end
  end

  -- create 'step_spacing' slider
  group_name = self.mappings.step_spacing.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      local c = UISlider(self)
      c.group_name = group_name
      c:set_pos(self.mappings.step_spacing.index or 1)
      c.tooltip = self.mappings.step_spacing.description
      c.ceiling = NOW_Sequence.MAX_LINE_SPACING
      c:set_value(NOW_Sequence.DEFAULT_STEP_SPACING)
      c.on_change = function(obj) 
        self.touched = true
        if (self.seq:set_spacing(math.floor(obj.value))) then
          self:schedule_output()
        end
      end 
      self._controls.step_spacing = c
    end
  end

  -- create 'write' button
  group_name = self.mappings.write.group_name
  if group_name then
    local update_button = function()
      if self.write_mode then
        self._controls.write:set(self.palette.write_on)
      else
        self._controls.write:set(self.palette.write_off)
      end
    end
    local group = cm.groups[group_name]
    if group then
      local c = UIButton(self)
      c.group_name = self.mappings.write.group_name
      c.tooltip = self.mappings.write.description
      c:set_pos(self.mappings.write.index or 1)
      c:set(self.palette.write_off)
      c.on_press = function(obj) 
        self.write_mode = not self.write_mode
        self.touched = false
        update_button()
      end
      c.on_release = function()
        --obj:set(self.write_mode,true)
        update_button()
      end
      self._controls.write = c    
    end
  end

  -- create 'learn' button
  group_name = self.mappings.learn.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      local c = UIButton(self)
      c.group_name = self.mappings.learn.group_name
      c.tooltip = self.mappings.learn.description
      c:set_pos(self.mappings.learn.index or 1)
      c:set(self.palette.learn_off)
      c.on_press = function(obj) 
        self:reset_adjustments()
        self.seq:learn_sequence()
        --obj:set_palette({background = {text=self.TEXT_LEARN_ON,color={0xFF,0xFF,0xFF}}})
        obj:set(self.palette.learn_on)
      end
      c.on_hold = function(obj)
        self:disable_write_mode()
        self.autolearn = true
        self.just_entered_autolearn = true
      end
      c.on_release = function()
        if not self.just_entered_autolearn then
          self.autolearn = false
          --[[
          obj:set_palette({background = {text=self.TEXT_LEARN_OFF,color={0x00,0x00,0x00}}})
          obj:set(false,true)
          ]]
          self._controls.learn:set(self.palette.learn_off)
        else
          self.just_entered_autolearn = false
        end
      end
      self._controls.learn = c    
    end
  end

  -- create 'fill' button
  group_name = self.mappings.fill.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      local update_button = function()
        if self.fill_mode then
          self._controls.fill:set(self.palette.fill_on)
        else
          self._controls.fill:set(self.palette.fill_off)
        end
      end
      local c = UIButton(self)
      c.group_name = self.mappings.fill.group_name
      c.tooltip = self.mappings.fill.description
      c:set_pos(self.mappings.fill.index or 1)
      c.on_press = function() 
        self.fill_mode = not self.fill_mode
        update_button()
      end
      self._controls.fill = c    
      update_button()
    end
  end

  -- create 'global' button
  group_name = self.mappings.global.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      local update_button = function()
        if self.global_mode then
          self._controls.global:set(self.palette.global_on)
        else
          self._controls.global:set(self.palette.global_off)
        end
      end
      local c = UIButton(self)
      c.group_name = self.mappings.global.group_name
      c.tooltip = self.mappings.global.description
      c:set_pos(self.mappings.global.index or 1)
      c.on_press = function(obj) 
        self.global_mode = not self.global_mode
        update_button()
      end
      self._controls.global = c    
      update_button()
    end
  end

  -- create 'shift_up' button
  group_name = self.mappings.shift_up.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      local c = UIButton(self)
      c.group_name = self.mappings.shift_up.group_name
      c.tooltip = self.mappings.shift_up.description
      c:set_pos(self.mappings.shift_up.index or 1)
      c:set(self.palette.shift_up_off)
      c.on_press = function(obj) 
        self.touched = true
        self:shift(1) 
        self:output_sequence(self.step)
        self._controls.shift_up:flash(
          0.1,self.palette.shift_up_on,self.palette.shift_up_off)
      end
      self._controls.shift_up = c    
    end
  end

  -- create 'shift_down' button
  group_name = self.mappings.shift_down.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      local c = UIButton(self)
      c.group_name = self.mappings.shift_down.group_name
      c.tooltip = self.mappings.shift_down.description
      c:set_pos(self.mappings.shift_down.index or 1)
      c:set(self.palette.shift_down_off)
      c.on_press = function(obj) 
        self.touched = true
        self:shift(-1) 
        self:output_sequence(self.step)
        self._controls.shift_down:flash(
          0.1,self.palette.shift_down_on,self.palette.shift_down_off)
      end
      self._controls.shift_down = c    
    end
  end

  -- create 'extend' button
  group_name = self.mappings.extend.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      local c = UIButton(self)
      c.group_name = self.mappings.extend.group_name
      c.tooltip = self.mappings.extend.description
      c:set_pos(self.mappings.extend.index or 1)
      c:set(self.palette.extend_off)
      c.on_press = function(obj) 
        self.touched = true
        if self.seq:extend() then
          self:output_sequence(self.step)
        end
      end
      self._controls.extend = c    
    end
  end

  -- create 'shrink' button
  group_name = self.mappings.shrink.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      local c = UIButton(self)
      c.group_name = self.mappings.shrink.group_name
      c.tooltip = self.mappings.shrink.description
      c:set_pos(self.mappings.shrink.index or 1)
      c:set(self.palette.shrink_off)
      c.on_press = function(obj) 
        self.touched = true
        if self.seq:shrink() then
          self:output_sequence(self.step)
        end
      end
      self._controls.shrink = c    
    end
  end

  -- create 'set_mode_pitch' button
  group_name = self.mappings.set_mode_pitch.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      local c = UIButton(self)
      c.group_name = self.mappings.set_mode_pitch.group_name
      c.tooltip = self.mappings.set_mode_pitch.description
      c:set_pos(self.mappings.set_mode_pitch.index or 1)
      c:set(self.palette.set_pitch_on)
      c.on_press = function(obj) 
        self:change_mode(MODE_PITCH)

      end
      c.on_hold = function(obj)
        self.touched = true
        self.fill_mode = true
        self:output_sequence(nil,MODE_PITCH,nil,true)
        self.fill_mode = false
      end
      self._controls.set_mode_pitch = c   
    end
  end

  -- create 'set_mode_velocity' button
  group_name = self.mappings.set_mode_velocity.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      local c = UIButton(self)
      c.group_name = self.mappings.set_mode_velocity.group_name
      c.tooltip = self.mappings.set_mode_velocity.description
      c:set_pos(self.mappings.set_mode_velocity.index or 1)
      c:set(self.palette.set_velocity_off)
      c.on_press = function(obj) 
        self:change_mode(MODE_VELOCITY)

      end
      c.on_hold = function(obj)
        self.touched = true
        self.fill_mode = true
        self:output_sequence(nil,MODE_VELOCITY,nil,true)
        self.fill_mode = false
      end
      self._controls.set_mode_velocity = c    
    end
  end

  -- create 'set_mode_offset' button
  group_name = self.mappings.set_mode_offset.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      local c = UIButton(self)
      c.group_name = self.mappings.set_mode_offset.group_name
      c.tooltip = self.mappings.set_mode_offset.description
      c:set_pos(self.mappings.set_mode_offset.index or 1)
      c:set(self.palette.set_offset_off)
      c.on_press = function(obj) 
        self:change_mode(MODE_OFFSET)

      end
      c.on_hold = function(obj)
        self.touched = true
        self.fill_mode = true
        self:output_sequence(nil,MODE_OFFSET,nil,true)
        self.fill_mode = false
      end
      self._controls.set_mode_offset = c    
    end
  end

  -- create 'set_mode_gate' button
  group_name = self.mappings.set_mode_gate.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      local c = UIButton(self)
      c.group_name = self.mappings.set_mode_gate.group_name
      c.tooltip = self.mappings.set_mode_gate.description
      c:set_pos(self.mappings.set_mode_gate.index or 1)
      c:set(self.palette.set_gate_off)
      c.on_press = function(obj) 
        self:change_mode(MODE_GATE)

      end
      c.on_hold = function(obj)
        self.touched = true
        self.fill_mode = true
        self:output_sequence(nil,MODE_GATE,nil,true)
        self.fill_mode = false
      end
      self._controls.set_mode_gate = c    
    end
  end

  -- create 'set_mode_retrig' button
  group_name = self.mappings.set_mode_retrig.group_name
  if group_name then
    local group = cm.groups[group_name]
    if group then
      local c = UIButton(self)
      c.group_name = self.mappings.set_mode_retrig.group_name
      c.tooltip = self.mappings.set_mode_retrig.description
      c:set_pos(self.mappings.set_mode_retrig.index or 1)
      c:set(self.palette.set_retrig_off)
      c.on_press = function(obj) 
        self:change_mode(MODE_RETRIG)

      end
      c.on_hold = function(obj)
        self.touched = true
        self.fill_mode = true
        self:output_sequence(nil,MODE_RETRIG,nil,true)
        self.fill_mode = false
      end
      self._controls.set_mode_retrig = c    
    end
  end

  Application._build_app(self)
  return true

end

-------------------------------------------------------------------------------

--- reset adjustments
-- will apply the default adjustment for each parameter,
-- and update the display (dedicated/multi-control) 

function NotesOnWheels:reset_adjustments()
  TRACE("NotesOnWheels:reset_adjustments()")
  
  local c = nil
  local skip_event = true
  local multi_adj = self._controls.multi_adjust
  
  -- pitch set to middle position
  c = self._controls.pitch_adjust
  if c then
    local val = self.seq.DEFAULT_PITCH_ADJUST
    c:set_value(val,skip_event)
    self.seq.pitch_adjust = val
    self.seq.transpose = 0
    if (self.mode==MODE_PITCH) then
      if multi_adj then
        multi_adj:set_value(val,skip_event)
      end
    end
  end
  -- velocity turned up
  c = self._controls.velocity_adjust
  if c then
    local val = self.seq.DEFAULT_VELOCITY_ADJUST
    c:set_value(val,skip_event)
    self.seq.velocity_adjust = self.seq.DEFAULT_VELOCITY_ADJUST
    if (self.mode==MODE_VELOCITY) then
      if multi_adj then
        multi_adj:set_value(val,skip_event)
      end
    end
  end
  -- offset turned down
  c = self._controls.offset_adjust
  if c then
    local val = self.seq.DEFAULT_OFFSET_ADJUST
    c:set_value(val,skip_event)
    self.seq.offset_adjust = val
    if (self.mode == MODE_OFFSET) then
      if multi_adj then
        multi_adj:set_value(val,skip_event)
      end
    end
  end
  -- gate turned up
  c = self._controls.gate_adjust
  if c then
    local val = self.seq.DEFAULT_GATE_ADJUST
    c:set_value(val,skip_event)
    self.seq.gate_adjust = val
    if (self.mode == MODE_GATE) then
      if multi_adj then
        multi_adj:set_value(val,skip_event)
      end
    end
  end
  -- retrig turned down
  c = self._controls.retrig_adjust
  if c then
    local val = self.seq.DEFAULT_RETRIG_ADJUST
    c:set_value(val,skip_event)
    self.seq.retrig_adjust = val
    if (self.mode==MODE_RETRIG) then
      if multi_adj then
        multi_adj:set_value(val,skip_event)
      end
    end
  end

end

--==============================================================================

class 'NOW_Sequence'

NOW_Sequence.DEFAULT_STEP_SPACING = 2
NOW_Sequence.DEFAULT_NUM_STEPS = 4
NOW_Sequence.MAX_LINE_SPACING = 16
NOW_Sequence.MAX_RETRIGS = 64
NOW_Sequence.MAX_NUM_STEPS = 12

-- default values for new sequences
NOW_Sequence.DEFAULT_PITCH_VALUE = -1 -- disabled note
NOW_Sequence.DEFAULT_VELOCITY_VALUE = 127 -- full volume
NOW_Sequence.DEFAULT_OFFSET_VALUE = 0 -- play from the beginning
NOW_Sequence.DEFAULT_GATE_VALUE = 255 -- fully open gate
NOW_Sequence.DEFAULT_RETRIG_VALUE = 0 -- no retriggering

-- initial position for adjustment faders (between 0-1)
NOW_Sequence.DEFAULT_PITCH_ADJUST = 0.5
NOW_Sequence.DEFAULT_VELOCITY_ADJUST = 1
NOW_Sequence.DEFAULT_OFFSET_ADJUST = 0
NOW_Sequence.DEFAULT_GATE_ADJUST = 1
NOW_Sequence.DEFAULT_RETRIG_ADJUST = 1/NOW_Sequence.MAX_RETRIGS

function NOW_Sequence:__init(owner)
  TRACE("NOW_Sequence:__init()")
  
  local api_version = renoise.API_VERSION
  if (api_version>=3) then
    self.GATE_PAN_LOWER = 3072
    self.GATE_PAN_UPPER = 3087
    self.RETRIG_PAN_LOWER = 6912
    self.RETRIG_PAN_UPPER = 6926
    self.OFFSET_NUM_VALUE = 28
  elseif (api_version>=2) then
    self.GATE_PAN_LOWER = 240
    self.GATE_PAN_UPPER = 255
    self.RETRIG_PAN_LOWER = 224
    self.RETRIG_PAN_UPPER = 240
    self.OFFSET_NUM_VALUE = 9
  end

  -- reference to the main class
  self.owner = owner

  -- flag raised when an 'explicit' length has been defined
  self._explicit_length = nil

  -- integer, quantized sample-offset adjustment
  self.sample_offset = 0

  -- integer, transpose amount
  -- e.g. -12 to transpose an octave down 
  self.transpose = 0

  -- sequence steps
  self.pitch_steps = {}     -- renoise pitch value
  self.velocity_steps = {}  -- renoise volume value
  self.offset_steps = {}    -- renoise sample offset value
  self.gate_steps = {}      -- gate duration (in ticks)
  self.retrig_steps = {}    -- retrig how many times?

  -- parameter adjustment (between 0 and 1)
  self.pitch_adjust = self.DEFAULT_PITCH_ADJUST
  self.velocity_adjust = self.DEFAULT_VELOCITY_ADJUST
  self.offset_adjust = self.DEFAULT_OFFSET_ADJUST
  self.gate_adjust = self.DEFAULT_GATE_ADJUST
  self.retrig_adjust = self.DEFAULT_RETRIG_ADJUST


  self.gate_cached = table.create()

  -- raise this flag when num_lines, spacing or any gate has changed
  self.recalc_gate_cached = true

  -- spacing between notes 
  -- (1 = every line, 2 = every 2nd line, 16 = maximum)
  self.spacing = 1

  -- number of steps in the sequence
  self.num_steps = nil

  -- this is the *actual* number of lines for the sequence,
  -- including step spacing and custom line count
  self.num_lines = nil

  -- setting the length will also un/mute note columns
  self:set_num_steps(self.DEFAULT_NUM_STEPS)

end

-- set value for the various parameters,
-- optionally update the dedicated control
-- @param idx (int, between 1 & #number_of_steps)
-- @param update (bool), update dedicated control 
-- @param multi (bool), update multi-control
-- @return true when changed, false when not

-- @param int_val (int), range 0-121
function NOW_Sequence:set_pitch(idx,int_val,update,multi)
  TRACE("NOW_Sequence:set_pitch",idx,int_val,update,multi)
  int_val = clamp_value(int_val,0,121)
  local display_val = int_val
  if (update or multi) and (self.owner.number_of_slices>0) then
    display_val = self.owner:to_sliced_pitch_range(int_val,true)
  end
  if update then
    self:update_pitch_ctrl(display_val,self.owner._controls.pitch_sliders[idx])
  end
  if multi then
    if (self.owner.mode==MODE_PITCH) then
      self:update_pitch_ctrl(display_val,self.owner._controls.multi_sliders[idx])
    end
  end
  if (int_val == 0) then
    -- the 'real' empty value
    int_val = 121
  end
  if (self.pitch_steps[idx] ~= int_val) then
  	self.pitch_steps[idx] = int_val
    local msg = string.format("Notes On Wheels: Pitch #%d was set to %s",idx,note_pitch_to_value(int_val))
    renoise.app():show_status(msg)
    return true
  else
    return false
  end
end

-- @param int_val (int), range 0-127
function NOW_Sequence:set_velocity(idx,int_val,update,multi)
  TRACE("NOW_Sequence:set_velocity",idx,int_val,update,multi)
  int_val = clamp_value(int_val,0,127)
  if update then
    self:update_velocity_ctrl(int_val,self.owner._controls.velocity_sliders[idx])
  end
  if multi then
    if (self.owner.mode==MODE_VELOCITY) then
      self:update_velocity_ctrl(int_val,self.owner._controls.multi_sliders[idx])
    end
  end
  if (self.velocity_steps[idx] ~= int_val) then
  	self.velocity_steps[idx] = int_val
    local msg = string.format("Notes On Wheels: Velocity #%d was set to %d",idx,int_val)
    renoise.app():show_status(msg)
    return true
  else
    return false
  end
end

-- @param int_val (int) between 0-255
function NOW_Sequence:set_offset(idx,int_val,update,multi)
  TRACE("NOW_Sequence:set_offset",idx,int_val,update,multi)
	int_val = clamp_value(int_val,0,255)

  if update then
    self:update_offset_ctrl(int_val,self.owner._controls.offset_sliders[idx])
  end
  if multi then
    if (self.owner.mode == MODE_OFFSET) then
      self:update_offset_ctrl(int_val,self.owner._controls.multi_sliders[idx])
    end
  end
  if (self.offset_steps[idx] ~= int_val) then
  	self.offset_steps[idx] = int_val
    local msg = string.format("Notes On Wheels: Offset #%d was set to %X",idx,int_val)
    renoise.app():show_status(msg)
    return true
  else
    return false
  end
end

-- @param int_val (int), range 0-255
function NOW_Sequence:set_gate(idx,int_val,update,multi)
  TRACE("NOW_Sequence:set_gate",idx,int_val,update,multi)
	int_val = clamp_value(int_val,0,255)
  if update then
    self:update_gate_ctrl(int_val,self.owner._controls.gate_sliders[idx])
  end
  if multi then
    if (self.owner.mode == MODE_GATE) then
      self:update_gate_ctrl(int_val,self.owner._controls.multi_sliders[idx])
    end
  end
  if (self.gate_steps[idx] ~= int_val) then
  	self.gate_steps[idx] = int_val
    self.recalc_gate_cached = true
    local msg = string.format("Notes On Wheels: Gate #%d was set to %d ticks",idx,int_val)
    renoise.app():show_status(msg)
    return true
  else
    return false
  end
end

-- @param int_val (int), range 0-MAX_RETRIGS
-- @param invert_scale (bool), inverse-scale the value 
function NOW_Sequence:set_retrig(idx,int_val,update,multi)
  TRACE("NOW_Sequence:set_retrig",idx,int_val,update,multi)
  --int_val = clamp_value(int_val,1,NOW_Sequence.MAX_RETRIGS)
  if update or multi then
    local display_val = int_val
    if (int_val>0) then
      display_val = math.floor(self:scale_log(int_val,NOW_Sequence.MAX_RETRIGS))
    end
    if update then
      self:update_retrig_ctrl(display_val,self.owner._controls.retrig_sliders[idx])
    end
    if multi then
      if (self.owner.mode == MODE_RETRIG) then
        self:update_retrig_ctrl(display_val,self.owner._controls.multi_sliders[idx])
      end
    end
  end
  if (self.retrig_steps[idx] ~= int_val) then
  	self.retrig_steps[idx] = int_val
    local msg = string.format("Notes On Wheels: Retrig #%d was set to %d",idx,int_val)
    renoise.app():show_status(msg)
    return true
  else
    return false
  end
end


-- update the various controls, scale values
-- @param int_val (int) the note-value: 0-121, 121==empty
-- @param ctrl (UISlider) 
function NOW_Sequence:update_pitch_ctrl(int_val,ctrl)
  if (ctrl) then
    ctrl:set_value(int_val/121,true)
  end
end

function NOW_Sequence:update_velocity_ctrl(int_val,ctrl)
  if (ctrl) then
    ctrl:set_value(int_val/127,true)
  end
end

function NOW_Sequence:update_offset_ctrl(int_val,ctrl)
  if (ctrl) then
    ctrl:set_value(int_val/255,true)
  end
end

function NOW_Sequence:update_gate_ctrl(int_val,ctrl)
  if (ctrl) then
    ctrl:set_value(int_val/255,true)
  end
end

function NOW_Sequence:update_retrig_ctrl(int_val,ctrl)
  if (ctrl) then
    ctrl:set_value(int_val/NOW_Sequence.MAX_RETRIGS,true)
  end
end

-- set step distance 
-- @param update (bool, when control needs update)
-- @return true when changed, false when not

function NOW_Sequence:set_spacing(int_val,update)
  TRACE("NOW_Sequence:set_spacing",int_val,update)

  if update and self.owner._controls.step_spacing then
    self.owner._controls.step_spacing:set_value(int_val,true)
  end

  if (self.spacing ~= int_val) then

  	self.spacing = int_val
    self.recalc_gate_cached = true
    self:_update_length()

    local msg = string.format("Notes On Wheels: Step distance was set to %d",int_val)
    renoise.app():show_status(msg)
    return true
  else
    return false
  end

end

-- set number of steps in sequence 
-- @param int_val (int) set to this number
-- @param update (bool) update control
-- @return true when changed, false when not

function NOW_Sequence:set_num_steps(int_val,update)
  TRACE("NOW_Sequence:set_num_steps",int_val,update)

  int_val = clamp_value(int_val,1,NOW_Sequence.MAX_NUM_STEPS)

  local skip_event = true
  if update then
    local ctrl = self.owner._controls.num_steps
    if ctrl then
      self.owner._controls.num_steps:set_value(int_val,skip_event)
    end
  end

  if (self.num_steps ~= int_val) then

    self.num_steps = int_val
    self:_update_length()

    -- nullify the focused step if not within bounds 
    if self.owner.step_focus and (self.owner.step_focus>int_val) then
      self.owner.step_focus = nil
    end

    --	supply default values for undefined indices
    for idx = 1,int_val do			
      if(self.pitch_steps[idx]==nil)then
        self:set_pitch(idx,self.DEFAULT_PITCH_VALUE)
      end
      if(self.gate_steps[idx]==nil)then
        self:set_gate(idx,self.DEFAULT_GATE_VALUE)
      end
      if(self.offset_steps[idx]==nil)then
        self:set_offset(idx,self.DEFAULT_OFFSET_VALUE)
      end
      if(self.velocity_steps[idx]==nil)then
        self:set_velocity(idx,self.DEFAULT_VELOCITY_VALUE)
      end
      if(self.retrig_steps[idx]==nil)then
        self:set_retrig(idx,self.DEFAULT_RETRIG_VALUE)
      end
    end

    self:mute_columns(int_val)

    local msg = string.format("Notes On Wheels: Number of steps was set to %d",int_val)
    renoise.app():show_status(msg)
    return true
  else
    return false
  end


end

function NOW_Sequence:mute_columns(idx)

    --	mute/unmute note columns
    -- prevent from writing in master/send track 
    local track_idx = renoise.song().selected_track_index
    if (track_idx<get_master_track_index()) then
      for i = 1,12 do
        local muted = (i > idx)
        renoise.song().tracks[track_idx]:mute_column(i, muted)
      end
    end

end

-- TODO set sequence to specific number of lines
-- @param update (bool, when control needs update)
-- @return true when changed, false when not
--[[
function NOW_Sequence:set_num_lines(int_val,update)

  self._explicit_length = true

  if (self.num_lines ~= int_val) then
    self.num_lines = int_val
    self.recalc_gate_cached = true
    local msg = string.format("Number of lines was set to %d",int_val)
    renoise.app():show_status(msg)
    return true
  else
    return false
  end

end

]]

-- adjust value (when using controller)
-- @param val (number) between 0-1
-- @param update (bool) update control
-- @return bool (true when adjusted)

function NOW_Sequence:adjust_pitch(val,update)
  TRACE("NOW_Sequence:adjust_pitch()",val,update)

  -- when instrument is sliced, ignore pitch adjustment
  if (self.owner.number_of_slices>0) then
    local msg = string.format("Notes On Wheels: Transpose is disabled when sample is sliced")
    renoise.app():show_status(msg)
    return false
  end

  -- adjust +/- 12 semitones
  local semitones = math.floor((val-0.49)*24)
  if (self.transpose ~= semitones) then
    local ctrl = self.owner._controls.pitch_adjust
    if update and ctrl then
      ctrl:set_value(val)
    end
    self.pitch_adjust = val
    self.transpose = semitones
    local msg = string.format("Notes On Wheels: Pitch transposed by %d semitones",semitones)
    renoise.app():show_status(msg)
    return true
  else
    return false
  end
end

function NOW_Sequence:adjust_velocity(val,update)
  TRACE("NOW_Sequence:adjust_velocity()",val,update)
  if (self.velocity_adjust ~= val) then
    local ctrl = self.owner._controls.velocity_adjust
    if update and ctrl then
      ctrl:set_value(val)
    end
    self.velocity_adjust = val
    local msg = string.format("Notes On Wheels: Master-velocity set to %d%%",(val*100))
    renoise.app():show_status(msg)
    return true
  else
    return false
  end
end

function NOW_Sequence:adjust_offset(val,update)
  TRACE("NOW_Sequence:adjust_offset()",val,update)
  local sample_offset = self:to_discrete_steps(math.floor(val*256))
  if (self.sample_offset ~= sample_offset) then
    local ctrl = self.owner._controls.offset_adjust
    if update and ctrl then
      ctrl:set_value(val)
    end
    self.offset_adjust = 1+(sample_offset-256)/256
    self.sample_offset = sample_offset
    local msg = string.format("Notes On Wheels: Sample-offset shifted by %X",sample_offset)
    renoise.app():show_status(msg)
    return true
  else
    return false
  end
end

function NOW_Sequence:adjust_gate(val,update)
  TRACE("NOW_Sequence:adjust_gate()",val,update)
  if (self.gate_adjust ~= val) then
    local ctrl = self.owner._controls.gate_adjust
    if update and ctrl then
      ctrl:set_value(val)
    end
    self.gate_adjust = val
    self.recalc_gate_cached = true
    local msg = string.format("Notes On Wheels: Note duration set to %d%%",(val*100))
    renoise.app():show_status(msg)
    return true
  else
    return false
  end
end

function NOW_Sequence:adjust_retrig(val,update)
  TRACE("NOW_Sequence:adjust_retrig()",val,update)
  local ctrl = self.owner._controls.retrig_adjust
  local skip_event = true
  if update and ctrl then
    local display_val = val
    if (val>0) then
      display_val = self:scale_log(val*NOW_Sequence.MAX_RETRIGS,NOW_Sequence.MAX_RETRIGS,4)/NOW_Sequence.MAX_RETRIGS
    end
    ctrl:set_value(display_val,skip_event)
  end
  -- convert value to integer range to detect if changed
  local val1 = math.floor(NOW_Sequence.MAX_RETRIGS*val)
  local val2 = math.floor(NOW_Sequence.MAX_RETRIGS*self.retrig_adjust)
  if (val1 ~= val2) then
    self.retrig_adjust = math.max(val,1/NOW_Sequence.MAX_RETRIGS)
    local msg = string.format("Notes On Wheels: Retriggering increased by a factor of %d",val*NOW_Sequence.MAX_RETRIGS)
    renoise.app():show_status(msg)
    return true
  else
    return false
  end
end

function NOW_Sequence:adjust_multi(val,update,update_self)
  TRACE("NOW_Sequence:adjust_multi",val,update)
  local ctrl = self.owner._controls.multi_adjust
  if update_self and ctrl then
    ctrl:set_value(val,true)
  end
  if (self.owner.mode == MODE_PITCH) then
    return self:adjust_pitch(val,update)
  elseif (self.owner.mode == MODE_VELOCITY) then
    return self:adjust_velocity(val,update) 
  elseif (self.owner.mode == MODE_OFFSET) then
    return self:adjust_offset(val,update)
  elseif (self.owner.mode == MODE_GATE) then
    return self:adjust_gate(val,update)
  elseif (self.owner.mode == MODE_RETRIG) then
    return self:adjust_retrig(val,update)
  end
end

-- update length automatically 
function NOW_Sequence:_update_length()
  if not self._explicit_length then
    self.num_lines = self:_compute_length()
    self.recalc_gate_cached = true
    TRACE("NOW_Sequence: number of lines was automatically set to",self.num_lines)
  end
end

-- extend the sequence
-- @return true when extended, false if not
function NOW_Sequence:extend()

  if (self.num_steps>6) then
    local msg = string.format("Notes On Wheels: Cannot extend a sequence which is more than 6 steps in length")
    renoise.app():show_status(msg)
    return false
  end

  local num_ticks = self.num_lines * renoise.song().transport.tpl

  for i=1,self.num_steps do

    local new_idx = i+self.num_steps
    local new_pitch = self.pitch_steps[i]
    if (new_pitch==121) then
      new_pitch = 0
    end
    self:set_pitch(new_idx,new_pitch,true,true)
    self:set_velocity(new_idx,self.velocity_steps[i],true,true)
    self:set_offset(new_idx,self.offset_steps[i],true,true)
    self:set_gate(new_idx,self.gate_steps[i],true,true)
    self:set_retrig(new_idx,self.retrig_steps[i],true,true)

  end
  -- update display
  local val_int = math.floor(self.retrig_adjust*NOW_Sequence.MAX_RETRIGS)*2/NOW_Sequence.MAX_RETRIGS
  self:adjust_retrig(clamp_value(val_int,0,1),true)

  self:set_num_steps(self.num_steps*2,true)
  return true

end

-- shrink the sequence
-- @return true when shrunk, false if not
function NOW_Sequence:shrink()

  if (self.num_steps<2) then
    local msg = string.format("Notes On Wheels: Cannot shrink a sequence which is less than 2 steps in length")
    renoise.app():show_status(msg)
    return false
  end

  local val_int = math.floor(self.retrig_adjust*NOW_Sequence.MAX_RETRIGS)/2/NOW_Sequence.MAX_RETRIGS
  self:adjust_retrig(math.max(val_int,NOW_Sequence.DEFAULT_RETRIG_ADJUST),true)

  local new_len = math.ceil(self.num_steps/2)
  self:set_num_steps(new_len,true)
  return true

end

-- calculate the total number of lines, including step spacing
-- this value is used when writing/learning 
function NOW_Sequence:_compute_length()
  return math.max(self.num_steps,(self.spacing*self.num_steps))
end

-- scale value exponentially
function NOW_Sequence:scale_exp(val,range,factor)
  if (val==0) then
    return val
  end 
  local incr = (factor/range)*val
  return math.exp(incr)/(math.exp(factor))*range
end

-- scale value logarithimic
function NOW_Sequence:scale_log(val,range)
  local log_base = range/math.log10(range)
  return (math.log10(val)*log_base)
end

-- return the doubled retrig rate
-- @param val (int) value between 0-64
-- @return (int) also between 0-64
function NOW_Sequence:get_expanded_retrig_rate(val)

    if (val==0) then
      return val
    end
    local new_retrig = ((math.floor(val+1)*2)-1)
    return clamp_value(new_retrig,0,NOW_Sequence.MAX_RETRIGS)
end

-- apply the current adjustment to the provided retrigger value
-- @return (int) between 0-MAX_RETRIGS
function NOW_Sequence:apply_retrig_adjust(val)
  local retrig_adj = math.floor(self.retrig_adjust*NOW_Sequence.MAX_RETRIGS)
  return math.floor(clamp_value(val*retrig_adj+(retrig_adj-1),0,NOW_Sequence.MAX_RETRIGS-1))
end

-- calculate the amount of retriggers
-- @return (int) between 0-MAX_RETRIGS
function NOW_Sequence:get_num_retrigs(val)
  local tmp = renoise.song().transport.tpl/val
  return clamp_value(math.floor(tmp*self.num_lines),0,NOW_Sequence.MAX_RETRIGS)
end

-- get the current pattern sequence position
-- (used when writing to pattern)
-- @return int
function NOW_Sequence:get_pattseq_pos(val)
  if renoise.song().transport.playing then
    return renoise.song().transport.playback_pos.sequence
  else
    return renoise.song().selected_sequence_index
  end
end

-- compute pending pattern's offset based on the current offset
function NOW_Sequence:compute_offset(pat_lines,line_offset)
  local pat_offset = pat_lines-(math.floor(pat_lines/self.num_lines)*self.num_lines)--%pat_lines
  return (line_offset+pat_offset)%self.num_lines

end

-- produce an "Ex" command for the pan column, depending
-- on the current TPL setting. However, not all combination
-- are valid - in such cases, we use the slower value:
-- @param val (int) the retrigger multiplier
-- @return int
function NOW_Sequence:fast_retrigger(val)
  --TRACE("NOW_Sequence:fast_retrigger",val)
  local tmp = renoise.song().transport.tpl/val
  local frac = (fraction(tmp)>0) and 1 or 0
  return self.RETRIG_PAN_LOWER+math.floor(tmp)+frac
end

-- @param val (int) pitch value
-- @param note_column (renoise.NoteColumn object)
-- @param skip_instr (bool) don't set instrument number (for retriggers)
function NOW_Sequence:write_note(val,note_column,skip_instr)
  --TRACE("NOW_Sequence:write_note",val,note_column,skip_instr)
  --local val = self.pitch_steps[offset2]
  local instr_index = renoise.song().selected_instrument_index-1
  if not val or (val==-1) then
    -- skip undefined notes
  elseif(val>120) then
    -- don't adjust when set to note-off or empty 
    note_column.note_value = val
    if not skip_instr then
      note_column.instrument_value = instr_index
    end
  else
    note_column.note_value = clamp_value(val+self.transpose,0,121)		
    if not skip_instr then
      note_column.instrument_value = instr_index
    end
  end
end

-- @param val (int) velocity value
-- @param note_column (renoise.NoteColumn object)
function NOW_Sequence:write_velocity(val,note_column)
  --TRACE("NOW_Sequence:write_velocity",val,note_column)
  if val then
    val = math.floor(val*self.velocity_adjust)
    if not (val==127 or val==255) then
      note_column.volume_value  = clamp_value(val,0,127)
    end
  end
end

-- raise tick value to produce a "Fx" value for the pan column
function NOW_Sequence:ticks_to_notecut(val)
  --TRACE("NOW_Sequence:ticks_to_notecut",val)
	return math.floor(val)+self.GATE_PAN_LOWER
end

-- interpret notecut+line(s), used by learn function
-- @param lines - the number of lines 
-- @param val - the effect value
-- @return number of ticks
function NOW_Sequence:notecut_to_ticks(lines,val)
  --TRACE("NOW_Sequence:notecut_to_ticks",lines,val)
	return (lines*renoise.song().transport.tpl)+(val-self.RETRIG_PAN_LOWER)
end

-- quantize value by the amount specified in options
function NOW_Sequence:to_discrete_steps(val)
  local quant = self.owner.options.offset_quantize.value
  if (quant==1) then
    -- special value, set to full resolution
    quant = 256
  end
  local rslt = math.floor(256/quant)
	rslt = math.floor(val/rslt)*rslt
	return rslt
end

--	clear sequence, update all parameter controls
function NOW_Sequence:clear()
  TRACE("NOW_Sequence:clear")

  local mode = self.owner.mode

	for idx = 1,self.num_steps do
    if self.owner.global_mode then
      self:set_pitch(idx,self.DEFAULT_PITCH_VALUE,true,true)
      self:set_velocity(idx,self.DEFAULT_VELOCITY_VALUE,true,true)
      self:set_offset(idx,self.DEFAULT_OFFSET_VALUE,true,true)
      self:set_gate(idx,self.DEFAULT_GATE_VALUE,true,true)
      self:set_retrig(idx,self.DEFAULT_RETRIG_VALUE,true,true)
    elseif (mode == MODE_PITCH) then
      self:set_pitch(idx,self.DEFAULT_PITCH_VALUE,true,true)
    elseif (mode == MODE_VELOCITY) then
      self:set_velocity(idx,self.DEFAULT_VELOCITY_VALUE,true,true)
    elseif (mode == MODE_OFFSET) then
      self:set_offset(idx,self.DEFAULT_OFFSET_VALUE,true,true)
    elseif (mode == MODE_GATE) then
      self:set_gate(idx,self.DEFAULT_GATE_VALUE,true,true)
    elseif (mode == MODE_RETRIG) then
      self:set_retrig(idx,self.DEFAULT_RETRIG_VALUE,true,true)
    end

	end
end

-- show_note_column
-- called when data is written to the pattern to ensure that columns are visible
function NOW_Sequence:show_note_column(idx)
  --TRACE("NOW_Sequence:show_note_column",idx)
	if idx > renoise.song().selected_track.visible_note_columns then
		renoise.song().selected_track.visible_note_columns = idx
	end
end

-- detect the number of steps in a sequence
-- (note: to detect steps, we need to have specing set first)
-- @param line_idx (int) trigger line
-- @param col_idx (int) trigger column index
-- @param seq_idx (int) position within sequence
-- @return int (null if no steps were detected)

function NOW_Sequence:detect_steps(patt_idx,line_idx,col_idx,seq_idx)
  TRACE("NOW_Sequence:detect_steps",patt_idx,line_idx,col_idx,seq_idx)
  
  local length = 0
  local expected_line = line_idx
  local expected_col = col_idx
  local done = false


  while not done do

    local patt = renoise.song().patterns[patt_idx]
    if not patt then
      --print("done E - no pattern with this pattern index ",patt_idx)
      done = true
      break
    end
    --print("about to iterate through lines in this pattern:",patt_idx,patt.number_of_lines)

    local iter = renoise.song().pattern_iterator:lines_in_pattern_track(
      patt_idx,
      renoise.song().selected_track_index);
    for pos,line in iter do
      if done then
        break
      end
      -- we have reached a trigger line?
      if (pos.line==expected_line)then

        if (length>0 and expected_col==col_idx) then
          --print("done A - we have completed a run, length is ",length)
          done = true
          break
        end
        if (line.note_columns[expected_col])
        and (line.note_columns[expected_col].instrument_value<255) then
          length = length+1
          expected_line = expected_line+self.spacing
          expected_col = expected_col+1
          if (self.spacing==0) then
            -- notes are aligned - simply look across columns
            while line.note_columns[expected_col] 
            and (line.note_columns[expected_col].instrument_value<255) do
              length = length+1
              expected_col = expected_col+1
            end
            --print("done C - all notes aligned on the same line")
            done = true
            break
          end
        else
          --print("done B - no more notes at this column:",expected_col)
          done = true
          break
        end

      end
    
      if (pos.line>=patt.number_of_lines) then
        -- reached last line, check next pattern
        seq_idx = seq_idx+1
        expected_line = expected_line-patt.number_of_lines
        patt_idx = renoise.song().sequencer.pattern_sequence[seq_idx]
        
      end

    end
  end

  return (length>0) and length or nil

end



-- detect the most recent trigger point (backwards,
-- looking inside the currently edited pattern/track) 
-- @param line_idx (int) pattern line
-- @param col_idx (int) note column index
-- @param forwards (bool) look forward (backwards is default)
-- @param seq_idx (int) position within sequence
-- @return int,int (line index, sequence index - both null if no trigger was detected)

function NOW_Sequence:detect_trigger(patt_idx,line_idx,col_idx,forwards,seq_idx)
  TRACE("NOW_Sequence:detect_trigger",patt_idx,line_idx,col_idx,forwards,seq_idx)

  local inst_idx = renoise.song().selected_instrument_index
  local trigger_line = nil -- the line number
  local tmp_seq_idx = seq_idx
  local done = false

  while not done do

    local patt = renoise.song().patterns[patt_idx]
    if not patt then
      --print("done B - no pattern with this pattern index ",patt_idx)
      done = true
      break
    end

    local iter = renoise.song().pattern_iterator:lines_in_pattern_track(
      patt_idx,
      renoise.song().selected_track_index);
    for pos,line in iter do
      if done then
        break
      end
      for col_count,note_column in ipairs(line.note_columns) do
        if done then
          break
        end
        local continue = true
        if (forwards) then
          continue = (pos.line>line_idx)
        end
        if continue then
          if (col_count==col_idx) then
            if (note_column.instrument_value<255) then
              if forwards then
                --print("done A - found forwards trigger in this pattern ",patt_idx,"trigger_line",trigger_line)
                return pos.line,tmp_seq_idx
              elseif (pos.line>=line_idx) then
                done = true
                break
              else
                trigger_line = pos.line
              end
            end
          end
        end
      end
    end

    if trigger_line then
      --print("we have completed looking in pattern",patt_idx,", trigger line is ",trigger_line)
      done = true
      break
    end

    tmp_seq_idx = (forwards) and tmp_seq_idx+1 or tmp_seq_idx-1
    patt_idx = renoise.song().sequencer.pattern_sequence[tmp_seq_idx]

  end

  return trigger_line,tmp_seq_idx

end

-- figure out the most likely spacing in the sequence
-- @param line_idx (int) trigger line
-- @param col_idx (int) trigger column
-- @param seq_idx (int) position within sequence
-- @return int (null if spacing couldn't be detected)

function NOW_Sequence:detect_spacing(patt_idx,line_idx,col_idx,seq_idx)
  TRACE("NOW_Sequence:detect_spacing",patt_idx,line_idx,col_idx,seq_idx)

  --local spacing = 0 -- the step spacing
  local spacing = 0 
  local triggered_line = nil
  local triggered_col = 0
  local done = false

  while not done do

    local patt = renoise.song().patterns[patt_idx]
    if not patt then
      --print("done B - no pattern with this pattern index ",patt_idx)
      done = true
      break
    end

    local iter = renoise.song().pattern_iterator:lines_in_pattern_track(
      patt_idx,
      renoise.song().selected_track_index);
    for pos,line in iter do
      if done then
        break
      end
      if (pos.line>=line_idx) then

        for col_count,note_column in ipairs(line.note_columns) do
          -- a trigger is only considered when it arrives 
          -- in the note column on the right-hand side,
          -- and contain an instrument value
          if done then
            break
          end
          if (note_column.instrument_value<255) then

            if (col_count>triggered_col) then
              local sp = 0
              if triggered_line then
                sp = pos.line-triggered_line
              end
              if (sp<=self.MAX_LINE_SPACING) then
                if (spacing>0) 
                and (sp==0) then
                  -- we can't have a trigger on the same line, once
                  -- we have had them distributed on different ones
                  done = true
                  --print("done C - new spacing encountered")
                  break
                end
                if triggered_line 
                and (pos.line>triggered_line+sp)
                or (col_count>triggered_col+1) then
                  -- expected column or line was skipped
                  done = true
                  --print("done D - expected column or line was skipped: col_count",col_count,"triggered_col",triggered_col)
                  break
                end
                -- increase count 
                spacing = sp
                --print("spacing is now",spacing)
                triggered_line = pos.line
                triggered_col = col_count
              end
            else
              if (triggered_col>0) then
                -- we have encountered 'stray notes'
                done = true
                --print("done E - stray notes")
                break
              end
            end
          end 
        end -- column loop 
      end
    end -- line loop
    line_idx = 1
    seq_idx = seq_idx+1
    triggered_line = -(patt.number_of_lines-triggered_line)
    patt_idx = renoise.song().sequencer.pattern_sequence[seq_idx]
    --print("check this pattern",patt_idx)

  end

  return spacing

end

-- write_to_pattern
-- @param begin_line (int) from what line to begin output
-- @param patt_idx (int) pattern index
-- @param seq_step (int) optional, limit output to sequence step
-- @param mask_type (int) optional, limit output to parameter
-- @param stream (bool) set when when realtime writing
-- @param recursive (bool) when function call itself, limit to single run 
-- @param line_offset (int) number of lines to offset output by

function NOW_Sequence:write_to_pattern(patt_idx,begin_line,seq_step,mask_type,stream,recursive,line_offset)
  TRACE("NOW_Sequence:write_to_pattern",patt_idx,begin_line,seq_step,mask_type,stream,recursive,line_offset)

  -- prevent from writing in master/send track 
	if (renoise.song().selected_track_index>=get_master_track_index()) then
		return
	end

  local pattern = renoise.song().patterns[patt_idx]
	local tpl = renoise.song().transport.tpl
	local offset = nil
	local set_note,set_gate,set_offset,set_velocity,set_retrig
  local seq_idx = self:get_pattseq_pos()
  local seq_len = self:_compute_length()

  -- A) manual write, output the exact sequence length
  local writeahead_length = self.num_lines-1
  -- B) fill mode, output to entire track
	if self.owner.fill_mode then
    begin_line = 1
		writeahead_length = renoise.Pattern.MAX_NUMBER_OF_LINES
  -- C) stream mode, output in smaller segments,
  --    based on current tempo, lines per beat
  elseif stream or renoise.song().transport.playing then
    local bpm = renoise.song().transport.bpm
    local lpb = renoise.song().transport.lpb
    writeahead_length = math.ceil(math.max(2,(bpm*lpb)/80))
	end
  --print("writeahead_length",writeahead_length)

	if mask_type then
		set_note = (mask_type == MODE_PITCH)
		set_gate = (mask_type == MODE_GATE)
		set_offset = (mask_type == MODE_OFFSET)
		set_velocity = (mask_type == MODE_VELOCITY)
		set_retrig = (mask_type == MODE_RETRIG)
    -- always output note when setting retriggers and vice versa
    if set_retrig then
      set_note = true
    elseif set_note then
      set_retrig = true
    end
	else
		set_note = true
		set_gate = true
		set_offset = true
		set_velocity = true
		set_retrig = true
	end	

  -- compute slow/fast retrigger lookup tables
  -- slow trigger table format : [column].{line,delay} 
  -- fast trigger table is simple numerical 
  local trigger_table = table.create()
  local line_retrigs = table.create()

  if set_retrig then

    for idx = 1,self.num_steps do

      local val = self.retrig_steps[idx]
      if val then

        val = self:apply_retrig_adjust(val)

        -- determine if we are retriggering using Ex (fast), or 
        -- delay commands (slow) - the switch happens when 
        -- the number of retrigged notes are equal to, or more 
        -- than twice the available amount of lines
        if (val>=(self.num_lines*2)) then

          -- fast trigger
          line_retrigs[idx] = math.floor(val/self.num_lines)
          trigger_table:insert({})

        else

          -- slow trigger
          local branch = table.create()
          if(val==0) then 
            -- don't repeat
          elseif (val>=self.num_lines)then
            -- repeat on each line
            for ln=1,self.num_lines do
              branch:insert({line=ln,delay=0})
            end
          else
            local line = 0
            while (line<self.num_lines) do
              line = (self.num_lines/(val+1))*#branch
              local line_adj = math.floor((line+((idx-1)*self.spacing))%self.num_lines)+1
              branch:insert({line=line_adj,delay=fraction(line)})
            end
            branch:remove() -- pop last element
          end
          trigger_table:insert(branch)

        end

      end
    end
  end

  -- bool value for each step, true when gate has been set
  local gates_set = table.create()

  -- create table for note-cut distribution (gate)
  -- format: [column][line_number_within_sequence][tick_value]
  if set_gate then
    if (self.recalc_gate_cached) then
      self.recalc_gate_cached = false
      self.gate_cached = table.create()
      for idx = 1,self.num_steps do
        self.gate_cached[idx] = {}
        local val = self.gate_steps[idx]
        if val then
          val = val*self.gate_adjust


          if val==255 or val==-1 then
            -- don't bother
          elseif(val<tpl) then
            -- insert the notecut right away
            self.gate_cached[idx][((idx-1)*self.spacing)+1] = val
          else
            -- insert the notecut later
            local row_value = math.floor(val/tpl)+1
            if(row_value<=self.num_lines) then
              local target_row = math.floor((row_value+((((idx-1)*self.spacing)+1)-1))%self.num_lines)
              if(target_row==0) then  --fix 
                target_row = self.num_lines
              end
              self.gate_cached[idx][target_row] = val%tpl
            end
          end
        end
      end
    end
  end

	local iter = renoise.song().pattern_iterator:lines_in_pattern_track(
		patt_idx,
		renoise.song().selected_track_index);
	for pos,line in iter do
    -- begin output from this line
		if(pos.line>=begin_line) then
			if(writeahead_length<0) then
        -- stop after writeahead
				break
			else
        
        local offset_line = pos.line+line_offset

        -- the current line within the sequence
        local seq_line = offset_line%self.num_lines
        if (seq_line==0) then
          seq_line = self.num_lines
        end

        -- 'offset' is the index we use to look up the sequence 
        -- (it can contain a fractional part, like 6.25)
        if (self.spacing>0) then
          offset = offset_line%(self.num_steps*self.spacing)
          offset = ((offset-1)/self.spacing)+1
        else
          offset = offset_line%self.num_steps
        end
        if(offset==0) then  --fix 
          offset = self.num_steps
        end

				--	process note columns 

				for col_index,note_column in ipairs(line.note_columns) do

          -- update only the relevant step/column?
					local continue = true
					if not self.owner.global_mode then
						if seq_step and seq_step ~= col_index then
							continue = false
						end
					end

					if continue then

						local show_column = false       -- we need to display note column
            local show_delay_column = false -- -//-
            local retrig_set = false        -- flag raised when retrig is written
            local is_trigger = nil          -- is this where we trigger the note?

            local retrigs = line_retrigs[col_index] or 0

            -- special case: when notes are aligned next to each other
            local offset2 = offset      -- 
            if (self.spacing == 0) then
              is_trigger = ((offset+col_index-1) == col_index)
              offset2 = col_index
            else 
              is_trigger = (offset==col_index)
            end

            -- todo: clear existing data, based on whether we are in 
            -- global mode (clear all) or not (clear only flagged parms)
            
            if set_note or set_retrig then
              note_column.note_value = 121
              note_column.instrument_value = 255
            end
            if set_velocity then
              note_column.volume_value  = 255
            end
            if set_gate or set_retrig then
              note_column.panning_value = 255
            end
            if set_retrig then
              note_column.delay_value = 0
            end

            -- begin pattern output 
              
            if (is_trigger) then

              -- process active columns
              if (col_index<=self.num_steps) then

                gates_set[col_index] = false

                if set_note then
                  local val = self.pitch_steps[offset2]
                  self:write_note(val,note_column)
                  if (val and val<120) then
                    show_column = true
                  end
                end
                if set_velocity then
                  local val = self.velocity_steps[offset2]
                  self:write_velocity(val,note_column)
                end
                -- retrig before gate (allow gate to overwrite it)
                if set_retrig then
                  if (retrigs>0) then
                    note_column.panning_value = self:fast_retrigger(retrigs)
                    retrig_set = true
                  end
                end
                if set_gate then
                  local val = self.gate_steps[offset2]
                  if val then
                    val = val*self.gate_adjust
                    if val==255 or val==-1 then
                      -- don't bother
                    elseif(val<tpl) then
                      -- insert the notecut right away
                      note_column.panning_value = self:ticks_to_notecut(val)
                      gates_set[col_index] = true
                      show_column = true
                    end
                  end
                end

              end -- active columns
              
            else -- not a trigger point

              -- process active columns
              if (col_index<=self.num_steps) then

                -- determine if note has been cut 
                if set_retrig and (col_index<=self.num_steps) then
                  
                  local gate_pos = nil
                  local gate_val = self.gate_cached[col_index]
                  if gate_val then
                    gate_pos = table.keys(self.gate_cached[col_index])[1]
                  end
                  if gate_pos then 
                    local trigger_pos = ((col_index-1)*self.spacing)+1
                    if (gate_pos<seq_line) then -- after note-cut
                      gates_set[col_index] = true
                      if (gate_pos<trigger_pos) 
                      and (seq_line>trigger_pos) 
                      then -- note has been triggered
                        gates_set[col_index] = false
                      end
                    else -- before note-cut
                      if (seq_line<trigger_pos) then -- before the trigger
                        if (gate_pos<trigger_pos) then -- cut before trigger
                          gates_set[col_index] = false
                        else
                          gates_set[col_index] = true
                        end
                      end
                    end
                  end

                end

                -- write retrigger before gate (allow gate to overwrite)
                if set_retrig and not gates_set[col_index] then

                  local retrig_val = self.retrig_steps[col_index]
                  if retrig_val then
                    retrig_val = self:apply_retrig_adjust(retrig_val)

                    if (retrig_val>0) then
                      if (retrigs>0) then
                        -- 'fast' retriggering using Ex commands 
                        note_column.panning_value = self:fast_retrigger(retrigs)
                        self:write_note(self.pitch_steps[col_index],note_column,true)
                        retrig_set = true
                      else
                        -- 'slow' retriggering using delay commands
                        local trigger = nil
                        if not table.is_empty(trigger_table) then
                          for k,v in ipairs(trigger_table[col_index]) do
                            if v.line and (v.line==seq_line)then
                              trigger = v 
                            end
                          end                    
                        end
                        if trigger then
                          self:write_note(self.pitch_steps[col_index],note_column,true)
                          self:write_velocity(self.velocity_steps[col_index],note_column)
                          note_column.delay_value = trigger.delay * 255
                          show_delay_column = true
                        end

                      end
                    end
                  end
                end -- end set_retrig

                -- write velocity
                if set_velocity and retrig_set and not gates_set[col_index] then
                  local val = self.velocity_steps[col_index]
                  self:write_velocity(val,note_column)
                end

                if set_gate then
                  --	look for scheduled notecut
                  if(self.gate_cached[col_index]) then
                    -- values that exceed the sequence are inserted from the top
                    local line_index = offset_line%self.num_lines
                    if (line_index == 0) then -- fix
                      line_index = self.num_lines
                    end
                    local tmp_value = self.gate_cached[col_index][line_index]
                    if tmp_value then 
                      note_column.panning_value = self:ticks_to_notecut(tmp_value)
                      gates_set[col_index] = true
                      show_column = true
                    end

                  end
                end -- end set_gate

              end -- active columns

            end

            -- show affected columns
            if show_column then
              self:show_note_column(col_index)
            end
            if show_delay_column then
              renoise.song().selected_track.delay_column_visible = true
            end
            if gates_set[col_index] or retrig_set then
              renoise.song().selected_track.panning_column_visible = true
            end

					end

				end -- note columns

				-- process effect columns
				for col_index,fx_column in ipairs(line.effect_columns) do
					if set_offset and col_index == 1 then
            -- first column is sample offset
						local continue = true
            local offset_set = false
            if seq_step and not self.owner.global_mode then
              -- only output a particular step
							if(seq_step~=offset) then
								continue = false
							end
						end 
						if(continue) then

              -- make offset point to the most recent step
              local tmp_offset = offset
              if(math.floor(tmp_offset)==0) then
                tmp_offset = self.num_steps
              end

              local val = self.offset_steps[math.floor(tmp_offset)]

							if val then
								val = self:to_discrete_steps(val)
								-- fix : 256 becoming 0 when wrapped 
								if val==256 then
									val=255
								end
                if (self.owner.options.offset_wrap.value == WRAP_OFFSET_ON) then
  								val = wrap_value(val+(math.floor(self.offset_adjust*255)),0,255)	
                else
                  val = clamp_value(val+(math.floor(self.offset_adjust*255)),0,255)	
                end
								if val ~= 0 then
									fx_column.number_value = self.OFFSET_NUM_VALUE
									fx_column.amount_value = val
                  offset_set = true
								end
							end
              
              -- clear existing
              if not offset_set then
                --[[
                fx_column.number_value = 0
                fx_column.amount_value = 0
                ]]
                fx_column:clear()
              end

            end
					end
				end -- effect columns
			end
			writeahead_length = writeahead_length-1
		end

    -- check if we need to write into another pattern 
    -- (call this function again then, but limited to a single run, 
    -- as the various gate/retrig tables needs to be rebuilt)
    if ((pos.line+1) > pattern.number_of_lines) then
      if not recursive then
        local next_pattern = nil
        local seq_loop_end = renoise.song().transport.loop_end.sequence
        local next_patt_idx = renoise.song().sequencer.pattern_sequence[seq_idx+1]
        --line_offset = 0
        if (renoise.song().transport.loop_pattern) then
          -- same pattern
          self.owner.pending_line_offset = self:compute_offset(pattern.number_of_lines,line_offset) 
          self.owner.pending_seq_pos = seq_idx
          next_patt_idx = renoise.song().sequencer.pattern_sequence[seq_idx]
          next_pattern = renoise.song().patterns[next_patt_idx]
          --print("A) looped pattern - self.owner.pending_line_offset",self.owner.pending_line_offset,"next_patt_idx",next_patt_idx)

        elseif (seq_loop_end==seq_idx) then
          --print("B) pattern loop in effect")
        elseif next_patt_idx then
          --print("C) write to next pattern")
          self.owner.pending_line_offset = self:compute_offset(pattern.number_of_lines,line_offset) 
          self.owner.pending_seq_pos = seq_idx+1
          next_pattern = renoise.song().patterns[next_patt_idx]
        else
          --print("D) skip end of song")
        end
        if next_pattern then
          self:write_to_pattern(next_patt_idx,1,seq_step,mask_type,true,true,self.owner.pending_line_offset)
        end
      end
    end

	end
end

-- learn_sequence() : import a sequence from actual pattern data
function NOW_Sequence:learn_sequence()
  TRACE("NOW_Sequence:learn_sequence()")

  local pos = renoise.song().transport.edit_pos
  local pattern = renoise.song().selected_pattern
  local patt_idx = renoise.song().selected_pattern_index
  local track_idx = renoise.song().selected_track_index
	local begin_line = pos.line
  local line_offset = 0
  local seq_idx = renoise.song().selected_sequence_index --self:get_pattseq_pos()

  -- the actual sequence/pattern index (can be prior to out current pattern)
  local tmp_seq_idx = seq_idx 
  local tmp_patt_idx = patt_idx 

  -- bring focus to the detected instrument once done
  -- (except when it's an empty pattern)
  local detected_instr_index = nil

  -- if pattern-track is empty, clear sequence
  if pattern.tracks[track_idx].is_empty then
    --print("pattern-track is empty, clear sequence")
    self:clear()
    return
  end

  -- pre analysis: detect existing sequence 
  local last_trigger,tmp_seq_idx = self:detect_trigger(patt_idx,begin_line,1,nil,seq_idx)
  --print("last_trigger A",last_trigger,tmp_seq_idx)
  if not last_trigger then
    -- try next trigger instead
    local forwards = true
    last_trigger,tmp_seq_idx = self:detect_trigger(patt_idx,begin_line,1,forwards,seq_idx)
  end
  if last_trigger then
    --print("last_trigger",last_trigger)
    -- detect spacing
    tmp_patt_idx = renoise.song().sequencer.pattern_sequence[tmp_seq_idx]
    local spacing = self:detect_spacing(tmp_patt_idx,last_trigger,1,tmp_seq_idx)
    --print("spacing",spacing)
    if spacing then
      self:set_spacing(spacing,true)
      -- detect the length
      local steps = self:detect_steps(tmp_patt_idx,last_trigger,1,tmp_seq_idx)
      --print("steps",steps)
      if steps then
        self:set_num_steps(steps,true)
        -- with spacing and steps, we are able to figure
        -- out the line offset (the number of lines _missing_ from 
        -- the sequence, when compared to the trigger point)
        local new_len = self.spacing*steps
        if (new_len~=0) then
          -- how many loops can we fit?
          local tmp_line = 0
          local count = 1
          while(tmp_line<last_trigger)do
            tmp_line = new_len*count
            count = count+1
          end
          local tmp_offset = math.abs(tmp_line-(last_trigger-1))
          line_offset = tmp_offset%new_len
          self.owner.line_offset = line_offset
          --print("line_offset",line_offset)
        end
      end
    end
  else
    -- no trigger detected
    local msg = string.format("Notes On Wheels: Learning aborted, could not reliably detect sequence")
    renoise.app():show_status(msg)
    return

  end

  -- now set the start point to our first trigger
  begin_line = last_trigger

  -- slow trigger detection: contain the rate of the first 
  -- matched note on a non-trigger position for each column
  local slow_triggers = table.create()

  local seq_len = self:_compute_length()
	--local val = nil
	local offset = nil
	local get_note,get_gate,get_offset,get_volume,get_retrig
	local readahead_length = self:_compute_length()-1
  --print("readahead_length",readahead_length)

  local steps_learned = 0

	if self.owner.global_mode then
		get_note = true
		get_gate = true
		get_offset = true
		get_volume = true
		get_retrig = true
		self:clear()
	else
		get_note = (self.owner.mode == MODE_PITCH)
		get_gate = (self.owner.mode == MODE_GATE)
		get_offset = (self.owner.mode == MODE_OFFSET)
		get_volume = (self.owner.mode == MODE_VELOCITY)
		get_retrig = (self.owner.mode == MODE_RETRIG)
	end	
  
	local done = false

  while not done do

    local pattern = renoise.song().patterns[tmp_patt_idx]
    if not pattern then
      --print("learn A - no pattern with this pattern index ",tmp_patt_idx)
      done = true
      break
    end

    local iter = renoise.song().pattern_iterator:lines_in_pattern_track(
      tmp_patt_idx,
      renoise.song().selected_track_index);
    for pos,line in iter do
      if(pos.line>=begin_line) then
        if(readahead_length<0) then
          break
        else
          --print("pos.line,self.num_steps",pos.line,self.num_steps)

          -- figure out the sequence step 
          local offset_line = pos.line+line_offset
          if (self.spacing>0) then
            offset = offset_line%(self.num_steps*self.spacing)
            offset = ((offset-1)/self.spacing)+1
          else
            offset = offset_line%self.num_steps
          end
          if (offset == 0) then -- fix
            offset = self.num_steps
          end

          --	process note columns
          for col_index,note_column in ipairs(line.note_columns) do
            if (col_index<=self.num_steps) then

              -- check if spacing is zero (notes aligned on same row)
              local offset2 = offset
              local is_trigger = false
              if (self.spacing == 0) then
                is_trigger = ((offset+col_index-1) == col_index)
                offset2 = col_index
              else 
                is_trigger = (offset == col_index)
              end

              --print("offset2",offset2)
              if is_trigger then
                steps_learned = steps_learned+1

                -- focus to this instrument
                local val = note_column.instrument_value
                if (val<255) then
                  detected_instr_index = note_column.instrument_value+1
                end

                if get_note then
                  --print("get note - pos.line",pos.line,"col_index",col_index,"note_column",note_column)
                  local val = note_column.note_value
                  if (val==121) then
                    val = 0
                  end
                  self:set_pitch(offset2,val,true,true) 
                end
                if get_volume then
                  self:set_velocity(offset2,note_column.volume_value,true,true) 
                end
                if get_gate then
                  local val = note_column.panning_value
                  if (val<self.GATE_PAN_UPPER) and (val>=self.GATE_PAN_LOWER) then
                    self:set_gate(col_index,val-self.GATE_PAN_LOWER,true,true)
                  end
                end
                if get_retrig then
                  local val = note_column.panning_value
                  if (val>self.RETRIG_PAN_LOWER) and (val<self.RETRIG_PAN_UPPER) then
                    -- compute the fast retrigger value, scale logarithmically
                    local val_adj = self:get_num_retrigs(val-self.RETRIG_PAN_LOWER)
                    self:set_retrig(col_index,val_adj,true,true,true)
                  end
                end
              else
                -- non-trigger point position
                if get_gate then
                  local val = note_column.panning_value
                  if (val<self.GATE_PAN_UPPER) and (val>self.GATE_PAN_LOWER) then
                  --if val ~= 255 and val > 239 then
                    local note_line = begin_line+((col_index-1)*self.spacing)
                    local seq_offset = (begin_line+line_offset+1)%seq_len
                    local num_lines = (seq_offset+pos.line-note_line-2)%seq_len
                    self:set_gate(col_index,self:notecut_to_ticks(num_lines,val),true,true)
                  end
                end
                if get_retrig then
                  if not slow_triggers[col_index] then
                    -- check that it's not a retrigger
                    local val = note_column.panning_value
                    if (val==255) or (val<self.RETRIG_PAN_LOWER) or (val>self.RETRIG_PAN_UPPER) then
                      -- position within sequence
                      local seq_line = pos.line+line_offset%self.num_lines
                      if (seq_line==0) then
                        seq_line = self.num_lines
                      end
                      -- look for the first note following a trigger
                      if last_trigger then
                        local matched_line = nil
                        local matched_note_column = nil
                        local next_trigger = last_trigger+((col_index-1)*self.spacing)
                        --print("A -- col_index",col_index,"pos.line",pos.line,"next_trigger",next_trigger)
                        if (pos.line>next_trigger) then
                          -- look from the most recent trigger and forth...
                          --print("look back from next_trigger->seq_line",next_trigger,seq_line)
                          local track_idx = renoise.song().selected_track_index
                          local track = renoise.song().patterns[tmp_patt_idx].tracks[track_idx]
                          for i=next_trigger+1,next_trigger+self.num_lines-1 do
                            if (i>pattern.number_of_lines) then
                              break
                            end
                            local col = track:line(i).note_columns[col_index]
                            local val = col.note_value
                            if val<121 then
                              matched_line = i
                              matched_note_column = col
                              --print("** matched A **",matched_line,matched_note_column)
                              break
                            end
                          end
                          if not matched_note_column then
                            -- there's nothing to find, do not look again
                            slow_triggers[col_index] = true
                            self:set_retrig(col_index,0,true,true)
                          end
                          -- finally, we can compute the number of retriggers
                          if matched_note_column then
                            local delay = matched_note_column.delay_value
                            local local_len = matched_line-next_trigger+(delay/255)
                            --print("next_trigger",next_trigger,"local_len",local_len)
                            local retrigs = math.floor(self.num_lines/local_len)-1
                            slow_triggers[col_index] = true
                            self:set_retrig(col_index,retrigs,true,true,true)
                         end
                        end

                      end -- if last trigger

                    end -- 
                  end
                end -- get_retrig

              end -- non-trigger
            end
          end

          -- process effect columns
          for col_index,fx_column in ipairs(line.effect_columns) do
            if (get_offset and col_index == 1) then
              -- skip 'fractional' offsets
              if (offset==math.floor(offset)) then
                -- rotate the values
                --print("get offset (before wrapping):",fx_column.amount_value)
                self:set_offset(offset,wrap_value(fx_column.amount_value,0,255),true,true) 
              end
            end
          end

        end
        readahead_length = readahead_length-1
      end
    end -- patt iterator
    --print("steps_learned,self.num_steps",steps_learned,self.num_steps)
    if (steps_learned<self.num_steps) then
      if not renoise.song().transport.loop_pattern then
        tmp_seq_idx = tmp_seq_idx+1
      end
      if (tmp_seq_idx>=seq_idx) then
        --print("done F - completed searching pattern",tmp_patt_idx)
      end
      begin_line = 1
      line_offset = self:compute_offset(pattern.number_of_lines,line_offset) 
      tmp_patt_idx = renoise.song().sequencer.pattern_sequence[tmp_seq_idx]
      --print("*** not yet done learning - proceed to this pattern ",tmp_patt_idx)
    else
      --print("done G - completed searching pattern",tmp_patt_idx)
      done = true
      break
    end
    

  end -- not done

  -- set active instrument
  if renoise.song().instruments[detected_instr_index] then
    renoise.song().selected_instrument_index = detected_instr_index
  end

  -- report back what got learned
  local msg = "Notes On Wheels: Learned sequence with %d steps (%s), spacing is %d, line offset is %d"
  local step_vals = ""
  for k,v in ipairs(self.pitch_steps) do
    if(k<=self.num_steps) then
      step_vals = step_vals..(note_pitch_to_value(v))
    end
    if not ((k+1)>self.num_steps) then
      step_vals = step_vals..", "
    end
  end
  msg = string.format(msg,self.num_steps,step_vals,self.spacing,line_offset,self.owner.line_offset)
  renoise.app():show_status(msg)

end
