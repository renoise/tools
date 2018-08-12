--[[===============================================================================================
-- AutoMateGenerator.lua
===============================================================================================]]--

--[[--

This class is able to generate xEnvelopes.

--]]

--=================================================================================================

class 'AutoMateGenerator' (AutoMateSandbox)

-- cPersistence
AutoMateGenerator.__PERSISTENCE = {
  "name",
  "arguments",
  "callback",
}

---------------------------------------------------------------------------------------------------

function AutoMateGenerator:__init()
  TRACE("AutoMateGenerator:__init()")

  AutoMateSandbox.__init(self)

  -- as a convenience, initialize the point with time and playmode
  self.sandbox.str_prefix = self.sandbox.str_prefix .. [[
-------------------------------------------------------------------------------
-- determine time 
-------------------------------------------------------------------------------
if (points_per_line > 0) then 
  -- positive PPL: one or more points per line 
  local time_offset = 1-(1/points_per_line)
  point.time = (index/points_per_line)+time_offset
else
  -- negative PPL: skip every nth line 
  local time_offset = points_per_line+1
  point.time = (index*math.abs(points_per_line))+time_offset
end
-------------------------------------------------------------------------------
-- set playmode (interpolation type)
-------------------------------------------------------------------------------
point.playmode = args.playmode    
  ]]

end

---------------------------------------------------------------------------------------------------

function AutoMateGenerator:__tostring()
  return type(self)
end

---------------------------------------------------------------------------------------------------
-- generate envelope data 
-- @param range_or_length (xSequencerSelection | number) restrict to this range/length
--  note: the value implies the target type (DEVICE_PARAMETER or CUSTOM_ENVELOPE)
-- @param playmode (renoise.PatternTrackAutomation.PLAYMODE_XX) force interpolation type
-- @param yield_at (xLib.YIELD_AT) for sliced processing 
-- @return xEnvelope or nil 

function AutoMateGenerator:generate(range_or_length,playmode,yield_at)
  TRACE("AutoMateGenerator:generate(range_or_length,playmode,yield_at)",range_or_length,playmode,yield_at)

  if not playmode then 
    playmode = renoise.PatternTrackAutomation.PLAYMODE_LINEAR
  end


  -- configure xSongPos (no looping / boundary checks)
  local xpos = nil
  local xpos_bounds = xSongPos.OUT_OF_BOUNDS.NULL
  local xpos_loop = xSongPos.LOOP_BOUNDARY.NONE
  local xpos_block = xSongPos.BLOCK_BOUNDARY.NONE
  
  -- figure out how many points to create 
  local num_points = nil

  -- line_increment (for each point, depends on points_per_line)
  local line_inc = 1

  -- points-per-line (negative number to specify every nth line)
  --  note: only used when range_or_length is xSequencerSelection
  local density = self:get_argument_by_name("density")
  local points_per_line = density.arg.value

  if (points_per_line == 0) then 
    -- TODO "smart mode", which inserts points at scope boundaries
    return 
  end
  
  if (type(range_or_length) == "number") then
    -- number (standalone)
    num_points = range_or_length
  else -- xSequencerSelection (bound to song)
    xpos = {
      sequence = range_or_length.start_sequence,
      line = range_or_length.start_line
    }
    num_points = xSequencerSelection.get_number_of_lines(range_or_length) 
    -- 
    if (points_per_line > 0) then 
      num_points = num_points * points_per_line
      line_inc = 1/points_per_line
    else
      num_points = num_points / math.abs(points_per_line)
      line_inc = math.abs(points_per_line)
    end
  end 

  local envelope = xEnvelope()
  local line_idx = 1
  local old_seq_idx = nil

  for point_idx = 1,num_points do 

    -- special case: output extra value at pattern boundary 
    if xpos and old_seq_idx and (xpos.sequence ~= old_seq_idx) then
      local pt = self:create_point(
        point_idx,
        num_points,
        points_per_line,
        playmode,
        xpos
      )
      pt.time = pt.time-xParameterAutomation.LINE_BOUNDARY_INV
      table.insert(envelope.points,pt)
      if (yield_at == xLib.YIELD_AT.PATTERN) then 
        coroutine.yield()
      end
    end

    -- regular point 
    table.insert(envelope.points,self:create_point(
      point_idx,
      num_points,
      points_per_line,
      playmode,
      xpos)
    )

    -- update song-position
    if xpos then 
      local old_line_idx = xpos.line
      old_seq_idx = xpos.sequence
      line_idx = line_idx + line_inc
      if (line_idx ~= old_line_idx) then 
        if xpos then 
          local line_diff = line_idx - old_line_idx
          xpos = xSongPos.increase_by_lines(line_diff,xpos,xpos_bounds,xpos_loop,xpos_block)
        end
      end
    end
  end

  -- special case: output extra value at the very end
  if xpos then
    local pt = self:create_point(
      num_points+1,
      num_points,
      points_per_line,
      playmode,
      {
        sequence = range_or_length.end_sequence,
        line = range_or_length.end_line
      })
    pt.time = pt.time-xParameterAutomation.LINE_BOUNDARY_INV
    table.insert(envelope.points,pt)
  end

  return envelope

end

---------------------------------------------------------------------------------------------------
-- cPersistence
---------------------------------------------------------------------------------------------------
-- extend method (ensure that density and playmode are always present)

function AutoMateGenerator:assign_definition(def)

  cPersistence.assign_definition(self,def)
  
  if not self:get_argument_by_name("density") then 
    table.insert(self.arguments,1,AutoMateSandboxArgument{
      name = "density",
      value = 1,
      value_min = -512,
      value_max = 256,
      value_quantum = 0,
      display_as = "valuebox",
    })
  end
  if not self:get_argument_by_name("playmode") then   
    table.insert(self.arguments,2,AutoMateSandboxArgument{
      name = "playmode",
      value = renoise.PatternTrackAutomation.PLAYMODE_LINEAR,
      value_min = renoise.PatternTrackAutomation.PLAYMODE_POINTS,
      value_max = renoise.PatternTrackAutomation.PLAYMODE_CUBIC,
      value_enums = {
        "Points",
        "Linear",
        "Cubic",
      },
      value_quantum = 1,
      display_as = "popup",
    })
  end

end

