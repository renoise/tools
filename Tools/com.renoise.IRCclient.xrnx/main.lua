------------------------------------------------------------------------------
----------------------       Simple IRC client       -------------------------
------------------------------------------------------------------------------

require "globals"
require "gui"

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

  if (not chat_dialog or not chat_dialog.visible) and active_channel ~=nil then
    send_command("",'status',"/part "..active_channel)
    active_channel = nil
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
      local SERVER_ARRAY = command_line:split( "[^,%s]+" )
      for t = 1, #SERVER_ARRAY do
        if sirc_debug then 
          print ("Word "..t..":"..SERVER_ARRAY[t])
        end
        if t == 2 then
          if SERVER_ARRAY[t] == "PART" or SERVER_ARRAY[t] == "JOIN" 
          or SERVER_ARRAY[t] == "QUIT" or SERVER_ARRAY[t] == "NICK" then 
            -- Any changes in the user-list?
            if active_channel ~= nil then
              send_command(SERVER_ARRAY[3],'status', "/names "..active_channel)
            end
          end 
          if SERVER_ARRAY[t] == "353" then -- Names list requested, enumerate the names for the channel list.
            update_channel_users(SERVER_ARRAY)
          end
          if SERVER_ARRAY[t] == "376" then  -- End of MOTD, auto-join the channel
            active_channel = irc_channel
            join_channel(irc_channel)
            chat_dialog_control(irc_channel)          
          end
        end
      end
      if quit_reply ~= nil then
        --Silently leave the arena when server returns a quit reply.
        stop_message_engine()
        local EOT = "Server disconnected ->"..command_line
        vb_status.views.status_output_frame:add_line(EOT)
        vb_channel.views.channel_output_frame:add_line(EOT)
        return
      end

      if sirc_debug then
        print (command_line)
      end
      
      if string.find(command_line, irc_nick_name) ~= 1 and string.find(command_line, " PRIVMSG ") ~= nil then
        if vb_channel == nil then
          return --Do not attempt to send private messages to non-existing 
                 --channel frames
        end
        local msg_type = string.find(command_line,"PRIVMSG")+8
        local msg_start = string.find(command_line,":",msg_type)
        local user_say = string.sub(command_line,2,string.find(command_line,"!")-1)
        local say_channel = string.sub(command_line,msg_type, msg_start-1)
        local say_text = string.sub(command_line,msg_start+1)
        local channel_line = "<"..user_say.."> "..say_text
        if string.find(say_text, "ACTION") == 2 then
          say_text = string.sub(say_text,8, #say_text-1)
          channel_line = user_say..say_text
        end

        vb_channel.views.channel_output_frame:add_line(channel_line)
        vb_channel.views.channel_output_frame:scroll_to_last_line()
      end

      rirc.views.status_output_frame:add_line(command_line)
      rirc.views.status_output_frame:scroll_to_last_line()
    end
  until command_line == nil
  last_idle_time = os.clock()
end


function update_channel_users(SERVER_ARRAY)
  local u_channel = SERVER_ARRAY[4]
  vb_channel.views.channel_user_frame:clear()
  for b = 1, (#SERVER_ARRAY-5) do
    if string.find(SERVER_ARRAY[b+5],":") == 1 then
      SERVER_ARRAY[b+5] = string.sub(SERVER_ARRAY[b+5],2)
    end
    vb_channel.views.channel_user_frame:add_line(SERVER_ARRAY[b+5])
  end
end


function set_nick(nick)
  local COMMAND = "NICK "..nick.."\r\n"
  if sirc_debug then
    print (COMMAND)
  end
 client:send(COMMAND)
end


function register_user(user, real_name)
  local COMMAND = "USER "..user.." 8 * : "..real_name.."\r\n"
  if sirc_debug then
    print (COMMAND)
  end
  client:send(COMMAND)
end


function join_channel(channel)
  local COMMAND = "JOIN "..channel.."\r\n"
  if sirc_debug then
    print (COMMAND)
  end
  client:send(COMMAND)
end


function quit_irc()
  local COMMAND = "QUIT :Has left the building\r\n"
  if sirc_debug then
    print (COMMAND)
  end
  client:send(COMMAND)
end


function send_command (target, target_frame, command)
  local local_echo = ''
  local found = false
  if command ~= nil then

    -- replace /command with COMMAND
    for _,known_command in pairs(known_commands) do
     if (command:lower():find("/" .. known_command:lower()) == 1) then
       command = known_command:upper() .. command:sub(#known_command + 2)
       found = true
       break
     end
    end
    if string.find(command,"NICK") == 1 then
      local new_nick = command:split("[^,%s]+")
        irc_nick_name = new_nick[2]
    end
    
    if string.find(command,"JOIN") == 1 then
      local new_channel = command:split("[^,%s]+")
      if chat_dialog and chat_dialog.visible == true and active_channel ~= nil then
        send_command('','status', "/part "..active_channel)
      end
      print ("Joining "..new_channel[2])
      chat_dialog_control(new_channel[2])          
    end
    if string.find(command,"PART") == 1 then
      local new_channel = command:split("[^,%s]+")
      if chat_dialog and chat_dialog.visible == true then
        if new_channel ~= nil then
          if #new_channel == 1 and active_channel ~= nil then --If only /part is given, then quit current channel
            new_channel[2] = active_channel
          end
          if new_channel[2] == active_channel then 
            -- Make sure we are closing the dialog that is matching the active channel
            chat_dialog:close()
          end
         else 
           print ("channel is nil")
        end
      end
    end
    if found == false then
      local_echo = "<"..irc_nick_name.."> "..command
      if string.find(command, "/me ") ~= nil then
        local_echo = irc_nick_name.." "..string.sub(command, 5)
        command = string.gsub(command,"/me ", "ACTION ")
        command = command..""
      end
      command = "PRIVMSG "..target.." :"..command
    end

    local COMMAND = command.."\r\n"

    if sirc_debug then
      print (COMMAND)
    end
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

    
function key_handler(dialog, mod, key)
  -- update key_text to show what we got
  -- close on escape...
  if (mod == "" and key == "esc") then
    dialog:close()
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

