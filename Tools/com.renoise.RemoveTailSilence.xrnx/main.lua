--[[============================================================================
main.lua
============================================================================]]--

-- includes
require "remove_silence"


--------------------------------------------------------------------------------
-- menu registration
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Instrument Box:Process:Remove tail silence from samples",
  invoke = function() process_samples() end
}


