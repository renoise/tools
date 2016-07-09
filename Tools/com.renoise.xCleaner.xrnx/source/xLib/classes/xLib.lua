--[[============================================================================
xLib
============================================================================]]--

--[[--

This is the core xLib class, containing a bunch of static helper methods
.
#


]]

--==============================================================================

-- Global variables and functions 

-- reference to song document 
-- rns = renoise.song()
function TRACE(...)
  print(...)
end

function LOG(...)
  print(...)
end

--------------------------------------------------------------------------------

class 'xLib'

xLib.COLOR_ENABLED = {0xD0,0xD8,0xD4}
xLib.COLOR_DISABLED = {0x00,0x00,0x00}

--------------------------------------------------------------------------------
-- Turn varargs into a table

function xLib.unpack_args(...)
  local args = {...}
  if not args[1] then
    return {}
  else
    return args[1]
  end
end

--------------------------------------------------------------------------------
-- Detect if we have a renoise song: in rare cases it can briefly go missing,
-- mostly while loading a song or creating a new document...

function xLib.is_song_available()

  local pass,err = pcall(function()
    rns.selected_instrument_index = rns.selected_instrument_index
  end)
  if not pass then
    return false
  end

  return true

end

--------------------------------------------------------------------------------
-- Match item(s) in an associative array (provide key)
-- @param t (table) 
-- @param key (string) 
-- @return table

function xLib.match_table_key(t,key)
  
  local rslt = table.create()
  for _,v in pairs(t) do
    rslt:insert(v[key])
  end
  return rslt

end

--------------------------------------------------------------------------------
-- Number methods
--------------------------------------------------------------------------------
-- scale_value: scale a value to a range within a range
-- @param value (number) the value we wish to scale
-- @param in_min (number) 
-- @param in_max (number) 
-- @param out_min (number) 
-- @param out_max (number) 
-- @return number
function xLib.scale_value(value,in_min,in_max,out_min,out_max)
  return(((value-in_min)*(out_max/(in_max-in_min)-(out_min/(in_max-in_min))))+out_min)
end

--------------------------------------------------------------------------------
-- clamp_value: ensure value is within min/max
-- @param value (number) 
-- @param min_value (number) 
-- @param max_value (number) 
-- @return number

function xLib.clamp_value(value, min_value, max_value)
  return math.min(max_value, math.max(value, min_value))
end

--------------------------------------------------------------------------------
--- greatest common divisor

function xLib.gcd(m,n)
  while n ~= 0 do
    local q = m
    m = n
    n = q % n
  end
  return m
end

--------------------------------------------------------------------------------
--- least common multiplier (2 args)

function xLib.lcm(m,n)
  return ( m ~= 0 and n ~= 0 ) and m * n / xLib.gcd( m, n ) or 0
end

--------------------------------------------------------------------------------
--- find least common multiplier 
-- @param t (table), use values in table as argument

function xLib.least_common(t)
  local cm = t[1]
  for i=1,#t-1,1 do
    cm = xLib.lcm(cm,t[i+1])
  end
  return cm
end

--------------------------------------------------------------------------------
-- String methods
--------------------------------------------------------------------------------
-- split string - original script: http://lua-users.org/wiki/SplitJoin 
-- @param str (string)
-- @param pat (string) pattern
-- @return table

function xLib.split(str, pat)

   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
   table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t

end

-------------------------------------------------------------------------------
-- remove trailing and leading whitespace from string.
-- http://en.wikipedia.org/wiki/Trim_(8programming)
-- @param s (string)
-- @return string

function xLib.trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-------------------------------------------------------------------------------
-- capitalize first letter of every word
-- @param s (string)
-- @return string

function xLib.capitalize(s)
  return string.gsub(" "..s, "%W%l", string.upper):sub(2)
end

-------------------------------------------------------------------------------
-- insert return code whenever we encounter dashes or spaces in a string
-- TODO keep dashes, and allow a certain length per line
-- @param str (string)
-- @return string

function xLib.soft_wrap(str)

  local t = xLib.split(str,"[-%s]")
  return table.concat(t,"\n")  

end

-------------------------------------------------------------------------------
-- detect counter in string (used for incrementing, unique names)

function xLib.detect_counter_in_str(str)
  local count = string.match(str,"%((%d)%)$")
  if count then 
    str = string.gsub(str,"%s*%(%d%)$","")
  else
    count = 1
  end
  return count
end

-------------------------------------------------------------------------------
-- find number of hex digits needed to represent a number (e.g. 255 = 2)
-- @param val (int)
-- @return int

function xLib.get_hex_digits(val)
  return 8-#string.match(bit.tohex(val),"0*")
end

-------------------------------------------------------------------------------
-- prepare a string so it can be stored in XML attributes
-- (strip illegal characters instead of trying to fix them)
-- @param str (string)
-- @return string

function xLib.sanitize_string(str)
  str=str:gsub('"','')  
  str=str:gsub("'",'')  
  return str
end

-------------------------------------------------------------------------------
-- take a table and convert into strings - useful e.g. for viewbuilder popup 
-- (if table is associative, will use values)
-- @param t (table)
-- @param prefix (string) insert before each entry
-- @param suffix (string) insert after each entry
-- @return table<string>

function xLib.stringify_table(t,prefix,suffix)

  local rslt = {}
  for k,v in ipairs(table.values(t)) do
    table.insert(rslt,("%s%s%s"):format(prefix or "",tostring(v),suffix or ""))
  end
  return rslt

end

-------------------------------------------------------------------------------
-- receives a string argument and turn it into a proper object or value
-- @param str (string), e.g. "renoise.song().transport.keyboard_velocity"
-- @return value (can be nil)
-- @return string, error message when failed

function xLib.parse_str(str)

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

--------------------------------------------------------------------------------
-- round_value (from http://lua-users.org/wiki/SimpleRound)

function xLib.round_value(num) 
  if num >= 0 then return math.floor(num+.5) 
  else return math.ceil(num-.5) end
end

--------------------------------------------------------------------------------
-- compare two numbers with variable precision
-- @param val1 
-- @param val2 
-- @param precision
-- @return boolean

function xLib.float_compare(val1,val2,precision)
  val1 = xLib.round_value(val1 * precision)
  val2 = xLib.round_value(val2 * precision)
  return val1 == val2 
end

--------------------------------------------------------------------------------
--- return the fractional part of a number
-- @param val 
-- @return number

function xLib.fraction(val)
  return val-math.floor(val)
end

--------------------------------------------------------------------------------
--- quick'n'dirty table compare (values in first level only)
-- @param t1 (table)
-- @param t2 (table)
-- @return boolean, true if identical

function xLib.table_compare(t1,t2)
  return (table.concat(t1,",")==table.concat(t2,","))
end

--------------------------------------------------------------------------------
-- try serializing a value or return "???"
-- the result should be a valid, quotable string
-- @param obj, value or object
-- @return string

function xLib.serialize_object(obj)
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

--------------------------------------------------------------------------------
-- serialize table into string, with some formatting options
-- @param t (table)
-- @param max_depth (int), determine how many levels to process - optional
-- @param longstring (boolean), use longstring format for multiline text
-- @return table

function xLib.serialize_table(t,max_depth,longstring)

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
    --local ordered = table_is_ordered(t)
    --print("ordered",ordered)
    local too_deep = (depth > max_depth) and true or false
    --print("too_deep",too_deep,depth)
    
    local next_indent
    for key, value in pairs(t) do
      --print("key, value",key,type(key),value)
      local str_key = (type(key) == 'number') and '' or '["'..xLib.serialize_object(key) .. '"] = ' 
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
          result = result .. indent .. str_key .. str_quote .. xLib.serialize_object(value) .. str_quote .. ',\n'
        end
      end
    end
    
    return result
  end

  rslt = rslt .. rdump(t) .. "}"
  --print(rslt)

  return rslt

end

