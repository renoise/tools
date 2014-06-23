--[[============================================================================
-- Duplex.UIComponent
============================================================================]]--

--[[--

UIComponent is the basic building block from which you create a user interface.

All classes that extend this class are prefixed with 'UI': UIButton, UISlider etc. 

This class, and all the classes extending it, are not to be confused with the Renoise viewbuilder API, which creates _actual_ on-screen controls. The virtual control surface (the on-screen representation of your hardware) is a static representation of the device interface, as defined by the control-map. 

UIComponents, on the other hand, are a little more abstract. They can basically be created, moved around and resized while the application is running. 
Imagine creating an instance of a "UISlider" which you then assign a size of 8 vertical units, and assign to the middle of a Launchpad grid? For all that matters, you will think of this as being a slider, and operate it as such. But in reality, the slider is made from 8 different buttons that "know" about each other. 

For examples on how to create/handle events with UIComponents, see either 
the UISlider or the UIButton class (both extensions of this class).

--]]

--==============================================================================

class 'UIComponent' 

--------------------------------------------------------------------------------

--- Initialize the UIComponent class
-- @param app (@{Duplex.Application})
-- @param map[opt] (table) mapping properties 

function UIComponent:__init(app,map)
  TRACE("UIComponent:__init",app,map)
  
  --- (@{Duplex.Canvas})
  self.canvas = Canvas()

  --- (string) control-map group name
  self.group_name = nil

  --- (table) default palette
  self.palette = {}

  --- (int) position within display
  self.x_pos = 1

  -- (int) position within display
  self.y_pos = 1

  --- (number) the minimum value for this component
  -- when a value is output to the device, this is used for scaling
  -- from our "local" value to the "external" one (only applies 
  -- to components that output a numeric value)
  self.floor = 0

  --- (number) the maximum value for this component
  -- when a value is output to the device, this is used for scaling
  -- from our "local" value to the "external" one (only applies 
  -- to components that output a numeric value)
  self.ceiling = 1
  
  --- (int) internal width (always use @{set_size})
  self.width = 1 

  --- (int) internal height (always use @{set_size})
  self.height = 1 

  --- (string) tooltip, displayed in the virtual UI
  self.tooltip = ""

  --- (string) link to a renoise midi-mapping - don't forget to register a 
  -- similarly named mapping with renoise.tool():add_midi_mapping
  self.midi_mapping = nil

  --- (bool) request refresh on next update
  self.dirty = true 
  
  --- (bool) when the message specifies this, hardware output is skipped
  -- when the message was triggered from the hardware itself
  self.soft_echo = false
  
  --- (@{Duplex.Application}) containing application
  self.app = app

  --- (bool) false if UIComponent state was changed - see (@{disable} or (@{enable}
  self._active = true 

  -- do some preparation --

  -- sync our width, height with the canvas
  self.canvas:set_size(self.width, self.height)

  -- if map was specified, initialize with these properties
  if map and map.group_name then
    self.group_name = map.group_name
    self.tooltip = map.description or ""
    self:set_pos(map.index or 1)
  end

  -- register with the app
  app:_add_component(self)


end


--------------------------------------------------------------------------------

---  Request update on next refresh

function UIComponent:invalidate()
  --TRACE("UIComponent:invalidate")

  self.dirty = true
end


--------------------------------------------------------------------------------

--- Update the control's visual appearance. We are not communicating directly
-- with the device through this method, but rather perform modifications to
-- the Canvas (which is translated into something the device can understand)

function UIComponent:draw()
  --TRACE("UIComponent:draw")

  self.dirty = false
  
  -- override to specify a draw implementation
end


--------------------------------------------------------------------------------

--- Make all associated viewbuilder widgets inactive 

function UIComponent:disable()
  TRACE("UIComponent:disable()")

  local widgets = self:_get_widgets()
  for k,v in ipairs(widgets) do
    v.active = false
  end

end

--------------------------------------------------------------------------------

--- Make all associated viewbuilder widgets active 

function UIComponent:enable()
  TRACE("UIComponent:enable()")

  local widgets = self:_get_widgets()
  for k,v in ipairs(widgets) do
    v.active = true
  end

end

--------------------------------------------------------------------------------

--- Attach listeners to the events 
-- (override this with your own implementation)

function UIComponent:add_listeners()

  -- don't forget to call this first...
  -- self:remove_listeners()

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
-- @param y (int) optional, leave out to specify index via `x` parameter

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
  if(x~=self.x_pos) or (y~=self.y_pos) then
    self:invalidate()
  end
  self.x_pos = x
  self.y_pos = y
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
          --print("comparing",rprint(self.palette[i][k]))
          --print("with",rprint(v))
          if (not table_compare(self.palette[i][k],v)) then
            --self.palette[i][k] = table.rcopy(v)
            self.palette[i][k] = v
            changed = true
            --print("*** set_palette - component has changed (color)",i,k)
          end
        elseif((type(v)=="string") or (type(v)=="boolean")) then 
          if(self.palette[i][k] ~= v)then
            self.palette[i][k] = v
            changed = true
            --print("*** set_palette - component has changed (text)")
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

--- Set the group that this component belongs to
-- @param group_name (string)

function UIComponent:set_group(group_name)

  if (group_name == self.group_name) then
    return
  end

  self.group_name = group_name

  --self:set_pos(self.x_pos,self.y_pos)
  --self:set_size(

end

--------------------------------------------------------------------------------

--- Perform simple "inside square" hit test
-- @param x_pos (int)
-- @param y_pos (int)
-- @return (bool), true if inside area

function UIComponent:test(x_pos, y_pos)
  --TRACE("UIComponent:test(",x_pos, y_pos,")")

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

--- Retrieve the viewbuilder widgets that we are associated with 
-- @return (table) renoise.Views.Control,...

function UIComponent:_get_widgets()
  TRACE("UIComponent:_get_widgets()")

  local widgets = {}
  local params = self:_get_ui_params()
  for k,param in ipairs(params) do
    widgets[#widgets+1] = self.app.display.vb.views[param.xarg.id]
  end

  return widgets

end

--------------------------------------------------------------------------------

--- Retrieve the control-map <Param> nodes that we are associated with 
-- @return (table) 

function UIComponent:_get_ui_params()
  TRACE("UIComponent:_get_ui_params()")

  local params = {}
  local cm = self.app.display.device.control_map

  for x = self.x_pos,self.x_pos + (self.width-1) do
    for y = self.y_pos,self.y_pos + (self.height-1) do
      local param = cm:get_param_by_pos(x,y,self.group_name)
      if param then
        params[#params+1] = param
      else
        local msg = "*** %s: failed to get parameter - pos %d,%d within group %s (%s)"
        LOG(string.format(msg,type(self),x,y,self.group_name or "",self.tooltip))
      end
    end
  end

  return params

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

