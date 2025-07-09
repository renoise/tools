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
-- [Static] find nearest value in table of numbers 
-- @param t (table<number>) 
-- @param val (number) 
-- @return number,number (value,key)

function cTable.nearest(t,val)
  TRACE("cTable.nearest(t,val)",#t,val)

  -- sort, but don't modify original table 
  local vals = table.values(t)
  table.sort(vals)

  local prev,key
  for k,v in ipairs(vals) do
    if (v == val) then 
      return v,k
    end 
    if (v > val) then 
      -- return first (lowest)
      if not prev then 
        return v,k
      end 
      -- shortest distance to prev/curr
      local d_prev = math.abs(prev-val)
      local d_curr = math.abs(v-val)
      if (math.min(d_prev,d_curr) == d_prev) then
        return prev,k
      else
        return v,k
      end
    end
    prev = v
    key = k
  end

  return prev,key

end

---------------------------------------------------------------------------------------------------
-- [Static] return next (higher value) in table of numbers 
-- @param t (table<number>) 
-- @param val (number) or nil

function cTable.next(t,val)
  TRACE("cTable.next(t,val)",#t,val)
  local vals = table.values(t)
  table.sort(vals)
  local _,idx = cTable.nearest(vals,val)
  --print("next - nearest idx",idx,rprint(vals))
  if idx then
    return vals[idx+1]
  end
end

---------------------------------------------------------------------------------------------------
-- [Static] return previous (lower value) in table of numbers 
-- @param t (table<number>) 
-- @param val (number) or nil

function cTable.previous(t,val)
  TRACE("cTable.previous(t,val)",#t,val)
  local vals = table.values(t)
  table.sort(vals)
  local _,idx = cTable.nearest(vals,val)
  --print("previous - nearest idx",idx)
  if idx then
    return vals[idx-1]
  end
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

---------------------------------------------------------------------------------------------------
-- Check if a given table is indexed (exclusively with numerical indices)

function cTable.is_indexed(t)
  local i = 0
  for _ in pairs(t) do
    i = i + 1
    if t[i] == nil then return false end
  end
  return true
end

