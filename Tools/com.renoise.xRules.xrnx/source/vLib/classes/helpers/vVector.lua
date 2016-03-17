--[[============================================================================
vVector
============================================================================]]--

class 'vVector'

--------------------------------------------------------------------------------
---  Static methods for tables whose elements all have the same data type

--------------------------------------------------------------------------------
--[[
-- TODO execute a test function on each item 
-- @param t (table)
-- @param fn_callback (function)
-- @return table

function vVector.filter(t,fn_callback)
  -- callback: item:t, index:int, vector:vector.<T>
  return rslt
end

--------------------------------------------------------------------------------
-- TODO sort elements according to the specified function
-- @param t (table) 
-- @param fn_compare (function) needs to return a boolean value
-- @return table

function vVector.sort(t,fn_compare)
  return rslt
end

--------------------------------------------------------------------------------
-- merge two vectors, using the specified key to identify matching items
-- used for joining a temporary/filtered set with the original 
-- note: t1 overwrites matches in t2
-- @param t1 (table)
-- @param t2 (table)
-- @return table

function vVector.merge(t1,t2)
  return rslt
end

]]
--------------------------------------------------------------------------------
-- Match entry in an array (provide key + value)
-- @param t (table) 
-- @param key (string) 
-- @param val (variant) 
-- @return variant or nil
-- @return int (index)

function vVector.match_by_key_value(t,key,val)
  TRACE("vVector.match_by_key_value(t,key,val)",t,key,val)
  
  local rslt = table.create()
  for k,v in pairs(t) do
    if v[key] and (v[key] == val) then
      return v,k
    end
  end

end

--------------------------------------------------------------------------------
-- count checked items ("checked" is key, value is boolean)
-- TODO depricated, use match instead
-- @param t (table)
-- @return int

function vVector.count_checked(t)
  TRACE("vVector.count_checked(t)",t)

  if (table.is_empty(t)) then
    return 0
  end

  local count = 0
  for k,v in ipairs(t) do
    if (type(v.checked)=="boolean") and (v.checked) then
      count = count+1
    end
  end
  return count
  
end

--------------------------------------------------------------------------------
-- return first item whose "checked" attribute is true
-- TODO depricated, use match instead
-- @param t (table)
-- @return table

function vVector.get_selected_item(t)

  for k,v in ipairs(t) do
    if (type(v.checked)=="boolean") and (v.checked) then
      return v
    end
  end

end
