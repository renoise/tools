--[[===============================================================================================
cTable
===============================================================================================]]--

--[[--

Contains common methods for working with tables

]]

--=================================================================================================

class 'cTable'

---------------------------------------------------------------------------------------------------
-- [Static] return the sorted values of the provided table
-- @param t table 
-- @return 

function cTable.values(t)

  local rslt = table.values(t)
  table.sort(rslt)
  return rslt

end

---------------------------------------------------------------------------------------------------
-- [Static] return the last entry of the provided table 
-- NB: only works with indexed tables 
-- @param table 
-- @return 

function cTable.last(t)

  return t[#t]

end

---------------------------------------------------------------------------------------------------
-- [Static] Merge two tables into one (recursive)
-- @param t1 (table)
-- @param t2 (table)
-- @return table

function cTable.merge(t1,t2)
  for k,v in pairs(t2) do
    if type(v) == "table" then
      if type(t1[k] or false) == "table" then
        cTable.merge(t1[k] or {}, t2[k] or {})
      else
        t1[k] = v
      end
    else
      t1[k] = v
    end
  end
  return t1
end

---------------------------------------------------------------------------------------------------
-- [Static] Convert a sparsely populated table into a compact one
-- @param t (table)
-- @return table

function cTable.compact(t)

  if table.is_empty(t) then
    return t
  end

  local cols = table.keys(t)
  table.sort(cols)
  for k,v in ipairs(cols) do
    t[k] = t[v]
  end
  local low,high = cTable.bounds(t)
  for k = high,#cols+1,-1 do
    t[k] = nil
  end

end

---------------------------------------------------------------------------------------------------
-- [Static] Quick'n'dirty table compare (values in first level only)
-- @param t1 (table)
-- @param t2 (table)
-- @return boolean, true if identical

function cTable.compare(t1,t2)
  return (table.concat(t1,",")==table.concat(t2,","))
end

---------------------------------------------------------------------------------------------------
-- [Static] Match item(s) in an associative array (provide key)
-- @param t (table) 
-- @param key (string) 
-- @return table

function cTable.match_key(t,key)
  
  local rslt = table.create()
  for _,v in pairs(t) do
    rslt:insert(v[key])
  end
  return rslt

end

---------------------------------------------------------------------------------------------------
-- [Static] Expand a multi-dimensional array with given keys
-- @param t (table) 
-- @param k1 (string) 
-- @param k2 (string) 
-- @param k3 (string) 
-- @param k4 (string) 
-- @return table

function cTable.expand(t,k1,k2,k3,k4)
  --TRACE("cTable.expand(t,k1,k2,k3,k4)",t,k1,k2,k3,k4)

  if not t[k1] then
    t[k1] = {}
  end
  if k2 then
    t = cTable.expand(t[k1],k2,k3,k4)
  end

  return t

end

---------------------------------------------------------------------------------------------------
-- [Static] Find the highest/lowest numeric key (index) in a sparsely populated table
-- @return lowest,highest

function cTable.bounds(t)
  
  local lowest,highest = nil,nil
  for k,v in ipairs(table.keys(t)) do
    if (type(v)=="number") then
      if not highest then highest = v end
      if not lowest then lowest = v end
      highest = math.max(highest,v)
      lowest = math.min(lowest,v)
    end
  end
  return lowest,highest 

end

