-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- tool setup
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

renoise.tool():add_menu_entry {
   name = "Main Menu:Tools:Epic Arpeggiator",
   invoke = function() open_arp_dialog() end
}



require "globals"
require "tone_matrix"
require "pattern_processing"
require "gui"
