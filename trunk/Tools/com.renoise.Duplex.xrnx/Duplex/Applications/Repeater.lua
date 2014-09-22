--[[============================================================================
-- Duplex.Repeater
============================================================================]]--

--[[--
Take control of the native repeater DSP device.
Inheritance: @{Duplex.Application} > @{Duplex.RoamingDSP} > Duplex.Application.Repeater 


### Changes 

  0.98
    - First release

--]]

--==============================================================================

-- constants

local DIVISORS = {1/1,1/2,1/4,1/8,1/16,1/32,1/64,1/128}
local HOLD_ENABLED = 1
local HOLD_DISABLED = 2
local MODE_OFF = 0
local MODE_FREE = 1
local MODE_EVEN = 2
local MODE_TRIPLET = 3
local MODE_DOTTED = 4
local MODE_AUTO = 5

--==============================================================================

class 'Repeater' (RoamingDSP)

Repeater.default_options = {
  mode_select = {
    label = "Mode select",
    description = "Determine the working mode of the grid:"
                .."\nFree: scale between 1/1 and 1/128"
                .."\nEven: display only 'even' divisors"
                .."\nTriplet: display only 'triplet' divisors"
                .."\nDotted: display only 'dotted' divisors"
                .."\nAutomatic: display 'even','triplet' and 'dotted' "                
                .."\n  divisors, each on a separate line (automatic layout)",
    items = {
      "Free",
      "Even",
      "Triplet",
      "Dotted",
      "Automatic",
    },
    value = 5,
    on_change = function(app)
      app:init_grid()
    end
  },
  hold_option = {
    label = "Hold option",
    description = "Determine what to do when a button is released",
    items = {
      "Continue (hold)",
      "Stop (hold off)",
    },
    value = 1,
    on_change = function(app)
      if (app.options.hold_option.value == HOLD_DISABLED) then
        app:stop_repeating()
      end
    end
  },
  divisor_min = {
    label = "Divisor (min) ",
    hidden = true,
    description = "Specify the minimum divisor value",
    items = {
      "1/1",
      "1/2",
      "1/4",
      "1/8",
      "1/16",
      "1/32",
      "1/64",
      "1/128",
    },
    value = 1,
    on_change = function(app)
      app:init_grid()
    end
  },
  divisor_max = {
    label = "Divisor (max) ",
    hidden = true,
    description = "Specify the minimum divisor value",
    items = {
      "1/1",
      "1/2",
      "1/4",
      "1/8",
      "1/16",
      "1/32",
      "1/64",
      "1/128",
    },
    value = 8,
    on_change = function(app)
      app:init_grid()
    end
  },
}

--- available_mappings
-- @field grid
-- @field divisor_slider
-- @field mode_slider
-- @field mode_even
-- @field mode_triplet
-- @field mode_dotted
-- @field mode_free
-- @table available_mappings
Repeater.available_mappings = {
  grid = {
    description = "Repeater: button grid"
  },
  divisor_slider = {
    description = "Repeater: Control divisor using a fader/knob",
  },
  mode_slider = {
    description = "Repeater: Control mode using a fader/knob",
  },
  mode_even = {
    description = "Repeater: Set mode to 'even'",
  },
  mode_triplet = {
    description = "Repeater: Set mode to 'triplet'",
  },
  mode_dotted = {
    description = "Repeater: Set mode to 'triplet'",
  },
  mode_free = {
    description = "Repeater: Set mode to 'free'",
  },
}

Repeater.default_palette = {
  enabled           = { color = {0xFF,0xFF,0xFF}, val=true  },
  disabled          = { color = {0x00,0x00,0x00}, val=false },
  mode_on           = { color = {0xFF,0xFF,0xFF}, text = "■", val=true  },
  mode_off          = { color = {0x00,0x00,0x00}, text = "·", val=false },
  mode_even_on      = { color = {0xFF,0xFF,0xFF}, text = "E", val=true  },
  mode_even_off     = { color = {0x00,0x00,0x00}, text = "E", val=false },
  mode_triplet_on   = { color = {0xFF,0xFF,0xFF}, text = "T", val=true  },
  mode_triplet_off  = { color = {0x00,0x00,0x00}, text = "T", val=false },
  mode_dotted_on    = { color = {0xFF,0xFF,0xFF}, text = "D", val=true  },
  mode_dotted_off   = { color = {0x00,0x00,0x00}, text = "D", val=false },
  mode_free_on      = { color = {0xFF,0xFF,0xFF}, text = "F", val=true  },
  mode_free_off     = { color = {0x00,0x00,0x00}, text = "F", val=false },

}

--  merge superclass options, mappings & palette --

for k,v in pairs(RoamingDSP.default_options) do
  Repeater.default_options[k] = v
end
for k,v in pairs(RoamingDSP.available_mappings) do
  Repeater.available_mappings[k] = v
end
for k,v in pairs(RoamingDSP.default_palette) do
  Repeater.default_palette[k] = v
end

--------------------------------------------------------------------------------

--- Constructor method
-- @param (VarArg)
-- @see Duplex.Application

function Repeater:__init(...)
  TRACE("Repeater:__init()")

  --- the name of the device we are controlling
  self._instance_name = "Repeater"

  --- update display
  self.update_requested = true

  --- boolean, set to temporarily skip value notifier
  self.suppress_value_observable = false

  --- the various UIComponents
  self._grid = nil          -- UIButtons...
  self._mode_slider = nil   -- UISlider
  self._mode_even = nil     -- UIButton
  self._mode_triplet = nil  -- UIButton
  self._mode_dotted = nil   -- UIButton
  self._mode_free = nil     -- UIButton
  self._divisor_slider = nil -- UISlider

  --- (int), grid size in units
  self._grid_width = nil
  self._grid_height = nil

  --- table, organized by [x][y], each containing the following
  --    divisor (number), the divisor value
  --    mode (int), the mode value (0-4)
  --    tooltip (string)
  self._grid_map = table.create()

  --- (table or nil) in grid mode, current coordinate 
  --    x=number
  --    y=number
  self._grid_coords = nil

  --- (enum) default automation mode is points (recommended)
  self.playmode = renoise.PatternTrackAutomation.PLAYMODE_POINTS

  RoamingDSP.__init(self,...)


end

--------------------------------------------------------------------------------

--- perform periodic updates

function Repeater:on_idle()

  if (not self.active) then 
    return 
  end

  if self.current_device_requested then
    self.update_requested = true
  end

  if self.update_requested then
    self.update_requested = false
    self:set_mode()
    self:set_divisor()
    self:update_grid()
  end


  RoamingDSP.on_idle(self)


end


--------------------------------------------------------------------------------

--- attach notifier to the device 
-- called when we use previous/next device, set the initial device
-- or are freely roaming the tracks

function Repeater:attach_to_device(track_idx,device_idx,device)
  TRACE("Repeater:attach_to_device()",track_idx,device_idx,device)

  -- clear observables, attach to track (if needed)
  RoamingDSP.attach_to_device(self,track_idx,device_idx,device)

  -- listen for changes to the mode/divisor parameters
  local mode_param = self:get_device_param("Mode")
  self._parameter_observables:insert(mode_param.value_observable)
  mode_param.value_observable:add_notifier(
    self, 
    function()
      if not self.suppress_value_observable then
        TRACE("Repeater - mode_param fired...")
        self.update_requested = true
      end
    end 
  )
  local divisor_param = self:get_device_param("Divisor")
  self._parameter_observables:insert(divisor_param.value_observable)
  divisor_param.value_observable:add_notifier(
    self, 
    function()
      if not self.suppress_value_observable then
        TRACE("Repeater - divisor_param fired...")
        self.update_requested = true
      end
    end 
  )


end


--------------------------------------------------------------------------------

--- (grid mode) update everything: the mode and/or divisor value is gained
-- and the grid cells are drawn accordingly. Also, record automation. 

function Repeater:set_value_from_coords(x,y)
  TRACE("Repeater:set_value_from_coords()",x,y)

  if not self.target_device then
    return
  end

  local cell = self._grid_map[x][y]

  -- check if out-of-bounds 
  if not cell.divisor then
    return
  end

  -- check if already active, and toggle state
  if self._grid_coords then
    if (x == self._grid_coords.x) and 
      (y == self._grid_coords.y) 
    then
      self:stop_repeating()
      -- TODO if button is held, toggle "hold" mode
      return
    end
  end
  
  -- apply values + record automation
  self:set_divisor(cell.divisor)
  self:set_mode(cell.mode)

  self:update_grid(x,y)

end

--------------------------------------------------------------------------------

-- switch the mode (update device, mode buttons/slider)
-- @param enum_mode (int) one of the MODE_xx constants
-- @param toggle (boolean) when mode-select button is pushed

function Repeater:set_mode(enum_mode,toggle)
  TRACE("Repeater:set_mode(enum_mode,toggle)",enum_mode,toggle)

  if not self.target_device then
    return 
  end

  local mode_param = self:get_device_param("Mode")

  -- return if value hasn't changed
  if (mode_param.value == enum_mode) then
    return
  end

  if (enum_mode == nil) then
    -- if no value was provided, use the device value
    enum_mode = mode_param.value
  else

    -- update device
    self.suppress_value_observable = true
    mode_param.value = enum_mode
    self.suppress_value_observable = false

  end

  -- update the grid/mode? this is done only if:
  -- (1) the mode isn't MODE_OFF (this mode isn't selectable)
  -- (2) a mode button was pushed (the "toggle" argument)
  -- (3) grid button pushed while in even, triplet or dotted mode 
  if (enum_mode ~= MODE_OFF) then
    if toggle or (not toggle and 
      --(self.options.mode_select.value ~= MODE_FREE) and 
      (self.options.mode_select.value ~= MODE_AUTO))
    then
      self:_set_option("mode_select",enum_mode,self._process)
    end
  end

  -- update the slider
  if self._mode_slider then
    local skip_event = true
    self._mode_slider:set_value(enum_mode/4,skip_event)
  end

  -- update the buttons
  if enum_mode ~= MODE_OFF then
    if self._mode_even then
      if enum_mode == MODE_EVEN then
        self._mode_even:set(self.palette.mode_even_on)
      else
        self._mode_even:set(self.palette.mode_even_off)
      end
    end
    if self._mode_triplet then
      if enum_mode == MODE_TRIPLET then
        self._mode_triplet:set(self.palette.mode_triplet_on)
      else
        self._mode_triplet:set(self.palette.mode_triplet_off)
      end
    end
    if self._mode_dotted then
      if enum_mode == MODE_DOTTED then
        self._mode_dotted:set(self.palette.mode_dotted_on)
      else
        self._mode_dotted:set(self.palette.mode_dotted_off)
      end
    end
    if self._mode_free then
      if enum_mode == MODE_FREE then
        self._mode_free:set(self.palette.mode_free_on)
      else
        self._mode_free:set(self.palette.mode_free_off)
      end
    end
  end

  -- update automation
  self:update_automation(self.track_index,mode_param,enum_mode/4,self.playmode)

end

--------------------------------------------------------------------------------

--- Update divisor (call without argument to use existing value)
-- @param divisor_val (number) [optional] between 0 and 1

function Repeater:set_divisor(divisor_val)
  TRACE("Repeater:set_divisor(divisor_val)",divisor_val)

  if not self.target_device then
    return 
  end

  local divisor_param = self:get_device_param("Divisor")

  if divisor_val then

    -- update device
    local str_value = ("1/%f"):format(1/divisor_val)
    self.suppress_value_observable = true
    divisor_param.value_string = str_value
    self.suppress_value_observable = false
  end

  -- update the slider
  if self._divisor_slider then
    local skip_event = true
    self._divisor_slider:set_value(divisor_param.value,skip_event)
  end

  -- update automation
  self:update_automation(self.track_index,divisor_param,divisor_param.value,self.playmode)

end

--------------------------------------------------------------------------------

--- this method will calculate a the divisor from a linear value
-- (e.g. 0.5 will output 1/8 == 0.125)
-- @param divisor_val (number) between 0 and 1

function Repeater:divisor_from_linear_value(divisor_val)
  TRACE("Repeater:set_divisor_from_linear_value(divisor_val)",divisor_val)

  if (divisor_val == 0) then
    return 1
  end

  local step_size = 1/8
  local step = math.ceil(divisor_val/step_size)
  local step_fraction = step-(divisor_val/step_size)
  local divisor_val = DIVISORS[step] 
  if (step>1) then
    divisor_val = divisor_val + (DIVISORS[step] * step_fraction)
  end

  return divisor_val

end

--------------------------------------------------------------------------------

--- set device to OFF mode, update controller + automation

function Repeater:stop_repeating()
  TRACE("Repeater:stop_repeating()")

  self:set_mode(MODE_OFF)
  self:update_grid()

end

--------------------------------------------------------------------------------

--- configure a map of mode/divisor values for the available buttons
-- even/triplet/dotted: update divisor value by quantized amount
-- free: update the divisor value by an exact amount

function Repeater:init_grid()
  TRACE("Repeater:init_grid()")

  local map = self.mappings.grid
  if not map.group_name then
    return
  end

  -- clear the current grid display
  self._grid_map = table.create()

  local min_divisor = DIVISORS[self.options.divisor_min.value]
  local max_divisor = DIVISORS[self.options.divisor_max.value]

  local produce_cell = function(mode,value)
    local tooltip = ""
    if value then
      if (mode == MODE_FREE) then
        tooltip = ("%.2f"):format(1/value)
      else
        tooltip = ("%i"):format(1/value)
      end
      if (mode == MODE_TRIPLET) then
        tooltip = tooltip.."T"
      elseif (mode == MODE_DOTTED) then
        tooltip = tooltip.."D"
      end
    end
    local cell = {
      divisor = value,
      mode = mode,
      tooltip = tooltip
    }
    return cell
  end

  if (self.options.mode_select.value == MODE_FREE) then
    
    -- distribute freely across grid

    local count = 1
    --local step_size = 127/((self._grid_width*self._grid_height)-1)
    local step_size = 1/((self._grid_width*self._grid_height))
    for y=1,self._grid_height do
      for x=1,self._grid_width do
        if not self._grid_map[x] then
          self._grid_map[x] = table.create()
        end
        --function scale_value(value,low_val,high_val,min_val,max_val)
        local val = step_size*count
        --local val_scaled = scale_value(val,0,127,min_divisor,max_divisor)
        local val_scaled = self:divisor_from_linear_value(val)
        local cell = {
          divisor = val_scaled,
          mode = MODE_FREE,
          tooltip = ("1/%f"):format(1/val_scaled)
        }
        self._grid_map[x][y] = produce_cell(MODE_FREE,val_scaled)
        count = count+1
      end
    end

  elseif (self.options.mode_select.value == MODE_AUTO) then

    -- automatic layout, will mimic the repeater device
    -- by creating one row for each mode (even/triplet/dotted)

    for x=1,self._grid_width do
      for y=1,self._grid_height do
        if not self._grid_map[x] then
          self._grid_map[x] = table.create()
        end
        local mode = (y==1) and MODE_EVEN 
          or (y==2) and MODE_TRIPLET 
          or (y==3) and MODE_DOTTED

        self._grid_map[x][y] = produce_cell(mode,DIVISORS[x])
      end
    end

  else

    -- fill with quantized intervals

    local count = 1
    for y=1,self._grid_height do
      for x=1,self._grid_width do
        if not self._grid_map[x] then
          self._grid_map[x] = table.create()
        end
        --function scale_value(value,low_val,high_val,min_val,max_val)
        local mode = self.options.mode_select.value
        self._grid_map[x][y] = produce_cell(mode,DIVISORS[count])
        count = count+1
      end
    end

  end

  -- update visual appearance + tooltips
  for x=1,self._grid_width do
    for y=1,self._grid_height do
      local cell = self._grid_map[x][y]
      self._grid[x][y].tooltip = ("Repeater: 1 / %s"):format(cell.tooltip)
      self._grid[x][y]:set_palette({foreground={text=cell.tooltip}})
    end
  end
  self.display:apply_tooltips(self.mappings.grid.group_name)

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application._build_app
-- @return bool

function Repeater:_build_app()
  TRACE("Repeater:_build_app()")
  
  -- start by adding the roaming controls:
  -- lock_button,next_device,prev_device...
  RoamingDSP._build_app(self)

  local cm = self.display.device.control_map

  -- button grid
  local map = self.mappings.grid
  if map.group_name then
    TRACE("Repeater - creating @grid ")
    -- determine if valid target (grid)
    if not cm:is_grid_group(map.group_name) then
      local msg = "Repeater: could not assign 'grid', the control-map group is invalid"
        .."\n(please assign the mapping to a group made entirely from buttons)"
      renoise.app():show_warning(msg)
      --return false
    else
      -- determine the grid size 
      self._grid_width = cm:count_columns(map.group_name)
      self._grid_height = cm:count_rows(map.group_name)

      self._grid = table.create()

      for x=1,self._grid_width do
        self._grid[x] = table.create()
        for y=1,self._grid_height do
          local c = UIButton(self)
          c.group_name = map.group_name
          c:set_pos(x,y)
          c.on_press = function()
            self:set_value_from_coords(x,y)
          end
          c.on_release = function(obj)
            if (self.options.hold_option.value == HOLD_DISABLED) then
              if self._grid_coords and
                (x == self._grid_coords.x) and 
                (y == self._grid_coords.y) 
              then
                self:stop_repeating()
              end
            end
          end
          self._grid[x][y] = c
        end
      end

      -- compute default values
      self:init_grid(self._grid_width,self._grid_height)

    end

  end


  -- mode slider
  local map = self.mappings.mode_slider
  if map.group_name then
    TRACE("Repeater - creating @mode_slider ")
    local c = UISlider(self)
    c.group_name = map.group_name
    c:set_pos(map.index)
    c.tooltip = map.description
    c.on_change = function(obj)
      local mode_val = round_value(obj.value*4)
      self:set_mode(mode_val)
    end
    self._mode_slider = c
  end

  -- divisor slider
  local map = self.mappings.divisor_slider
  if map.group_name then
    local c = UISlider(self)
    c.group_name = map.group_name
    c:set_pos(map.index)
    --c.ceiling = 127
    c.tooltip = map.description
    c.on_change = function(obj)
      local divisor_val = self:divisor_from_linear_value(obj.value)
      self:set_divisor(divisor_val)
      self.update_requested = true

    end
    self._divisor_slider = c
  end

  -- mode_even
  local map = self.mappings.mode_even
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set(self.palette.mode_even_off)
    c:set_pos(map.index)
    c.on_press = function(obj)
      self:set_mode(MODE_EVEN,true)
    end
    self._mode_even = c
  end

  -- mode_triplet
  local map = self.mappings.mode_triplet
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set(self.palette.mode_triplet_off)
    c:set_pos(map.index)
    c.on_press = function(obj)
      self:set_mode(MODE_TRIPLET,true)
    end
    self._mode_triplet = c
  end

  -- mode_dotted
  local map = self.mappings.mode_dotted
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set(self.palette.mode_dotted_off)
    c:set_pos(map.index)
    c.on_press = function(obj)
      self:set_mode(MODE_DOTTED,true)
    end
    self._mode_dotted = c
  end

  -- mode_free
  local map = self.mappings.mode_free
  if map.group_name then
    local c = UIButton(self)
    c.group_name = map.group_name
    c.tooltip = map.description
    c:set(self.palette.mode_free_off)
    c:set_pos(map.index)
    c.on_press = function(obj)
      self:set_mode(MODE_FREE,true)
    end
    self._mode_free = c
  end

  -- attach to song at first run
  self:_attach_to_song()

  return true

end

--------------------------------------------------------------------------------

--- update controller grid (no impact on Renoise)

function Repeater:update_grid(x,y)
  TRACE("Repeater:update_grid(x,y)",x,y)

  if not self.target_device then
    --print("no target device, cannot update grid")
    return
  end

  if not self._grid then
    --print("no grid present, cannot update")
    return
  end

  -- turn off the current button
  if self._grid_coords then
    local old_x = self._grid_coords.x
    local old_y = self._grid_coords.y
    if (old_x ~= x) or (old_y ~= y) then
      local palette = {
        foreground = {
          color = self.palette.disabled.color,
          val = self.palette.disabled.val,
        }
      }
      self._grid[old_x][old_y]:set_palette(palette)
    end
  end

  local mode_param = self:get_device_param("Mode")
  if (mode_param.value ==MODE_OFF) then
    self._grid_coords = nil
    return
  end

  -- determine coords from current device settings
  if not x and not y then
    local mode_divisor = self:get_device_param("Divisor")
    for grid_x=1,self._grid_width do
      for grid_y=1,self._grid_height do
        local cell = self._grid_map[grid_x][grid_y]
        if not cell.divisor or 
          (cell.mode == MODE_OFF) 
        then
          -- ignore unmapped or disabled buttons
        else
          local str_value = nil
          if (cell.mode == MODE_FREE) then
            str_value = ("1 / %.2f"):format(1/cell.divisor)
          else
            str_value = ("1 / %i"):format(1/cell.divisor)
          end
          if (round_value(mode_param.value) == cell.mode) and
            (mode_divisor.value_string == str_value)
          then
            x = grid_x
            y = grid_y
          end
        end
      end
    end
  end

  if x and y and (self._grid[x][y]) then
    local palette = {
      foreground = {
        color = self.palette.enabled.color,
        val = self.palette.enabled.val,
      }
    }
    self._grid[x][y]:set_palette(palette)
    self._grid_coords = {x=x,y=y}
  end


end

