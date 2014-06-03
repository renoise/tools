--[[============================================================================
-- Duplex.Automation
============================================================================]]--

--[[--

Provide generic automation features for Duplex applications

In the Renoise API, each pattern-track can contain a list of automation envelopes which are listed in order-of-arrival. This means that it's quite complicated to do something as simple as saying "write a point here for this parameter", because first you have to find the right envelope, or create it.

This class provides a much simpler way of writing automation, exposing just a single method, add_automation(). Provided with a track number, a parameter and a value, the rest happens automatically. If the continuous/latch recording mode is enabled, one also need to call the update() method with regular intervals to ensure that the envelope is being written ahead of the actual playback position. 

To set up the Automation class, you need to instantiate it in your application (the `__init()` method), and make sure that `attach_to_song()` is called when the application is initialized, and new songs are created. 

]]--

--==============================================================================

local rns = nil

--==============================================================================

class 'Automation'

Automation.FOLLOW_EDIT_POS = 1
Automation.FOLLOW_PLAY_POS = 2

--------------------------------------------------------------------------------

--- Initialize the Automation class

function Automation:__init()
  TRACE("Automation:__init")

  rns = renoise.song()

  --- (bool) set this to true when data is continuously output
  self.latch_record = false

  --- (bool) if true, recording will not cross pattern boundaries
  self.stop_at_loop = false

  --- (enum) leave undefined, or set to
  -- renoise.PatternTrackAutomation.PLAYMODE_POINTS
  -- renoise.PatternTrackAutomation.PLAYMODE_LINEAR
  -- renoise.PatternTrackAutomation.PLAYMODE_CUBIC
  self.preferred_playmode = nil

  --- (enum) how position is determined
  self.follow_pos = Automation.FOLLOW_EDIT_POS

  --- extrapolation strength, 3 is the default value
  -- range is from 1 and up, with higher values causing more overshooting
  -- (when recording, choose point envelopes to avoid extrapolation at all)
  self.extrapolate_strength = self:_get_extrapolation_strength()

  --- AutomationLane instances
  self._automations = table.create() 

  --- temporarily skip output while recording slider movements
  self._skip_updates = 1
  self._skip_update_count = 0

end


--------------------------------------------------------------------------------

--- Retrieve the extrapolation strength from Duplex setting

function Automation:_get_extrapolation_strength()
  return duplex_preferences.extrapolation_strength.value
end

--------------------------------------------------------------------------------

--- Update currently recording automation lanes
-- (this method is designed to be called from within an idle loop)

function Automation:update()
  --TRACE("Automation:update()")

  if not rns.transport.playing then
    return
  end

  if not self.latch_record then
    return
  end

  -- we skip constant updates while actively changing values
  self._skip_update_count = math.max(0,self._skip_update_count-1)
  if(self._skip_update_count>0) then
    --print("self._skip_update_count",self._skip_update_count)
    return
  end

  -- the higher the tempo, the greater writeahead
  local lpb = rns.transport.lpb
  local bpm = rns.transport.bpm
  local writeahead_amount = 0
  --if rns.transport.follow_player then
    writeahead_amount = math.max(2,math.floor((lpb*bpm)/300))
  --end

  -- status message
  local msg = "Automation recording "

  -- find and output automation 
  local seq_idx = self:get_current_seq_index()
  local patt_idx = rns.sequencer.pattern_sequence[seq_idx]
  for k,v in ipairs(self._automations) do
    local auto_idx = v.map:get(seq_idx)
    if auto_idx then
      local ptrack = rns.patterns[patt_idx]:track(v.track_idx)
      local automation = ptrack.automation[math.abs(auto_idx)]
      if automation then
        msg = string.format("%s %s (%d), ",msg,v.parameter.name,v.track_idx)
        self:writeahead(writeahead_amount,automation,v)
      else
        LOG("*** expected automation")
      end
    end
  end

  -- see which parameters are actively being recorded
  renoise.app():show_status(msg)
  

end

--------------------------------------------------------------------------------

--- Add a point at current time (will add new automations on the fly)
-- @param track_idx (int) the track index
-- @param parameter (DeviceParameter object)
-- @param value (number between 0-1)
-- @param playmode (enum), renoise.PatternTrackAutomation.PLAYMODE_xxx

function Automation:add_automation(track_idx,parameter,value,playmode)
  TRACE("Automation:add_automation",track_idx,parameter,value,playmode)

  if not parameter.is_automatable then
    LOG("Could not write automation, parameter is not automatable")
    return
  end
  if not rns.tracks[track_idx] then
    LOG("Could not write automation, invalid track index #",track_idx)
  end

  local seq_idx = self:get_current_seq_index()
  local patt_idx = rns.sequencer.pattern_sequence[seq_idx]
  if not patt_idx then
    LOG("Could not write automation, invalid sequence index #",seq_idx)
  end
  local ptrack = rns.patterns[patt_idx]:track(track_idx)

  -- (latch mode) if set, we create automation once there is a notifier
  local create_automation = false

  -- check if the parameter is automated, create if not
  local ptrack_auto = ptrack:find_automation(parameter)
  --print("*** add_automation - ptrack_auto A",ptrack_auto)
  if not ptrack_auto then
    ptrack_auto = ptrack:create_automation(parameter)
    -- when the automation class is first instantiated, the 
    -- ptrack instance may not appear and we abort
    if not ptrack_auto then
      TRACE("Automation:add_automation() - could not create automation")
      return
    end
    if self.latch_record then
      create_automation = true
    end
  else
    --print("*** add_automation - ptrack_auto B",ptrack_auto)
  end

  local line = self:get_current_line()

  if self.preferred_playmode then
    ptrack_auto.playmode = self.preferred_playmode
  end

  -- touch mode, write to pattern and return
  if not self.latch_record then
    --print("*** add_automation - touch mode: add point at ",line,value)
    self:add_point(ptrack_auto,line,value,nil,playmode)
    return
  end

  --= latch mode =-- 

  -- skip constant output while changing value
  self._skip_update_count = self._skip_updates

  -- locate the AutomationLane (if any), store our value...
  local lane = nil
  local add_notifier = false
  for k,v in ipairs(self._automations) do
    if rawequal(parameter,v.parameter) then
      lane = self._automations[k]
      lane.old_value = lane.value
      if not lane.older_value then
        lane.older_value = lane.value
      end
      lane.value = value

      -- check if pattern-track needs automation observable
      local auto_idx = v.map:get(seq_idx)
      if auto_idx then
        -- if negative index, add observable (see find_or_create)
        if (math.abs(auto_idx)~=auto_idx) then
          add_notifier = true
          v.map:set(seq_idx,math.abs(auto_idx))
        else
          add_notifier = false
        end
      end

      break
    end
  end

  -- define notifier handler as local function
  -- in order to pick up the "pseudo-context" (track index, seq_idx):
  -- however this is not always reliable, which is why the
  -- automation class is still to be considered experimental
  local automation_handler = function(notifier)
    TRACE("Automation:automation_observable fired...",notifier)

    -- this is a pseudo-value, will only work for as 
    -- long as the current pattern is also the one that
    -- we are recording automation to...
    seq_idx = self:get_current_seq_index()

    if (notifier.type=="insert") then

      local patt_idx = rns.sequencer.pattern_sequence[seq_idx]
      local ptrack = rns.patterns[patt_idx]:track(track_idx)
      --local ptrack = pattern:track(automation_lane.track_idx)
      --local ptrack_auto = rns.selected_pattern_track.automation[notifier.index]
      local ptrack_auto = ptrack.automation[notifier.index]
      local param_name = ptrack_auto.dest_parameter.name
      local device_name = ptrack_auto.dest_device.name

      -- attempt to capture the index
      for k,v in ripairs(self._automations) do
        if rawequal(parameter,v.parameter) then
          if v.map:get(seq_idx) then
            v.map:set(seq_idx,notifier.index)
            --print("*** automation index captured",notifier.index,"v.parameter.name",v.parameter.name)
          end
        end
      end
      -- find the most recently added AutomationLane
      local lane = self._automations[#self._automations]
      if lane and not lane.map:get(seq_idx) then
        -- we couldn't capture the automation index, so perform this
        -- ugly workaround: provide last added index as "fallback"
        lane.map:set(seq_idx,notifier.index)
        --print("*** assigned fall-back idx ",notifier.index,"parameter.name",parameter.name)
      end
    elseif (notifier.type=="remove") then
      --self:stop_automation()
    end
  end


  if lane then
    self:add_point(ptrack_auto,line,value,nil,playmode)
    if add_notifier then
      lane.observables:insert(ptrack.automation_observable)
      ptrack.automation_observable:add_notifier(self,automation_handler)
      --print("*** add_automation - add notifier to existing lane",#lane.observables)
    end
  else

    local device = self:get_device_by_param(track_idx,parameter)

    -- create new AutomationLane
    local a = AutomationLane()
    self._automations:insert(a)
    a.observables:insert(ptrack.automation_observable)
    ptrack.automation_observable:add_notifier(self,automation_handler)
    --print("*** new lane/notifier added",#self._automations)

    -- these need to be set before we trigger the notifier,
    -- in order to capture index more reliably
    a.track_idx = track_idx
    a.parameter = parameter
    a.device_name = device.name
    a.value = value

    if create_automation then
      -- now that the notifier has been attached, 
      -- we can capture the automation index 
      ptrack:delete_automation(parameter)
      ptrack_auto = ptrack:create_automation(parameter)
    else
      -- automation data already exist
      local auto_idx = self:get_automation_index(ptrack,ptrack_auto)
      a.map:set(seq_idx,auto_idx)
    end

    self:add_point(ptrack_auto,line,value,nil,playmode)

  end


end


--------------------------------------------------------------------------------

--- Retrieve the current line 
-- @return int

function Automation:get_current_line()

  local line = nil
  if (self.follow_pos == Automation.FOLLOW_EDIT_POS) then
    line = rns.transport.edit_pos.line
  elseif (self.follow_pos == Automation.FOLLOW_PLAY_POS) then
    line = rns.transport.playback_pos.line
  end

  return line

end

--------------------------------------------------------------------------------

--- Retrieve the current sequence index
-- @return int

function Automation:get_current_seq_index()

  local seq_idx = nil
  if (self.follow_pos == Automation.FOLLOW_EDIT_POS) then
    seq_idx = rns.transport.edit_pos.sequence
  elseif (self.follow_pos == Automation.FOLLOW_PLAY_POS) then
    seq_idx = rns.transport.playback_pos.sequence
  end
  return seq_idx

end

--------------------------------------------------------------------------------

--- This method is an enhanced version of add_point_at(), as it will wrap at 
--  pattern boundaries and create automation on the fly
-- @param ptrack_auto (PatternTrackAutomation)
-- @param line (int), line in pattern
-- @param value (number), between 0 and 1
-- @param automation_lane (AutomationLane), when called from update()
-- @param playmode (enum), [optional] renoise.PatternTrackAutomation.PLAYMODE_xxx

function Automation:add_point(ptrack_auto,line,value,automation_lane,playmode)
  TRACE("Automation:add_point()",ptrack_auto,line,value,automation_lane,playmode)

  local seq_idx = self:get_current_seq_index()
  local patt_idx = rns.sequencer.pattern_sequence[seq_idx]
  local pattern = rns.patterns[patt_idx]
  local seq_loop_end = rns.transport.loop_sequence_end
  local seq_loop_start = rns.transport.loop_sequence_start

  if playmode and (ptrack_auto.playmode ~= playmode) then
    --print("switched playmode from/to",ptrack_auto.playmode,playmode)
    ptrack_auto.playmode = playmode
  end

  if (line <= pattern.number_of_lines) then
    -- normal point
    ptrack_auto:add_point_at(line,value)
  else
    -- extend/wrap in patterns
    if automation_lane then

      -- set to true when we want to register automation as
      -- "waiting for observable", not true when we are
      -- repeating/looping the same pattern
      local register = true

      local stop_recording = true
      local next_seq_idx = seq_idx+1
      local line = line-pattern.number_of_lines
      if (rns.transport.loop_pattern) then
        next_seq_idx = seq_idx
        register = false
        --print("same pattern")
      elseif (seq_loop_end==seq_idx) then
        next_seq_idx = seq_loop_start
        register = false
        --print("pattern loop")
      elseif rns.sequencer.pattern_sequence[next_seq_idx] then 
        --print("next pattern")
        stop_recording = false
      else
        next_seq_idx = 1
        --print("end of song")
      end
      if stop_recording and self.stop_at_loop then
        self:stop_automation()
      else
        local pattern = rns.patterns[next_seq_idx]
        if pattern then
          local ptrack = pattern:track(automation_lane.track_idx)
          local ptrack_au2 = self:find_or_create(ptrack,automation_lane,next_seq_idx,register)
          if ptrack_au2 then
            ptrack_au2:add_point_at(line,value)
            --print("add_point_at (B)",line,value)
          end
        end
      end
    end
  end

end



--------------------------------------------------------------------------------

--- "Write-ahead" using extrapolated values
-- (enabled when dealing with cubic/linear envelopes)
-- @param amount (int), number of extrapolated points, 0 and up
-- @param ptrack_auto (renoise.PatternTrackAutomation)
-- @param lane (AutomationLane)

function Automation:writeahead(amount,ptrack_auto,lane)
  TRACE("Automation:writeahead()",amount,ptrack_auto,lane)
  
  local points_mode = (ptrack_auto.playmode == 
    renoise.PatternTrackAutomation.PLAYMODE_POINTS)

  local line = self:get_current_line()

  local inc = 0
  if lane.old_value then
    inc = ((lane.value-average(lane.old_value,lane.older_value))/amount)*self.extrapolate_strength
    lane.older_value = lane.old_value
    lane.old_value = nil
  end
  if points_mode then
    inc=0
  end
  for i=0,amount do
    self:add_point(ptrack_auto,line+i,math.max(0,math.min(1,lane.value+(inc*i) )),lane)
  end

end


--------------------------------------------------------------------------------

--- Find_or_create will always return a PatternTrackAutomation index when
-- provided with a valid PatternTrack. The PatternTrackAutomation object is 
-- created on-the-fly if not already present
-- note: when playback progress into pattern that does not (yet) contain 
-- any automation, supply a negative value ("waiting for observable")
-- @param ptrack (PatternTrack)
-- @param autolane (AutomationLane)
-- @param seq_idx (int) the sequence index
-- @param register (bool) register as "waiting for observable"
-- @return (int), the resulting index

function Automation:find_or_create(ptrack,autolane,seq_idx,register)
  TRACE("Automation:find_or_create",ptrack,autolane,seq_idx,register)

  local ptrack_auto = ptrack:find_automation(autolane.parameter)
  if not ptrack_auto then
    -- create automation
    ptrack_auto = ptrack:create_automation(autolane.parameter)
  end
  local auto_idx = nil
  if register then
    auto_idx = self:get_automation_index(ptrack,ptrack_auto)
    if auto_idx then
      --print("find_or_create() - register here: seq_idx",seq_idx,"auto_idx",auto_idx,"ptrack_auto",ptrack_auto)
      autolane.map:set(seq_idx,-auto_idx)
    end
  end
  return ptrack_auto

end


--------------------------------------------------------------------------------

--- Figure out the track automation's index
-- @param ptrack (PatternTrack)
-- @param ptrack_auto (PatternTrackAutomation)
-- @return (int) the automation index

function Automation:get_automation_index(ptrack,ptrack_auto)
  TRACE("Automation:get_automation_index",ptrack,ptrack_auto)

  for k,v in ipairs(ptrack.automation) do
    if rawequal(v,ptrack_auto) then
      return k
    end

  end

end

--------------------------------------------------------------------------------

--- Figure out the device by supplying a parameter 
-- @param track_idx (int)
-- @param parameter (DeviceParameter)
-- @return TrackDevice

function Automation:get_device_by_param(track_idx,parameter)
  TRACE("Automation:get_device_by_param",track_idx,parameter)

  local track = rns.tracks[track_idx]
  for _,device in ipairs(track.devices) do
    for __,param in ipairs(device.parameters) do
      if rawequal(param,parameter) then
        return device
      end
    end
  end

end


--------------------------------------------------------------------------------

--- Stop all currently recording automation

function Automation:stop_automation()
  TRACE("Automation:stop_automation()")

  self:_remove_notifiers()
  self._automations:clear()

end

--------------------------------------------------------------------------------

--- Attach to song (call this from the host application)

function Automation:attach_to_song(new_song)
  TRACE("Automation:attach_to_song() new_song",new_song)

  rns = renoise.song()

  -- first, remove automation observables
  self:_remove_notifiers(new_song)

  -- when playback progress into new pattern, find or create automation
  rns.selected_sequence_index_observable:add_notifier(
    function() 
      TRACE("Automation:selected_sequence_index_observable fired...")

      local seq_idx = rns.selected_sequence_index

      for k,v in ipairs(self._automations) do
        
        if not v.map:get(seq_idx) then
          local ptrack = rns.selected_pattern_track
          self:find_or_create(ptrack,v,seq_idx,true)
        end

      end
    end 
  )

  -- when pattern sequence is changed, adjust automation index 
  rns.sequencer.pattern_sequence_observable:add_notifier(
    function(obj)
      TRACE("Automation:pattern_sequence_observable fired...")
      if (obj.type=="insert") then
        for k,v in ipairs(self._automations) do
          v.map:insert(obj.index,v.track_idx)
        end
      elseif (obj.type=="remove") then
        for k,v in ipairs(self._automations) do
          if v.map:get(obj.index) then
            v.map:remove(obj.index)
          end
        end
      end
    end
  
  )

  -- when tracks are changed, adjust track index 
  rns.tracks_observable:add_notifier(
    function(obj)
      TRACE("Automation:tracks_observable fired...")
      if (obj.type=="insert") then
        for k,v in ripairs(self._automations) do
          -- shift up
          if (v.track_idx>=obj.index) then
            v.track_idx = v.track_idx+1
            --print("track shifted up",v.track_idx)
          end
        end
      elseif (obj.type=="remove") then
        for k,v in ripairs(self._automations) do
          -- shift down
          if (v.track_idx==obj.index) then
            -- remove this AutomationLane
            self._automations:remove(k)
            --print("removed this lane",k)
          elseif (v.track_idx>=obj.index) then
            v.track_idx = v.track_idx-1
            --print("track shifted down",v.track_idx)
          end
        end
      elseif (obj.type=="swap") then
        for k,v in ripairs(self._automations) do
          if (v.track_idx==obj.index1) then
            v.track_idx = obj.index2
            --print("tracks swapped A",v.track_idx)
          elseif (v.track_idx==obj.index2) then
            v.track_idx = obj.index1
            --print("tracks swapped B",v.track_idx)
          end
        end
      end
    end
  
  )

  -- just give us an excuse to stop recording!

  rns.transport.edit_mode_observable:add_notifier(
    function()
      TRACE("Automation:edit_mode_observable fired...")
      if not rns.transport.edit_mode then
        self:stop_automation()  
      end
    end
  )

  rns.transport.playing_observable:add_notifier(
    function()
      TRACE("Automation:playing_observable fired...",rns.transport.playing)
      if not rns.transport.playing then
        self:stop_automation()
      end
    end
  )

end

--------------------------------------------------------------------------------

--- Remove all notifiers associated with this class instance
-- @param new_song (bool) if defined, do not attempt to remove notifiers

function Automation:_remove_notifiers(new_song)
  TRACE("Automation:_remove_notifiers()",new_song)

  for _,autolane in ipairs(self._automations) do
    if (not new_song) then
      for __,observable in ipairs(autolane.observables) do
        --print("about to remove _automation_observable ",observable)
        pcall(function() observable:remove_notifier(self) end)
      end
    end
    autolane.observables:clear()
  end

end

--==============================================================================

--- Logical automation lane, represents an ongoing automation

class 'AutomationLane'

function AutomationLane:__init()
  TRACE("AutomationLane:__init()")

  self.observables = table.create() --- list of active observables
  self.map = AutomationMap()  --- automation indices are kept here
  self.parameter = nil      -- DeviceParameter
  self.track_idx = nil      -- track index
  self.device_name = nil    -- string (pseudo-value)
  self.value = nil          -- current value, between 0-1
  self.old_value = nil      -- used for extrapolating,
  self.older_value = nil    -- smoothing 


end

--==============================================================================

--- The 'AutomationMap' contains the table of pattern-track automation indices 
-- for each AutomationLane, ordered by sequence index

class 'AutomationMap'

function AutomationMap:__init()
  TRACE("AutomationMap:__init()")
  self.map = {}

end

function AutomationMap:set(seq_idx,value)
  self.map[seq_idx] = value
end

function AutomationMap:get(seq_idx)
  return self.map[seq_idx]
end

function AutomationMap:insert(seq_idx)
  TRACE("AutomationMap:insert",seq_idx)
  table.insert(self.map,seq_idx,self:get(seq_idx-1))
end

function AutomationMap:remove(seq_idx)
  TRACE("AutomationMap:remove",seq_idx)
  table.remove(self.map,seq_idx)
end


