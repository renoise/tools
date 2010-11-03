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
           header[t[1]] = tostring(t[2])
        else
           header[k] = tostring(v)
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

-- URL-encode a string (see RFC 2396)
function Util:urlencode(str)
  str = tostring(str)
  str = string.gsub (str, "\n", "\r\n")
  str = string.gsub (str, "([^0-9a-zA-Z_/ ])", -- locale independent
    function (c) return string.format ("%%%02X", string.byte(c)) end)
  str = string.gsub (str, " ", "+")
  return str
  
end  

-- Decode an URL-encoded string (see RFC 2396)
function Util:urldecode(str)
  str = string.gsub (str, "+", " ")
  str = string.gsub (str, "%%(%x%x)", function(h) return string.char(tonumber(h,16)) end)
  str = string.gsub (str, "\r\n", "\n")
  return str
end

-- Generates a URL-encoded query string from the 
-- associative (or indexed) array provided.
-- @param data Table containing parameters. May be multi-dimensional.
-- @param prefix If numeric indices are used in the base table and this 
--   parameter is provided, it will be prepended to the numeric index for 
--   elements in the base table only.
-- @param sep '&' is used to separate arguments, unless this parameter is 
--   specified, and is then used.
-- @param _key Don't use. It's a temporary key used recursively.
function Util:http_build_query(data, prefix, sep, _key)
  local ret = table.create()
  local prefix = prefix or ''
  local sep = sep or '&'
  local _key = _key or ''

  for k,v in pairs(data) do
    if (type(k) == "number" and prefix ~= '') then
      k = Util:urlencode(prefix .. k)
    end
    if (_key ~= '' or _key == 0) then
      k = ("%s[%s]"):format(_key, Util:urlencode(k))
    end
    if (type(v) == 'table') then
      ret:insert(Util:http_build_query(v, '', sep, k))
    else
      ret:insert(("%s=%s"):format(k, Util:urlencode(v)))
    end
  end
  return ret:concat(sep)
end


function Util:get_extension(file)
    return file:match("%.(%a+)$")
end

function Util:trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function Util:split(str, pat)
   str = str or ''
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
function Util:merge_tables(a,b)
  for k,v in pairs(a) do
    if (type(v)=='table') then
      b[k] = Util:merge_tables(b[k], v)
    else
      b[k] = v
    end
  end
  return b
end
