--[[============================================================================
main.lua
============================================================================]]--

-- requires

require "globals"
require "gui"
require "tone_matrix"
require "pattern_processing"
require "preset_manager"


--------------------------------------------------------------------------------
-- menu registration
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
   name = "Main Menu:Tools:Epic Arpeggiator...",
   invoke = open_arp_dialog
}

