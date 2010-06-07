
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Connect to #Renoise@espernet",
  invoke = function() client_login() end
}

local irc_host = "canis.esper.net"
local irc_port = 6667
local socket_timeout = 1000
local server, server_error
local rirc = nil


function print_server_replies()
  local command_line = nil
  local last_line = nil
  local dpos = nil
    
  repeat 
    if command_line ~= nil then
      last_line = command_line
    end
    local command_line, status = server:receive("*l", socket_timeout)
    -- If a ping is received, reply immediately
    if command_line ~= nil then
      rirc.views.console_frame:add_line(command_line)
      rirc.views.console_frame:scroll_to_last_line()
      dpos = string.find(command_line, "PING")
      if  dpos ~= nil then
        command_line = string.gsub(command_line, "PING", "PONG").."\r\n"
        server:send(command_line)
      end
    end
  until command_line == nil

  return last_line
end

function send_and_receive(msg)
    server:send(msg)
    print_server_replies()  
end

function set_nick(nick)
  local COMMAND = "NICK "..nick.."\r\n"
  print (COMMAND)
  send_and_receive(COMMAND)
end
function register_user(user, real_name)
  local COMMAND = "USER "..user.." 8 * : "..real_name.."\r\n"
  print (COMMAND)
  send_and_receive(COMMAND)
end

function join_channel(channel)
  local COMMAND = "JOIN "..channel.."\r\n"
  print (COMMAND)
  send_and_receive(COMMAND)
end

function send_command (command)
  if command ~= nil then
    local COMMAND = command.."\r\n"
    send_and_receive(COMMAND)
  end
end

--------------------------------------------------------------------------------

-- GUI dialog

function client_login()
  rirc = irc_dialog()
  
  local function show_status(message)
    renoise.app():show_status(message); print(message)
  end
  
  -- we memorize a reference to the dialog this time, to close it
  local login_dialog = nil
  
  local vb = renoise.ViewBuilder()
  
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local DEFAULT_MINI_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_MINI_CONTROL_HEIGHT
  
  local TEXT_ROW_WIDTH = 80


  -- CONTROL ROWS
  
  -- textfield
  local textfield_row = vb:column{
    vb:row {
      vb:text {
        width = TEXT_ROW_WIDTH,
        text = "username"
      },
      vb:textfield {
        width = 300,
        text = "guest",
        id = 'irc_user_name',
        notifier = function(text)
        end
      },
    },
    vb:row{
      vb:text {
        width = TEXT_ROW_WIDTH,
        text = "real name"
      },
      vb:textfield {
        width = 300,
        text = "Vincent Voois",
        id = 'irc_real_name',
        notifier = function(text)
        end
      },
    },
    vb:row{
      vb:text {
        width = TEXT_ROW_WIDTH,
        text = "nickname"
      },
      vb:textfield {
        width = 300,
        text = "vvoois",
        id = 'irc_nick_name',
        notifier = function(text)
        end
      },
    },
    vb:row{
      vb:button {
        width = TEXT_ROW_WIDTH,
        text = "Login",
        notifier = function(text)
          local start_time = os.clock()
        
          repeat
            server, server_error = renoise.Socket.create_client(
              irc_host, irc_port)
            -- wait a bit until the controller started...
          until (server or os.clock() - start_time > 2.0) 
          if server then
            print_server_replies()
            set_nick(vb.views.irc_nick_name.text)            
            print_server_replies()
            register_user(vb.views.irc_user_name.text, vb.views.irc_real_name.text)
            print_server_replies()
            login_dialog:close()
        --    while not server:receive("*l"):find("004") do end
        --    server:send("PRIVMSG #Renoise :Testing my Lua socket client\n")
        --    print_server_replies()  
           end
        end
      },
    }
  }
  -- MAIN CONTENT & LAYOUT
  
  local dialog_content = vb:column {
    margin = DIALOG_MARGIN,
    spacing = CONTENT_SPACING,
    uniform = true,

    vb:column {
      textfield_row, 
      vb:space { height = 2*CONTENT_SPACING },
    },
    
  }
  
  
  -- DIALOG
  
  login_dialog = renoise.app():show_custom_dialog(
    "IRC Client", dialog_content
  )

end



function irc_dialog()

  local function show_status(message)
    renoise.app():show_status(message); print(message)
  end
  
  -- we memorize a reference to the dialog this time, to close it
  local irc_dialog = nil
  
  local vb = renoise.ViewBuilder()
  
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local DEFAULT_MINI_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_MINI_CONTROL_HEIGHT
  local CONTROL_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
    
  local TEXT_ROW_WIDTH = 80


  -- CONTROL ROWS
  
  -- textfield
  local textfield_row = vb:column{
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
        end
      },
    },
    vb:row{
      vb:button {
        width = TEXT_ROW_WIDTH,
        text = "Send",
        notifier = function(text)
          send_command(text)
        end
      },
    }
  }
  -- MAIN CONTENT & LAYOUT
  
  local dialog_content = vb:column {
    margin = DIALOG_MARGIN,
    spacing = CONTENT_SPACING,
    uniform = true,

    vb:column {
      textfield_row, 
      vb:space { height = 2*CONTENT_SPACING },
    },
    
  }
  
  
  -- DIALOG
  
  irc_dialog = renoise.app():show_custom_dialog(
    "IRC Client", dialog_content
  )
  return vb
end
