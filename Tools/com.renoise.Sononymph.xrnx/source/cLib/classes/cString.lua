--[[============================================================================
cString
============================================================================]]--

--[[--

Common string-manipulation methods
.
#

]]

class 'cString'

--------------------------------------------------------------------------------
-- split string - original script: http://lua-users.org/wiki/SplitJoin 
-- @param str (string)
-- @param pat (string) pattern
-- @return table

function cString.split(str, pat)
  TRACE("cString.split(str, pat)",str, pat)

   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
   table.insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      table.insert(t, cap)
   end
   return t

end

-------------------------------------------------------------------------------
-- remove trailing and leading whitespace from string.
-- http://en.wikipedia.org/wiki/Trim_(8programming)
-- @param s (string)
-- @return string

function cString.trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-------------------------------------------------------------------------------
-- capitalize first letter of every word
-- @param s (string)
-- @return string

function cString.capitalize(s)
  return string.gsub(" "..s, "%W%l", string.upper):sub(2)
end

-------------------------------------------------------------------------------
-- insert return code whenever we encounter dashes or spaces in a string
-- TODO keep dashes, and allow a certain length per line
-- @param str (string)
-- @return string

function cString.soft_wrap(str)

  local t = cString.split(str,"[-%s]")
  return table.concat(t,"\n")  

end

-------------------------------------------------------------------------------
-- detect counter in string (used for incrementing, unique names)

function cString.detect_counter_in_str(str)
  local count = string.match(str,"%((%d)%)$")
  if count then 
    str = string.gsub(str,"%s*%(%d%)$","")
  else
    count = 1
  end
  return count
end

-------------------------------------------------------------------------------
-- prepare a string so it can be stored in XML attributes
-- (strip illegal characters instead of trying to fix them)
-- @param str (string)
-- @return string

function cString.sanitize_string(str)
  str=str:gsub('"','')  
  str=str:gsub("'",'')  
  return str
end

--------------------------------------------------------------------------------
-- sortable time - date which can be sorted alphabetically
-- @return string

function cString.get_sortable_time(tstamp)

  --[[
  [day] =>  22
  [hour] =>  19
  [isdst] =>  true
  [min] =>  25
  [month] =>  5
  [sec] =>  58
  [wday] =>  6
  [yday] =>  142
  [year] =>  2015
  ]]
  local t = os.date("*t",tstamp)
  return ("%d/%.2d/%.2d  %.2d:%.2d"):format(
    t.year,t.month,t.day,t.hour,t.min)

end

---------------------------------------------------------------------------------------------------
-- format "beat" in the same way as Renoise does it 
--  e.g: [beat:line:fraction]
-- @param val (number), 
-- @return string 

function cString.format_beat(val)
  TRACE("cString.format_beat(val)",val)

  local line = cLib.fraction(val)*(40/10)
  local fract = cLib.fraction(line)*256
  return ("%d.%d.%d"):format(math.floor(val),math.floor(line),fract)

end

--------------------------------------------------------------------------------
-- Strip line matching pattern, from multiline string
-- @param str (string) 
-- @param patt (string) 
-- @return str, resulting string
-- @return int, #stripped lines 

function cString.strip_line(str,patt)
  TRACE("cString.strip_line(str,patt)",str,patt)
  
  local rslt = table.create()
  local captures = string.gmatch(str,"([^\n]*)\n")
  local line_count = 0
  for k in captures do
    if not (string.match(k,patt)) then
      rslt:insert(k)
    end
    line_count = line_count+1
  end

  local lines_stripped = line_count-#rslt
  return table.concat(rslt,"\n"),lines_stripped

end

--------------------------------------------------------------------------------
-- Strip leading and/or trailing character from string
-- @param str (string) the string to search
-- @param chr (string) the character to match, e.g. "\n" or " "
-- @param rlead (bool) remove leading 
-- @param rtrail (bool) remove trailing
-- @return str

function cString.strip_leading_trailing_chars(str,chr,rlead,rtrail)

  if rlead then
    while (string.sub(str,1,1)==chr) do
      str = string.sub(str,2,#str)
    end
  end
  
  if rtrail then
    while (string.sub(str,#str,#str)==chr) do
      str = string.sub(str,1,#str-1)
    end
  end
  
  return str

end


-------------------------------------------------------------------------------
-- present a lua table as a formatted string 
-- @param t (table)
-- @param args (table) formatting directives
--  multiline: if false, create single-line string
--  number_format: formatting for numeric values (e.g. precision)
-- @return string

function cString.table_to_string(t,args)
  TRACE("cString.table_to_string(t,args)",t,args)

  args = args or {}
  args.multiline = args.multiline or false
  args.number_format = args.number_format or "%f"

  local str = ""
  local linebr = args.multiline and "\n" or ""

  if table.is_empty(t) then
    return "{}"
  else
    str = str.."{"
    for k,v in ipairs(t) do
      if (type(v) == "string") then
        str = ("%s'%s',"):format(str,v)
      elseif (type(v) == "number") then
        str = ("%s"..args.number_format..","):format(str,v)
      elseif (type(v) == "table") then
        str = str.."{"
        for k2,v2 in pairs(v) do
          if (type(v2) == "string") then
            local val = (type(v2) == "string") and("'%s'"):format(v2) or v2
            str = ("%s%s = %s,"):format(str,k2,val)
          elseif (type(v2) == "number") then
            str = ("%s%s = "..args.number_format..","):format(str,k2,v2)
          elseif (type(v2) == "boolean") then
            str = ("%s%s = %s,"):format(str,k2,(v2) and "true" or "false")
          end
        end
        str = str.."},"..linebr
      end
    end
    str = str.."}"..linebr
  end

  return str

end

