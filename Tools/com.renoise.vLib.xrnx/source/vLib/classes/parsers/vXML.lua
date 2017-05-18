--[[============================================================================
vXML
============================================================================]]--
--[[

Ability to parse xml into a vLib-friendly table representation 
.
#

TODO use cParseXML, share data with this class
 (retrieve, modify original document)

]]

class 'vXML' 

require (_clibroot.."cParseXML")

-------------------------------------------------------------------------------

function vXML:__init()

end

-------------------------------------------------------------------------------

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




