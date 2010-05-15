--[[---------------------------------------------------------------------------
com.renoise.FindAndReplace.xrnx/main.lua
---------------------------------------------------------------------------]]--


-------------------------------------------------------------------------------
-- tool setup
-------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Pattern Editor:Find and Replace...",
  invoke = function() show_dialog() end
} 

renoise.tool():add_keybinding {
  name = "Pattern Editor:Tools:Find and Replace",
  invoke = function() show_dialog() end
}


-------------------------------------------------------------------------------
-- modes
-------------------------------------------------------------------------------

local modes = { "Notes", "Effects" }


-------------------------------------------------------------------------------
-- scopes
-------------------------------------------------------------------------------

local song_scope = {}

song_scope.name = "Whole Song"
song_scope.iter = function(note_mode, visible_only)
  if note_mode then
    return renoise.song().pattern_iterator:note_columns_in_song(visible_only)
  else
    return renoise.song().pattern_iterator:effect_columns_in_song(visible_only)
  end
end

local pattern_scope = {}

pattern_scope.name = "Whole Pattern"
pattern_scope.iter = function(note_mode, visible_only)
  local pattern_index = renoise.song().selected_pattern_index
  if note_mode then
    return renoise.song().pattern_iterator:note_columns_in_pattern(
      pattern_index, visible_only)
  else
    return renoise.song().pattern_iterator:effect_columns_in_pattern(
      pattern_index, visible_only)
  end
end

local song_track_scope = {}

song_track_scope.name = "Track in Song"
song_track_scope.iter = function(note_mode, visible_only)
  local track_index = renoise.song().selected_track_index
  
  if note_mode then
    return renoise.song().pattern_iterator:note_columns_in_track(
      track_index, visible_only)
  else
    return renoise.song().pattern_iterator:effect_columns_in_track(
      track_index, visible_only)
  end
end

local pattern_track_scope = {}

pattern_track_scope.name = "Track in Pattern"
pattern_track_scope.iter = function(note_mode, visible_only)
  local pattern_index = renoise.song().selected_pattern_index  
  local track_index = renoise.song().selected_track_index
  
  if note_mode then
    return renoise.song().pattern_iterator:note_columns_in_pattern_track(
      pattern_index, track_index, visible_only)
  else
    return renoise.song().pattern_iterator:effect_columns_in_pattern_track(
      pattern_index, track_index, visible_only)
  end
end

local scopes = {
  song_scope,
  pattern_scope,
  song_track_scope,
  pattern_track_scope
}

local scope_names = {}

for _,scope in pairs(scopes) do
  table.insert(scope_names, scope.name)
end


-------------------------------------------------------------------------------
-- search set
-------------------------------------------------------------------------------

local note_properties = {
  "note",
  "instrument",
  "volume",
  "panning",
  "delay"
}

local effect_properties = {
  "number",
  "amount"
}

local note_and_effect_properties = {}

for _,property in pairs(note_properties) do
  table.insert(note_and_effect_properties, property)
end

for _,property in pairs(effect_properties) do
  table.insert(note_and_effect_properties, property)
end


-- find & replace set

local find_set = {}
local replace_set = {}

for _,property in pairs(note_and_effect_properties) do
  find_set[property] = "*"
  replace_set[property] = ""
end


-------------------------------------------------------------------------------
-- search set helpers
-------------------------------------------------------------------------------

-- is_valid_property

local valid_notes = {}

for octave = 0,10 do
  valid_notes["C-"..octave] = true
  valid_notes["C#"..octave] = true
  valid_notes["D-"..octave] = true
  valid_notes["D#"..octave] = true
  valid_notes["E-"..octave] = true
  valid_notes["F-"..octave] = true
  valid_notes["F#"..octave] = true
  valid_notes["G-"..octave] = true
  valid_notes["G#"..octave] = true
  valid_notes["A-"..octave] = true
  valid_notes["A#"..octave] = true
  valid_notes["B-"..octave] = true
end

valid_notes["---"] = true
valid_notes["OFF"] = true

local function is_valid_property(str_value, property)
  if (property == "note") then
    return valid_notes[str_value:upper()]
  else
    if (#str_value == 2) then
      if (str_value == "..") then
        return true
      else
        local number = tonumber(str_value, 0x10)
        return (number and number >= 0 and number < 256)
      end
    end
  end
end


-------------------------------------------------------------------------------
-- search status
-------------------------------------------------------------------------------

local current_mode_index = 1
local current_scope_index = 1

local current_position = {
  pattern = 1,
  track = 1,
  line = 1,
  column = 1
}

local current_column = nil
local current_iter = nil
local current_visibility_mode = nil

local find_replace_dialog = nil


-------------------------------------------------------------------------------
-- search status helpers
-------------------------------------------------------------------------------

-- current_scope

local function current_scope()
  return scopes[current_scope_index]
end


-- note_mode

local function note_mode()
  return (current_mode_index == 1)
end


-- effect_mode

local function effect_mode()
  return (current_mode_index == 2)
end


-- current_property_set

local function current_property_set()
  if note_mode() then
    return note_properties
  elseif effect_mode() then
    return effect_properties
  else
    assert(false, "unexpected mode")
  end
end


-- current_pos_is_valid

local function current_pos_is_valid()
  local pos = current_position

  if (pos.pattern <= #renoise.song().patterns and
      pos.track <= #renoise.song().tracks) then    
    local pattern = renoise.song().patterns[pos.pattern]
    
    if (pos.line <= pattern.number_of_lines) then
      local columns = nil 
      
      if note_mode() then
        columns = pattern.tracks[pos.track].lines[pos.line].note_columns
      elseif effect_mode() then
        columns = pattern.tracks[pos.track].lines[pos.line].effect_columns
      else
        assert(false, "unknown mode")
      end

      return (pos.column <= #columns)
    end
  end

  return false
end


-- set_current_pos

local function set_current_pos(pos)
  current_position.pattern = pos.pattern
  current_position.track = pos.track
  current_position.line = pos.line
  current_position.column = pos.column
end


-- jump_to_current_pos

local function jump_to_current_pos()
  local pos = current_position

  local found_pattern = false
  local pattern_sequence = renoise.song().sequencer.pattern_sequence

  for sequence_index, pattern_index in pairs(pattern_sequence) do
    if (pattern_index == pos.pattern) then
      renoise.song().selected_sequence_index = sequence_index
      found_pattern = true
      break
    end
  end

  -- can only show jump, if the pattern is used in the sequence...
  if found_pattern then
    renoise.song().selected_track_index = pos.track
    renoise.song().selected_line_index = pos.line

    local selected_track = renoise.song().selected_track

    if note_mode() then
      if (pos.column <= selected_track.visible_note_columns) then
        renoise.song().selected_note_column_index = pos.column
      end
    elseif effect_mode() then
      if (pos.column <= selected_track.visible_effect_columns) then
        renoise.song().selected_effect_column_index = pos.column
      end
    else
      assert(false, "unexpected mode")
    end
  end
end


-------------------------------------------------------------------------------
-- global functions
-------------------------------------------------------------------------------

-- reset_status

function reset_status()
  current_iter = nil
  current_column = nil
end


-------------------------------------------------------------------------------

-- validate_find_set

function validate_find_set()
  for _,property in pairs(current_property_set()) do
    local value = find_set[property]
    if (value == "*" or is_valid_property(value, property)) then
      -- valid
    else
      renoise.app():show_error(([[
The find set contains an invalid '%s' entry: '%s'

Valid entries for notes are something like 'C-4' or '*'.
Valid entries for effects are two chars like '2A' or '*'.

Search or Replace was aborted...]]):format(property, value))

      return false
    end
  end

  return true
end


-------------------------------------------------------------------------------

-- validate_replace_set

function validate_replace_set()
  for _,property in pairs(current_property_set()) do
    local value = replace_set[property]
    if (value == "" or is_valid_property(value, property)) then
      -- valid
    else
      renoise.app():show_error(([[
The replace set contains an invalid '%s' entry: '%s'


Valid entries for notes are something like 'C-4' or and empty value.
Valid entries for effects are two chars like '2A' or an empty value.

Replace was aborted...]]):format(property, value))

      return false
    end
  end

  return true
end


-------------------------------------------------------------------------------

-- find_next

function find_next(visible_content_only)
  if (visible_content_only == nil) then 
    visible_content_only = true
  end
  
  ---- column_match

  local function column_match(column, properties)
    if column.is_empty then
      return false
    end

    for _,property in pairs(properties) do
      if (find_set[property] ~= "*") then
        local column_value = column[tostring(property).."_string"]
        local find_value = find_set[property]
        if (column_value:lower() ~= find_value:lower()) then
          return false
        end
      end
    end

    return true
  end


  ---- find_next

  -- check if we've got a valid find set first

  if (not validate_find_set()) then
    return nil
  end


  -- setup the iter when the search was (re)started

  local initial_match = false

  if (not current_iter or 
      not current_pos_is_valid() or
      current_visibility_mode ~= visible_content_only) then
    initial_match = true
    current_iter = current_scope().iter(note_mode(), visible_content_only)
    current_visibility_mode = visible_content_only
  end


  -- start or contine the search...
  
  local found_match = false

  for pos, column in current_iter do

    -- reset to the iters start position when the search was (re)started
    if initial_match then
      initial_match = false
      set_current_pos(pos)
    end

    -- find a matching column
    if column_match(column, current_property_set()) then
      found_match = true
      current_column = column
      set_current_pos(pos)
      break
    end
  end

  if found_match then
    -- show to the user what we've found when searching visible content
    if visible_content_only then
      jump_to_current_pos()
    end

    return true
  else
    -- reset the search state when we're done...
    reset_status()
    return false
  end
end


-------------------------------------------------------------------------------

-- replace_next

function replace_next(visible_content_only)
  if (visible_content_only == nil) then 
    visible_content_only = true
  end
  
  -- check if we've got a valid replace set first
  if (not validate_replace_set()) then
    return nil
  end

  -- replace current, or navigate to a new pos first
  if (not current_column) then
    return find_next(visible_content_only)
  end

  for _,property in pairs(current_property_set()) do
    if (replace_set[property] ~= "") then
       local column_property = tostring(property).."_string"
       current_column[column_property] = replace_set[property]
    end
  end

  return find_next(visible_content_only)
end


-------------------------------------------------------------------------------

-- replace_all

function replace_all()
  -- replace also invisible content with replace all in tracks & songs
  local visible_content_only = (current_scope() ~= song_scope and 
    current_scope() ~= song_track_scope)
    
  reset_status()
  repeat until(not replace_next(visible_content_only))

end



-----------------------------------------------------------------------------

-- show_help

function show_help()

   local help_message = [[
The find & replace tool, lets you find and replace note column (notes, instruments, and so on...) or effect column data in the pattern editor.

To find any non empty values, specify a '*' in the find fields. To replace matched entries with the original content, leave the replace fields empty. Else specify the values you like to replace the found columns with.

* A 'find' example:
Note, Instr, Vol, Pan, Delay
C-4, *, 20, *, *

Matches any occurences or 'C-4's which have a volume of 20. All other fields are ignored (always matched, empty or not), so a 'C-4 01 20 80' will match just like 'C-4 02 20 ..' will do...

* A 'replace' example:
using the find example above, setting the replace fields like:

Note, Instr, Vol, Pan, Delay
C-4, '', '', '', 20

will set the delay value to 20 for all matching lines. All other properties will remain unchanged.

To clear matched entries, use either '---' for notes, or '..' for any values. Just like you see it in the pattern editor...
]]

   local title = "Find And Replace Info"
   local buttons = {"OK"}

   renoise.app():show_prompt(title, help_message, buttons)
end


-------------------------------------------------------------------------------

-- show_dialog

function show_dialog()

  if find_replace_dialog and find_replace_dialog.visible then
    find_replace_dialog:show()
    return
  end
  
  --  consts

  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING

  local BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT

  local NOTE_WIDTH = 40
  local NUMBER_WIDTH = 30

  local BUTTON_WIDTH = 86
  local HELP_BUTTON_WIDTH = 10
  
  local POPUP_WIDTH = 2*BUTTON_WIDTH - 2*DEFAULT_MARGIN
  
  local vb = renoise.ViewBuilder()

  local find_builder = renoise.ViewBuilder()
  local replace_builder = renoise.ViewBuilder()

  -- start each find&replace with a clean state...
  reset_status()


  ----  build_search_set_row

  local function build_search_set_row(builder, search_set)

     ------  build_prop_column

     local function build_prop_column(builder, property, name, width, visible)
      assert(search_set[property] ~= nil,
        ("invalid property %s"):format( property))

      return builder:column {
        id = property,
        visible = visible,
        
        builder:text { 
          text = name 
        },
        builder:textfield {
          width = width,
          value = search_set[property],
          notifier = function(value)
            search_set[property] = value
          end
        }
      }
    end

    return builder:row {
      build_prop_column(builder, "note", "Note", NOTE_WIDTH, note_mode()),
      build_prop_column(builder, "instrument", "Inst", NUMBER_WIDTH, note_mode()),
      build_prop_column(builder, "volume", "Vol", NUMBER_WIDTH, note_mode()),
      build_prop_column(builder, "panning", "Pan", NUMBER_WIDTH, note_mode()),
      build_prop_column(builder, "delay", "Delay", NUMBER_WIDTH, note_mode()),
      build_prop_column(builder, "number", "No.", NUMBER_WIDTH, effect_mode()),
      build_prop_column(builder, "amount", "Value", NUMBER_WIDTH, effect_mode()),
    }
  end


  ----  update_mode_views

  local function update_mode_views()
    for _,builder in pairs { find_builder, replace_builder } do
      local views = builder.views

      -- set all invisible first to avoid that the rack expands
      for _,prop in pairs(note_and_effect_properties) do
        views[prop].visible = false
      end

      -- then make the selected modes properties visible
      for _,prop in pairs(note_properties) do
        views[prop].visible = note_mode()
      end
      
      for _,prop in pairs(effect_properties) do
        views[prop].visible = effect_mode()
      end
    end
  end


  --  create dialog

  find_replace_dialog = renoise.app():show_custom_dialog(
    "Find & Replace",

    vb:column {
      margin = DEFAULT_MARGIN,
      spacing = DEFAULT_MARGIN,
      uniform = true,

      -- Mode
      vb:column {
        margin = DEFAULT_MARGIN,
        style = "group",
        vb:text { text = "Mode:" },
        vb:switch {
          width = BUTTON_WIDTH,
          items = modes,
          value = current_mode_index,
          notifier = function(value)
            current_mode_index = value
            reset_status()
            update_mode_views()
          end
        },
      },

      -- Find what
      vb:column {
        margin = DEFAULT_MARGIN,
        style = "group",
        vb:text { text = "Find what:" },
        build_search_set_row(find_builder, find_set),
      },

      -- Replace with:
      vb:column {
        margin = DEFAULT_MARGIN,
        style = "group",
        vb:text { text = "Replace with:" },
        build_search_set_row(replace_builder, replace_set),
      },

      -- Search in:
      vb:column {
        margin = DEFAULT_MARGIN,
        style = "group",
        vb:text { text = "Search in:" },
        vb:popup {
          width = POPUP_WIDTH,
          items = scope_names,
          value = current_scope_index,
          notifier = function(value)
            current_scope_index = value
            reset_status()
          end
        },
      },

      vb:space{ height = BUTTON_HEIGHT - 2*DEFAULT_SPACING },

      -- Buttons:
      vb:row{
        vb:button {
          text = "Find Next",
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT,
          notifier = function ()
            if (find_next() == false) then
              renoise.app():show_warning(
                "No more matches found. "..
                "Reached the end of the current search scope...")
            end
          end
        },
        vb:button{
          text = "Replace",
          width = BUTTON_WIDTH,
          height = BUTTON_HEIGHT,
          notifier = function()
            if (replace_next() == false) then
              renoise.app():show_warning(
                "No more matches found. "..
                "Reached the end of the current search scope...")
            end
          end
        }
      },

      vb:button{
        text = "Replace All",
        width = BUTTON_WIDTH,
        height = BUTTON_HEIGHT,
        notifier = replace_all
      },

      vb:row {
        vb:space {
          width = 2*BUTTON_WIDTH - 2*DEFAULT_MARGIN - HELP_BUTTON_WIDTH
        },

        vb:button {
           text = "?",
           width = HELP_BUTTON_WIDTH,
           notifier = show_help
        }
      }
    }
  )

end


--[[---------------------------------------------------------------------------
---------------------------------------------------------------------------]]--
