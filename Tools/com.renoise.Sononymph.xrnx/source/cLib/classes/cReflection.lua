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
  TRACE("cReflection.copy_object_properties(from_class,to_class,level)",from_class,to_class,level)

  if (type(from_class) ~= type(to_class))then
    LOG("*** Classes need to be of an identical type:",
      type(from_class),type(to_class))
    return false
  end
  
  local copy_property = function(val,target_class,prop_name)
    target_class[prop_name] = val
  end
  
  local level = level or 0
  local max_level = 1
  local props = cReflection.get_object_info(from_class)
  for _,prop in ipairs(props) do
    if (prop:find("_observable")) then
      -- skip observables 
    elseif not cReflection.is_standard_type(from_class[prop]) then
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
-- [Static] cast a value to boolean, provide fallback value if undefined
-- (can be used for setting arguments)

function cReflection.as_boolean(val,fallback)
  if (type(val)=="nil") then 
    return fallback
  else 
    return cReflection.cast_value(val,"boolean")
  end
end

---------------------------------------------------------------------------------------------------
-- cast variable as basic datatype (boolean,number,string)

function cReflection.cast_value(val,val_type)
  TRACE("cReflection.cast_value(val,val_type)",val,val_type)

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
-- @return table

function cReflection.get_object_properties(class,_level)
  TRACE("cReflection.get_object_properties(class,_level)",class,_level)

  local props_table = {}
  local level = _level or 0
  local max_level = 1
  local props = cReflection.get_object_info(class)
  for _,prop in ipairs(props) do
    if (prop:find("_observable")) then
      -- skip observables 
      --print("skipped observable property",prop)
    elseif not cReflection.is_standard_type(class[prop]) then
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
-- get native object properties (renoise API)
-- @return table or nil  

function cReflection.get_object_info(class)
  TRACE("cReflection.get_object_info(class)",class)

  local rslt = {}
  local str = objinfo(class)
  local begin1,begin2 = str:find("properties:")
  if begin2 then 
    local end1 = str:find("methods:")
    local capture = str:sub(begin2+1,end1-1)
    for prop in capture:gmatch("([%a_]+)") do 
      table.insert(rslt,prop)
    end
  end
  return rslt
end

---------------------------------------------------------------------------------------------------
-- @param val (any)
-- @return boolean

function cReflection.is_standard_type(val)

  return table.find({
    "nil",
    "boolean",
    "number",
    "string",
    "table",
    "function",
    "thread"
  },type(val))

end

---------------------------------------------------------------------------------------------------
-- check if a given value is serializable
-- @param val (any)
-- @return boolean

function cReflection.is_serializable_type(val)

  return table.find({
    "boolean",
    "number",
    "string",
    "table",
  },type(val))

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
-- attempt to evaluate expression in string
-- TODO run in sandbox 
-- @return number or nil 

function cReflection.evaluate_string(x)
  TRACE("cReflection.evaluate_string(x)",x)
  local num
  local x_str = 'return '..x
  if (pcall(loadstring(x_str)) == false or loadstring(x_str)()==nil) then  
    return nil
  else 
    num=loadstring(x_str)()
  end
  return tonumber(num)
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
