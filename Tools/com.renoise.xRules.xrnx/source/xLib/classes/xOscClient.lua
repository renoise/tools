--[[============================================================================
-- Duplex.xOscClient
============================================================================]]--

--[[--

  xOscClient is a simple OSC client that connect to the built-in OSC server in Renoise, producing realtime messages that trigger notes or send MIDI messages


--]]

--==============================================================================

class 'xOscClient' 

--------------------------------------------------------------------------------


function xOscClient:__init(osc_host,osc_port,prefs)

  -- ScriptingToolPreferences, set this to specify global "preferences"
  -- (will display a message the first time a note message is sent)
  self.preferences = prefs 

  -- private --------------------------

  -- the socket connection, nil if not established
  self._connection = nil
  self._osc_host = nil
  self._osc_port = nil

  -- initialize -----------------------

  self:create(osc_host,osc_port)


end


--------------------------------------------------------------------------------

--- Initialize the xOscClient class
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

	local client, socket_error = renoise.Socket.create_client(osc_host, osc_port, renoise.Socket.PROTOCOL_UDP)
	if (socket_error) then 
    self._connection = nil
    return false, "Warning: failed to start the internal OSC client"
	else
    self._connection = client
    self._osc_host = osc_host
    self._osc_port = osc_port
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

function xOscClient:trigger_instrument(note_on,instr,track,note,velocity)
  TRACE("xOscClient:trigger_instrument()",note_on,instr,track,note,velocity)
  
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

function xOscClient:trigger_midi(t)
  TRACE("xOscClient:trigger_midi()",t)
  
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

--- Display usage instructions the first time the class is used

function xOscClient:_show_instructions()

  if self.preferences and
    self.preferences.osc_first_run.value 
  then
    self.preferences.osc_first_run.value = false
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

