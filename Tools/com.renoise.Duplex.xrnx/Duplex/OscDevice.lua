--[[============================================================================
-- Duplex.OscDevice
-- Inheritance: OscDevice -> Device
============================================================================]]--

--[[--
A generic OSC device class, providing the ability to send and receive OSC.


### Changes

  0.99.3
    - Ability to dump OSC message to console (just like MIDI messages)
    - Feedback prevention: optionally block messages that appear to be echoed back

  0.99.2
    - strip non-ascii character from text before sending
    - "pattern captures" - reconstruct when sending outgoing OSC message

  0.98.27
    - support text values

  0.98.14  
    - optional, per-device message bundling (for example, TouchOSC)
      ..no more lost messages on wireless devices?

  0.9
    - First release


--]]

--==============================================================================


class 'OscDevice' (Device)

--------------------------------------------------------------------------------

--- Initialize OSCDevice class
-- @param name (string) the friendly name of the device
-- @param message_stream (@{Duplex.MessageStream}) the msg-stream we should attach to
-- @param prefix (string) the OSC prefix to use
-- @param address (string) the OSC address (can be an IP address)
-- @param port_in (int) the OSC input port 
-- @param port_out (int) the OSC output port 

function OscDevice:__init(name, message_stream,prefix,address,port_in,port_out)
  TRACE("OscDevice:__init()",name,message_stream,prefix,address,port_in,port_out)
  
  Device.__init(self, name, message_stream, DEVICE_PROTOCOL.OSC)

  --- (string) optional device prefix, e.g. "/duplex"
  self.prefix = prefix

  --- (address) can be an IP address or a domain
  self.address = address

  --- (int) the port where incoming messages arrive
  self.port_in = port_in

  --- (int) the port where outgoing messages leave
  self.port_out = port_out

  --- (bool) whether we should bundle OSC messages (true) or not (false).
  -- Enable this feature if you experience lost packets, and/or is using
  -- devices that communicate over wireless networks (see TouchOSC class)
  self.bundle_messages = false


  ---- private

  --- (renoise.Socket.SocketClient)
  self.client = nil

  --- (renoise.Socket.SocketServer)
  self.server = nil

  --- (table) containing queued messages.
  --    [1] = {
  --      message = (string) -- e.g. "/device/button %i"
  --      value = (number or table) -- the current value
  --    },...
  self.message_queue = nil


  ---- initialize

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

--- An error happened in the servers background thread (this should not happen)

function OscDevice:socket_error(error_message)
  TRACE("OscDevice:socket_error",error_message)

  -- should we bother the user with this?
end


--------------------------------------------------------------------------------

--- Receive/unpack osc messages - this is a low-level method which will receive 
-- incoming messages and translate them into a text representation 
-- @param socket (a "dummy" socket, contains socket.port and socket.address)
-- @param binary_data (raw, packetized socket data)

function OscDevice:socket_message(socket, binary_data)
  TRACE("OscDevice:socket_message",socket, binary_data)

  local message_or_bundle, osc_error = 
    renoise.Osc.from_binary_data(binary_data)
  
  if (message_or_bundle) then
    local messages = table.create()
    self:_unpack_messages(message_or_bundle, messages)

    for _,msg in pairs(messages) do

      local value_str = self:_msg_to_string(msg)
      if(self.dump_osc)then
        LOG(("OscDevice: %i incoming OSC message %s"):format(
          self.port_in, value_str))
      end

      -- block/ignore messages that appear to be feedback
      --print("*** OscDevice.receive_osc_message - self.feedback_prevention_enabled",self.feedback_prevention_enabled,value_str)
      if self.feedback_prevention_enabled then
        for k,v in ipairs(self._feedback_buffer) do
          if (value_str == v.value_str) then
            --print("*** receive_osc_message - feedback prevention:",value_str)
            return
          end
        end
      end

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
        self:receive_osc_message(value_str)
      end

    end
  
  else
    LOG(("OscDevice: Got invalid OSC data, or data which is not " .. 
      "OSC data at all. Error: '%s'"):format(osc_error))    
  end
  
end

--------------------------------------------------------------------------------

--- Look up value, once we have unpacked the message
-- @param value_str (string), control-map string

function OscDevice:receive_osc_message(value_str)
  TRACE("OscDevice:receive_message",value_str)

  -- retrieve the relevant control-map parameter(s)
  local params = self.control_map:get_osc_params(value_str)
  --print("*** OscDevice.receive_osc_message - value_str,#params",value_str,#params)

  for k,v in ipairs(params) do

    local param,val,regex = v[1],v[2],v[3]
    --print("param,val,regex",param,"val",val,"regex",regex)
    --print("param",rprint(param))

    -- take copy before modifying stuff
    --param = table.rcopy(param)
    val = table.rcopy(val)
    
    local msg = Message()
    msg.context = DEVICE_MESSAGE.OSC

    -- cap to the range specified in the control-map
    for k,v in pairs(val) do
      val[k] = clamp_value(v,param.xarg.minimum,param.xarg.maximum)
    end

    -- multiple messages are tables, single value a number...
    msg.value = (#val>1) and val or val[1]
    
    --print("*** OscDevice:receive_osc_msg - msg.value",msg.value)

    self:_send_message(msg,param,regex)
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
-- @param prefix (string)

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
--  @param message (string) the message string
--  @param value (number, string or table) the value(s) to inject

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

--- Bundle & send queued messages

function OscDevice:on_idle()

  if self.message_queue then
    self:send_osc_bundle()
  end

  -- clear the feedback buffer after a certain time
  if self.feedback_prevention_enabled then
    local clk = os.clock()
    for k,v in ripairs(self._feedback_buffer) do
      if (clk-v.timestamp > 0.05) then
        table.remove(self._feedback_buffer,k)
        --print("cleared recent message, #self._feedback_buffer",#self._feedback_buffer)
      else
        break
      end
    end
  end

end

--------------------------------------------------------------------------------

--- Send a queued bundle of OSC messages 
-- @see OscDevice:queue_osc_message

function OscDevice:send_osc_bundle()

  if (self.client) and (self.client.is_open) then
    local msgs = table.create()
    for k,v in ipairs(self.message_queue) do

      local value_str = nil
      local osc_msg = self:_construct_osc_message(v.message,v.value)
      msgs:insert(osc_msg)
        value_str = self:_msg_to_string(osc_msg)

      -- remember for later (feedback prevention)
      if self.feedback_prevention_enabled then
        value_str = self:_msg_to_string(osc_msg)
        self._feedback_buffer[#self._feedback_buffer+1] = {
          timestamp = os.clock(),
          value_str = value_str
        }
      end
      --print("*** send_osc_bundle",v,rprint(v.value),value_str)
      if(self.dump_osc)then
        LOG(("OscDevice: %i send message %s"):format(
          self.port_out, value_str))
      end

    end
    local osc_bundle = renoise.Osc.Bundle(os.clock(),msgs)
    self.client:send(osc_bundle)
  end

  self.message_queue:clear()
  self.message_queue = nil

end


--------------------------------------------------------------------------------

--- Send a OSC message right away. This is the method being used by the 
-- Display for updating the visual state of device 
-- @param message (string) the message string, e.g. "/device/button %i"
-- @param value (number or table) the value(s) to inject

function OscDevice:send_osc_message(message,value)
  TRACE("OscDevice:send_osc_message()",message,value)

  if (self.client) and (self.client.is_open) then

    local osc_msg = self:_construct_osc_message(message,value)
    local value_str = nil

    -- remember for later (feedback prevention)
    if self.feedback_prevention_enabled then
      value_str = self:_msg_to_string(osc_msg)
      self._feedback_buffer[#self._feedback_buffer+1] = {
        timestamp = os.clock(),
        value_str = value_str
      }
    end

    if(self.dump_osc)then
      LOG(("OscDevice: %i send message %s %s %s"):format(
        self.port_out, message,tostring(value),tostring(value_str)))
    end


    self.client:send(osc_msg)

  end

end


--------------------------------------------------------------------------------
-- Private
--------------------------------------------------------------------------------


--- Construct OSC message (used by @{send_osc_message} & @{send_osc_bundle})
-- @param message (string) the message string, e.g. "/device/button %i"
-- @param value (number or table) the value(s) to inject

function OscDevice:_construct_osc_message(message,value)
  TRACE("OscDevice:_construct_osc_message()",message,value)

  -- typemap helps us detect if we have captures, tokens
  local tmap = self.control_map.typemaps[message]
  --print("tmap,message",tmap,message)

  --print("value",rprint(value))
  --print("table_vars",rprint(table_vars))
  --print("has_captures",has_captures)
  --print("tmap",rprint(tmap),#tmap)

  local header = nil
  local osc_vars = table.create()
  local counter = 1

  if tmap then

    -- using the typemap we can assemble a message from captured parts,
    -- however, not all messages have a typemap (raw messages being
    -- sent to device will not have one, only control-map based ones)

    for k = 1, #tmap do
      
      local t = tmap[k]
      if t.is_header then
        header = t.text
      else
        -- the variable part
        local entry = table.create()
        if (type(value)=="table") then
          if t.is_token then
            if tmap.has_captures then
              if t.is_capture then
                --print("table, insert captured value #",counter,"at pos",k)
                entry = self:_produce_entry(v,value[counter])
                if (entry.tag) then
                  osc_vars:insert(entry)
                end
                counter = counter+1
              else
                --print("table, insert neutral value")
                entry = self:_produce_entry(t.text,0)
                if (entry.tag) then
                  osc_vars:insert(entry)
                end
              end
            else
              --print("table, no captures, insert value#",counter)
              entry = self:_produce_entry(t.text,value[counter])
              if (entry.tag) then
                osc_vars:insert(entry)
              end
              counter = counter+1
            end
          else
            --print("table, no token, insert literal value")
            entry = self:_produce_entry(t.text,t.text)
            if (entry.tag) then
              osc_vars:insert(entry)
            end
          end
        else
          -- single value
          entry = self:_produce_entry(t.text,(t.is_token) and value or t.text)
          if (entry.tag) then
            osc_vars:insert(entry)
          end
        end

      end --/variable part
    end--/iterator

  else

    -- do basic osc output 

    -- split the message into non-whitespace chunks
    local str_vars = string.gmatch(message,"[^%s]+")

    -- construct the table of variables
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
              entry = self:_produce_entry(vars,v)
            end
            counter2 = counter2+1
          end
        else
          entry = self:_produce_entry(vars,value)
        end
        if (entry.tag) then
          osc_vars:insert(entry)
        end
        counter = counter+1
      end

    end


  end

  --print("self.prefix,header",self.prefix,header)
  header = self.prefix and ("%s%s"):format(self.prefix,header) or header

  return renoise.Osc.Message(header,osc_vars)

end

--------------------------------------------------------------------------------

--- Recursively unpacks all OSC messages from the given bundle or message. 
-- when message_or_bundle is a single message, only this one will be added
-- to the given message list
-- @param message_or_bundle (renoise.Osc.Message or renoise.Osc.Bundle) 
-- @param messages (table) table to insert unpacked messages into

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

--- Produce an OSC message value entry (utilized by @{_construct_osc_message}).
--
-- Note that if only "vars" is defined, it will be treated as a standalone 
-- floating-point value. Otherwise, "vars" will indicate the type of value
--
-- @param vars (number or string), value or the type of value
--    "%i" = integer number 
--    "%f" = floating-point 
--    "%s" = string (ascii)
-- @param value (number)

function OscDevice:_produce_entry(vars,value)
  TRACE("OscDevice:_produce_entry()",vars,value)

  local entry = table.create()
  if (vars=="%i") or (vars=="{%i}") then
    entry.tag = "i"
    entry.value = math.floor(value) or 0
  elseif (vars=="%f") or (vars=="{%f}")then
    entry.tag = "f"
    entry.value = tonumber(value) or 0
  elseif (vars=="%s") or (vars=="{%s}") then
    entry.tag = "s"

    -- remove control characters (linebreak, etc)
    value = value and string.gsub(value,"%c"," ") or ""
     
    -- strip remaining non-ascii characters
    local rslt = {}
    for i = 1,#value do
      local str_char = string.sub(value,i,i)
      if (string.byte(str_char) <= 127) then
        rslt[#rslt+1] = str_char -- .."("..string.byte(str_char)..")"
      end
    end
    --print("rslt...")
    --rprint(rslt)

    entry.value = table.concat(rslt,"")

  elseif (tonumber(vars)~=nil) then
    entry.tag = "f"
    entry.value = tonumber(vars)
  end
  --print("entry...")
  --rprint(entry)
  return entry
end

--------------------------------------------------------------------------------

--- Create string representation of OSC message:
-- e.g. "/this/is/the/pattern 1 2 3"
-- @param msg (renoise.Osc.Message)

function OscDevice:_msg_to_string(msg)
  TRACE("OscDevice:_msg_to_string()",msg)

  local str_rslt = msg.pattern
  for k,v in ipairs(msg.arguments) do
    --print("*** OscDevice:_msg_to_string",k,v.value,type(v.value))
    str_rslt = ("%s %s"):format(str_rslt, tostring(v.value))
  end

  return str_rslt

end

