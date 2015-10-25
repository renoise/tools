--[[============================================================================
xLib
============================================================================]]--
--[[

  The xLib library is a suite of classes that extend the standard Renoise API
  
  ## Conventions

  Each class aims to be implemented with static methods, this should make it 
  possible to use xLib with most programming styles. 

  However, some of the more advanced classes do contain class methods 
  and properties. This includes xSongPos and xLine (+related)

  

]]

--==============================================================================

-- global variables and functions 

-- reference to song document - needs app_new_document_observable notifier 
-- to be added to whatever tool that implements xLib 
-- rns = renoise.song()

TRACE = function(...)
  --print(...)
end

LOG = function(...)
  print(...)
end

--------------------------------------------------------------------------------

class 'xLib'

xLib.UNDEFINED = "xLib.UNDEFINED"

xLib.SYNC_MODE = {
  OFF = 1,
  SOURCE = 2,
  TARGET = 3,
}

xLib.DESTINATION = {
  SOURCE = 1,
  TARGET = 2,
}

xLib.PRESET_TYPES = {
  "Effect Chains",
  "Effect Presets",
  "Instruments",
  "Modulation Sets",
  "Multi-Samples",
  "Phrases",
  "Samples",
  "Songs",
}


xLib.COLOR_ENABLED = {0xD0,0xD8,0xD4}
xLib.COLOR_DISABLED = {0x00,0x00,0x00}
xLib.COLOR_BASE = {0x5A,0x5A,0x5A}
xLib.LARGE_BUTTON_H = 22
xLib.SWITCHER_H = 22

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
-- Add notifier, while checking for / removing existing one
-- supports all three combinations of arguments:
-- function or (object, function) or (function, object)
-- @param obs (renoise.Document.ObservableXXX)
-- @param arg1 (function or object)
-- @param arg2 (function or object)

function xLib.attach_to_observable(obs,arg1,arg2)
  TRACE("xLib.attach_to_observable(obs,arg1,arg2)",obs,arg1,arg2)
  
  if type(arg1)=="function" then
    local fn,obj = arg1,arg2
    if obj then
      if obs:has_notifier(fn,obj) then obs:remove_notifier(fn,obj) end
      obs:add_notifier(fn,obj)
    else
      if obs:has_notifier(fn) then obs:remove_notifier(fn) end
      obs:add_notifier(fn)
    end
  elseif type(arg2)=="function" then
    local obj,fn = arg1,arg2
    if obs:has_notifier(obj,fn) then obs:remove_notifier(obj,fn) end
    obs:add_notifier(obj,fn)
  else
    error("Unsupported arguments")
  end

end

--------------------------------------------------------------------------------
-- Match item(s) in an associative array (provide key)
-- @param t (table) 
-- @param key (string) 
-- @return table

function xLib.match_table_key(t,key)
  --TRACE("xLib.match_table_key(t,key)",t,key)
  
  local rslt = table.create()
  for _,v in pairs(t) do
    rslt:insert(v[key])
  end
  return rslt

end

--------------------------------------------------------------------------------

--- scale_value: scale a value to a range within a range
-- @param value (number) the value we wish to scale
-- @return number
function xLib.scale_value(value,in_min,in_max,out_min,out_max)
  return(((value-in_min)*(out_max/(in_max-in_min)-(out_min/(in_max-in_min))))+out_min)
end

--------------------------------------------------------------------------------
-- split string - original script: http://lua-users.org/wiki/SplitJoin 
-- @param str_input (string)
-- @param pat (string) pattern

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

function xLib.trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
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
-- find number of hex digits needed to represent a number (e.g. 255 = 2)
-- @param val (int)
-- @return int

function xLib.get_hex_digits(val)
  return 8-#string.match(bit.tohex(val),"0*")
end

-------------------------------------------------------------------------------
-- prepare a string so it can be stored in XML attributes
-- (strip illegal characters instead of trying to fix them)

function xLib.sanitize_string(str)
  str=str:gsub('"','')  
  str=str:gsub("'",'')  
  return str
end

-------------------------------------------------------------------------------
-- receives a string argument and turn it into a proper object or value
-- @param str (string), e.g. "renoise.song().transport.keyboard_velocity"
-- @return value (can be nil)
-- @return string, error message when failed

function xLib.parse_str(str)
  --TRACE("xLib.parse_str(str)",str)

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

-------------------------------------------------------------------------------
-- evaluate string, assign value to the resulting object 
-- @param str (string), e.g. "renoise.song().transport.keyboard_velocity"
-- @param value (vararg), any basic lua type
-- @return bool, false when failed
-- @return string, error message when failed

function xLib.set_obj_str_value(str,value)
  TRACE("xLib.parse_str(str,str_base,value)",str,value)

  -- wrap strings in quotes
  value = (type(value)=="string") and '"'..value..'"' or value

  local success,err = pcall(function()
    loadstring(str .. " = " .. tostring(value))()
  end)

  --print("success,err",success,err)
  if not success then
    return false,err
  else
    return true
  end

end

--------------------------------------------------------------------------------
-- serialize table into string, with some formatting options
-- @param t (table)
-- @param max_depth (int), determine how many levels to process - optional
-- @return table

function xLib.serialize_table(t,max_depth)

  assert(type(t) == "table", "this method accepts only a table as argument")

  local rslt = "{\n"
  --local max_depth = 3
  if not max_depth then
    max_depth = 9999
  end

  -- try serializing a value or return "???"
  local function serialize(obj)
    local succeeded, result = pcall(tostring, obj)
    if succeeded then
      -- replace return codes
      result=string.gsub(result,"\n","\\n") 
      return result 
    else
     return "???"
    end
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
      local str_key = (type(key) == "number") and "" or serialize(key) .. ' = ' 
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
        --print("got here",type(value))
        local str_quote = (type(value) == "string") and '"' or ""
        --local str_key = ordered and "" or serialize(key) .. ' = ' 
        result = result .. indent .. str_key .. str_quote .. serialize(value) .. str_quote .. ',\n'
      end
    end
    
    return result
  end

  rslt = rslt .. rdump(t) .. "}"
  --print(rslt)

  return rslt

end

