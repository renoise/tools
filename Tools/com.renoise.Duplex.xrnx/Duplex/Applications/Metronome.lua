--[[----------------------------------------------------------------------------
-- Duplex.Metronome
-- Inheritance: Application > Metronome
----------------------------------------------------------------------------]]--

--[[

  This is our sample Metronome application 

--]]

--==============================================================================


class 'Metronome' (Application)

Metronome.default_options = {}

function Metronome:__init(process,mappings,options,cfg_name,palette)

  self.mappings = {
    toggle = {
      description = "Metronome: toggle on/off"
    }
  }
  self.palette = {
    enabled   = { color = {0xFF,0x80,0x80}, text = "M", val=true  },
    disabled  = { color = {0x00,0x00,0x00}, text = "M", val=false }
  }

  Application.__init(self,process,mappings,options,cfg_name,palette)

end

--------------------------------------------------------------------------------

-- check configuration, build & start the application

function Metronome:start_app()

  if not Application.start_app(self) then
    return
  end
  self:update()

end

--------------------------------------------------------------------------------

-- construct the user interface

function Metronome:_build_app()

  local c = UIButton(self.display)
  c.group_name = self.mappings.toggle.group_name
  c:set_pos(self.mappings.toggle.index)
  c.tooltip = self.mappings.toggle.description
  c.on_press = function(obj)
    if not self.active then
      return false
    end
    local enabled = renoise.song().transport.metronome_enabled
    renoise.song().transport.metronome_enabled = not enabled
    self:update()
  end
  self:_add_component(c)
  self._toggle = c

  -- attach to song at first run
  self:_attach_to_song()

  return true

end

--------------------------------------------------------------------------------

-- set button to current state

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

-- called whenever a new document becomes available

function Metronome:on_new_document()
  self:_attach_to_song()
end

--------------------------------------------------------------------------------

-- attach notifier to the song, handle changes

function Metronome:_attach_to_song()

  renoise.song().transport.metronome_enabled_observable:add_notifier(
    function()
      self:update()
    end
  )

end
