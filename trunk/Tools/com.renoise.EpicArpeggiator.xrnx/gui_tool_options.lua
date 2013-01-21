--[[============================================================================
gui_tool_options.lua, Tool option components
============================================================================]]--

function app_options(vb)
  -------------------------------------------------------------------------
  -- Application options
  
  local midi_device_area=vb:column {
    width=428, 
    vb:row {
      vb:text{
        align='center',
        width=425,
        text='Application options'
      },
    },
    vb:row {
      vb:text {
        width=TEXT_ROW_WIDTH,
        text='Device'
      },
      vb:popup {
        id='popup_device',
        width=200,
        items=device_list,
        value=selected_device,
        tooltip="Select device for input or instrument control",
        bind=preferences.master_device,
        notifier=function(value)
          midi_record_mode  = true --Midi record mode should always be disabled
          toggle_midi_record()
          selected_device = value
          preferences:save_as("preferences.xml")
        end
      },
      vb:space {width = 5,},
      vb:text {
        width=50,
        text='Channel'
      },
      vb:valuebox {
        id='vbox_device_channel',
        width=50,
        min=0,
        max=16,
        value=selected_channel,
        tooltip='Midi channel to listen to',
        tostring = function(value) 

          if value == 0 then
            return "Any"
          else
            return tostring(value)
          end

        end,
        tonumber = function(str) 
          return tonumber(str)
        end,
        bind=preferences.master_channel,
        notifier=function(value) 
          midi_record_mode  = true --Midi record mode should always be disabled
          toggle_midi_record()
          selected_channel=value 
          preferences:save_as("preferences.xml")
        end
      },
      vb:button {
        id='midi_record_mode',
        text='record',
        tooltip = 'When toggle, start recording notes (default shortcut:F5)',
        color=midi_record_color,
        notifier=function()
          midi_record_mode = not midi_record_mode
          if midi_record_mode == true then
            midi_record_color = MIDI_RECORDING
            midi_engine('start')
          else
            midi_record_color = MIDI_MUTED
            midi_engine('stop')
          end
          vb.views['midi_record_mode'].color = midi_record_color
        end
      },
    },
  }
  local pattern_arp_area = vb:column{
    vb:row {
      vb:text{
        align='center',
        width=428,
        text='Pattern Arpeggiator options'
      },
    },
    vb:row {
      vb:text {
        width=TEXT_ROW_WIDTH,
        text='Layout type',
      },
      vb:chooser {
        id='layout_option',
        width=265,
        items= {"Full (Classic mode)","Tabs (Compact mode)", "Custom"},
        value=gui_layout_option,
        bind=preferences.layout,
        notifier=function(value) 
          gui_layout_option = value 
          preferences:save_as("preferences.xml")
          if value == LAYOUT_TABS then
            vb.views['sub_tab_row'].visible = true
          else
            vb.views['sub_tab_row'].visible = false
          end
          if value == LAYOUT_CUSTOM then
            if tab_states.top == 1 then
              vb.views['pat_toggle_row'].visible = true   
            end
            if tab_states.top == 2 then
              vb.views['env_toggle_row'].visible = true   
            end
          else
            if tab_states.top == 1 then
              vb.views['pat_toggle_row'].visible = false
            end
            if tab_states.top == 2 then
              vb.views['env_toggle_row'].visible = true   
            end
          end
          set_visible_area()
        end
      },
    }
  }
  local envelope_arp_area = vb:column{
    vb:row {
      vb:text{
        align='center',
        width=428,
        text='Envelope Arpeggiator options'
      },
    },
    vb:row {
      vb:text {
        text = "Sequencer lines"
      },
      vb:valuefield {
        id='opt_visible_lines',
        width=20,
        
        tooltip='Amount of lines to show in the envelope sequencer',
        min = 5,
        max = 50,
        value = visible_lines,
        tostring = function(value)
          if value > 50 then
            value = 50
          end
          if value < 5 then
            value = 5
          end
          return string.format('%02d',value)
        end,
        tonumber = function(value)
          if tonumber(value) > 50 then
            value = 50
          end
          if tonumber(value) < 5 then
            value = 5
          end
          return tonumber(value)
        end,
        notifier=function(value)
          visible_lines = value
          preferences.opt_visible_lines.value = value
          preferences:save_as("preferences.xml")
          tool_dialog:close()
          open_main_dialog(2,1)
          line_position_offset = 0
          env_current_line.row = 0
          set_cursor_location()
        end
      }
    },
    vb:row {
      vb:text {
      
        text = "Enable undo"
      },
      vb:space {width =16,},
      vb:checkbox {
        id='enable_undo',
        width=18,
        tooltip='Uncheck this box if the undo saving is getting on your nerves',
        bind = preferences.enable_undo,
        notifier=function(value)
          preferences.enable_undo.value = value
          preferences:save_as("preferences.xml")
          enable_undo = value
        end
      },
      vb:button {
        width=40,
        text = 'Clear undo',
        tooltip='press this button to clear the undo data',
        notifier=function(value)
          clear_undo_folder()
        end
      }
    }  
  }

  local property_area = vb:column{
    margin = CONTENT_MARGIN,
    spacing = CONTENT_SPACING,
    width = TOOL_FRAME_WIDTH+9,
    id='app_option_area',
    vb:horizontal_aligner {
      mode = "justify",
      width = "100%",
      margin=10,
      vb:column {
        vb:row{
          vb:column{
            margin = DIALOG_MARGIN,
            style = "group",

            vb:horizontal_aligner {
              mode = "center",
              midi_device_area
            }
          }
        },
        vb:space{height=5},
        vb:row{
          vb:column{
            margin = DIALOG_MARGIN,
            style = "group",

            vb:horizontal_aligner {
              mode = "center",
              pattern_arp_area
            }
          }
        },
        vb:space{height=5},
        vb:row{
          vb:column{
            margin = DIALOG_MARGIN,
            style = "group",

            vb:horizontal_aligner {
              mode = "center",
              envelope_arp_area
            }
          }
        }
        
      }
    }
  }  
  return property_area
  
end



--------------------------------------------------------------------------------
--      End of teh road...
--------------------------------------------------------------------------------

