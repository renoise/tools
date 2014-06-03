--[[============================================================================
-- Duplex.UIComponent
============================================================================]]--

--[[--

The UIComponent is the basic building block from which you can create a Duplex application user interface 

All classes that extend this class are prefixed with 'UI': UIButton, UISlider etc. 

The UIComponent pretty much leaves it up to you how to specify events. 
For examples on how to create/handle events with UIComponents, see either 
the UISlider or the UIButton class (both extensions of this class).

--]]

--==============================================================================

class 'UIComponent' 

--------------------------------------------------------------------------------

--- Initialize the UIComponent class
-- @param app (@{Duplex.Application})

function UIComponent:__init(app)
  TRACE("UIComponent:__init",app)
  
  --- (@{Duplex.Canvas})
  self.canvas = Canvas()

  --- (string) control-map group name
  self.group_name = nil

  --- (table) default palette
  self.palette = {}

  --- (int) ORIENTATION.HORIZONTAL position within display
  self.x_pos = 1

  -- (int) ORIENTATION.VERTICAL position within display
  self.y_pos = 1

  --- (number) the maximum value for this component
  self.ceiling = 1
  
  --- (int) internal width (always use @{set_size})
  self.width = 1 

  --- (int) internal height (always use @{set_size})
  self.height = 1 

  --- (string) text to display on the virtual UI
  self.tooltip = ""

  --- (string) link to a renoise midi-mapping
  self.midi_mapping = nil

  --- (bool) request refresh on next update
  self.dirty = true 
  
  --- (@{Duplex.Application}) containing application
  self.app = app

  -- do some preparation
  -- sync our width, height with the canvas
  self.canvas:set_size(self.width, self.height)

end


--------------------------------------------------------------------------------

---  Request update on next refresh

function UIComponent:invalidate()
  --TRACE("UIComponent:invalidate")

  self.dirty = true
end


--------------------------------------------------------------------------------

--- Update the control's visual appearance 

function UIComponent:draw()
  --TRACE("UIComponent:draw")

  self.dirty = false
  
  -- override to specify a draw implementation
end


--------------------------------------------------------------------------------

--- Attach listeners to the events 
-- (override this with your own implementation)

function UIComponent:add_listeners()

end


--------------------------------------------------------------------------------

--- Remove previously attached event listeners
-- (override this with your own implementation)

function UIComponent:remove_listeners()

end


--------------------------------------------------------------------------------

--- Method to set the control's size in units - it is important to use this 
-- instead of setting width/height directly, as this method will resize Canvas
-- @param width (int)
-- @param height (int)

function UIComponent:set_size(width, height)
  TRACE("UIComponent:set_size", width, height)

  self.canvas:set_size(width, height)

  if (width ~= self.width) or
    (height ~= self.height) then
    self:invalidate()
  end

  self.width = width      
  self.height = height
end


--------------------------------------------------------------------------------

--- Set the position using x/y or index within group
-- @param x (int)
-- @param y (int)

function UIComponent:set_pos(x,y)
  TRACE("UIComponent:set_pos",x,y)
  
  local idx = nil
  if x and (not y) then
    idx = x
  end

  if (idx) then
    -- obtain the size of the group
    local cm = self.app.display.device.control_map
    local cols = cm:count_columns(self.group_name)
    -- calculate x/y from index
    if (idx>0) then
      y = math.ceil(idx/cols)
      x = idx-(cols*(y-1))
    end
  end
  if(x~=self.x_pos) and (y~=self.y_pos) then
    self:invalidate()
  end
  self.x_pos = x
  self.y_pos = y
end


--------------------------------------------------------------------------------

--- Perform simple "inside square" hit test
-- @param x_pos (int)
-- @param y_pos (int)
-- @return (bool), true if inside area

function UIComponent:test(x_pos, y_pos)
  TRACE("UIComponent:test(",x_pos, y_pos,")")

  -- pressed to the left or above?
  if (x_pos < self.x_pos) or 
     (y_pos < self.y_pos) 
  then
    return false
  end
  
  -- pressed to the right or below?
  if (x_pos >= self.x_pos + self.width) or 
     (y_pos >= self.y_pos + self.height) 
  then
    return false
  end
  
  return true
end


--------------------------------------------------------------------------------

--- Set palette, invalidate if changed
-- @param palette (table), e.g {foreground={color={0x00,0x00,0x00}}}

function UIComponent:set_palette(palette)
  TRACE("UIComponent:set_palette()",palette)

  local changed = false

  for i,_ in pairs(palette)do
    for k,v in pairs(palette[i])do
      if self.palette[i] and (type(self.palette[i][k])~="nil") then
        if(type(v)=="table")then -- color
          if(not table_compare(self.palette[i][k],v))then
            self.palette[i][k] = table.rcopy(v)
            changed = true
          end
        elseif((type(v)=="string") or (type(v)=="boolean")) then 
          if(self.palette[i][k] ~= v)then
            self.palette[i][k] = v
            changed = true
          end
        end
      end
    end
  end
  if (changed) then
    self:invalidate()
  end
end


--------------------------------------------------------------------------------

--- Compare with another instance (only check for object identity)
-- @param other (@{Duplex.UIComponent}) 
-- @return bool

function UIComponent:__eq(other)
  return rawequal(self, other)
end  


--------------------------------------------------------------------------------

--- Output the type of UIComponent
-- @return string

function UIComponent:__tostring()
  return type(self)
end  

