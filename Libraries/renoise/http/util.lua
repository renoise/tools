-------------------------------------------------------------------------------
--  Description
-------------------------------------------------------------------------------

-- This Utility library offers various general purpose functions related to
-- web, socket and Renoise programming.

-- Author: bantai [marvin@renoise.com]


-------------------------------------------------------------------------------
--  Dependencies
-------------------------------------------------------------------------------

require "renoise.http.url"


-------------------------------------------------------------------------------
--  Util class
-------------------------------------------------------------------------------

class 'Util'

function Util:split_lines(str)
  local t = {}
  local function helper(line) table.insert(t, line) return "" end
  helper((str:gsub("(.-)\r?\n", helper)))
  return t
end

function Util:parse_message(m)
  local lines = m
  if (type(m) == "string") then
    lines = Util:split_lines(m)
  end
  assert(type(lines) == "table", "Variable 'lines' is not of type table.")
  local s = false
  local header = table.create()
  local body = ""
  local header_size, body_size = 0, 0
  header["Content-Length"] = 0
  local t = {}
  for k,v in ipairs(lines) do
     if v:match("^$") then s = true end
     if not s then
        t = Util:split(v,": ")        
        if #t == 2 then
           header[t[1]] = tostring(t[2]):lower()
        else
           header[k] = tostring(v):lower()
        end
        header_size = header_size + #v
     else        
        --body[k] = v
        body=body..v.."\r\n"
        body_size = body_size + #v
     end
  end  
  return header, body, header_size, body_size
end

function Util:parse(url, default)
  return URL:parse(url, default)    
end

function Util:read_file(file_path, binary)
  local mode = "r"
  if binary then mode = "rb" end
  local file_ref,err = io.open(file_path, mode)
  if not err then
    local data=file_ref:read("*all")        
    io.close(file_ref)    
    return data
  else
    return nil,err;
  end
end

-- Compute the difference in seconds between local time and UTC.
function Util:get_timezone()
  local now = os.time()
  return os.difftime(now, os.time(os.date("!*t", now)))
end

-- Return a timezone string in ISO 8601:2000 standard form (+hhmm or -hhmm)
function Util:get_tzoffset()
  local h, m = math.modf(Util:get_timezone() / 3600)
  return string.format("%+.4d", 100 * h + 60 * m)
end

function Util:get_date(time) 
  return os.date("%a, %d %b %Y %X " .. Util:get_tzoffset(), time)
end

-- TODO encode html entities
function Util:html_entity_encode(str)
  return str:gsub("[ %c]", "%%20")  
end  

-- TODO decode html entities
function Util:html_entity_decode(str)
  local a,b = str:gsub("%%20", " ")
  a,b = a:gsub("%+", " ")  
  a,b = a:gsub("%%5B", "[")
  a,b = a:gsub("%%5D", "]")
  return a
end

function Util:get_extension(file)
    return file:match("%.(%a+)$")
end

function Util:trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function Util:split(str, pat)
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

-- Assumes "#comment" is a comment, "value  key_1 key_2"
function Util:parse_config_file(filename)
   local str = Util:read_file(Util.root .. filename)
   local lines = Util:split_lines(str)
   local t = {}
   local k, v = nil
   for _,l in ipairs(lines) do
      if not l:find("^(%s*)#") then
        local a = Util:split(l, "%s+")
           for i=2,#a do
              t[a[i]] = a[1]
           end
      end
   end
   return t
end
