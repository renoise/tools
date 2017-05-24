--[[===============================================================================================
cReflection
===============================================================================================]]--

--[[--

Pull off some API tricks to achieve reflection-alike abilities.

##

]]

--=================================================================================================

class 'cReflection'

---------------------------------------------------------------------------------------------------
-- Copy properties from one class instance to another
-- @param from_class (userdata)
-- @param to_class (userdata)
-- @param level (int) for internal use
-- @return bool, true when copied

function cReflection.copy_object_properties(from_class,to_class,level)

  if (type(from_class) ~= type(to_class))then
    LOG("*** Classes need to be of an identical type:",
      type(from_class),type(to_class))
    return false
  end

  local level = level or 0
  local max_level = 1
  local capture = cReflection.get_object_info(from_class)

  local copy_property = function(val,target_class,prop_name)
    target_class[prop_name] = val
  end

  local iter = capture:gmatch("([%a_]+)")
  for prop in iter do
    if (prop:find("_observable")) then
      -- skip observables 
    elseif not cReflection.is_standard_type(type(from_class[prop])) then
      if (level < max_level) then
        cReflection.copy_object_properties(from_class[prop],to_class[prop],level+1)
      end
    else
      --props_table[prop] = c[prop]
      local success = pcall(copy_property,from_class[prop],to_class,prop)
      if not success then
      end
    end
  end

  return true

end

---------------------------------------------------------------------------------------------------
-- cast variable as basic datatype (boolean,number,string)

function cReflection.cast_value(val,val_type)

  if (val_type == "boolean") then
    if (type(val) == "boolean") then
      return val
    elseif (type(val) == "string") then
      if (val == "true") or (val == "1") then
        return true
      else
        return false
      end
    elseif (type(val) == "number") then
      if (val == 1) then
        return true
      else
        return false
      end
    else
      error("Could not cast value as boolean")
    end

  elseif (val_type == "string") then
    return tostring(val)
  elseif (val_type == "number") then
    return tonumber(val)
  else
    error("Unsupported datatype")
  end

end

---------------------------------------------------------------------------------------------------
-- get properties from class instance 
-- @param class (userdata)
-- @param level (int) internal counter
-- @return table

function cReflection.get_object_properties(class,level)

  local level = level or 0
  local max_level = 1
  local capture = cReflection.get_object_info(class)
  local props_table = {}
  local iter = capture:gmatch("([%a_]+)")
  for prop in iter do
    if (prop:find("_observable")) then
      -- skip observables 
    elseif not cReflection.is_standard_type(type(class[prop])) then
      if (level < max_level) then
        props_table[prop] = cReflection.get_object_properties(class[prop],level+1)
      end
    else
      props_table[prop] = class[prop]
    end
  end

  return props_table

end

---------------------------------------------------------------------------------------------------
-- get information about native object (renoise API)

function cReflection.get_object_info(class)

  local str = objinfo(class)
  local begin1,begin2 = str:find("properties:")
  local end1 = str:find("methods:")
  return str:sub(begin2+1,end1-1)

end

---------------------------------------------------------------------------------------------------
-- @param val (string), the type we want to check
-- @return int, or nil if not a recognized type

function cReflection.is_standard_type(val)

    return table.find({
      "nil",
      "boolean",
      "number",
      "string",
      "table",
      "function",
      "thread"
    },val) 

end

---------------------------------------------------------------------------------------------------
-- evaluate string, assign value to the resulting object 
-- @param str (string), e.g. "renoise.song().transport.keyboard_velocity"
-- @param value (vararg), any basic lua type
-- @return boolean, string (error message when failed)

function cReflection.set_property(str,value)

  -- wrap strings in quotes
  value = (type(value)=="string") and '"'..value..'"' or value

  local success,err = pcall(function()
    loadstring(str .. " = " .. tostring(value))()
  end)

  if not success then
    return false,err
  else
    return true
  end

end


---------------------------------------------------------------------------------------------------
-- @param str (string), name of indentifier 
-- @return boolean, string (error message when failed)

function cReflection.is_valid_identifier(str)

  if string.match(str,"^%d+") then
    return false, ("'%s' is not a valid identifier (avoid using number as the first character)"):format(str)
  end
  local match = string.match(str,"[_%w]*")
  if match and (#match == #str) then
    return true
  else
    return false, ("'%s' is not a valid identifier (avoid using special characters)"):format(str)
  end

end
