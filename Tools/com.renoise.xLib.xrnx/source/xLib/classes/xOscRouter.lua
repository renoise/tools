--[[============================================================================
xOscRouter
============================================================================]]--

--[[--

A simple OSC router with caching
.
#

The router is using instances of xOscPattern to match messages. 

Caching works only when patterns does not define captures of float values. 
Should this be the case, _all matched patterns_ will not be cached. 

]]

-------------------------------------------------------------------------------

class 'xOscRouter' 

function xOscRouter:__init(...)

	local args = cLib.unpack_args(...) 

  --- table<xOscPattern>
  self.patterns = property(self.get_patterns,self.set_patterns)
  self._patterns = args.patterns or {}

  -- internal --

  --- table<xOscPattern>, indexed by fingerprint
  self.cache = {}

end

-------------------------------------------------------------------------------

function xOscRouter:get_patterns()
  return self._patterns
end

function xOscRouter:set_patterns(val)
  assert(type(val) == "table","Expected table as argument")
  self._patterns = val
  self.cache = {}
end


-------------------------------------------------------------------------------
-- Input message, return matching patterns
-- @param osc_msg, renoise.Osc.Message
-- @return table<xOscPattern>

function xOscRouter:input(osc_msg)

  local fingerprint = tostring(osc_msg)
  local rslt = {}

  if (self.cache[fingerprint]) then
    for k,v in ipairs(self.cache[fingerprint]) do
      table.insert(rslt,v)
    end
  else
    local all_cacheable = true
    for k,v in ipairs(self.patterns) do
      local matched,err = v:match(osc_msg)
      if matched then
        if not v.cacheable then
          all_cacheable = false
        end
        table.insert(rslt,v)
      else
        --LOG("***",err)
      end
    end
    -- only cache when patterns are _all_ cacheable
    -- (this is usually the case, having a pattern which match the 
    -- same message both via float and integer is highly unusual)
    if all_cacheable then
      for k,v in ipairs(rslt) do
        if not self.cache[fingerprint] then
          self.cache[fingerprint] = {}
        end
        table.insert(self.cache[fingerprint],v)
      end
    end
  end
  return rslt

end

-------------------------------------------------------------------------------
-- @param patt xOscPattern
-- @return int, index in patterns

function xOscRouter:add_pattern(patt)

  table.insert(self.patterns,patt)
  local patt_idx = #self.patterns

  patt.before_modified_observable:add_notifier(function()
    self:remove_from_cache(patt_idx)
  end)
  
  return #self.patterns

end

-------------------------------------------------------------------------------
-- @param patt, xOscPattern
-- @param idx (int), pattern index

function xOscRouter:replace_pattern(patt,idx)
  self.patterns[idx] = patt
end

-------------------------------------------------------------------------------
-- @param idx (int), pattern index

function xOscRouter:remove_pattern(idx)
  self:remove_from_cache(idx)
  table.remove(self.patterns,idx)
end

-------------------------------------------------------------------------------
-- @param idx (int), pattern index

function xOscRouter:remove_from_cache(idx)

  local patt = self.patterns[idx]
  local pattern_in = patt.pattern_in

  local purely_literal = patt:purely_literal()
  if purely_literal then
    -- we can generate a fingerprint - find and remove matches 
    local fingerprint = tostring(patt:generate())
    if self.cache[fingerprint] then
      self.cache[fingerprint] = nil
    end
    -- if any cached patterns contain wildcards that match
    -- our literal types, remove these entries 
    for k,v in pairs(self.cache) do
      for k2,v2 in ripairs(v) do
        local patterns_match,err = xOscPattern.types_are_matching(patt,v2)
        if patterns_match then
          self.cache[k] = nil
        end
      end
    end
  end

end
