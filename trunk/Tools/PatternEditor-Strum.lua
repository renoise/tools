
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- manifest
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

manifest = {}
manifest.api_version = 0.2
manifest.author = "Vincent Voois [vincent.voois@gmail.com]"
manifest.description = "Strum script V2.303"

manifest.actions = {}

manifest.actions[#manifest.actions + 1] = {
   name = "MainMenu:Tools:Strum generator",
   description = "This script adds delay values for notes on the same row.",
   invoke = function() open_strum_dialog() end
}

manifest.actions[#manifest.actions + 1] = {
  name = "PatternEditor:Selection:Strum selection",
  description = "Executes strum. (for hotkey assignment) If preferences are opened, preferences will be opened instead",
  invoke = function() execute_strum(1) end
}
manifest.actions[#manifest.actions + 1] = {
  name = "PatternEditor:Track:Strum track",
  description = "Executes strum. (for hotkey assignment) If preferences are opened, preferences will be opened instead",
  invoke = function() execute_strum(2) end
}
manifest.actions[#manifest.actions + 1] = {
  name = "PatternEditor:Track:Strum track in song",
  description = "Executes strum. (for hotkey assignment) If preferences are opened, preferences will be opened instead",
  invoke = function() execute_strum(3) end
}
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- content
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

function open_strum_dialog(option)
   --Here we set the pop_index to a valid value, the "execute_strum" function
   --must know, if the Gui has been opened or not so the user always gets the
   --possibility to change options before executing the script using a hotkey
   --This means that pop_up index will always be 0 during the first start-up.
   popup_index = 1
   if option ~= nil then
      marker_area = option
   end

   -- only show one dialog at the same time...
   if not (strum_dialog and strum_dialog.visible) then
      strum_dialog = nil
      local vb = renoise.ViewBuilder()

      local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
      local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
      local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN

      local TEXT_ROW_WIDTH = 80

      strum_dialog = renoise.app():show_custom_dialog(
      "Strum generator",

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
      --- popup
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
      --- switch
         vb:row {
            vb:text {
            width = TEXT_ROW_WIDTH,
            text = "Which area"
         },
         vb:chooser {
            id = "chooser",
            width = 100,
            value = marker_area,
            items = {"Selection in track", 
            "Track in pattern", "Track in song"},

            notifier = function(new_index)
            local chooser = vb.views.chooser
               marker_area = new_index
            end
        }
      },         
      --- space
         vb:space{
            height = 3*CONTENT_SPACING
         },
      --- checkbox
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
      --- space
         vb:space{
            height = 3*CONTENT_SPACING
         },
      --- button
         vb:row {
            vb:space {
               width = 40
            },
            vb:button {
               text = "Strum my track",
               width = 60,
               notifier = function()
                  execute_strum(marker_area)
               end,
            },
            vb:space {
               width = 30,
            },
      --- subbutton
            vb:button {
               text = "?",
               width = 10,
               notifier = function()
                 show_help()
               end,
            }
         }
      }
   )
   else
      arpeg_option_dialog:show()
   end
end


-----------------------------------------------------------------------------

function show_help()
   renoise.app():show_prompt(
      "About Strum generator",
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

function execute_strum(option)

   if popup_index == 0 then
      open_strum_dialog(option)
   elseif popup_index == 1 then
      strum(down, option)
   elseif popup_index == 2 then
      strum(up, option)
   elseif popup_index == 3 then
      strum_two_ways(down_up, option)
   elseif popup_index == 4 then
      strum_two_ways(up_down, option)
   else
      assert(false, "unexpected popup index")
   end


end

-----------------------------------------------------------------------------

function strum(direction, option)

   -- Apply delay's upward or downward (one stroke)
   local line_count = 0
   local song = renoise.song()
   local pattern_index = song.selected_pattern_index
   local track_index = song.selected_track_index
   local track_type = song.selected_track.type
   local pattern_lines = song.selected_pattern.number_of_lines
   local iter
   if option ~= nil then
      marker_area = option
   end   

   if track_type ~= renoise.Track.TRACK_TYPE_MASTER and
   track_type ~= renoise.Track.TRACK_TYPE_SEND then
      --show delay column in case it is invisible      
      song.tracks[track_index].delay_column_visible = true

      if marker_area == 1 then
         iter = song.pattern_iterator:
         lines_in_pattern(pattern_index)
         renoise.app():show_status("Strumming selection in pattern")
      elseif marker_area == 2 then
         iter = song.pattern_iterator:
         lines_in_pattern_track(pattern_index, track_index)
         renoise.app():show_status("Strumming track in pattern")
      elseif marker_area == 3 then
         iter = song.pattern_iterator:lines_in_track(track_index)
         renoise.app():show_status("Strumming track in song")
      end
      
      for _,line in iter do
         -- First note is the offset for the strum, for each line this
         -- must be reset to 0
         first_note = 0
         if not line.is_empty then
            if direction == down then
               for __,note_column in ipairs(line.note_columns) do
                  if marker_area == 1 and note_column.is_selected or option ~= 1 then
                     note_column = apply_strum_delay(note_column)
                  end 
               end
            else
               for __,note_column in reverseipairs(line.note_columns) do
                  if marker_area == 1 and note_column.is_selected or option ~= 1 then
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

function strum_two_ways(direction, option)
   --print ("direction ->" .. direction)

   -- Apply delay's according to the desired direction (e.g. double
   -- guitar strokes)
   local song = renoise.song()
   local pattern_lines = song.selected_pattern.number_of_lines
   local pattern_index = song.selected_pattern_index
   local track_index = song.selected_track_index
   local track_type = song.selected_track.type
   local iter
   if option ~= nil then
      marker_area = option
   end   
   if track_type ~= renoise.Track.TRACK_TYPE_MASTER and
   track_type ~= renoise.Track.TRACK_TYPE_SEND then
      --show delay column in case it is invisible      
      song.tracks[track_index].delay_column_visible = true
      
         if marker_area == 1 then
            iter = song.pattern_iterator:
            lines_in_pattern(pattern_index)
            renoise.app():show_status("Strumming selection in pattern")
         elseif marker_area == 2 then
            iter = song.pattern_iterator:
            lines_in_pattern_track(pattern_index, track_index)
            renoise.app():show_status("Strumming track in pattern")
         elseif marker_area == 3 then
            iter = song.pattern_iterator:lines_in_track(track_index)
            renoise.app():show_status("Strumming track in song")
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
               for __,note_column in ipairs(line.note_columns) do
                  if marker_area == 1 and note_column.is_selected or option ~= 1 then
                     note_column = apply_strum_delay(note_column)
                  end
               end
            else
               for __,note_column in reverseipairs(line.note_columns) do
                  if marker_area == 1 and note_column.is_selected or option ~= 1 then
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

function reverseipairs(Arr)
   local I = #Arr
   local function Iter()
      local Ret1, Ret2
      if I>0 then
         Ret1, Ret2 = I, Arr[I]
         I = I - 1
      end
      return Ret1, Ret2
   end
   return Iter
end


-----------------------------------------------------------------------------

function round(num, idp)
   local mult = 10^(idp or 0)
   return math.floor(num * mult + 0.5) / mult
end
