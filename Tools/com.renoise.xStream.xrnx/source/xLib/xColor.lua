--[[============================================================================
xColor
============================================================================]]--
--[[

	Static methods for dealing with color

]]

class 'xColor'

--------------------------------------------------------------------------------
-- brighten/darken color by variable amount 
-- @param t (table{r,g,b})
-- @param amt (number) 0 = black, 0.5 = neutral, 1 = white
-- @return table

function xColor.adjust_brightness(t,amt)
  --print("xColor.adjust_brightness(t,amt)",t,amt)

  t = table.rcopy(t)

  local do_brighten = (amt > 0.5)
  if do_brighten then
    local brighten_factor = (amt-0.5)*2
    --print("brighten_factor",brighten_factor)
    for k,v in ipairs(t) do
      t[k] = t[k] + ((255-t[k])*brighten_factor)
    end
  else
    local darken_factor = 1-(amt*2)
    --print("darken_factor",darken_factor)
    for k,v in ipairs(t) do
      t[k] = t[k] - (t[k]*darken_factor)
    end
  end

  return {
    math.floor(t[1]),
    math.floor(t[2]),
    math.floor(t[3]),
  }

end


--------------------------------------------------------------------------------
-- convert r,g,b into numeric representation valid for hex display (#RRGGBB)
-- @param t (table)
-- @return number

function xColor.color_table_to_value(t)
  return t[1]*0x10000 + t[2]*0x100 + t[3]
end

--------------------------------------------------------------------------------
-- convert r,g,b table to string representation (e.g. "0xFFCC66")
-- @param t (table)
-- @return string

function xColor.color_table_to_hex_string(t)

  local val = xColor.color_table_to_value(t)
  return xColor.value_to_hex_string(val)

end

--------------------------------------------------------------------------------
-- convert numeric representation into r,g,b table
-- @param val (int)
-- @return (table)

function xColor.value_to_color_table(val)
  local r = math.floor(val/0x10000)
  local g = math.floor(val/0x100) - (r*0x100)
  local b = val - ((r*0x10000)+(g*0x100))
  return {r,g,b}
end

--------------------------------------------------------------------------------
-- convert value to hexadecimal string (e.g. 0xFFCC66)
-- @param val (int)
-- @return string

function xColor.value_to_hex_string(val)
  return ("0x%.6X"):format(val)
end

--------------------------------------------------------------------------------
-- convert hexadecimal string to value 
-- @param str (string), e.g. "5FEC99", "#5FEC99" or "0x5FEC99"
-- @return int or nil if unable to convert

function xColor.hex_string_to_value(str_val)

  -- strip prefixes "#" or "0x" 
  if (string.sub(str_val,1,1)=="#") then
    str_val = string.sub(str_val,2,#str_val)
  end

  if (string.sub(str_val,1,2)=="0x") then
    str_val = string.sub(str_val,3,#str_val)
  end

  local rslt = tonumber("0x"..str_val)

  if rslt and (rslt <= 0xFFFFFF) then
    return rslt
  end

end

