--[[--------------------------------------------------------------------------
TestDocument.lua
--------------------------------------------------------------------------]]--

do

  ----------------------------------------------------------------------------
  -- tools
  
  local function assert_error(statement)
    assert(pcall(statement) == false, "expected function socket_error")
  end
  
  
  ----------------------------------------------------------------------------
  -- client
  
  local receive_timeout = 500
    
  -- TCP GET / HTTP
  for _,protocol in pairs{renoise.Socket.PROTOCOL_TCP} do
    -- bogus URL and port must fail
    local client, socket_error = renoise.Socket.create_client(
      "www.googleqwe.com", 66, protocol)
    assert(not client and socket_error)
    
    -- valid URL should not fail
    client, socket_error = renoise.Socket.create_client(
      "www.google.com", 80, protocol)
    assert(client and not socket_error)
    
    -- bogus receives
    assert_error(function()
      client:receive("*nothing", receive_timeout)
    end)
    assert_error(function()
      client:receive(0, receive_timeout)
    end)
    assert_error(function()
      client:receive({}, receive_timeout)
    end)

    -- nothing requested, nothing send
    message, socket_error = client:receive("*all", receive_timeout)
    assert(not message and socket_error)
    
    -- send page request
    succeeded, socket_error = client:send("GET / HTTP/1.0\n\n")
    assert(succeeded and not socket_error)
    
    -- get page request
    local message, socket_error = client:receive(1024, receive_timeout)
    assert(message and not socket_error)
    
    -- status checks
    assert(client.is_open)
    assert(client.local_port ~= 80)
    assert(client.local_address ~= "")
    
    assert(client.peer_port == 80)
    assert(client.peer_address ~= "")
    
    -- nothing pending, nothing received
    message, socket_error = client:receive("*all", receive_timeout)
    assert(not message and socket_error)
    
    -- closed on error
    assert(not client.is_open)  
    
    -- closed socket behavior 
    assert_error(function()
      client:send("something")
    end)
     assert_error(function()
      client:receive("*all", receive_timeout)
    end)
  end 
  
  
  ----------------------------------------------------------------------------
  -- server / client
  
  class "NotificationClass"
    function NotificationClass:__init(server)
      self.server = server
    end
  
    function NotificationClass:socket_error(error_message)
      error("server error: ", error_message)
    end
    
    function NotificationClass:socket_accepted(socket)
      print(("client %s:%d connected"):format(
        socket.peer_address, socket.peer_port))
    end
  
    function NotificationClass:socket_message(socket, message)
      print(("client %s:%d sent '%s'"):format(
        socket.peer_address, socket.peer_port, message))
              
      local succeeded, socket_error = socket:send("Hello Client!\r")
      assert(succeeded, socket_error)
    end
  
  notification_table = {
    socket_error = function(error_message)
      error("server error: ", error_message)
    end,
  
    socket_message = function(socket, message)
      print(("client %s:%d sent '%s'"):format(
        socket.peer_address, socket.peer_port, message))
              
      local succeeded, socket_error = socket:send("Hello Client!\r\n")
      assert(succeeded, socket_error)
    end
  }
    
  -- test everything for UDP and TCP
  
  for _,protocol in pairs{renoise.Socket.PROTOCOL_TCP, renoise.Socket.PROTOCOL_UDP} do
    local server_port = 1024
    
    -- create a server
    local server, socket_error = 
      renoise.Socket.create_server(server_port, protocol)
    assert(server, socket_error)
    
    -- test class and table notifications
    if (protocol == renoise.Socket.PROTOCOL_TCP) then
      server:run(NotificationClass(server))
    else
      server:run(notification_table)
    end
    
    -- create a client  
    local client1, socket_error = renoise.Socket.create_client(
      "localhost", server_port, protocol)
    assert(client1, socket_error)
    
    local client2, socket_error = renoise.Socket.create_client(
      "localhost", server_port, protocol)
    assert(client2, socket_error)
    
      
    -- send a message to the server
    client1:send(("Hello Server from %s:%d"):format(
      client1.local_address, client1.local_port))
   
    client2:send(("Hello Server from %s:%d"):format(
      client2.local_address, client2.local_port))
      
    -- wait a bit till its received
    server:wait(receive_timeout)    
    
    -- and print the response from the server
    message1, message_error1 = client1:receive("*line", receive_timeout)
    assert(message1, message_error1)
    
    print(("client %s:%d got '%s' from server %s:%d"):format(
      client1.local_address, client1.local_port,  
      message1, client1.peer_address, client1.peer_port))
      
    message2, message_error2 = client2:receive("*line", receive_timeout)
    assert(message2, message_error2)
    
    print(("client %s:%d got '%s' from server %s:%d"):format(
      client2.local_address, client2.local_port,  
      message2, client2.peer_address, client2.peer_port))
       
    -- shut off and repeat
    server:close()
  end

end
  
  
------------------------------------------------------------------------------
-- test finalizers

collectgarbage()

  
--[[--------------------------------------------------------------------------
--------------------------------------------------------------------------]]--

