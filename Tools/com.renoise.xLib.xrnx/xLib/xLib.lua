--[[============================================================================
xLib
============================================================================]]--
--[[

  The xLib library is a suite of classes that extend the standard Renoise API
  The core is comprised of a number of static properties and methods

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


xLib.COLOR_ENABLED = {0xD0,0x40,0x40}
xLib.COLOR_DISABLED = {0x00,0x00,0x00}
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
-- Match item(s) in an associative array (provide key)
-- @param t (table) 
-- @param key (string) 
-- @return table

function xLib.match_table_key(t,key)
  --TRACE("xLib.match_table_key(t,key)",t,key)
  
  local rslt = table.create()
  for k,v in pairs(t) do
    rslt:insert(v[key])
  end
  return rslt

end

--------------------------------------------------------------------------------
-- Split string 
-- @param str_input (string)
-- @param sep (string) separator

function xLib.split_string(str_input, sep)
  TRACE("xLib.split_string(str_input, sep)",str_input, sep)

  if sep == nil then
    sep = "%s"
  end
  local t={} 
  for str in string.gmatch(str_input, "([^"..sep.."]+)") do
    table.insert(t,str)
  end
  return t

end

-------------------------------------------------------------------------------
-- receives a string argument and turn it into a proper object or value
-- @param str (string), e.g. "renoise.song().transport.keyboard_velocity"
-- @return value (can be nil)
-- @return string, error message when failed

function xLib.parse_str(str)
  TRACE("xLib.parse_str(str)",str)

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
-- set a string-based object reference to a certain value
-- @param str (string), e.g. "renoise.song().transport.keyboard_velocity"
-- @param value (vararg), any basic lua type
-- @return string, error message when failed

function xLib.set_obj_str_value(str,value)
  TRACE("xLib.parse_str(str,str_base,value)",str,value)

  -- wrap strings in quotes
  value = (type(value)=="string") and '"'..value..'"' or value

  local success,err = pcall(function()
    loadstring(str .. " = " .. value)()
  end)

  if not success then
    return err
  end

end

--------------------------------------------------------------------------------
-- @return table

function xLib.get_thirdparty_libraries()

  local lib_path = xLib._renoise_library_path
  if (type(lib_path) == "nil") then
    error("You need to define xLib._renoise_library_path")
  end

  --print("lib_path",lib_path)

  local thirdparty_names = os.dirnames(lib_path.."/Installed Libraries")
  --rprint(thirdparty_names)

  return thirdparty_names

end

--------------------------------------------------------------------------------
-- @return table

function xLib.get_instrument_list()

  local zero_pad = function(str,count)
    return ("%0"..count.."s"):format(str) 
  end

  local rslt = table.create()
  for k,v in ipairs(rns.instruments) do
    local display_num = zero_pad(tostring(k-1),2)
    local display_name = v.name
    if (display_name == "") then
      display_name = "(Untitled Instrument)"
    end
    rslt:insert(("%s:%s"):format(display_num,display_name))
  end
  return rslt

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

  --[[
  if( type(obj) == 'table') then
    result = result .. rdump(obj)
  else
    result = result .. serialize(select(i, ...))
    if (i ~= n) then 
      result = result .. "\t"
    end
  end
  ]]

  rslt = rslt .. rdump(t) .. "}"
  --print(rslt)

  return rslt

end

--------------------------------------------------------------------------------
--- determine if ordered table (unequal amount of keys/indices)
-- @return bool
--[[
function xLib.table_is_ordered(t)

  local t_len = #t
  local t_keys = table.keys(t)
  return  ((t_len > 0) and (t_keys ~= t_len))

end
]]

