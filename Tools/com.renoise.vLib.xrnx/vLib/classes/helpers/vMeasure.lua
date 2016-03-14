--[[============================================================================
vMeasure
============================================================================]]--
--[[

  Using Lua meta-methods to emulate viewbuilder unit measurements.

]]

class 'vMeasure'

--------------------------------------------------------------------------------

function vMeasure:__init(...)

  -- (ObservableNumber/String) depending on what you feed it
  self.value = nil

end




