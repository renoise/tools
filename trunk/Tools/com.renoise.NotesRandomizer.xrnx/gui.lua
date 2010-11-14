--[[============================================================================
gui.lua
============================================================================]]--

module("gui", package.seeall)

-- randomize_modes table, including shuffle
randomize_modes = table.create(table.rcopy(Random.mode_names))
randomize_modes:insert(1, "Shuffle")

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
local current_custom = table.create()
local current_key = "C-"
local current_preserve_notes = false
local current_preserve_octaves = true
local current_neighbour = false
local current_neighbour_shift = "Rand"
local current_min = 0
local current_max = 9
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
    if (mode == "Custom") then
      mode = current_custom
    end
    randomizer.invoke_random(
      mode, iter, selection_only, current_key, current_preserve_notes,
      current_preserve_octaves, current_neighbour, current_neighbour_shift,
      current_min, current_max
    )
  end
end

--------------------------------------------------------------------------------

-- redraw

local function redraw(vb)
  -- hide custom
  vb.views.custom_column.visible =
    current_mode == randomize_modes:find("Custom")
  -- hide key
  vb.views.key_column.visible =
    (current_mode ~= randomize_modes:find("Shuffle") and
    current_mode ~= randomize_modes:find("Chaos") and
    current_mode ~= randomize_modes:find("Custom"))
  -- hide neighbour
  vb.views.neighbour_row.visible =
    (current_mode ~= randomize_modes:find("Shuffle") and
    current_mode ~= randomize_modes:find("Chaos"))
  vb.views.neighbour_row_2.visible =
    (vb.views.neighbour_row.visible == true and
    current_neighbour == true)
  -- hide notes
  vb.views.preserve_notes_row.visible =
    (current_mode ~= randomize_modes:find("Shuffle") and
    current_mode ~= randomize_modes:find("Chaos"))
  -- hide octave
  vb.views.preserve_octave_row.visible =
    (current_mode ~= randomize_modes:find("Shuffle"))
  vb.views.preserve_octave_row_2.visible =
    (current_mode ~= randomize_modes:find("Shuffle") and
     current_preserve_octaves == false)
  -- re-draw
  vb.views.dialog_content:resize()
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
  current_mode = current_mode or 1

  -- create and show a new dialog
  local DIALOG_MARGIN =
    renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN

  local CONTROL_SPACING =
    renoise.ViewBuilder.DEFAULT_CONTROL_SPACING

  local DIALOG_BUTTON_HEIGHT =
    renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT

  local POPUP_WIDTH = 140
  local TEXT_ROW_WIDTH = 40

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
      redraw(vb)
    end,
    width = POPUP_WIDTH
  }

  local key_selector = vb:popup {
    items = Random.note_sets["Chaos"],
    value = Random.note_sets["Chaos"]:find(tostring(current_key)),
    notifier = function(value)
      current_key = Random.note_sets["Chaos"][value]
      redraw(vb)
    end,
    width = POPUP_WIDTH
  }

  local custom_selector = vb:column {
    style = "border",
    margin = DIALOG_MARGIN,
    spacing = CONTROL_SPACING,
  }
  local custom_selector_row = vb:row { spacing = CONTROL_SPACING }
  local j = 1
  for i = 1, #Random.note_sets["Chaos"] do
    custom_selector_row:add_child(vb:text {
      text = Random.note_sets["Chaos"][i],
      font = "mono"
    })
    local bool = false
    if current_custom:find(Random.note_sets["Chaos"][i]) ~= nil then
      bool = true
    end
    custom_selector_row:add_child(vb:checkbox {
      value = bool,
      notifier = function(value)
        if (value) then
          current_custom[i] = Random.note_sets["Chaos"][i]
        else
          current_custom[i] = nil
        end
      end
    })
    j = j + 1
    if (j > 3) then
      j = 1
      custom_selector:add_child(custom_selector_row)
      custom_selector_row = vb:row { spacing = CONTROL_SPACING }
    end
  end
  custom_selector:add_child(custom_selector_row)

  local preserve_notes_switch = vb:checkbox {
    value = current_preserve_notes,
    notifier = function(value)
      current_preserve_notes = value
      redraw(vb)
    end
  }

  local preserve_octave_switch = vb:checkbox {
    value = current_preserve_octaves,
    notifier = function(value)
      current_preserve_octaves = value
      redraw(vb)
    end
  }

  local octaves = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}
  local octave_selector = vb:row {
    width = POPUP_WIDTH,
    vb:text {
      text = "Min"
    },
    vb:popup {
      id = "octave_selector_min",
      items = octaves,
      value = table.find(octaves, tostring(current_min)),
      notifier = function(value)
        current_min = tonumber(octaves[value])
        if vb.views.octave_selector_max.value < value then
          vb.views.octave_selector_max.value = value
        end
      end,
      width = TEXT_ROW_WIDTH
    },
    vb:text {
      text = "Max"
    },
    vb:popup {
      id = "octave_selector_max",
      items = octaves,
      value = table.find(octaves, tostring(current_max)),
      notifier = function(value)
        current_max = tonumber(octaves[value])
        if vb.views.octave_selector_min.value > value then
          vb.views.octave_selector_min.value = value
        end
      end,
      width = TEXT_ROW_WIDTH
    }
  }

  local neighbour_switch = vb:checkbox {
    value = current_neighbour,
    notifier = function(value)
      current_neighbour = value
      redraw(vb)
    end
  }

  local switches = {"Rand", "Up", "Down"}
  local neighbour_shift = vb:switch {
    id = "neighbour_shift",
    value = table.find(switches, current_neighbour_shift),
    width = POPUP_WIDTH,
    items = switches,
    notifier = function(value)
      local switch = vb.views.neighbour_shift
      current_neighbour_shift = switch.items[value]
    end
  }

  local process_button = vb:button {
    text = "Randomize",
    width = POPUP_WIDTH - DIALOG_MARGIN,
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

    vb:column {
      id = "key_column",
      vb:text { text = 'Key:' },
      key_selector,
    },

    vb:column {
      id = "custom_column",
      vb:text { text = 'Custom Scale:' },
      custom_selector,
    },

    vb:row {
      id = "neighbour_row",
      neighbour_switch,
      vb:text { text = 'Nearest Neighbour' }
    },

    vb:horizontal_aligner {
      id = "neighbour_row_2",
      mode = "center",
      neighbour_shift
    },

    vb:row {
      id = "preserve_notes_row",
      preserve_notes_switch,
      vb:text { text = 'Preserve Notes In Scale' }
    },

    vb:row {
      id = "preserve_octave_row",
      preserve_octave_switch,
      vb:text { text = 'Preserve Octaves' }
    },

    vb:horizontal_aligner {
      id = "preserve_octave_row_2",
      mode = "center",
      octave_selector,
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

    elseif (key.name == "left") then
      key_selector.value = math.max(
        1, key_selector.value - 1)

    elseif (key.name == "right") then
      key_selector.value = math.min(
        #Random.note_sets["Chaos"], key_selector.value + 1)

    else
      return key
    end
  end

  redraw(vb)

  current_dialog = renoise.app():show_custom_dialog(
    "Notes Randomizer", content_view, key_handler)

end

