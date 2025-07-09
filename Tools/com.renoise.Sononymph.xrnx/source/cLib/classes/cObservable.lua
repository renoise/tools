--[[============================================================================
cObservable
============================================================================]]--

--[[--

Be 'smart' about observable properties in the Renoise API
.
#

This class tries to be clever and provide 'inside knowledge' about properties.
For example, the valid range of a "selected_instrument_index" is an integer with a minimum of 1

For now, we only care about the "first level" properties - the ones that belong to the song object. 

]]


class 'cObservable'

cObservable.SONG = {
  artist_observable = {type="string"},
  name_observable = {type="string"},
  comments_observable = {type="table",subclass="string"}, -- array of strings
  show_comments_after_loading_observable = {type="boolean"},
  instruments_observable = {type="table",subclass="Instrument"},
  patterns_observable = {type="table",subclass="Pattern"},
  tracks_observable = {type="table",subclass="Track"},
  selected_instrument_observable = {type="table",subclass="Instrument"},
  selected_instrument_index_observable = {type="number",subclass="integer",min=1},
  selected_phrase_observable = {type="table",subclass="InstrumentPhrase"},
  selected_phrase_index_observable = {type="number",subclass="integer",min=0},
  selected_sample_observable = {type="Sample"},
  selected_sample_modulation_set_observable = {type="SampleModulationSet"},
  selected_sample_device_chain_observable = {type="SampleDeviceChain"},
  selected_sample_device_observable = {type="AudioDevice"},
  selected_track_observable = {type="Track"},
  selected_track_index_observable = {type="number",subclass="integer",min=1},
  selected_track_device_observable = {type="AudioDevice"},
  --selected_device -- deprecated
  selected_parameter_observable = {type="DeviceParameter"},
  selected_automation_parameter_observable = {type="DeviceParameter"},
  selected_automation_device_observable = {type="AudioDevice"},
  selected_pattern_observable = {type="Pattern"},
  selected_pattern_index_observable = {type="number",subclass="integer",min=1},
  selected_pattern_track_observable = {type="PatternTrack"},
  selected_sequence_index_observable = {type="number",subclass="integer",min=1},
  selected_note_column_observable = {type="NoteColumn"},
  transport = {
    playing_observable = {type="boolean"},
    bpm_observable = {type="number",subclass="float",min=32,max=999},
    lpb_observable = {type="number",subclass="integer",min=1,max=256},
    tpl_observable = {type="number",subclass="integer",min=1,max=16},
    loop_pattern_observable = {type="boolean"},
    edit_mode_observable = {type="boolean"},
    edit_step_observable = {type="number",subclass="integer",min=0,max=64},
    octave_observable = {subclass="integer",min=0,max=8},
    metronome_enabled_observable = {type="boolean"},
    metronome_beats_per_bar_observable = {type="number",subclass="integer",min=1,max=16},
    metronome_lines_per_beat_observable = {type="number",subclass="integer",min=0,max=256}, -- 0 = songs current LPB
    metronome_precount_enabled_observable = {type="boolean"},
    metronome_precount_bars_observable = {type="number",subclass="integer",min=1,max=4},
    record_quantize_enabled_observable = {type="boolean"},
    record_quantize_lines_observable = {type="number",subclass="integer",min=1,max=32},
    record_parameter_mode_observable = {enum={
      renoise.Transport.RECORD_PARAMETER_MODE_PATTERN,
      renoise.Transport.RECORD_PARAMETER_MODE_AUTOMATION}},
    follow_player_observable = {type="boolean"},
    wrapped_pattern_edit_observable = {type="boolean"},
    single_track_edit_mode_observable = {type="boolean"},
    groove_enabled_observable = {type="boolean"},
    track_headroom_observable = {type="number",subclass="decibel"},
    keyboard_velocity_enabled_observable = {type="boolean"},
    keyboard_velocity_observable = {type="number",subclass="integer",min=0,max=127},
  },
  sequencer = {
    --:sequence_is_start_of_section_observable = 
    --:sequence_section_name_observable
    --:sequence_sections_changed_observable
    keep_sequence_sorted_observable = {type="boolean"},
    selection_range_observable = {type="table"}, -- array of two numbers
    pattern_sequence_observable = {type="table",subclass="integer"}, -- array of numbers
    pattern_assignments_observable = {type="Observable"}, -- ?? 
    pattern_slot_mutes_observable = {type="Observable"},
  },

}

--[[

-- refresh when SONG.tracks_observable change

cObservable.Track = {
  prefx_volume -> DeviceParameter
  prefx_panning -> DeviceParameter
  prefx_width -> DeviceParameter
  column_is_muted_observable
  column_name_observable
  name_observable
  color_observable,
  color_blend_observable
  mute_state_observable
  solo_state_observable
  collapsed_observable
  output_routing_observable
  output_delay_observable
  visible_effect_columns_observable
  visible_note_columns_observable
  volume_column_visible
  panning_column_visible
  delay_column_visible
  sample_effects_column_visible_observable
  devices__observable
}

cObservable.AudioDevice = {
  display_name_observable
  is_active_observable
  is_maximized_observable
  active_preset_observable
}

cObservable.DeviceParameter = {
  is_automated_observable
  is_midi_mapped_observable
  show_in_mixer_observable
  value_observable
  value_string_observable
}

]]

-- precomputed version
cObservable.SONG_BY_TYPE = {}

cObservable.MODE = {
  MANUAL = 1,
  AUTOMATIC = 2,
}

cObservable.mode = cObservable.MODE.MANUAL

-------------------------------------------------------------------------------
-- automatically attach to song (auto-renew registered observables)

function cObservable.set_mode(mode)

  if (cObservable.mode ~= mode) 
    and (cObservable.mode == cObservable.MODE.AUTOMATIC)
  then
    -- remove notifier
  end

  if (mode == cObservable.MODE.AUTOMATIC) then
    -- add notifier
  end

end

-------------------------------------------------------------------------------
-- get a specific type of observable 
-- @param str_type, string ("boolean","number" or "string")
-- @param array, list of cObservable descriptors
-- @return table or nil

function cObservable.get_by_type(str_type,array)

  if cObservable.SONG_BY_TYPE[str_type] then
    return cObservable.SONG_BY_TYPE[str_type]
  end

  if not array then
    array = cObservable.SONG
  end

  local t = {}
  for k,v in pairs(array) do
    if type(v) == "table" then
      if type(v.type) ~= "nil" and (v.type == str_type) then
        t[k] = v
      else
        t[k] = cObservable.get_by_type(str_type,v)
      end
    end
  end
  return not table.is_empty(t) and t or nil

end

-- precompute 
cObservable.SONG_BY_TYPE["boolean"] = cObservable.get_by_type("boolean")
cObservable.SONG_BY_TYPE["number"] = cObservable.get_by_type("number")
cObservable.SONG_BY_TYPE["string"] = cObservable.get_by_type("string")

-------------------------------------------------------------------------------
-- combine the above search with a match for a given name
-- @param str_type (string), one of xStreamArg.BASE_TYPES
-- @param str_obs (string), e.g. "transport.keyboard_velocity_enabled_observable"
-- @param str_prefix (string), e.g. "rns."

function cObservable.get_by_type_and_name(str_type,str_obs,str_prefix)

  -- strip away prefix
  if str_prefix then
    local s,e = string.find(str_obs,'^'..str_prefix)
    if s and e then
      str_obs = string.sub(str_obs,e+1)
    end
  end

  local matches = cObservable.get_by_type(str_type)

  -- break string into segments
  local obs_parts = cString.split(str_obs,"%.")
  local tmp = matches[obs_parts[1]]
  local target = tmp
  local count = 1
  while tmp do
    count = count + 1
    tmp = tmp[obs_parts[count]]
    if tmp then
      target = tmp
    end
  end

  return target or {}

end


-------------------------------------------------------------------------------
-- return a 'flattened' list of observable names, e.g.
-- "transport.keyboard_velocity_enabled_observable"
-- @param str_type (string), one of xStreamArg.BASE_TYPES
-- @param prefix (string), e.g. "rns."
-- @param arr (table) supply observables (when we got them)
-- @return table<string>

function cObservable.get_keys_by_type(str_type,prefix,arr)

  if not arr then
    arr = cObservable.get_by_type(str_type)
  end

  if not prefix then
    prefix = ""
  end

  local t = {}
  for k,v in pairs(arr) do
    if type(v) == "table" then
      if not v.type then
        prefix = prefix..k.."."
        local branch = cObservable.get_keys_by_type(str_type,prefix,v)
        for k2,v2 in ipairs(branch) do
          table.insert(t,v2)
        end
      else
        table.insert(t,prefix..k)
      end
    end
  end

  return t

end

--------------------------------------------------------------------------------
-- Remove notifier - wrap in protected call (when observables are gone)
-- supports all three combinations of arguments:
-- function or (object, function) or (function, object)
-- @param obs (renoise.Document.ObservableXXX)
-- @param arg1 (function or object)
-- @param arg2 (function or object)
-- @return bool, true when attached
-- @return string, error message when failed

function cObservable.detach(obs,arg1,arg2)

  local err 
  obs,err = cObservable.retrieve_observable(obs)
  if err then
    return false,err
  end

  local passed,err = pcall(function()
    if type(arg1)=="function" then
      local fn,obj = arg1,arg2
      if obj then
        if obs:has_notifier(fn,obj) then 
          obs:remove_notifier(fn,obj)
        end
      else
        if obs:has_notifier(fn) then 
          obs:remove_notifier(fn)
        end
      end
    elseif type(arg2)=="function" then
      local obj,fn = arg1,arg2
      if obs:has_notifier(obj,fn) then 
        obs:remove_notifier(obj,fn)
      end
    else
      error("Unsupported arguments")
    end
  end)

  return passed,err

end

--------------------------------------------------------------------------------
-- Add notifier, while checking for / removing existing one
-- supports all three combinations of arguments:
-- function or (object, function) or (function, object)
-- @param obs (renoise.Document.ObservableXXX)
-- @param arg1 (function or object)
-- @param arg2 (function or object)
-- @return bool, true when attached
-- @return string, error message when failed

function cObservable.attach(obs,arg1,arg2)
  
  local err = nil
  obs,err = cObservable.retrieve_observable(obs)
  if err then
    return false,err
  end

  cObservable.detach(obs,arg1,arg2)

  if type(arg1)=="function" then
    local fn,obj = arg1,arg2
    if obj then
      obs:add_notifier(fn,obj)
    else
      obs:add_notifier(fn)
    end
  elseif type(arg2)=="function" then
    local obj,fn = arg1,arg2
    obs:add_notifier(obj,fn)
  else
    error("Unsupported arguments")
  end

  return true

end

--------------------------------------------------------------------------------
-- support the use of string-based observable names
-- @param obs (string or ObservableXXX)
-- @return ObservableXXX

function cObservable.retrieve_observable(obs)

  local err
  if (type(obs)=="string") then
    obs,err = cLib.parse_str(obs)
    if err then
      return false,err
    end
  end
  return obs

end

--------------------------------------------------------------------------------
-- remove all entries from ObservableXXXList with specified value 

function cObservable.list_remove(obs,val)
  TRACE("cObservable.list_remove",obs,val)

  for k = 1,#obs do
    if obs[k] and (val == obs[k].value) then
      obs:remove(k)
    end
  end
  return obs

end

--------------------------------------------------------------------------------
-- add to ObservableXXXList when not already present

function cObservable.list_add(obs,val)
  TRACE("cObservable.list_add",obs,val)

  local exists = false
  for k = 1,#obs do
    if obs[k] and (val == obs[k].value) then
      exists = true
    end
  end
  if not exists then
    obs:insert(val)
  end
  return obs

end

--------------------------------------------------------------------------------
-- return table containing all names (using .dot syntax)

function cObservable.get_song_names(prefix)

  local rslt = {}
  local branches = {"transport","sequencer"}

  if not prefix then
    prefix = "rns." 
  end

  for k,v in pairs(cObservable.SONG) do
    if not table.find(branches,k) then
      table.insert(rslt,prefix..k)
    end
  end

  for k,v in pairs(branches) do
    for k2,v2 in pairs(cObservable.SONG[v]) do
      table.insert(rslt,prefix..v.."."..k2)
    end
  end

  table.sort(rslt)
  return rslt

end
