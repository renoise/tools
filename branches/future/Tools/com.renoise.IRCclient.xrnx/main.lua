
renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Connect to #Renoise@espernet",
  invoke = function() main() end
}

local irc_host = "canis.esper.net"
local irc_port = 6667
local socket_timeout = 1000
local server, server_error

function main()
  ------------ ircclient.lua
  local start_time = os.clock()

  repeat
    server, server_error = renoise.Socket.create_client(
      irc_host, irc_port)
    -- wait a bit until the controller started...
  until (server or os.clock() - start_time > 2.0) 
  if server then
    print_server_replies()
    text_control()  

--    print_server_replies()  
--    server:send("PASS guest\r\n")
    server:send("NICK vvoois\r\n")
    print ("nick sent")
    print_server_replies()  
    server:send("USER voois 8 * : Vincent Voois\r\n")
    print ("user sent")
    local reply = print_server_replies()  
    local dopos = nil
    if reply ~= nil then
      dopos = string.find(reply, "PING")
    end
    if dopos ~= nil then
      reply = string.gsub(reply, "PING", "PONG").."\r\n"
      server:send(reply)
      print ("send:"..reply)
      print ("pong sent")
    end
    print_server_replies()  
    server:send("JOIN #renoise")
    print ("join sent")
--    while not server:receive("*l"):find("004") do end
--    server:send("PRIVMSG #Renoise :Testing my Lua socket client\n")
--    print_server_replies()  
   end
--  text_control()  
end


function print_server_replies()
  local command_line = nil
  local last_line = nil
  local dpos = nil
    
  repeat 
    if command_line ~= nil then
      last_line = command_line
    end
    local command_line, status = server:receive("*l", socket_timeout)
    if command_line ~= nil then
      dpos = string.find(command_line, "PING")
    end
    if  dpos ~= nil then
      command_line = string.gsub(command_line, "PING", "PONG").."\r\n"
      server:send(command_line)
      print ("send:"..command_line)
      print ("pong sent")
    end

    print (command_line)
  until command_line == nil

  return last_line
end

function send_and_receive(msg)
    server:send(msg)
    print_server_replies()  
end
--------------------------------------------------------------------------------

-- available_controls

function text_control()

  local function show_status(message)
    renoise.app():show_status(message); print(message)
  end
  
  -- we memorize a reference to the dialog this time, to close it
  local control_example_dialog = nil
  
  local vb = renoise.ViewBuilder()
  
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local DEFAULT_MINI_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_MINI_CONTROL_HEIGHT
  
  local TEXT_ROW_WIDTH = 80


  -- CONTROL ROWS
  
  -- textfield
  local textfield_row = vb:row {
    vb:text {
      width = TEXT_ROW_WIDTH,
      text = "vb:textfield"
    },
    vb:textfield {
      width = 300,
      text = "PONG ",
      notifier = function(text)
          send_and_receive(text)
      end
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
  
  control_example_dialog = renoise.app():show_custom_dialog(
    "Controls", dialog_content
  )

end

