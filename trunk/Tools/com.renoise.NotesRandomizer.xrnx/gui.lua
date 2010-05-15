--[[----------------------------------------------------------------------------
GUI
----------------------------------------------------------------------------]]--

-- Copy Random.mode_names table for local use
local randomize_modes = table.create()
for k,v in pairs(Random.mode_names) do randomize_modes[k] = v end
table.insert(randomize_modes, 1, "Shuffle")

local range_modes = table.create {
  "Whole Song",
  "Whole Pattern",
  "Track in Song",
  "Track in Pattern",
  "Selection"
}

local current_range = #range_modes
local current_mode = 1
local current_preserve_octaves = true

local current_dialog = nil

-------------------------------------------------------------------------------

function invoke_current_random()
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
    invoke_shuffle(iter, selection_only)
  else
    invoke_random(mode, iter, selection_only, current_preserve_octaves)
  end
end


-------------------------------------------------------------------------------

function randomize_gui()

  if (current_dialog and current_dialog.visible) then
    current_dialog:show()
    return
  end

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
    end,
    width = POPUP_WIDTH
  }

  local preserve_octave_switch = vb:checkbox {
    value = true,
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
      preserve_octave_switch,
      vb:text { text = 'Preserve Octaves' }
    },

    vb:space { height = 10 },

    vb:horizontal_aligner {
      mode = "center",
      process_button
    }
  }

  local function key_handler(dialog, mod_name, key_name)
    if (key_name == "esc") then
      dialog:close()

    elseif (key_name == "return") then
      invoke_current_random()

    elseif (key_name == "up") then
      mode_selector.value = math.max(
        1, mode_selector.value - 1)

    elseif (key_name == "down") then
      mode_selector.value = math.min(
        #randomize_modes, mode_selector.value + 1)
    end
  end

  current_dialog = renoise.app():show_custom_dialog(
    "Notes Randomizer", content_view, key_handler)
end
