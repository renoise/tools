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

  self.device = device  

  --  viewbuilder stuff
  self.vb = renoise.ViewBuilder()
  self.view = nil    

  --  temp values used during construction of control surface
  self.parents = {}
  self.grid_obj = nil    
  self.grid_count = 0
  --self.grid_columns = nil

  -- array of DisplayObject instances
  self.ui_objects = {}  

  -- each UI object notifier method is referenced by id, 
  -- so we can attach/detach the method when we need
  self.ui_notifiers = {}  

  -- "palette" is a table of named color-constants 
  self.palette = {
    background = {
      text="·",
      color={0x00,0x00,0x00}
    },
    color_1 = {
      text="■",
      color={0xff,0xff,0x00}
    },
    color_1_dimmed = {
      text="□",
      color={0x40,0x40,0x00}
    },
    color_2 = {
      text="▪",
      color={0x80,0x80,0x00}
    },
    color_2_dimmed = {
      text="▫",
      color={0x40,0x40,0x00}
    },
  }    
end


--------------------------------------------------------------------------------

function Display:add(obj_instance)
  TRACE('Display:add')
  table.insert(self.ui_objects,#self.ui_objects+1,obj_instance)
end


--------------------------------------------------------------------------------

-- TODO: clear display
-- use hardware-specific feature if possible

function Display:clear()
  TRACE("Display:clear()")
  
  for _,group in pairs(self.device.control_map.groups)do
    for __,param in ipairs(group) do
-- @elm : control-map definition of the element
-- @obj : reference to the DisplayObject instance
-- @point : canvas point containing text/value/color 
--[[
      local pt = Point()
      local obj = {ceiling=100}
      self.set_parameter(param,obj,pt)
--rprint(param)      
]]
    end
  end
end


--------------------------------------------------------------------------------

-- update: will update virtual/hardware displays

function Display:update()

  if (not self.view) then
    return
  end

  for i,obj in ipairs(self.ui_objects) do
    if obj.dirty then

      -- update the object display
      obj.draw(obj)

      -- loop through the delta array - it contains all recent updates
      if obj.canvas.has_changed then
        for x = 1,obj.width do
          for y = 1, obj.height do
            if obj.canvas.delta[x][y] then
              if not self.device.control_map.groups[obj.group_name] then
                print("Warning: ",type(obj)," not specified in control-map group ",obj.group_name)
              else
  --[[
  print(type(obj),obj.group_name)
  rprint(self.device.control_map.groups,obj.group_name)
  print(self.device.control_map.groups[obj.group_name])
  print(self.device.control_map.groups[obj.group_name].columns)
  ]]
                local columns = self.device.control_map.groups[obj.group_name].columns
                local idx = (x+obj.x_pos-1)+((y+obj.y_pos-2)*columns)
                local elm = self.device.control_map:get_indexed_element(idx,obj.group_name)
                if elm then
                  self:set_parameter(elm,obj,obj.canvas.delta[x][y])
                end
              end
            end
          end
        end
        obj.canvas.clear_delta(obj.canvas)
      end

    end
  end

end


--------------------------------------------------------------------------------

-- set_parameter: update object states
-- @elm : control-map definition of the element
-- @obj : reference to the DisplayObject instance
-- @point : canvas point containing text/value/color 

function Display:set_parameter(elm,obj,point)
  TRACE('Display:set_parameter',elm.name,elm.value,point.text)
  --objinfo(point)

  local widget = nil
  local value = nil
  local num = nil

  -- update hardware display

  if self.device then 
    local msg_type = self.device.control_map:determine_type(elm.value)
    if msg_type == MIDI_NOTE_MESSAGE then
      num = self.device:extract_midi_note(elm.value)
      value = self.device:point_to_value(point,elm.maximum,elm.minimum,obj.ceiling)
      self.device:send_note_message(num,value)
    elseif msg_type == MIDI_CC_MESSAGE then
      num = self.device:extract_midi_cc(elm.value)
      value = self.device:point_to_value(point,elm.maximum,elm.minimum,obj.ceiling)
      self.device:send_cc_message(num,value)
    end
  end

  -- update virtual control surface

  if self.vb and self.vb.views then 
    widget = self.vb.views[elm.id]
  end
  if widget then
    if type(widget)=="Button" then
      widget.text = point.text
    end
    if (type(widget)=="MiniSlider") or (type(widget)=="Slider") then
      value = self.device:point_to_value(point,elm.maximum,elm.minimum,obj.ceiling)
      widget.remove_notifier(widget,self.ui_notifiers[elm.id])
      widget.value = value*1 -- toNumber
      widget.add_notifier(widget,self.ui_notifiers[elm.id])
    end
  end
end


--------------------------------------------------------------------------------

function Display:show_control_surface()
  TRACE('Display:show_control_surface')

  if (not self.view) then
    self:build_control_surface()
  end
  self.vb.views.display_rootnode.visible = true

end


--------------------------------------------------------------------------------

function Display:hide_control_surface()
  self.vb.views.display_rootnode.visible = false
end


--------------------------------------------------------------------------------

--  build the virtual control-surface
--  based on the parsed control-map

function Display:build_control_surface()
  TRACE('Display:build_control_surface')

  self.view = self.vb:column{
    id="display_rootnode",
    style="invisible",
    width = 500,
    height = 500,
    margin = DEFAULT_MARGIN,
    --spacing = 16,
  }
  if self.device.control_map.definition then
    self:walk_table(self.device.control_map.definition)
  end

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
  if metadata.type == "button" then
    msg.input_method = CONTROLLER_BUTTON
  elseif metadata.type == "encoder" then
    msg.input_method = CONTROLLER_ENCODER
  elseif metadata.type == "fader" then
    msg.input_method = CONTROLLER_FADER
  end

  -- include additional useful meta-properties
  msg.name  = metadata.name
  msg.group_name = metadata.group_name
  msg.max    = metadata.maximum+0
  msg.min    = metadata.minimum+0
  msg.id    = metadata.id
  msg.index  = metadata.index
  msg.column  = metadata.column
  msg.row    = metadata.row
  msg.timestamp = os.clock()

  self.device.message_stream:input_message(msg)
end


--------------------------------------------------------------------------------

--  walk_table: create the virtual control surface
--  iterate through the control-map, while adding/collecting 
--  relevant meta-information 

function Display:walk_table(t, done, deep)

  deep = deep or 0  --  the nesting level
  deep = deep +1
  done = done or {}

  for key, value in pairs (t) do
    if type (value) == "table" and not done [value] then
    done [value] = true
    local grid_id = nil
    local view_obj = {
      meta = t[key].xarg  -- xml attributes
    }
    if t[key].label=="Param" then
      -- the parameters
      local notifier = nil

      TRACE("Display:view_obj.meta:",view_obj.meta)
      TRACE("Display:view_obj.meta.name:",view_obj.meta.name)
  
      if not view_obj.meta.type then

        -- an empty parameter (placeholder unit)

          view_obj.view = self.vb:column{
            height=UNIT_HEIGHT,
            width=UNIT_WIDTH,
            style = "invisible"
          }


      else

        -- a parameter unit

        local tooltip = string.format("%s (%s)",view_obj.meta.name,view_obj.meta.value)
        if t[key].xarg.type == "button" then
          notifier = function(value) 
            -- output the maximum value
            self:generate_message(view_obj.meta.maximum*1,view_obj.meta)
          end
          self.ui_notifiers[t[key].xarg.id] = notifier
          view_obj.view = self.vb:button{
            id=t[key].xarg.id,
            height=UNIT_HEIGHT,
            width=UNIT_WIDTH,
            tooltip = tooltip,
            notifier = notifier
          }
        elseif t[key].xarg.type == "encoder" then
          notifier = function(value) 
            -- output the current value
            self:generate_message(value,view_obj.meta)
          end
          self.ui_notifiers[t[key].xarg.id] = notifier
          view_obj.view = self.vb:minislider{
            id=t[key].xarg.id,
            min = view_obj.meta.minimum+0,
            max = view_obj.meta.maximum+0,
            tooltip = tooltip,
            height=UNIT_HEIGHT/1.5,
            width = UNIT_WIDTH,
            notifier = notifier
          }
        elseif t[key].xarg.type == "fader" then
          notifier = function(value) 
            -- output the current value
            self:generate_message(value,view_obj.meta)
          end
          self.ui_notifiers[t[key].xarg.id] = notifier
          view_obj.view = self.vb:slider{
            id=t[key].xarg.id,
            min = view_obj.meta.minimum+0,
            max = view_obj.meta.maximum+0,
            tooltip = tooltip,
            --height=UNIT_HEIGHT/1.5,
            width = (UNIT_WIDTH*t[key].xarg.size)+(DEFAULT_SPACING*(t[key].xarg.size-1)),
            notifier = notifier
          }
        end
      end
    elseif t[key].label=="Column" then
      view_obj.view = self.vb:column{
        style="invisible",
        spacing=DEFAULT_SPACING
      }
      self.parents[deep] = view_obj
    elseif t[key].label=="Row" then
      view_obj.view = self.vb:row{
        style="invisible",
        spacing=DEFAULT_SPACING,
      }
      self.parents[deep] = view_obj
    elseif t[key].label=="Group" then
      -- the group
      local orientation = t[key].xarg.orientation
      local columns = t[key].xarg.columns
      if columns then
        -- enter "grid mode": use current group as 
        -- base object for inserting multiple rows
        self.grid_count = self.grid_count+1
        grid_id = string.format("grid_%i",self.grid_count)
        orientation = "vertical"
      else
        -- exit "grid mode"
        self.grid_obj = nil
      end
      if orientation=="vertical" then
        view_obj.view = self.vb:column{
          style="group",
          id=grid_id,
          margin=DEFAULT_MARGIN,
          spacing=DEFAULT_SPACING,
        }
      else
      --[[
        view_obj.view = self.vb:horizontal_aligner{
          mode = "center",
          self.vb:row{
            style="group",
            id=grid_id,
            margin=DEFAULT_MARGIN,
            spacing=DEFAULT_SPACING,
          }
        }
      ]]
        view_obj.view = self.vb:row{
          style="group",
          id=grid_id,
          width=500,
          margin=DEFAULT_MARGIN,
          spacing=DEFAULT_SPACING,
        }
      end
      -- more grid mode stuff: remember the original view_obj
      -- grid mode will otherwise loose this reference...
      if grid_id then
        self.grid_obj = view_obj
      end
      self.parents[deep] = view_obj
    end
    -- something was matched
    if view_obj.view then
      -- grid mode: create a(nother) row ?
      local row_id = nil
      if view_obj.meta.row then
        row_id = string.format("grid_%i_row_%i",self.grid_count,view_obj.meta.row)
      end
      if not grid_id and self.grid_obj and not self.vb.views[row_id] then
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
      for i = deep-1,1,-1 do
        if self.parents[i] then
          self.parents[i].view:add_child(view_obj.view)
          added = true
          break
        end
      end
      -- else, add to main view
      if not added then
        self.view:add_child(view_obj.view)
      end
    end
    self:walk_table (value, done, deep)
  end
  end
end

