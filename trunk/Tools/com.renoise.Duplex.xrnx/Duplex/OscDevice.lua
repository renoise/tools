--[[----------------------------------------------------------------------------
-- Duplex.OscDevice
----------------------------------------------------------------------------]]--

--[[

Inheritance: OscDevice -> Device

Requires: Globals

--]]


--==============================================================================

class 'OscDevice' (Device)

function OscDevice:__init(name, message_stream,prefix,address,port_in,port_out)
  TRACE("OscDevice:__init()",
    name, 
    message_stream,
    prefix,
    address,
    port_in,
    port_out)
  
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

-- create the OSC client/server sockets, set prefix (if any)

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

-- an error happened in the servers background thread
-- (note: this should not happen)

function OscDevice:socket_error(error_message)
  TRACE("OscDevice:socket_error",error_message)

  -- should we bother the user with this?
end


--------------------------------------------------------------------------------

-- receive/unpack incoming osc messages
-- largely identical to the MidiDevice implementation, except that we 
-- look for the control-map "action" instead of the "value" attribute
-- (but still using the "value" as fallback if "action" is undefined)

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

      --print("osc value_str",value_str)

      if value_str then
        print("*** received message",value_str)
        self:receive_osc_message(value_str)
      end

    end
  
  else
    TRACE(("OscDevice: Got invalid OSC data, or data which is not " .. 
      "OSC data at all. Error: '%s'"):format(osc_error))    
  end
  
end


--------------------------------------------------------------------------------

-- look up value, once we have unpacked the message
function OscDevice:receive_osc_message(value_str)
  TRACE("OscDevice:receive_message",value_str)

  local param,val = self.control_map:get_param_by_action(value_str)
  if (param) then
    local message = Message()
    message.context = OSC_MESSAGE
    -- cap to the range specified in the control-map
    for k,v in pairs(val) do
      val[k] = clamp_value(v,param["xarg"].minimum,param["xarg"].maximum)
    end
    -- multiple values?
    message.value = (#val>1) and val or val[1]
    self:_send_message(message,param["xarg"])
  end

end

--------------------------------------------------------------------------------

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

-- set prefix for this device (pattern is appended to all outgoing traffic,
-- and also act as a filter for incoming messages). 
-- @param prefix (string), e.g. "/my_device" 

function OscDevice:set_device_prefix(prefix)
  TRACE("OscDevice:set_device_prefix()",prefix)

  if (not prefix) then 
    self.prefix = ""
  else
    self.prefix = prefix
  end

end

--------------------------------------------------------------------------------

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

-- bundle & send queued messages, clear queue

function OscDevice:on_idle()

  if self.message_queue then
    self:send_osc_bundle()
  end

end

--------------------------------------------------------------------------------

-- construct_osc_message

function OscDevice:construct_osc_message(message,value)

    -- split the message into non-whitespace chunks
    local str_vars = string.gmatch(message,"[^%s]+")

    -- construct the table of variables
    local header = nil
    local osc_vars = table.create()
    local counter = 1
    for vars in str_vars do
      --print("vars",vars)
      
      if (string.sub(vars,0,1)=="/") then
        -- the message part
        header = vars
      else
        -- the variable part
        local entry = table.create()
        if (type(value)=="table") then
          local counter2 = 1
          for k,v in pairs(value) do
            --print("*** got here",counter,counter2)
            if (counter==counter2) then
              --print(k,v)
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

--  send bundle of OSC messages

function OscDevice:send_osc_bundle()

  local msgs = table.create()
  for k,v in ipairs(self.message_queue) do
    msgs:insert(self:construct_osc_message(v.message,v.value))
  end
  --[[
  print("msgs",msgs)
  rprint(msgs)
  ]]
  local bundle = renoise.Osc.Bundle(os.clock(),msgs)
  self:send_osc_message(bundle)
  self.message_queue:clear()
  self.message_queue = nil

end


--------------------------------------------------------------------------------

--  send OSC message
--  @param message (string) the message string
--  @param value (number) the value to inject

function OscDevice:send_osc_message(message)
  TRACE("OscDevice:send_osc_message()",message)

  if (self.client) and (self.client.is_open) then

    self.client:send(message)
  end

end


--------------------------------------------------------------------------------

-- produce an OSC message entry 

function OscDevice:produce_entry(vars,value)

  local entry = table.create()
  if (vars=="%i") then
    entry.tag = "i"
    entry.value = tonumber(value)
  elseif (vars=="%f") then
    --print("*** got here B")
    entry.tag = "f"
    entry.value = tonumber(value)
  elseif (tonumber(vars)~=nil) then
    --print("*** got here A")
    entry.tag = "f"
    entry.value = tonumber(vars)
  end
  return entry
end

--------------------------------------------------------------------------------

-- Convert the point to an output value
-- @param pt (CanvasPoint)
-- @param elm - control-map parameter
-- @param ceiling - the UIComponent ceiling value
-- @return value (number, or table of numbers)

function OscDevice:point_to_value(pt,elm,ceiling)
  TRACE("OscDevice:point_to_value()",pt,elm,ceiling)

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
    --rprint(value)

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

-- recursively unpacks all OSC messages from the given bundle or message. 
-- when message_or_bundle is a single message, only this one will be added
-- to the given message list

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

-- create string representation of OSC message:
-- e.g. "/this/is/the/pattern 1 2 3"

function OscDevice:_msg_to_string(msg)
  --TRACE("OscDevice:_msg_to_string()",msg)

  local rslt = msg.pattern
  for k,v in ipairs(msg.arguments) do
    rslt = ("%s %s"):format(rslt, tostring(v.value))
  end

  return rslt

end



