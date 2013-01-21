--[[============================================================================
gui_init.lua, get and set initial values, then open the main frame
============================================================================]]--

  
function open_main_dialog(top_tab,sub_tab)
  if tool_dialog ~= nil then
    if tool_dialog.visible then
      return
    end
  end
  
  get_device_index()
  set_row_frequency_size()
  processing_instrument = 1
  track_index = renoise.song().selected_track_index
  max_note_columns = renoise.song().tracks[track_index].visible_note_columns
  column_offset = renoise.song().selected_note_column_index 
  if top_tab == nil  then
    top_tab = 1
    if first_show == false then
      init_tables(ENV_NOTE_COLUMN)    
      init_tables(ENV_VOL_COLUMN)    
      init_tables(ENV_PAN_COLUMN) 
      init_tables(false) 
      first_show = true
    else
      top_tab = tab_states.top
      sub_tab = tab_states.sub
    end
  end
  if sub_tab == nil then
    sub_tab = 1
  end
  if max_note_columns < 1 then -- Cursor on Master / sendtrack?
    max_note_columns = 1
    column_offset = 1
  end
  
  local vb = renoise.ViewBuilder()
  ea_gui = vb

  sub_tabs_bound = pat_tabs_bound
  tab_states.top = top_tab
  tab_states.sub = sub_tab
  
  if selected_device > #device_list then
    selected_device = 1
  end
  
  local main_frame = vb:column{
    id='main_frame',
    width=TOOL_FRAME_WIDTH,
    switchable_layout_definition(vb),
    profile_selection(vb),
    note_matrix_properties(vb),
    note_octave_properties(vb),
    ins_vol_properties(vb),
    arpeggio_options(vb),
    application_area(vb),
    preset_management(vb),
    pattern_arp_executor(vb),
    envelope_pattern_editor(vb),

    envelope_arp_executor(vb),
    app_options(vb),
    
  }

  
  init_tab_properties(vb)
  init_toggle_buttons(vb)
  init_notifiers()
  update_envelope_arpeggiator_instrument_list()
  sample_envelope_line_sync()
  get_preset_list(vb)
  set_visible_area()
  set_cursor_location()
  set_envelope_notifiers(processing_instrument)
  populate_columns()
  toggle_pan_vol_color()
  
  tool_dialog = renoise.app():show_custom_dialog(TOOL_TITLE, 
  main_frame,key_control)
end

---------------------------------------------------------------------------------------

function init_tab_properties(vb)
  vb.views['top_tab_1'].bitmap = "images/tab_pattern_arp.png"
  if tab_states.top == 1 then
    vb.views['top_tab_1'].mode = "button_color"
  elseif tab_states.top == 2 then
    vb.views['top_tab_2'].mode = "button_color"
  end
  vb.views['top_tab_2'].bitmap = "images/tab_envelope_arp.png"
  vb.views['top_tab_3'].bitmap = "images/tab_options.png"
  
  vb.views['sub_tab_1'].bitmap = "images/tab_note_profile.png"
  vb.views['sub_tab_1'].mode = "button_color"
  vb.views['sub_tab_2'].bitmap = "images/tab_ins_volume.png"
  vb.views['sub_tab_3'].bitmap = "images/tab_options.png"
  vb.views['sub_tab_4'].bitmap = "images/tab_pool_area.png"
  vb.views['sub_tab_5'].bitmap = "images/tab_presets.png"  

  if gui_layout_option ~= LAYOUT_TABS then  
    vb.views['sub_tab_row'].visible = false   
  end

end

---------------------------------------------------------------------------------------

function init_toggle_buttons(vb)
  vb.views['pat_toggle_1'].text = "Note profile"
  vb.views['pat_toggle_2'].text = "Ins & volume"
  vb.views['pat_toggle_3'].text = "Options"
  vb.views['pat_toggle_4'].text = "Area"
  vb.views['pat_toggle_5'].text = "Presets"
  
  vb.views['env_toggle_1'].text = "Env. profile"
  vb.views['env_toggle_2'].text = "Options"
  vb.views['env_toggle_3'].text = "Presets"

  if gui_layout_option ~= LAYOUT_CUSTOM then  
    vb.views['pat_toggle_row'].visible = false   
    vb.views['env_toggle_row'].visible = false   
  end  
  
  vb.views['env_multiplier'].active = false
  
  if env_auto_apply then
    vb.views['env_auto_apply'].color = bool_button[env_auto_apply]
  end
end


--------------------------------------------------------------------------------
--      End of teh road...
--------------------------------------------------------------------------------

