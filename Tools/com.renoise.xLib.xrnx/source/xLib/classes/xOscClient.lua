--[[============================================================================
-- Duplex.xOscClient
============================================================================]]--

--[[--

xOscClient is a simple OSC client 
.
#

* Connects to the built-in OSC server in Renoise, 
* Produce realtime messages (notes or MIDI messages)


--]]

--==============================================================================

class 'xOscClient' 

--------------------------------------------------------------------------------
-- Class methods
--------------------------------------------------------------------------------

function xOscClient:__init(...)
  TRACE("xOscClient:__init(...)")

  local args = cLib.unpack_args(...)

  -- bool, display a message the first time a note message is sent
  self.first_run = property(self.get_first_run,self.set_first_run)
  self.first_run_observable = renoise.Document.ObservableBoolean()

  --- string
  self.osc_host = property(self.get_osc_host,self.set_osc_host)
  self.osc_host_observable = renoise.Document.ObservableString()

  --- int
  self.osc_port = property(self.get_osc_port,self.set_osc_port)
  self.osc_port_observable = renoise.Document.ObservableNumber()

  -- internal --

  --- the socket connection, nil if not established
  self._connection = nil

  -- initialize --

  self.first_run = args.first_run or false

  self:create(args.osc_host,args.osc_port)


end


--------------------------------------------------------------------------------
--- Initialize the xOscClient class
-- @param osc_host (string) the host-address name (can be an IP address)
-- @param osc_port (int) the host port
-- @return boolean, 
-- @return string, error message when failed

function xOscClient:create(osc_host,osc_port)

  --assert(osc_host and osc_port,"Expected osc_host and osc_port as arguments")
  if not osc_host and not osc_port then
    return
  end

	local client, socket_error = renoise.Socket.create_client(osc_host, osc_port, renoise.Socket.PROTOCOL_UDP)
	if (socket_error) then 
    self._connection = nil
    return false, "Warning: failed to start the internal OSC client"
	else
    self._connection = client
    self.osc_host_observable.value = osc_host
    self.osc_port_observable.value = osc_port
    return true
	end

end

--------------------------------------------------------------------------------
--- Trigger instrument-note
-- @param note_on (bool), true when note-on and false when note-off
-- @param instr (int), the Renoise instrument index 
-- @param track (int) the Renoise track index
-- @param note (int), the desired pitch, 0-120
-- @param velocity (int), the desired velocity, 0-127
-- @return bool, true when triggered

function xOscClient:trigger_instrument(note_on,instr,track,note,velocity)
  
  if not self._connection then
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
    self:_show_instructions()
  end

  local osc_msg = renoise.Osc.Message(header,osc_vars)
  self._connection:send(osc_msg)

  return true

end

--------------------------------------------------------------------------------
--- Trigger standard midi-message
-- @param t (table), a ready-to-send MIDI message
-- @return bool, true when triggered

function xOscClient:trigger_midi(t)
  TRACE("xOscClient:trigger_midi(t)",t)
  
  if not self._connection then
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
-- trigger 'automatic MIDI' using the internal OSC client
-- if notes, route to specified track + instrument - else, pass as raw MIDI
-- @param xmsg (xMidiMessage or xOscMessage)
-- @return bool, true when triggered

function xOscClient:trigger_auto(xmsg)
  TRACE("xOscClient:trigger_auto(xmsg)",xmsg)

  local is_note_on = (xmsg.message_type == xMidiMessage.TYPE.NOTE_ON)
  local is_note_off = (xmsg.message_type == xMidiMessage.TYPE.NOTE_OFF)
  --print("is_note_on, is_note_off",is_note_on,is_note_off)

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
-- trigger 'raw MIDI' (makes notes MIDI-mappable)
-- @param xmsg (xMidiMessage or xOscMessage)
-- @return bool, true when triggered
-- @return string, error message when failed

function xOscClient:trigger_raw(xmsg)
  TRACE("xOscClient:trigger_raw(xmsg)",xmsg)

  assert(type(xmsg)=="xMidiMessage","Expected xMidiMessage as argument")

  if (xmsg.message_type == xMidiMessage.TYPE.SYSEX) then
    local err = "Warning: the internal OSC server does not support sysex messages"
    return false,err
  end

  local midi_msgs = xmsg:create_raw_message()
  for k,v in ipairs(midi_msgs) do
    self:trigger_midi(v)
  end

  return true

end


--------------------------------------------------------------------------------
--- Display usage instructions the first time the class is used

function xOscClient:_show_instructions()

  if self.first_run then
    self.first_run = false
    local msg = "IMPORTANT ONE-TIME MESSAGE"
              .."\n"
              .."\nTo be able to trigger instruments and send MIDI messages, the"
              .."\ninternal OSC server in Renoise needs to be enabled (go to "
              .."\nRenoise preferences > OSC settings to enable this feature)"
              .."\n"
              .."\nThanks!"
    renoise.app():show_message(msg)
  end

end

--------------------------------------------------------------------------------
-- Get/set methods
--------------------------------------------------------------------------------

function xOscClient:get_first_run()
  return self.first_run_observable.value
end

function xOscClient:set_first_run(val)
  self.first_run_observable.value = val
end

--------------------------------------------------------------------------------

function xOscClient:get_osc_host()
  return self.osc_host_observable.value
end

function xOscClient:set_osc_host(val)
  self.osc_host_observable.value = val
end

--------------------------------------------------------------------------------

function xOscClient:get_osc_port()
  return self.osc_port_observable.value
end

function xOscClient:set_osc_port(val)
  self.osc_port_observable.value = val
end

--------------------------------------------------------------------------------


