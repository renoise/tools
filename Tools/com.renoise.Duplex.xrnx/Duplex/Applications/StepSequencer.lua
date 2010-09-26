--[[----------------------------------------------------------------------------
-- Duplex.StepSequencer

Use your Novation Launchpad as a step sequencer.
8x8 grid is 8 vertical tracks with 8 lines visible.  Press an empty button to put a note down using currently selected instrument.  Press a lit button to remove the note.
Page lines up/down with "line" spinner
Page tracks left/right with "track" spinner
Transpose note up/down with "transpose" control (4 buttons, from left: oct-, semi-, semi+, oct+)
Select note volume from 8 preset levels with "level" slider (right-hand trigger buttons)
If transpose / level controls are used while holding down grid buttons, the transpose / level will be applied to all held notes.  Otherwise the base note will be adjusted.

Only tested with Launchpad.  Could probably be applied to other grid controllers but might need some modification.

Code mostly based on danoise's Matrix application.

TODO:
  - use trigger buttons for more than just volume
  - track muting
  - insert / delete (shift up/down or left/right)
  - copy / repeat whole page or track in page
  
v.001

daxton.fleming@gmail.com

----------------------------------------------------------------------------]]--

-- danoise comments --
-- this class has been embedded into the application : UIBasicButton
-- now uses UIButtonStrip for displaying volume level + position
-- switched from .lines[idx] to :line(idx) syntax (performance)

class 'StepSequencer' (Application)

function StepSequencer:__init(display,mappings,options)
  TRACE("StepSequencer:__init(",display,mappings,options)

  Application.__init(self)
  self.display = display -- what does this do?
  
  -- build list of volumes (0-121)
  local vols = { }
  for i=0,127 do vols[i]=i end
  
  self.options = {
    base_note = {
        label = "Base Note",
        items = { "C-", "C#", "D-", "D#", "E-", "F-", "F#", "G-", "G#", "A-", "A#", "B-" },
        default = 1,
    },
    base_octave = {
        label = "Base Octave",
        items = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" },
        default = 4,
    },
    base_volume = {
        label = "Base Volume",
        items = vols,
        default = 100,
    },
  }
  self:__set_default_options(true)

  -- define the mappings (unassigned)
  self.mappings = {
    grid = {
      description = "Sequencer: Toggle notes on/off, hold to copy note",
      ui_component = UI_COMPONENT_CUSTOM,
      greedy = true,
    },
    level = {
      description = "Sequencer: Adjust note volume",
      ui_component = UI_COMPONENT_SLIDER,
    },
    line = { 
      description = "Sequencer: Flip up/down through lines",
      ui_component = UI_COMPONENT_SPINNER,
    },
    track = {
      description = "Sequencer: Flip through tracks",
      ui_component = UI_COMPONENT_SPINNER,
    },
    transpose = {
      description = "Sequencer: 4 buttons for transpose up/down.  oct- / semi- / semi+ / oct+",
      ui_component = UI_COMPONENT_CUSTOM,
    },

  }

  -- define default palette
  self.palette = {
    out_of_bounds = {
      color={0x40,0x00,0x00}, 
      text="",
    },
    
    slot_empty = {
      color={0x00,0x00,0x00},
      text="",
    },
    slot_muted = { -- volume 0 or note_cut
      color={0x40,0x00,0x00},
      text="□",
    },
    slot_level = { -- at different volume levels (automatically scales to #slot_level levels
      { color={0x00,0x40,0xff}, },
      { color={0x00,0x80,0xff}, },
      { color={0x00,0xc0,0xff}, },
      { color={0x00,0xff,0xff}, },
      { color={0x40,0xff,0xff}, },
      { color={0x80,0xff,0xff}, },
    },
    
    transpose = {
      { color={0xff,0x00,0xff}, }, -- down an octave
      { color={0xc0,0x40,0xff}, }, -- down a semi
      { color={0x40,0xc0,0xff}, }, -- up a semi
      { color={0x00,0xff,0xff}, }, -- up an octave
    },
    position = {
      color={0x00,0xff,0x00},
    },

  }

  -- the various controls
  self.__buttons = nil
  self.__level = nil
  self.__line_navigator = nil
  self.__track_navigator = nil
  self.__transpose = nil

  self.__width = 8
  self.__height = 8

  self.__edit_page = 0  -- the currently editing page
  self.__track_offset = 0  -- the track offset (0-#tracks)

  self.__current_pattern = 0
  
  self.__update_lines_requested = false
  self.__update_tracks_requested = false
  self.__update_grid_requested = false
  
  -- STEP SEQUENCER VARIABLES
  self.__keys_down = { } -- track held grid keys
  self.__toggle_exempt = { } -- don't toggle off if pressing multiple on / transposing / etc

  -- apply arguments
  self:__apply_options(options)
  self:__apply_mappings(mappings)

end

--------------------------------------------------------------------------------

function StepSequencer:start_app()
  TRACE("StepSequencer.start_app()")

  if not (self.__created) then self:__build_app() end

  -- update everything!
  self:__update_line_count()
  self:__update_track_count()
  self:__update_grid()

  Application.start_app(self)


end


--------------------------------------------------------------------------------

-- build ui
function StepSequencer:__build_app()
  TRACE("StepSequencer:__build_app()")
  Application.__build_app(self)

  -- determine grid size by looking at the control-map
  local control_map = self.display.device.control_map.groups[self.mappings.grid.group_name]
  if(control_map["columns"])then
      self.__width = control_map["columns"]
      self.__height = math.ceil(#control_map/self.__width)
  end

  -- build each section's controllers
  self:__build_line()
  self:__build_track()
  self:__build_grid()
  self:__build_level()
  self:__build_transpose()

  -- bind observables
  self:__attach_to_song(renoise.song())
end

--------------------------------------------------------------------------------

function StepSequencer:__build_line()
  -- line (up/down scrolling)
  local c = UISpinner(self.display)
  c.group_name = self.mappings.line.group_name
  c.tooltip = self.mappings.line.description
  c:set_pos(self.mappings.line.index)
  c.text_orientation = VERTICAL
  c.step_size = 1
  c.on_change = function(obj) 
    if (not self.active) then return false end
    if(self.__edit_page~=obj.index)then
      self.__edit_page = obj.index
      self:__update_grid()
      return true
    end
    return false
  end
  self:__add_component(c)
  self.__line_navigator = c
end

--------------------------------------------------------------------------------

function StepSequencer:__build_track()
  --  track (sideways scrolling)
  local c = UISpinner(self.display)
  c.group_name = self.mappings.track.group_name
  c.tooltip = self.mappings.track.description
  c:set_pos(self.mappings.track.index)
  c.text_orientation = HORIZONTAL
  c.on_change = function(obj) 
    if (not self.active) then return false end
    self.__track_offset = obj.index*self.__width
    self:__update_grid()
    return true
  end
  self:__add_component(c)
  self.__track_navigator = c
end

--------------------------------------------------------------------------------

function StepSequencer:__build_grid()
  self.__buttons = {}
  for x=1,self.__width do
    -- construct 2d tables
    self.__buttons[x] = {}
    self.__keys_down[x] = {}
    self.__toggle_exempt[x] = {}

    for y=1,self.__height do

      local c = UIBasicButton(self.display)
      c.group_name = self.mappings.grid.group_name
      c.tooltip = self.mappings.grid.description
      c.x_pos = x
      c.y_pos = y
      c.active = false

      -- grid toggling
      c.on_press = function(obj)
        if (not self.active) then return false end
        return self:__process_grid_event(x, y, true,obj)
      end
      c.on_release = function(obj)
      if (not self.active) then return false end
        return self:__process_grid_event(x, y, false,obj)
      end
      
      -- hold to "pick up" note, volume & instrument (ie copy step)
      c.on_hold = function(obj)
        if (not self.active) then return false end
        -- check if we're holding multiple keys
        local held = self:walk_held_keys(nil, false)
        if (held == 1) then
          self.__toggle_exempt[x][y] = true
          self:__copy_grid_button(x,y,obj)
          
          -- make it blink off (visual feedback)
          local palette = {}
          palette.foreground = table.rcopy(self.palette.slot_empty)
          obj:set_palette(palette)
          self.__update_grid_requested = true
        end
      end
      self:__add_component(c)
      self.__buttons[x][y] = c

    end  
  end
end

--------------------------------------------------------------------------------

function StepSequencer:__build_level()

  -- figure out the number of rows in our level-slider group

  local cm = self.display.device.control_map
  local rows = cm:count_rows(self.mappings.level.group_name)

  -- level buttons
  local c = UIButtonStrip(self.display)
  c.group_name = self.mappings.level.group_name
  c.tooltip = self.mappings.level.description
  c.toggleable = false
  c.monochrome = is_monochrome(self.display.device.colorspace)
  c.mode = c.MODE_INDEX
  c.flipped = true
  c:set_size(rows)
  c.on_index_change = function(obj) 
    
    if not self.active then 
      return false 
    end

    local idx = obj:get_index()
    local idx_flipped = obj.__size-obj:get_index()+1
    local newval = (127/(obj.__size-1)) * (idx_flipped-1)

    -- check for held grid notes
    local held = self:walk_held_keys(
      function(x,y)
        local note = renoise.song().selected_pattern.tracks[x+self.__track_offset]:line(y+self.__edit_page*self.__height).note_columns[1]
        note.volume_value = newval
      end,
      true
    )
    if (held == 0) then -- no keys down, change basenote instead of transpose
      self.options.base_volume.value = newval
    end
    self.__update_grid_requested = true
    
    -- draw buttons
    local p = { }
    if (newval == 0) then
      p = table.rcopy(self.palette.slot_muted)
    else 
      p = self:__volume_palette(newval, 127)
    end
    --c.palette.index = p
    c.palette.range = p
    c:set_range(idx,obj.__size)
    c:invalidate()
    
    return true
  end
  self:__add_component(c)
  self.__level = c


end

--------------------------------------------------------------------------------

function StepSequencer:__build_transpose()
  self.__transpose = { }
  local transposes = { -12, -1, 1, 12 }
  for k,v in ipairs(transposes) do
    
    local c = UIBasicButton(self.display)
    c.group_name = self.mappings.transpose.group_name
    c.tooltip = self.mappings.transpose.description
    c:set_pos(self.mappings.transpose.index+(k-1))
    c.active = false
    c.transpose = v
    
    c.on_press = function(obj)
      if not self.active then return false end
      
      -- check for held grid notes
      local held = self:walk_held_keys(
        function(x,y)
          local note = renoise.song().selected_pattern.tracks[x+self.__track_offset]:line(y+self.__edit_page*self.__height).note_columns[1]
          local newval = note.note_value + obj.transpose
          if (newval > 0 and newval < 120) then 
            note.note_value = newval
          end
        end,
        true
      )
      if (held == 0) then -- no keys down, change basenote instead of transpose
        self:__transpose_basenote(obj.transpose)
      end
    end
    
    self:__add_component(c)
    self.__transpose[k] = c
    
  end
end

--------------------------------------------------------------------------------

-- periodic updates: handle "un-observable" things here
function StepSequencer:on_idle()
  if (not self.active) then return end
  
  -- did we change current_pattern? (why is this not observable?)
  if (self.__current_pattern ~= renoise.song().selected_pattern_index) then
    self.__current_pattern = renoise.song().selected_pattern_index
    self.__update_lines_requested = true
  end


  -- check update flags
  if (self.__update_tracks_requested) then
    self.__update_grid_requested = true
    self.__update_tracks_requested = false
    self:__update_track_count()
  end
  -- 
  if (self.__update_lines_requested) then
    self.__update_grid_requested = true
    self.__update_lines_requested = false
    self:__update_line_count()
  end
  
  if (self.__update_grid_requested) then
    self.__update_grid_requested = false
    self:__update_grid()
    self:__update_level()
    self:__update_transpose()
  end
  
  if renoise.song().transport.playing then
    self:__update_position()
  else
    -- clear level?
    self:__draw_position(0)
  end
end

--------------------------------------------------------------------------------

function StepSequencer:__update_track_count()
  TRACE("StepSequencer:__update_track_count")
  self.__track_navigator:set_range(nil, math.floor((get_master_track_index()-2)/self.__width))
end

--------------------------------------------------------------------------------

function StepSequencer:__update_position()
  -- can we see the current step?
  local pos = renoise.song().transport.playback_pos.line
  if ((self.__edit_page)*self.__height < pos and pos < (self.__edit_page+1)*self.__height +1) then
    self:__draw_position(((pos-1)%self.__height)+1)
  else
    self:__draw_position(0)
  end
end

--------------------------------------------------------------------------------

function StepSequencer:__draw_position(idx)
  self.__level:set_index(idx,true)
  self.__level:invalidate()
end

--------------------------------------------------------------------------------

function StepSequencer:__update_line_count()
  TRACE("StepSequencer:__update_line_count()")
  self.__line_navigator:set_range(0, (math.floor(renoise.song().selected_pattern.number_of_lines)/self.__height)-1)
end

--------------------------------------------------------------------------------

function StepSequencer:__update_grid()
  if (not self.active) then return end

  -- loop through grid & buttons
  local button = nil
  local note = nil
  local line_offset = self.__edit_page*self.__height
  local master_idx = get_master_track_index()
  local track_count = #renoise.song().tracks
  for track_idx = (1+self.__track_offset),(self.__width+self.__track_offset) do
    for line_idx = (1+line_offset),(self.__height+line_offset) do
      button = self.__buttons[track_idx-self.__track_offset][line_idx-line_offset]
      if(line_idx <= renoise.song().selected_pattern.number_of_lines) and
      (renoise.song().selected_pattern.tracks[track_idx]) and
      (renoise.song().selected_pattern.tracks[track_idx]:line(line_idx)) then
        note = nil
        if (track_idx <= track_count) then
          note = renoise.song().selected_pattern.tracks[track_idx]:line(line_idx).note_columns[1]
        end
        self:__draw_grid_button(button, note)
      end
    end
  end
end

--------------------------------------------------------------------------------

function StepSequencer:__update_level()
  if (not self.active) then return end
--[[
  local p = { }
  if (self.options.base_volume.value == 0) then
    p = table.rcopy(self.palette.slot_muted)
  else 
    p = self:__volume_palette(self.options.base_volume.value, 127)
  end
  --self.__level.palette.tip = p
  --self.__level:draw()
  self.__level.palette.track = p
  self.__level:invalidate()
]]
end

--------------------------------------------------------------------------------

function StepSequencer:__update_transpose()
  if (not self.active) then return end
  local palette = { }
  for k,btn in ipairs(self.__transpose) do
    palette.foreground = table.rcopy(self.palette.transpose[k])
    btn:set_palette(palette)
  end
  
end

--------------------------------------------------------------------------------

-- binds notifiers
function StepSequencer:__attach_to_song(song)
  TRACE("StepSequencer:__attach_to_song()")
  
  -- song notifiers
  song.tracks_observable:add_notifier(
    function()
      TRACE("StepSequencer:tracks_observable fired...")
      self.__update_tracks_requested = true
    end
  )
  song.patterns_observable:add_notifier(
    function()
      TRACE("StepSequencer:patterns_observable fired...")
      self.__update_lines_requested = true
    end
  )
  
  -- pattern notifiers
  --[[
  song.selected_pattern_observable:add_notifier(
    function()
      TRACE("StepSequencer:patterns_observable fired...")
      self.__update_lines_requested = true
    end
  )
  ]]
end

--------------------------------------------------------------------------------

-- called when a new document becomes available
function StepSequencer:on_new_document()
  TRACE("StepSequencer:on_new_document()")

  self:__attach_to_song(renoise.song())
  self:__update_line_count()
  self:__update_track_count()
  --self:__update_grid()

end

------------------------ STEP SEQUENCER FUNCTIONS
function StepSequencer:__process_grid_event(x,y, state, btn)
  local track_idx = x+self.__track_offset
  local line_idx = y+self.__edit_page*self.__height
  if (track_idx >= get_master_track_index()) then return false end
  
  local note = renoise.song().selected_pattern.tracks[track_idx]:line(line_idx).note_columns[1]
  
  if (state) then -- press
    self.__keys_down[x][y] = true
    if (note.note_string == "OFF" or note.note_string == "---") then
      local base_note = (self.options.base_note.value-1)+(self.options.base_octave.value-1)*12
      self:__set_note(note, base_note, renoise.song().selected_instrument_index-1, self.options.base_volume.value)
      self.__toggle_exempt[x][y] = true
      -- and update the button ...
      self:__draw_grid_button(btn, note)
    end
      
  else -- release
    self.__keys_down[x][y] = nil
    if (not self.__toggle_exempt[x][y]) then -- don't toggle off if we just turned on
      self:__clear_note(note)
      -- and update the button ...
      self:__draw_grid_button(btn, note)
    else
      self.__toggle_exempt[x][y] = nil
    end
  end
  return true
end

function StepSequencer:__copy_grid_button(lx,ly, btn)
  local gx = lx+self.__track_offset
  local gy = ly+self.__edit_page*self.__height
  if (gx >= get_master_track_index()) then return false end
  local note = renoise.song().selected_pattern.tracks[gx]:line(gy).note_columns[1]
  
  -- copy note to base note
  if (note.note_value < 120) then
    self:__set_basenote(note.note_value)
  end
  -- copy volume to base volume
  if (note.volume_value <= 127) then
    self.options.base_volume.value = note.volume_value
  end
  -- change selected instrument
  if (note.instrument_value < #renoise.song().instruments) then
    renoise.song().selected_instrument_index = note.instrument_value+1
  end
  
  return true
end

function StepSequencer:__set_note(note_obj, note, instrument, volume)
  note_obj.note_value = note
  note_obj.instrument_value = instrument
  note_obj.volume_value = volume
end
function StepSequencer:__clear_note(note_obj)
  self:__set_note(note_obj, 121, 255, 255)
end

function StepSequencer:__draw_grid_button(button, note)
  if (button ~= nil) then 
    local palette = {}
    
    if (note ~= nil) then
      if (note.note_value == 121) then
        palette.foreground = table.rcopy(self.palette.slot_empty)
      elseif (note.note_value == 120 or note.volume_value == 0) then
        palette.foreground = table.rcopy(self.palette.slot_muted)
      else
        palette.foreground = self:__volume_palette(note.volume_value, 127)
      end
    
    else
      palette.foreground = table.rcopy(self.palette.out_of_bounds)
    end
    
    button:set_palette(palette)
  end
end

function StepSequencer:__volume_palette(vol, max)
  if (vol > max) then vol = max end
  local vol_level = 1+ math.floor(vol / max * (#self.palette.slot_level-1))
  return table.rcopy(self.palette.slot_level[vol_level])
end

function StepSequencer:__set_basenote(note_value)
  local note = note_value % 12 +1
  local oct = math.floor(note_value / 12) +1
  self.options.base_note.value = note
  self.options.base_octave.value = oct
end
function StepSequencer:__transpose_basenote(steps)
  local baseNote = (self.options.base_note.value-1)+(self.options.base_octave.value-1)*12
  local newval = baseNote + steps
  if (0 <= newval and newval < 120) then
    self:__set_basenote(newval)
  end
end

-- apply a function to all held grid buttons, optionally adding them all to toggle_exempt table.  return the number of held keys
function StepSequencer:walk_held_keys(callback, toggleExempt)
  local newval = nil
  local note = nil
  local ct = 0 -- count as we go through pairs.  # keysDown doesn't seem to work all the time?
  for x,row in pairs(self.__keys_down) do
    for y,down in pairs(row) do
      if (down) then
        ct = ct + 1
        if (callback ~= nil) then
          callback(x,y)
        end
        if (toggleExempt) then
          self.__toggle_exempt[x][y] = true
        end
      end
    end
  end
  return ct
end


--[[----------------------------------------------------------------------------
-- Duplex.UIBasicButton
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent > UIBasicButton
Requires: Globals, Display, MessageStream, CanvasPoint

About

UIBasicButton is a general purpose button with press & release handlers, 
with limited support for input methods - only the "button" type is fully
supported (see UIToggleButton for a more widely supported type).

Note: since this type of button has no internal on/off state, and you want
to turn the light off for a LED-based controller, you need to output a 
completely black color (0x00,0x00,0x00)


Supported input methods

- button
- togglebutton*

* release/hold events are not supported for this type 


Events

  on_press()
  on_release()
  on_hold()


--]]


--==============================================================================

class 'UIBasicButton' (UIComponent)

function UIBasicButton:__init(display)
  TRACE('UIBasicButton:__init')

  UIComponent.__init(self,display)

  self.palette = {
    foreground = table.rcopy(display.palette.color_1),
    --background = table.rcopy(display.palette.background)
  }

  self.add_listeners(self)
  
  -- external event handlers
  self.on_press = nil
  self.on_release = nil
  self.on_hold = nil

end


--------------------------------------------------------------------------------

-- user input via button

function UIBasicButton:do_press()
  TRACE("UIBasicButton:do_press()")

  if (self.on_press ~= nil) then
    local msg = self:get_msg()
    if not (self.group_name == msg.group_name) then
      return 
    end
    if not self:test(msg.column,msg.row) then
      return 
    end
    self:on_press()
  end

end

-- ... and release

function UIBasicButton:do_release()
  TRACE("UIBasicButton:do_release()")

  if (self.on_release ~= nil) then
    local msg = self:get_msg()
    if not (self.group_name == msg.group_name) then
      return 
    end
    if not self:test(msg.column,msg.row) then
      return 
    end
    self:on_release()
  end

end


--------------------------------------------------------------------------------

-- user input via (held) button
-- on_hold() is the optional handler method

function UIBasicButton:do_hold()
  TRACE("UIBasicButton:do_hold()")

  if (self.on_hold ~= nil) then
    local msg = self:get_msg()
    if not (self.group_name == msg.group_name) then
      return 
    end
    if not self:test(msg.column,msg.row) then
      return 
    end
    self:on_hold()
  end

end

--------------------------------------------------------------------------------

function UIBasicButton:draw()
  TRACE("UIBasicButton:draw")

  local color = self.palette.foreground
  local point = CanvasPoint()
  point:apply(color)
  -- if the color is completely dark, this is also how
  -- LED buttons will represent the value (turned off)
  if(get_color_average(color.color)>0x00)then
    point.val = true        
  else
    point.val = false        
  end
  self.canvas:fill(point)
  UIComponent.draw(self)

end


--------------------------------------------------------------------------------

function UIBasicButton:add_listeners()

  self.__display.device.message_stream:add_listener(
    self, DEVICE_EVENT_BUTTON_PRESSED,
    function() self:do_press() end )

  self.__display.device.message_stream:add_listener(
    self,DEVICE_EVENT_BUTTON_HELD,
    function() self:do_hold() end )

  self.__display.device.message_stream:add_listener(
    self,DEVICE_EVENT_BUTTON_RELEASED,
    function() self:do_release() end )

end


--------------------------------------------------------------------------------

function UIBasicButton:remove_listeners()

  self.__display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_PRESSED)

  self.__display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_HELD)
    
  self.__display.device.message_stream:remove_listener(
    self,DEVICE_EVENT_BUTTON_RELEASED)

end
