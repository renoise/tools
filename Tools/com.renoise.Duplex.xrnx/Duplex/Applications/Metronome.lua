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

function Metronome:__init(display,mappings,options,config_name)

  self.mappings = {
    toggle = {
      description = "Metronome: toggle on/off"
    }
  }

  Application.__init(self,display,mappings,options,config_name)

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

  local c = UIToggleButton(self.display)
  c.group_name = self.mappings.toggle.group_name
  c:set_pos(self.mappings.toggle.index)
  c.on_change = function(obj)
    if not self.active then
      return false
    end
    renoise.song().transport.metronome_enabled = obj.active
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
    self._toggle:set(renoise.song().transport.metronome_enabled)
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
      if self._toggle then
        self._toggle:set(renoise.song().transport.metronome_enabled)
      end
    end
  )

end
