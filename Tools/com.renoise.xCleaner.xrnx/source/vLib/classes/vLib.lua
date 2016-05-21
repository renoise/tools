--[[============================================================================
vLib
============================================================================]]--

class 'vLib'

--------------------------------------------------------------------------------
--- This class provides static members and methods for the vLib library

--- (int) when you instantiate a vLib component, it will register itself
-- with a unique viewbuilder ID. This is the global incrementer
vLib.uid_counter = 0

--- (bool) when true, complex widgets will schedule their updates, 
-- possibly saving a little CPU along the way
vLib.lazy_updates = false

-- (table) provide a default color for selected items
vLib.COLOR_SELECTED = {0xD0,0x40,0x40}

-- (table) provide a default color for normal (not selected) items
vLib.COLOR_NORMAL = {0x00,0x00,0x00}

--- specify a bitmap which is *guaranteed* to exist (required when 
-- creating bitmap views before assigning the final value)
vLib.DEFAULT_BMP = "Icons/ArrowRight.bmp"

vLib.BITMAP_STYLES = {
  "plain",        -- bitmap is drawn as is, no recoloring is done             
  "transparent",  -- same as plain, but black pixels will be fully transparent
  "button_color", -- recolor the bitmap, using the theme's button color       
  "body_color",   -- same as 'button_back' but with body text/back color      
  "main_color",   -- same as 'button_back' but with main text/back colors     
}

vLib.LARGE_BUTTON_H = 22
vLib.SUBMIT_BT_W = 82

--------------------------------------------------------------------------------
--- generate a unique string that you is used as viewbuilder id for widgets
-- (avoids clashes in names between multiple instances of the same widget)
-- @return string, e.g. "vlib12"

function vLib.generate_uid()
  
  vLib.uid_counter = vLib.uid_counter + 1
  return ("_vlib%i"):format(vLib.uid_counter)

end

--------------------------------------------------------------------------------
--- used for unpacking constructor arguments
-- @param ... (varargs)
-- @return table

function vLib.unpack_args(...)

  local args = {...}
  if not args[1] then
    return {}
  else
    return args[1]
  end
end

--------------------------------------------------------------------------------
--- function to ensure that a value is within the given range
-- @param val (number) 
-- @param val_min (number) 
-- @param val_max (number) 
-- @return bool

function vLib.within_range(val,val_min,val_max)

  if (val <= val_max) and (val >= val_min) then
    return true
  end
  return false

end

--------------------------------------------------------------------------------
--- function to scale a value from one range to another
-- @param value (number) 
-- @param in_min (number) 
-- @param in_max (number) 
-- @param out_min (number) 
-- @param out_max (number) 
-- @return number

function vLib.scale_value(value,in_min,in_max,out_min,out_max)
  return(((value-in_min)*(out_max/(in_max-in_min)-(out_min/(in_max-in_min))))+out_min)
end

--------------------------------------------------------------------------------
--- get fractional (decimal) part of a number
-- @param value (number) 
-- @return number

function vLib.get_fractional_value(value)
  return value-math.floor(value)
end

--------------------------------------------------------------------------------
-- round_value (from http://lua-users.org/wiki/SimpleRound)
-- @param num (number)
-- @return int
function vLib.round_value(num) 
  if num >= 0 then return math.floor(num+.5) 
  else return math.ceil(num-.5) end
end
