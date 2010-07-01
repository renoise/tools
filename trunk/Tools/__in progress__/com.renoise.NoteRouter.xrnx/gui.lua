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
      vb:row{ 
        vb:column{ 
          style='group',
          margin=DEFAULT_MARGIN, 
          vb:horizontal_aligner {
            mode = "center",
            vb:text {
              width = 20,
              text = "Controller options"
            },
          },
          vb:row {
            margin = DEFAULT_MARGIN,
            vb:text {
              width = 20,
              text = "Device in:"
            },
            vb:popup {
              id = 'device_list',
              width = 180,
              value = 1,
              tooltip = 'Select midi-in device',
              items = {"None"},
              notifier = function(index)
              end
            },
          },
          vb:horizontal_aligner {
            mode = "center",
            vb:row {
              margin = DEFAULT_MARGIN,
              spacing = CONTENT_SPACING,
              uniform = true,
              vb:button {
                id = 'connect',
                text = "Start",
                tooltip = 'Trigger reading from midi device or\n read from pc keyboard.',
                width = 70,
                color = {36, 37, 44},
                notifier = function(value)
                  record_mode = not record_mode
                  if record_mode == true then
                    vb.views.connect.text = 'Stop'
                    vb.views.connect.color = {245, 245, 245}
                    midi_engine('start')
                  else
                    vb.views.connect.text = 'Start'
                    vb.views.connect.color = {36, 37, 44}
                    midi_engine('stop')
                  end
                end,
              },
              vb:switch {
                id = "mode_switch",
                width = 120,
                value = record_destination,
                tooltip = 'Learning:Map note-keys to tracks\nRecording:Record keys to mapped tracks',
                items = {"Learning", "Recording"},
                notifier = function(index)
                  record_destination = index
                end
              } 
            } 
          }
        } 
      }  
    },
      vb:horizontal_aligner{
      mode = 'right',
    vb:column{
        vb:row{
          vb:button {
            text = "?",
            width = 10,
            height = 10,
            notifier = function()
              show_help()
            end,
          }      
        }
      }
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



-------------------------------------------------------------------------------
---                           Help dialog                                  ----
-------------------------------------------------------------------------------
function show_help()
   local vb = renoise.ViewBuilder()

   local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
   local DIALOG_SPACING = renoise.ViewBuilder.DEFAULT_DIALOG_SPACING

   renoise.app():show_prompt(
      "About Note mapper",
            [[
The note mapper allows you to bind specific notes to tracks. In this way you can
split your drumkits or otherwise effect kits across specific tracks and apply
different effect chains to each individual assigned sample or VSTI output channel.

Use of PC keyboard or selected Midi device possible.
You can manually insert these notes or you can record them into the 
pattern editor.

Programming:
-First select the track in the drop-down you want to bind a specific note to.
-Then select the learning mode
-Then click start to start the learning mode.
You can now press any key on your keyboard or midi keyboard, the triggered note 
will appear left in the line where the selected track is listed.

Recording:
-Select recording mode
-Click start
-Hit your programmed keys on pc keyboard or midi keyboard and observe where 
notes end up in the pattern editor.

Edit mode is automatically being turned off as soon as you click "start" so no
notes will unawarely end up in the pattern editor during learn mode and no
double notes are recorded during recording mode.


Limitations:
-You cannot record delay values (Quantize per line only)
-At higher BPM values, precision is getting less reliable
-Recording is only done on the first note-column of each track.
-CC messages are not recorded in the effect column.
-Note-off support for MIDI currently not programmed
-PC Keyboard input only works if dialog has focus.

This script is not a definite solution to an existing problem, yet it offers
an idea to add to the new XRNI structure. You are welcome to extend this script
in order to help shaping this part.

This script is not very suitable for live performances!

                                                                                                                         vV   
]],
      {"OK"}
   )

end
