-- PHP style exlpode()
function explode(div,str)
  if (div=='') then return false end
  local pos,arr = 0,table.create()
  -- for each divider found
  for st,sp in function() return string.find(str,div,pos,true) end do
    table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
    pos = sp + 1 -- Jump past current divider
  end
  table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
  return arr
end


-- PHP style (int) type casting
function toint(num)
  num = tonumber(num)
  if num == nil then
    return 0
  else
    return math.floor(num)
  end
end


-- PHP style remove trailing and leading whitespace from string
function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end


-- Converts all delta times in track to absolute times
function _delta2Absolute(track)
  local mc = track:count()
  local last = 0
  for i=1,mc do
    local msg = explode(' ', track[i])
    local t = last + toint(msg[1])
    msg[1] = t
    track[i] = table.concat(msg, " ")
    last = t
  end
end


-- Variable length string to int (+repositioning)
function _readVarLen(str, pos)
  pos = pos + 1
  local value = str:byte(pos)
  if bit.band(value, 0x80) > 0 then
    local c = nil
    value = bit.band(value, 0x7F)
    repeat
      pos = pos + 1
      c = str:byte(pos)
      value = bit.lshift(value, 7) + bit.band(c, 0x7F)
    until bit.band(c, 0x80) <= 0
  end
  return value, pos
end


-- int to variable length string
function _writeVarLen(value)
  local buf = bit.band(value, 0x7F)
  local str = ""
  value = bit.rshift(value, 7)
  while value > 0 do
    buf = bit.lshift(buf, 8)
    buf = bit.bor(buf, bit.bor(bit.band(value, 0x7F), 0x80))
    value = bit.rshift(value, 7)
  end
  while true do
    str = str .. string.char(buf % 256)
    if bit.band(buf, 0x80) > 0 then
      buf = bit.rshift(buf, 8)
    else
      break
    end
  end
  -- print(str:byte())
  return str
end


-- int to bytes (length len)
function _getBytes(n, len)
  local str = ""
  for i = len-1, 0 , -1 do
    local tmp = math.floor(n / math.pow(256 , i))
    if tmp > 255 then
      local tmp2 = toint(tmp / 256) * 256
      tmp = tmp - tmp2
    end
    str = str .. string.char(toint(tmp))
  end
  return str
end


-- hexstr to binstr
function _hex2bin(hex_str)
  local bin_str = ""
  for i = 1, hex_str:len(), 2 do
    bin_str = bin_str .. string.char(tonumber(hex_str:sub(i, i + 2), 16))
  end
  return bin_str
end

