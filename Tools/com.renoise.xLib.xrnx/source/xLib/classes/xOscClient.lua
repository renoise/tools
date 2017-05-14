--[[============================================================================
-- xLib.xOscClient
============================================================================]]--

--[[--

xOscClient wraps a renoise.Socket with some handy methods 
.
#

* Connects to the built-in OSC server in Renoise, 
* Produce realtime messages (notes or MIDI messages)

--]]

--==============================================================================

class 'xOscClient' 

--------------------------------------------------------------------------------
-- [Constructor] Accepts a table argument for initializing the class 
-- @param table{
--    osc_host (string),
--    osc_port (number)
--  }

function xOscClient:__init(...)
  TRACE("xOscClient:__init(...)")

  local args = cLib.unpack_args(...)

  --- string
  self.osc_host = property(self.get_osc_host,self.set_osc_host)
  self.osc_host_observable = renoise.Document.ObservableString()

  --- int
  self.osc_port = property(self.get_osc_port,self.set_osc_port)
  self.osc_port_observable = renoise.Document.ObservableNumber()

  -- internal --

  -- number, used for internal server test 
  self._test_clock = nil
  self._test_new_value = nil
  self._test_old_value = nil
  self._test_failed_observable = renoise.Document.ObservableBang()
  self._test_passed_observable = renoise.Document.ObservableBang()

  --- the socket connection, nil if not established
  self._connection = nil

  -- initialize --

  local created,err = self:create(args.osc_host,args.osc_port) 
  if not created and err then 
    LOG(err)
  end 


end


--------------------------------------------------------------------------------
-- [Class] Initialize the xOscClient class
-- @param osc_host (string) the host-address name (can be an IP address)
-- @param osc_port (int) the host port
-- @return boolean, 
-- @return string, error message when failed

function xOscClient:create(osc_host,osc_port)
  TRACE("xOscClient:create(osc_host,osc_port)",osc_host,osc_port)

  --assert(osc_host and osc_port,"Expected osc_host and osc_port as arguments")
  if not osc_host and not osc_port then
    return
  end

  if self._connection then 
    self._connection:close()
  end

	local client, socket_error = renoise.Socket.create_client(osc_host, osc_port, renoise.Socket.PROTOCOL_UDP)
	if (socket_error) then 
    self._connection = nil
    return false, "*** Warning: xOscClient failed to start the internal OSC client"
	else
    self._connection = client
    self.osc_host_observable.value = osc_host
    self.osc_port_observable.value = osc_port
    return true
	end

end

--------------------------------------------------------------------------------
-- [Class] Trigger instrument-note
-- @param note_on (bool), true when note-on and false when note-off
-- @param instr (int), the Renoise instrument index 
-- @param track (int) the Renoise track index
-- @param note (int), the desired pitch, 0-120
-- @param velocity (int), the desired velocity, 0-127
-- @return bool, true when triggered

function xOscClient:trigger_instrument(note_on,instr,track,note,velocity)
  TRACE("xOscClient:trigger_instrument(note_on,instr,track,note,velocity)",note_on,instr,track,note,velocity)
  
  if not self._connection then
    LOG("*** xOscClient: can't trigger notes without a connection")    
    return false
  end

  local osc_vars = table.create()
  osc_vars:insert({tag = "i",value = instr})
  osc_vars:insert({tag = "i",value = track})
  osc_vars:insert({tag = "i",value = note})

  local header = nil
  if (note_on) then
    header = "/renoise/trigger/note_on"
    osc_vars:insert({tag = "i",value = velocity})
  else
    header = "/renoise/trigger/note_off"
    -- show instructions when releasing note
    --self:_show_instructions()
  end

  local osc_msg = renoise.Osc.Message(header,osc_vars)
  self._connection:send(osc_msg)

  return true

end

--------------------------------------------------------------------------------
-- [Class] Trigger standard midi-message
-- @param t (table), a ready-to-send MIDI message
-- @return bool, true when triggered

function xOscClient:trigger_midi(t)
  TRACE("xOscClient:trigger_midi(t)",t)
  
  if not self._connection then
    LOG("*** xOscClient: can't trigger MIDI without a connection")  
    return false
  end

  local header = "/renoise/trigger/midi"
  local val = math.floor(t[1])+
             (math.floor(t[2])*256)+
             (math.floor(t[3])*65536)

  local osc_vars = table.create()
  osc_vars:insert({tag = "i",value = val})

  local osc_msg = renoise.Osc.Message(header,osc_vars)
  self._connection:send(osc_msg)

  return true

end

--------------------------------------------------------------------------------
-- [Class] Trigger 'automatic MIDI' using the internal OSC client
-- if notes, route to specified track + instrument - else, pass as raw MIDI
-- @param xmsg (xMidiMessage or xOscMessage)
-- @return bool, true when triggered

function xOscClient:trigger_auto(xmsg)
  TRACE("xOscClient:trigger_auto(xmsg)",xmsg)

  local is_note_on = (xmsg.message_type == xMidiMessage.TYPE.NOTE_ON)
  local is_note_off = (xmsg.message_type == xMidiMessage.TYPE.NOTE_OFF)

  if is_note_on or is_note_off then
    local instr_idx = xmsg.instrument_index or rns.selected_instrument_index
    local track_idx = xmsg.track_index or rns.selected_track_index
    return self:trigger_instrument(is_note_on,instr_idx,track_idx,xmsg.values[1],xmsg.values[2])
  else
    if (type(xmsg)~="xMidiMessage") then
      -- on-the-fly conversion, include MIDI properties 
      -- that has been specified in the function
      local def = xmsg.__def
      def.message_type = xmsg.message_type
      def.channel = xmsg.channel
      def.bit_depth = xmsg.bit_depth
      def.port_name = xmsg.port_name
      xmsg = xMidiMessage(def) 
    end
    return self:trigger_raw(xmsg)
  end

end

--------------------------------------------------------------------------------
-- [Class] Trigger 'raw MIDI' (makes notes MIDI-mappable)
-- @param xmsg (xMidiMessage or xOscMessage)
-- @return bool, true when triggered
-- @return string, error message when failed

function xOscClient:trigger_raw(xmsg)
  TRACE("xOscClient:trigger_raw(xmsg)",xmsg)

  assert(type(xmsg)=="xMidiMessage","Expected xMidiMessage as argument")

  if (xmsg.message_type == xMidiMessage.TYPE.SYSEX) then
    local err = "*** Warning: the internal OSC server does not support sysex messages"
    return false,err
  end

  local midi_msgs = xmsg:create_raw_message()
  for k,v in ipairs(midi_msgs) do
    self:trigger_midi(v)
  end

  return true

end

--------------------------------------------------------------------------------

function xOscClient:get_osc_host()
  return self.osc_host_observable.value
end

function xOscClient:set_osc_host(val)
  TRACE("xOscClient:set_osc_port(val)",val)

  self.osc_host_observable.value = val
  local created,err = self:create(val,self.osc_port_observable.value)  
  if not created and err then 
    LOG(err)
  end 
  
end

--------------------------------------------------------------------------------

function xOscClient:get_osc_port()
  return self.osc_port_observable.value
end

function xOscClient:set_osc_port(val)
  TRACE("xOscClient:set_osc_port(val)",val)

  if (val > xLib.MAX_OSC_PORT) or (val < xLib.MIN_OSC_PORT) then
    local msg = "Cannot set to a port number outside this range: %d-%d"
    error(msg:format(xLib.MAX_OSC_PORT,xLib.MIN_OSC_PORT))
  end    
  self.osc_port_observable.value = val
  local created,err = self:create(self.osc_host_observable.value,val)
  if not created and err then 
    LOG(err)
  end 

end

--------------------------------------------------------------------------------
-- Confirm that the internal OSC server is configured and running - 
-- TODO: switch to API method for detection once available, this method is 
-- only reliable for as long as there are no more than 3 concurrent attempts
-- (after that, the active_clipboard_index will point to the original value)

function xOscClient:_detect_server()
  TRACE("xOscClient:_detect_server()")

  if not self._connection then
    LOG("*** xOscClient: can't detect server, no connection was established")
    return false
  end

  renoise.tool().app_idle_observable:add_notifier(self,xOscClient._test_idle_notifier)

  -- trigger the change using a fairly obscure property: 
  -- active_clipboard_index (will not modify undo history)
  self._test_clock = os.clock()
  self._test_old_value = renoise.app().active_clipboard_index
  self._test_new_value = 1+(self._test_old_value%4)
  self._connection:send(
    renoise.Osc.Message("/renoise/evaluate", { 
      {tag="s", value="renoise.app().active_clipboard_index = "..self._test_new_value} 
    })
  )  

end

--------------------------------------------------------------------------------
-- Server test - check if the property was "instantly" changed (0.2s)

function xOscClient:_test_idle_notifier()

  local remove_obs = function()
    local obs = renoise.tool().app_idle_observable
    if obs:has_notifier(self,xOscClient._test_idle_notifier) then 
      obs:remove_notifier(self,xOscClient._test_idle_notifier)
    end
    -- also restore old value
    renoise.app().active_clipboard_index = self._test_old_value
  end

  local clock_diff = os.clock() - self._test_clock
  if (clock_diff > 1) then -- failed test 
    remove_obs()
    self._test_failed_observable:bang()
  else
    local curr_value = renoise.app().active_clipboard_index
    if (curr_value == self._test_new_value) then -- passed test
      local msg = "xOscClient: Renoise OSC server was found at %s:%d"
      LOG(msg:format(self._connection.peer_address,self._connection.peer_port))
      remove_obs()
      self._test_passed_observable:bang()
    end
  end

end

