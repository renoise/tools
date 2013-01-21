--[[============================================================================
main.lua
============================================================================]]--

-- requires
require 'globals'
require 'midi_device'
require 'gui_controls'
require 'gui_pattern_arp'
require 'gui_envelope_arp'
require 'gui_tool_options'
require 'gui_miscelaneous'
require 'midi_control'
require 'gui_init'
require 'pattern_processing'
require 'envelope_processing'
require 'preset_manager'
require 'undo_management'
require 'scale_finder_ea'  --Main routine by Jaan Pullerits (Aka Suva)



clear_undo_folder()
--------------------------------------------------------------------------------
-- Helper functions in the globals.lua that you can find scattered around here:
-- math.round(value) -> rounds up values with .5 or higher, rounds down if lower.
-- toboolean(value) -> converts (string)values to true or false
-- table.serialize(table) -> concats table contents to a string
-- string:split(pattern) -> splits string to a table based on a Regex pattern
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- menu registration
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
   name = "Main Menu:Tools:Epic Arpeggiator...",
   invoke = open_main_dialog
}

renoise.tool():add_keybinding {
  name = "Global:Tools:Epic Arp Midi Record Toggle",
  invoke = toggle_midi_record
}

function init_notifiers ()
  local song = renoise.song()
  local tool = renoise.tool()
  if not song.transport.lpb_observable:has_notifier(lpb_handler) then
    song.transport.lpb_observable:add_notifier(lpb_handler)  
  end 

--App idle notifier, a function called every 10msecs.
--Perform actions or checks here that require frequent polling but not overloading
--the script-engine.
--  if not instruments[sel_inst_idx].name_observable:has_notifier(get_instrument_index) then
    --instruments[sel_inst_idx].name_observable:add_notifier(get_instrument_index)
  --end

  if not renoise.tool().app_idle_observable:has_notifier(idle_handler) then
    renoise.tool().app_idle_observable:add_notifier(idle_handler)
  end

--generic instrument change (removed or added instruments)  
  if not (song.instruments_observable:has_notifier(update_envelope_arpeggiator_instrument_list)) then
    song.instruments_observable:add_notifier(update_envelope_arpeggiator_instrument_list)
  end
  
--Fired if the song is being changed for a loaded one or a new document
  if not (tool.app_new_document_observable:has_notifier(update_envelope_arpeggiator_instrument_list)) then
    tool.app_new_document_observable:add_notifier(update_envelope_arpeggiator_instrument_list)
  end

--Fired if the edit step value is being changed
  if not renoise.song().transport.edit_step_observable:has_notifier(set_row_frequency_size) then
    renoise.song().transport.edit_step_observable:add_notifier(set_row_frequency_size)
  end
  
end


function idle_handler()
--Reset key-state of the modifier keys.
--This is to prevent mouseclicks being intepreted as 
--"modifier + mouseclick" when no modifier is pressed
--Also allow the tonescope to be moved within a 500 milliseconds period.
--if after 500 milliseconds, the slider hasn't been changed, reset its undo recording.
  if os.clock() - grace_wait > .5 and grace_turn ~= 0 then
    
    if grace_turn == 1 then
      grace_turn = 2
    elseif grace_turn == 2 then
      grace_turn = 0
    end
    
  end
  --print (os.clock() - key_state_time_out)
  if os.clock() - key_state_time_out > .15 and key_state > 0 then
    key_state = 0
    if env_auto_apply == false then
      ea_gui.views['env_auto_apply'].color = COLOR_THEME
      ea_gui.views['env_auto_apply'].text = "Apply changes"
    end
    ea_gui.views['fetch_notes'].color = COLOR_THEME
    ea_gui.views['fetch_volume'].color = COLOR_THEME
    ea_gui.views['fetch_panning'].color = COLOR_THEME
  end
  
end

function init_tables(column)
  for t = 0,MAXIMUM_FRAME_LENGTH do
    if column == ENV_NOTE_COLUMN then
      env_note_value[t] = EMPTY_CELL
    elseif column == ENV_VOL_COLUMN then
      env_vol_value[t] = EMPTY_CELL
    elseif column == ENV_PAN_COLUMN then
      env_pan_value[t] = EMPTY_CELL
    elseif column == false then
      env_cut_value[t] = EMPTY_CELL
      env_res_value[t] = EMPTY_CELL
    end
  end

--[[

  if column == ENV_NOTE_COLUMN then
    note_loop_type = ENV_LOOP_OFF 
  elseif column == ENV_VOL_COLUMN then
    vol_loop_type = ENV_LOOP_OFF
  elseif column == ENV_PAN_COLUMN then
    pan_loop_type = ENV_LOOP_OFF
  end

  if note_scheme_size <= MINIMUM_FRAME_LENGTH then
    env_note_value[MINIMUM_FRAME_LENGTH] = NOTE_SCHEME_TERMINATION
  end
  if vol_scheme_size <= MINIMUM_FRAME_LENGTH then
    env_vol_value[MINIMUM_FRAME_LENGTH] = VOL_PAN_TERMINATION
  end
  if pan_scheme_size <= MINIMUM_FRAME_LENGTH then
    env_pan_value[MINIMUM_FRAME_LENGTH] = VOL_PAN_TERMINATION
  end
--]]  
  
  --note_scheme_size = 0
end
