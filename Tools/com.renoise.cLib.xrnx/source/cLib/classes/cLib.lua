--[[===============================================================================================
cLib
===============================================================================================]]--

--[[--

Contains common methods for working with strings, numbers and tables.

##

Note that several classes in the cLib library invokes the LOG/TRACE statement - 
therefore, it is recommended that any cLib-powered tool includes this file

]]

--=================================================================================================

require (_clibroot.."cValue")
require (_clibroot.."cNumber")

class 'cLib'

--- placeholder value for nil, storable in table.
cLib.NIL = {} 

---------------------------------------------------------------------------------------------------
-- [Static] LOG statement - invokes cLib.log(). 
-- you can override this method with your own custom implementation  
-- @param ... (vararg)

function LOG(...)
  cLib.log(...)
end

---------------------------------------------------------------------------------------------------
-- [Static] Placeholder TRACE statement
-- (include cDebug for the full-featured implementation)
-- @param ... (vararg)

function TRACE(...) 

end

---------------------------------------------------------------------------------------------------
-- [Static] Print important messages to the console (errors and warnings)
-- @param ... (vararg)

function cLib.log(...)

  local args = {...}
  local n = select('#', ...)

  local success,err = pcall(function()
    local result = ""
    for i = 1, n do
      result = result .. tostring(args[i]) .. "\t"
    end
    print (result)
  end)

  if not success then 
    print(...)
  end 

end

---------------------------------------------------------------------------------------------------
-- [Static] For class constructors that use this syntax: 
--    local obj = SomeObject{
--      some_prop = "initial value",
--      other_prop = 42
--    }
-- @param ... (vararg)
-- @return (likely table, but depends on what you feed it)

function cLib.unpack_args(...)
  local args = {...}
  if not args[1] then
    return {}
  else
    return args[1]
  end
end

---------------------------------------------------------------------------------------------------
-- [Static] Vararg packer with `nil` placeholder
-- See http://lua-users.org/wiki/VarargTheSecondClassCitizen
-- @param ... (vararg)
-- @return table 

function cLib.pack(...)
  local n = select('#', ...)
  local t = {}
  for i = 1,n do
    local v = select(i, ...)
    t[i] = (v == nil) and NIL or v
  end
  return t
end

---------------------------------------------------------------------------------------------------
-- [Static] Call a class method or function and show/log results
-- Note: currently with a maximum of 8 arguments can be passed (this is a
-- convenience function after all...)
-- @param ... (vararg), [class+function or function] + argument(s)

function cLib.invoke_task(...)
  local fn = select(1,...)
  fn(select(2,...),select(3,...),select(4,...),select(5,...),
    select(6,...),select(7,...),select(8,...),select(9,...))
end

---------------------------------------------------------------------------------------------------
-- [Static] Turn value descriptor into instance
-- @return cNumber or cValue

function cLib.create_cvalue(t)

  local val = t.value or t.value_default
  if (type(val)=="number") then
    return cNumber(t)
  else
    return cValue(t)
  end

end

---------------------------------------------------------------------------------------------------
-- Array/table methods
---------------------------------------------------------------------------------------------------
-- [Static] Match item(s) in an associative array (provide key)
-- @param t (table) 
-- @param key (string) 
-- @return table

function cLib.match_table_key(t,key)
  
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

function cLib.expand_table(t,k1,k2,k3,k4)
  --TRACE("cLib.expand_table(t,k1,k2,k3,k4)",t,k1,k2,k3,k4)

  if not t[k1] then
    t[k1] = {}
  end
  if k2 then
    t = cLib.expand_table(t[k1],k2,k3,k4)
  end

  return t

end

---------------------------------------------------------------------------------------------------
-- [Static] Find the highest/lowest numeric key (index) in a sparsely populated table
-- @return lowest,highest

function cLib.get_table_bounds(t)
  
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
-- [Static] Merge two tables into one (recursive)
-- @param t1 (table)
-- @param t2 (table)
-- @return table

function cLib.merge_tables(t1,t2)
  for k,v in pairs(t2) do
    if type(v) == "table" then
      if type(t1[k] or false) == "table" then
        cLib.merge_tables(t1[k] or {}, t2[k] or {})
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

function cLib.compact_table(t)

  if table.is_empty(t) then
    return t
  end

  local cols = table.keys(t)
  table.sort(cols)
  for k,v in ipairs(cols) do
    t[k] = t[v]
  end
  local low,high = cLib.get_table_bounds(t)
  for k = high,#cols+1,-1 do
    t[k] = nil
  end

end

---------------------------------------------------------------------------------------------------
-- [Static] Quick'n'dirty table compare (values in first level only)
-- @param t1 (table)
-- @param t2 (table)
-- @return boolean, true if identical

function cLib.table_compare(t1,t2)
  return (table.concat(t1,",")==table.concat(t2,","))
end

---------------------------------------------------------------------------------------------------
-- Number methods
---------------------------------------------------------------------------------------------------
-- [Static] Scale value to a range within a range
-- @param value (number) the value we wish to scale
-- @param in_min (number) 
-- @param in_max (number) 
-- @param out_min (number) 
-- @param out_max (number) 
-- @return number

function cLib.scale_value(value,in_min,in_max,out_min,out_max)
  return(((value-in_min)*(out_max/(in_max-in_min)-(out_min/(in_max-in_min))))+out_min)
end

---------------------------------------------------------------------------------------------------
-- [Static] Attempt to convert string to a number (strip percent sign)
-- @param str (string), e.g. "33.3%"
-- @return number or (TODO) nil if not able to convert

function cLib.string_to_percentage(str)
  TRACE("cLib.string_to_percentage(str)",str)
  return tonumber(string.sub(str,1,#str-1))
end


---------------------------------------------------------------------------------------------------
--- [Static] Get average of supplied numbers
-- @return number 

function cLib.average(...)
  local rslt = 0
  for i=1, #arg do
    rslt = rslt+arg[i]
  end
	return rslt/#arg
end

---------------------------------------------------------------------------------------------------
-- [Static] Clamp value - ensure value is within min/max
-- @param value (number) 
-- @param min_value (number) 
-- @param max_value (number) 
-- @return number

function cLib.clamp_value(value, min_value, max_value)
  return math.min(max_value, math.max(value, min_value))
end

---------------------------------------------------------------------------------------------------
-- [Static] 'Wrap/rotate' value within specified range
-- (with a range of 64-127, a value of 128 should output 65)
-- TODO use % modulo to obtain offset

function cLib.wrap_value(value, min_value, max_value)
  local range = max_value - min_value + 1
  assert(range > 0, "invalid range")
  while (value < min_value) do
    value = value + range
  end
  while (value > max_value) do
    value = value - range
  end
  return value
end

---------------------------------------------------------------------------------------------------
-- [Static] Determine the sign of a number
-- @return -1 if negative or 1 if positive

function cLib.sign(x)
    return (x<0 and -1) or 1
end

---------------------------------------------------------------------------------------------------
--- [Static] Inverse logarithmic scaling (exponential)

function cLib.inv_log_scale(ceiling,val)
  return ceiling-cLib.log_scale(ceiling,ceiling-val+1)
end

---------------------------------------------------------------------------------------------------
--- logarithmic scaling within a fixed space
-- @param ceiling (number) the upper boundary 
-- @param val (number) the value to scale

function cLib.log_scale(ceiling,val)
  return math.log(val)*ceiling/math.log(ceiling)
end

---------------------------------------------------------------------------------------------------
-- [Static] Check for whole number, using format() 

function cLib.is_whole_number(n)
  return (("%.8f"):format(n-math.floor(n)) == "0.00000000") 
end

---------------------------------------------------------------------------------------------------
-- [Static] Convert between note/hertz

function cLib.note_to_hz(note)
  TRACE('cLib.note_to_hz(note)',note)
  return math.pow(2, (note - 45) / 12) * 440;
end

function cLib.hz_to_note(freq)
  TRACE('cLib.hz_to_note(freq)',freq)
  return (math.log(freq) - math.log(440)) / math.log(2) + 4;
end

---------------------------------------------------------------------------------------------------
-- [Static] Greatest common divisor

function cLib.gcd(m,n)
  while n ~= 0 do
    local q = m
    m = n
    n = q % n
  end
  return m
end

---------------------------------------------------------------------------------------------------
-- [Static] Least common multiplier (2 args)

function cLib.lcm(m,n)
  return ( m ~= 0 and n ~= 0 ) and m * n / cLib.gcd( m, n ) or 0
end

---------------------------------------------------------------------------------------------------
-- [Static] Find least common multiplier 
-- @param t (table), use values in table as argument

function cLib.least_common(t)
  local cm = t[1]
  for i=1,#t-1,1 do
    cm = cLib.lcm(cm,t[i+1])
  end
  return cm
end

---------------------------------------------------------------------------------------------------
-- [Static] Round value (from http://lua-users.org/wiki/SimpleRound)
-- @param num (number)

function cLib.round_value(num) 
  if num >= 0 then return math.floor(num+.5) 
  else return math.ceil(num-.5) end
end

---------------------------------------------------------------------------------------------------
-- [Static] Compare two numbers with variable precision
-- @param val1 
-- @param val2 
-- @param precision, '10000000' is suitable for parameter values
-- @return boolean

function cLib.float_compare(val1,val2,precision)
  val1 = cLib.round_value(val1 * precision)
  val2 = cLib.round_value(val2 * precision)
  return val1 == val2 
end

---------------------------------------------------------------------------------------------------
-- [Static] Return the fractional part of a number
-- @param val 
-- @return number

function cLib.fraction(val)
  return val-math.floor(val)
end

---------------------------------------------------------------------------------------------------
-- [Static] Find number of hex digits needed to represent a number (e.g. 255 = 2)
-- @param val (int)
-- @return int

function cLib.get_hex_digits(val)
  return 8-#string.match(bit.tohex(val),"0*")
end

---------------------------------------------------------------------------------------------------
-- [Static] Take a table and convert into strings - useful e.g. for viewbuilder popup 
-- (if table is associative, will use values)
-- @param t (table)
-- @param prefix (string) insert before each entry
-- @param suffix (string) insert after each entry
-- @return table<string>

function cLib.stringify_table(t,prefix,suffix)

  local rslt = {}
  for k,v in ipairs(table.values(t)) do
    table.insert(rslt,("%s%s%s"):format(prefix or "",tostring(v),suffix or ""))
  end
  return rslt

end

---------------------------------------------------------------------------------------------------
-- [Static] Receives a string argument and turn it into a proper object or value
-- @param str (string), e.g. "renoise.song().transport.keyboard_velocity"
-- @return value (can be nil)
-- @return string, error message when failed

function cLib.parse_str(str)

  local rslt
  local success,err = pcall(function()
    rslt = loadstring("return " .. str)()
  end)

  if success then
    return rslt
  else
    return nil,err
  end

end

---------------------------------------------------------------------------------------------------
-- Check if table values are all identical
-- (useful e.g. for detecting if a color is tinted)
-- @return boolean

function cLib.table_has_equal_values(t)

  local val = nil
  for k,v in ipairs(t) do
    if (val==nil) then
      val = v
    end
    if (val~=v) then
      return false
    end
  end
  return true

end

---------------------------------------------------------------------------------------------------
-- Quick'n'dirty table compare, compares values (not keys)
-- @return boolean, true if identical

function cLib.table_compare(t1,t2)
  return (table.concat(t1,",")==table.concat(t2,","))
end

---------------------------------------------------------------------------------------------------
-- Count table entries, including mixed types
-- @return int or nil

function cLib.table_count(t)
  local n=0
  if ("table" == type(t)) then
    for key in pairs(t) do
      n = n + 1
    end
    return n
  else
    return nil
  end
end

---------------------------------------------------------------------------------------------------
-- [Static] Try serializing a value or return "???"
-- the result should be a valid, quotable string
-- @param obj, value or object
-- @return string

function cLib.serialize_object(obj)
  local succeeded, result = pcall(tostring, obj)
  if succeeded then
    result=string.gsub(result,"\n","\\n")    -- return code
    result=string.gsub(result,'\\"','\\\\"') -- double-quotes
    result=string.gsub(result,'"','\\"')     -- single-quotes
    return result 
  else
   return "???"
  end
end

---------------------------------------------------------------------------------------------------
-- [Static] Serialize table into string, with some formatting options
-- @param t (table)
-- @param max_depth (int), determine how many levels to process - optional
-- @param longstring (boolean), use longstring format for multiline text
-- @return table

function cLib.serialize_table(t,max_depth,longstring)

  assert(type(t) == "table", "this method accepts only a table as argument")

  local rslt = "{\n"
  if not max_depth then
    max_depth = 9999
  end


  -- table dump helper
  local function rdump(t, indent, depth)
    local result = ""--"\n"
    indent = indent or string.rep(' ', 2)
    depth = depth or 1 
    local too_deep = (depth > max_depth) and true or false    
    local next_indent
    -- list keys in alphabetic order
    local keys = table.keys(t)
    table.sort(keys)
    for _, key in ipairs(keys) do
      local value = t[key]
      local str_key = (type(key) == 'number') and '' or '["'..cLib.serialize_object(key) .. '"] = ' 
      if (type(value) == 'table') then
        if table.is_empty(value) then
          result = result .. indent .. str_key .. '{},\n'      
        elseif too_deep then
          result = result .. indent .. str_key .. '"table...",\n'
        else
          next_indent = next_indent or (indent .. string.rep(' ', 2))
          result = result .. indent .. str_key .. '{\n'
          depth = depth + 1 
          result = result .. rdump(value, next_indent .. string.rep(' ', 2), depth)
          result = result .. indent .. '},\n'
        end
      else
        if longstring and type(value)=="string" and string.find(value,"\n") then
          result = result .. indent .. str_key .. '[[' .. value .. ']]' .. ',\n'
        else
          local str_quote = (type(value) == "string") and '"' or ""
          result = result .. indent .. str_key .. str_quote .. cLib.serialize_object(value) .. str_quote .. ',\n'
        end
      end
    end
    
    return result
  end

  rslt = rslt .. rdump(t) .. "}"
  return rslt

end

