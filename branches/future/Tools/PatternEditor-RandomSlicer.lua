--[[----------------------------------------------------------------------------
[kG] Random_Slicer.lua
----------------------------------------------------------------------------]]--

-- manifest

manifest = {}
manifest.api_version = 0.2

manifest.author = "kRAkEn/gORe [kraken@renoise.com]"
manifest.description = "Tool to slice-randomize drums in current pattern"

manifest.actions = {}
manifest.actions[#manifest.actions + 1] = {
  name = "MainMenu:Tools:Randomized Pattern Slicer",
  description = "Randomized slicing of drum in pattern",
  invoke = function() show_randomize_dialog() end
}


------------------------------------------------------------------------------
-- show_randomize_dialog

function show_randomize_dialog()

  local vb = renoise.ViewBuilder()
  
  local DEFAULT_DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local DEFAULT_CONTROL_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local TEXT_ROW_WIDTH = 80

  local control_example_dialog = nil
  control_example_dialog = renoise.app():show_custom_dialog(
    "Randomized slicing",
    vb:column {
      margin = DEFAULT_DIALOG_MARGIN,
      spacing = DEFAULT_CONTROL_SPACING,

      -- default group
      vb:column {
        style = "group",
        margin = DEFAULT_DIALOG_MARGIN,
 
        vb:button {
          text = "Randomize!",
          tooltip = "Hit this button to slice-randomize the current pattern.",
          width = 180,
          notifier = function()
            randomize_pattern_track ()
          end
        }
      },

      --- close button
      vb:row {
        vb:text {
          width = 2*TEXT_ROW_WIDTH,
        },
        vb:button {
          text = "Close",
          width = 60,
          notifier = function()
            control_example_dialog:close()
          end
        }
      }
    }
  )
  
end


------------------------------------------------------------------------------
-- randomize_pattern_track

function randomize_pattern_track ()
  local song = renoise.song()
  local pattern_lines, pattern_index, track_index, track_type
  local first_note, first_instr
  local line_count = 0    
  local effect_line_count = 0
  local effect_slice_value
 
  pattern_index = song.selected_pattern_index 
  track_index = song.selected_track_index
  track_type = song.tracks[track_index].type
  pattern_lines = song.patterns[pattern_index].number_of_lines

  if track_type ~= renoise.Track.TRACK_TYPE_MASTER and track_type ~= renoise.Track.TRACK_TYPE_SEND then

    local iter = song.pattern_iterator:lines_in_pattern_track(pattern_index, track_index)

    for _,line in iter do
      
      if line_count == 0 then
        if line.note_columns[1].note_string == "---" or
           line.note_columns[1].instrument_value == ".."
        then
          renoise.app():show_warning("You have to select a pattern with at least a note and instrument on the first line!") 
          break
        else
          first_note = line.note_columns[1].note_value
          first_instr = line.note_columns[1].instrument_value
        end
      end
      
      if (line_count % 4 == 0 and random(0,100) % 10 == 0) or effect_line_count > 0 then
        if effect_line_count == 0 then
          effect_line_count = 4
          effect_slice_value = random (0, 15) * 16
        end
        repeat_line (effect_line_count, first_note, first_instr, line, effect_slice_value)
        effect_line_count = effect_line_count - 1
      else
        randomize_line(line_count, first_note, first_instr, line)
      end

      line_count = line_count + 1
    end

  else

      renoise.app():show_warning("Cannot do randomized slicing on Master or Send-tracks!") 

  end

end


------------------------------------------------------------------------------
-- randomize_line

function randomize_line (number, note, instr, line)
  local place_note = math.random (0, 10) % 2
  local beat_note = number % 4
  local slice_value = random (0, 15) * 16
  
  if place_note == 0 or beat_note == 0 then
    line.note_columns[1].note_value = note
    line.note_columns[1].instrument_value = instr
    line.note_columns[1].volume_string = ".."
    line.note_columns[1].delay_string = ".."
    line.effect_columns[1].number_value = 0x09
    line.effect_columns[1].amount_value = slice_value
  else
    line.note_columns[1].note_string = "---"
    line.note_columns[1].instrument_string = ".."
    line.note_columns[1].volume_string = ".."
    line.note_columns[1].delay_string = ".."
    line.effect_columns[1].number_string = ".."
    line.effect_columns[1].amount_string = ".."
  end
end


------------------------------------------------------------------------------
-- repeat_line

function repeat_line (number, note, instr, line, slice_value)
  line.note_columns[1].note_value = note
  line.note_columns[1].volume_value = number * 32
  line.note_columns[1].instrument_value = instr
  line.effect_columns[1].number_value = 0x09
  line.effect_columns[1].amount_value = slice_value
end


------------------------------------------------------------------------------
-- random

function random (min, max)
  return min + math.random (max)
end

