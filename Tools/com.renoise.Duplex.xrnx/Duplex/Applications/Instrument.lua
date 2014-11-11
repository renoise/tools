--[[============================================================================
-- Duplex.Application.Instrument
============================================================================]]--

--[[--
Take control of the Renoise Instrument (tutorial).


### Changes

  0.99.3
    - First release



--]]

--==============================================================================


class 'Instrument' (Application)

--Instrument.default_options = {}

Instrument.available_mappings = {
  prev_scale = {
    description = "Instrument: select the previous harmonic scale",
  },
  next_scale = {
    description = "Instrument: select the next harmonic scale",
  },
  label_scale = {
    description = "Instrument: display name of current scale",
  },
  set_key = {
    description = "Instrument: select the harmonic key",
    orientation = ORIENTATION.HORIZONTAL,
    flipped = true,
  },
}

Instrument.default_palette = {
  scale_prev_enabled  = { color = {0xFF,0xff,0xff}, text="-≣", val=true  },
  scale_prev_disabled = { color = {0x00,0x00,0x00}, text="-≣", val=false },
  scale_next_enabled  = { color = {0xFF,0xff,0xff}, text="+≣", val=true  },
  scale_next_disabled = { color = {0x00,0x00,0x00}, text="+≣", val=false },

  key_select_enabled   = { color = {0xFF,0xff,0xff}, val=true  },
  key_select_disabled  = { color = {0x00,0x00,0x00}, text="·", val=false },

}

Instrument.SCALE_KEYS = { "C","C♯","D","D♯","E","F","F♯","G","G♯","A","A♯","B" }



--------------------------------------------------------------------------------

--- Constructor method
-- @param (VarArg)
-- @see Duplex.Application

function Instrument:__init(...)

  self._controls = {}

  Application.__init(self,...)

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.start_app
-- @return bool or nil

function Instrument:start_app()

  if not Application.start_app(self) then
    return
  end
  self:update()

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application._build_app
-- @return bool

function Instrument:_build_app()

  local map = self.mappings.prev_scale
  if map.group_name then
    local c = UIButton(self,map)
    c.on_press = function(obj)
      local instr = renoise.song().selected_instrument
      local scale_mode = instr.trigger_options.scale_mode
      local scale_idx = HARMONIC_SCALES[scale_mode].index
      for k,v in pairs(HARMONIC_SCALES) do
        if (v.index==scale_idx-1) then
          scale_mode = k
          break
        end
      end
      instr.trigger_options.scale_mode = scale_mode
    end
    c.on_hold = function(obj)
      local instr = renoise.song().selected_instrument
      instr.trigger_options.scale_mode = "None"
    end
    self._controls.prev_scale = c
  end

  local map = self.mappings.next_scale
  if map.group_name then
    local c = UIButton(self,map)
    c.on_press = function(obj)
      local instr = renoise.song().selected_instrument
      local scale_mode = instr.trigger_options.scale_mode
      local scale_idx = HARMONIC_SCALES[scale_mode].index
      for k,v in pairs(HARMONIC_SCALES) do
        if (v.index==scale_idx+1) then
          scale_mode = k
          break
        end
      end
      instr.trigger_options.scale_mode = scale_mode
    end
    c.on_hold = function(obj)
      local instr = renoise.song().selected_instrument
      local scale_count = table_count(HARMONIC_SCALES)
      for k,v in pairs(HARMONIC_SCALES) do
        if (v.index==scale_count) then
          instr.trigger_options.scale_mode = k
          break
        end
      end
    end
    self._controls.next_scale = c
  end

  local map = self.mappings.set_key
  if map.group_name then
    
    -- assigned to buttons?
    local slider_size = 1
    local cm = self.display.device.control_map
    if (cm:is_grid_group(map.group_name)) then
      slider_size = cm:get_group_size(map.group_name)
      --map.orientation = ORIENTATION.NONE
    end
    --print("slider_size",slider_size)

    local c = UISlider(self,map)
    c:set_size(slider_size)
    c.on_change = function()
      local instr = renoise.song().selected_instrument
      instr.trigger_options.scale_key = c.index
    end
    self._controls.set_key = c
  end

  -- attach to song at first run
  self:_attach_to_song()

  return true

end

--------------------------------------------------------------------------------

--- set button to current state

function Instrument:update()

  self:update_scale_controls()

end

--------------------------------------------------------------------------------

--- set button to current state

function Instrument:update_scale_controls()
  TRACE("Instrument:update_scale_controls()")

  local instr = renoise.song().selected_instrument
  local scale_mode = instr.trigger_options.scale_mode
  local scale_idx = HARMONIC_SCALES[scale_mode].index

  local ctrl = self._controls.prev_scale
  if ctrl then
    if (scale_idx == 1) then
      ctrl:set(self.palette.scale_prev_disabled)
    else
      ctrl:set(self.palette.scale_prev_enabled)
    end
  end

  local ctrl = self._controls.next_scale
  if ctrl then
    if (scale_idx == table_count(HARMONIC_SCALES)) then
      ctrl:set(self.palette.scale_next_disabled)
    else
      ctrl:set(self.palette.scale_next_enabled)
    end
  end

  local ctrl = self._controls.set_key
  if ctrl then
    local palette = {}
    palette.tip = table.rcopy(self.palette.key_select_enabled)
    palette.tip.text = Instrument.SCALE_KEYS[instr.trigger_options.scale_key]
    palette.track = table.rcopy(self.palette.key_select_disabled)
    ctrl:set_palette(palette)
    ctrl:set_index(instr.trigger_options.scale_key)
  end



end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_new_document

function Instrument:on_new_document()
  self:_attach_to_song()
end

--------------------------------------------------------------------------------

--- attach notifier to the song, handle changes

function Instrument:_attach_to_song()

  -- immediately attach to instrument 
  self:_attach_to_instrument()

end

--------------------------------------------------------------------------------

--- attach notifier to the instrument

function Instrument:_attach_to_instrument()

  local instr = renoise.song().selected_instrument

  -- update when selected scale changes
  instr.trigger_options.scale_mode_observable:add_notifier(
    function(notifier)
      --print("scale_mode_observable fired...")
      self:update_scale_controls()
    end
  )

  -- update when selected scale changes
  instr.trigger_options.scale_key_observable:add_notifier(
    function(notifier)
      --print("scale_key_observable fired...")
      self:update_scale_controls()
    end
  )


end
