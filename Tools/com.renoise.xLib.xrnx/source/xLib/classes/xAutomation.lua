--[[============================================================================
xAutomation
============================================================================]]--

--[[--

Easy control of parameter automation
.
#

### Requires
@{xPlayPos}

]]

class 'xAutomation'

xAutomation.FOLLOW_MODE = {
  AUTOMATIC = "automatic",
  EDIT_POS = "edit_pos",
  PLAY_POS = "play_pos",
}

--- How to write data into an envelope
-- INTERLEAVE: leave existing data as-is (renoise default)
-- PUNCH_IN: remove existing data (using writeahead)
-- (TODO) LATCH: keep erasing data ahead of play-position
xAutomation.WRITE_MODE = {
  INTERLEAVE = "interleave",
  PUNCH_IN = "punch_in",
}

--- Envelope interpolation
-- AUTOMATIC: use existing mode
-- POINTS: set to points mode
-- LINEAR: set to linear mode
-- CUBIC: set to cubic mode
xAutomation.PLAYMODE = {
  AUTOMATIC = 0,
  POINTS = 1,
  LINEAR = 2,
  CUBIC = 3,
}

xAutomation.PLAYMODE_NAMES = {
  "Automatic",
  "Points", 
  "Linear", 
  "Cubic", 
}

--------------------------------------------------------------------------------

function xAutomation:__init(...)

  local args = xLib.unpack_args(...)

  --- xAutomation.FOLLOW_MODE
  self.follow_mode = args.follow_mode or xAutomation.FOLLOW_MODE.AUTOMATIC

  --- xAutomation.WRITE_MODE
  self.write_mode = args.write_mode or xAutomation.WRITE_MODE.PUNCH_IN

  --- renoise.PatternTrackAutomation.PLAYMODE_xx
  -- (leave undefined to use current interpolation mode)
  self.playmode = args.playmode or xAutomation.PLAYMODE.AUTOMATIC

  --- boolean, whether to use fractional line-index or not
  self.highres_mode = args.highres_mode or false

  --- number, lines that we should clear 
  -- (this is automatically computed as tempo changes)
  self.writeahead = nil

  -- internal --

  self.playpos = xPlayPos()

  --- table, keep track of where we last recorded
  --  {
  --    track_idx = {
  --      [parameter] = {
  --        sequence (int)
  --        line (int)
  --      }
  --    }
  --  }
  --self.active_parameters = {}

  -- initialize --

  renoise.tool().app_idle_observable:add_notifier(function()
    self.playpos:update()
  end)

  renoise.tool().app_new_document_observable:add_notifier(function()
    self:attach_to_song()
  end)

  self:attach_to_song()

end

--------------------------------------------------------------------------------
-- Class methods
--------------------------------------------------------------------------------
--- add automation point at current time 
-- @param track_idx (int)
-- @param param (renoise.DeviceParameter)
-- @param value (number) the input value
-- @param value_mode (xMidiMessage.MODE) - apply scaling to the input value

function xAutomation:record(track_idx,param,value,value_mode)
  TRACE("xAutomation:record(track_idx,param,value,value_mode)",track_idx,param,value,value_mode)

  if not param.is_automatable then
    LOG("Could not write automation, parameter is not automatable")
    return
  end
  if not rns.tracks[track_idx] then
    LOG("Could not write automation, invalid track index #",track_idx)
  end

  if value_mode then
    value = xAutomation.get_scaled_value(value,value_mode)
  end

  local pos = self:get_position()
  local patt_idx = rns.sequencer.pattern_sequence[pos.sequence]
  if not patt_idx then
    LOG("Could not write automation, invalid sequence index #",pos.sequence)
  end
  local ptrack = rns.patterns[patt_idx]:track(track_idx)
  local ptrack_auto = xAutomation.get_or_create_automation(ptrack,param)

  if not rns.transport.playing or
    (self.follow_mode == xAutomation.FOLLOW_MODE.EDIT_POS)
  then
    -- always record 'on line' (no fraction)
    self:clear_range(pos.line,1,ptrack_auto)
    ptrack_auto:add_point_at(pos.line,value)
  else
    if self.highres_mode then
      local highres_pos = self.playpos:get_fractional()
      local line_fract = highres_pos.line + highres_pos.fraction
      self:clear_range(line_fract,self.writeahead,ptrack_auto)
      ptrack_auto:add_point_at(line_fract,value)
      --print("add point at",highres_pos.line + highres_pos.fraction,value)
    else
      self:clear_range(self.playpos.line,1,ptrack_auto)
      ptrack_auto:add_point_at(self.playpos.line,value)
    end
  end

  if (self.playmode ~= xAutomation.PLAYMODE.AUTOMATIC) then
    --print("self.playmode",self.playmode)
    ptrack_auto.playmode = self.playmode
  end

end

--------------------------------------------------------------------------------
-- check if automation exists for the given parameter

function xAutomation:has_automation(track_idx,param)

  if not rns.tracks[track_idx] then
    LOG("Could not write automation, invalid track index #",track_idx)
  end
  local pos = self:get_position()
  local patt_idx = rns.sequencer.pattern_sequence[pos.sequence]
  if not patt_idx then
    LOG("Could not write automation, invalid sequence index #",pos.sequence)
  end
  local ptrack = rns.patterns[patt_idx]:track(track_idx)
  local ptrack_auto = ptrack:find_automation(param)

  --print("ptrack_auto",ptrack_auto)
  return (ptrack_auto) and true or false

end

--------------------------------------------------------------------------------
-- clear automation for the given range
-- @param pos_from (int)
-- @param length (number), can be fractional
-- @param ptrack_auto (renoise.PatternTrackAutomation)

function xAutomation:clear_range(pos_from,length,ptrack_auto)
  
  if rns.transport.playing 
    and (self.write_mode == xAutomation.WRITE_MODE.INTERLEAVE) 
  then
    return
  end

  local pos_to = math.min(renoise.Pattern.MAX_NUMBER_OF_LINES,pos_from+length)
  ptrack_auto:clear_range(pos_from,pos_to)

end

--------------------------------------------------------------------------------
-- retrieve the correct SongPos object according to FOLLOW_MODE
-- @return int

function xAutomation:get_position()

  if (self.follow_mode == xAutomation.FOLLOW_MODE.AUTOMATIC) then
    if not rns.transport.playing then
      return rns.transport.edit_pos
    else
      return rns.transport.playback_pos
    end
  elseif (self.follow_mode == xAutomation.FOLLOW_MODE.EDIT_POS) then
    return rns.transport.edit_pos
  elseif (self.follow_mode == xAutomation.FOLLOW_MODE.PLAY_POS) then
    return rns.transport.playback_pos
  else
    error("Unexpected follow mode")
  end

end

--------------------------------------------------------------------------------

function xAutomation:attach_to_song()

  rns = renoise.song()

  rns.transport.bpm_observable:add_notifier(function()
    self:compute_writeahead()
  end)
  rns.transport.lpb_observable:add_notifier(function()
    self:compute_writeahead()
  end)
  self:compute_writeahead()

end

--------------------------------------------------------------------------------

function xAutomation:compute_writeahead()
  --TRACE("xAutomation:compute_writeahead()")

  self.writeahead = (rns.transport.bpm * rns.transport.lpb / 200)
  --print("self.writeahead",self.writeahead)

end


--------------------------------------------------------------------------------
-- Static methods
--------------------------------------------------------------------------------
-- get or create the parameter automation 

function xAutomation.get_or_create_automation(ptrack,param)

  local ptrack_auto = ptrack:find_automation(param)
  if not ptrack_auto then
    ptrack_auto = ptrack:create_automation(param)
  end
  return ptrack_auto

end

-------------------------------------------------------------------------------
-- Scale an incoming value to the automation range (0-1)
-- @param value (number)
-- @param value_mode (xMidiMessage.MODE), abs/rel + #bits
-- @return number

function xAutomation.get_scaled_value(value,value_mode)
  TRACE("xAutomation.get_scaled_value(value,value_mode)",value,value_mode)

  assert(type(value)=="number","Expected value to be a number")
  assert(type(value_mode)=="string","Expected value_mode to be a string")

  local val_min,val_max
  if value_mode then
    if value_mode:find("7") then
      val_min = 0 
      val_max = 127 
    elseif value_mode:find("14") then
      val_min = 0 
      val_max = 16383 
    else
      -- TODO
      LOG("Unexpected value_mode")
      return value
    end
  else
    -- floating point values etc.
    return value
  end
  
  return cLib.scale_value(value,val_min,val_max,0,1)

end

