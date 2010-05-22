-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- tool setup
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

renoise.tool():add_menu_entry {
   name = "Main Menu:Tools:Epic Arpeggiator",
   invoke = function() open_arp_dialog() end
}



require "header"
require "helpers"
require "tone_matrix"
require "pattern_sequencer"
require "pattern_processing"
require "gui_environment"