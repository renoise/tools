--[[============================================================================
gui.lua
============================================================================]]--

-- Login dialog

function client_login()
  
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
    },

    vb:row{

      vb:checkbox {
        width = 17,
        value = status_dialog_mode,
        id = 'irc_status_dialog_mode',
        notifier = function(value)
          status_dialog_mode = value
        end
      },

      vb:space {
        width = 62,
      },

      vb:text {
        width = TEXT_ROW_WIDTH,
        text = "Show status-window",
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
  vb_login = vb

  -- DIALOG
  if (not login_dialog or not login_dialog.visible) then
    login_dialog = renoise.app():show_custom_dialog(
      "Chat connect", dialog_content, login_key_handler
    )
  end

end


--------------------------------------------------------------------------------
-- Status dialog dialog
--------------------------------------------------------------------------------

function status_dialog()
  local target = ''
  local vb = renoise.ViewBuilder()
  
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local CONTROL_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
    
  local TEXT_ROW_WIDTH = 80


  if status_dialog_mode == false then
    return
  end

  -- CONTROL ROWS
  
  -- textfield
  local status_frame = vb:column{
    id='status_dialog_content',

    vb:row {
      margin = CONTROL_MARGIN,

      vb:multiline_text{
        width = 700,
        height = 300, 
        font = "mono",
        style = 'border',
        id = 'status_output_frame',
        text = ""
      },
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
          if no_loop == 0 then
            send_command(target, 'status', text)
            no_loop = 1
          else
            no_loop = 0
          end
        end
      },

      vb:button {
        width = TEXT_ROW_WIDTH,
        text = "Send",
        notifier = function(text)
          if no_loop == 0 then
            send_command(target, 'status', text)
            no_loop = 1
          else
            no_loop = 0
          end
         
        end
      },
    }
  }

  local minimize_button = vb:column{

    vb:row{

      vb:space{
        width = 622,
      },

      vb:button {
        id = 'minimizer',
        width = TEXT_ROW_WIDTH,
        text = "Minimize",
        notifier = function(text)
           if vb.views.minimizer.text == "Maximize" then
             vb.views.minimizer.text = "Minimize"
           else
             vb.views.minimizer.text = "Maximize"
           end
          vb.views.status_dialog_content.visible = not vb.views.status_dialog_content.visible
          vb.views.sdf:resize()
        end
      }
    },
  }
  
  local dialog_content = vb:column {
    id = 'sdf',
    margin = DIALOG_MARGIN,
    spacing = CONTENT_SPACING,
    uniform = true,
    status_frame, 
    minimize_button
  }
      
  
  -- DIALOG
  if (not irc_dialog or not irc_dialog.visible) then
    irc_dialog = renoise.app():show_custom_dialog(
      "Status", dialog_content, status_key_handler
    )
  end
  vb_status = vb

  return vb

end


--------------------------------------------------------------------------------
-- Chat dialog dialog
--------------------------------------------------------------------------------

function chat_dialog_control(target)
  active_channel = target
  local vb = renoise.ViewBuilder()
  
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local CONTROL_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
    
  local TEXT_ROW_WIDTH = 80
--  local no_loop = 0
  
  if irc_dialog == nil then
    --If dialog is being closed now, the connection is broken
    --yet only if the status window is not being used.
    switch_channel = false 
  end
  
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
--          edit_mode = false,
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
--          edit_mode = false,
          text = ""
        }
      },
    },

    vb:row{

      vb:text {
        width = TEXT_ROW_WIDTH,
        text = "text / command"
      },

      vb:multiline_text {
        width = 480,
        height = 20, 
        style = 'border',
        text = "",
        id = 'channel_command',
--[[
        notifier = function(text)
          if no_loop == 0 then
            send_command(target, 'channel', text)
            no_loop = 1 -- Prevent triggering the notifier again 
                        -- simply because the value got cleared
                        -- else a new empty command would be send again.
--            vb.views.channel_command.text = ""
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
          no_loop = 1
          vb.views.channel_command.text = ""
        end
--]]
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
      target, dialog_content, chat_key_handler
    )
  end
  vb_channel = vb

end

--------------------------------------------------------------------------------
-- Connection progress dialog
--------------------------------------------------------------------------------

function progress_dialog()
  local vb = renoise.ViewBuilder()
  
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local CONTROL_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
    
  local TEXT_ROW_WIDTH = 80
  
  local message_row = vb:column{
  
    vb:row{
  
      vb:text {
        width = TEXT_ROW_WIDTH,
        text = "Please wait while connecting..."
      },
    }  
  }
  
  
  -- DIALOG
  if (not connect_progress_dialog or not connect_progress_dialog.visible) then
    connect_progress_dialog = renoise.app():show_custom_dialog(
      'Connecting...', message_row, connect_key_handler
    )
  end
  
end




