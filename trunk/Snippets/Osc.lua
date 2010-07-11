--[[---------------------------------------------------------------------------
-- renoise.Osc
---------------------------------------------------------------------------]]--

error("do not run this file. read and copy/paste from it only...")


-------------------------------------------------------------------------------
---- Osc server (receive Osc from one or more clients)

-- open a socket connection to the server
local server, socket_error = renoise.Socket.create_server(
  "localhost", 8008, renoise.Socket.PROTOCOL_UDP)
   
if (socket_error) then 
  app:show_warning(("Failed to start the " .. 
    "OSC server: '%s'"):format(socket_error))
  return
end

server:run {
  socket_message = function(socket, data)
    local message_or_bundle, osc_error = 
      renoise.Osc.from_binary_data(data)
    
    if (message_or_bundle) then
      if (type(message_or_bundle) == "Message") then
        print(("Got OSC message: '%s'"):format(
          tostring(message_or_bundle)))

      elseif (type(message_or_bundle) == "Bundle") then
        print(("Got OSC bundle: '%s'"):format(
          tostring(message_or_bundle)))
      
      else
        -- never will get in here
      end
      
    else
      print(("Got an invalid or some data which is not an " ..
        "OSC message at all. error: '%s'"):format(osc_error))
    end
  end    
}


-------------------------------------------------------------------------------
-- Osc client & message construction (send Osc to a server)

-- open a socket connection to the server
local client, socket_error = renoise.Socket.create_client(
  "localhost", 8008, renoise.Socket.PROTOCOL_UDP)
   
if socket_error then 
  app:show_warning(("Failed to start the " .. 
    "OSC client: '%s'"):format(socket_error))
  return
end

-- create some handy shortcuts
local OscMessage = renoise.Osc.Message
local OscBundle = renoise.Osc.Bundle

-- construct and send messages
local message = OscMessage("/someone/transport/start")

client:send(message)

message = OscMessage("/someone/transport/bpm", {
  {tag="f", value=127.5}
})

client:send(message)

-- construct and send bundles
local bundle = OscBundle(os.clock(), 
  OscMessage("/someone/transport/start"))
  
client:send(bundle)

bundle = OscBundle(os.clock(), {message, message})
client:send(bundle)


--[[---------------------------------------------------------------------------
---------------------------------------------------------------------------]]--
