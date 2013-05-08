--[[----------------------------------------------------------------------------
-- Duplex.PatternSequence
-- Inheritance: Application > PatternSequence
----------------------------------------------------------------------------]]--

--[[

About



Mappings

  display_next
  display_previous	


Options


Changes (equal to Duplex version number)

  0.98  - Initial version


--]]


--==============================================================================

class 'PatternSequence' (Application)

PatternSequence.default_options = {}

PatternSequence.available_mappings = {
  display_next = {
    description = "PatternSequence: Display next pattern",
  },
  display_previous = {
    description = "PatternSequence: Display previous pattern",
  }
}

PatternSequence.default_palette = {
  previous_enabled  = { color={0xff,0xff,0x00}, text="▲", val=true  },
  previous_disabled = { color={0x00,0x00,0x00}, text="▲", val=false },
  next_enabled      = { color={0xff,0xff,0x00}, text="▼", val=true  },
  next_disabled     = { color={0x00,0x00,0x00}, text="▼", val=false },

}

--------------------------------------------------------------------------------

--- Constructor method
-- @param (VarArg), see Application to learn more

function PatternSequence:__init(...)
  TRACE("PatternSequence:__init(",...)

  self._update_pos_requested = false

  -- the various UIComponents
  self.controls = {}

  Application.__init(self,...)

end


--------------------------------------------------------------------------------

function PatternSequence:start_app()
  TRACE("PatternSequence.start_app()")

  if not Application.start_app(self) then
    return
  end

  self:_update_prev_next()

end


--------------------------------------------------------------------------------

function PatternSequence:_build_app()
  TRACE("PatternSequence:_build_app()")

  -- add buttons

  if self.mappings.display_next.group_name then
    local c = UIButton(self)
    c.group_name = self.mappings.display_next.group_name
    c.tooltip = self.mappings.display_next.description
    c:set_pos(self.mappings.display_next.index)
    c.on_press = function(obj)
      self:_display_next()
    end
    c.on_hold = function(obj)
      self:_display_last()
    end
    self:_add_component(c)
    self.controls.next = c
  end

  if self.mappings.display_previous.group_name then
    local c = UIButton(self)
    c.group_name = self.mappings.display_previous.group_name
    c.tooltip = self.mappings.display_previous.description
    c:set_pos(self.mappings.display_previous.index)
    c.on_press = function(obj)
      self:_display_previous()
    end
    c.on_hold = function(obj)
      self:_display_first()
    end
    self:_add_component(c)
    self.controls.previous = c
  end


  -- bind observables
  self:_attach_to_song()

  Application._build_app(self)
  return true

end



--------------------------------------------------------------------------------

-- periodic updates: handle "un-observable" things here
function PatternSequence:on_idle()

  if not self.active then 
    return 
  end
  
  if self._update_pos_requested then
    self._update_pos_requested = false
    self:_update_prev_next()

  end

end

--------------------------------------------------------------------------------

function PatternSequence:_attach_to_song()
  TRACE("PatternSequence:_attach_to_song()")

  renoise.song().selected_sequence_index_observable:add_notifier(
    function(e)
      --TRACE("PatternSequence: selected_sequence_index_observable fired...")
      self._update_pos_requested = true
    end
  )

end


--------------------------------------------------------------------------------

-- called when a new document becomes available

function PatternSequence:on_new_document()
  TRACE("PatternSequence:on_new_document()")

  self:_attach_to_song()

end


--------------------------------------------------------------------------------

function PatternSequence:_get_pattern(idx)

  local patt_seq = renoise.song().sequencer.pattern_sequence
  return patt_seq[idx] 

end


--------------------------------------------------------------------------------

function PatternSequence:_update_prev_next()

  if self.controls.previous then
    local new_idx = renoise.song().selected_sequence_index-1
    local patt = self:_get_pattern(new_idx)
    if patt then
      self.controls.previous:set(self.palette.previous_enabled)
    else
      self.controls.previous:set(self.palette.previous_disabled)
    end
  end
  if self.controls.next then
    local new_idx = renoise.song().selected_sequence_index+1
    local patt = self:_get_pattern(new_idx)
    if patt then
      self.controls.next:set(self.palette.next_enabled)
    else
      self.controls.next:set(self.palette.next_disabled)
    end
  end
end

--------------------------------------------------------------------------------

function PatternSequence:_display_next()

  local new_idx = renoise.song().selected_sequence_index+1
  local patt = self:_get_pattern(new_idx)
  if patt then
    renoise.song().selected_sequence_index = new_idx
  end

end

--------------------------------------------------------------------------------

function PatternSequence:_display_previous()

  local new_idx = renoise.song().selected_sequence_index-1
  local patt = self:_get_pattern(new_idx)
  if patt then
    renoise.song().selected_sequence_index = new_idx
  end

end

--------------------------------------------------------------------------------

function PatternSequence:_display_first()

  renoise.song().selected_sequence_index = 1

end

--------------------------------------------------------------------------------

function PatternSequence:_display_last()

  local new_idx = #renoise.song().sequencer.pattern_sequence
  local patt = self:_get_pattern(new_idx)
  if patt then
    renoise.song().selected_sequence_index = new_idx
  end

end
