--[[============================================================================
vControl
============================================================================]]--

require (_vlibroot.."vView")

class 'vControl' (vView)

--------------------------------------------------------------------------------
--- Control is the base class for all views which let the user change a 
-- value or some "state" from the UI

function vControl:__init(...)

  local args = cLib.unpack_args(...)

  -- properties -----------------------

  --- (bool, r/w) active property of this control
  -- note: implemented differently from class to class...
  self.active = property(self.get_active,self.set_active)
  self._active = args.active or true

  --- (string) define name of the midi-mapping 
  -- note: supply a similarly-named function to establish
  -- actual handling of midi messages in your tool... 
  self.midi_mapping = property(self.get_midi_mapping,self.set_midi_mapping)
  self._midi_mapping = args.midi_mapping or nil 

  -- internal -------------------------

	vView.__init(self,...)

end

--------------------------------------------------------------------------------
-- request update() - either the control will update immediately, or 
-- at a later time (lazy_updates, a vLib static property) 

function vControl:request_update()
  TRACE("vControl:request_update()")
  
  if not self.update then
    return
  end

  if not vLib.lazy_updates then
    self:update()
  else
    if not renoise.tool():has_timer({self,self.perform_update}) then
      renoise.tool():add_timer({self,self.perform_update},10)
    end
  end

end

--------------------------------------------------------------------------------
--- perform a scheduled update and clear the timer

function vControl:perform_update()
  TRACE("vControl:perform_update(self)",self)

  if renoise.tool():has_timer({self,self.perform_update}) then
    renoise.tool():remove_timer({self,self.perform_update})
  end


  self:update()

end

--------------------------------------------------------------------------------
-- invoke this method as the last step when implementing your own method
-- it will confirm the existence of required properties

function vControl:build()
  TRACE("vControl:build()")

  if (type(self.id)=="nil") then
    error("vLib components need unique IDs")
  end

  if (type(self.view)=="nil") then
    error("vLib components need to define a view")
  end

end

--------------------------------------------------------------------------------

function vControl:update()
  TRACE("vControl:update() - unimplemented")
end

--------------------------------------------------------------------------------

function vControl:set_active(b)
  self._active = b
end

function vControl:get_active()
  return self._active
end

--------------------------------------------------------------------------------

function vControl:set_midi_mapping(str)
  self._midi_mapping = str
end

function vControl:get_midi_mapping()
  return self._midi_mapping
end

