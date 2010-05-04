-[[----------------------------------------------------------------------------
-- renoise.Socket
---------------------------------------------------------------------------]]--

error("do not run this file. read and copy/paste from it only...")


-- HTTP / GET client

-- create a TCP socket and connect it to www.wurst.com, http
local client, socket_error = renoise.Socket.create_client(
  "www.wurst.com", 80, renoise.Socket.PROTOCOL_TCP)
   
if socket_error then 
 renoise.app():show_warning(socket_error)
 return
end

-- request something
local succeeded, socket_error = 
  client:send("GET / HTTP/1.0\n\n")

if socket_error then 
 renoise.app():show_warning(socket_error)
 return
end

-- receive something and show what we got
local receive_timeout = 500

local message, socket_error = 
  client:receive(receive_timeout)

if socket_error then 
 renoise.app():show_warning(socket_error)
else
 renoise.app():show_prompt(
   "GET / HTTP/1.0 response", 
   message, 
   {"OK"}
 )
end


-------------------------------------------------------------------------------
-- echo udp server (using a table as notifier):

local server, socket_error = renoise.Socket.create_server(
  "localhost", 1025, renoise.Socket.PROTOCOL_UDP)
   
if socket_error then 
  app:show_warning(
     "Failed to start the echo server: " .. socket_error)
else
  server:run {
    socket_error = function(socket_error)
      renoise.app():show_warning(socket_error)
    end,
    
    socket_accepted = function(socket)
      print(("client %s:%d connected"):format(
        socket.peer_address, socket.peer_port))
    end,
  
    socket_message = function(socket, message)
      print(("client %s:%d sent '%s'"):format(
        socket.peer_address, socket.peer_port,  message))
      -- simply sent the message back      
      socket:send(message)
    end    
  }
end

-- will run and echo as long as the script runs...


-------------------------------------------------------------------------------
-- echo TCP server (using a class as notifier):

class "EchoServer"
  function EchoServer:__init(port)
   -- create a server socket
   local server, socket_error = 
     renoise.Socket.create_server("localhost", port)
     
   if socket_error then 
     app:show_warning(
       "Failed to start the echo server: " .. socket_error)
   else
     -- start running
     self.server = server
     self.server:run(self)
   end
  end

  function EchoServer:socket_error(socket_error)
    renoise.app():show_warning(socket_error)
  end
  
  function EchoServer:socket_accepted(socket)
    print(("client %s:%d connected"):format(
      socket.peer_address, socket.peer_port))
  end

  function EchoServer:socket_message(socket, message)
    print(("client %s:%d sent '%s'"):format(
      socket.peer_address, socket.peer_port,  message))
    -- simply sent the message back      
    socket:send(message)
  end
  
-- create and run the echo server on port 1025
local echo_server = EchoServer(1025)

-- will run and echo as long as the script runs or the EchoServer 
-- object is garbage collected...


--[[---------------------------------------------------------------------------
---------------------------------------------------------------------------]]--

