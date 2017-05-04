--[[============================================================================
-- Duplex.Application.Metronome
============================================================================]]--

--[[--

Take control of the Renoise metronome (tutorial).

--]]

--==============================================================================


class 'Metronome' (Application)

Metronome.default_options = {}
Metronome.available_mappings = {
  toggle = {
    description = "Metronome: toggle on/off"
  }
}
Metronome.default_palette = {
  enabled   = { color = {0xFF,0x80,0x80}, text = "M", val=true  },
  disabled  = { color = {0x00,0x00,0x00}, text = "M", val=false }
}


--------------------------------------------------------------------------------

--- Constructor method
-- @param (VarArg)
-- @see Duplex.Application

function Metronome:__init(...)

  Application.__init(self,...)

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.start_app
-- @return bool or nil

function Metronome:start_app()

  if not Application.start_app(self) then
    return
  end
  self:update()

end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application._build_app
-- @return bool

function Metronome:_build_app()

  local map = self.mappings.toggle
  local c = UIButton(self,map)
  c.on_press = function(obj)
    local enabled = renoise.song().transport.metronome_enabled
    renoise.song().transport.metronome_enabled = not enabled
    self:update()
  end
  self._toggle = c

  -- attach to song at first run
  self:_attach_to_song()

  return true

end

--------------------------------------------------------------------------------

--- set button to current state

function Metronome:update()
  if self._toggle then
    if renoise.song().transport.metronome_enabled then
      self._toggle:set(self.palette.enabled)
    else
      self._toggle:set(self.palette.disabled)
    end
  end
end

--------------------------------------------------------------------------------

--- inherited from Application
-- @see Duplex.Application.on_new_document

function Metronome:on_new_document()
  self:_attach_to_song()
end

--------------------------------------------------------------------------------

--- attach notifier to the song, handle changes

function Metronome:_attach_to_song()

  renoise.song().transport.metronome_enabled_observable:add_notifier(
    function()
      self:update()
    end
  )

end
