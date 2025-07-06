--[[============================================================================
cColor
============================================================================]]--
--[[

	Static methods for dealing with color

]]

class 'cColor'

--------------------------------------------------------------------------------
-- brighten/darken color by variable amount, using HSV color space
-- @param t (table{r,g,b})
-- @param amt (number) 0 = black, 0.5 = neutral, 1 = white
-- @return table

function cColor.adjust_brightness(rgb,amt)
  TRACE("cColor.adjust_brightness(rgb,amt)",rgb,amt)

  rgb = table.rcopy(rgb)

  local hsv = cColor.rgb_to_hsv(rgb)
  if (amt > 0.5) then
    local factor = (amt-0.5)*2
    hsv[3] = hsv[3] + ((1-hsv[3]) * factor)
  else
    local factor = 1-(amt*2)
    hsv[3] = hsv[3] * factor
  end

  return cColor.hsv_to_rgb(hsv)

end

--------------------------------------------------------------------------------
-- get average from color
-- @param color (table<int,int,int>) 
-- @return number 

function cColor.get_average(color)
  return (color[1]+color[2]+color[3])/3
end

--------------------------------------------------------------------------------
-- convert r,g,b into numeric representation valid for hex display (#RRGGBB)
-- @param t (table)
-- @return number

function cColor.color_table_to_value(t)
  return t[1]*0x10000 + t[2]*0x100 + t[3]
end

--------------------------------------------------------------------------------
-- convert r,g,b table to string representation (e.g. "0xFFCC66")
-- @param t (table)
-- @param [prefix], string - e.g. "#" to return CSS-style color 
-- @return string

function cColor.color_table_to_hex_string(t,prefix)

  local val = cColor.color_table_to_value(t)
  return cColor.value_to_hex_string(val,prefix)

end

--------------------------------------------------------------------------------
-- convert numeric representation into r,g,b table
-- @param val (int)
-- @return (table)

function cColor.value_to_color_table(val)
  local r = math.floor(val/0x10000)
  local g = math.floor(val/0x100) - (r*0x100)
  local b = val - ((r*0x10000)+(g*0x100))
  return {r,g,b}
end

--------------------------------------------------------------------------------
-- convert value to hexadecimal string (e.g. 0xFFCC66)
-- @param val (int)
-- @param [prefix], string - e.g. "#" to return CSS-style color 
-- @return string

function cColor.value_to_hex_string(val,prefix)
  if not prefix then 
    prefix = "0x"
  end
  return ("%s%.6X"):format(prefix,val)
end

--------------------------------------------------------------------------------
-- convert hexadecimal string to value 
-- @param str_val (string), e.g. "5FEC99", "#5FEC99" or "0x5FEC99"
-- @return int or nil if unable to convert

function cColor.hex_string_to_value(str_val)

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

--------------------------------------------------------------------------------
-- Converts an RGB color value to HSV. Conversion formula
-- adapted from http://en.wikipedia.org/wiki/HSV_color_space.
-- @param rgb (table), the RGB representation
-- @return table, the HSV representation

function cColor.rgb_to_hsv(rgb)
  local r, g, b = rgb[1] / 255, rgb[2] / 255, rgb[3] / 255
  local max, min = math.max(r, g, b), math.min(r, g, b)
  local h, s, v
  v = max

  local d = max - min
  if max == 0 then s = 0 else s = d / max end

  if max == min then
    h = 0 -- achromatic
  else
    if max == r then
    h = (g - b) / d
    if g < b then h = h + 6 end
    elseif max == g then h = (b - r) / d + 2
    elseif max == b then h = (r - g) / d + 4
    end
    h = h / 6
  end

  return {h,s,v}
end

--------------------------------------------------------------------------------
-- Converts an HSV color value to RGB. Conversion formula
-- adapted from http://en.wikipedia.org/wiki/HSV_color_space.
-- @param hsv (table), the HSV representation
-- @return table, the RGB representation

function cColor.hsv_to_rgb(hsv)

  local h, s, v = hsv[1],hsv[2],hsv[3]
  local r, g, b

  local i = math.floor(h * 6);
  local f = h * 6 - i;
  local p = v * (1 - s);
  local q = v * (1 - f * s);
  local t = v * (1 - (1 - f) * s);

  i = i % 6

  if i == 0 then r, g, b = v, t, p
  elseif i == 1 then r, g, b = q, v, p
  elseif i == 2 then r, g, b = p, v, t
  elseif i == 3 then r, g, b = p, q, v
  elseif i == 4 then r, g, b = t, p, v
  elseif i == 5 then r, g, b = v, p, q
  end

  return {
    math.floor(r * 255), 
    math.floor(g * 255), 
    math.floor(b * 255)
  }

end
