--[[============================================================================
MP_Instrument
============================================================================]]--
--[[

This class describes a single managed instrument in MidiPerformer
.
#

]]

-------------------------------------------------------------------------------

class 'MP_Instrument'

function MP_Instrument:__init(...)

  local args = cLib.unpack_args(...) 

  -- check for required arguments 
  assert(type(args.instr_index)=="number")
  assert(type(args.owner)=="MidiPerformer")

  --- MidiPerformer, application instance   
  self.owner = args.owner

  --- number, required
  self.instr_index = args.instr_index

  --- TODO string, a copy of the track-index
  -- (because instrument itself might temporarily be routed 
  -- to alternative group/master track while in edit_mode) 
  self.track_index = args.track_index

  --- boolean, specify if instrument is manually armed
  -- (applies when not autoarmed or disabled)
  self.manual_arm = args.manual_arm or false

  --- MidiPerformer.STATE, the current state 
  -- (value is managed by the application)
  self.state = MidiPerformer.STATE.UNDEFINED

  --- MP_Prefs, current settings
  self.prefs = renoise.tool().preferences

end

-------------------------------------------------------------------------------
-- return data suitable for display in table

function MP_Instrument:get_expanded()

  local instr = rns.instruments[self.instr_index]
  assert(instr,"Could not locate instrument")

  local track_idx = xInstrument.resolve_midi_track(instr)
  local state = self:determine_state() 
  local manual_arm = self.manual_arm and "Manual" 
    or (self.prefs.autoarm_on_edit_enable.value
      and rns.transport.edit_mode) and "Auto"   
  local state_name = (state == MidiPerformer.STATE.UNARMED) and "Off"
    or (state == MidiPerformer.STATE.ARMED) and manual_arm
    or (state == MidiPerformer.STATE.MUTED) and "Muted"
    or (state == MidiPerformer.STATE.SILENT) and "Silent"
  local instr_name = (instr.name and instr.name~="") and instr.name or "(untitled)" 
  local midi_port_idx = table.find(renoise.Midi.available_input_devices(),instr.midi_input_properties.device_name) or 0
  local label = ("%.2X: %s"):format(self.instr_index-1,instr_name)
  
  return {
    REMOVE = "⨯",
    STATE = state_name,
    LABEL = label,
    INSTR_INDEX = self.instr_index,
    MIDI_IN = midi_port_idx+1,
    MIDI_CHANNEL = instr.midi_input_properties.channel,
    MIDI_NOTE_FROM = instr.midi_input_properties.note_range[1],
    MIDI_NOTE_TO = instr.midi_input_properties.note_range[2],
    MIDI_TRACK = self.track_index 
      and self.track_index+1 
      or instr.midi_input_properties.assigned_track+1,    
  }


end

--------------------------------------------------------------------------------
-- @param only_arm (boolean), check un/armed state only (skip checks for
-- silenced/muted modes)

function MP_Instrument:determine_state(only_arm)
  TRACE("MP_Instrument:determine_state")
  
  local instr = rns.instruments[self.instr_index]
  assert(instr,"Could not locate instrument")

  local track_idx = xInstrument.resolve_midi_track(instr)
  local track = rns.tracks[track_idx]
  assert(track,"Could not locate track")

  if not only_arm then
    if (self.prefs.disable_when_track_silent.value) then
      if (track.prefx_volume.value == 0) then
        return MidiPerformer.STATE.SILENT
      end
    end
    if (self.prefs.disable_when_track_muted.value) then
      if (track.mute_state ~= renoise.Track.MUTE_STATE_ACTIVE) then
        return MidiPerformer.STATE.MUTED
      end
    end
  end
  if (self.prefs.autoarm_on_edit_enable.value) 
    and rns.transport.edit_mode
    and not self.manual_arm
  then
    return MidiPerformer.STATE.ARMED
  elseif self.manual_arm then
    return MidiPerformer.STATE.ARMED
  end
  return MidiPerformer.STATE.UNARMED

end

--------------------------------------------------------------------------------

function MP_Instrument:__tostring()

  return type(self)
    ..", instr_index="..tostring(self.instr_index)
    ..", manual_arm="..tostring(self.manual_arm)
    ..", state="..tostring(self.state)

end
