require "toolbox"

--[[ Globals ]]--

local matrix_width = 8
local matrix_height = 8
local matrix_cells = table.create{}

local x_pos = 1
local y_pos = 1

local my_interface = nil
local vb = nil
local gridpie_idx = nil

--------------------------------------------------------------------------------
-- Keyboard input
--------------------------------------------------------------------------------

function key_handler(dialog, key)

  if (key.name == "esc") then
    dialog:close()
  else
    return key
  end

end


--------------------------------------------------------------------------------
-- Is garbage PM position?
--------------------------------------------------------------------------------

function is_garbage_pos(x, y)

  -- Garbage position?
  local sequencer = renoise.song().sequencer
  local total_sequence = #sequencer.pattern_sequence

  if
    renoise.song().sequencer.pattern_sequence[y] == nil or
    renoise.song().tracks[x] == nil or
    renoise.song().tracks[x].type == renoise.Track.TRACK_TYPE_MASTER or
    renoise.song().tracks[x].type == renoise.Track.TRACK_TYPE_SEND or
    total_sequence == y
  then
    return true
  else
    return false
  end

end


--------------------------------------------------------------------------------
-- Access a cell in the matrix view
--------------------------------------------------------------------------------

function matrix_cell(x, y)

  if (matrix_cells[x] ~= nil) then
    return matrix_cells[x][y]
  else
    return nil
  end
end


--------------------------------------------------------------------------------
-- Initialize PM
--------------------------------------------------------------------------------

function init_pm()

  local rns = renoise.song()
  local tracks = rns.tracks
  local sequencer = rns.sequencer
  local total_tracks = #tracks
  local total_sequence = #sequencer.pattern_sequence

  for x = 1, total_tracks do
    if
      tracks[x].type ~= renoise.Track.TRACK_TYPE_MASTER and
      tracks[x].type ~= renoise.Track.TRACK_TYPE_SEND
    then
      for y = 1, total_sequence do
        rns.sequencer:set_track_sequence_slot_is_muted(x , y, true)
      end
    end
  end

end


--------------------------------------------------------------------------------
-- Initialize Grid Pie Pattern
--------------------------------------------------------------------------------

function init_gp_pattern()

  local rns = renoise.song()
  local tracks = rns.tracks
  local total_tracks = #tracks
  local sequencer = rns.sequencer
  local total_sequence = #sequencer.pattern_sequence
  local last_pattern = rns.sequencer:pattern(total_sequence)

  if rns.patterns[last_pattern].name ~= "__GRID_PIE__" then
    -- Create new pattern
    local new_pattern = rns.sequencer:insert_new_pattern_at(total_sequence + 1)
    rns.patterns[new_pattern].name = "__GRID_PIE__"
    gridpie_idx = new_pattern
    total_sequence = total_sequence + 1
  else
    -- Clear pattern, unmute slot
    rns.patterns[last_pattern]:clear()
    rns.patterns[last_pattern].name = "__GRID_PIE__"
    for x = 1, total_tracks do
      rns.sequencer:set_track_sequence_slot_is_muted(x , total_sequence, false)
    end
    gridpie_idx = last_pattern
  end

  -- Cleanup any other pattern named __GRID_PIE__
  for x = 1, total_sequence - 1 do
    local tmp = rns.sequencer:pattern(x)

    if rns.patterns[tmp].name:find("__GRID_PIE__") ~= nil then
      rns.patterns[tmp].name = ""
    end
  end

  -- Ajdust the Renoise interface, move playhead to last pattern, ...
  renoise.app().window.pattern_matrix_is_visible = true
  rns.selected_sequence_index = #sequencer.pattern_sequence
  rns.transport.follow_player = false
  rns.transport.loop_pattern = true
  rns.transport:start(renoise.Transport.PLAYMODE_RESTART_PATTERN)

end


--------------------------------------------------------------------------------
-- Adjust grid
--------------------------------------------------------------------------------

function adjust_grid()

  local cell = nil
  for x = x_pos, matrix_width + x_pos - 1 do
    for y = y_pos, matrix_height + y_pos - 1 do
      cell = matrix_cell(x - x_pos + 1, y - y_pos + 1)
      if cell ~= nil and not is_garbage_pos(x, y) then
        local val = renoise.song().sequencer:track_sequence_slot_is_muted(x, y)
        if val then cell.color = { 0, 0, 0 }
        else cell.color = { 0, 255, 0 } end
      elseif cell ~= nil then
         cell.color = { 0, 0, 0 }
      end
    end
  end

end


--------------------------------------------------------------------------------
-- Toggler
--------------------------------------------------------------------------------

function toggler(x, y)

  local cell = matrix_cell(x, y)
  local muted = false
  if cell ~= nil and cell.color[2] == 255 then muted = true end

  x = x + (x_pos - 1)
  y = y + (y_pos - 1)

  if is_garbage_pos(x, y) then return end

  local rns = renoise.song()

  -- Copy to gridpie_idx
  if muted then
    -- Mute
    -- TODO: This is a hackaround, fix when API is updated
    -- See: http://www.renoise.com/board/index.php?showtopic=31927
    rns.tracks[x].mute_state = renoise.Track.MUTE_STATE_OFF
    OneShotIdleNotifier(0, function()
      rns.patterns[gridpie_idx].tracks[x]:clear()
      rns.tracks[x].mute_state = renoise.Track.MUTE_STATE_ACTIVE
    end)
  else
    -- Copy
    rns.patterns[gridpie_idx].tracks[x]:copy_from(rns.patterns[rns.sequencer:pattern(y)].tracks[x])
    rns.patterns[gridpie_idx].number_of_lines = rns.patterns[rns.sequencer:pattern(y)].number_of_lines
    -- TODO: Improve. E.g. Polyrythm with least_common(), renoise.Pattern.MAX_NUMBER_OF_LINES, ...
  end

  -- Change PM
  for i = 1, #rns.sequencer.pattern_sequence - 1 do
    if not is_garbage_pos(x, i) then
      if i == y then
        rns.sequencer:set_track_sequence_slot_is_muted(x , i, muted)
      else
        rns.sequencer:set_track_sequence_slot_is_muted(x , i, true)
      end
    end
  end
  adjust_grid()

end


--------------------------------------------------------------------------------
-- Build GUI Interface
--------------------------------------------------------------------------------

function build_interface()

  -- Init VB
  vb = renoise.ViewBuilder()

  local max_x = renoise.song().sequencer_track_count - matrix_width + 1
  if max_x < 1 then max_x = 1 end

  local max_y = #renoise.song().sequencer.pattern_sequence - matrix_height
  if max_y < 1 then max_y = 1 end

  -- Reset
  x_pos = 1
  y_pos = 1

  -- Buttons
  local button_view = vb:row {
    vb:text {
      text = "x:",
      font = "mono",
    },
    vb:valuebox {
      id = "gp_x",
      min = 1,
      max = max_x,
      value = x_pos,
      notifier = function(val)
        x_pos = val
        adjust_grid()
      end,
      midi_mapping = "Grid Pie:X Axis",
    },
    vb:text {
      text = " y:",
      font = "mono",
    },
    vb:valuebox {
      id = "gp_y",
      min = 1,
      max = max_y,
      value = y_pos,
      notifier = function(val)
        y_pos = val
        adjust_grid()
      end,
      midi_mapping = "Grid Pie:Y Axis",
    },
  }

  -- Checkmark Matrix
  local matrix_view = vb:row { }
  for x = 1, matrix_width do
    local column = vb:column {  margin = 2, spacing = 2, }
    matrix_cells[x] = table.create()
    for y = 1, matrix_height do
      matrix_cells[x][y] = vb:button {
        width = 35,
        height = 35,
        pressed = function()
          toggler(x, y)
        end,
        midi_mapping = "Grid Pie:Slice " .. x .. "," .. y,
      }
      column:add_child(matrix_cells[x][y])
    end
    matrix_view:add_child(column)
  end

  -- Racks
  local rack = vb:column {
    id = "my_interface",
    uniform = true,
    margin = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN,
    spacing = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING,

    vb:column {
      vb:horizontal_aligner {
        id = "my_buttons",
        mode = "center",
        button_view,
      },
    },

    vb:space { height = 10 },

    vb:column {
      vb:horizontal_aligner {
        id = "my_matrix",
        mode = "center",
        matrix_view,
      },
    },

  }

  -- Show dialog
  my_interface = renoise.app():show_custom_dialog("Grid Pie", rack, key_handler)

end


--------------------------------------------------------------------------------
-- Main
--------------------------------------------------------------------------------

function main(x, y)

  if
    not vb or
    x ~= matrix_width or
    y ~= matrix_height
  then
    matrix_width = x
    matrix_height = y
    init_pm()
    init_gp_pattern()
    if my_interface and my_interface.visible then my_interface:close() end
    build_interface()
  end
  run()

end



--------------------------------------------------------------------------------
-- Abort
--------------------------------------------------------------------------------

function abort(notification)

  renoise.app():show_message(
  "You dun goofed! Grid Pie needs to be restarted."
  )
  if my_interface and my_interface.visible then my_interface:close() end

end


--------------------------------------------------------------------------------
-- Handle track change
--------------------------------------------------------------------------------

function tracks_changed(notification)

  if (notification.type == "insert") then
    -- TODO: This is a hackaround, fix when API is updated
    -- See: http://www.renoise.com/board/index.php?showtopic=31893
    OneShotIdleNotifier(0, function()
      for i = 1, #renoise.song().sequencer.pattern_sequence - 1 do
        renoise.song().sequencer:set_track_sequence_slot_is_muted(notification.index , i, true)
      end
    end)
  end
end


--------------------------------------------------------------------------------
-- Idler
--------------------------------------------------------------------------------

function idler(notification)

  if (not vb or not my_interface or not my_interface.visible) then
    stop()
    return
  end

  local last_pattern = renoise.song().sequencer:pattern(#renoise.song().sequencer.pattern_sequence)
  if renoise.song().patterns[last_pattern].name ~= "__GRID_PIE__" then
    abort()
  else

    vb.views.gp_x.max = renoise.song().sequencer_track_count - matrix_width + 1
    if vb.views.gp_x.max < 1 then vb.views.gp_x.max = 1 end
    if vb.views.gp_x.value > vb.views.gp_x.max then
      vb.views.gp_x.value = vb.views.gp_x.max
      adjust_grid()
    end

    vb.views.gp_y.max = #renoise.song().sequencer.pattern_sequence - matrix_height
    if vb.views.gp_y.max < 1 then vb.views.gp_y.max = 1 end
    if vb.views.gp_y.value > vb.views.gp_y.max then
      vb.views.gp_x.value = vb.views.gp_x.max
      adjust_grid()
    end

  end

end


--------------------------------------------------------------------------------
-- Bootsauce
--------------------------------------------------------------------------------

function run()

  -- Observers init
  if not (renoise.tool().app_idle_observable:has_notifier(idler)) then
    renoise.tool().app_idle_observable:add_notifier(idler)
  end
  if not (renoise.song().tracks_observable:has_notifier(tracks_changed)) then
    renoise.song().tracks_observable:add_notifier(tracks_changed)
  end

end


function stop()

  -- Observers takedown
  if (renoise.tool().app_idle_observable:has_notifier(idler)) then
    renoise.tool().app_idle_observable:remove_notifier(idler)
  end
  if (renoise.song().tracks_observable:has_notifier(tracks_changed)) then
    renoise.song().tracks_observable:remove_notifier(tracks_changed)
  end
  -- Destroy vb
  vb = nil
end


--------------------------------------------------------------------------------
-- MIDI Mappings
--------------------------------------------------------------------------------

renoise.tool():add_midi_mapping{
  name = "Grid Pie:X Axis",
  invoke = function(message)
    -- midi_debug(message)
    if not vb then
     return
    elseif message.int_value >= 0 and message.int_value <= 128 then
      -- Knob? Then scale
      local tmp = 1 + (message.int_value / 127) * (vb.views.gp_x.max - 1) -- Scale
      vb.views.gp_x.value = math.floor(tmp * 1 + 0.5) / 1 -- Round to int
    elseif message:is_trigger() then
      -- Button? Then increment
      if vb.views.gp_x.value == vb.views.gp_x.max then
        vb.views.gp_x.value = 1
      else
        local tmp = vb.views.gp_x.value + matrix_width
        if tmp > vb.views.gp_x.max then
          vb.views.gp_x.value = vb.views.gp_x.max
        else
          vb.views.gp_x.value = tmp
        end
      end
    end
  end
}


renoise.tool():add_midi_mapping{
  name = "Grid Pie:Y Axis",
  invoke = function(message)
    -- midi_debug(message)
    if not vb then
     return
    elseif message.int_value >= 0 and message.int_value <= 128 then
      -- Knob? Then scale
      local tmp = 1 + (message.int_value / 127) * (vb.views.gp_y.max - 1) -- Scale
      vb.views.gp_y.value = math.floor(tmp * 1 + 0.5) / 1 -- Round to int
    elseif message:is_trigger() then
      -- Button? Then increment
      if vb.views.gp_y.value == vb.views.gp_y.max then
        vb.views.gp_y.value = 1
      else
        local tmp = vb.views.gp_y.value + matrix_height
        if tmp > vb.views.gp_y.max then
          vb.views.gp_y.value = vb.views.gp_y.max
        else
          vb.views.gp_y.value = tmp
        end
      end
    end
  end
}


for x = 1, matrix_width do
  for y = 1, matrix_height do
    renoise.tool():add_midi_mapping{
      name = "Grid Pie:Slice " .. x .. "," .. y,
      invoke = function(message)
        -- midi_debug(message)
        if not vb then
          return
        elseif (message:is_trigger()) then
          toggler(x, y)
        end
      end
    }
  end
end


--------------------------------------------------------------------------------
-- Menu Registration
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Grid Pie:4x2...",
  invoke = function() main(4, 2) end
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Grid Pie:4x4...",
  invoke = function() main(4, 4) end
}

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Grid Pie:8x8...",
  invoke = function() main(8, 8) end
}
