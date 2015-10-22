--[[============================================================================
xObservable
============================================================================]]--
--[[

  Offer 'inside knowledge' about observable properties in the Renoise API
  (for example, the valid range of a "selected_instrument_index" is an 
  integer with a minimum of 1). 

  For now, we only care about the "first level" properties - the ones that
  belong to the song object. 

]]


class 'xObservable'

--[[
xObservable.TYPES = {
  "integer",
  "float",
  "boolean",
  "string",
  "decibel",
}
]]

xObservable.SONG = {
  artist_observable = {type="string"},
  name_observable = {type="string"},
  selected_instrument_index_observable = {type="number",subclass="integer",min=1},
  selected_track_index_observable = {type="number",subclass="integer",min=1},
  selected_pattern_index_observable = {type="number",subclass="integer",min=1},
  selected_sequence_index_observable = {type="number",subclass="integer",min=1},
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
  }
}

-- precomputed version
xObservable.SONG_BY_TYPE = {}



-------------------------------------------------------------------------------

function xObservable.get_by_type(str_type,array)
  TRACE("xObservable.get_by_type(str_type)",str_type)

  if xObservable.SONG_BY_TYPE[str_type] then
    return xObservable.SONG_BY_TYPE[str_type]
  end

  if not array then
    array = xObservable.SONG
  end

  local t = {}
  for k,v in pairs(array) do
    if type(v) == "table" then
      if type(v.type) ~= "nil" and (v.type == str_type) then
        t[k] = v
      else
        t[k] = xObservable.get_by_type(str_type,v)
      end
    end
  end
  return not table.is_empty(t) and t or nil

end

-- precompute 
xObservable.SONG_BY_TYPE["boolean"] = xObservable.get_by_type("boolean")
xObservable.SONG_BY_TYPE["number"] = xObservable.get_by_type("number")
xObservable.SONG_BY_TYPE["string"] = xObservable.get_by_type("string")

-------------------------------------------------------------------------------
-- combine the above search with a match for a given name
-- @param str_type (string), one of xStreamArg.BASE_TYPES
-- @param obs (string), e.g. "transport.keyboard_velocity_enabled_observable"

function xObservable.get_by_type_and_name(str_type,str_obs,str_prefix)
  TRACE("xObservable.get_by_type_and_name(str_type,str_obs,str_prefix)",str_type,str_obs,str_prefix)

  -- strip away prefix
  if str_prefix then
    local s,e = string.find(str_obs,'^'..str_prefix)
    if s and e then
      str_obs = string.sub(str_obs,e+1)
    end
  end

  local matches = xObservable.get_by_type(str_type)
  --print(">>> matches",matches,#matches)

  -- break string into segments
  local obs_parts = xLib.split(str_obs,"%.")
  local tmp = matches[obs_parts[1]]
  local target = tmp
  --print(">>> target PRE",target,rprint(target))
  local count = 1
  while tmp do
    count = count + 1
    tmp = tmp[obs_parts[count]]
    if tmp then
      target = tmp
    end
  end

  --print(">>> target POST",rprint(target))
  return target or {}

end


-------------------------------------------------------------------------------
-- return a 'flattened' list of observable names, e.g.
-- "transport.keyboard_velocity_enabled_observable"
-- @param str_type (string), one of xStreamArg.BASE_TYPES
-- @return table<string>

function xObservable.get_keys_by_type(str_type,prefix,arr)

  if not arr then
    arr = xObservable.get_by_type(str_type)
  end

  if not prefix then
    prefix = ""
  end

  local t = {}
  for k,v in pairs(arr) do
    if type(v) == "table" then
      if not v.type then
        prefix = prefix..k.."."
        local branch = xObservable.get_keys_by_type(str_type,prefix,v)
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
