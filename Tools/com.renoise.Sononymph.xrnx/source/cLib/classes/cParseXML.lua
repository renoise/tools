--[[============================================================================
cParseXML
============================================================================]]--
--[[

Ability to parse xml into a lua table
.
#

Based on/requires the slaxdom parser
TODO implement more xpath-alike methods

]]

class 'cParseXML' 

SLAXML = require (_clibroot.."/support/slaxdom/slaxml")
SLAXML = require (_clibroot.."/support/slaxdom/slaxdom")

-------------------------------------------------------------------------------
--- load and parse XML from disk
-- @return table or nil

function cParseXML.load_and_parse(file_path)
  TRACE('cParseXML.load_and_parse(file_path)',file_path)

  local str_xml = io.open(file_path):read('*all')
  return cParseXML.parse(str_xml)

end

-------------------------------------------------------------------------------
--- parse XML from string
-- @return table or nil

function cParseXML.parse(str_xml)
  TRACE('cParseXML.parse(str_xml)',str_xml)

  local doc = SLAXML:dom(str_xml,{ simple=true,stripWhitespace=true })

  return doc

end

-------------------------------------------------------------------------------
--- retrieve named attribute
-- @return table or nil

function cParseXML.get_attribute(doc,attr_name)
  TRACE('cParseXML.get_attribute(doc,attr_name)',doc,attr_name)

  if table.is_empty(doc) then
    return
  end

  if not table.is_empty(doc.kids) then
    for k,v in ipairs(doc.kids) do
      if (v.name == attr_name) then
        return v
      end
    end
  end

end

-------------------------------------------------------------------------------
--- retrieve property by path
-- @return table or nil

function cParseXML.get_node_by_path(doc,xpath)
  TRACE("cParseXML.get_node_by_path(doc,xpath)",doc,xpath)

  local parts = cString.split(xpath,"/")
  local node = doc
  for k,v in ipairs(parts) do
    node = cParseXML.get_attribute(node,v)
  end
  return node

end

-------------------------------------------------------------------------------
-- retrieve value of property 
-- @return string or nil

function cParseXML.get_node_value(node)
  TRACE("cParseXML.get_node_value(node)",node)

  if not node then
    return
  end
  if node.kids[1] then
    return node.kids[1].value
  end

end

