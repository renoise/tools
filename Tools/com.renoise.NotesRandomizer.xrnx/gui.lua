--[[============================================================================
gui.lua
============================================================================]]--

module("gui", package.seeall)

-- randomize_modes table, including shuffle
randomize_modes = table.create( table.rcopy(Random.mode_names) )
randomize_modes:insert("Shuffle")

-- available iterator ranges
range_modes = table.create {
  "Whole Song",
  "Whole Pattern",
  "Track in Song",
  "Track in Pattern",
  "Selection"
}


--------------------------------------------------------------------------------
-- Local Functions & States
--------------------------------------------------------------------------------

-- status

local current_range = #range_modes
local current_mode = nil
local current_preserve_octaves = true
local current_neighbour = false
local current_neighbour_shift = "Up"
local current_dialog = nil


--------------------------------------------------------------------------------

-- invoke_current_random

local function invoke_current_random()
  assert(current_range and current_mode, "mode or range was not yet set")

  local range = range_modes[current_range]
  local mode = randomize_modes[current_mode]

  local iter = nil
  local selection_only = false

  if (range == "Whole Song") then
    local visible_only = true
    iter = renoise.song().pattern_iterator:lines_in_song(
      renoise.song().selected_pattern_index, visible_only)

  elseif (range == "Whole Pattern") then
    iter = renoise.song().pattern_iterator:lines_in_pattern(
      renoise.song().selected_pattern_index)

  elseif (range == "Track in Song") then
    local visible_only = true
    iter = renoise.song().pattern_iterator:lines_in_track(
      renoise.song().selected_track_index, visible_only)

  elseif (range == "Track in Pattern") then
    iter = renoise.song().pattern_iterator:lines_in_pattern_track(
      renoise.song().selected_pattern_index,
      renoise.song().selected_track_index)

  elseif (range == "Selection") then
    selection_only = true
    iter = renoise.song().pattern_iterator:lines_in_pattern(
      renoise.song().selected_pattern_index)

  else
    error("Unknown range mode")
  end

  if (mode == "Shuffle") then
    randomizer.invoke_shuffle(iter, selection_only)
  else
    randomizer.invoke_random(
      mode, iter, selection_only, current_preserve_octaves, current_neighbour,
      current_neighbour_shift
    )
  end
end


--------------------------------------------------------------------------------
-- Public functions
--------------------------------------------------------------------------------

-- if a mode already was set, invoke this mode, else open the GUI
-- to let the user define a mode

function invoke_random_in_range(range_string)
  current_range = table.find(range_modes, range_string) or
    error("expected param range to be one of 'range_string'")

  if not (current_mode) then
    show_randomize_gui()
  else
    invoke_current_random()
  end
end


--------------------------------------------------------------------------------

-- create and show the randomize GUI dialog or bring the existing one to front

function show_randomize_gui()

  -- check for already opened dialogs
  if (current_dialog and current_dialog.visible) then
    current_dialog:show()
    return
  end

  -- initialize mode when opened the first time
  current_mode = current_mode or #randomize_modes

  -- create and show a new dialog
  local DIALOG_MARGIN =
    renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN

  local CONTROL_SPACING =
    renoise.ViewBuilder.DEFAULT_CONTROL_SPACING

  local DIALOG_BUTTON_HEIGHT =
    renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT

  local POPUP_WIDTH = 140

  local vb = renoise.ViewBuilder()

  local range_selector = vb:popup {
    items = range_modes,
    value = current_range,
    notifier = function(value)
      current_range = value
    end,
    width = POPUP_WIDTH
  }

  local mode_selector = vb:popup {
    items = randomize_modes,
    value = current_mode,
    notifier = function(value)
      current_mode = value
      -- hide preserve_octave with shuffle
      vb.views.preserve_octave_row.visible =
        (current_mode ~= randomize_modes:find("Shuffle"))
      -- hide neighbour with shuffle and chaos
      vb.views.neighbour_row.visible =
        (current_mode ~= randomize_modes:find("Shuffle") and
        current_mode ~= randomize_modes:find("Chaos"))
      vb.views.neighbour_row_2.visible =
        (vb.views.neighbour_row.visible == true and
        current_neighbour == true)
      vb.views.dialog_content:resize()
    end,
    width = POPUP_WIDTH
  }

  local neighbour_switch = vb:checkbox {
    value = current_neighbour,
    notifier = function(value)
      current_neighbour = value
      vb.views.neighbour_row_2.visible =
        (vb.views.neighbour_row.visible == true and
        current_neighbour == true)
      vb.views.dialog_content:resize()
    end
  }

  local switches = {"Up", "Down"}
  local neighbour_shift = vb:switch {
    id = "switch",
    value = table.find(switches, current_neighbour_shift),
    width = 100,
    items = switches,
    notifier = function(value)
      local switch = vb.views.switch
      current_neighbour_shift = switch.items[value]
    end
  }

  local preserve_octave_switch = vb:checkbox {
    value = current_preserve_octaves,
    notifier = function(value)
      current_preserve_octaves = value
    end
  }

  local process_button = vb:button {
    text = "Randomize",
    width = 100,
    height = DIALOG_BUTTON_HEIGHT,
    notifier = invoke_current_random
  }

  local content_view = vb:column {
    id = "dialog_content",
    uniform = true,
    margin = DIALOG_MARGIN,
    spacing = CONTROL_SPACING,

    vb:column {
      vb:text { text = 'Where:' },
      range_selector,
    },

    vb:column {
      vb:text { text = 'How:' },
      mode_selector,
    },

    vb:row {
      id = "preserve_octave_row",
      visible = (current_mode ~= randomize_modes:find("Shuffle")),
      preserve_octave_switch,
      vb:text { text = 'Preserve Octaves' }
    },

    vb:row {
      id = "neighbour_row",
      visible =
        (current_mode ~= randomize_modes:find("Shuffle") and
        current_mode ~= randomize_modes:find("Chaos")),
      neighbour_switch,
      vb:text { text = 'Nearest Neighbour' }
    },

    vb: row {
      id = "neighbour_row_2",
      visible =
        (vb.views.neighbour_row.visible == true and
        current_neighbour == true),
      vb:column { width = 20 },
      neighbour_shift
    },

    vb:space { height = 10 },

    vb:horizontal_aligner {
      mode = "center",
      process_button
    }
  }

  local function key_handler(dialog, key)
    if (key.name == "esc") then
      dialog:close()

    elseif (key.name == "return") then
      invoke_current_random()

    elseif (key.name == "up") then
      mode_selector.value = math.max(
        1, mode_selector.value - 1)

    elseif (key.name == "down") then
      mode_selector.value = math.min(
        #randomize_modes, mode_selector.value + 1)
    end
  end

  current_dialog = renoise.app():show_custom_dialog(
    "Notes Randomizer", content_view, key_handler)
end

