--[[============================================================================
-- xLib.xOscDevice
============================================================================]]--

--[[--

xOscDevice represents a networked location which is able to send and/or
receive OSC messages
.
#

The class defines certain methods, according to the Renoise Socket API:
socket_error(),socket_message()

### How to use 

Create an instance and supply any of these arguments:

  xOscDevice{
    active
    name
    prefix
    address
    port_in
    port_out
    callback
    bundling_enabled
    bundle_limit
  }


--]]

--==============================================================================

require (_clibroot.."cDocument")

class 'xOscDevice' (cDocument)

-- exportable properties (cDocument)
xOscDevice.DOC_PROPS = {
  active = "boolean",
  name = "string",
  prefix = "string",
  address = "string",
  port_in = "number",
  port_out = "number",
}

xOscDevice.DEFAULT_DEVICE_NAME = "Untitled device"

--------------------------------------------------------------------------------
-- [Constructor] supply a table to initialize the class 

function xOscDevice:__init(...)

	local args = cLib.unpack_args(...) 

  --- string, the state of the device
  self.active = property(self.get_active,self.set_active)
  self.active_observable = renoise.Document.ObservableBoolean(args.active or false)

  --- string, the device name (for display purposes)
  self.name = property(self.get_name,self.set_name)
  self.name_observable = renoise.Document.ObservableString(args.name or "")

  --- string, the 'prefix' part 
  -- when defined, only messages which begin with the prefix are matched
  -- also, the prefix is appended to any outgoing messages
  self.prefix = property(self.get_prefix,self.set_prefix)
  self.prefix_observable = renoise.Document.ObservableString(args.prefix or "")

  --- string, the 'address' part (IP or hostname)
  self.address = property(self.get_address,self.set_address)
  self.address_observable = renoise.Document.ObservableString(args.address or "")

  --- integer, the input port 
  self.port_in = property(self.get_port_in,self.set_port_in)
  self.port_in_observable = renoise.Document.ObservableNumber(args.port_in or 0)

  --- integer, the output port
  self.port_out = property(self.get_port_out,self.set_port_out)
  self.port_out_observable = renoise.Document.ObservableNumber(args.port_out or 0)

  --- function, where to pass received messages
  -- @param renoise.Osc.Message
  -- @param pattern (without prefix)
  self.callback = property(self.get_callback,self.set_callback)
  self._callback = args.callback 

  --- boolean, when true we queue messages and send them on idle time 
  self.bundling_enabled = property(self.get_bundling_enabled,self.set_bundling_enabled)
  self.bundling_enabled_observable = renoise.Document.ObservableBoolean(args.bundling_enabled or false)

  --- int, output when reaching this number of queued messages (0 = disable)
  self.bundle_limit = property(self.get_bundle_limit,self.set_bundle_limit)
  self.bundle_limit_observable = renoise.Document.ObservableNumber(args.bundle_limit or 0)

  --- set when properties have changed which require re-initialize
  self.modified_observable = renoise.Document.ObservableBang()

  -- private --

  --- function
  self.idle_notifier = nil

  --- table, used when bundling is enabled
  self.message_queue = {}

  --- (renoise.Socket.SocketClient)
  self.client = nil

  --- (renoise.Socket.SocketServer)
  self.server = nil

  -- initialize --

  renoise.tool().app_idle_observable:add_notifier(function()
    self:on_idle()
  end)

  --self:on_idle()


end

--==============================================================================
-- Getter/Setter Methods
--==============================================================================
-- get/set the device name

function xOscDevice:get_active()
  return self.active_observable.value
end

function xOscDevice:set_active(val)
  assert(type(val) == "boolean","Expected active to be a boolean")
  local modified = (val ~= self.active_observable.value)
  self.active_observable.value = val
  if modified then
    if not val then
      self:close()
    else
      --self:initialize()
      self._initialize_requested = true
    end
    self.modified_observable:bang()
  end
end

--------------------------------------------------------------------------------

function xOscDevice:get_name()
  return self.name_observable.value
end

function xOscDevice:set_name(val)
  assert(type(val) == "string","Expected name to be a string")
  local modified = (val ~= self.name_observable.value)
  self.name_observable.value = val
  if modified then
    self.modified_observable:bang()
  end
end

--------------------------------------------------------------------------------

function xOscDevice:get_prefix()
  return self.prefix_observable.value
end

function xOscDevice:set_prefix(val)
  assert(type(val) == "string","Expected prefix to be a string")
  local modified = (val ~= self.prefix_observable.value)
  self.prefix_observable.value = val
  if modified then
    self.modified_observable:bang()
  end

end

--------------------------------------------------------------------------------

function xOscDevice:get_address()
  return self.address_observable.value
end

function xOscDevice:set_address(val)
  assert(type(val) == "string","Expected address to be a string")
  local modified = (val ~= self.address_observable.value)
  self.address_observable.value = val
  if modified then
    --self:initialize()
    self._initialize_requested = true
    self.modified_observable:bang()
  end

end

--------------------------------------------------------------------------------

function xOscDevice:get_port_in()
  return self.port_in_observable.value
end

function xOscDevice:set_port_in(val)
  assert(type(val) == "number","Expected port_in to be a number")

  if (val > xLib.MAX_OSC_PORT) or (val < xLib.MIN_OSC_PORT) then
    local msg = "Cannot set to a port number outside this range: %d-%d"
    error(msg:format(xLib.MAX_OSC_PORT,xLib.MIN_OSC_PORT))
  end    
  
  local modified = (val ~= self.port_in_observable.value)
  self.port_in_observable.value = val
  if modified then
    --self:initialize()
    self._initialize_requested = true
    self.modified_observable:bang()
  end
end

--------------------------------------------------------------------------------

function xOscDevice:get_port_out()
  return self.port_out_observable.value
end

function xOscDevice:set_port_out(val)
  assert(type(val) == "number","Expected port_out to be a number")

  if (val > xLib.MAX_OSC_PORT) or (val < xLib.MIN_OSC_PORT) then
    local msg = "Cannot set to a port number outside this range: %d-%d"
    error(msg:format(xLib.MAX_OSC_PORT,xLib.MIN_OSC_PORT))
  end    
  
  local modified = (val ~= self.port_out_observable.value)
  self.port_out_observable.value = val
  if modified then
    --self:initialize()
    self._initialize_requested = true
    self.modified_observable:bang()
  end

end

--------------------------------------------------------------------------------

function xOscDevice:get_callback()
  return self._callback
end

function xOscDevice:set_callback(val)
  assert(type(val) == "function","Expected callback to be a function")
  self._callback = val

end

--------------------------------------------------------------------------------

function xOscDevice:get_bundling_enabled()
  return self.bundling_enabled_observable.value
end

function xOscDevice:set_bundling_enabled(val)
  assert(type(val) == "boolean","Expected bundling_enabled to be a boolean")
  self.bundling_enabled_observable.value = val
end

--------------------------------------------------------------------------------

function xOscDevice:get_bundle_limit()
  return self.bundle_limit_observable.value
end

function xOscDevice:set_bundle_limit(val)
  assert(type(val) == "number","Expected bundle_limit to be a number")
  self.bundle_limit_observable.value = val
end

--==============================================================================
-- Class Methods
--==============================================================================

function xOscDevice:open()

  if self.active then
    self:close()
  end

  assert(((not self.client) or (not self.server)), 
    "Internal Error. Please report: " .. 
    "trying to start an OSC service which is already active")

  -- open a client connection (send to device)
  local client, socket_error = renoise.Socket.create_client(
    self.address, self.port_out, renoise.Socket.PROTOCOL_UDP)
  if (socket_error) then 
    renoise.app():show_warning(("Failed to start the " .. 
      "OSC client for device '%s'. Error: '%s'"):format(
      self.name, socket_error))
      
    self.client = nil
    return 

  else
    self.client = client
  end

  -- open a server connection (receive from device)
  local server, socket_error = renoise.Socket.create_server(
    self.port_in, renoise.Socket.PROTOCOL_UDP)
  if (socket_error) then 
    renoise.app():show_warning(("Failed to start the " .. 
      "OSC server for device '%s'. Error: '%s'"):format(
      self.name, socket_error))

    self.server = nil
    return 
  
  else
    self.server = server
    self.server:run(self)
  end
    
  --self:set_device_prefix(self.prefix)  

end

--------------------------------------------------------------------------------

function xOscDevice:close()

  if (self.client) and (self.client.is_open) then
    self.client:close()
    self.client = nil
  end

  if (self.server) and (self.server.is_open) then
    if (self.server.is_running) then
      self.server:stop()
    end
    self.server:close()
    self.server = nil
  end

end

--------------------------------------------------------------------------------
--- Recursively unpacks all OSC messages from the given bundle or message. 
-- when message_or_bundle is a single message, only this one will be added
-- to the given message list
-- @param message_or_bundle (renoise.Osc.Message or renoise.Osc.Bundle) 
-- @param messages (table) table to insert unpacked messages into

function xOscDevice:_unpack_messages(message_or_bundle, messages)
   
  if (type(message_or_bundle) == "Message") then
    messages:insert(message_or_bundle)

  elseif (type(message_or_bundle) == "Bundle") then
    for _,element in pairs(message_or_bundle.elements) do
      -- bundles may contain messages or other bundles
      self:_unpack_messages(element, messages)
    end

  else
    error("Internal Error: unexpected argument for unpack_messages: "..
      "expected an osc bundle or message")
  end
   
end


--------------------------------------------------------------------------------
--- An error happened in the servers background thread (this should not happen)

function xOscDevice:socket_error(error_message)

  LOG(("xOscDevice: socket error: '%s'"):format(osc_error))    

end

--------------------------------------------------------------------------------
--- Receive/unpack osc messages 
-- @param socket (contains socket.port and socket.address)
-- @param binary_data (raw, packetized socket data)

function xOscDevice:socket_message(socket, binary_data)

  if not self.active then
    LOG("*** xOscDevice - ignoring messages while inactive")
    return
  end

  local message_or_bundle, osc_error = 
    renoise.Osc.from_binary_data(binary_data)
  
  if (message_or_bundle) then
    local messages = table.create()
    self:_unpack_messages(message_or_bundle, messages)

    for _,msg in pairs(messages) do

      if self.callback then

        -- ignore messages that doesn't match our prefix
        if (self.prefix ~= "") then
          local prefix_str = string.sub(msg.pattern,0,string.len(self.prefix))
          if (prefix_str ~= self.prefix) then 
            LOG("*** xOscDevice - ignoring message with invalid prefix",msg.pattern)
            return 
          end
          -- strip the prefix before continuing
          -- (we need to create a new osc message)
          local msg_pattern = string.sub(msg.pattern,string.len(self.prefix)+1)

          msg = renoise.Osc.Message(msg_pattern,msg.arguments)

        end

        self.callback(msg)
      end
    end
  
  else
    LOG(("xOscDevice: Got invalid OSC data, or data which is not " .. 
      "OSC data at all. Error: '%s'"):format(osc_error))    
  end
end

--------------------------------------------------------------------------------
-- build raw message, send or add to queue
-- @param xmsg, xOscMessage
-- @return bool, true when message was transmitted
-- @return string, message when failed

function xOscDevice:send(xmsg)

  if not self.client or not self.client.is_open then
    LOG("Could not send OSC message - device is not ready")
    return false
  end

  -- add prefix , if not already added
  local prefix_str = string.sub(xmsg.pattern.osc_pattern_out,0,string.len(self.prefix))
  if (prefix_str ~= self.prefix) then 
    xmsg.pattern.osc_pattern_out = self.prefix .. xmsg.pattern.osc_pattern_out
  end

  local msg = xmsg:create_raw_message()

  if not self.bundling_enabled then
    self.client:send(msg)
  else
    table.insert(self.message_queue,msg)
    -- send immediately? 
    if (self.bundle_limit > 0) 
      and (#self.message_queue > self.bundle_limit)
    then
      self:send_bundle()
    end
  end

  return true

end

--------------------------------------------------------------------------------

function xOscDevice:send_bundle()

  if not self.client or not self.client.is_open then
    LOG("Could not send OSC message - device is not ready")
    return false
  end

  local osc_bundle = renoise.Osc.Bundle(os.clock(),self.message_queue)
  
  self.message_queue = {}

end

--------------------------------------------------------------------------------

function xOscDevice:on_idle()
  --TRACE("xOscDevice:on_idle()")

  if self._initialize_requested then
    if not self.active then
      return
    end
    self._initialize_requested = false
    self:close()
    self:open()
  end

  if not table.is_empty(self.message_queue) then
    self:send_bundle()
  end

end

--------------------------------------------------------------------------------

function xOscDevice:__tostring()

  return type(self) 
    .. ", active:"    .. tostring(self.active_observable.value) 
    .. ", name:"      .. tostring(self.name_observable.value) 
    .. ", prefix:"    .. tostring(self.prefix_observable.value) 
    .. ", address:"   .. tostring(self.address_observable.value) 
    .. ", port_in:"   .. tostring(self.port_in_observable.value) 
    .. ", port_out:"  .. tostring(self.port_out_observable.value)

end



