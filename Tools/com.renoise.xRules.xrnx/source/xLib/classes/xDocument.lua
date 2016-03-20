--[[============================================================================
-- xLib.xOscDevice
============================================================================]]--

--[[--

  Extend xDocument to create classes with basic import/export features

  For the xDocument to work, you need to define a static DOC_PROPS property, which will define the properties which should be included in exports/imports as well as their type (number,boolean,string)

  For example: 

    MyClass.DOC_PROPS = {
      active = "boolean",
      name = "string",
    }


--]]

--==============================================================================

class 'xDocument'


--------------------------------------------------------------------------------
-- import serialized values that match one of our DOC_PROPS
-- @param str (string) serialized values 

function xDocument:import(str)
  TRACE("xDocument:import(str)",str)

  local t = xDocument.deserialize(str,self.DOC_PROPS)
  for k,v in pairs(t) do
    self[k] = v
  end

end

--------------------------------------------------------------------------------
-- @return string, serialized values

function xDocument:export()
  TRACE("xDocument:export()")

  local t = xDocument.serialize(self,self.DOC_PROPS)
  return xLib.serialize_table(t)

end

--------------------------------------------------------------------------------
-- collect properties from object
-- @param obj (class instance)
-- @param props (table) DOC_PROPS
-- @return table 

function xDocument.serialize(obj,props)
  TRACE("xDocument.serialize(obj,props)",obj,props)

  local t = {}
  for k,v in pairs(props) do
    local property_type = props[k]
    if property_type then
      t[k] = xReflection.cast_value(obj[k],property_type)
    else
      t[k] = obj[k]
    end
  end
  return t

end

--------------------------------------------------------------------------------
-- deserialize string 
-- @param str (str) serialized string
-- @param props (table) DOC_PROPS
-- @return table or nil

function xDocument.deserialize(str,props)
  TRACE("xDocument.deserialize(str,props)",str,props)

  local t = loadstring("return "..str)
  local deserialized = t()
  if not deserialized then
    return
  end
  
  t = {}
  for k,v in pairs(props) do
    if deserialized[k] then
      local property_type = v
      if property_type then
        t[k] = xReflection.cast_value(deserialized[k],property_type)
      else
        t[k] = deserialized[k]
      end
    end
  end

  return t

end

