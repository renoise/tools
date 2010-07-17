--[[============================================================================
main.lua
============================================================================]]--

-- includes

require "add_silence"
require "remove_silence"


--------------------------------------------------------------------------------
-- menu registration
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Sample Editor:Process:Add Silence...",
  invoke = function() show_add_silence_dialog() end
}

renoise.tool():add_menu_entry {
  name = "Sample Editor:Process:Remove Silence...",
  invoke = function() show_remove_silence_dialog() end
}

