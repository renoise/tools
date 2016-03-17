--[[============================================================================
xParseXML
============================================================================]]--
--[[

  Parsing is based on the implementation by Roberto Ierusalimschy, modified to support underscores in attribute names.

  (TODO) In addition to the raw XML parsing, the class can also convert a XML document into a native renoise.Document instance (particularly optimized for renoise-generated documents). 

  See also 
    http://lua-users.org/wiki/LuaXml 
  

]]

class 'xParseXML'

-------------------------------------------------------------------------------
-- @param str (string), string containing XML data
-- @return bool (true if success or false if failed)
-- @return table or string (error message when failed)

function xParseXML.parse(str)

  local err 
  local function parseargs(s)
    local arg = {}
    string.gsub(s, "([%-%w%_]+)=([\"'])(.-)%2", function (w, _, a)
    --string.gsub(s, "([%-%w%]+)=([\"'])(.-)%2", function (w, _, a)
      arg[w] = a
    end)
    --rprint(arg)
    return arg
  end
      
  local function collect(s)
    local stack = {}
    local top = {}
    table.insert(stack, top)
    local ni,c,label,xarg, empty
    local i, j = 1, 1
    while true do
      --ni,j,c,label,xarg, empty = string.find(s, "<(%/?)([%w:]+)(.-)(%/?)>", i)
      ni,j,c,label,xarg, empty = string.find(s, "<(%/?)([%w:_]+)(.-)(%/?)>", i)
      if not ni then break end
      local text = string.sub(s, i, ni-1)
      if not string.find(text, "^%s*$") then
        table.insert(top, text)
      end
      if empty == "/" then  -- empty element tag
        table.insert(top, {label=label, xarg=parseargs(xarg), empty=1})
      elseif c == "" then   -- start tag
        top = {label=label, xarg=parseargs(xarg)}
        table.insert(stack, top)   -- new level
      else  -- end tag
        local toclose = table.remove(stack)  -- remove top
        top = stack[#stack]
        if #stack < 1 then
          return "nothing to close with "..label 
        end
        if toclose.label ~= label then
          return "trying to close "..toclose.label.." with "..label
        end
        table.insert(top, toclose)
      end
      i = j+1
    end
    local text = string.sub(s, i)
    if not string.find(text, "^%s*$") then
      table.insert(stack[#stack], text)
    end
    if #stack > 1 then
      return "unclosed "..stack[#stack].label
    end
    return stack[1]
  end

  local rslt = collect(str)
  if (type(rslt) == "table") then
    return true, rslt
  else
    return false, err
  end


end

-------------------------------------------------------------------------------
-- Convert a (parsed) table into a renoise.Document
--
--  This is the expected structure:
--  (the method should be able to create a 100% identical version of any
--  renoise-generated document, but might fail with other sources)
--
--   [1] <?xml version="1.0" encoding="UTF-8"?>
--   [2] table
--     [...] content nodes
--      -- single index means property (defines a label)
--      -- multiple indices means list 
--      -- multiple indices with "xarg.type" means document list
--     [label] "DocumentName"
--     [xarg] 
--       [doc_version] = 0

--[[
function xParseXML.to_document(t)
  TRACE("xParseXML.to_document(t)",t)

  if (#t ~= 2) then
    error("Unexpected document format, cannot continue")
  end

  -- create the basic document
  local doc = renoise.Document.create(t[2]["label"]){}
  for k,v in ipairs(t[2]) do
    --print(">>>",k,v,#v)
    --print("v.label",v.label,v[1])
    if not (v[1][1]) then -- property
      doc:add_property(v.label,v[1])
    else -- list
      doc:add_property(v.label,xParseXML.process_list(v))
    end
  end

  return doc

end

-------------------------------------------------------------------------------
-- @param t, table

function xParseXML.process_list(t)
  TRACE("xParseXML.process_list(t)",t)

  local rslt, list_type

  if (t[1].xarg.type) then
    -- document list
    list_type = "document"
    rslt = renoise.Document.DocumentList()
  else
    -- number/string/boolean list
    -- figure out the type by sampling a value
    --print("sample value from list",t[1][1],type(t[1][1]))
    list_type = type(t[1][1])
    if (list_type == "boolean") then
      rslt = renoise.Document.ObservableBooleanList()
    elseif (list_type == "number") then
      rslt = renoise.Document.ObservableNumberList()
    elseif (list_type == "string") then
      rslt = renoise.Document.ObservableStringList()
    else
      error("Unexpected node-type, cannot continue")
    end
  end
  --print("rslt",rslt,type(rslt))

  -- iterate through entries
  for k,v in ipairs(t) do
    --print("k,v",k,v,list_type)
    if (list_type == "document") then
      -- look for "lua_model:[classname]" 
      rslt:insert(xParseXML.process_document(v))
    else
      rslt:insert(v[1])
    end
  end

  return rslt

end

-------------------------------------------------------------------------------
-- @param t, table

function xParseXML.process_document(t)
  TRACE("xParseXML.process_document(t)",t)

  local model_name 
  if (t.xarg.type) then
    --print("t.xarg.type",t.xarg.type)
    local first,last = string.find(t.xarg.type,"lua_model:")
    --print('first,last',first,last)
    model_name = string.sub(t.xarg.type,last+1)
  else
    model_name = "UntitledModel"
  end

  local doc = renoise.Document.create(model_name){}
  for k,v in ipairs(t) do
    if not v[1] then
      -- ambiguous/nil value (skip)
      -- TODO resolve by checking if the given model
      -- is loaded into memory - and contain NODE_NAME info      
    else
      --print("k,v",k,v[1],type(v[1]))
      doc:add_property(v.label,v[1])
    end
  end

  return doc

end
]]

