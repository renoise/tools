--[[----------------------------------------------------------------------------
-- Duplex.OscClient
----------------------------------------------------------------------------]]--

--[[

About 

  OscClient is a simple OSC client that connect to the built-in OSC server in 
  Renoise, producing realtime messages that trigger notes or send MIDI messages


--]]


--==============================================================================

class 'OscClient' 

--------------------------------------------------------------------------------

--- Initialize the OscClient class
-- @param osc_host (String) the host-address name (can be an IP address)
-- @param osc_port (Number) the host port

function OscClient:__init(osc_host,osc_port)

  -- the socket connection, nil if not established
  self._connection = nil

	--print("*** about to connect to the internal osc_server",osc_host,osc_port,type(osc_host),type(osc_port))
	local client, socket_error = renoise.Socket.create_client(osc_host, osc_port, renoise.Socket.PROTOCOL_UDP)
	if (socket_error) then 
    renoise.app():show_warning("Warning: Duplex failed to start the internal OSC client")
    self._connection = nil
	else
    self._connection = client
    --print("*** started the internal osc_server",osc_host,osc_port)
	end

end


--------------------------------------------------------------------------------

--- Trigger instrument-note
-- @param note_on (Boolean), true when note-on and false when note-off
-- @param instr (Number), the Renoise instrument index 
-- @param note (Number), the desired pitch
-- @param velocity (Number), the desired velocity

function OscClient:trigger_instrument(note_on,instr,track,note,velocity)
  TRACE("OscClient:trigger_instrument()",note_on,instr,track,note,velocity)
  
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

  --print("about to send internally routed note",header)
  --rprint(osc_vars)

  local osc_msg = renoise.Osc.Message(header,osc_vars)
  self._connection:send(osc_msg)

  return true

end

--------------------------------------------------------------------------------

--- Internal midi-message function, shared across applications
-- @param t (Table/MIDIMessage), a ready-to-send MIDI message

function OscClient:trigger_midi(t)
  TRACE("OscClient:trigger_midi()",t)
  
  if not self._connection then
    return false
  end

  --rprint(t)
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

--- Display usage instructions the first time the class is used

function OscClient:_show_instructions()

  if (duplex_preferences.osc_first_run.value) then
    duplex_preferences.osc_first_run.value = false
    local msg = "IMPORTANT ONE-TIME MESSAGE FROM DUPLEX"
              .."\n"
              .."\nTo be able to trigger instruments and send MIDI messages, the"
              .."\ninternal OSC server in Renoise needs to be enabled (go to "
              .."\nRenoise preferences > OSC settings to enable this feature)"
              .."\n"
              .."\nThanks!"
    renoise.app():show_message(msg)
  end

end

