--[[============================================================================
xLineAutomation
============================================================================]]--

--[[--

A representation of automation data within a single line.

#

See also:
@{xLine}
@{xLinePattern}
@{xAutomation}

]]

class 'xLineAutomation'

-------------------------------------------------------------------------------
-- [Constructor] accepts a single argument 
-- @param automation 

function xLineAutomation:__init(automation)

  --- table<{value,time}>, multiple values are possible per-line
  self.automation = table.create()

  -- initialize -----------------------

  if automation then
    for _,v in ipairs(automation) do
      self.automation:insert(v)
    end
  end

end

-------------------------------------------------------------------------------
-- [Class] Write to the provided automation lane
-- @param line (int)
-- @param ptrack_auto (renoise.PatternTrackAutomation)
-- @param patt_num_lines (int), length of the playpos pattern

function xLineAutomation:do_write(line,ptrack_auto,patt_num_lines)
  TRACE("xLineAutomation:do_write(line,ptrack_auto,patt_num_lines)",line,ptrack_auto,patt_num_lines)
  
  assert(ptrack_auto,"Required argument 'ptrack_auto' not defined")

  if table.is_empty(self.automation) then
    return
  end

  -- clear existing line, if supported 
  if (renoise.API_VERSION <= 5) then
    ptrack_auto:clear_range(line,line+1)
  end

  for k,v in ipairs(self.automation) do
    ptrack_auto:add_point_at(line+v.time_offset or 0,v.value or 0)
  end

  -- if the last line in the playpos pattern, add extra automation point 
  -- (this will only _really_ work if the first automation point is
  -- without a time offset)
  if (line == patt_num_lines) then
    ptrack_auto:add_point_at(line+0.999,self.automation[1].value)
  end

end

-------------------------------------------------------------------------------

function xLineAutomation:__tostring()

  return type(self)

end
