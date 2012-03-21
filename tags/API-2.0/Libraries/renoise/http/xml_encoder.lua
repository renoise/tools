---------------------------------------------------------------
-- xml_encoder.lua
---------------------------------------------------------------
-- simple XML encoding for Lua tables
-- attributes not supported
---------------------------------------------------------------

XmlEncoder = {}

local TAB = "\t"

function XmlEncoder:traverse(t, tabs)
  local closing_tabs = ""
  tabs = tabs or 0
  local buffer = table.create()
  
  for k,v in pairs(t) do                
    if (type(k)=="number") then
      k = "data"
    end
    if (type(v)~="table" or not v[1]) then
      buffer:insert("\n")
    end
    for i=1,tabs do
      buffer:insert(TAB)
    end    
    if (type(v) == "table") then      
      for i=1,tabs do
        closing_tabs = closing_tabs .. TAB
      end
      if (v[1]) then
        for _,w in ipairs(v) do
          local temp = {}
          temp[k] = w
          buffer:insert(XmlEncoder:traverse(temp, tabs))
        end
      elseif (table.count(v) == 0) then
         buffer:insert( ("<%s />"):format(k) )
      else        
        buffer:insert( ("<%s>%s\n%s</%s>"):format(
          k,XmlEncoder:traverse(v, tabs+1),closing_tabs,k) )
      end
    else
      buffer:insert( ("<%s>%s</%s>"):format(k,tostring(v),k) )
    end    
    
  end
  return buffer:concat()
end

function XmlEncoder:encode_table(t)
  local xml_str = ("%s%s"):format(
     "<?xml version='1.0' encoding='UTF-8' ?>",
     XmlEncoder:traverse(t)     
  )  
  return xml_str
end
