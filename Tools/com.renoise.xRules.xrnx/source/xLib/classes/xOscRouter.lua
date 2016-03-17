--[[============================================================================
xOscRouter
============================================================================]]--

--[[

  A simple OSC router with caching
  The router is using instances of xOscPattern to match messages. 

  Caching works only when patterns does not define captures of float values. 
  Should this be the case, _all matched patterns_ will not be cached. 

]]

-------------------------------------------------------------------------------

class 'xOscRouter' 

function xOscRouter:__init(...)

	local args = xLib.unpack_args(...) 

  -- table<xOscPattern>
  self.patterns = property(self.get_patterns,self.set_patterns)
  self._patterns = args.patterns or {}

  -- internal --

  -- {pattern_in=string,osc_msg=renoise.Osc.Message}
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
  TRACE("xOscRouter:input(osc_msg)",osc_msg)

  local fingerprint = tostring(osc_msg)
  local rslt = {}

  if (self.cache[fingerprint]) then
    --print("return cached patterns...")
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
        --print("***",err)
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
        --print(">>> add to cache",v,v.pattern_in)
        table.insert(self.cache[fingerprint],v)
      end
    end
  end

  return rslt

end

-------------------------------------------------------------------------------
-- @patt xOscPattern
-- @return int, index in patterns

function xOscRouter:add_pattern(patt)
  TRACE("xOscRouter:add_pattern(patt)",patt)

  table.insert(self.patterns,patt)
  local patt_idx = #self.patterns

  patt.before_modified_observable:add_notifier(function()
    -- clear from cache
    --print(">>> before_modified_observable fired... clear from cache")
    self:remove_from_cache(patt_idx)
  end)
  --print(">>> xOscRouter:add_pattern",self.patterns)

  return #self.patterns

end

-------------------------------------------------------------------------------
-- @param patt, xOscPattern
-- @param idx (int), pattern index

function xOscRouter:replace_pattern(patt,idx)
  TRACE("xOscRouter:replace_pattern(patt,idx)",patt,idx)

  self.patterns[idx] = patt

  --print(">>> xOscRouter:replace_pattern",self.patterns)

end

-------------------------------------------------------------------------------
-- @param idx (int), pattern index

function xOscRouter:remove_pattern(idx)
  TRACE("xOscRouter:remove_pattern(idx)",idx)

  self:remove_from_cache(idx)

  table.remove(self.patterns,idx)

  --print(">>> xOscRouter:remove_pattern - patterns",self.patterns)

end

-------------------------------------------------------------------------------
-- @param idx (int), pattern index

function xOscRouter:remove_from_cache(idx)
  TRACE("xOscRouter:remove_from_cache(idx)",idx)

  --print(">>> xOscRouter:remove_from_cache - cache PRE",self.cache)

  local pattern_in = self.patterns[idx].pattern_in
  --print("*** removing from cache - pattern_in",pattern_in)
  local rslt = {}
  for k,v in pairs(self.cache) do
    --print("k,v",k,v)
    for k2,v2 in ripairs(v) do
      --print("k2,v2",k2,v2)
      if (v2.pattern_in == pattern_in) then
        --print("*** remove",v2.pattern_in)
        --table.insert(rslt,k)
        self.cache[k] = nil
        break
      end
    end
  end
  --[[
  for k,v in pairs(rslt) do
    self.cache[k] = nil
  end
  ]]

  --print(">>> xOscRouter:remove_from_cache - cache POST",self.cache)

end
