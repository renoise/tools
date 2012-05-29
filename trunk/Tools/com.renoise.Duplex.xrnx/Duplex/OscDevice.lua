--[[----------------------------------------------------------------------------
-- Duplex.OscDevice
----------------------------------------------------------------------------]]--

--[[

Inheritance: OscDevice -> Device

Requires: Globals

--]]


--==============================================================================

class 'OscDevice' (Device)

--------------------------------------------------------------------------------

--- Initialize OSCDevice class
-- @param name (String) the friendly name of the device
-- @param message_stream (MessageStream) the msg-stream we should attach to
-- @param prefix (String) the OSC prefix to use
-- @param address (String) the OSC address (can be an IP address)
-- @param port_in (Number) the OSC input port 
-- @param port_out (Number) the OSC output port 

function OscDevice:__init(name, message_stream,prefix,address,port_in,port_out)
  TRACE("OscDevice:__init()",name,message_stream,prefix,address,port_in,port_out)
  
  Device.__init(self, name, message_stream, DEVICE_OSC_PROTOCOL)

  self.prefix = prefix
  self.address = address

  self.port_in = port_in
  self.port_out = port_out

  self.client = nil
  self.server = nil

  self.message_queue = nil

  self.bundle_messages = false

  self:open()

end


--------------------------------------------------------------------------------

--- Create the OSC client/server sockets, set prefix (if any)

function OscDevice:open()
  TRACE("OscDevice:open()")

  assert(((not self.client) or (not self.server)), 
    "Internal Error. Please report: " .. 
    "trying to start an OSC service which is already active")

  -- open a client connection (send to device)
  local client, socket_error = renoise.Socket.create_client(
    self.address, self.port_out, renoise.Socket.PROTOCOL_UDP)
  if (socket_error) then 
    renoise.app():show_warning(("Failed to start the " .. 
      "OSC client for Duplex device '%s'. Error: '%s'"):format(
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
      "OSC server for Duplex device '%s'. Error: '%s'"):format(
      self.name, socket_error))

    self.server = nil
    return
  
  else
    self.server = server
    self.server:run(self)
  end
    
  self:set_device_prefix(self.prefix)
    
end


--------------------------------------------------------------------------------

--- En error happened in the servers background thread (this should not happen)

function OscDevice:socket_error(error_message)
  TRACE("OscDevice:socket_error",error_message)

  -- should we bother the user with this?
end


--------------------------------------------------------------------------------

--- Receive/unpack incoming osc messages: largely identical to the 
-- MidiDevice implementation, except that we look for the control-map "action" 
-- instead of the "value" attribute
-- @param socket (
-- @param binary_data
--[[
function OscDevice:socket_message(socket, binary_data)
  TRACE("OscDevice:socket_message",socket, binary_data)

  local message_or_bundle, osc_error = 
    renoise.Osc.from_binary_data(binary_data)
  
  if (message_or_bundle) then
    local messages = table.create()
    self:_unpack_messages(message_or_bundle, messages)

    for _,msg in pairs(messages) do
      local value_str = self:_msg_to_string(msg)

      -- (only if defined) check the prefix:
      -- ignore messages that doesn't match our prefix
      if (self.prefix) then
        local prefix_str = string.sub(value_str,0,string.len(self.prefix))
        if (prefix_str~=self.prefix) then 
          return 
        end
        -- strip the prefix before continuing
        value_str = string.sub(value_str,string.len(self.prefix)+1)
      end

      if value_str then
        
        --print("incoming OSC",os.clock(),value_str)
        self:receive_osc_message(value_str)
      end

    end
  
  else
    TRACE(("OscDevice: Got invalid OSC data, or data which is not " .. 
      "OSC data at all. Error: '%s'"):format(osc_error))    
  end
  
end
]]

--------------------------------------------------------------------------------

--- Look up value, once we have unpacked the message
-- @param value_str (String), control-map string

function OscDevice:receive_osc_message(value_str)
  TRACE("OscDevice:receive_message",value_str)

  local param,val,w_idx,r_char = self.control_map:get_osc_param(value_str)
  --print("*** OscDevice: param,val,w_idx,r_char",param,val,w_idx,r_char)

  if (param) then

    -- take copy before modifying stuff
    local xarg = table.rcopy(param["xarg"])
    if w_idx then
      -- insert the wildcard index
      xarg["index"] = tonumber(r_char)
      --print('*** OscDevice: wildcard replace param["xarg"]["value"]',xarg["value"])
    end
    local message = Message()
    message.context = OSC_MESSAGE
    message.is_osc_msg = true
    -- cap to the range specified in the control-map
    for k,v in pairs(val) do
      val[k] = clamp_value(v,xarg.minimum,xarg.maximum)
    end
    --rprint(xarg)
    -- multiple messages are tables, single value a number...
    message.value = (#val>1) and val or val[1]
    --print("*** OscDevice:receive_osc_message - message.value",message.value)
    self:_send_message(message,xarg)
  end

end

--------------------------------------------------------------------------------

--- Release the device

function OscDevice:release()
  TRACE("OscDevice:release()")
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

--- Set prefix for this device (a pattern which is appended to all outgoing 
-- traffic, and also act as a filter for incoming messages)
-- @param prefix (String)

function OscDevice:set_device_prefix(prefix)
  TRACE("OscDevice:set_device_prefix()",prefix)

  if (not prefix) then 
    self.prefix = ""
  else
    self.prefix = prefix
  end

end

--------------------------------------------------------------------------------

--- Queue a message instead of sending it right away. Some devices need data
-- to arrive in fewer packets due to network conditions
--  @param message (String) the message string
--  @param value (Number or Table) the value(s) to inject

function OscDevice:queue_osc_message(message,value)

  if not self.message_queue then
    self.message_queue = table.create()
  end

  -- TODO when queue reach certain size, send bundle
  -- (for increased responsiveness)
    
  self.message_queue:insert({
    message=message,
    value=value
  })

end

--------------------------------------------------------------------------------

-- bundle & send queued messages

function OscDevice:on_idle()

  if self.message_queue then
    self:send_osc_bundle()
  end

end

--------------------------------------------------------------------------------

-- construct_osc_message

function OscDevice:construct_osc_message(message,value)
  TRACE("OscDevice:construct_osc_message()",message,value)

    -- split the message into non-whitespace chunks
    local str_vars = string.gmatch(message,"[^%s]+")

    -- construct the table of variables
    local header = nil
    local osc_vars = table.create()
    local counter = 1
    for vars in str_vars do
      
      if (string.sub(vars,0,1)=="/") then
        -- the message part
        header = vars
      else
        -- the variable part
        local entry = table.create()
        if (type(value)=="table") then
	
          local counter2 = 1
          for k,v in pairs(value) do
            if (counter==counter2) then
              entry = self:produce_entry(vars,v)
            end
            counter2 = counter2+1
          end
        else
          entry = self:produce_entry(vars,value)
        end
        if (entry.tag) then
          osc_vars:insert(entry)
        end
        counter = counter+1
      end

    end

    header = self.prefix and ("%s%s"):format(self.prefix,header) or header

    return renoise.Osc.Message(header,osc_vars)

end

--------------------------------------------------------------------------------

---  Send a queued bundle of OSC messages 
-- @see OscDevice:queue_osc_message

function OscDevice:send_osc_bundle()

  if (self.client) and (self.client.is_open) then
    local msgs = table.create()
    for k,v in ipairs(self.message_queue) do
      msgs:insert(self:construct_osc_message(v.message,v.value))
    end
    local osc_bundle = renoise.Osc.Bundle(os.clock(),msgs)
    self.client:send(osc_bundle)
  end

  self.message_queue:clear()
  self.message_queue = nil

end


--------------------------------------------------------------------------------

---  Send a OSC message right away
--  @param message (String) the message string
--  @param value (Number or Table) the value(s) to inject

function OscDevice:send_osc_message(message,value)
  TRACE("OscDevice:send_osc_message()",message,value)

  if (self.client) and (self.client.is_open) then
    --print("about to send osc message",message,value)
    local osc_msg = self:construct_osc_message(message,value)
    --rprint(osc_msg)
    self.client:send(osc_msg)
  end

end


--------------------------------------------------------------------------------

--- Produce an OSC message value entry. If only "vars" is defined, it will 
--  be treated as a standalone floating-point value. Otherwise, "vars" will 
--  indicate the type of value - Integer is "%i", while floating-point is "%f"
-- @param vars (Number or String), value or the type of value
-- @param value (Number)

function OscDevice:produce_entry(vars,value)
  --TRACE("OscDevice:produce_entry()",vars,value)

  local entry = table.create()
  if (vars=="%i") then
    entry.tag = "i"
    entry.value = tonumber(value)
  elseif (vars=="%f") then
    entry.tag = "f"
    entry.value = tonumber(value)
  elseif (tonumber(vars)~=nil) then
    entry.tag = "f"
    entry.value = tonumber(vars)
  end
  return entry
end

--------------------------------------------------------------------------------

--- Convert the point to an output value. If the point has multiple values, it
--  is describing a multidimensional value, such as a tilt sensor or XY-pad. In
--  such a case, the method will return a table of values
-- @param pt (CanvasPoint), point containing the current value
-- @param elm (Table), control-map parameter
-- @param ceiling (Number), the UIComponent ceiling value
-- @return value (Number, or Table of Numbers)

function OscDevice:point_to_value(pt,elm,ceiling)
  --TRACE("OscDevice:point_to_value()",pt,elm,ceiling)

  local value = nil
  local val_type = type(pt.val)

  if (val_type == "boolean") then

    if (pt.val) then
      value = elm.maximum
    else
      value = elm.minimum
    end
  elseif (val_type == "table") then
    -- multiple-parameter: tilt sensors, xy-pad...
    value = table.create()
    for k,v in ipairs(pt.val) do
      value:insert((v * (1 / ceiling)) * 1)
    end

  else
    -- scale the value from "local" to "external"
    -- for instance, from Renoise dB range (1.4125375747681) 
    -- to a 7-bit controller value (127)
    value = (pt.val * (1 / ceiling)) * elm.maximum
  end

  return value
end


--------------------------------------------------------------------------------
-- Private
--------------------------------------------------------------------------------

--- Recursively unpacks all OSC messages from the given bundle or message. 
-- when message_or_bundle is a single message, only this one will be added
-- to the given message list
-- @param message_or_bundle (renoise.Osc.Message or renoise.Osc.Bundle) 
-- @param messages (Table) table to insert unpacked messages into

function OscDevice:_unpack_messages(message_or_bundle, messages)
   --TRACE("OscDevice:_unpack_messages()",message_or_bundle)
   
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

--- Create string representation of OSC message:
-- e.g. "/this/is/the/pattern 1 2 3"
-- @param msg (renoise.Osc.Message)

function OscDevice:_msg_to_string(msg)
  TRACE("OscDevice:_msg_to_string()",msg)

  local rslt = msg.pattern
  for k,v in ipairs(msg.arguments) do
    rslt = ("%s %s"):format(rslt, tostring(v.value))
  end

  return rslt

end



