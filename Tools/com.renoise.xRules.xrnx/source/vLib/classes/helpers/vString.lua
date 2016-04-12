--[[============================================================================
vString
============================================================================]]--
--[[


]]


class 'vString'

--------------------------------------------------------------------------------
--- Static string-manipulation methods for the vString library

--------------------------------------------------------------------------------
-- Strip leading and/or trailing character from string
-- @param str (string) the string to search
-- @param chr (string) the character to match, e.g. "\n" or " "
-- @param rlead (bool) remove leading 
-- @param rtrail (bool) remove trailing
-- @return str

function vString.strip_leading_trailing_chars(str,chr,rlead,rtrail)

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

--------------------------------------------------------------------------------
-- Strip line matching pattern, from multiline string
-- @param str (string) 
-- @param patt (string) 
-- @return str, resulting string
-- @return int, #stripped lines 

function vString.strip_line(str,patt)
  
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
-- @param str (string), e.g. "33.3%"

function vString.string_to_percentage(str)
  return tonumber(string.sub(str,1,#str-1))
end

--------------------------------------------------------------------------------
-- sortable time - date which can be sorted alphabetically
-- @return string

function vString.get_sortable_time(tstamp)

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


-------------------------------------------------------------------------------
-- present a lua table as a formatted string 
-- @param t (table)
-- @param args (table) formatting directives
--  multiline: if false, create single-line string
--  number_format: formatting for numeric values (e.g. precision)
-- @return string

function vString.table_to_string(t,args)

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
