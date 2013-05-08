--[[----------------------------------------------------------------------------
-- Duplex.UIComponent
----------------------------------------------------------------------------]]--

--[[

Inheritance: UIComponent 

About 

The UIComponent is the basic building block from which you model the user 
interface, and how it interacts with you. You will need to extend the 
UIComponent class, as it doesn't come with any type of pre-defined events.

The UIComponent pretty much leaves it up to you how to specify events. 
However, there's only a limited number of different events:

DEVICE_EVENT_VALUE_CHANGED 
DEVICE_EVENT_BUTTON_PRESSED
DEVICE_EVENT_BUTTON_RELEASED
DEVICE_EVENT_BUTTON_HELD

For examples on how to create/handle events with UIComponents, see either 
the UISlider or the UIButton class (both extensions of this class).

--]]


--==============================================================================

class 'UIComponent' 

--------------------------------------------------------------------------------

--- Initialize the UIComponent class
-- @param app (Duplex.Application)

function UIComponent:__init(app)
  TRACE("UIComponent:__init",app)
  
  self.canvas = Canvas()

  -- for indexed elements
  self.group_name = nil

  -- default palette
  self.palette = {}

  -- position within display
  self.x_pos = 1
  self.y_pos = 1

  -- "ceiling" will inform the device how to scale values
  -- for an example, check MidiDevice.point_to_value()
  self.ceiling = 1
  
  -- set width/height through the set_size() method
  self.width = 1 
  self.height = 1 

  -- text to display on the virtual UI
  self.tooltip = ""

  -- sync our width, height with the canvas
  self.canvas:set_size(self.width, self.height)

  -- request refresh
  self.dirty = true 
  
  -- reference to containing application
  self.app = app

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
-- (applications override this with their own implementation)

function UIComponent:add_listeners()

end


--------------------------------------------------------------------------------

--- Remove previously attached event listeners
-- (applications override this with their own implementation)

function UIComponent:remove_listeners()

end


--------------------------------------------------------------------------------

--- Method to set the control's size in units - it is important to use this 
-- instead of setting width/height directly, as this method will resize Canvas
-- @param width (Number)
-- @param height (Number)

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
-- @param x (Number)
-- @param y (Number)

function UIComponent:set_pos(x,y)
  TRACE("UIComponent:set_pos", x, y)
  
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
-- @param x_pos (Number)
-- @param y_pos (Number)
-- @return (Boolean) true if inside area

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
-- @param palette (Table), e.g {foreground={color={0x00,0x00,0x00}}}

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
-- @param other (UIComponent) another UIComponent instance
-- @return Boolean

function UIComponent:__eq(other)
  return rawequal(self, other)
end  


--------------------------------------------------------------------------------

--- Prints the type of UIComponent

function UIComponent:__tostring()
  return type(self)
end  

