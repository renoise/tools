--[[============================================================================
xReflection
============================================================================]]--
--[[

	Lacking proper reflection, pull off some API tricks to a similar result

]]

class 'xReflection'

--------------------------------------------------------------------------------
-- Copy properties from one class instance to another
-- @param from_class (userdata)
-- @param to_class (userdata)
-- @return bool, true when copied

function xReflection.copy_object_properties(from_class,to_class,level)
  TRACE("xReflection.copy_object_properties(from_class,to_class)",from_class,to_class)

  if (type(from_class) ~= type(to_class))then
    LOG("*** Classes need to be of an identical type:",
      type(from_class),type(to_class))
    return false
  end

  local level = level or 0
  local max_level = 1
  local capture = xReflection.get_object_info(from_class)

  local copy_property = function(val,target_class,prop_name)
    --print("*** copy_property",prop_name,val,target_class,"current=",target_class[prop_name])
    target_class[prop_name] = val
  end

  local iter = capture:gmatch("([%a_]+)")
  for prop in iter do
    --print("*** prop",prop,type(from_class[prop]),objinfo(from_class[prop]))
    if (prop:find("_observable")) then
      -- skip observables 
    elseif not xReflection.is_standard_type(type(from_class[prop])) then
      if (level < max_level) then
        --print("*** recursively check",level+1)
        xReflection.copy_object_properties(from_class[prop],to_class[prop],level+1)
      end
    else
      --props_table[prop] = c[prop]
      local success = pcall(copy_property,from_class[prop],to_class,prop)
      if not success then
        --print("*** failed copy of property",prop)
      end
    end
  end

  return true

end

--------------------------------------------------------------------------------
-- get properties from class instance 
-- @param class (userdata)
-- @return table

function xReflection.get_object_properties(class,level)
  TRACE("xReflection.get_object_properties(class,level)",class,level)

  local level = level or 0
  local max_level = 1
  local capture = xReflection.get_object_info(class)
  local props_table = {}
  local iter = capture:gmatch("([%a_]+)")
  for prop in iter do
    --print("*** prop",prop)
    if (prop:find("_observable")) then
      -- skip observables 
    elseif not xReflection.is_standard_type(type(class[prop])) then
      if (level < max_level) then
        props_table[prop] = xReflection.get_object_properties(class[prop],level+1)
      end
    else
      props_table[prop] = class[prop]
    end
  end

  return props_table

end

--------------------------------------------------------------------------------
-- get properties from class instance 

function xReflection.get_object_info(class)

  local str = objinfo(class)
  --print("objinfo",str,class,type(class))
  local begin1,begin2 = str:find("properties:")
  local end1 = str:find("methods:")
  return str:sub(begin2+1,end1-1)

end


--------------------------------------------------------------------------------
-- @param val (string), the type we want to check
-- @return int, or nil if not a recognized type

function xReflection.is_standard_type(val)

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

--------------------------------------------------------------------------------
-- @param str (string), name of indentifier 
-- @return bool, true when a valid lua indentifier 

function xReflection.is_valid_identifier(str)
  local p = "[_%w]*"
  local match = string.match(str,p)
  return match and (#match == #str)
end
