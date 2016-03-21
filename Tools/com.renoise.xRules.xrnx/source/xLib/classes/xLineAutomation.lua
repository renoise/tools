--[[============================================================================
xLineAutomation
============================================================================]]--

--[[--

A representation of automation data within a single line
.
#

Specify multiple values across the line, by supplying 'time' 


]]

class 'xLineAutomation'


-------------------------------------------------------------------------------
-- constructor
-- @param automation (table{value,time}) 

function xLineAutomation:__init(automation)

  --- table
  self.automation = table.create()

  -- initialize -----------------------

  if automation then
    for _,v in ipairs(automation) do
      self.automation:insert(v)
    end
  end

  --rprint(automation)

end

-------------------------------------------------------------------------------
-- @param sequence (int)
-- @param line (int)
-- @param ptrack_auto (renoise.PatternTrackAutomation)
-- @param patt_num_lines (int), length of the playpos pattern

function xLineAutomation:do_write(sequence,line,ptrack_auto,patt_num_lines)
  TRACE("xLineAutomation:do_write(sequence,line,ptrack_auto,patt_num_lines)",
    sequence,line,ptrack_auto,patt_num_lines)
  
  assert(ptrack_auto,"Required argument 'ptrack_auto' not defined")

  if table.is_empty(self.automation) then
    return
  end

  -- TODO clear existing, but how? API suggestion: clear_line_at(line_index)

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

  return "xLineAutomation" 

end
