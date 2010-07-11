------------------------------------------------------------------------------
----------------------       Simple IRC client       -------------------------
------------------------------------------------------------------------------

require "globals"
require "gui"

renoise.tool():add_menu_entry {
  name = "Main Menu:Help:Visit the Community Chatroom...",
  invoke = function() client_login() end
}

function print_server_replies()
  local vb = renoise.ViewBuilder()
  -- Only run every 0.3 seconds
  if (os.clock() - last_idle_time < 2.0) then
    return
  end    

--If status window is closed, drop connection
--yet if status window was not raised, then drop connection upon closing
--the chat dialog. (if not switch_channel status is up)
  if (not irc_dialog or not irc_dialog.visible) and status_dialog_mode then
    stop_message_engine()
    if chat_dialog or chat_dialog.visible then
      local channel_line = os.date("%c").." [CLIENT] Disconnected from server."
      vb_channel.views.channel_output_frame:add_line(channel_line)
      vb_channel.views.channel_output_frame:scroll_to_last_line()
    end
  else
    if (not chat_dialog or not chat_dialog.visible) and 
       (not status_dialog_mode) and (not switch_channel) then
      stop_message_engine()
      return
    end
  end

  if (not chat_dialog or not chat_dialog.visible) and active_channel ~=nil then
    send_command("",'status',"/part "..active_channel)
    active_channel = nil
    return
  end

  repeat 
    if client.is_open == false then
        --We got disconnected from the other end?
        stop_message_engine()
        local EOT = "\n[[Server disconnected]]\n"
        if irc_dialog ~= nil then
          if irc_dialog.visible then
            vb_status.views.status_output_frame:add_line(EOT)
            vb_channel.views.channel_output_frame:add_line(EOT)
          end
        end
        if chat_dialog ~= nil then
          if chat_dialog.visible then
            vb_channel.views.channel_output_frame:add_line(EOT)
            vb_channel.views.channel_output_frame:scroll_to_last_line()
          end
        end
        return 
    end
    local command_line, status = client:receive("*l", 0)
    if command_line ~= nil then
      -- If a ping is received, reply immediately
      local pingpos = string.find(command_line, "PING")

      if pingpos ~= nil then
        command_line = string.gsub(command_line, "PING", "PONG").."\r\n"
        client:send(command_line)
      end

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

          if SERVER_ARRAY[t] == "332" then  -- channel topic
            local topic = ""
            for y = 5, #SERVER_ARRAY do
              topic = topic..SERVER_ARRAY[y]
            end
            if topic ~= "" then
              topic = "Current channel topic"..topic
            else
              topic = "Current channel topic not set"
            end
            vb_channel.views.channel_output_frame:add_line(topic)
            
          end

          if SERVER_ARRAY[t] == "353" then -- Names list requested, enumerate the names for the channel list.
            update_channel_users(SERVER_ARRAY)
          end
          if SERVER_ARRAY[t] == "433" then  -- nickname already in use
            if connection_status == IN_PROGRESS then
              stop_message_engine()
              if connect_progress_dialog ~= nil then
                connect_progress_dialog:close()
              end
              local err_msg = vb:text {
                      
                      text = "     Nickname "..irc_nick_name.." already in use"
                    }
              local buttons = {"change", "exit"}
              local choice = renoise.app():show_custom_prompt("IRC error", err_msg,buttons)
               if choice == "change" then
                 client_login()
               end
             else
               if irc_dialog == nil and chat_dialog ~= nil then
                 local channel_line = os.date("%c").." [SERVER] nick "..irc_nick_name.." already in use"
                 vb_channel.views.channel_output_frame:add_line(channel_line)
                 vb_channel.views.channel_output_frame:scroll_to_last_line()
               end
             end
          end
          if SERVER_ARRAY[t] == "473" then  -- channel is invite only
            if connection_status == IN_PROGRESS then
              stop_message_engine()
              if connect_progress_dialog ~= nil then
                connect_progress_dialog:close()
              end
              local err_msg = vb:text {
                      
                      text = "     channel "..irc_channel.." is invite only"
                    }
              local buttons = {"change", "exit"}
              local choice = renoise.app():show_custom_prompt("IRC error", err_msg,buttons)
               if choice == "change" then
                 client_login()
               end
             else
               if irc_dialog == nil and chat_dialog ~= nil then
                 local channel_line = os.date("%c").." [SERVER] channel "..active_channel.." is invite only"
                 vb_channel.views.channel_output_frame:add_line(channel_line)
                 vb_channel.views.channel_output_frame:scroll_to_last_line()
               end
             end

          end
          if SERVER_ARRAY[t] == "376" then  -- End of MOTD, auto-join the channel
            active_channel = irc_channel
            if connect_progress_dialog ~= nil then
              connect_progress_dialog:close()
              connect_progress_dialog = nil
              connection_status = CONNECTED
            end

            chat_dialog_control(irc_channel)          
            join_channel(irc_channel)
            if irc_dialog ~= nil then
              vb_status.views.status_dialog_content.visible = false
              vb_status.views.minimizer.text = "Maximize"
              vb_status.views.sdf:resize()
            end
          end
          if SERVER_ARRAY[t] == "PRIVMSG" then
            if vb_channel == nil then
              return --Do not attempt to send private messages to non-existing 
                     --channel frames
            end
            local user_say = string.sub(command_line,2,string.find(SERVER_ARRAY[1],"!")-1)
            local msg_cmd_pos = string.find(command_line,"PRIVMSG")+8
            local msg_start = string.find(command_line,":",msg_cmd_pos)
            local say_channel = SERVER_ARRAY[3]
            local say_text = string.sub(command_line,msg_start+1)
            local channel_line = ""
            if say_channel == active_channel then
              channel_line = os.date("%c").." <"..user_say.."> "..say_text
            else
              channel_line = os.date("%c").." ("..user_say.." -> "..irc_nick_name..") "..say_text
            end
            if string.find(say_text, "ACTION") == 2 then
              say_text = string.sub(say_text,8, #say_text-1)
              channel_line = os.date("%c").." "..user_say..say_text
            end

            vb_channel.views.channel_output_frame:add_line(channel_line)
            vb_channel.views.channel_output_frame:scroll_to_last_line()
          end
        end
      end



      if sirc_debug then
        print (command_line)
      end
      
      if irc_dialog ~= nil then
        if irc_dialog.visible then
          command_line = os.date("%c")..command_line
          vb_status.views.status_output_frame:add_line(command_line)
          vb_status.views.status_output_frame:scroll_to_last_line()
        end
      end
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
  if client.is_open then
   client:send(COMMAND)
  end
end


function register_user(user, real_name)
  local COMMAND = "USER "..user.." 8 * : "..real_name.."\r\n"
  if sirc_debug then
    print (COMMAND)
  end
  if client.is_open then
    client:send(COMMAND)
  end
end


function join_channel(channel)
  local COMMAND = "JOIN "..channel.."\r\n"
  if sirc_debug then
    print (COMMAND)
  end
  if client.is_open then
    client:send(COMMAND)
  end
end


function quit_irc()
  local COMMAND = "QUIT :Has left the building\r\n"
  if sirc_debug then
    print (COMMAND)
  end
  if client.is_open then
    client:send(COMMAND)
  end
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
      if #new_nick > 1 then
        irc_nick_name = new_nick[2]
      end
    end

    if string.find(command,"PRIVMSG") == 1 then
      local priv_msg = command:split("[^,%s]+")
      if #priv_msg > 1 then
        command = priv_msg[1].." "..priv_msg[2].." :"
        for t = 3, #priv_msg do
          command = command ..priv_msg[t].." "
        end
      end
    end

    if string.find(command,"TOPIC") == 1 then -- Get / set local topic description
      local topic_subject = command:split("[^,%s]+")
        if #topic_subject == 1 then
          command = command.." "..active_channel
        end
    end
    
    if string.find(command,"JOIN") == 1 then
      local new_channel = command:split("[^,%s]+")
      if #new_channel > 1 then
        if chat_dialog and chat_dialog.visible == true and active_channel ~= nil then
          send_command('','status', "/part "..active_channel)
        end
        if sirc_debug then
          print ("Joining "..new_channel[2])
        end
        chat_dialog_control(new_channel[2])          
      end
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
            switch_channel = true --And take care the connection is *not* closed!
            chat_dialog:close()
          end

         else 

           if sirc_debug then
             print ("channel is nil")
           end

        end
      end
    end

    if found == false then
      local_echo = os.date("%c").." <"..irc_nick_name.."> "..command

      if string.find(command, "/me ") ~= nil then
        local_echo = os.date("%c ")..irc_nick_name.." "..string.sub(command, 5)
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
      if irc_dialog ~= nil then
        if irc_dialog.visible then
          vb_status.views.status_output_frame:add_line(local_echo)
          vb_status.views.status_output_frame:scroll_to_last_line()
        end
      end
    else
      if chat_dialog ~= nil then
        if chat_dialog.visible then
          vb_channel.views.channel_output_frame:add_line(local_echo)
          vb_channel.views.channel_output_frame:scroll_to_last_line()
        end
      end
    end

    if client.is_open then
      client:send(COMMAND)
    else
        --We got disconnected from the other end?
        stop_message_engine()
        local EOT = "Server disconnected ->"..command
        if irc_dialog ~= nil then
          if irc_dialog.visible then
            vb_status.views.status_output_frame:add_line(EOT)
            vb_channel.views.channel_output_frame:add_line(EOT)
          end
        end
        if chat_dialog ~= nil then
          if chat_dialog.visible then
            vb_channel.views.channel_output_frame:add_line(EOT)
            vb_channel.views.channel_output_frame:scroll_to_last_line()
          end
        end
        return    
    end

    if string.find(command,"QUIT") == 1 then
        --Silently leave the arena when server returns a quit reply.
        stop_message_engine()
        local EOT = "Server disconnected ->"..command
        if irc_dialog ~= nil then
          if irc_dialog.visible then
            vb_status.views.status_output_frame:add_line(EOT)
            vb_channel.views.channel_output_frame:add_line(EOT)
          end
        end
        if chat_dialog ~= nil then
          if chat_dialog.visible then
            vb_channel.views.channel_output_frame:add_line(EOT)
            vb_channel.views.channel_output_frame:scroll_to_last_line()
          end
        end
        return
    end

  end
end

    
function status_key_handler(dialog, mod, key)
  -- update key_text to show what we got
  -- close on escape...
  if (mod == "" and key == "esc") then
    dialog:close()
    return
  end
  -- Let's send the text-line contents if present
  if (mod == "" and key == "return") then
    send_command('', 'status', vb_status.views.status_command.text)
    vb_status.views.status_command.value = ""
    return 
  end
 
end

function chat_key_handler(dialog, mod, key)
  -- update key_text to show what we got
  -- close on escape...
  if (key == "esc") then
    dialog:close()
  end
  -- Let's send the text-line contents if present
  if (key == "return") then
    send_command(active_channel, 'channel', vb_channel.views.channel_command.text)
    no_loop = 1 -- Prevent triggering the notifier again 
                -- simply because the value got cleared
                -- else a new empty command would be send again.
    vb_channel.views.channel_command.value = ""
    global_channel_command = ""
    return
  end

  if (key == "back") then
    no_loop = 1 -- Prevent triggering the notifier again 
    global_channel_command = string.sub(global_channel_command,1,
    string.len(global_channel_command)-1)
    vb_channel.views.channel_command.value = global_channel_command
    return
  end

  if (key == "space") then
    no_loop = 1 -- Prevent triggering the notifier again 
    vb_channel.views.channel_command.value = vb_channel.views.channel_command.value.." "
    global_channel_command = global_channel_command.." "
    return
  end

  if (key == "rshift"or key =="rcontrol" or key == "ralt" or key == "tab") then
    return
  end

  --Here we are going to pump characters into the chatline even 
  --if the chatline does not has keyboard focus.
  --A way to circumvent the lack of focus functionality
  --Not the best way, but better than clicking the text-field
  --each time.
  if (mod ~= "control" and mod ~= "alt" and key ~="lshift") then
    no_loop = 1

    if sirc_debug then
      print ("mod:"..mod.." key:"..key)
    end
    
    if (mod == "shift") then
      -- This part sucks a bit as it is default US-english
      -- layout. So you will have to adapt it to your 
      -- own national layout to make these matches fit correctly.
      -- Another thing is that rshift etc aren't specified as MOD
      -- So you can't use those.
      if key=="^" then key = "~" end
      if key=="1" then key = "!" end
      if key=="2" then key = "@" end
      if key=="3" then key = "#" end
      if key=="4" then key = "$" end
      if key=="5" then key = "%" end
      if key=="6" then key = "^" end
      if key=="7" then key = "&" end
      if key=="8" then key = "*" end
      if key=="9" then key = "(" end
      if key=="0" then key = ")" end
      if key=="/" then key = "?" end
      if key=="comma" then key = "<" end
      if key=="period" then key = ">" end
      if key==";" then key = ":" end
      if key=="'" then key = "\"" end
      if key=="[" then key = "{" end
      if key=="]" then key = "}" end
      if key=="-" then key = "_" end
      if key=="=" then key = "+" end
      if key=="a" then key = "A" end
      if key=="b" then key = "B" end
      if key=="c" then key = "C" end
      if key=="d" then key = "D" end
      if key=="e" then key = "E" end
      if key=="f" then key = "F" end
      if key=="g" then key = "G" end
      if key=="h" then key = "H" end
      if key=="i" then key = "I" end
      if key=="j" then key = "J" end
      if key=="k" then key = "K" end
      if key=="l" then key = "L" end
      if key=="m" then key = "M" end
      if key=="n" then key = "N" end
      if key=="o" then key = "O" end
      if key=="p" then key = "P" end
      if key=="q" then key = "Q" end
      if key=="r" then key = "R" end
      if key=="s" then key = "S" end
      if key=="t" then key = "T" end
      if key=="u" then key = "U" end
      if key=="v" then key = "V" end
      if key=="w" then key = "W" end
      if key=="x" then key = "X" end
      if key=="y" then key = "Y" end
      if key=="z" then key = "Z" end
    end
    if key=="comma" then key = "," end
    if key=="period" then key = "." end
--Strange, the inversed apostrophe and tilde are being send as a "^" key?
    if key=="^" then key = "`" end

    vb_channel.views.channel_command.value = vb_channel.views.channel_command.value..key
    global_channel_command = global_channel_command..key
  end
    
end

function login_key_handler(dialog, mod, key)
  -- update key_text to show what we got
  -- close on escape...
  if (mod == "" and key == "esc") then
    dialog:close()
  end
  if (mod == "" and key == "return") then
    connect_to_server()
    login_dialog:close()
  end
end

function connect_key_handler(dialog, mod, key)
  -- update key_text to show what we got
  -- close on escape...
  if (mod == "" and key == "esc") then
    dialog:close()
    stop_message_engine()
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
  if sirc_debug then
    print ("Disconnecting from server")
  end
  if (renoise.tool().app_idle_observable:has_notifier(print_server_replies)) then
    connection_status = DISCONNECTED
    renoise.tool().app_idle_observable:remove_notifier(print_server_replies)
    quit_irc()
  end
end


function connect_to_server(vb)
  client, client_error = renoise.Socket.create_client(vb_login.views.irc_server.text, 
  tonumber(vb_login.views.irc_server_port.text))
  connection_status = IN_PROGRESS
  switch_channel = true
  if status_dialog_mode then --Show status window when checkbox checked
    status_dialog()
  else
    progress_dialog()
  end

  if client.is_open then
    set_nick(vb_login.views.irc_nick_name.text)            
    register_user(vb_login.views.irc_user_name.text, vb_login.views.irc_real_name.text)
    --    client:send("PRIVMSG #channelname :"..irc_nick_name.." in da house!!\r\n")
    start_message_engine()          
   else
     if client_error then
       if irc_dialog ~= nil then
         vb_status.views.status_output_frame:add_line(client_error)
       else
         if connect_progress_dialog ~= nil then
           connect_progress_dialog:close()
         end
         local err_msg = "Could not connect to chat-server reason: ["..client_error.."]\n\nPlease check your network connection and try again "
         local choice = renoise.app():show_prompt("Network error",err_msg,{'close'})

       end
     end
   end
  
end

