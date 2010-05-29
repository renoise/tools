--[[============================================================================
main.lua
============================================================================]]--

pcall(require, "future")

require "randomizer"
require "gui"


--[[----------------------------------------------------------------------------
Helpers
----------------------------------------------------------------------------]]--

local function song()
  return renoise.song()
end


--[[----------------------------------------------------------------------------
Keybinding Registration
----------------------------------------------------------------------------]]--

-- Whole pattern
renoise.tool():add_keybinding {
  name = "Pattern Editor:Pattern Operations:Randomize Notes",
  invoke = function()
    gui.invoke_random_in_range("Whole Pattern")
  end
}

-- Track in Pattern
renoise.tool():add_keybinding {
  name = "Pattern Editor:Track Operations:Randomize Notes in Pattern",
  invoke = function()
    gui.invoke_random_in_range("Track in Pattern")
  end
}

-- Track in Song
renoise.tool():add_keybinding {
  name = "Pattern Editor:Track Operations:Randomize Notes in Song",
  invoke = function()
     gui.invoke_random_in_range("Track in Song")
  end
}

-- Selection
renoise.tool():add_keybinding {
  name = "Pattern Editor:Block Operations:Randomize Notes",
  invoke = function()
    gui.invoke_random_in_range("Selection")
  end
}

-- Randomize GUI
renoise.tool():add_keybinding {
  name = "Pattern Editor:Tools:Randomize Notes...",
  invoke = gui.show_randomize_gui
}


--[[----------------------------------------------------------------------------
Menu Registration
----------------------------------------------------------------------------]]--

-- Randomize GUI
renoise.tool():add_menu_entry {
  name = "Pattern Editor:Randomize Notes...",
  invoke = gui.show_randomize_gui
}

