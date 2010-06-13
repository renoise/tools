------------------------------------------------------------------------------
----------------------       Simple IRC client       -------------------------
------------------------------------------------------------------------------
local irc_host = "canis.esper.net"
local irc_port = 6667
local irc_user = "guest"
local irc_nick_name = "jdoe452"
--local irc_real_name = "Renoise IRC client"
local irc_real_name = "J. dorkalong"
local irc_channel = "#myhhchannel"
local socket_timeout = 1000
local server, server_error
local rirc = nil
local last_idle_time = 0
local irc_dialog = nil
local chat_dialog = nil
local sessions = {}


renoise.tool():add_menu_entry {
  name = "Main Menu:Help:Visit the Community Chatroom",
  invoke = function() client_login() end
}

function print_server_replies()
  -- Only run every 0.3 seconds
  if (os.clock() - last_idle_time < 2.0) then
    return
  end    

  if (not irc_dialog or not irc_dialog.visible) then
    stop_message_engine()
    return
  end


  repeat 
    local command_line, status = server:receive("*l", socket_timeout)
    if command_line ~= nil then
      -- If a ping is received, reply immediately
      local pingpos = string.find(command_line, "PING")
      if  pingpos ~= nil then
        command_line = string.gsub(command_line, "PING", "PONG").."\r\n"
        server:send(command_line)
      end
      print (command_line)
      rirc.views.console_frame:add_line(command_line)
      rirc.views.console_frame:scroll_to_last_line()
    end
  until command_line == nil
  last_idle_time = os.clock()
end


function set_nick(nick)
  local COMMAND = "NICK "..nick.."\r\n"
  print (COMMAND)
 server:send(COMMAND)
end


function register_user(user, real_name)
  local COMMAND = "USER "..user.." 8 * : "..real_name.."\r\n"
  print (COMMAND)
  server:send(COMMAND)
end


function join_channel(channel)
  local COMMAND = "JOIN "..channel.."\r\n"
  print (COMMAND)
  server:send(COMMAND)
end


function quit_irc()
  local COMMAND = "QUIT :Has left the building\r\n"
  print (COMMAND)
  server:send(COMMAND)
end


function send_command (command)
  if command ~= nil then
    local COMMAND = command.."\r\n"
    server:send(COMMAND)
  end
end

-- Start running the message poller
function start_message_engine()
  if not (renoise.tool().app_idle_observable:has_notifier(print_server_replies)) then
    renoise.tool().app_idle_observable:add_notifier(print_server_replies)
  end
end


-- Stop running the message poller
function stop_message_engine()
  if (renoise.tool().app_idle_observable:has_notifier(print_server_replies)) then
    renoise.tool().app_idle_observable:remove_notifier(print_server_replies)
    quit_irc()
  end
end

function open_chat_session(target)

  sessions[#sessions+1] = target

end
--------------------------------------------------------------------------------
-- GUI dialog

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
          irc_server = text
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
            local start_time = os.clock()
          
            repeat
              server, server_error = renoise.Socket.create_client(
                vb.views.irc_server.text, tonumber(vb.views.irc_server_port.text))
              -- wait a bit until the controller started...
            until (server or os.clock() - start_time > 2.0) 
            rirc = status_dialog()
  
            if server then
              set_nick(vb.views.irc_nick_name.text)            
              register_user(vb.views.irc_user_name.text, vb.views.irc_real_name.text)
              login_dialog:close()
          --    server:send("PRIVMSG #channelname :"..irc_nick_name.." in da house!!\r\n")
              start_message_engine()          
             end
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
      "Chat connect", dialog_content
    )
  end

end



function status_dialog()

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
        width = 500,
        height = 300, 
        id = 'console_frame',
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
        notifier = function(text)
          send_command(text)
          text = ""
        end
      },
      vb:button {
        width = TEXT_ROW_WIDTH,
        text = "Send",
        notifier = function(text)
          send_command(text)
        end
      },
    },
    vb:row{
      vb:button {
        width = TEXT_ROW_WIDTH,
        text = "Join #renoise community chat channel",
        notifier = function(text)
          join_channel(irc_channel)
          open_chat_session(chat_dialog_control(irc_channel))
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
      "Status", dialog_content
    )
  end
  return vb
end

function chat_dialog_control(target)

  local vb = renoise.ViewBuilder()
  
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local CONTROL_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
    
  local TEXT_ROW_WIDTH = 80


  -- CONTROL ROWS
  
  -- textfield
  local chat_frame_row = vb:column{
    vb:row{    
      vb:column {
        margin = CONTROL_MARGIN,
        vb:multiline_text{
          width = 300,
          height = 300, 
          id = 'chat_frame',
          text = ""
        }
      },
      vb:column {
        margin = CONTROL_MARGIN,
        vb:multiline_text{
          width = 200,
          height = 300, 
          id = 'user_frame',
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
        width = 300,
        text = "",
        notifier = function(text)
          send_command(text)
          text = ""
        end
      },
      vb:button {
        width = TEXT_ROW_WIDTH,
        text = "Send",
        notifier = function(text)
          send_command(text)
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
      target, dialog_content
    )
  end
  return vb
end
