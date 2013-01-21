--[[============================================================================
gui_miscelaneous.lua, Tabs/switches/help and various other dialogs & attributes
============================================================================]]--

function switchable_layout_definition(vb)
  ---------------------------------------------------------------------------
  -- Tabs and switches

  local top_tab_row = vb:row {}
  local sub_tab_row = vb:row {id='sub_tab_row'}
  local pat_toggle_row = vb:row {id='pat_toggle_row'}
  local env_toggle_row = vb:row {id='env_toggle_row'}

  for tabs = 1,top_tabs_bound do
    top_tab_row:add_child(
      vb:bitmap {
        mode = IMAGE_UNTOGGLED_MODE,
        bitmap = "images/tab_pattern_arp.png",
        id='top_tab_'..tostring(tabs),
        notifier = function()
          tab_states.top = tabs
          set_selected_tab("top_tab_",tabs, top_tabs_bound)
          top_tab_arming_toggle()
          if tab_states.top == 1 then
            visible_subtabs(tabs, pat_tabs_bound)
          elseif tab_states.top == 2 then
            visible_subtabs(tabs, env_tabs_bound)
          end
          set_visible_area()
        end
      }
    )
  end

  --- Help function
  top_tab_row:add_child(
    vb:horizontal_aligner {
      mode='right',
      vb:space{width=454-(top_tabs_bound*80)},
      vb:button {
        width=10,
        text="?",
        notifier= function()show_help()end
      },
      vb:space{width=2},
    }
  )
  
  for tabs = 1,sub_tabs_bound do
    sub_tab_row:add_child(
      vb:bitmap {
        mode = IMAGE_UNTOGGLED_MODE,
        bitmap = "images/tab_note_profile.png",
        id='sub_tab_'..tostring(tabs),
        notifier = function()
          tab_states.sub = tabs
          if tab_states.top == 1 then
            set_selected_tab("sub_tab_",tabs, pat_tabs_bound)
          elseif tab_states.top == 2 then
            set_selected_tab("sub_tab_",tabs, env_tabs_bound)
          end
          set_visible_area()
        end
      }
    )
  end
  
  for switch = 1,sub_tabs_bound do
    pat_toggle_row:add_child(
      vb:button {
        id='pat_toggle_'..tostring(switch),
        color=bool_button[pat_toggle_states[switch]],
        width=80,
        notifier = function()
          pat_toggle_states[switch] = not pat_toggle_states[switch]
          preferences['pat_toggle_'..tostring(switch)].value = pat_toggle_states[switch]
          preferences:save_as("preferences.xml") 
          ea_gui.views['pat_toggle_'..tostring(switch)].color = bool_button[pat_toggle_states[switch]]
          set_visible_area()
        end
      }
    )
  end

  for switch = 1,env_tabs_bound do

    env_toggle_row:add_child(
      vb:button {
        id='env_toggle_'..tostring(switch),
        color=bool_button[env_toggle_states[switch]],
        width=80,
        notifier = function()
          env_toggle_states[switch] = not env_toggle_states[switch]
          preferences['env_toggle_'..tostring(switch)].value = env_toggle_states[switch]
          preferences:save_as("preferences.xml") 
          ea_gui.views['env_toggle_'..tostring(switch)].color = bool_button[env_toggle_states[switch]]
          set_visible_area()
        end
      }
    )
  end
  
  local switch_area = vb:column {
    top_tab_row,
    sub_tab_row,
    pat_toggle_row,
    env_toggle_row,
  }
  return switch_area
end



--------------------------------------------------------------------------------
-- Warning dialog pattern sequence
--------------------------------------------------------------------------------

function cross_write_dialog(return_val, double, doubles, alias, vrb)
  local vb = renoise.ViewBuilder() 
  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local dialog_title = "Cross-write warning"

  local dialog_content = nil
  if alias == false then
    dialog_content = vb:column { 
      margin = CONTENT_MARGIN,
      spacing = CONTENT_SPACING,
      uniform = true,
      vb:text {
        align="center",
        text = "You have "..#double.." patterns that repeat on "..doubles..
        " positions\n".."If you arpeggiate across the song, you"..
        " might\nunawarely overwrite previously filled areas.\n\nDo you want to"..
        " make the pattern order\nunique in the pattern sequencer?"
      },
  
      vb:horizontal_aligner{
        mode = "center",
        vb:row{
          spacing = 8,
          vb:button { 
            width=50,
            text='Make unique',
            tooltip='Making all patterns unique by copying the pattern to a new instance',
            notifier=function()
              make_unique_pattern()
              pseq_warn_dialog:close()
              pseq_warn_dialog = nil
              return_val = 0
            end
          },
          vb:button { 
            width=50,
            text='Cancel',
            tooltip='reverts to previous area choice',
            notifier=function()
              pseq_warn_dialog:close()
              pseq_warn_dialog = nil
              if vrb.views.chooser.value == 3 then
                vrb.views.chooser.value = 2
              else
                vrb.views.chooser.value = 4
              end    
            end
          },
        }
      }
    }
  else
    dialog_content = vb:column { 
      margin = CONTENT_MARGIN,
      spacing = CONTENT_SPACING,
      uniform = true,
      vb:text {
        align="center",
        text = "Alias tracks are present, song mode is not supported for aliassed "..
        " tracks. either unalias the track, or pick a different track."
      },
  
      vb:horizontal_aligner{
        mode = "center",
        vb:row{
          spacing = 8,
          vb:button {
            width=50,
            text='Ok',
            tooltip='reverts to previous area choice',
            notifier=function()
              pseq_warn_dialog:close()
              pseq_warn_dialog = nil
              if vrb.views.chooser.value == 3 then
                vrb.views.chooser.value = 2
              else
                vrb.views.chooser.value = 4
              end
            end
          }
        }
      }
    }
  end
  
  if (pseq_warn_dialog and pseq_warn_dialog.visible)then
    pseq_warn_dialog:show()
  else
    pseq_warn_dialog = nil
    pseq_warn_dialog = renoise.app():show_custom_dialog(dialog_title,
    dialog_content)
  end

  return return_val

end

--------------------------------------------------------------------------------
-- Saving pattern arpeggio presets
--------------------------------------------------------------------------------

function save_dialog(type,vrb)
  local vb = renoise.ViewBuilder() 
  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local dialog_title = "Save preset"
  local preset_file = vrb.views.popup_preset.items[vrb.views.popup_preset.value]
  local saving_dialog = nil
  if type == ENVELOPE then
    preset_file = vrb.views.env_popup_preset.items[vrb.views.env_popup_preset.value]
  end
  local dialog_content = vb:column { 
      margin = CONTENT_MARGIN,
      spacing = CONTENT_SPACING,
      uniform = true,
      vb:text {
        align="center",
        text = "Preset name"
      },
      vb:textfield {
        id='textfield_filename',
        width=230,
        value=preset_file,
        tooltip="enter presetname without extensions",
        notifier=function(value)
          preset_file = value 
          preset_file = string.gsub(preset_file,",", "_")
          preset_file = string.gsub(preset_file," ", "_")
        end
      },
      vb:horizontal_aligner{
        mode = "center",
        vb:row{
          spacing = 8,
          vb:button {
            width=50,
            text='Save',
            tooltip='Save the preset under this name (existing files will be overwritten'..
                    ' without warning!!',
            notifier=function()
              save_preset(preset_file,type,vrb)
              
              saving_dialog:close()
              saving_dialog = nil
            end
          },
          vb:button {
            width=50,
            text='Cancel',
            tooltip='Abort saving',
            notifier=function()
              saving_dialog:close()
              saving_dialog = nil
            end
          },
        }
      }
    }
  if (saving_dialog and saving_dialog.visible)then
    saving_dialog:show()
  else
    saving_dialog = nil
    saving_dialog = renoise.app():show_custom_dialog(dialog_title,
    dialog_content)
  end

end


function file_exists_dialog(preset_name)
  local vb = renoise.ViewBuilder()

  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local DIALOG_SPACING = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING
  local message = "Preset "..preset_name.." already exists... Overwrite?"
  local choice = renoise.app():show_prompt("Warning",message, {"Overwrite", "Cancel"})

  if choice == 1 or choice == "Overwrite" then 
    return true
  else
    return false
  end
end


function recorrect_notifier(vb)
  vb.views['textfield_filename'].notifier = function(value)
    preset_file = value 
    preset_file = string.gsub(preset_file,",", "_")
    preset_file = string.gsub(preset_file," ", "_")
    vb.views['textfield_filename'].notifier = function(value)end
    vb.views['textfield_filename'].value = preset_file
    recorrect_notifier()
  end

end


--------------------------------------------------------------------------------
-- Pick any particular undo option
--------------------------------------------------------------------------------


function undo_management()
  -------------------------------------------------------------------------
  -- Undo management
  local vb = renoise.ViewBuilder()
  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING  
  local dialog_title = "Undo management"
  local undo_area = nil
  local property_area = nil
  undo_gui = vb
  
  if not undo_dialog or not undo_dialog.visible then
    undo_area=vb:column {
      vb:row {
        vb:text {
          width=TEXT_ROW_WIDTH,
          text='Undo this action'
        },
        vb:popup {
          id='popup_undo',
          width=320,
          items=undo_descriptions,
          value=#undo_descriptions,
          tooltip="Select action level\n",
          notifier=function(value)pat_preset_field = value end
        },
        vb:space {width = 10,},
        vb:button {
          width=10,
          text='Restore',
          tooltip='Restore this situation',
          notifier=function()
            load_undo_state(undo_gui.views['popup_undo'].value)
          end
        }
      }
    }
  
    property_area = vb:column{
      margin = CONTENT_MARGIN,
      spacing = CONTENT_SPACING,
      width = TOOL_FRAME_WIDTH,
      id='undo_area',
      vb:horizontal_aligner {
        mode = "justify",
        width = "100%",
        margin=SECTION_MARGIN,
        vb:column {
          vb:row{
            vb:column{
              margin = DIALOG_MARGIN,
              style = "group",
  
              vb:horizontal_aligner {
                mode = "center",
                undo_area
              }
            }
          }
        }
      }
    }
  end
  if (undo_dialog and undo_dialog.visible)then
    undo_dialog:show()
  else
    undo_dialog = nil
    undo_dialog = renoise.app():show_custom_dialog(dialog_title,property_area)
  end
end

--------------------------------------------------------------------------------
--      End of teh road...
--------------------------------------------------------------------------------

