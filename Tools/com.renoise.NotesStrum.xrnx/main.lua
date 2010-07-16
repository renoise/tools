-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- tool setup
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

-- menu options

local OPTION_SELECTION_IN_PATTERN = 1
local OPTION_TRACK_IN_PATTERN = 2
local OPTION_TRACK_IN_SONG = 3

local range_options = {
  "Selection in Track", 
  "Track in Pattern", 
  "Track in Song"
}
      

-- menu entries
            
renoise.tool():add_menu_entry {
   name = "Pattern Editor:Strum Notes...",
   invoke = function() open_strum_dialog() end
}

renoise.tool():add_menu_entry {
  name = "Pattern Editor:Pattern:Strum Notes in Selection",
  invoke = function() execute_strum(OPTION_SELECTION_IN_PATTERN) end
}

renoise.tool():add_menu_entry {
  name = "Pattern Editor:Track:Strum Notes in Pattern",
  invoke = function() execute_strum(OPTION_TRACK_IN_PATTERN) end
}

renoise.tool():add_menu_entry {
  name = "Pattern Editor:Track:Strum Notes In Song",
  invoke = function() execute_strum(OPTION_TRACK_IN_SONG) end
}


-- key bindings

renoise.tool():add_keybinding {
  name = "Pattern Editor:Block Operations:Strum Notes",
  invoke = function() execute_strum(OPTION_SELECTION_IN_PATTERN) end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Track Operations:Strum Notes in Pattern",
  invoke = function() execute_strum(OPTION_TRACK_IN_PATTERN) end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Track Operations:Strum Notes in Song",
  invoke = function() execute_strum(OPTION_TRACK_IN_SONG) end
}


-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- main content
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

local down_up = 0
local up_down = 0.5
local down = 1
local up = 0

local safe_mode = true
local popup_index = 0
local delay_step = 16

local first_note = 0
local offs_delay = 0
local marker_area = 1
local not_extended = false
local line_had_valid_notes = false

local strum_dialog = nil


-----------------------------------------------------------------------------

function open_strum_dialog(range_option)
   --Here we set the pop_index to a valid value, the "execute_strum" function
   --must know, if the Gui has been opened or not so the user always gets the
   --possibility to change options before executing the script using a hotkey
   --This means that pop_up index will always be 0 during the first start-up.
   popup_index = 1

   if range_option ~= nil then
      marker_area = range_option
   end

   if (strum_dialog and strum_dialog.visible) then
      -- only show one dialog at the same time...
      strum_dialog:show()
   
   else
      local vb = renoise.ViewBuilder()

      local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
      local DIALOG_BUTTON_HEIGHT = renoise.ViewBuilder.DEFAULT_DIALOG_BUTTON_HEIGHT

      local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
      local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
      
      local TEXT_ROW_WIDTH = 80

      strum_dialog = renoise.app():show_custom_dialog(
      "Strum Generator",

      vb:column {
         margin = DIALOG_MARGIN,
         spacing = CONTENT_SPACING,
         uniform = true,

      --- valuebox
         vb:row {

            vb:text {
               width = TEXT_ROW_WIDTH,
               text = "Delay steps"
            },

            vb:valuebox {
               min = 0,
               max = 64,
               value = delay_step,
               notifier = function(value)
               delay_step = value
               end,
               tooltip = "Next delay value = previous (generated) " ..
               "delay value + delay step\n(min value 0, max value 64)",
            },
         },

         vb:row {

            vb:text {
               width = TEXT_ROW_WIDTH,
               text = "Strum direction"
            },

            vb:popup {
               id = "popup",
               width = 95,
               items = {"Down", "Up", "Down then up", "Up then down"},
               value = popup_index,
               notifier = function(new_index)
               popup_index = new_index
               end,
            }
         },

         vb:row {
            vb:text {
            width = TEXT_ROW_WIDTH,
            text = "Which area"
         },

         vb:chooser {
            id = "chooser",
            width = 100,
            value = marker_area,
            items = range_options,

            notifier = function(new_index)
            local chooser = vb.views.chooser
               marker_area = new_index
            end
          }
        },         

        vb:space{
          height = 3*CONTENT_SPACING
        },

        vb:row {

          vb:checkbox {
            tooltip = "When checked, delay values beyond 255 will " ..
            "not be truncated\nto new delay values added to an offset of 00 ",

            value = safe_mode,
            notifier = function(value)
            safe_mode = value
            end,
          },

          vb:text {
            width = TEXT_ROW_WIDTH,
            text = "Apply safe delay change"
          }
        },

        vb:space{
          height = 3*CONTENT_SPACING
        },

        vb:row {

          vb:space {
            width = 40
          },
        
          vb:button {
            text = "Strum Notes",
            width = 100,
            height = DIALOG_BUTTON_HEIGHT,
            notifier = function()
              execute_strum(marker_area)
            end,
          },

          vb:space {
            width = 30,
          },
  
          vb:button {
            text = "?",
            width = 10,
            height = DIALOG_BUTTON_HEIGHT,
            notifier = function()
              show_help()
            end,
          }
        }
      }
    )
 end
end


-----------------------------------------------------------------------------

function show_help()
   renoise.app():show_prompt(
      "About Strum Generator",
            [[This strum generator generates strum emulation, usually for string instruments.
It scans for more than one note on each row and applies a small delay to the 
following note thereafter. Delay values are increased using the delay-step value. 
You can emulate guitar strokes, harp strokes etc.

Hey you can even apply note grooves on percussion!
            
Note:this snap-in does not work on one note-column tracks and requires multiple 
notes on one row!]],
      {"OK"}
   )

end


-----------------------------------------------------------------------------

function execute_strum(range_option)

   if popup_index == 0 then
      open_strum_dialog(range_option)
   elseif popup_index == 1 then
      strum(down, range_option)
   elseif popup_index == 2 then
      strum(up, range_option)
   elseif popup_index == 3 then
      strum_two_ways(down_up, range_option)
   elseif popup_index == 4 then
      strum_two_ways(up_down, range_option)
   else
      assert(false, "unexpected popup index")
   end

end


-----------------------------------------------------------------------------

function strum(direction, range_option)

   -- Apply delay's upward or downward (one stroke)
   local line_count = 0
   local song = renoise.song()
   local pattern_index = song.selected_pattern_index
   local track_index = song.selected_track_index
   local track_type = song.selected_track.type
   local pattern_lines = song.selected_pattern.number_of_lines

   if range_option ~= nil then
      marker_area = range_option
   end   

   if track_type ~= renoise.Track.TRACK_TYPE_MASTER and
      track_type ~= renoise.Track.TRACK_TYPE_SEND 
   then
      --show delay column in case it is invisible      
      song.tracks[track_index].delay_column_visible = true

      local iter
   
      if marker_area == OPTION_SELECTION_IN_PATTERN then
         iter = song.pattern_iterator:lines_in_pattern(pattern_index)
         renoise.app():show_status("Strumming Selection in Pattern...")

      elseif marker_area == OPTION_TRACK_IN_PATTERN then
         iter = song.pattern_iterator:lines_in_pattern_track(
           pattern_index, track_index)
         renoise.app():show_status("Strumming Track in Pattern...")

      elseif marker_area == OPTION_TRACK_IN_SONG then
         iter = song.pattern_iterator:lines_in_track(track_index)
         renoise.app():show_status("Strumming Track in Song...")
      end
      
      for _,line in iter do
         -- First note is the offset for the strum, for each line this
         -- must be reset to 0
         first_note = 0
         if not line.is_empty then

            if direction == down then

               for _,note_column in ipairs(line.note_columns) do

                  if marker_area ~= OPTION_SELECTION_IN_PATTERN or 
                     note_column.is_selected 
                  then
                     note_column = apply_strum_delay(note_column)
                  end 

               end

            else

               for _,note_column in ripairs(line.note_columns) do

                  if marker_area ~= OPTION_SELECTION_IN_PATTERN or 
                     note_column.is_selected 
                  then
                     note_column = apply_strum_delay(note_column)
                  end

               end

            end

         end

      end

      if not_extended then
         renoise.app():show_warning(
            "Some delays not extended:\rprev. value + delay step exceeds 255")
            not_extended = false
      end

   else
      renoise.app():show_warning("Cannot strum Master or Send-tracks!")
   end

end


-----------------------------------------------------------------------------

function strum_two_ways(direction, range_option)
   --print ("direction ->" .. direction)

   -- Apply delay's according to the desired direction (e.g. double
   -- guitar strokes)
   local song = renoise.song()
   local pattern_lines = song.selected_pattern.number_of_lines
   local pattern_index = song.selected_pattern_index
   local track_index = song.selected_track_index
   local track_type = song.selected_track.type
   
   if range_option ~= nil then
      marker_area = range_option
   end   
   
   if track_type ~= renoise.Track.TRACK_TYPE_MASTER and
      track_type ~= renoise.Track.TRACK_TYPE_SEND 
   then
      --show delay column in case it is invisible      
      song.tracks[track_index].delay_column_visible = true
      
      local iter
   
      if marker_area == OPTION_SELECTION_IN_PATTERN then
         iter = song.pattern_iterator:lines_in_pattern(pattern_index)
         renoise.app():show_status("Strumming Selection in Pattern...")

      elseif marker_area == OPTION_TRACK_IN_PATTERN then
         iter = song.pattern_iterator:lines_in_pattern_track(
           pattern_index, track_index)
         renoise.app():show_status("Strumming Track in Pattern...")

      elseif marker_area == OPTION_TRACK_IN_SONG then
         iter = song.pattern_iterator:lines_in_track(track_index)
         renoise.app():show_status("Strumming Track in Song...")
      end

      local line_type = 0

      for _,line in iter do
         -- First note is the offset for the strum, for each line this
         -- must be reset to 0
         first_note = 0
         if not line.is_empty then
            -- Only odd counted lines will be strummed upwards and even
            -- counted lines will be strummed downwards
            line_had_valid_notes = false
            line_type = line_type + 1

            if (round((line_type/2),0) - (line_type / 2)) ~= direction then

               for _,note_column in ipairs(line.note_columns) do

                  if marker_area ~= OPTION_SELECTION_IN_PATTERN or 
                     note_column.is_selected 
                  then
                     note_column = apply_strum_delay(note_column)
                  end

               end

            else

               for _,note_column in ripairs(line.note_columns) do

                  if marker_area ~= OPTION_SELECTION_IN_PATTERN or 
                     note_column.is_selected 
                  then
                     note_column = apply_strum_delay(note_column)
                  end

               end

            end

            if not line_had_valid_notes then
               line_type = line_type - 1
            end

         end

      end

      if not_extended then
         renoise.app():show_warning(
         "Some delays not extended:\rprev. value + delay step exceeds 255")
      end

   else
      renoise.app():show_warning("Cannot strum Master or Send-tracks!")
   end
end


-----------------------------------------------------------------------------

function apply_strum_delay(note_column)
  
  if note_column.note_value ~= renoise.PatternTrackLine.EMPTY_NOTE and
      note_column.note_value ~= renoise.PatternTrackLine.NOTE_OFF then

      if first_note ~= 0 then

         if offs_delay + delay_step <= 255 then
            note_column.delay_value=offs_delay + delay_step
         else
            -- Ouch, delay values would raise above 255 with the last
            -- inserted delay, do not change values or truncate and
            -- start from 00..
            if safe_mode then
               not_extended = true
            else
               note_column.delay_value = (delay_step - (255 - offs_delay))
            end

         end

      else
         --The first note will not have a delay applied, or at
         -- least not the step delay.
         first_note = 1
      end

      offs_delay = note_column.delay_value
      -- This is only for the two way strum, to prevent switching the other
      -- direction if only
      -- note-offs were encountered. In that case line was not empty, yet
      -- no delay values were filled in either.
      line_had_valid_notes = true

      return note_column
   end

end


-----------------------------------------------------------------------------

function round(num, idp)
   local mult = 10^(idp or 0)
   return math.floor(num * mult + 0.5) / mult
end

