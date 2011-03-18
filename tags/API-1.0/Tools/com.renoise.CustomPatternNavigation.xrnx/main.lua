--[[============================================================================
main.lua
============================================================================]]--

-- tool registration

local JUMP_UP = 1
local JUMP_DOWN = 2

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Custom Pattern Navigation Setup...",
  invoke = function() 
    open_jump_dialog()
  end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Navigation:Custom Jump Lines Up",
  invoke = function(repeated) jump(JUMP_UP) end
}

renoise.tool():add_keybinding {
  name = "Pattern Editor:Navigation:Custom Jump Lines Down",
  invoke = function(repeated) jump(JUMP_DOWN) end
}


--------------------------------------------------------------------------------
-- locals
--------------------------------------------------------------------------------

local jump_dialog = nil
local MODE_LINES = 1
local MODE_LINES_LPB = 2
local MODE_LENGTH_FACTOR = 3
local POS_MODE_PLAYBACK = 1
local POS_MODE_EDIT = 2
local row_step = 16
local switch_jump_mode_index = MODE_LINES_LPB
local switch_pos_mode_index = POS_MODE_PLAYBACK
local MAX_PATTERN_LINES = 512


--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

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
            max = MAX_PATTERN_LINES,
            value = row_step,
            tooltip = "Jump in row amounts 0 to max. 512 lines"..
            "\nor set the division factor to divide the pattern size with",
            notifier = function(value)
              row_step = value
            end,
          },
        },
        
        vb:row {

          vb:text {
            width = TEXT_ROW_WIDTH,
            text = "Position Mode "
          },

          vb:popup {
            id = "switch_pos_mode",
            width = 140,
            value = switch_pos_mode_index,
            items = {"Playback Position", "Edit Position"},
            tooltip = [[
Playback Position: Jumps to a new playback position. Good for live experimentation.
Edit Position: Jumps to a new edit position. Good in pattern edit mode or for
changing things on the fly during playback.]],
            notifier = function(new_index)
              switch_pos_mode_index = new_index
            end   
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


--------------------------------------------------------------------------------
-- processing
--------------------------------------------------------------------------------

function jump(option)
  local song = renoise.song()
  local new_pos = 0
  local jump_steps = 0
  
  if switch_jump_mode_index == MODE_LINES then
    jump_steps = row_step 
  end

  if switch_jump_mode_index == MODE_LINES_LPB then
    jump_steps = song.transport.lpb
  end   

  if switch_jump_mode_index == MODE_LENGTH_FACTOR then
    jump_steps = song.selected_pattern.number_of_lines / row_step
  end
  
  if option == JUMP_UP then
    if (switch_pos_mode_index == POS_MODE_PLAYBACK) then
      new_pos = song.transport.playback_pos
    end
    
    if (switch_pos_mode_index == POS_MODE_EDIT) then
      new_pos = song.transport.edit_pos
    end
    
    new_pos.line = new_pos.line - jump_steps

    if new_pos.line < 1 then

      if song.selected_sequence_index-1 > 0 then
        local prv_sq_idx = song.selected_sequence_index-1
        local prv_pt = song.sequencer.pattern_sequence[prv_sq_idx]
        local prv_pt_lines = song.patterns[prv_pt].number_of_lines

        if switch_jump_mode_index ~= MODE_LENGTH_FACTOR then 
          new_pos.line = prv_pt_lines + new_pos.line
        else
          --Always jump the division factor into the new pattern
          new_pos.line = prv_pt_lines - (prv_pt_lines / row_step) --+ 1
        end
        
        new_pos.sequence = song.selected_sequence_index -1
      else
        new_pos.line = 1
      end

    end
  end

  if option == JUMP_DOWN then
    if (switch_pos_mode_index == POS_MODE_PLAYBACK) then
      new_pos = song.transport.playback_pos
    end

    if (switch_pos_mode_index == POS_MODE_EDIT) then
      new_pos = song.transport.edit_pos
    end

    new_pos.line = new_pos.line + jump_steps
    if new_pos.line > song.selected_pattern.number_of_lines then
      
      if song.selected_sequence_index+1 <= #song.sequencer.pattern_sequence then
  
        if switch_jump_mode_index ~= MODE_LENGTH_FACTOR then 
          new_pos.line = new_pos.line - song.selected_pattern.number_of_lines
        else
          local nxt_sq_idx = song.selected_sequence_index+1
          local nxt_pt =  song.sequencer.pattern_sequence[nxt_sq_idx]
          local nxt_pt_lines = song.patterns[nxt_pt].number_of_lines
          --Always jump the division factor into the new pattern
          new_pos.line = (nxt_pt_lines / row_step) --+ 1
        end
        new_pos.sequence = song.selected_sequence_index +1
  
      else 
        new_pos.line = song.selected_pattern.number_of_lines
      end

    end
  end

    if (switch_pos_mode_index == POS_MODE_PLAYBACK) then
      song.transport.playback_pos = new_pos
    end

    if (switch_pos_mode_index == POS_MODE_EDIT) then
      song.transport.edit_pos = new_pos
    end

end

