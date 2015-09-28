--[[============================================================================
xParseXML
============================================================================]]--
--[[

  Based on the implementation by Roberto Ierusalimschy,
  but adds support for underscores in attribute names!

  See also http://lua-users.org/wiki/LuaXml
  

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

