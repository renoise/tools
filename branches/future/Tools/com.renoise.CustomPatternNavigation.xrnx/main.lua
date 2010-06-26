-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- tool registration
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Custom Pattern Navigation Setup...",
  invoke = function() 
     open_jump_dialog()
  end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Navigation:Custom Jump Lines Up",
  invoke = function() jump(1) end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Navigation:Custom Jump Lines Down",
  invoke = function() jump(2) end
}



-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- main content
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

local jump_dialog = nil
local row_step = 16
local switch_jump_mode_index = 1


-------------------------------------------------------------------------------

function open_jump_dialog()
   -- only show one dialog at the same time...
   if not (jump_dialog and jump_dialog.visible) then
      jump_dialog = nil
      local vb = renoise.ViewBuilder()

      local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
      local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
      local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN

      local TEXT_ROW_WIDTH = 90

      jump_dialog = renoise.app():show_custom_dialog(
         "Custom Pattern Navigation",
         vb:column {
            margin = DIALOG_MARGIN,
            spacing = CONTENT_SPACING,
            uniform = true,

      --- valuebox
            vb:row {
               vb:text {
                  width = TEXT_ROW_WIDTH,
                  text = "Jump Mode"
               },
               
               vb:popup {
                  id = "switch_jump_mode",
                  width = 140,
                  value = switch_jump_mode_index,
                  items = {"Lines", "Lines * LPB", "Length / Factor"},
                  tooltip = [[
Lines: Place each note straight at minimum distance.
Lines * LPB: Jump LPB amount of lines.
Length / Factor: The patternlength divided by given factor.]],
                  notifier = function(new_index)
                     switch_jump_mode_index = new_index
                  end   
               },
            },

            vb:row {
               vb:text {
                  width = TEXT_ROW_WIDTH,
                  text = "Steps or Factor "
               },
               vb:valuebox {
                  min = 0,
                  max = 512,
                  value = row_step,
                  tooltip = "Jump in row amounts 0 to max. 512 lines"..
                  "\nor set the division factor to divide the pattern size with",
                  notifier = function(value)
                     row_step = value
                  end,
               },
            },
            
            vb:space { height = 10 },
            
            vb:multiline_text {
               width = TEXT_ROW_WIDTH + 140,
               height = 55,
               text = "To use the custom mode, assign keyboard shortcuts to "..
               "'Custom Jump Lines Up/Down' in 'Pattern Editor/Navigation'."
            },
         }
      )
   else
      jump_dialog:show()
   end
end


-------------------------------------------------------------------------------

function jump(option)
   local song = renoise.song()
   local new_pos = 0
   local jump_steps = 0
   
   if switch_jump_mode_index == 1 then
      jump_steps = row_step 
   end
   if switch_jump_mode_index == 2 then
      jump_steps = song.transport.lpb
   end   
   if switch_jump_mode_index == 3 then
      jump_steps = song.selected_pattern.number_of_lines / row_step
   end
   
   if option == 1 then
--      new_pos = song.selected_line_index - jump_steps
      new_pos = song.transport.playback_pos
      new_pos.line = new_pos.line - jump_steps
      if new_pos.line < 1 then
         if song.selected_sequence_index-1 > 0 then
            local prv_sq_idx = song.selected_sequence_index-1
            local prv_pt = song.pattern_sequence[prv_sq_idx]
            local prv_pt_lines = song.patterns[prv_pt].number_of_lines
            if switch_jump_mode_index ~= 3 then 
               new_pos.line = prv_pt_lines + new_pos.line
            else
               --Always jump the division factor into the new pattern
               new_pos.line = prv_pt_lines - (prv_pt_lines / row_step) --+ 1
            end
            new_pos.sequence = song.selected_sequence_index -1
--            song.selected_sequence_index = song.selected_sequence_index -1
         else
            new_pos.line = 1
         end
      end
--      song.selected_line_index = new_pos
   end

   if option == 2 then
      new_pos = song.transport.playback_pos
      new_pos.line = new_pos.line + jump_steps
--      new_pos = song.selected_line_index + jump_steps
      if new_pos.line > song.selected_pattern.number_of_lines then
        
         if song.selected_sequence_index+1 <= #song.pattern_sequence then
            if switch_jump_mode_index ~= 3 then 
--               new_pos = new_pos - song.selected_pattern.number_of_lines
               new_pos.line = new_pos.line - song.selected_pattern.number_of_lines
            else
               local nxt_sq_idx = song.selected_sequence_index+1
               local nxt_pt =  song.pattern_sequence[nxt_sq_idx]
               local nxt_pt_lines = song.patterns[nxt_pt].number_of_lines
               --Always jump the division factor into the new pattern
               new_pos.line = (nxt_pt_lines / row_step) --+ 1
            end
            new_pos.sequence = song.selected_sequence_index +1
--            song.selected_sequence_index = song.selected_sequence_index +1
         else 
            new_pos.line = song.selected_pattern.number_of_lines
         end
      end
--      song.selected_line_index = new_pos
   end

   song.transport.playback_pos = new_pos
end

