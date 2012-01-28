--[[----------------------------------------------------------------------------
-- Duplex.OscClient
----------------------------------------------------------------------------]]--

--[[

About 

  OscClient is a simply OSC client that connect to the built-in OSC server, producing realtime messages that trigger notes or send MIDI messages

  


--]]


--==============================================================================

class 'OscClient' 

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

-- internal sample-trigger function, shared across applications

function OscClient:_trigger_instrument(note_on,instr,track,note,velocity)
  TRACE("OscClient:_trigger_instrument(note_on,instr,track,note,velocity)",note_on,instr,track,note,velocity)
  
  if not self._connection then
    return false
  end

  local header = nil
  local osc_vars = table.create()
  osc_vars:insert({tag = "i",value = instr})
  osc_vars:insert({tag = "i",value = track})
  osc_vars:insert({tag = "i",value = note})

  if (note_on) then
    header = "/renoise/trigger/note_on"
    osc_vars:insert({tag = "i",value = velocity})
  else
    header = "/renoise/trigger/note_off"
  end

  --print("about to send internally routed note",header)
  --rprint(osc_vars)

  local osc_msg = renoise.Osc.Message(header,osc_vars)
  self._connection:send(osc_msg)

  return true

end

--------------------------------------------------------------------------------

-- internal midi-message function, shared across applications

function OscClient:_trigger_midi(val)
  TRACE("OscClient:_trigger_instrument(val)",val)
  
  if not self._connection then
    return false
  end

  local header = "/renoise/trigger/midi"
  local osc_vars = table.create()
  osc_vars:insert({tag = "i",value = val})

  --print("about to send internally routed midi message",header)
  --rprint(osc_vars)

  local osc_msg = renoise.Osc.Message(header,osc_vars)
  self._connection:send(osc_msg)

  return true

end
