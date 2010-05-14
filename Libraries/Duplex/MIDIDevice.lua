--[[----------------------------------------------------------------------------
-- Duplex.MIDIDevice
----------------------------------------------------------------------------]]--

--[[

Inheritance: MIDIDevice -> Device

Requires: Globals, ControlMap, Message

--]]

module("Duplex", package.seeall);

class 'MIDIDevice' (Device)

function MIDIDevice:__init(name)
--print("MIDIDevice:__init("..name..")")

	Device.__init(self, name, DEVICE_MIDI_PROTOCOL)

	self.midi_in = nil
	self.midi_out = nil

	local input_devices = renoise.Midi.available_input_devices()
	local output_devices = renoise.Midi.available_output_devices()

	if table.find(input_devices, name) then
	self.midi_in = renoise.Midi.create_input_device(name,
	  {self, MIDIDevice.midi_callback},
	  {self, MIDIDevice.sysex_callback}
	)
	else
		print("Notice: Could not create MIDI input device "..name)
	end

	if table.find(output_devices, name) then
		self.midi_out = renoise.Midi.create_output_device(name)
	else
		print("Notice: Could not create MIDI output device "..name)
	end


end

function MIDIDevice:release()
--print("MIDIDevice:release()")

	if self.midi_in and self.midi_in.is_open then
		self.midi_in:close()
	end
	
	if self.midi_out and self.midi_out.is_open then
		self.midi_out:close()
	end

	self.midi_in = nil
	self.midi_out = nil

end

function MIDIDevice:midi_callback(message)

	assert(#message == 3)
	assert(message[1] >= 0 and message[1] <= 0xff)
	assert(message[2] >= 0 and message[2] <= 0xff)    
	assert(message[3] >= 0 and message[3] <= 0xff)

	--print(("%s: func got MIDI %X %X %X"):format(self.name,message[1], message[2], message[3]))

	local msg = Message()
	local value_str = nil

	-- determine the type of signal : note/cc/etc
	if message[1] == 144 then
		msg.context = MIDI_NOTE_MESSAGE
		msg.value = message[3]
		value_str = self.note_to_string(self,message[2])
	elseif message[1] == 176 then
		msg.context = MIDI_CC_MESSAGE
		msg.value = message[3]
		value_str = self.midi_cc_to_string(self,message[2])
	end

	-- locate the relevant parameter in the control-map
	local param = self.control_map.get_param_by_value(self.control_map,value_str)

	if param then
		-- input method
		if param["xarg"].type == "button" then
			msg.input_method = CONTROLLER_BUTTON
		elseif param["xarg"].type == "encoder" then
			msg.input_method = CONTROLLER_ENCODER
		elseif param["xarg"].type == "fader" then
			msg.input_method = CONTROLLER_FADER
		end
		-- include additional meta-properties
		msg.name	= param["xarg"].name
		msg.group_name = param["xarg"].group_name
		msg.max		= param["xarg"].maximum+0
		msg.min		= param["xarg"].minimum+0
		msg.id		= param["xarg"].id
		msg.index	= param["xarg"].index
		msg.column	= param["xarg"].column
		msg.row		= param["xarg"].row
		msg.timestamp = os.clock()
	end

	self.message_stream:input_message(msg)

end


function MIDIDevice:sysex_callback(message)
--print(("%s: MidiDumper got SYSEX with %d bytes"):format(self.device_name, #message))
end


--	send CC message
--	@param number (int) the control-number (0-127)
--	@param value (int) the control-value (0-127)

function MIDIDevice:send_cc_message(number,value)
--print("MIDIDevice:send_cc_message",number,value)

	if not self.midi_out or not self.midi_out.is_open then
		return
	end

	self.midi_out:send({0xB0, number, value})
end


function MIDIDevice:send_note_message(key,velocity)
--print("MIDIDevice:send_note_message",key,velocity)

	if not self.midi_out or not self.midi_out.is_open then
		return
	end

	key = math.floor(key)
	velocity = math.floor(velocity)
--print("velocity",velocity)
	if velocity == 0 then
		self.midi_out:send({0x80, key, velocity})
--print("send note-off")
	else
		self.midi_out:send({0x90, key, velocity})
	end
end


-- convert MIDI note to string, range 0 (C--1) to 120 (C-9)
-- @param key: the key (7-bit integer)
-- @return string (e.g. "C#5")

function MIDIDevice:note_to_string(int)
--print("MIDIDevice:note_to_string",int)
	local key = (int%12)+1
	local oct = math.floor(int/12)-1
	return NOTE_ARRAY[key]..(oct)
end


function MIDIDevice:midi_cc_to_string(int)
	return string.format("CC#%d",int)
end


-- Extract MIDI message note-value (range C--1 to C9)
-- @param str	- string, e.g. "C-4" or "F#-1"
-- @return #note (7-bit integer)

function MIDIDevice:extract_midi_note(str) 
--print("MIDIDevice:extract_midi_note",str)
	local rslt = nil
	local note_segment = string.sub(str,0,2)
	local octave_segment = string.sub(str,3)
	for k,v in ipairs(NOTE_ARRAY) do 
		if(NOTE_ARRAY[k]==note_segment)then 
			if octave_segment == "-1" then
				rslt=(k-1)
			else
				rslt=(k-1)+(12*octave_segment)+12
			end
		end
	end
	return rslt
end


-- Extract MIDI CC number (range 0-127)
-- @return #cc (integer) 

function MIDIDevice:extract_midi_cc(str)
--print("MIDIDevice:extract_midi_cc",string.sub(str,4)+0)

	return string.sub(str,4)+0

end

-- Convert the point to an output value
-- (override with device-specific implementation)
function MIDIDevice:point_to_value(pt,maximum,minimum,ceiling)
--print("MIDIDevice:point_to_value:",pt,maximum,minimum,ceiling)

	if not ceiling then
		ceiling = 127
	end

	if(type(pt.val)=="boolean")then
		if pt.val then
			value = maximum
		else
			value = minimum
		end
	else
		-- scale the value from "local" to "external"
		-- for instance, from Renoise dB range (1.4125375747681) 
		-- to a 7-bit controller value (127)
		value = math.floor((pt.val*(1/ceiling))*maximum)
	end

	return value*1	-- toNumber

end
