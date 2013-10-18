--[[----------------------------------------------------------------------------
-- Duplex.Mlrx
-- Inheritance: Application > Mlrx
----------------------------------------------------------------------------]]--

--[[





]]

--==============================================================================

-- constants

local NOTE_OFF = 120
local NUM_GROUPS = 4
local MAX_VELOCITY = 127


--==============================================================================

class 'Mlrx' (Application)

Mlrx.writeahead = nil 
Mlrx.readahead = nil 
Mlrx.metronome_count = nil 
Mlrx.lps = nil -- "lines per second"

Mlrx.default_options = {
  midi_controller = {
    label = "MIDI-Control",
    description = "Specify a secondary MIDI controller for additional mappings",
    items = {
      "None",
    },
    value = 1,
    on_change = function(inst)
      inst:select_midi_port(inst.options.midi_controller.value-1)
    end,
  },

}

Mlrx.available_mappings = {

  -- global

  triggers = {
    description = "Mlrx: Sample triggers",
    greedy = true,
  },
  matrix = {
    description = "Mlrx: Assign tracks to groups",
    greedy = true,
  },
  select_track = {
    description = "Mlrx: Set the active track",
    greedy = true,
  },
  track_labels = {
    description = "Mlrx: Display information about tracks",
    greedy = true,
  },
  erase = {
    description = "Mlrx: Press and release ERASE to erase the entire pattern",
    --[[
    description = "Mlrx: Press ERASE + track-trigger to erase a few lines in a single track," 
    .."\nERASE + group toggle to erase the content of an entire group"
    .."\nPress and release ERASE to erase the entire pattern",
    ]]
  },
  clone = {
    description = "Mlrx: Press and release CLONE to create a duplicate of the current pattern",
  },

  -- mixer

  group_toggles = {
    description = "Mlrx: Toggle group recording/mute state",
    greedy = true,
  },
  group_levels = {
    description = "Mlrx: Adjust output velocity for each group",
    greedy = true,
  },

  -- tracks

  set_mode_loop = {
    description = "Mlrx: Set track to TRIG_LOOP mode",
  },
  set_mode_hold = {
    description = "Mlrx: Set track to TRIG_HOLD mode",
  },
  transpose_up = {
    description = "Mlrx: Transpose up",
  },
  transpose_down = {
    description = "Mlrx: Transpose down",
  },
  toggle_sync = {
    description = "Mlrx: Sync 'sync' in instrument (affects how transpose works)",
  },
  toggle_keys = {
    description = "Mlrx: Toggle 'key transpose'",
  },
  toggle_sample_offset = {
    description = "Mlrx: Toggle the output of 'sample offset' commands",
  },
  toggle_envelope_offset = {
    description = "Mlrx: Toggle the output of 'envelope offset' commands",
  },
  --[[
  cycle_increase = {
    description = "Mlrx: Increase cycle length",
  },
  cycle_decrease = {
    description = "Mlrx: Decrease cycle length",
  },
  ]]
  set_cycle_1 = {
    description = "Mlrx: Set cycle length to full",
  },
  set_cycle_2 = {
    description = "Mlrx: Set cycle length to half",
  },
  set_cycle_4 = {
    description = "Mlrx: Set cycle length to quarter",
  },
  set_cycle_8 = {
    description = "Mlrx: Set cycle length to an eigth",
  },
  set_cycle_16 = {
    description = "Mlrx: Set cycle length to a sixteenth",
  },
  --[[
  next_instr = {
    description = "Mlrx: Select next instrument",
  },
  prev_instr = {
    description = "Mlrx: Select previous instrument",
  },
  focus_instr = {
    description = "Mlrx: Focus instrument in Renoise",
  },
  focus_track = {
    description = "Mlrx: Focus track in Renoise",
  },
  ]]
}

Mlrx.default_palette = {

  group_a   = {color={0xFF,0x00,0x00},val=true},  -- RED
  group_b   = {color={0xFF,0x7F,0x00},val=true},  -- ORANGE
  group_c   = {color={0xFF,0xFF,0x00},val=true},  -- YELLOW
  group_d   = {color={0x00,0xFF,0x00},val=true},  -- GREEN
  group_default = {color={0xFF,0xFF,0xFF},val=true},  -- WHITE
  group_default_off = {color={0x36,0x36,0x36},val=false},  -- DARK GREY / BLACK
  enabled   = {val=true,color={0xFF,0xFF,0xFF}},  
  disabled   = {val=false,color={0x00,0x00,0x00}},

}

--------------------------------------------------------------------------------

--- Constructor method
-- @param (VarArg), see Application to learn more

function Mlrx:__init(...)
  TRACE("Mlrx:__init",...)

  -- (table) available mlrx-tracks (how many depends on controller)
  self.tracks = table.create()

  -- (int) the currently active track (1 - NUM_TRACK, _always_ defined)
  self.selected_track = nil

  -- (table) available mlrx-groups (1 - NUM_GROUPS)
  self.groups = table.create()

  -- (boolean) detect when Renoise toggles playing
  self._playing = renoise.song().transport.playing

  -- (SongPos) store the last playback position in this variable
  -- (to save us from unneeded idle updates)
  self._last_playpos = nil

  -- (int) internally keep track of the number of lines in the
  -- currently playing pattern (used for metronome/blinking)
  self._patt_num_lines = nil

  -- (int) when application is first run, check the
  -- controller to see how many slices we can offer 
  self._num_divisions = nil

  -- keep reference to UI controls here
  self._controls = table.create()
  self._controls.triggers = table.create()
  self._controls.matrix = table.create()
  self._controls.track_labels = table.create()
  self._controls.group_toggles = table.create()
  self._controls.group_levels = table.create()

  -- extend default options with the available midi ports
  local input_devices = renoise.Midi.available_input_devices()
  local options = select(3,...)
  local items = Mlrx.default_options.midi_controller.items
  for k,v in ipairs(input_devices) do
    items[k+1] = v
    options.midi_controller.items[k+1] = v
  end

  Application.__init(self,...)

  -- set up external midi control
  self.midi_in = nil
  self:select_midi_port(self.options.midi_controller.value-1)

end

--------------------------------------------------------------------------------

-- perform periodic updates

function Mlrx:on_idle()

  if not self.active then
    return
  end

  local rns = renoise.song()

  --print("self._playing",self._playing)
  local playing = rns.transport.playing
  local playpos = Mlrx_pos(rns.transport.playback_pos)

  if playing and
    (playpos ~= self._last_playpos) 
  then

    --print("playpos",playpos)

    for _,g in ipairs(self.groups) do
      if (#g.tracks > 0) then
        g:group_output(true)
      end
    end

    -- update stuff that is synchronized to the metronome 
    if not self._last_playpos or (playpos.sequence ~= self._last_playpos.sequence) then
      -- switched pattern, check the pattern length
      local patt_idx = rns.sequencer.pattern_sequence[playpos.sequence]
      local patt = rns:pattern(patt_idx)
      self._patt_num_lines = patt.number_of_lines
      --print("self._patt_num_lines",self._patt_num_lines)
    end

    local update_blink = false
    local tmp = (math.floor((playpos.line-1)/Mlrx.metronome_count)%2 == 0) and true or false
    if (tmp ~= self._metronome_blink) then
      self._metronome_blink = tmp
      update_blink = true
    end
    if update_blink then
      self:update_group_toggles()
    end

  end

  self._last_playpos = Mlrx_pos(rns.transport.playback_pos)

  if (not playing and playing ~= self._playing) then
    -- when we stop playing
    self._last_playpos = nil
    self:panic()
  end

  


  self._playing = playing

end

--------------------------------------------------------------------------------

-- complete controller display-update 

function Mlrx:update()  
  --TRACE("Mlrx:update()")

  self:update_matrix()
  self:update_group_levels()
  self:update_group_toggles()
  self:update_selected_track()
  self:update_track()

end

--------------------------------------------------------------------------------

-- update of single track display 

function Mlrx:update_track()  
  TRACE("Mlrx:update_track()")

  self:update_linesync()
  self:update_keytoggler()
  self:update_offset_types()
  self:update_trigger_mode()
  self:update_cycle_length()
  self:update_summary()

end

--------------------------------------------------------------------------------

-- start/resume application

function Mlrx:start_app()
  TRACE("Mlrx.start_app()")

  self.selected_track = 1

  if not Application.start_app(self) then
    return
  end

  self:determine_writeahead()
  self:determine_metronome()
  self:update()

end

--------------------------------------------------------------------------------

--- Stop application

function Mlrx:stop_app()
  TRACE("Mlrx:stop_app()")
  
  self:panic()

  Application.stop_app(self)

end


--------------------------------------------------------------------------------

function Mlrx:on_new_document()
  TRACE("Mlrx:on_new_document")
  
  -- import the session, if any...
  self:_attach_to_song()
  
  if (self.active) then
    self:update()
  end

end


--------------------------------------------------------------------------------

-- build_app - called when application is first started
-- @return boolean (false if requirements were not met)

function Mlrx:_build_app()
  TRACE("Mlrx:_build_app(")

  local cm = self.display.device.control_map
  local tool = renoise.tool()

  -- add trigger buttons ----------------------------------
  -- this will create the Mlrx_track instances as well...

  -- check for required mappings
  local map = self.mappings.triggers
  if not map.group_name then
    local msg = "Warning: a required mapping for the application Mlr-x is missing."
    .."Please review the device configuration to ensure that"
    .."the mapping named 'triggers' has been properly defined"
    renoise.app():show_warning(msg)
    return false
  end

  local orientation = map.orientation or HORIZONTAL

  -- determine the number of tracks
  local num_tracks = nil
  if (orientation == HORIZONTAL) then
    num_tracks = cm:count_rows(map.group_name)
  else
    num_tracks = cm:count_columns(map.group_name)
  end
  --print("num_tracks",num_tracks)
  --num_tracks = 4

  -- determine the number of triggers
  if (orientation == HORIZONTAL) then
    self._num_divisions = cm:count_columns(map.group_name)
  else
    self._num_divisions = cm:count_rows(map.group_name)
  end
  --print("self._num_divisions",self._num_divisions)


  for track_idx = 1, num_tracks do

    local trk = Mlrx_track(self)
    trk.divisions = self._num_divisions
    self.tracks[track_idx] = trk

    for trigger_idx = 1, self._num_divisions do
      local c = UIButton(self)
      c.group_name = map.group_name
      c.tooltip = map.description
      c:set_pos(trigger_idx,track_idx)
      c.on_press = function() 
        self.tracks[track_idx]:trigger_press(trigger_idx)
        self:trigger_feedback(track_idx,trigger_idx)
      end
      c.on_release = function() 
        self.tracks[track_idx]:trigger_release(trigger_idx)
      end
      self._controls.triggers:insert(c)
      self:_add_component(c)
    end
  end

  -- group assign -----------------------------------------
  -- TODO confirm required size for group

  local map = self.mappings.matrix
  local ctrl_idx = 1
  for track_idx = 1, #self.tracks do
    for group_index = 1, NUM_GROUPS do
      local c = UIButton(self)
      c.group_name = map.group_name
      c.tooltip = map.description
      c:set_pos(ctrl_idx)
      c.on_press = function() 
        self:assign_track(group_index,track_idx)
      end
      c.on_release = function() 
        --print("matrix on_release")

      end
      self._controls.matrix:insert(c)
      self:_add_component(c)
      --[[
      ]]
      ctrl_idx = ctrl_idx+1
    end
  end

  -- track selector ---------------------------------------
  -- TODO support slider and not just grid mode
  -- if grid-based, check if group is equal to number of tracks

  local map = self.mappings.select_track
  if map.group_name then
    local c = UISlider(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c.orientation = map.orientation
    --c:set_pos(map.index or 1)
    c:set_size(#self.tracks)
    c.palette.track = c.palette.background
    c.flipped = true
    c.value = self.selected_track
    c.on_change = function() 
      --print("select_track on_change,c.value",c.value,"c.index",c.index)
      self:select_track(c.index)
    end
    self._controls.select_track = c
    self:_add_component(c)
  end

  -- group toggles ----------------------------------------

  local map = self.mappings.group_toggles
  for group_index = 1, NUM_GROUPS do
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(group_index)
    c.on_press = function() 
      local grp = self.groups[group_index]
      grp:toggle()
      self:update_group_toggles()
    end
    self._controls.group_toggles:insert(c)
    self:_add_component(c)
  end

  -- group levels -----------------------------------------

  local map = self.mappings.group_levels
  for group_index = 1, NUM_GROUPS do

    if map.group_name then
      local c = UISlider(self)
      c.group_name = map.group_name
      c.tooltip = map.description
      c.ceiling = 1
      c:set_pos(group_index)
      c.on_change = function() 
        --print("group_levels on_change",c.value)
        local grp = self.groups[group_index]
        grp:set_velocity(c.value)
      end
      self._controls.group_levels:insert(c)
      self:_add_component(c)
    end

    local midi_map_name = string.format("Global:Tools:Duplex:Mlrx:Group %d Level [Set]",group_index)
    if not tool:has_midi_mapping(midi_map_name) then
      renoise.tool():add_midi_mapping({
        name = midi_map_name,
        invoke = function(msg)
          if msg:is_abs_value() then
            local grp = self.groups[group_index]
            local val = msg.int_value/127
            grp:set_velocity(val)
            self:update_group_levels()

          end
        end
      })
    end
    --[[
    ]]

  end


  -- erase modifier ---------------------------------------

  local map = self.mappings.erase
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function() 
      --print("ERASE on_press")
    end
    c:set({text="ERASE"})
    c.on_release = function() 
      --print("ERASE on_release - clear pattern")
      
      self:erase_pattern()
      
    end
    self._controls.erase = c
    self:_add_component(c)

  end


  -- clone modifier ---------------------------------------

  local map = self.mappings.clone
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c.on_press = function() 
      --print("CLONE on_press")
    end
    c:set({text="CLONE"})
    c.on_release = function() 
      --print("CLONE on_release - clear pattern")

      -- take a copy of the current pattern 
      local playpos = Mlrx_pos()
      local migrate_playpos = true
      self:clone_pattern(playpos.sequence,migrate_playpos)
      
    end
    self._controls.clone = c
    self:_add_component(c)

  end

  -- track summary ----------------------------------------

  local map = self.mappings.track_labels
  if map.group_name then
    for track_idx = 1, #self.tracks do
      local c = UILabel(self)
      c.group_name = map.group_name
      c.tooltip = map.description
      c:set_pos(track_idx)
      self._controls.track_labels:insert(c)
      self:_add_component(c)
      --print("added track_labels #",track_idx)

    end
  end

  -- track: trigger mode ----------------------------------

  local map = self.mappings.set_mode_loop
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c:set({text="LOOP"})
    c.on_press = function() 
      --print("set_mode_loop on_press")
      local trk = self.tracks[self.selected_track]
      trk:set_trig_mode(Mlrx_track.TRIG_LOOP)
      self:update_track()
    end
    self._controls.set_mode_loop = c
    self:_add_component(c)
    --print("added set_mode_loop")
  end

  local map = self.mappings.set_mode_hold
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c:set({text="HOLD"})
    c.on_press = function() 
      --print("set_mode_hold on_press")
      local trk = self.tracks[self.selected_track]
      trk:set_trig_mode(Mlrx_track.TRIG_HOLD)
      self:update_track()
    end
    self._controls.set_mode_hold = c
    self:_add_component(c)
    --print("added set_mode_hold")
  end

  -- track: offset modes ----------------------------------

  local map = self.mappings.toggle_sample_offset
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c:set({text="Sxx"})
    c.on_press = function() 
      local trk = self.tracks[self.selected_track]
      trk:toggle_sample_offset()
      self:update_track()
    end
    self._controls.toggle_sample_offset = c
    self:_add_component(c)

  end

  local map = self.mappings.toggle_envelope_offset
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c:set({text="Exx"})
    c.on_press = function() 
      local trk = self.tracks[self.selected_track]
      trk:toggle_envelope_offset()
      self:update_track()
    end
    self._controls.toggle_envelope_offset = c
    self:_add_component(c)

  end



  -- track: transpose_up/down -----------------------------

  local map = self.mappings.transpose_up
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c:set({text="♪+"})
    c.on_press = function() 
      --print("transpose_up on_press")
      local trk = self.tracks[self.selected_track]
      --print("trk",trk)
      trk:set_transpose(1)
      self:update_track()
    end
    self._controls.transpose_up = c
    self:_add_component(c)
  end

  local map = self.mappings.transpose_down
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c:set({text="♪-"})
    c.on_press = function() 
      --print("transpose_down on_press")
      local trk = self.tracks[self.selected_track]
      --print("trk",trk)
      trk:set_transpose(-1)
      self:update_track()
    end
    self._controls.transpose_down = c
    self:_add_component(c)
  end

  -- track: instrument sync -------------------------------

  local map = self.mappings.toggle_sync
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c:set({text="BEAT\nSYNC"})
    c.on_press = function() 
      --print("toggle_sync on_press")
      local trk = self.tracks[self.selected_track]
      trk:toggle_sync()
      self:update_track()
    end
    self._controls.toggle_sync = c
    self:_add_component(c)
  end

  -- track: key transpose ---------------------------------

  local map = self.mappings.toggle_keys
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c:set({text="MIDI\nKEYS"})
    c.on_press = function() 
      --print("toggle_sync on_press")
      local trk = self.tracks[self.selected_track]
      trk:toggle_keys()
      self:update_track()
    end
    self._controls.toggle_keys = c
    self:_add_component(c)
  end

  --print("got here 3")

  -- track: cycle_length ----------------------------------

  local map = self.mappings.set_cycle_1
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c:set({text="1/1"})
    c.on_press = function() 
      --print("set_cycle_1 on_press")
      local trk = self.tracks[self.selected_track]
      trk:set_cycle_length(1)
      self:update_track()
    end
    self._controls.set_cycle_1 = c
    self:_add_component(c)
  end

  local map = self.mappings.set_cycle_2
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c:set({text="1/2"})
    c.on_press = function() 
      --print("set_cycle_2 on_press")
      local trk = self.tracks[self.selected_track]
      trk:set_cycle_length(2)
      self:update_track()
    end
    self._controls.set_cycle_2 = c
    self:_add_component(c)
  end

  local map = self.mappings.set_cycle_4
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c:set({text="1/4"})
    c.on_press = function() 
      --print("set_cycle_4 on_press")
      local trk = self.tracks[self.selected_track]
      trk:set_cycle_length(4)
      self:update_track()
    end
    self._controls.set_cycle_4 = c
    self:_add_component(c)
  end

  local map = self.mappings.set_cycle_8
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c:set({text="1/8"})
    c.on_press = function() 
      --print("set_cycle_8 on_press")
      local trk = self.tracks[self.selected_track]
      trk:set_cycle_length(8)
      self:update_track()
    end
    self._controls.set_cycle_8 = c
    self:_add_component(c)
  end

  local map = self.mappings.set_cycle_16
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set_pos(map.index)
    c:set({text="1/16"})
    c.on_press = function() 
      --print("set_cycle_16 on_press")
      local trk = self.tracks[self.selected_track]
      trk:set_cycle_length(16)
      self:update_track()
    end
    self._controls.set_cycle_16 = c
    self:_add_component(c)
  end


  -- finishing touches
  self:create_groups()
  self:_attach_to_song()
  Application._build_app(self)
  return true

end

--------------------------------------------------------------------------------

-- adds notifiers to song
-- invoked when first run, and when a new document becomes available

function Mlrx:_attach_to_song()
  TRACE("Mlrx:_attach_to_song")

  renoise.song().transport.bpm_observable:add_notifier(
    function()
      TRACE("Mlrx:bpm_observable fired...")
      self:determine_writeahead()
    end
  )
  renoise.song().transport.lpb_observable:add_notifier(
    function()
      TRACE("Mlrx:lpb_observable fired...")
      self:determine_writeahead()
    end
  )
  renoise.song().transport.metronome_lines_per_beat_observable:add_notifier(
    function()
      TRACE("Mlrx:metronome_lines_per_beat fired...")
      self:determine_metronome()
    end
  )

  -- observe the instrument list
  renoise.song().instruments_observable:add_notifier(
    function()
      TRACE("Mlrx:instruments_observable fired...")
      self:update_track()
    end
  )

  for trk_idx,trk in ipairs(self.tracks) do
    renoise.song().instruments[trk_idx].name_observable:add_notifier(
      function()
        TRACE("Mlrx:name_observable fired...")
        self:update_summary()
      end
    )
  end


  -- import the session (attach to instruments)
  self:import_session()

end

--------------------------------------------------------------------------------

-- cancel notes in all groups, reset state

function Mlrx:panic()

  for _,g in ipairs(self.groups) do
    g:cancel_notes()
    g.last_triggered = nil
  end


end

--------------------------------------------------------------------------------

function Mlrx:create_groups()
  TRACE("Mlrx:create_groups()")

  for idx=1,NUM_GROUPS do
    self.groups[idx] = Mlrx_group(self)

    local color = nil
    if (idx==1) then
      color = self.palette.group_a.color
    elseif (idx==2) then
      color = self.palette.group_b.color
    elseif (idx==3) then
      color = self.palette.group_c.color
    elseif (idx==4) then
      color = self.palette.group_d.color
    else
      color = self.palette.group_default.color
    end

    self.groups[idx].color = color

  end

end


--------------------------------------------------------------------------------

-- look for an existing session in the song, 
-- or (if not found) initialize a new session

function Mlrx:import_session()
  TRACE("Mlrx:import_session()")

  -- TODO:
  -- look for embedded session,
  -- recycle previously created master group

  -- configure our tracks

  for trk_idx,trk in ipairs(self.tracks) do

    trk.trig_mode = Mlrx_track.TRIG_LOOP
    trk.rns_instr_idx = trk_idx
    trk.rns_track_idx = trk_idx
    trk.mlrx_track_idx = trk_idx
    trk.group = (trk_idx > #self.groups) and self.groups[1] or self.groups[trk_idx]
    trk.do_sample_fx = true
    trk.do_envelope_fx = false
    trk.transpose = 0
    trk.cycle_length = 1 
    trk.group.tracks:insert(trk)
    local sample = trk:get_sample_ref()
    if sample then
      trk.sync_to_lines = sample.beat_sync_lines
      trk:maintain_transpose()
    end

  end



end


--------------------------------------------------------------------------------

function Mlrx:select_track(idx)
  TRACE("Mlrx:select_track()",idx)

  self.selected_track = idx
  self:update_track()

end

--------------------------------------------------------------------------------

-- assign the provided track to this group 
-- (and remove it from it's previous group)

function Mlrx:assign_track(group_idx,track_idx)
  TRACE("Mlrx:assign_track()",group_idx,track_idx)

  -- first, remove the track group-index 
  for trk_idx, t in ipairs(self.tracks) do
    if (trk_idx == track_idx) then
      t.group = nil
    end  
  end

  -- then assign to the provided group
  local track = nil
  for idx, t in ipairs(self.tracks) do
    if (idx == track_idx) then
      track = t
    end
  end
  assert(track,"track not found")
  --print("assign track #",track,"to group #",group)
  track.group = self.groups[group_idx]

  for grp_idx,g in ipairs(self.groups) do
    -- make sure group is up to date
    g:collect_group_tracks(grp_idx)
    -- if this track was the one last triggered
    if (g.last_triggered == track_idx) then
      local group_has_note = false
      for trk_idx, t in ipairs(g.tracks) do
        -- we are only interested in other tracks
        if (trk_idx ~= track_idx) and t.note then
          -- make that one the last triggered
          group_has_note = true
          g.last_triggered = trk_idx
          --print("group has note : last triggered track is now",trk_idx,"grp_idx",grp_idx)
        end
      end 
      if not group_has_note then
        g.last_triggered = nil
        --print("no more active notes in group",grp_idx)
      end
    end
    --print("g.last_triggered",g.last_triggered)
  end

  --[[
  ]]

  -- update display
  self:update_matrix()

end

--------------------------------------------------------------------------------

function Mlrx:erase_pattern()

  local rns = renoise.song()
  local playpos = Mlrx_pos()
  local patt_idx = rns.sequencer.pattern_sequence[playpos.sequence]
  rns:pattern(patt_idx):clear()

end

--------------------------------------------------------------------------------

function Mlrx:clone_pattern(seq_idx,migrate_playpos)

  local rns = renoise.song()
  rns.sequencer:clone_range(seq_idx, seq_idx)

  if migrate_playpos then
    if rns.transport.playing then
      local pos = rns.transport.playback_pos
      pos.sequence = seq_idx+1
      rns.transport.playback_pos = pos
    else
      local pos = rns.transport.edit_pos
      pos.sequence = seq_idx+1
      rns.transport.edit_pos = pos
    end
  end


end

--------------------------------------------------------------------------------

--[[
function Mlrx:retrieve_group_palette(grp_idx)

  if (grp_idx==1) then
    return self.palette.group_a
  elseif (grp_idx==2) then
    return self.palette.group_b
  elseif (grp_idx==3) then
    return self.palette.group_c
  elseif (grp_idx==4) then
    return self.palette.group_d
  end

  return self.palette.group_default

end
]]

--------------------------------------------------------------------------------

-- update visual display of groups assignments

function Mlrx:update_matrix()
  TRACE("Mlrx:update_matrix()")

  local ctrl_idx = 1
  for trk_idx = 1, #self.tracks do
    for grp_idx = 1, NUM_GROUPS do
    
      local grp = self.groups[grp_idx]
      local trk = self.tracks[trk_idx]
      local ctrl = self._controls.matrix[ctrl_idx]
      --print("grp",grp, "trk",trk)
      --print("ctrl",ctrl)

      -- pick among predefined group color
      --local group_palette = self:retrieve_group_palette(grp_idx)
  
      -- alfabetic name A1/B2/C3 etc.
      local bt_title = string.char(64+grp_idx)..trk_idx

      if (trk and trk.group == grp) then   
        ctrl:set({val=true,color=grp.color,text=bt_title})
        --print("active: trk_idx",trk_idx, "grp_idx",grp_idx,", ctrl_idx:",ctrl_idx)
        trk:colorize_track(grp.color)
      else
        ctrl:set({val=false,color=self.palette.group_default_off.color,text=bt_title})
        --trk:colorize_track(self.palette.group_default_off.color)
      end

      ctrl_idx = ctrl_idx+1

    end
  end
  
end

--------------------------------------------------------------------------------

function Mlrx:update_group_toggles()
  TRACE("Mlrx:update_group_toggles()")

  local ctrl = nil
  local rns = renoise.song()
  local enabled = table.rcopy(self.palette.enabled)
  local disabled = self.palette.disabled

  for grp_idx = 1, NUM_GROUPS do
    --local palette = self:retrieve_group_palette(grp_idx)
    local grp = self.groups[grp_idx]
    enabled.color = grp.color
    -- determine if there's an active note
    local grp_active = false
    local grp_muted = false
    for _,trk in ipairs(grp.tracks) do
      if trk.note then
        grp_active = true
      end
      local rns_trk = rns.tracks[trk.rns_track_idx] 
      assert(rns_trk,"track not found")
      if (rns_trk.mute_state ~= MUTE_STATE_ACTIVE) then
        grp_muted = true
        --print("muted track found",trk,trk.rns_track_idx)
      end
    end
    ctrl = self._controls.group_toggles[grp_idx]
    assert(ctrl,"group button not found")
    if grp_active then
      ctrl:set((self._metronome_blink) and enabled or disabled)
    elseif grp_muted then
      ctrl:set(disabled)
    else
      ctrl:set(enabled)
    end
  end

end


--------------------------------------------------------------------------------

function Mlrx:update_group_levels()
  --TRACE("Mlrx:update_group_levels()")

  local ctrl = nil
  local skip_event = true
  for grp_idx = 1, NUM_GROUPS do
    ctrl = self._controls.group_levels[grp_idx]
    if ctrl then
      local val = self.groups[grp_idx].velocity / MAX_VELOCITY
      ctrl:set_value(val,skip_event)
    end

  end

end

--------------------------------------------------------------------------------

-- update visual display of selected track

function Mlrx:update_selected_track()
  TRACE("Mlrx:update_selected_track()")

  if self._controls.select_track then
    self._controls.select_track:set_index(self.selected_track)
  end

end

--------------------------------------------------------------------------------

function Mlrx:get_trigger_ctrl(trk_idx,trigger_idx)

  local trk = self.tracks[trk_idx]
  assert(trk,"Could not locate track")
  
  return self._controls.triggers[trigger_idx+(trk.divisions*(trk_idx-1))]

end

--------------------------------------------------------------------------------

-- update the lit position on the controller, called from the track itself
-- @param trk_idx (int) the index of the Mlrx_track instance
-- @param trigger_idx (int) optional, the position to light up (omit to clear)

function Mlrx:update_trigger_pos(trk_idx,trigger_idx)
  TRACE("Mlrx:update_trigger_pos(trk_idx,trigger_idx)",trk_idx,trigger_idx)

  local trk = self.tracks[trk_idx]
  assert(trk,"Could not locate track")

  -- turn off previous position
  if trk._lit_position then
    local ctrl = self:get_trigger_ctrl(trk_idx,trk._lit_position)
    if ctrl then
      --print("*** update_trigger_pos - disable this index:",trk._lit_position)
      ctrl:set(self.palette.disabled)
    end
    trk._lit_position = nil
  end

  -- light the new one
  if trigger_idx then
    local ctrl = self:get_trigger_ctrl(trk_idx,trigger_idx)
    if ctrl then
      --print("*** update_trigger_pos - enable this index:",trigger_idx)
      --local enabled = self:retrieve_group_palette(trk.group_index)
      local enabled = table.rcopy(self.palette.enabled)
      enabled.color = trk.group.color
      ctrl:set(enabled)
    end
    trk._lit_position = trigger_idx
  end


end

--------------------------------------------------------------------------------

-- provide some quick feedback on the controller (flashing buttons)

function Mlrx:trigger_feedback(trk_idx,trigger_idx)
  --TRACE("Mlrx:trigger_feedback(trk_idx,trigger_idx)",trk_idx,trigger_idx)

  local trk = self.tracks[trk_idx]
  assert(trk,"Could not locate track")

  if (trigger_idx == trk._lit_position) then
    --print("*** trigger_feedback - position is already lit")
    return
  end

  local ctrl = self:get_trigger_ctrl(trk_idx,trigger_idx)
  assert(trk,"Could not locate trigger button")

  local enabled = table.rcopy(self.palette.enabled)
  enabled.color = trk.group.color

  ctrl:flash(0.1,enabled,self.palette.disabled)


end

--------------------------------------------------------------------------------

-- update sync button (light up if sample is synced)

function Mlrx:update_linesync()
  TRACE("Mlrx:update_linesync()")

  local ctrl = self._controls.toggle_sync
  if not ctrl then
    return
  end 

  local trk = self.tracks[self.selected_track]
  assert(trk,"track not found!"..self.selected_track)

  local sample = trk:get_sample_ref()
  if not sample then
    return
  end

  local enabled = self.palette.enabled
  local disabled = self.palette.disabled
  local linesynced = sample.beat_sync_enabled 

  ctrl:set((linesynced) and enabled or disabled)


end

--------------------------------------------------------------------------------

-- update key toggle 

function Mlrx:update_keytoggler()
  TRACE("Mlrx:update_keytoggler()")

  local ctrl = self._controls.toggle_keys
  if not ctrl then
    return
  end 

  local trk = self.tracks[self.selected_track]
  assert(trk,"track not found!"..self.selected_track)

  local enabled = self.palette.enabled
  local disabled = self.palette.disabled


  ctrl:set((trk.apply_key_transpose) and enabled or disabled)

end

--------------------------------------------------------------------------------

-- update display of trigger mode buttons

function Mlrx:update_trigger_mode()
  TRACE("Mlrx:update_trigger_mode()")

  local trk = self.tracks[self.selected_track]
  assert(trk,"Track not found!"..self.selected_track)

  local ctrl = nil
  local enabled = self.palette.enabled
  local disabled = self.palette.disabled

  ctrl = self._controls.set_mode_loop
  if ctrl then
    ctrl:set((trk.trig_mode == Mlrx_track.TRIG_LOOP) and enabled or disabled)
  end

  ctrl = self._controls.set_mode_hold
  if ctrl then
    ctrl:set((trk.trig_mode == Mlrx_track.TRIG_HOLD) and enabled or disabled)
  end

end

--------------------------------------------------------------------------------

-- update display of trigger mode buttons

function Mlrx:update_offset_types()
  TRACE("Mlrx:update_offset_types()")

  local trk = self.tracks[self.selected_track]
  assert(trk,"Track not found!"..self.selected_track)

  local ctrl = nil
  local enabled = self.palette.enabled
  local disabled = self.palette.disabled

  ctrl = self._controls.toggle_sample_offset
  if ctrl then
    ctrl:set((trk.do_sample_fx) and enabled or disabled)
  end

  ctrl = self._controls.toggle_envelope_offset
  if ctrl then
    ctrl:set((trk.do_envelope_fx) and enabled or disabled)
  end

end

--------------------------------------------------------------------------------

-- update display of cycle-length buttons

function Mlrx:update_cycle_length()
  TRACE("Mlrx:update_cycle_length()")

  local trk = self.tracks[self.selected_track]
  assert(trk,"Track not found!"..self.selected_track)

  local ctrl = nil
  local enabled = self.palette.enabled
  local disabled = self.palette.disabled

  ctrl = self._controls.set_cycle_1
  if ctrl then
    ctrl:set((trk.cycle_length == 1) and enabled or disabled)
  end

  ctrl = self._controls.set_cycle_2
  if ctrl then
    ctrl:set((trk.cycle_length == 2) and enabled or disabled)
  end

  ctrl = self._controls.set_cycle_4
  if ctrl then
    ctrl:set((trk.cycle_length == 4) and enabled or disabled)
  end

  ctrl = self._controls.set_cycle_8
  if ctrl then
    ctrl:set((trk.cycle_length == 8) and enabled or disabled)
  end

  ctrl = self._controls.set_cycle_16
  if ctrl then
    ctrl:set((trk.cycle_length == 16) and enabled or disabled)
  end


end

--------------------------------------------------------------------------------

-- update label displaying summary of track(s)

function Mlrx:update_summary()
  TRACE("Mlrx:update_summary()")

  local rns = renoise.song()
  local ctrl = nil
  for i,trk in ipairs(self.tracks) do
    --assert(trk,"Track not found!"..track_idx)
    ctrl = self._controls.track_labels[i]
    if ctrl then
      local str_name = "N/A"
      local str_trig = ""
      local str_cycle = ""
      local str_transpose = ""
      local sample = trk:get_sample_ref()
      if sample then
        str_name = string.format("%.15s",rns.instruments[trk.rns_instr_idx].name)
        str_trig = (trk.trig_mode == Mlrx_track.TRIG_HOLD) and "HOLD" or "LOOP"
        str_cycle = "1/"..trk.cycle_length
        local linesynced = sample.beat_sync_enabled 
        if linesynced then
          str_transpose = string.format("%d/%d lines",sample.beat_sync_lines,sample.beat_sync_lines/trk.cycle_length)
        else
          str_transpose = string.format("%d st",trk.transpose)
        end
      end
      local str_summary = string.format("%02d:%s\n%s, %s, %s",i,str_name,str_trig,str_cycle,str_transpose)
      ctrl:set_text(str_summary)

    end
  end

end


--------------------------------------------------------------------------------

-- obtain the difference in lines between two song-positions
-- note: when the pattern is the same, we ignore the sequence and assume 
-- that pos1 comes before pos2 (so, a 64-line pattern containing two
-- positions: 63 and 1 would result in 2 lines)


function Mlrx:get_pos_diff(pos1,pos2)
  --TRACE("Mlrx:get_pos_diff()",pos1,pos2)

  local rns = renoise.song()
  local patt_idx = rns.sequencer.pattern_sequence[pos1.sequence]
  local patt = rns:pattern(patt_idx)
  local num_lines = patt.number_of_lines

  if (pos1.sequence == pos2.sequence) then
    if (pos1.line > pos2.line) then   
      return num_lines-pos1.line+pos2.line
    else
      return pos2.line-pos1.line
    end
  else
    return num_lines-pos1.line+pos2.line
  end

end

--------------------------------------------------------------------------------

-- get the current quantize amount from renoise
-- @return int (1 or more)

function Mlrx:get_quantize()

  local rns = renoise.song()
  if rns.transport.record_quantize_enabled then
    return rns.transport.record_quantize_lines
  else
    return 1
  end
end

--------------------------------------------------------------------------------

-- expanded check for looped pattern, will also consider if the (currently
-- playing) pattern is looped by means of a pattern sequence loop

function Mlrx:pattern_is_looped()

  local rns = renoise.song()
  if rns.transport.loop_pattern then
    return true
  end

  local seq_idx = rns.transport.playback_pos.sequence
  if (rns.transport.loop_sequence_start == seq_idx) and
    (rns.transport.loop_sequence_end == seq_idx) 
  then
    return true
  end

end

--------------------------------------------------------------------------------

-- @return int (the number of pattern lines), or nil if not found

function Mlrx:count_lines(seq_idx)
  --TRACE("Mlrx:count_lines()",seq_idx)

  local rns = renoise.song()
  local patt_idx = rns.sequencer.pattern_sequence[seq_idx]
  if patt_idx then
    return rns:pattern(patt_idx).number_of_lines
  end

end

--------------------------------------------------------------------------------

-- called whenever tempo has changed

function Mlrx:determine_writeahead()
  TRACE("Mlrx:determine_writeahead()")

  local bpm = renoise.song().transport.bpm
  local lpb = renoise.song().transport.lpb

  -- output buffer size
  Mlrx.writeahead = math.ceil(math.max(1,(bpm*lpb)/300))
  --print("Mlrx.writeahead",Mlrx.writeahead)

  --Mlrx.writeahead = 4

  -- lines-per-second 
  Mlrx.lps = 1 / (60/bpm/lpb)
  --print("Mlrx.lps",Mlrx.lps)

  -- we assume that idle loop is called every 10th of a second,
  -- so we can divide the lines-per-second with this value
  Mlrx.readahead = math.ceil(math.max(1,Mlrx.lps/10))
  --print("Mlrx.readahead",Mlrx.readahead)

end


--------------------------------------------------------------------------------

function Mlrx:determine_metronome()

  local rns = renoise.song()
  local count = rns.transport.metronome_lines_per_beat
  if (count == 0) then
    count = renoise.song().transport.lpb
  end

  Mlrx.metronome_count = count

end


--------------------------------------------------------------------------------

-- initialize MIDI input

function Mlrx:select_midi_port(port_idx)
  TRACE("Mlrx.select_midi_port()",port_idx)

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
      {self, Mlrx.midi_callback}
    )
  end

end


--------------------------------------------------------------------------------

-- receive MIDI from device

function Mlrx:midi_callback(message)
  TRACE("Mlrx:midi_callback",message[1], message[2], message[3])

  -- determine the type of signal : note/cc/etc
  if (message[1]>=128) and (message[1]<=159) then
    print("MIDI_NOTE_MESSAGE")
  elseif (message[1]>=176) and (message[1]<=191) then
    print("MIDI_CC_MESSAGE")
  elseif (message[1]>=224) and (message[1]<=239) then
    print("MIDI_PITCH_BEND_MESSAGE")
  else
    -- unsupported message...
  end

end

--==============================================================================

-- the group takes care of administering updates to it's child tracks
--

class 'Mlrx_group' 

function Mlrx_group:__init(main)

  -- (Mlrx) reference to main application
  self.main = main

  -- (int) the group velocity (between 0-127)
  self.velocity = 127

  -- (int) the color assigned to this group
  self.color = {0xff,0xff,0xff}

  -- (<Mlrx_track...>) updated whenever tracks are reassigned
  self.tracks = table.create()

  -- (int) indicates which track that was last triggered (if any) 
  self.last_triggered = nil


end

--------------------------------------------------------------------------------

-- collect all Mlrx_tracks assigned to this group
-- @param self_idx (int) this group's index, as the main application know it

function Mlrx_group:collect_group_tracks(self_idx)

  self.tracks = table.create()
  for _,trk in ipairs(self.main.tracks) do
    if (trk.group == self) then
      self.tracks:insert(trk)
    end
  end


end

--------------------------------------------------------------------------------

-- compare to another class instance (check for object identity)

function Mlrx_group:__eq(other)
  return rawequal(self, other)
end  

--------------------------------------------------------------------------------

-- this method will call track output in all child tracks
-- @param on_idle (boolean) true when method is invoked by idle loop

function Mlrx_group:group_output(on_idle)
  --TRACE("Mlrx_group:group_output()",on_idle)

  local writeahead = Mlrx.writeahead
  local writepos = Mlrx_pos()
  local wraparound = false

  for _,trk in ipairs(self.tracks) do
    trk:track_output(writepos,writeahead,wraparound,on_idle) 
  end

end

--------------------------------------------------------------------------------

-- specify the group velocity level 
-- @param val (float) value between 0 and 1

function Mlrx_group:set_velocity(val)
  --TRACE("Mlrx_group:set_velocity(val)",val)

  val = math.floor(val*MAX_VELOCITY)
  self.velocity = val

end

--------------------------------------------------------------------------------

-- disable activity for the group (stop active tracks), or toggle mute state

function Mlrx_group:toggle()
  --TRACE("Mlrx_group:toggle()")
  
  local rns = renoise.song()
  local toggle_mute = true
  local mute_state = MUTE_STATE_ACTIVE
  for _,trk in ipairs(self.tracks) do
    local rns_trk = rns.tracks[trk.rns_track_idx] 
    if trk.note then
      trk:schedule_noteoff()
      toggle_mute = false
    end
    if (rns_trk.mute_state ~= MUTE_STATE_ACTIVE) then
      mute_state = MUTE_STATE_OFF
    end
  end

  if toggle_mute then
    mute_state = (mute_state == MUTE_STATE_OFF) and MUTE_STATE_ACTIVE or MUTE_STATE_OFF
    for _,trk in ipairs(self.tracks) do
      local rns_trk = rns.tracks[trk.rns_track_idx] 
      rns_trk.mute_state = mute_state
    end
  end

end

--------------------------------------------------------------------------------

-- when switching track, check if we should output note-off for other tracks 

function Mlrx_group:switch_to_track(trk_idx)
  --TRACE("Mlrx_group:switch_to_track()",trk_idx)

  local rns = renoise.song()
  
  --[[
  if self.last_triggered and (self.last_triggered == trk_idx) then
    --print("switch_to_track - no need to switch, already there")
    return
  end
  ]]

  if self.last_triggered then
    for _,trk in ipairs(self.main.tracks) do
      if (trk.group == self) and 
        (trk_idx ~= trk.mlrx_track_idx) 
      then 
        if (trk.note) then
          trk:schedule_noteoff()
        else

          -- non-playing tracks will receive a note-off directly

          local offpos = Mlrx_pos()
          offpos.line = offpos.line+1
          offpos:normalize()

          local patt_idx = rns.sequencer.pattern_sequence[offpos.sequence]
          local line = rns.patterns[patt_idx].tracks[trk.rns_track_idx].lines[offpos.line]
          assert(line,"Line not found")
          line:clear()
          line:note_column(1).note_value = NOTE_OFF

          --print("switch_to_track - note-off written @line",offpos.line,", track",trk.rns_track_idx)

        end
      end
    end
  end

  self.last_triggered = trk_idx
  --print("switch_to_track - last_triggered is now",trk_idx)

end


--------------------------------------------------------------------------------

-- stop group, triggered when stopping playback
-- (will not write anything to pattern but simply cancel notes)

function Mlrx_group:cancel_notes()
  TRACE("Mlrx_group:cancel_notes()")

  for trk_idx,trk in ipairs(self.tracks) do
    if trk.note then
      trk.note = nil
      --print("*** nullified the note in track",trk_idx)
    end
    self.main:update_trigger_pos(trk_idx) -- clear the light
  end

end

--==============================================================================

-- a seperate class for containing track properties 

class 'Mlrx_track' 

Mlrx_track.TRIG_LOOP = 1  -- output from offset, looped playback
--Mlrx_track.TRIG_SHOT = 2  -- output from offset -> end of sample
Mlrx_track.TRIG_HOLD = 3  -- output for as long as trigger is held

Mlrx_track.NOTE_CUT = 1
Mlrx_track.NOTE_OFF = 2
Mlrx_track.NOTE_CONTINUE = 3

function Mlrx_track:__init(main)
  TRACE("Mlrx_track:__init()")

  -- (Mlrx) reference to main application
  self.main = main

  -- (int) the associated Renoise instrument/track
  self.rns_instr_idx = nil
  self.rns_track_idx = nil

  -- (Mlrx_group) the group that this track belong to 
  self.group = nil

  -- (int) the index of this track in the main application 
  self.mlrx_track_idx = nil

  -- (int) number of possible sample-offsets/slices
  self.divisions = nil

  -- (enum) the default triggering mode
  self.trig_mode = self.TRIG_LOOP

  -- (boolean) whether to include sample-offset in output
  self.do_sample_fx = true

  -- (boolean) whether to include envelope-offset in output
  self.do_envelope_fx = false

  -- (int) the line-sync value
  -- (note: this property should reflect the actual instrument)
  self.sync_to_lines = nil

  -- (int) the user-specified transpose amount (in semitones)
  self.transpose = 0

  -- (boolean) when true, use the MIDI keyboard for setting transpose
  self.apply_key_transpose = false

  -- (int) independantly of "sync_to_lines", specify the cycle length
  -- either 1,2,4,8 or 16 (divide sync_to_lines by this amount)
  self.cycle_length = 1

  -- playing/scheduled notes (instance of Mlrx_note)
  self.note = nil

  -- (int) the actual sample transpose + our user-specified one
  self._note_transposed = 0

  -- (SongPos) local copy of playback position
  self._last_playpos = nil

  -- (int) the last trigger button that was pressed (1 - NUM_DIVISIONS)
  -- this is also a good way to check if any button is pressed...
  self._last_pressed = nil

  -- (int) which button is currently being lit  (1 - NUM_DIVISIONS)
  self._lit_position = nil


end

--------------------------------------------------------------------------------

--- Print some debugging info

function Mlrx_track:__tostring()
  return "Mlrx_track - rns_track_idx",rns_track_idx,"rns_instr_idx",rns_instr_idx

end  

--------------------------------------------------------------------------------

-- method for figuring out this track's index within the main application
-- @return (int)

function Mlrx_track:get_index()

  for i,t in ipairs(self.main.tracks) do
    if (t==self) then
      return i
    end
  end

end


--------------------------------------------------------------------------------

-- method for writing data into a pattern-track, a few lines at a time
-- also: fancy detection of active state & duration of notes, and more
--
-- @param writepos (Mlrx_pos) start from this position
-- @param writeahead (int) process # of lines, starting from writepos (0 means single line is written)
-- @param wraparound (boolean) true when writing across pattern boundaries
-- @param on_idle (boolean) true when invoked by idle loop (we then detect notes being active or turned off)

function Mlrx_track:track_output(writepos,writeahead,wraparound,on_idle)
  --TRACE("Mlrx_track:track_output()",writepos,writeahead,wraparound,on_idle)

  local rns = renoise.song()
  if not rns.tracks[self.rns_track_idx] then
    --print("track_output - not possible, track ",self.rns_track_idx," not found")
    return
  end

  local patt_idx = rns.sequencer.pattern_sequence[writepos.sequence]
  local patt = rns:pattern(patt_idx)
  local do_wipe = false
  local do_read = false
  local readahead = Mlrx.readahead

  -- check if any child-tracks have an active note
  local group_active = self.note
  if not self.note then
    --local grp = self.main.groups[self.group_index]
    for _,trk in ipairs(self.group.tracks) do
      if (trk.note) then
        group_active = true
        break
      end
    end
  end
  if group_active then
    do_wipe = not self.note
  else
    do_read = true
  end

  local playpos = Mlrx_pos()
  --print("playpos",playpos)

  -- the rate at which looped notes should repeat
  -- (if rate is very fast, use alternative write method)
  local cycle_lines = self.sync_to_lines/self.cycle_length
  local fast_repeat = false
  if (cycle_lines <= Mlrx.writeahead) then
    fast_repeat = true
  end

  local schedule_repeat = function(seq,line)
    --print("schedule_repeat(seq,line)",seq,line)

    local repeatpos = Mlrx_pos({
      sequence = seq,
      line = line
    })

    self.note.travelled = playpos.line-line

    -- if positive, take a closer look...probably means that
    -- the current pattern wrapped around
    if (self.note.travelled>0) then
      local diff = Mlrx:get_pos_diff(playpos,repeatpos)
      self.note.travelled = -diff
      --renoise.app():show_status("self.note.travelled:"..self.note.travelled)
    end
    self.note.repeatpos = repeatpos
    self.note.repeatpos.line = line+cycle_lines
    self.note.repeatpos:normalize()
    --print("*** scheduled repeatpos",self.note.repeatpos)

  end

  local write_note = function(line)
    local note_col = line:note_column(1)
    local effect_col_1 = line:effect_column(1)
    local effect_col_2 = line:effect_column(2)
    note_col.instrument_value = self.rns_instr_idx-1
    note_col.volume_value = self.group.velocity
    note_col.note_value = self._note_transposed
    if self.do_sample_fx then
      effect_col_1.number_string = "0S"
      effect_col_1.amount_value = (256/self.divisions)*(self.note.index-1)
    else
      effect_col_1:clear()
    end
    if self.do_envelope_fx then
      effect_col_2.number_string = "0E"
      effect_col_2.amount_value = (256/self.divisions)*(self.note.index-1)
    else
      effect_col_2:clear()
    end
  end

  -- check if we exceed the pattern 
  local exceeded = false
  local exceeded_by = nil
  local line_to = writepos.line+writeahead
  if (line_to > patt.number_of_lines) then
    exceeded = true
    exceeded_by = line_to-patt.number_of_lines-1
    line_to = patt.number_of_lines
    writeahead = writeahead - exceeded_by
    --print("pattern exceeded_by",exceeded_by,"line_to",line_to)
  end

  local lines = patt.tracks[self.rns_track_idx]:lines_in_range(writepos.line,line_to)
  for i = 1,#lines do
    
    local line = lines[i]
    local line_idx = writepos.line+i-1

    writeahead = writeahead-1

    if do_wipe then 

      ---------------------------------------------------
      -- wipe inactive track in active group
      ---------------------------------------------------

      --print("*** perform track wipe @line",line_idx,"track index",self.rns_track_idx)
      line:clear()

    elseif do_read then 

      if not wraparound then

        ---------------------------------------------------
        -- read & display pattern data in inactive group
        ---------------------------------------------------

        --print("line",line)
        local note_col = line:note_column(1)
        if not note_col.is_empty then

          local offset = nil

          -- check if the note match our track's instrument
          -- (we only want to display matching content)
          if not ((note_col.instrument_value+1) == self.rns_instr_idx) then
            --print("*** ignore non-matching instrument at this line",line)
          else
            -- figure out the offset
            local fx_col_1 = line:effect_column(1)
            local fx_col_2 = line:effect_column(2)
            if fx_col_1.is_empty and fx_col_2.is_empty then
              -- no offset to display (perhaps offset commands are disabled)
            else
              if (fx_col_1.number_string == "0S")then
              offset = fx_col_1.amount_value
              elseif (fx_col_2.number_string == "0E")then
              offset = fx_col_2.amount_value
              end
            end

          end

          if offset then

            --print("light up offset A",offset)
            offset = math.min(self.divisions,math.ceil((offset/256)*self.divisions)+1)
            --print("light up offset B",offset)

            -- display on the controller as a brief flash
            self.main:trigger_feedback(self.mlrx_track_idx,offset)

          end

        end

        readahead = readahead-1
        if (readahead == 0) then
          break
        end

      end

    else         
      ---------------------------------------------------
      -- process active track
      ---------------------------------------------------

      --print("self.note.startpos",self.note.startpos)
      --print("self.note.endpos",self.note.endpos)

      if self.note.repeatpos and (line_idx == self.note.repeatpos.line) and
        -- check if travelled "roughly" far enough for our repeat
        -- (otherwise, a 128-line repeat within a 64-line pattern wouldn't work)
        (self.note.travelled+Mlrx.writeahead*2 >= cycle_lines)
      then 
        -- output a repeated note 
        --print("*** output repeated note",line_idx,", track",self.rns_track_idx)
        write_note(line)

        -- add to ignore list
        if (line_idx >= patt.number_of_lines) then
          local normalized_pos = Mlrx_pos(self.note.repeatpos)
          normalized_pos:normalize()
          self.note.ignore_lines:insert(normalized_pos)
          --print("insert into self.note.ignore_lines A ",normalized_pos)
        else
          self.note.ignore_lines:insert(self.note.repeatpos)
          --print("insert into self.note.ignore_lines B ",self.note.repeatpos)
        end

        --rprint(self.note.ignore_lines)
        schedule_repeat(self.note.repeatpos.sequence,line_idx)


      elseif self.note.startpos and (line_idx == self.note.startpos.line) 
      then 
        -- output a note 
        
        if not self.note.active then
          -- output for the first time
          --print("*** output note",line_idx,", track",self.rns_track_idx)
          write_note(line)
          self.note.written = true

          if (self.trig_mode == self.TRIG_LOOP) then
            schedule_repeat(writepos.sequence,line_idx)
          end

        else

          if (line_idx > playpos.line) then

            -- if already output, clear the line 
            -- (excerpt if repeat has written some content there)
            local ignore = false
            if self.note.repeatpos then
            ignore = self.note:on_ignore_list(line_idx)
            end
            if not ignore then
            --print("*** clear line (instead of note)",line_idx,"playback_pos",rns.transport.playback_pos,", track",self.rns_track_idx)
            line:clear()
            end
          end
        end


      elseif not self.note.offed and
        self.note.endpos and
        (line_idx == self.note.endpos.line) 
      then 

        -- output a note-off 
        --print("*** output note-off",line_idx,", track",self.rns_track_idx)

        line:clear()
        line:note_column(1).note_value = NOTE_OFF
        self.note.offed = true

      elseif self.note.startpos and 
        (not self.note.written or not self.note.active and 
        (self.note.startpos.sequence == writepos.sequence) and
        (self.note.startpos.line > line_idx))
      then
        -- skip output until note is written
        --print("*** skip this line",line_idx)

      elseif not self.note.offed and
        ((line_idx == 1) or 
        (line_idx > writepos.line))
      then 
        -- clear line

        --if (line_idx > playpos.line) then

        local ignore = self.note:on_ignore_list(line_idx)
        --print("on ignore list",ignore)
        --rprint(self.note.ignore_lines)
        if not ignore then

          --print("*** clear line",line_idx,writepos,", track",self.rns_track_idx)
          if self.note.written or self.note.active then
          line:clear()
          end
        else
          --print("*** clear line (ignored)",line_idx,writepos,", track",self.rns_track_idx)
        end

        --[[
        elseif self.note.offed and not self.note.offed_2nd then

          -- output a secondary note-off 
          print("*** output secondary note-off",line_idx)

          line:clear()
          line:note_column(1).note_value = NOTE_OFF
          self.note.offed_2nd = true
        ]]
      end
    end

  end

  -- detect note (de)activation and travel length only when 
  -- (1) we have a note, and (2) method is invoked by the idle loop...

  if self.note and on_idle then

    -- check if playback has wrapped around in same pattern
    local repeated = false
    if (self._last_playpos) then
      repeated = (playpos < self._last_playpos)
    else
      -- always initialize this value!
      self._last_playpos = playpos
    end

    -- check if we have crossed the note-on point, and 
    -- measure how far a playing note might have travelled

    if self.note.startpos then

      if not self.note.active and self.note.written and
        (self.note.startpos.line <= playpos.line) and -- less than or equal to current position
        (self.note.startpos.line > playpos.line-Mlrx.writeahead) and -- within the 
        (self.note.startpos.sequence <= playpos.sequence) -- in current, or a previous pattern
      then
        self.note.active = true
        --print("*** the sound was detected as active @playpos",playpos,", track",self.rns_track_idx)
        self:light_position(1)
      end

      -- if the note is active and looped, measure the travel distance 

      if self.note.active then

        if not self.note.travelled then
          
          -- for the HOLD mode, we need to initialize the travel
          -- distance ourselves (as no repeat note is being scheduled)
          if not (self.trig_mode == self.TRIG_LOOP) and
            (self.note.startpos.line < playpos.line) 
          then
            self.note.travelled = playpos.line - self.note.startpos.line
            --print("*** initialized travel distance to",self.note.travelled)
          end

        else
          local count_remaining = false
          if (self._last_playpos.sequence == playpos.sequence) then
            if not repeated then
              local diff = playpos.line - self._last_playpos.line
              self.note.travelled = self.note.travelled + diff
            else -- repeated
              count_remaining = true
            end
          else -- next (or first) pattern
            count_remaining = true
          end

          if count_remaining then
            -- when crossing a pattern boundary, count lines in old pattern
            if not (playpos == self._last_playpos) then
              local diff = Mlrx:get_pos_diff(self._last_playpos,playpos)
              --print("counted line difference",diff)
              self.note.travelled = self.note.travelled + diff

            end  

          end

          --print("*** self.note.travelled",self.note.travelled,"playpos",playpos)
          if not wraparound then
            self:light_position(self.note.travelled)
          end


        end

      end

    end

    -- playback has continued past the endpos of the sound? (then nullify)
    if self.note.endpos and self.note.offed then
      if 
        -- passed the note-off
        (not repeated and 
          (self.note.endpos.sequence == playpos.sequence) and (self.note.endpos.line <= playpos.line)) or
        -- wrapped around same pattern
        (repeated and self.note.endpos.line > playpos.line) 
      then
        --print("*** nullify the sound @playpos",playpos,"track index",self.rns_track_idx)
        self.note = nil
        self.main:update_trigger_pos(self.mlrx_track_idx) -- clear the light
        return
      end
    end

    -- purge the ignore list 
    if not table.is_empty(self.note.ignore_lines) then
      -- check if we are close enough to the end of the pattern to have wrapped
      --local wrapped = (playpos.line >= patt.number_of_lines) 
      local wrapped = (playpos.line+Mlrx.writeahead > patt.number_of_lines) 
      if not wraparound then -- ignore when writing into a different pattern
        for i,v in ipairs(self.note.ignore_lines) do
          if (v < playpos) then
            --if wrapped and (v.line < Mlrx.writeahead) then
            if wrapped and (playpos.line-Mlrx.writeahead*2 > v.line) then
              --print("*** ignore early positions as a result of wrapping",v)
            else
              self.note.ignore_lines:remove(i)
              --print("*** purge from self.note.ignore_lines",v)
            end
          elseif repeated and (v.line > (playpos.line+Mlrx.writeahead)) then
            --print("*** purge late repeatpos",v)
            self.note.ignore_lines:remove(i)
          end
        end

      end
      --print("*** post-purge ignore_lines")
      --rprint(self.note.ignore_lines)
    end


    self._last_playpos = playpos


  end  -- on_idle

  if exceeded then 
    -- call function again, supply the new writepos
    writepos.line = patt.number_of_lines+1
    writepos:normalize()
    wraparound = true
    --print("*** wraparound - exceeded_by",exceeded_by,writepos)
    self:track_output(writepos,exceeded_by,wraparound,on_idle)
  end

end


--------------------------------------------------------------------------------

-- obtain reference to the first sample in the instrument
-- @return renoise.Sample or nil if not found

function Mlrx_track:get_sample_ref()

  local rns = renoise.song()
  local instr = rns.instruments[self.rns_instr_idx]
  if not instr then
    --print("get_sample_ref - instrument not found: self.rns_instr_idx",self.rns_instr_idx)
    return
  end
  local sample = instr.samples[1]
  if not sample then
    --print("get_sample_ref - sample not found")
    return
  end

  return sample

end

--------------------------------------------------------------------------------

function Mlrx_track:toggle_sample_offset()
  --TRACE("Mlrx_track:toggle_envelope_offset()")

  self.do_sample_fx = not self.do_sample_fx 


  if self.do_sample_fx then
    -- reveal (at least) the first effect column
    local rns = renoise.song()
    local rns_trk = rns.tracks[self.rns_track_idx]
    assert(rns_trk,"Could not locate track in renoise")
    if (rns_trk.visible_effect_columns < 1) then
      if self.do_envelope_fx then
        rns_trk.visible_effect_columns = 2
      else
        rns_trk.visible_effect_columns = 1
      end
    end
  end

end

--------------------------------------------------------------------------------

function Mlrx_track:toggle_envelope_offset()
  --TRACE("Mlrx_track:toggle_envelope_offset()")

  self.do_envelope_fx = not self.do_envelope_fx 

  if self.do_envelope_fx then
    -- reveal the second effect column
    local rns = renoise.song()
    local rns_trk = rns.tracks[self.rns_track_idx]
    assert(rns_trk,"Could not locate track in renoise")
    if (rns_trk.visible_effect_columns < 2) then
      rns_trk.visible_effect_columns = 2
    end
  end

end

--------------------------------------------------------------------------------

function Mlrx_track:toggle_sync()
  TRACE("Mlrx_track:toggle_sync()")

  local rns = renoise.song()
  local sample = self:get_sample_ref()
  if not sample then
    return
  end
  sample.beat_sync_enabled = not sample.beat_sync_enabled

end

--------------------------------------------------------------------------------

function Mlrx_track:toggle_keys()
  TRACE("Mlrx_track:toggle_keys()")

  local rns = renoise.song()
  local sample = self:get_sample_ref()
  if not sample then
    return
  end
  self.apply_key_transpose = not self.apply_key_transpose

end

--------------------------------------------------------------------------------

-- adjust the transpose/line sync 
-- @param val (int) the amount +/-

function Mlrx_track:set_transpose(val)
  TRACE("Mlrx_track:set_transpose(val)",val)

  -- obtain reference to the instrument
  local rns = renoise.song()
  local sample = self:get_sample_ref()
  if not sample then
    return
  end

  local linesynced = sample.beat_sync_enabled 
  --print("linesynced",linesynced)
  if linesynced then

    -- up means down :-)
    val = -val

    -- read the current value
    self.sync_to_lines = sample.beat_sync_lines

    -- restrict to predefined set
    local lines_set = table.create()
    for i = 16,513,16 do
      lines_set:insert(i)
    end
    local tmp = nil
    local new_lines = nil
    for i,num_lines in ipairs(lines_set) do
      if (lines_set[i]>=self.sync_to_lines) then
        tmp = i
        break
      end
    end
    self.sync_to_lines = lines_set[math.max(1,math.min(32,tmp + val))]

    -- apply to sample
    sample.beat_sync_lines = self.sync_to_lines

  else

    -- transpose by provided value
    self.transpose = self.transpose+val
    --print("self.transpose",self.transpose)

    self:maintain_transpose()

  end

end

--------------------------------------------------------------------------------

-- when initializing, or changing the transpose amount,
-- call this method to maintain the correct value at all times

function Mlrx_track:maintain_transpose()
  TRACE("Mlrx_track:maintain_transpose()")

  local rns = renoise.song()

  local sample = self:get_sample_ref()
  if not sample then
    return
  end

  -- obtain the basenote from the keyzone mapping
  local basenote = 0
  for i,v in ipairs(rns.instruments[self.rns_instr_idx].sample_mappings) do
    for i2,v2 in ipairs(v) do
      if (v2.sample_index == 1) then
        basenote = v2.base_note
      end
    end
  end
  --print("maintain_transpose - basenote",basenote)

  self._note_transposed = basenote + sample.transpose + self.transpose
  --print("maintain_transpose - self._note_transposed",self._note_transposed)

end

--------------------------------------------------------------------------------

-- kindly ask a playing track to schedule a note-off 
-- (this will ensure that the light is properly turned off, etc)

function Mlrx_track:schedule_noteoff()
  --TRACE("Mlrx_track:schedule_noteoff()")

  if not self.note then
    return
  end

  local playpos = Mlrx_pos()

  -- do not output or clear anything else!!
  self.note.ignore_lines:insert(playpos)
  self.note.startpos = nil
  self.note.repeatpos = nil

  local endpos = Mlrx_pos(playpos)
  endpos.line = endpos.line+1
  endpos:normalize()
  self.note.endpos = endpos
  --print("Mlrx_track.schedule_noteoff - endpos",endpos)

  -- immediately output
  self:track_output(playpos,1)


end

--------------------------------------------------------------------------------

function Mlrx_track:set_trig_mode(enum)
  --TRACE("Mlrx_track:set_trig_mode(enum)",enum)

  self.trig_mode = enum

end

--------------------------------------------------------------------------------

function Mlrx_track:set_cycle_length(val)
  TRACE("Mlrx_track:set_cycle_length(val)",val)

  self.cycle_length = val

  -- retrigger the playing note
  -- TODO more clever implementation would use an alternative quantize 
  -- which would allow the sound to play in it's "own" time
  if self.note and self.note.active then
    self:trigger_press(self.note.index)
  end

end

--------------------------------------------------------------------------------

-- light up a button on the controller, appropriate for the given position

function Mlrx_track:light_position(travelled)
  --print("Mlrx_track:light_position(travelled)",travelled)


  if not self.note then
    return
  end

  -- compensate for negative values, restrict to lines in cycle
  if (travelled < 1) then
    local cycle_lines = self.sync_to_lines/self.cycle_length
    travelled = cycle_lines + travelled
    if (self.cycle_length > 1) then
      travelled = ((travelled-1)%cycle_lines)+1
    end
  end

  local offset = math.ceil((travelled/self.sync_to_lines) * self.divisions)
  --print("*** light_position - travelled,offset",travelled,offset)

  -- rotate the position, according to the offset
  offset = (((offset+self.note.index-1)-1)%self.divisions)+1
  --offset = (offset==0) and self.divisions or offset

  if (offset ~= self._lit_position) then
    --print("*** light_position - final offset",offset)
    self.main:update_trigger_pos(self.mlrx_track_idx,offset)
  end

end

--------------------------------------------------------------------------------

function Mlrx_track:colorize_track(color)
  --TRACE("Mlrx_track:colorize_track(color)",color)

  local rns = renoise.song()
  local rns_trk = rns.tracks[self.rns_track_idx]

  if (rns_trk) then
    rns_trk.color = color
  end

end


--------------------------------------------------------------------------------

-- handle pressed buttons 

function Mlrx_track:trigger_press(trigger_idx)
  TRACE("Mlrx_track:trigger_press()",trigger_idx)

  local rns = renoise.song()
  local is_playing = rns.transport.playing


  -- figure out the closest quantized line
  local quant = Mlrx.get_quantize()
  local songpos = Mlrx_pos()
  --print("trigger_press - songpos",songpos)
  local tmp = songpos.line%quant
  if (tmp==0) then
    tmp = quant
  end
  --print("trigger_press - tmp",tmp)

  -- calculate the time spent waiting for the
  -- quantize to be applied (used on release)
  local quant_time_delay = (quant-tmp)/Mlrx.lps
  --print("quant_time_delay",quant_time_delay)

  local startpos = Mlrx_pos()

  startpos.line = songpos.line+(quant-tmp)+1
  if (tmp == 1) and not is_playing then
    startpos.line = songpos.line
  end
  startpos.sequence = songpos.sequence
  
  local force_to_start = true
  startpos:normalize(force_to_start)

  --print("trigger_press - startpos",startpos.line)

  self.note = Mlrx_note()
  self.note.index = trigger_idx
  self.note.time_pressed = os.clock()
  self.note.pos = Mlrx_pos() -- for later use
  self.note.startpos = startpos
  self.note.time_quant = os.clock()+quant_time_delay
  --print("trigger_press - note.startpos",self.note.startpos.line,self.mlrx_track_idx)
  --print("trigger_press - note.time_pressed",self.note.time_pressed)
  --print("trigger_press - note.time_quant",self.note.time_quant)

  self.group:switch_to_track(self.mlrx_track_idx)

  -- ask the group to perform the update
  self.group:group_output()

  -- if not playing, note notes are cleared at once
  if not is_playing then
    self.note = nil
  end

  self._last_pressed = trigger_idx

end

--------------------------------------------------------------------------------

-- handle released buttons 

function Mlrx_track:trigger_release(trigger_idx)
  TRACE("Mlrx_track:trigger_release()",trigger_idx)

  if not self.note then
    return
  end

  local rns = renoise.song()

  -- ignore release if in continously looping mode
  if (self.trig_mode == self.TRIG_LOOP) then
    return
  end

  -- ignore release if another button in the same track
  -- is pressed
  if self._last_pressed and (trigger_idx ~= self._last_pressed) then
    --print("trigger_release: another button is pressed",self._last_pressed)
    return
  end


  -- update the release time
  local time_released = os.clock()
  -- print("trigger_release - time_released",time_released)

  local pos = Mlrx_pos()
  local line_count = 0

  if (time_released > self.note.time_quant) then
    --print("released after note-on - output note-off at first given chance")
    pos.line = pos.line+1
  elseif self.note.startpos then -- released before note-on, use held time as duration
    pos = self.note.startpos
    local time_diff = time_released - self.note.time_pressed
    line_count = math.ceil(Mlrx.lps * (time_released - self.note.time_pressed))
    line_count = math.min(1,line_count) -- duration should be at least one line
  end

  self.note.endpos = Mlrx_pos({
    sequence = pos.sequence,
    line = pos.line + line_count
  })

  -- print("trigger_release - self.endpos.line",self.note.endpos.line)

  -- normalize the endpos
  self.note.endpos:normalize()

  -- make sure it is _at least_ one line after startpos
  if self.note.startpos and 
    (self.note.startpos == self.note.endpos) 
  then
    --print("trigger_release - self.endpos (prior to normalize)",self.note.endpos.sequence,self.note.endpos.line)
    self.note.endpos.line = self.note.endpos.line+1
    self.note.endpos:normalize()
  end

  --print("trigger_release - self.endpos",self.note.endpos.sequence,self.note.endpos.line)


  if (self.trig_mode == Mlrx_track.TRIG_HOLD) then
    self.group:group_output()
  end

  if (trigger_idx == self._last_pressed) then
    --print("trigger_release: last button released")
    self._last_pressed = nil
  end

  --print("trigger_release: _last_pressed",self._last_pressed)

end

--------------------------------------------------------------------------------

-- compare to another class instance (check for object identity)

function Mlrx_track:__eq(other)
  return rawequal(self, other)
end  

--==============================================================================

-- the note is associated with a track

class 'Mlrx_note' 


function Mlrx_note:__init()
  TRACE("Mlrx_note:__init()")

  -- (int) the most recently pressed trigger (1 - #Mlrx_track.divisions)
  self.index = nil

  -- (SongPos) unmodified
  self.pos = nil  

  -- (SongPos) quantized & normalized
  self.startpos = nil  

  -- (float) exact time when button was pressed
  self.time_pressed = nil 

  -- (float) same as above, but quantized
  self.time_quant = nil 

  -- (SongPos) when another note should be written (only for TRIG_LOOP)
  self.repeatpos = nil  

  -- (SongPos) scheduled note-off (only for TRIG_HOLD/TRIG_SHOT)
  self.endpos = nil  

  -- (table) list of song positions that should be ignored when clearing
  -- (contains repeated notes within the writeahead range) 
  self.ignore_lines = table.create()

  -- (int) how many lines the note has travelled since first triggered 
  -- this value is used for two things: (1) to display some visual feedback,
  -- and (2) to enable repeat-rates which exceed a pattern's length
  -- (can be a negative value if we schedule a repeat prior to writing it)
  self.travelled = nil

  -- (boolean) true once note has been written
  self.written = false 

  -- (boolean) true once note has been written, and playback has passed it
  -- used when switching from one track to another, to check if we should
  -- output a note-off (exclusive groups)
  self.active = false 

  -- (boolean) true once an OFF has been written 
  self.offed = false 

  -- (boolean) true once an second OFF (!) has been written 
  self.offed_2nd = false 

end

--------------------------------------------------------------------------------

-- check the ignore list

function Mlrx_note:on_ignore_list(line_idx)

  for i,v in ipairs(self.ignore_lines) do
    if (v.line == line_idx) then
      return true
    end
  end

end

--==============================================================================

-- class for handling operations on song-position objects
-- (a more flexible implementation of the native SongPos)

class 'Mlrx_pos' 

--------------------------------------------------------------------------------

function Mlrx_pos:__init(pos)

  if not pos then
    local rns = renoise.song()
    if rns.transport.playing then
      pos = rns.transport.playback_pos
    else
      pos = rns.transport.edit_pos
    end
  end

  self.line = pos.line
  self.sequence = pos.sequence

end

--------------------------------------------------------------------------------

function Mlrx_pos:__eq(other)

  -- TODO faster if both are native SongPos objects:
  --return rawequal(self, other)

  if (self.line == other.line) and
    (self.sequence == other.sequence)
  then
    return true
  end

end

--------------------------------------------------------------------------------

function Mlrx_pos:__lt(other)

  -- TODO faster if both are native SongPos objects:
  --return (self < other)

  if (self.sequence == other.sequence) then
    return (self.line < other.line)
  elseif (self.sequence < other.sequence) then
    return true
  else
    return false
  end

end


--------------------------------------------------------------------------------

function Mlrx_pos:__tostring()

  return "[Mlrx_pos: " .. self.sequence .. ", " .. self.line .. "]"

end

--------------------------------------------------------------------------------

-- ensure that a song-position stays with #number_of_lines, taking stuff like
-- pattern/sequence loop and song duration into consideration
-- @param pos (SongPos) a song-position object to process
-- @param force_to_start (boolean) when dealing with quantized notes,
--    this will allow us to force a note to always trigger at the first line
-- return table ("emulated" SongPos, without comparison operators)

function Mlrx_pos:normalize(force_to_start)

  local num_lines = Mlrx:count_lines(self.sequence)
  if (self.line > num_lines) then -- exceeded pattern length
    local rns = renoise.song()
    self.line = (force_to_start) and 1 or self.line-num_lines

    --print("*** normalize - exceeded pattern length, line is now",self.line)
    if not Mlrx:pattern_is_looped() then
      self.sequence = self.sequence+1
      --print("*** normalize - increase sequence to",self.sequence)
      if (self.sequence > #rns.sequencer.pattern_sequence) then
        --print("*** normalize - set sequence to song start")
        self.sequence = 1
      elseif (self.sequence-1 == rns.transport.loop_sequence_end) then
        --print("*** normalize - set sequence to loop start")
        self.sequence = rns.transport.loop_sequence_start
      end

    end

    local patt_idx = rns.sequencer.pattern_sequence[self.sequence]
    local patt = rns:pattern(patt_idx)
    if (patt.number_of_lines < self.line) then
      --print("*** normalize - recursive action")
      self:normalize()
    end

  end

end
