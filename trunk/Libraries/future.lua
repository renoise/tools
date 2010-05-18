--[[----------------------------------------------------------------------------
-- future.lua
----------------------------------------------------------------------------]]--

--[[
  module which enables some branch/futures standard Lua functions before 
  they got released - before they are built into Renoise. This way you can 
  already test and use them, before the new alpha builds are avilable.
  
  To use this module, put a:
    pcall(require, "future") 
  
  somewhere into your scripts. The 'pcall' will ensure that your script runs 
  even without "future" in the paths, but its recommended to remove the 
  require "future" with every new alpha.
  
  This file will be emptied / updated each time branches/future was 
  merged back to the trunk...
]]


--------------------------------------------------------------------------------
-- new table tools
--------------------------------------------------------------------------------

-- count the number of items of a table, also works for non index
-- based tables (using pairs).

function table.count(t)
  assert(type(t) == 'table', ("bad argument #1 to 'table.copy' "..
    "(table expected, got '%s')"):format(type(t)))
  
  local count = 0
  for _,_ in pairs(t) do
    count = count + 1
  end
  
  return count
end


--------------------------------------------------------------------------------

-- copy the metatable and all first level elements of the given table into a
-- new table. Use table.rcopy to do a recursive copy of all elements

function table.copy(t)
  assert(type(t) == 'table', ("bad argument #1 to 'table.copy' "..
    "(table expected, got '%s')"):format(type(t)))
  
  local new_table = {}
  for k, v in pairs(t) do
    new_table[k] = v
  end
  
  return setmetatable(new_table, getmetatable(t))
end


--------------------------------------------------------------------------------

-- deeply copy the metatable and all elements of the given table recursively
-- into a new table - create a clone with unique references.

function table.rcopy(t)
  assert(type(t) == 'table', ("bad argument #1 to 'table.copy' "..
    "(table expected, got '%s')"):format(type(t)))

  local lookup_table = {}
  
  local function _copy(object)
    if (type(object) ~= 'table') then
      return object
    
    elseif (lookup_table[object] ~= nil) then
      return lookup_table[object]
    
    else
      local new_table = {}
      lookup_table[object] = new_table
      for k, v in pairs(object) do
        new_table[_copy(k)] = _copy(v)
      end
      return setmetatable(new_table, getmetatable(object))
    end
    
  end

  return _copy(t)
end


--------------------------------------------------------------------------------
-- debug session shortcuts
--------------------------------------------------------------------------------

-- use debug.start/stop without requires ...

if (pcall(require, "remdebug.session")) then
  debug.start = remdebug.session.start
  debug.stop = remdebug.session.stop

else
  debug.start = function() 
    error("module 'remdebug.session' could not be found, but is "..
      "required to start debug sessions.")
  end
  
  debug.stop = nil
end

