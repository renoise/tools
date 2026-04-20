-- mcp/json.lua
-- Minimal but complete JSON encoder/decoder for Lua 5.1

local M = {}

--------------------------------------------------------------------------------
-- Encoder
--------------------------------------------------------------------------------

local encode_value  -- forward declaration

local ESC = {
  ['"']  = '\\"',
  ['\\'] = '\\\\',
  ['\n'] = '\\n',
  ['\r'] = '\\r',
  ['\t'] = '\\t',
  ['\b'] = '\\b',
  ['\f'] = '\\f',
}

local function encode_string(s)
  return '"' .. s:gsub('["\\\n\r\t\b\f]', ESC):gsub('%z', '\\u0000') .. '"'
end

local function encode_array(t, stack)
  local parts = {}
  for i = 1, #t do
    parts[i] = encode_value(t[i], stack)
  end
  return '[' .. table.concat(parts, ',') .. ']'
end

local function encode_object(t, stack)
  local parts = {}
  for k, v in pairs(t) do
    if type(k) == 'string' then
      parts[#parts + 1] = encode_string(k) .. ':' .. encode_value(v, stack)
    end
  end
  return '{' .. table.concat(parts, ',') .. '}'
end

encode_value = function(val, stack)
  local t = type(val)
  if t == 'nil' then
    return 'null'
  elseif t == 'boolean' then
    return val and 'true' or 'false'
  elseif t == 'number' then
    if val ~= val or val == math.huge or val == -math.huge then
      return 'null'
    end
    -- Avoid scientific notation for integers
    if math.floor(val) == val and math.abs(val) < 1e15 then
      return string.format('%d', val)
    end
    return tostring(val)
  elseif t == 'string' then
    return encode_string(val)
  elseif t == 'table' then
    if stack[val] then return 'null' end  -- cycle guard
    stack[val] = true
    -- Detect array: sequential integer keys starting at 1
    local n = #val
    local is_array = (n > 0)
    if is_array then
      for k in pairs(val) do
        if type(k) ~= 'number' or k < 1 or k > n or k ~= math.floor(k) then
          is_array = false
          break
        end
      end
    end
    local result
    if is_array then
      result = encode_array(val, stack)
    else
      result = encode_object(val, stack)
    end
    stack[val] = nil
    return result
  else
    return 'null'
  end
end

function M.encode(val)
  return encode_value(val, {})
end

--------------------------------------------------------------------------------
-- Decoder
--------------------------------------------------------------------------------

local decode_value  -- forward declaration

local function skip_ws(s, i)
  while i <= #s do
    local c = s:sub(i, i)
    if c ~= ' ' and c ~= '\t' and c ~= '\n' and c ~= '\r' then break end
    i = i + 1
  end
  return i
end

local function decode_string(s, i)
  -- i is at the opening '"'
  i = i + 1
  local buf = {}
  while i <= #s do
    local c = s:sub(i, i)
    if c == '"' then
      return table.concat(buf), i + 1
    elseif c == '\\' then
      i = i + 1
      local e = s:sub(i, i)
      if     e == '"'  then buf[#buf+1] = '"'
      elseif e == '\\' then buf[#buf+1] = '\\'
      elseif e == '/'  then buf[#buf+1] = '/'
      elseif e == 'n'  then buf[#buf+1] = '\n'
      elseif e == 'r'  then buf[#buf+1] = '\r'
      elseif e == 't'  then buf[#buf+1] = '\t'
      elseif e == 'b'  then buf[#buf+1] = '\b'
      elseif e == 'f'  then buf[#buf+1] = '\f'
      elseif e == 'u'  then
        local hex = s:sub(i+1, i+4)
        local cp = tonumber(hex, 16) or 0
        -- Simple BMP encoding; encode as UTF-8
        if cp < 0x80 then
          buf[#buf+1] = string.char(cp)
        elseif cp < 0x800 then
          buf[#buf+1] = string.char(0xC0 + math.floor(cp/64), 0x80 + (cp%64))
        else
          buf[#buf+1] = string.char(
            0xE0 + math.floor(cp/4096),
            0x80 + math.floor((cp%4096)/64),
            0x80 + (cp%64))
        end
        i = i + 4
      else
        buf[#buf+1] = e
      end
      i = i + 1
    else
      buf[#buf+1] = c
      i = i + 1
    end
  end
  return nil, i, 'unterminated string'
end

local function decode_number(s, i)
  local num_str = s:match('^-?%d+%.?%d*[eE]?[+-]?%d*', i)
  if num_str then
    return tonumber(num_str), i + #num_str
  end
  return nil, i, 'invalid number'
end

local function decode_array(s, i)
  i = i + 1  -- skip '['
  local arr = {}
  i = skip_ws(s, i)
  if s:sub(i,i) == ']' then return arr, i + 1 end
  while true do
    local val, new_i, err = decode_value(s, i)
    if err then return nil, new_i, err end
    arr[#arr+1] = val
    i = skip_ws(s, new_i)
    local c = s:sub(i,i)
    if c == ']' then return arr, i + 1
    elseif c == ',' then i = skip_ws(s, i + 1)
    else return nil, i, 'expected , or ] in array'
    end
  end
end

local function decode_object(s, i)
  i = i + 1  -- skip '{'
  local obj = {}
  i = skip_ws(s, i)
  if s:sub(i,i) == '}' then return obj, i + 1 end
  while true do
    i = skip_ws(s, i)
    if s:sub(i,i) ~= '"' then return nil, i, 'expected string key' end
    local key, new_i, err = decode_string(s, i)
    if err then return nil, new_i, err end
    i = skip_ws(s, new_i)
    if s:sub(i,i) ~= ':' then return nil, i, 'expected colon' end
    i = skip_ws(s, i + 1)
    local val
    val, i, err = decode_value(s, i)
    if err then return nil, i, err end
    obj[key] = val
    i = skip_ws(s, i)
    local c = s:sub(i,i)
    if c == '}' then return obj, i + 1
    elseif c == ',' then i = i + 1
    else return nil, i, 'expected , or } in object'
    end
  end
end

decode_value = function(s, i)
  i = skip_ws(s, i)
  if i > #s then return nil, i, 'unexpected end of input' end
  local c = s:sub(i,i)
  if c == '"' then
    return decode_string(s, i)
  elseif c == '{' then
    return decode_object(s, i)
  elseif c == '[' then
    return decode_array(s, i)
  elseif c == 't' then
    if s:sub(i, i+3) == 'true' then return true, i+4 end
  elseif c == 'f' then
    if s:sub(i, i+4) == 'false' then return false, i+5 end
  elseif c == 'n' then
    if s:sub(i, i+3) == 'null' then return nil, i+4 end
  elseif c == '-' or c:match('%d') then
    return decode_number(s, i)
  end
  return nil, i, 'unexpected character: ' .. c
end

function M.decode(s)
  if type(s) ~= 'string' then return nil, 'input must be a string' end
  local val, _, err = decode_value(s, 1)
  if err then return nil, err end
  return val
end

return M
