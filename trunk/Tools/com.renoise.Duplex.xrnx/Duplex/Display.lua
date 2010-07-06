--[[----------------------------------------------------------------------------
-- Duplex.Display
----------------------------------------------------------------------------]]--

--[[

The Display is the base class for building device displays

--]]


--==============================================================================

local UNIT_HEIGHT = 32
local UNIT_WIDTH = 32


--==============================================================================

class 'Display' 

function Display:__init(device)
  TRACE('Display:__init')

  assert(device, "Internal Error. Please report: " ..
    "expected a valid device for a display")
  
  self.device = device  

  --  viewbuilder stuff
  self.vb = nil
  self.view = nil    

  --  temp values (construction of control surface)
  self.parents = {}
  self.grid_obj = nil    
  self.grid_count = 0

  --self.scheduler = Scheduler()

  -- array of UIComponent instances
  self.ui_objects = table.create()

  -- each UI object notifier method is referenced by id, 
  -- so we can attach/detach the method when we need
  self.ui_notifiers = table.create()

  -- this is the default palette for any display,
  -- the UIComponents use these values as defaults
  self.palette = {
    background = {
      text="·",
      color={0x00,0x00,0x00}
    },
    color_1 = {
      text="■",
      color={0xff,0xff,0xff}
    },
    color_1_dimmed = {
      text="□",
      color={0x40,0x40,0x40}
    },
    color_2 = {
      text="▪",
      color={0x80,0x80,0x80}
    },
    color_2_dimmed = {
      text="▫",
      color={0x40,0x40,0x40}
    },
  }    
end


--------------------------------------------------------------------------------

function Display:add(obj_instance)
  TRACE('Display:add')
  
  self.ui_objects:insert(obj_instance)
end


--------------------------------------------------------------------------------

-- clear display. force an update of all UI components
-- TODO: also use hardware-specific feature if possible

function Display:clear()
  TRACE("Display:clear()")
  
  if (not self.view) then
    return
  end
  
  -- force updating all canvas for the next update
  for _,obj in ipairs(self.ui_objects) do
    if (obj.group_name) then
      obj.canvas.delta = table.rcopy(obj.canvas.buffer)
      obj.canvas.has_changed = true
      obj:invalidate()
    end
  end
end


--------------------------------------------------------------------------------

-- update: will update virtual/hardware displays

function Display:update()

  if (not self.view) then
    return
  end

  local control_map = self.device.control_map
  
  for _,obj in pairs(self.ui_objects) do

    -- skip unused objects, object that doesn't need update
    if (obj.group_name and obj.dirty) then

      obj:draw()

      -- loop through the delta array - it contains all recent updates
      if (obj.canvas.has_changed) then
        for x = 1,obj.width do
          for y = 1, obj.height do

            if (obj.canvas.delta[x][y]) then
              if not (control_map.groups[obj.group_name]) then
                print(("Warning: '%s' is not specified in control-map "..
                  "group '%s'"):format(type(obj), tostring(obj.group_name)))

              else
                local columns = control_map.groups[obj.group_name].columns
                local idx = (x+obj.x_pos-1)+((y+obj.y_pos-2)*columns)

                local elm = control_map:get_indexed_element(idx, obj.group_name)
                
                if (elm) then
                  self:set_parameter(elm, obj, obj.canvas.delta[x][y])
                end
              end
            end
          end
        end
        
        -- reset has_changed flag
        obj.canvas:clear_delta()
      end
    end
  end
end


--------------------------------------------------------------------------------

-- set_parameter: update object states
-- @elm : control-map definition of the element
-- @obj : reference to the UIComponent instance
-- @point : canvas point containing text/value/color 

function Display:set_parameter(elm, obj, point)
  TRACE('Display:set_parameter',elm.name,elm.value,point.text)

  local widget = nil
  local value = nil
  local num = nil

  -- update hardware display

  if (self.device) then 
    local msg_type = self.device.control_map:determine_type(elm.value)
    
    local current_message = self.device.message_stream.current_message
    
    if (msg_type == MIDI_NOTE_MESSAGE) then
      num = self.device:extract_midi_note(elm.value)

      value = self.device:point_to_value(
        point, elm.maximum, elm.minimum, obj.ceiling)

      -- do not loop back the original value change back to the sender, 
      -- unless the device explicitly wants this
      if (not current_message) or
         (current_message.context ~= MIDI_NOTE_MESSAGE) or
         (current_message.id ~= elm.id) or
         (current_message.value ~= value) or
         (self.device.loopback_received_messages)
      then
        self.device:send_note_message(num,value)
      end
    
    elseif (msg_type == MIDI_CC_MESSAGE) then
      num = self.device:extract_midi_cc(elm.value)
      
      value = self.device:point_to_value(
        point, elm.maximum, elm.minimum, obj.ceiling)

      -- do not loop back the original value change back to the sender, 
      -- unless the device explicitly wants this
      if (not current_message) or
         (current_message.context ~= MIDI_CC_MESSAGE) or
         (current_message.id ~= elm.id) or
         (current_message.value ~= value) or
         (self.device.loopback_received_messages)
      then
        self.device:send_cc_message(num,value)
      end
    
    elseif (msg_type == MIDI_PITCH_BEND_MESSAGE) then

--[[ TODO      
      value = self.device:point_to_value(
        point, elm.maximum, elm.minimum, obj.ceiling)

      -- do not loop back the original value change back to the sender, 
      -- unless the device explicitly wants this
      if (not current_message) or
         (current_message.context ~= MIDI_PITCH_BEND_MESSAGE) or
         (current_message.id ~= elm.id) or
         (current_message.value ~= value) or
         (self.device.loopback_received_messages)
      then
        self.device:send_pb_message(num,value)
      end
]]    
    else
      error(("Internal Error. Please report: " ..
        "unknown or unhandled msg_type: '%s'"):format(msg_type or "nil"))
    end
  end


  -- update virtual control surface

  if (self.vb and self.vb.views) then 
    widget = self.vb.views[elm.id]
  end

  if (widget) then
    if (type(widget) == "Button") then
      -- either use text or colors for a button
      local colorspace = self.device.colorspace
      if (colorspace[1] or colorspace[2] or colorspace[3]) then
        widget.color = self:__quantize_widget_color(point.color)
        widget.text = ""
      else
        widget.color = { 0, 0, 0 }
        widget.text = point.text
      end
    
    elseif (type(widget) == "RotaryEncoder") or 
      (type(widget) == "MiniSlider") or
      (type(widget) == "Slider")
    then
      value = self.device:point_to_value(
        point, elm.maximum, elm.minimum, obj.ceiling)

      widget:remove_notifier(self.ui_notifiers[elm.id])
      widget.value = tonumber(value)
      widget:add_notifier(self.ui_notifiers[elm.id])
    
    else
      error(("Internal Error. Please report: " .. 
        "unexpected or unknown widget type '%s'"):format(type(widget)))
    end
  end 
end


--------------------------------------------------------------------------------

-- build the virtual control-surface based on the parsed control-map

function Display:build_control_surface()
  TRACE('Display:build_control_surface')

  self.vb = renoise.ViewBuilder()

  self.view = self.vb:column {
    id = "display_rootnode",
    margin = DEFAULT_MARGIN,
    --spacing = 16,
  }
  
  -- loading may have failed. check if definition is valid...
  if (self.device.control_map.definition) then
    self:walk_table(self.device.control_map.definition)
  end
  
  return self.view
end


--------------------------------------------------------------------------------

--  generate message : used by virtual control-surface elements
--  @value : the value
--  @metadata : metadata table (min/max etc.)

function Display:generate_message(value, metadata)
  TRACE('Display:generate_message:'..value)

  local msg = Message()
  msg.value = value

  -- the type of message (MIDI/OSC...)
  msg.context = self.device.control_map:determine_type(metadata.value)

  -- input method : make sure we're using the right handler 
  if (metadata.type == "button") then
    msg.input_method = CONTROLLER_BUTTON

--  elseif (metadata.type == "encoder") then
--    msg.input_method = CONTROLLER_ENCODER

  elseif (metadata.type == "fader") then
    msg.input_method = CONTROLLER_FADER

  elseif (metadata.type == "dial") then
    msg.input_method = CONTROLLER_DIAL

  else
    error(("Internal Error. Please report: " .. 
      "unknown metadata.type '%s'"):format(metadata.type or "nil"))
  end

  -- include additional useful meta-properties
  msg.name = metadata.name
  msg.group_name = metadata.group_name
  msg.max = tonumber(metadata.maximum)
  msg.min = tonumber(metadata.minimum)
  msg.id = metadata.id
  msg.index = metadata.index
  msg.column = metadata.column
  msg.row = metadata.row
  msg.timestamp = os.clock()

  -- mark as virtual generated message
  msg.is_virtual = true

  -- send the message
  self.device.message_stream:input_message(msg)
end


--------------------------------------------------------------------------------

--  walk_table: create the virtual control surface
--  iterate through the control-map, while adding/collecting 
--  relevant meta-information 

function Display:walk_table(t, done, deep)

  deep = deep and deep + 1 or 1  --  the nesting level
  done = done or {}

  for key, value in pairs(t) do
    if (type(value) == "table" and not done[value]) then
      done [value] = true
        
      local grid_id = nil
      local view_obj = {
        meta = t[key].xarg  -- xml attributes
      }
  
      --- Param
  
      if (t[key].label == "Param") then
  
          -- empty parameter (placeholder unit)?
        if not (view_obj.meta.type) then
          view_obj.view = self.vb:column{
            height = UNIT_HEIGHT,
            width = UNIT_WIDTH,
          }

          -- a parameter unit
        else
  
          local tooltip = string.format("%s (%s)",
            view_obj.meta.name,view_obj.meta.value)
  
  
          --- Param:button
          
          if (t[key].xarg.type == "button") then
            local notifier = function(value) 
              -- output the maximum value
              self:generate_message(view_obj.meta.maximum*1,view_obj.meta)
            end
              
            self.ui_notifiers[t[key].xarg.id] = notifier
            view_obj.view = self.vb:button{
              id = t[key].xarg.id,
              height = UNIT_HEIGHT,
              width = UNIT_WIDTH,
              tooltip = tooltip,
              notifier = notifier
            }
          
          
          --- Param:encoder
              
          elseif (t[key].xarg.type == "encoder") then
            local notifier = function(value) 
              -- output the current value
              self:generate_message(value,view_obj.meta)
            end
              
              self.ui_notifiers[t[key].xarg.id] = notifier
              view_obj.view = self.vb:minislider{
                id=t[key].xarg.id,
                min = tonumber(view_obj.meta.minimum),
                max = tonumber(view_obj.meta.maximum),
                tooltip = tooltip,
                height = UNIT_HEIGHT/1.5,
                width = UNIT_WIDTH,
                notifier = notifier
              }
              
            
          --- Param:dial
          
          elseif (t[key].xarg.type == "dial") then
            local notifier = function(value) 
              -- output the current value
              self:generate_message(value,view_obj.meta)
            end
            
            self.ui_notifiers[t[key].xarg.id] = notifier
            view_obj.view = self.vb:rotary{
              id = t[key].xarg.id,
              min = tonumber(view_obj.meta.minimum),
              max = tonumber(view_obj.meta.maximum),
              tooltip = tooltip,
              width = UNIT_WIDTH,
              height = UNIT_WIDTH,
              notifier = notifier
            }
            
            
          --- Param:fader
                    
          elseif (t[key].xarg.type == "fader") then
            local notifier = function(value) 
              -- output the current value
              self:generate_message(value,view_obj.meta)
            end
              
            self.ui_notifiers[t[key].xarg.id] = notifier
  
            if (t[key].xarg.orientation == "vertical") then
              view_obj.view = self.vb:row {
                -- padd with spaces to center DEFAULT_CONTROL_HEIGHT in UNIT_WIDTH
                self.vb:space { 
                  width = (UNIT_WIDTH -  DEFAULT_CONTROL_HEIGHT) / 2 
                },
                self.vb:slider{
                  id = t[key].xarg.id,
                  min = tonumber(view_obj.meta.minimum),
                  max = tonumber(view_obj.meta.maximum),
                  tooltip = tooltip,
                  width = DEFAULT_CONTROL_HEIGHT,
                  height = (UNIT_WIDTH * t[key].xarg.size) + 
                    (DEFAULT_SPACING * (t[key].xarg.size - 1)),
                  notifier = notifier
                },
                self.vb:space {
                  width = (UNIT_WIDTH -  DEFAULT_CONTROL_HEIGHT) / 2 
                }
              }
            else

              assert(t[key].xarg.orientation == "horizontal",
                "Internal Error. Please report: unexpected UI orientation")
              
              view_obj.view = self.vb:slider {
                id  =t[key].xarg.id,
                min = tonumber(view_obj.meta.minimum),
                max = tonumber(view_obj.meta.maximum),
                tooltip = tooltip,
                width = (UNIT_WIDTH*t[key].xarg.size) + 
                  (DEFAULT_SPACING*(t[key].xarg.size-1)),
                notifier = notifier
              }
            end
          end
        end
        
  
      --- Column
  
      elseif (t[key].label == "Column") then
        view_obj.view = self.vb:column{
          spacing = DEFAULT_SPACING
        }
        self.parents[deep] = view_obj
        
  
  
      --- Row
  
      elseif (t[key].label == "Row") then
        view_obj.view = self.vb:row{
          spacing = DEFAULT_SPACING,
        }
        self.parents[deep] = view_obj
        
  
      --- Group
  
      elseif (t[key].label == "Group") then
        -- the group
        local orientation = t[key].xarg.orientation
        local columns = t[key].xarg.columns
          
        if (columns) then
          -- enter "grid mode": use current group as 
          -- base object for inserting multiple rows
          self.grid_count = self.grid_count+1
          grid_id = string.format("grid_%i",self.grid_count)
          orientation = "vertical"
        else
          -- exit "grid mode"
          self.grid_obj = nil
        end
          
        if (orientation == "vertical") then
          view_obj.view = self.vb:column{
            style = "group",
            id = grid_id,
            margin = DEFAULT_MARGIN,
            spacing = DEFAULT_SPACING,
          }
        else
          assert(orientation == "horizontal",
             "Internal Error. Please report: unexpected UI orientation")
             
          view_obj.view = self.vb:row{
            style = "group",
            id = grid_id,
            width = 400,
            margin = DEFAULT_MARGIN,
            spacing = DEFAULT_SPACING,
          }
        end
    
        -- more grid mode stuff: remember the original view_obj
        -- grid mode will otherwise loose this reference...
        if (grid_id) then
          self.grid_obj = view_obj
        end
          
        self.parents[deep] = view_obj
      end
        
      -- something was matched
      if (view_obj.view) then
        -- grid mode: create a(nother) row ?
        local row_id = nil
    
        if (view_obj.meta.row) then
          row_id = string.format("grid_%i_row_%i",
            self.grid_count,view_obj.meta.row)
        end
    
          if (not grid_id and self.grid_obj and 
              not self.vb.views[row_id]) then
    
          local row_obj = {
            view = self.vb:row{
              id=row_id,
              spacing=DEFAULT_SPACING,
            }
          }
          -- assign grid objects to this row
          self.grid_obj.view:add_child(row_obj.view)
          self.parents[deep-1] = row_obj
        end
          
        -- attach to parent object (if it exists)
        local added = false
    
        for i = deep-1, 1, -1 do
          if self.parents[i] then
            self.parents[i].view:add_child(view_obj.view)
            added = true
            break
          end
        end
          
        -- else, add to main view
        if (not added) then
          self.view:add_child(view_obj.view)
        end
      end
      self:walk_table(value,done,deep)
    end
  end
end


--------------------------------------------------------------------------------

function Display:__tostring()
  return type(self)
end


--------------------------------------------------------------------------------

function Display:__quantize_widget_color(color)

  local function quantize_color(value, depth)
    if (depth and depth > 0) then
      assert(depth <= 256, "invalid device colorspace value")
      local a = 256/(depth+1)
      local b = a*(math.floor(value/a))
      return math.min(math.floor(b*256/(256-b)),255)
    else
      return 0
    end
  end

  -- check if monochrome, then apply the average value
  local cs = self.device.colorspace
  local range = math.max(cs[1],cs[2],cs[3])
  if(range<2)then
    local avg = (color[1]+color[2]+color[3])/3
    color = {avg,avg,avg}
  end

  return {
    quantize_color(color[1], self.device.colorspace[1]),
    quantize_color(color[2], self.device.colorspace[2]),
    quantize_color(color[3], self.device.colorspace[3])
  } 
end

