--[[============================================================================
vXML
============================================================================]]--
--[[

  Ability to parse xml into a lua table

]]

class 'vXML' 

SLAXML = require (_vlibroot.."/support/slaxdom/slaxml")
SLAXML = require (_vlibroot.."/support/slaxdom/slaxdom")

function vXML:__init()

  --[[
  self.parser = SLAXML:parser{
    startElement = function(name,nsURI,nsPrefix)       
      print('When "<foo" or <x:foo is seen')
    end, 
    attribute = function(name,value,nsURI,nsPrefix) 
      print('attribute found on current element',name,value,nsURI,nsPrefix)
    end, 
    closeElement = function(name,nsURI)                
      print('When "</foo>" or </x:foo> or "/>" is seen',name,nsURI)    
    end, 
    text = function(text)                      
      pinrt('text and CDATA nodes',text)    
    end, 
    comment = function(content)                   
      print('comments',content)
    end, 
    pi = function(target,content)            
      print('processing instructions e.g. "<?yes mon?>"',target,content)
    end, 
  }
  ]]

end

-------------------------------------------------------------------------------
-- recursively parse the slaxml and return a vLib-friendly representation 

function vXML:parse(xml_doc)
  TRACE('vXML:parse(xml_doc)',xml_doc.name)

  local function is_single_element(t)
    local depth = 0 
    while t and t.kids do
      depth = depth + 1
      t = t.kids[1]
    end
    return (depth == 1) and true or false
  end

  local rslt = {}
  
  if not table.is_empty(xml_doc.kids) then

    rslt.name = xml_doc.name
    for k,v in ipairs(xml_doc.kids) do
      rslt[k] = self:parse(v)
      if is_single_element(v) then
        rslt[k] = {
          expanded = false,
          name = v.name,
        }
      else
        rslt[k].expanded = true
        rslt.name = xml_doc.name
      end
    end

  end

  return rslt

end

-------------------------------------------------------------------------------
--- load and parse XML from disk

function vXML:load_and_parse(file_path)
  TRACE('vXML:parse_to_dom(str_xml)')

  local str_xml = io.open(file_path):read('*all')
  local xml_doc = SLAXML:dom(str_xml,{ simple=true,stripWhitespace=true })
  --rprint(xml_doc)

  return self:parse(xml_doc,{})

end



-------------------------------------------------------------------------------
--- retrieve named attribute

function vXML:get_attribute(doc,attr_name)
  TRACE('vXML:get_attribute(doc)')

  if not table.is_empty(doc.attr) then
    for k,v in ipairs(doc.attr) do
      if (v[attr_name]) then
        return v[attr_name]
      end
    end
  end

end

-------------------------------------------------------------------------------
--- retrieve value of first child

function vXML:get_first_value(doc,attr_name)
  TRACE('vXML:get_first_value(doc)')

  for k,v in pairs(doc.kids[1]) do
    if (k == "value") then
      return v
    end
  end

end




