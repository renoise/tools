-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
-- GUI dialogs
-- -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=


function main_dialog()


  local vb = renoise.ViewBuilder()
  local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN



  local TEXT_ROW_WIDTH = 80
  local title = "Note mapper (map notes to tracks)"
  
  local dialog_content = vb:column {
    margin = DIALOG_MARGIN,
    spacing = 5,

    vb:row {
      style = 'group',
      margin = DEFAULT_MARGIN,
      vb:text {
        width = 20,
        text = "Map note "
      },
      vb:text {
        id = 'note_field',
        width = 20,
        text = "None"
      },
      vb:text {
        width = 20,
        text = "to track:"
      },
      vb:popup {
        id = 'trackindex',
        width = 100,
        value = 1,
        tooltip = 'Hit note on your keyboard to attach',
        items = {"None"},
        notifier = function(index)
          vb.views.note_field.text = note_to_track[index]
        end
      },
      vb:button {
        text = "Clear",
        width = 60,
        tooltip = 'Clear track-mapping',
        notifier = function(value)
          note_to_track[vb.views.trackindex.value] = 'None'
          vb.views.note_field.text = note_to_track[vb.views.trackindex.value]
        end,
      },
    },
    vb:horizontal_aligner {
      mode = "center",
      vb:row {
        style = "group",
        margin = DEFAULT_MARGIN,
        spacing = CONTENT_SPACING,
        uniform = true,
        vb:button {
          id = 'connect',
          text = "Connect",
          tooltip = 'Connect to midi device or\n record from pc keyboard (not yet supported)',
          width = 70,
          color = {36, 37, 44},
          notifier = function(value)
            record_mode = not record_mode
            if record_mode == true then
              vb.views.connect.text = 'Disconnect'
              vb.views.connect.color = {245, 245, 245}
              midi_engine('start')
            else
              vb.views.connect.text = 'Connect'
              vb.views.connect.color = {36, 37, 44}
              midi_engine('stop')
            end
          end,
        },
        vb:switch {
          id = "mode_switch",
          width = 120,
          value = record_destination,
          tooltip = 'Mapping:Map keys to tracks\nRecording:Record keys to mapped tracks',
          items = {"Mapping", "Recording"},
          notifier = function(index)
            record_destination = index
          end
        },    
     
      },
    }
  }  
  note_map_dialog_vb = vb

  if not note_map_dialog or not note_map_dialog.visible then
    note_map_dialog = renoise.app():show_custom_dialog(
      title, dialog_content, key_handler)
  else
    note_map_dialog:show()
  end

  
end



