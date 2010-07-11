-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- tool setup
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

require "globals"
require "gui"
require "tone_matrix"
require "pattern_processing"

renoise.tool():add_menu_entry {
   name = "Main Menu:Tools:Epic Arpeggiator...",
   invoke = open_arp_dialog
} 
