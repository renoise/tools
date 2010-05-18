--[[============================================================================
main.lua
============================================================================]]--

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

--[[ Song ]]--

-- Randomize song
for _,mode in pairs(Random.mode_names) do
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Randomize Notes in Song:" .. mode,
    invoke = function()
      local visible_only = true
      invoke_random(mode, song().pattern_iterator:lines_in_song(visible_only))
    end
  }
end

-- Shuffle song
renoise.tool():add_keybinding {
  name = "Pattern Editor:Randomize Notes in Song:Shuffle",
  invoke = function()
    local visible_only = true
    invoke_shuffle(song().pattern_iterator:lines_in_song(visible_only))
  end
}


--[[ Pattern ]]--

-- Randomize pattern
for _,mode in pairs(Random.mode_names) do
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Randomize Notes in Pattern:" .. mode,
    invoke = function()
      invoke_random(mode, song().pattern_iterator:lines_in_pattern(
        song().selected_pattern_index))
    end
  }
end

-- Shuffle pattern
renoise.tool():add_keybinding {
  name = "Pattern Editor:Randomize Notes in Pattern:Shuffle",
  invoke = function()
    invoke_shuffle(song().pattern_iterator:lines_in_pattern(
      song().selected_pattern_index))
  end
}


--[[ Track ]]--

-- Randomize track
for _,mode in pairs(Random.mode_names) do
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Randomize Notes in Track:" .. mode,
    invoke = function()
      local visible_only = true
      invoke_random(mode, song().pattern_iterator:lines_in_track(
        song().selected_track_index, visible_only))
    end
  }
end

-- Shuffle track
renoise.tool():add_keybinding {
  name = "Pattern Editor:Randomize Notes in Track:Shuffle",
  invoke = function()
    local visible_only = true
    invoke_shuffle(song().pattern_iterator:lines_in_track(
      song().selected_track_index, visible_only))
  end
}


--[[ Track in Pattern ]]--

-- Randomize track
for _,mode in pairs(Random.mode_names) do
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Randomize Notes in Track in Pattern:" .. mode,
    invoke = function()
      invoke_random(mode, song().pattern_iterator:lines_in_pattern_track(
        song().selected_pattern_index, song().selected_track_index))
    end
  }
end

-- Shuffle track
renoise.tool():add_keybinding {
  name = "Pattern Editor:Randomize Notes in Track in Pattern:Shuffle",
  invoke = function()
    invoke_shuffle(song().pattern_iterator:lines_in_pattern_track(
      song().selected_pattern_index, song().selected_track_index))
  end
}


--[[ Selection ]]--

-- Randomize selected notes in pattern
for _,mode in pairs(Random.mode_names) do
  renoise.tool():add_keybinding {
    name = "Pattern Editor:Randomize Notes in Selection:" .. mode,
    invoke = function()
      local in_selection = true
      invoke_random(mode, song().pattern_iterator:lines_in_pattern(
        song().selected_pattern_index), in_selection)
    end
  }
end

-- Shuffle selected notes in pattern
renoise.tool():add_keybinding {
  name = "Pattern Editor:Randomize Notes in Selection:Shuffle",
  invoke = function()
    local in_selection = true
    invoke_shuffle(song().pattern_iterator:lines_in_pattern(
      song().selected_pattern_index), in_selection)
  end
}


--[[ GUI ]]--

renoise.tool():add_keybinding {
  name = "Pattern Editor:Tools:Randomize Notes...",
  invoke = function()
    randomize_gui()
  end
}


--[[----------------------------------------------------------------------------
Menu Registration
----------------------------------------------------------------------------]]--

--[[ GUI ]]--

renoise.tool():add_menu_entry {
  name = "Pattern Editor:Randomize Notes...",
  invoke = function()
    randomize_gui()
  end
}
