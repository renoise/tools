--------------------------------------------------------------------------------
-- GUI dialogs

------------------------------------------------------------------------------
----------------------       Login dialog frame      -------------------------
------------------------------------------------------------------------------

function client_login()
  
  local login_dialog = nil
  
  local vb = renoise.ViewBuilder()
  
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  
  local TEXT_ROW_WIDTH = 80


  local login_fields_generic = vb:column{
    id = 'login_dialog_content',
    vb:row {
      vb:text {
        width = TEXT_ROW_WIDTH,
        text = "server",
      },
      vb:textfield {
        width = 100,
        text = irc_host,
        id = 'irc_server',
        notifier = function(text)
          irc_host = text
        end
      },
    },
    vb:row {
      vb:text {
        width = TEXT_ROW_WIDTH,
        text = "port",
      },
      vb:textfield {
        width = 50,
        text = tostring(irc_port),
        id = 'irc_server_port',
        notifier = function(text)
          irc_port = text
        end
      },
    },
    vb:row {
      vb:text {
        width = TEXT_ROW_WIDTH,
        text = "channel",
      },
      vb:textfield {
        width = 100,
        text = irc_channel,
        id = 'irc_channel_name',
        notifier = function(text)
          irc_channel = text
        end
      },
    },
    vb:row {
      vb:text {
        width = TEXT_ROW_WIDTH,
        text = "username",
      },
      vb:textfield {
        width = 100,
        text = irc_user,
        id = 'irc_user_name',
        notifier = function(text)
          irc_user = text
        end
      },
    },
    vb:row{
      vb:text {
        width = TEXT_ROW_WIDTH,
        text = "real name",
      },
      vb:textfield {
        width = 100,
        text = irc_real_name,
        id = 'irc_real_name',
        notifier = function(text)
          irc_real_name = text
        end
      },
    }
  }
  
  
  local login_fields_nick = vb:column{

    vb:row{
      vb:text {
        width = TEXT_ROW_WIDTH,
        text = "nickname"
      },
      vb:textfield {
        width = 100,
        text = irc_nick_name,
        id = 'irc_nick_name',
        notifier = function(text)
          irc_nick_name = text
        end
      },
    },
    vb:space{
      height=10
    },
    vb:row{
      vb:horizontal_aligner {
        mode = "justify",
        spacing = 10,
        
        vb:button {
          width = 50,
          text = "Connect",
          notifier = function(text)
            connect_to_server(vb)
            login_dialog:close()
          end
        },

        vb:space {
          width = 35,
        },
        
        vb:button {
          width = 50,
          text = "More options",
          id = 'options_button',
          notifier = function(text)
           if vb.views.options_button.text == "More options" then
             vb.views.login_dialog_content.visible = true
             vb.views.options_button.text = "Less options"
           else
             vb.views.login_dialog_content.visible = false
             vb.views.options_button.text = "More options"
           end
           vb.views.visible_login_dialog:resize()         
          end
        }
      },
    }
  }
  -- MAIN CONTENT & LAYOUT
  
  local dialog_content = vb:column {
    id = "visible_login_dialog",
    margin = DIALOG_MARGIN,
    spacing = CONTENT_SPACING,
    uniform = true,
    login_fields_generic,
    login_fields_nick
  }
  
  vb.views.login_dialog_content.visible = false
  vb.views.visible_login_dialog:resize()         
  
  -- DIALOG
  if (not login_dialog or not login_dialog.visible) then
    login_dialog = renoise.app():show_custom_dialog(
      "Chat connect", dialog_content, key_handler
    )
  end

end

------------------------------------------------------------------------------
----------------------       Status dialog frame     -------------------------
------------------------------------------------------------------------------

function status_dialog()
  local target = ''
  local vb = renoise.ViewBuilder()
  
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local CONTROL_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
    
  local TEXT_ROW_WIDTH = 80


  -- CONTROL ROWS
  
  -- textfield
  local status_frame_row = vb:column{
    vb:row {
      margin = CONTROL_MARGIN,
      vb:multiline_text{
        width = 700,
        height = 300, 
        font = "mono",
        id = 'status_output_frame',
        text = ""
      }
    },
    vb:row{
      vb:text {
        width = TEXT_ROW_WIDTH,
        text = "text / command"
      },
      vb:textfield {
        width = 300,
        text = "",
        id = 'status_command',
        notifier = function(text)
          send_command(target, 'status', text)
          vb.views.status_command.text = ""
        end
      },
      vb:button {
        width = TEXT_ROW_WIDTH,
        text = "Send",
        notifier = function(text)
          send_command(target, 'status', text)
          vb.views.status_command.text = ""
        end
      },
    }
  }
  
  local dialog_content = vb:column {
    margin = DIALOG_MARGIN,
    spacing = CONTENT_SPACING,
    uniform = true,

    vb:column {
      status_frame_row, 
      vb:space { height = 2*CONTENT_SPACING },
    },
    
  }
  
  
  -- DIALOG
  if (not irc_dialog or not irc_dialog.visible) then
    irc_dialog = renoise.app():show_custom_dialog(
      "Status", dialog_content, key_handler
    )
  end
  vb_status = vb
  return vb
end

------------------------------------------------------------------------------
----------------------       Chat dialog frame       -------------------------
------------------------------------------------------------------------------

function chat_dialog_control(target)
  active_channel = target
  local vb = renoise.ViewBuilder()
  
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local CONTROL_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
    
  local TEXT_ROW_WIDTH = 80
  local no_loop = 0
  
  local chat_frame_row = vb:column{
    vb:row{    
      vb:column {
        margin = CONTROL_MARGIN,
        vb:multiline_text{
          width = 400,
          height = 300, 
          font = "mono",
          style = 'border',
          id = 'channel_output_frame',
          text = ""
        }
      },
      vb:column {
        margin = CONTROL_MARGIN,
        vb:multiline_text{
          width = 150,
          height = 300, 
          font = "mono",
          style = 'border',
          id = 'channel_user_frame',
          text = ""
        }
      },
    },
    vb:row{
      vb:text {
        width = TEXT_ROW_WIDTH,
        text = "text / command"
      },
      vb:textfield {
        width = 322,
        text = "",
        id = 'channel_command',
        notifier = function(text)
          if no_loop == 0 then
            send_command(target, 'channel', text)
            no_loop = 1 -- Prevent triggering the notifier again 
                        -- simply because the value got cleared
                        -- else a new empty command would be send again.
            vb.views.channel_command.value = ""
          else
            no_loop = 0
          end
        end
      },
      vb:space {
        width = 8,
      },
      vb:button {
        width = 150,
        text = "Send",
        notifier = function(text)
          send_command(target, 'channel', text)
          vb.views.channel_command.text = ""
        end
      },
    },
  }
  
  local dialog_content = vb:column {
    margin = DIALOG_MARGIN,
    spacing = CONTENT_SPACING,
    uniform = true,

    vb:column {
      chat_frame_row, 
      vb:space { height = 2*CONTENT_SPACING },
    },
    
  }
  
  
  -- DIALOG
  if (not chat_dialog or not chat_dialog.visible) then
    chat_dialog = renoise.app():show_custom_dialog(
      target, dialog_content, key_handler
    )
  end
  vb_channel = vb
end
