--[[============================================================================
-- Duplex.Application.Automateable
============================================================================]]--

--[[--

Base class for applications that need automation 

--]]

--==============================================================================

class 'Automateable' (Application)

local RECORD_NONE = 1
local RECORD_INTERLEAVE = 2
local RECORD_PUNCH_IN = 3

--------------------------------------------------------------------------------

Automateable.default_options = {
  record_method = {
    label = "Automation rec.",
    description = "Determine if/how to record automation ",
    items = {
      "Disabled, do not record automation",
      "Interleaved, record while touched",
      "Punch-in, remove existing data",
    },
    value = 1,
    on_change = function(inst)
      --[[
      inst.automation.latch_record = 
        (inst.options.record_method.value==RECORD_LATCH) 
        ]]
      inst:update_record_mode()
    end
  }
}

--------------------------------------------------------------------------------

function Automateable:__init(...)

  -- use Automation class to record movements
  self.automation = xAutomation()

  -- set while recording automation
  self._record_mode = false

  -- apply arguments
  Application.__init(self,...)

  -- do stuff after options have been set
  --[[
  self.automation.latch_record = 
    (self.options.record_method.value==RECORD_LATCH)
    ]]

  -- attach notifiers 

  duplex_preferences.highres_automation:add_notifier(function()
    self.automation.highres_mode = duplex_preferences.highres_automation.value
  end)
  self.automation.highres_mode = duplex_preferences.highres_automation.value

end

--------------------------------------------------------------------------------

-- update the record mode (when editmode or record_method has changed)

function Automateable:update_record_mode()
  TRACE("Automateable:update_record_mode")

  local val = self.options.record_method.value
  if (val ~= RECORD_NONE) 
    and rns.transport.edit_mode
  then
    if (val == RECORD_INTERLEAVE) then 
      self.automation.write_mode = xAutomation.WRITE_MODE.INTERLEAVE
    elseif (val == RECORD_PUNCH_IN) then 
      self.automation.write_mode = xAutomation.WRITE_MODE.PUNCH_IN
    else 
      error("Unexpected record mode")
    end 
    self._record_mode = rns.transport.edit_mode
  else
    self._record_mode = false
  end

end

--------------------------------------------------------------------------------
--- attach notifiers to the song, handle changes

function Automateable:_attach_to_song()
  TRACE("Automateable:_attach_to_song()",self)

  -- track edit_mode, and set record_mode accordingly
  rns.transport.edit_mode_observable:add_notifier(
    function()
      TRACE("Automateable:edit_mode_observable fired...")
        self:update_record_mode()
    end
  )
  self:update_record_mode()


end

--------------------------------------------------------------------------------
-- @see Duplex.Application.on_idle

function Automateable:on_idle()

  --[[
  if self._record_mode then
    self.automation:update()
  end
  ]]

  Application.on_idle()

end
