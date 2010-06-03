-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- tool setup
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

require "globals"
require "tone_matrix"
require "pattern_processing"
require "gui"

renoise.tool():add_menu_entry {
   name = "Main Menu:Tools:Epic Arpeggiator...",
   invoke = open_arp_dialog
}
