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
-- @return table 

function xDocument:serialize()

  local t = {}
  for k,v in pairs(self.DOC_PROPS) do
    local property_type = self.DOC_PROPS[k]
    if property_type then
      t[k] = xReflection.cast_value(self[k],property_type)
    else
      t[k] = self[k]
    end
  end
  return t

end

--------------------------------------------------------------------------------
-- import serialized values that match one of our DOC_PROPS
-- @param str (string) serialized values 

function xDocument:import(str)

  local t = loadstring("return "..str)
  local deserialized = t()
  --print("deserialized",deserialized,type(deserialized))
  if not deserialized then
    return
  end

  for k,v in pairs(self.DOC_PROPS) do
    --print("DOC_PROPS",k,v)
    if deserialized[k] then
      --print("xDocument:import - about to set",k,v,deserialized[k])
      local property_type = v
      if property_type then
        self[k] = xReflection.cast_value(deserialized[k],property_type)
      else
        self[k] = deserialized[k]
      end
      --print(">>> xDocument:import - set",k,v,self[k],type(self[k]))

    end
  end
end

--------------------------------------------------------------------------------
-- @return string, serialized values

function xDocument:export()
  local t = self:serialize()
  return xLib.serialize_table(t)
end

--------------------------------------------------------------------------------
-- populate the class with values from document-node or table (xParseXML)
-- @param arg, DocumentNode or table 
--[[
function xDocument:import(arg)
  
  --print("xDocument:import - arg type",type(arg))

  if (type(arg) == "DocumentNode") then
    for k,v in pairs(self.DOC_PROPS) do
      --print("importing property:",k,arg[k],type(arg[k]))
      self[k] = arg[k].value
    end
  elseif (type(arg) == "table") then 
    -- convert to node, then import
    local node = xParseXML.to_document(arg)
    self:import(node)
    
  else
    error("Unexpected format, please supply a DocumentNode or table")
  end

end

--------------------------------------------------------------------------------
-- export properties to a document-node
-- @return renoise.Document

function xDocument:export()

  local t = self:serialize()
  local doc = renoise.Document.create(type(self)){}
  for k,v in pairs(t) do
    --print("export property",k,v,type(v))
    doc:add_property(k,v)
  end
  return doc

end
]]
