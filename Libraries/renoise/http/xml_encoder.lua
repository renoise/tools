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
  local str = "" 
  
  for k,v in pairs(t) do            
    
    if (type(v)~="table" or not v[1]) then
      str = str .. "\n"    
    end
    for i=1,tabs do
      str = str .. TAB       
    end    
    if (type(v) == "table") then
      for i=1,tabs do
        closing_tabs = closing_tabs .. TAB
      end
      if (v[1]) then
        for _,w in ipairs(v) do
          local temp = {}
          temp[k] = w
          str = ("%s%s"):format(str,XmlEncoder:traverse(temp, tabs))
        end
      else
        str = ("%s<%s>%s\n%s</%s>"):format(
          str,k,XmlEncoder:traverse(v, tabs+1),closing_tabs,k)      
      end
    else 
      str = ("%s<%s>%s</%s>"):format(str,k,v,k)      
    end    
    
  end
  return str
end

function XmlEncoder:encode_table(t)
  local xml_str = ("%s%s"):format(
     "<?xml version='1.0' encoding='UTF-8' ?>",
     XmlEncoder:traverse(t)     
  )  
  return xml_str
end
