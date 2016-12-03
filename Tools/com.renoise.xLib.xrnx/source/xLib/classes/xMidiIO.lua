--[[============================================================================
xMidiIO
============================================================================]]--

--[[--

Extend applications with MIDI input/output
.
#

Requires
xLib
cObservable
xMidiInput

]]

-------------------------------------------------------------------------------

require (_clibroot.."cObservable")

class 'xMidiIO' 

-------------------------------------------------------------------------------

function xMidiIO:__init(...)
  TRACE("xMidiIO:__init(...)")

	local args = cLib.unpack_args(...)

  assert(type(args.midi_callback_fn)=="function",
    "Required argument 'midi_callback_fn' missing")

  --- table<string> the ports to open 
  self.midi_inputs = property(self.get_midi_input,self.set_midi_inputs)
  self.midi_inputs_observable = renoise.Document.ObservableStringList()

  --- table<string> the ports to open 
  self.midi_outputs = property(self.get_midi_output,self.set_midi_output)
  self.midi_outputs_observable = renoise.Document.ObservableStringList()

  ---  xMidiInput
  self.interpretor = xMidiInput{
    multibyte_enabled = args.multibyte_enabled,
    nrpn_enabled = args.nrpn_enabled,
    terminate_nrpns = args.terminate_nrpns,
  }

  --- table<renoise.Midi.MidiInputDevice>
  self._midi_input_ports = {}

  --- table<renoise.Midi.MidiOutputDevice>
  self._midi_output_ports = {}

  -- initialize --

  if args.midi_inputs then
    self:set_midi_inputs(args.midi_inputs)
  end
  if args.midi_outputs then
    self:set_midi_outputs(args.midi_outputs)
  end

  self.interpretor.callback_fn = function(xmsg)
    args.midi_callback_fn(xmsg)
  end

  renoise.Midi.devices_changed_observable():add_notifier(function()
    self:initialize_midi_devices()
  end)

  self:initialize_midi_devices()

end

--------------------------------------------------------------------------------
-- open access to midi port 
-- @param port_name (string)

function xMidiIO:open_midi_input(port_name)
  TRACE("xMidiIO:open_midi_input(port_name)",port_name)

  assert(type(port_name),"string","Expected port_name to be a string")

  local input_devices = renoise.Midi.available_input_devices()
  if table.find(input_devices, port_name) then

    local port_available = (self._midi_input_ports[port_name] ~= nil)
    local port_open = port_available and self._midi_input_ports[port_name].is_open
    if port_available and port_open then
      -- don't create/open if already active
      return
    elseif port_available and not port_open then
      self._midi_input_ports[port_name]:close()
    end

    self._midi_input_ports[port_name] = renoise.Midi.create_input_device(port_name,
      function(midi_msg)
        if not xLib.is_song_available() then 
          return 
        end
        self:input_midi(midi_msg,port_name)
      end,
      function(sysex_msg)
        if not xLib.is_song_available() then 
          return 
        end
        self:input_sysex(sysex_msg,port_name)
      end
    )

    self.midi_inputs_observable = cObservable.list_add(self.midi_inputs_observable,port_name)

  else
    LOG("*** Could not create MIDI input device " .. port_name)
  end

end

--------------------------------------------------------------------------------
-- input raw midi messages here and pass them into xMidiInput
-- @param midi_msg (table), midi message
-- @param port_name (string)

function xMidiIO:input_midi(midi_msg,port_name)
  TRACE("xMidiIO:input_midi(midi_msg,port_name)",midi_msg,port_name)

  assert(type(midi_msg),"table","Expected midi_msg to be a table")
  assert(type(port_name),"string","Expected port_name to be a string")

  self.interpretor:input(midi_msg,port_name)

end

--------------------------------------------------------------------------------
-- input raw sysex messages here (immediately matched)
-- @param sysex_msg (table), sysex message
-- @param port_name (string)

function xMidiIO:input_sysex(sysex_msg,port_name)
  TRACE("xMidiIO:input_sysex(sysex_msg,port_name)")

  assert(type(sysex_msg),"table","Expected sysex_msg to be a table")
  assert(type(port_name),"string","Expected port_name to be a string")

  self:match_message(xMidiMessage{
    message_type = xMidiMessage.TYPE.SYSEX,
    values = sysex_msg,
    port_name = port_name,
  })

end

--------------------------------------------------------------------------------
-- @param port_name (string)

function xMidiIO:close_midi_input(port_name)
  TRACE("xMidiIO:close_midi_input(port_name)")

  assert(type(port_name),"string","Expected port_name to be a string")

  local midi_input = self._midi_input_ports[port_name] 
  if (midi_input and midi_input.is_open) 
  then
    midi_input:close()
  end

  self._midi_input_ports[port_name] = nil
  self.midi_inputs_observable = cObservable.list_remove(self.midi_inputs_observable,port_name)

end

--------------------------------------------------------------------------------
-- @param port_name (string)

function xMidiIO:open_midi_output(port_name)
  TRACE("xMidiIO:open_midi_output(port_name)")

  assert(type(port_name),"string","Expected port_name to be a string")

  local output_devices = renoise.Midi.available_output_devices()
  if table.find(output_devices, port_name) then
    self._midi_output_ports[port_name] = renoise.Midi.create_output_device(port_name)
  else
    LOG("*** Could not create MIDI output device " .. port_name)
  end

end

--------------------------------------------------------------------------------
-- @param port_name (string)

function xMidiIO:close_midi_output(port_name)
  TRACE("xMidiIO:close_midi_output(port_name)")

  assert(type(port_name),"string","Expected port_name to be a string")

  local midi_output = self._midi_output_ports[port_name] 
  if (midi_output and midi_output.is_open) 
  then
    midi_output:close()
  end

  self._midi_output_ports[port_name] = nil
  self.midi_outputs_observable = cObservable.list_remove(self.midi_outputs_observable,port_name)

end

--------------------------------------------------------------------------------
-- make sure the specified ports (and only those) are opened

function xMidiIO:initialize_midi_devices()
  TRACE("xMidiIO:initialize_midi_devices()")

  for k,v in ipairs(self._midi_input_ports) do
    self:close_midi_input(k)
  end

  for k,v in ipairs(self._midi_output_ports) do
    self:close_midi_output(k)
  end

  for k = 1, #self.midi_inputs_observable do
    local port_name = self.midi_inputs_observable[k].value
    self:open_midi_input(port_name)
  end

  for k = 1, #self.midi_outputs_observable do
    local port_name = self.midi_outputs_observable[k].value
    self:open_midi_output(v.value)
  end

end

--------------------------------------------------------------------------------
-- Get/set methods
--------------------------------------------------------------------------------

function xMidiIO:get_midi_inputs()
  return self.midi_inputs_observable
end

function xMidiIO:set_midi_inputs(val)
  self.midi_inputs_observable = val
end

--------------------------------------------------------------------------------

function xMidiIO:get_midi_outputs()
  return self.midi_outputs_observable
end

function xMidiIO:set_midi_outputs(val)
  self.midi_outputs_observable = val
end

