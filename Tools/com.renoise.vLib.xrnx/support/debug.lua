--[[============================================================================
Debug.lua
============================================================================]]--
--[[

--- Debug tracing & logging
--
-- set one or more expressions to either show all or only a few messages 
-- from TRACE calls.
-- 
-- Some examples: 
--    {".*"} -> show all traces
--    {"^Display:"} " -> show traces, starting with "Display:" only
--    {"^ControlMap:", "^Display:"} -> show "Display:" and "ControlMap:"
]]

local _trace_filters = nil
--local _trace_filters = {"^Recorder*","^UISlider*"}
--local _trace_filters = {".*"}

--------------------------------------------------------------------------------

if (_trace_filters ~= nil) then
  
  --- TRACE impl
  -- @param (vararg)
  function TRACE(...)
    local result = ""
  
    -- try serializing a value or return "???"
    local function serialize(obj)
      local succeeded, result = pcall(tostring, obj)
      if succeeded then
        return result 
      else
       return "???"
      end
    end
    
    -- table dump helper
    local function rdump(t, indent, done)
      local result = "\n"
      done = done or {}
      indent = indent or string.rep(' ', 2)
      
      local next_indent
      for key, value in pairs(t) do
        if (type(value) == 'table' and not done[value]) then
          done[value] = true
          next_indent = next_indent or (indent .. string.rep(' ', 2))
          result = result .. indent .. '[' .. serialize(key) .. '] => table\n'
          rdump(value, next_indent .. string.rep(' ', 2), done)
        else
          result = result .. indent .. '[' .. serialize(key) .. '] => ' .. 
            serialize(value) .. '\n'
        end
      end
      
      return result
    end
   
    -- concat args to a string
    local n = select('#', ...)
    for i = 1, n do
      local obj = select(i, ...)
      if( type(obj) == 'table') then
        result = result .. rdump(obj)
      else
        result = result .. serialize(select(i, ...))
        if (i ~= n) then 
          result = result .. "\t"
        end
      end
    end
  
    -- apply filter
    for _,filter in pairs(_trace_filters) do
      if result:find(filter) then
        print(result)
        break
      end
    end
  end
  
else

  function TRACE()
    -- do nothing
  end
    
end


--- call this to avoid using "print" statements in source code
function LOG(str)
  print(str)
end
