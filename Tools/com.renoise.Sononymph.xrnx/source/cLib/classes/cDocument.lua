--[[============================================================================
-- cDocument
============================================================================]]--

--[[--

Create lightweight classes with import/export features
.
#

For the cDocument to work, you need to define a static DOC_PROPS property.
You can define integers, floating point values, strings and booleans

    MyClass.DOC_PROPS = {
      { 
        name = "my_integer",    -- class/property name
        title = "IntegerValue", -- display name 
        value_min = 1,          -- only for numbers
        value_max = 12,         -- -//-
        value_quantum = 1,      -- -//-
        value_default = 4,      -- always define this!!
      },
      {
        name = "my_float",
        title = "A floating point value between 0-1",
        value_min = 0,
        value_max = 1,
        value_default = 0.0,
      },
    }



FIXME
  * Re-implement as ipairs (changed implementation)


--]]

--==============================================================================

require (_clibroot.."cReflection")

class 'cDocument'


--------------------------------------------------------------------------------
-- import serialized values that match one of our DOC_PROPS
-- @param str (string) serialized values 

function cDocument:import(str)

  assert(type(str)=="string")

  local t = cDocument.deserialize(str,self.DOC_PROPS)
  for k,v in pairs(t) do
    self[k] = v
  end

end

--------------------------------------------------------------------------------
-- @return string, serialized values

function cDocument:export()

  local t = cDocument.serialize(self,self.DOC_PROPS)
  return cLib.serialize_table(t)

end

--------------------------------------------------------------------------------
-- collect properties from object
-- @param obj (class instance)
-- @param props (table) DOC_PROPS
-- @return table 

function cDocument.serialize(obj,props)

  assert(type(props)=="table")

  local t = {}
  for k,v in pairs(props) do
    local property_type = props[k]
    if property_type then
      t[k] = cReflection.cast_value(obj[k],property_type)
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

function cDocument.deserialize(str,props)

  assert(type(str)=="string")
  assert(type(props)=="table")

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
        t[k] = cReflection.cast_value(deserialized[k],property_type)
      else
        t[k] = deserialized[k]
      end
    end
  end

  return t

end

--------------------------------------------------------------------------------
-- find property descriptor by key
-- @return table or nil

function cDocument.get_property(props,key)
  TRACE("cDocument.get_property(props,key)",props,key)

  assert(type(key)=="string")
  assert(type(props)=="table")

  for k,v in ipairs(props) do
    if (v.name == key) then
      return v,k
    end
  end

end

--------------------------------------------------------------------------------
-- apply value to object
-- * will clamp/cast value when outside range / wrong type
-- @return value (boolean,string,number)

function cDocument.apply_value(obj,prop,val)
  TRACE("cDocument.apply_value(obj,prop,val)",obj,prop,val)

  assert(type(prop)=="table")

  if type(prop.value_default)=="boolean" then

  elseif type(prop.value_default)=="string" then

  elseif type(prop.value_default)=="number" then

    if prop.value_max and prop.value_min then
      if (val > prop.value_max) then
        LOG("Clamp to range")
        val = prop.value_max
      elseif (val < prop.value_min) then
        LOG("Clamp to range")
        val = prop.value_min
      end
    end

    if prop.zero_based then
      val = val+1
    end

  else
    error("Unsupported value type")
  end

  if not (obj[prop.name] == val) then
    obj[prop.name] = val
    return val
  end

end

