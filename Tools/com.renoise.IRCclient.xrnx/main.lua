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
local client, client_error
local rirc = nil
local last_idle_time = 0
local irc_dialog = nil
local chat_dialog = nil
local session = {}
local sessions = 1
local target = nil
local vb_channel = nil
local vb_status = nil


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
    local command_line, status = client:receive("*l", 0)
    if command_line ~= nil then
      -- If a ping is received, reply immediately
      local pingpos = string.find(command_line, "PING")
      if pingpos ~= nil then
        command_line = string.gsub(command_line, "PING", "PONG").."\r\n"
        client:send(command_line)
      end
      local quit_reply = string.find(string.lower(command_line),"quit: ")

      if quit_reply ~= nil then
        --Silently leave the arena when server returns a quit reply.
        stop_message_engine()
        local EOT = "Server disconnected ->"..command_line
        vb_status.views.status_output_frame:add_line(EOT)
        vb_channel.views.channel_output_frame:add_line(EOT)
        return
      end

      print (command_line)
      if string.find(command_line, irc_nick_name) ~= 1 and string.find(command_line, " PRIVMSG ") ~= nil then
        local msg_type = string.find(command_line,"PRIVMSG")+8
        local msg_start = string.find(command_line,":",msg_type)
        local user_say = string.sub(command_line,2,string.find(command_line,"!")-1)
        local say_channel = string.sub(command_line,msg_type, msg_start-1)
        local say_text = string.sub(command_line,msg_start+1)
        local channel_line = "<"..user_say.."> "..say_text
--        if say_channel == irc_channel then
          vb_channel.views.channel_output_frame:add_line(channel_line)
          vb_channel.views.channel_output_frame:scroll_to_last_line()
--        end 
      end
--      if string.find(command_line, irc_nick_name) == 1 and string.find(command_line, "JOIN :") > 0 then
--        local session_slot = string.sub(command_line, string.find(command_line, "JOIN :")+7)
--        sessions[session] = session_slot
--        sessions[session+1] = 
        
--:jdoe452!guest@95-36-35-62.dsl.alice.nl JOIN :#myhhchannel
--:canis.esper.net 353 jdoe452 = #myhhchannel :jdoe452 vV
--:canis.esper.net 366 jdoe452 #myhhchannel :End of /NAMES list.
      rirc.views.status_output_frame:add_line(command_line)
      rirc.views.status_output_frame:scroll_to_last_line()
    end
  until command_line == nil
  last_idle_time = os.clock()
end


function set_nick(nick)
  local COMMAND = "NICK "..nick.."\r\n"
  print (COMMAND)
 client:send(COMMAND)
end


function register_user(user, real_name)
  local COMMAND = "USER "..user.." 8 * : "..real_name.."\r\n"
  print (COMMAND)
  client:send(COMMAND)
end


function join_channel(channel)
  local COMMAND = "JOIN "..channel.."\r\n"
  print (COMMAND)
  client:send(COMMAND)
end


function quit_irc()
  local COMMAND = "QUIT :Has left the building\r\n"
  print (COMMAND)
  client:send(COMMAND)
end


function send_command (target, target_frame, command)
  local local_echo = ''
  if command ~= nil then
    if string.find(command, "/") == 1 then
      if string.find(command, string.lower("/join")) == 1 then
        command = "JOIN "..string.sub(command, 7)
      end
      if string.find(command, string.lower("/part")) == 1 then
        command = "PART "..string.sub(command, 7)
      end
      if string.find(command, string.lower("/nick")) == 1 then
        command = "NICK "..string.sub(command, 7)
      end
      if string.find(command, string.lower("/list")) == 1 then
        command = "LIST "..string.sub(command, 7)
      end
      if string.find(command, string.lower("/names")) == 1 then
        command = "NAMES "..string.sub(command, 8)
      end
      if string.find(command, string.lower("/topic")) == 1 then
        command = "TOPIC "..string.sub(command, 8)
      end
      if string.find(command, string.lower("/invite")) == 1 then
        command = "INVITE "..string.sub(command, 9)
      end
      if string.find(command, string.lower("/stats")) == 1 then
        command = "STATS "..string.sub(command, 8)
      end
      if string.find(command, string.lower("/kick")) == 1 then
        command = "KICK "..string.sub(command, 7)
      end
      if string.find(command, string.lower("/links")) == 1 then
        command = "LINKS "..string.sub(command, 8)
      end
      if string.find(command, string.lower("/time")) == 1 then
        command = "TIME "..string.sub(command, 7)
      end
      if string.find(command, string.lower("/trace")) == 1 then
        command = "TRACE "..string.sub(command, 8)
      end
      if string.find(command, string.lower("/connect")) == 1 then
        command = "CONNECT "..string.sub(command, 10)
      end
      if string.find(command, string.lower("/admin")) == 1 then
        command = "ADMIN "..string.sub(command, 7)
      end
      if string.find(command, string.lower("/info")) == 1 then
        command = "INFO "..string.sub(command, 7)
      end
      if string.find(command, string.lower("/who")) == 1 then
        command = "WHO "..string.sub(command, 6)
      end
      if string.find(command, string.lower("/whois")) == 1 then
        command = "WHOIS "..string.sub(command, 8)
      end
      if string.find(command, string.lower("/whowas")) == 1 then
        command = "WHOWAS "..string.sub(command, 9)
      end
      if string.find(command, string.lower("/notice")) == 1 then
        command = "NOTICE "..string.sub(command, 9)
      end
      if string.find(command, string.lower("/version")) == 1 then
        command = "VERSION "..string.sub(command, 9)
      end
      if string.find(command, string.lower("/quit")) == 1 then
        command = "QUIT "..string.sub(command, 7)
      end
      if string.find(command, string.lower("/oper")) == 1 then
        command = "OPER "..string.sub(command, 7)
      end
      if string.find(command, string.lower("/mode")) == 1 then
        command = "MODE "..string.sub(command, 7)
      end
    else
      local_echo = "<"..irc_nick_name.."> "..command
      command = "PRIVMSG "..target.." :"..command
    end
    local COMMAND = command.."\r\n"
    print (COMMAND)
    if target_frame == 'status' then
      vb_status.views.status_output_frame:add_line(local_echo)
      vb_status.views.status_output_frame:scroll_to_last_line()
    else
      vb_channel.views.channel_output_frame:add_line(local_echo)
      vb_channel.views.channel_output_frame:scroll_to_last_line()
    end
    client:send(COMMAND)
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

function open_chat_session()
   session[sessions] = 'channel'..tostring(sessions)
   sessions = sessions + 1
   return (sessions - 1)
end

function close_chat_session(session_no)
  table.remove(session,session_no)
end


function connect_to_server(vb)
  client, client_error = renoise.Socket.create_client(vb.views.irc_server.text, 
  tonumber(vb.views.irc_server_port.text))
  rirc = status_dialog()
  
  if client then
    set_nick(vb.views.irc_nick_name.text)            
    register_user(vb.views.irc_user_name.text, vb.views.irc_real_name.text)
    --    client:send("PRIVMSG #channelname :"..irc_nick_name.." in da house!!\r\n")
    start_message_engine()          
   else
     if client_error then
       rirc.views.status_output_frame:add_line(client_error)
     end
   end
  
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
      "Chat connect", dialog_content
    )
  end

end


------------------------------------------------------------------------------
----------------------       Status dialog frame     -------------------------
------------------------------------------------------------------------------

function status_dialog()
  local target = 'status_'
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
          send_command(text)
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
    },
    vb:row{
      vb:button {
        width = TEXT_ROW_WIDTH,
        text = "Join #renoise community chat channel",
        notifier = function(text)
          join_channel(irc_channel)
          chat_dialog_control(irc_channel)
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
  vb_status = vb
  return vb
end

function strip_illegal_chars(target)
  string.gsub(target," ","_")

  for y = 33,47 do
    string.gsub(target,"!","")
  end
  
  return target
end
------------------------------------------------------------------------------
----------------------       Chat dialog frame       -------------------------
------------------------------------------------------------------------------

function chat_dialog_control(target)

  local vb = renoise.ViewBuilder()
  
  local DIALOG_MARGIN = renoise.ViewBuilder.DEFAULT_DIALOG_MARGIN
  local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING
  local CONTENT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
  local DEFAULT_CONTROL_HEIGHT = renoise.ViewBuilder.DEFAULT_CONTROL_HEIGHT
  local CONTROL_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
    
  local TEXT_ROW_WIDTH = 80
  local no_loop = 0
--  local session_id = open_chat_session()
  -- CONTROL ROWS
  
  -- textfield
  local chat_frame_row = vb:column{
    vb:row{    
      vb:column {
        margin = CONTROL_MARGIN,
        vb:multiline_text{
          width = 300,
          height = 300, 
          font = "mono",
          id = 'channel_output_frame',
          text = ""
        }
      },
      vb:column {
        margin = CONTROL_MARGIN,
        vb:multiline_text{
          width = 200,
          height = 300, 
          font = "mono",
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
        width = 300,
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
      vb:button {
        width = TEXT_ROW_WIDTH,
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
      target, dialog_content
    )
  end
  vb_channel = vb
end
