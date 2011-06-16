--[[----------------------------------------------------------------------------
-- Duplex.Display
----------------------------------------------------------------------------]]--

--[[

The Display is the base class for device displays, and performs many duties;
it manages UIComponents, as it will both send and recieve their 
messages, and take care of their visual updates on the idle time update. 
The Display will also build the control surface, an interactive representation 
of the device complete with native sliders, knobs etc. 

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

  -- array of UIComponent instances
  self.ui_objects = table.create()
  -- each UI object notifier method is referenced by id, 
  -- so we can attach/detach the method when we need
  self.ui_notifiers = table.create()

  -- use the scheduler to perform periodic updates
  self.scheduler = Scheduler()

  -- this is the default palette for any display,
  -- the UIComponents use these values as defaults
  -- (note that color values with an average below 0x80
  -- might not display on monochrome devices)
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
  
  --  temp values (construction of control surface)
  self._parents = nil
  self._grid_obj = nil    
  self._grid_count = nil
end


--------------------------------------------------------------------------------

-- register a UIComponent with this display

function Display:add(obj_instance)
  TRACE('Display:add',obj_instance)
  
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
  
  -- force-update entire canvas for the next update
  for _,obj in ipairs(self.ui_objects) do
    if (obj.group_name) then
      obj.canvas.delta = table.rcopy(obj.canvas.buffer)
      obj.canvas.has_changed = true
      obj:invalidate()
    end
  end
end

--------------------------------------------------------------------------------

-- apply_tooltips: set tooltips on the virtual display based on the 
-- tooltip property assigned to existing ui_objects 
-- @param group_name: limit to a specific control-map group

function Display:apply_tooltips(group_name)
  TRACE("Display:apply_tooltips()",group_name)

  if (not self.view) then
    return
  end

  local control_map = self.device.control_map

  for _,obj in pairs(self.ui_objects) do
    if (control_map.groups[obj.group_name]) then
      if (group_name) and (group_name~=obj.group_name) then
        -- skip this element
      else
        for x = 1,obj.width do
          for y = 1, obj.height do
            local columns = control_map.groups[obj.group_name].columns
            local idx = (x+obj.x_pos-1)+((y+obj.y_pos-2)*columns)
            local elm = control_map:get_indexed_element(idx, obj.group_name)
            if (elm) then
              local widget = self.vb.views[elm.id]
              widget.tooltip = string.format("%s (%s)",obj.tooltip,elm.value)
            end
          end
        end
      end
    end
  end

end

--------------------------------------------------------------------------------

-- update: will update virtual/hardware displays (called continously)

function Display:update()

  if (not self.view) then
    return
  end

  if(self.scheduler)then
    self.scheduler:on_idle()
  end

  local control_map = self.device.control_map
  
  for _,obj in pairs(self.ui_objects) do

    -- skip unused objects, objects that doesn't need update
    if (obj.group_name and obj.dirty) then

      obj:draw()

      local columns = control_map.groups[obj.group_name].columns

      -- loop through the delta array - it contains all recent updates
      if (obj.canvas.has_changed) then

        for x = 1,obj.width do
          for y = 1, obj.height do
            if (obj.canvas.delta[x][y]) then
              if not (control_map.groups[obj.group_name]) then
                print(("Warning: '%s' is not specified in control-map "..
                  "group '%s'"):format(type(obj), tostring(obj.group_name)))
              else
                local idx = (x+obj.x_pos-1)+((y+obj.y_pos-2)*columns)
                local elm = control_map:get_indexed_element(idx, obj.group_name)
                if (elm) then
                  self:set_parameter(elm, obj, obj.canvas.delta[x][y])
                end
              end
            end

          end
        end
        
        obj.canvas:clear_delta()

      end

      -- check if the canvas has extraneous points that need to be cleared
      for x,v in pairs(obj.canvas.clear) do
        for y,v2 in pairs(obj.canvas.clear[x]) do
          -- clear point (TODO: clear tooltips as well)
          local idx = (x+obj.x_pos-1)+((y+obj.y_pos-2)*columns)
          local elm = control_map:get_indexed_element(idx, obj.group_name)
          if (elm) then
            local point = CanvasPoint()
            point:apply(self.palette.background)
            point.val = false      
            self:set_parameter(elm,obj,point)
          end

        end
      end

      obj.canvas.clear = {}

    end
  end
end


--------------------------------------------------------------------------------

-- set_parameter: update object states
-- @elm : control-map definition of the element
-- @obj : UIComponent instance
-- @point : canvas point (text/value/color)

function Display:set_parameter(elm, obj, point)
  TRACE('Display:set_parameter',elm.name,elm.value,point.text)

  local widget = nil
  local value = nil
  local num = nil

  -- update hardware display

  if (self.device) then 

    local msg_type = self.device.control_map:determine_type(elm.value)
    local current_message = self.device.message_stream.current_message
    local channel = nil
    if (self.device.protocol==DEVICE_MIDI_PROTOCOL) then
      channel = self.device:extract_midi_channel(elm.value) or 
        self.device.default_midi_channel
    end

    if (msg_type == MIDI_NOTE_MESSAGE) then
      num = self.device:extract_midi_note(elm.value)

      value = self.device:point_to_value(
        point, elm, obj.ceiling)

      -- do not loop back the original value change back to the sender, 
      -- unless the device explicitly wants this
      if (not current_message) or
         (current_message.is_virtual) or
         (current_message.context ~= MIDI_NOTE_MESSAGE) or
         (current_message.id ~= elm.id) or
         (current_message.value ~= value) or
         (self.device.loopback_received_messages)
      then
        self.device:send_note_message(num,value,channel)
      end
    
    elseif (msg_type == MIDI_CC_MESSAGE) then
      num = self.device:extract_midi_cc(elm.value)
      
      value = self.device:point_to_value(
        point, elm, obj.ceiling)

      -- do not loop back the original value change back to the sender, 
      -- unless the device explicitly wants this
      if (not current_message) or
         (current_message.is_virtual) or
         (current_message.context ~= MIDI_CC_MESSAGE) or
         (current_message.id ~= elm.id) or
         (current_message.value ~= value) or
         (self.device.loopback_received_messages)
      then
        self.device:send_cc_message(num,value,channel)
      end
    
    elseif (msg_type == MIDI_PITCH_BEND_MESSAGE) then

--[[ TODO      
      value = self.device:point_to_value(
        point, elm, obj.ceiling)

      -- do not loop back the original value change back to the sender, 
      -- unless the device explicitly wants this
      if (not current_message) or
         (current_message.is_virtual) or
         (current_message.context ~= MIDI_PITCH_BEND_MESSAGE) or
         (current_message.id ~= elm.id) or
         (current_message.value ~= value) or
         (self.device.loopback_received_messages)
      then
        self.device:send_pb_message(num,value)
      end
]]    
    elseif (msg_type == OSC_MESSAGE) then

      value = self.device:point_to_value(
        point, elm, obj.ceiling)
      -- do not loop back the original value change back to the sender, 
      -- unless the device explicitly wants this
      if (not current_message) or
         (current_message.is_virtual) or
         (current_message.context ~= OSC_MESSAGE) or
         (current_message.id ~= elm.id) or
         (current_message.value ~= value) or
         (self.device.loopback_received_messages)
      then
        self.device:send_osc_message(elm.value,value)
      end



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
      --local colorspace = self.device.colorspace
      local colorspace = elm.colorspace or self.device.colorspace
      if (colorspace[1] or colorspace[2] or colorspace[3]) then
        widget.color = self.device:quantize_color(point.color,colorspace)
        --widget.text = point.text
        --widget.text = nil
      else
        widget.color = { 0, 0, 0 }
        widget.text = point.text
      end
    elseif (type(widget) == "RotaryEncoder") or 
      (type(widget) == "MiniSlider") or
      (type(widget) == "Slider")
    then
      value = self.device:point_to_value(
        point, elm, obj.ceiling)

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
  
    -- reset temp states from previous walks
    self._parents = {}
    self._grid_obj = nil    
    self._grid_count = 0

    -- construct the control surface UI
    self:_walk_table(self.device.control_map.definition)

    self:apply_tooltips()

  end
  
  return self.view
end


--------------------------------------------------------------------------------

--  generate message : used by virtual control-surface elements
--  @value : the value
--  @metadata : metadata table (min/max etc.)
--  @release: boolean, true when button has been released

function Display:generate_message(value, metadata, released)
  TRACE('Display:generate_message:'..value)

  local msg = Message()
  msg.value = value

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

  -- the type of message (MIDI/OSC...)
  msg.context = self.device.control_map:determine_type(metadata.value)
  -- add channel/note-off for MIDI devices
  if (self.device.protocol == DEVICE_MIDI_PROTOCOL) then
    msg.channel = self.device:extract_midi_channel(metadata.value) or 
      self.device.default_midi_channel
    if (msg.context==MIDI_NOTE_MESSAGE) and released then
      msg.is_note_off = true
    end
  end

  -- input method : make sure we're using the right handler 
  if (metadata.type == "button") then
    msg.input_method = CONTROLLER_BUTTON

  elseif (metadata.type == "togglebutton") then
    msg.input_method = CONTROLLER_TOGGLEBUTTON

  elseif (metadata.type == "pushbutton") then
    msg.input_method = CONTROLLER_PUSHBUTTON

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

  -- mark as virtual generated message
  msg.is_virtual = true

  -- send the message
  self.device.message_stream:input_message(msg)
end


--------------------------------------------------------------------------------

--  _walk_table: create the virtual control surface
--  iterate through the control-map, while adding/collecting 
--  relevant meta-information 

function Display:_walk_table(t, done, deep)

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
  
        --- validate param properties first
        
        self:_validate_param(t[key].xarg)
      
      
        --- common properties

        local tooltip = string.format("%s (unassigned)",view_obj.meta.value)

        --  relative size
        local adj_width = UNIT_WIDTH
        local adj_height = UNIT_WIDTH
        if view_obj.meta.size then
          adj_width = (UNIT_WIDTH * view_obj.meta.size) + 
            (DEFAULT_SPACING * (view_obj.meta.size - 1))
          adj_height = (UNIT_HEIGHT * view_obj.meta.size) + 
            (DEFAULT_SPACING * (view_obj.meta.size - 1))
        end
        if view_obj.meta.aspect then
          adj_height = adj_height*view_obj.meta.aspect
        end


        --- Param:button, togglebutton or pushbutton

        if (view_obj.meta.type == "button" or 
            view_obj.meta.type == "togglebutton" or
            view_obj.meta.type == "pushbutton") then
          local notifier = function(value) 
            -- output the maximum value
            self:generate_message(tonumber(view_obj.meta.maximum),view_obj.meta)
          end
          local press_notifier = function(value) 
            -- output the maximum value
            self:generate_message(tonumber(view_obj.meta.maximum),view_obj.meta)
          end
          local release_notifier = function(value) 
            -- output the minimum value
            local released = true
            self:generate_message(
              tonumber(view_obj.meta.minimum),view_obj.meta,released)
          end
            
          self.ui_notifiers[view_obj.meta.id] = notifier
          view_obj.view = self.vb:button{
            id = view_obj.meta.id,
            width = adj_width,
            height = adj_height,
            tooltip = tooltip,
            pressed = press_notifier,
            released = release_notifier
          }
        
        
        --- Param:encoder
        --[[
        elseif (view_obj.meta.type == "encoder") then
          local notifier = function(value) 
            -- output the current value
            self:generate_message(value,view_obj.meta)
          end
            
            self.ui_notifiers[view_obj.meta.id] = notifier
            view_obj.view = self.vb:minislider{
              id=view_obj.meta.id,
              min = tonumber(view_obj.meta.minimum),
              max = tonumber(view_obj.meta.maximum),
              tooltip = tooltip,
              height = UNIT_HEIGHT/1.5,
              width = UNIT_WIDTH,
              notifier = notifier
            }
        ]]
          
        --- Param:dial
        
        elseif (view_obj.meta.type == "dial") then
          local notifier = function(value) 
            -- output the current value
            self:generate_message(value,view_obj.meta)
          end
          
          self.ui_notifiers[view_obj.meta.id] = notifier
          view_obj.view = self.vb:rotary{
            id = view_obj.meta.id,
            min = tonumber(view_obj.meta.minimum),
            max = tonumber(view_obj.meta.maximum),
            tooltip = tooltip,
            width = adj_width,
            height = adj_height,
            notifier = notifier
          }
          
          
        --- Param:fader
                  
        elseif (view_obj.meta.type == "fader") then
          local notifier = function(value) 
            -- output the current value
            self:generate_message(value,view_obj.meta)
          end
            
          self.ui_notifiers[view_obj.meta.id] = notifier

          if (view_obj.meta.orientation == "vertical") then
            view_obj.view = self.vb:row {
              -- padd with spaces to center DEFAULT_CONTROL_HEIGHT in UNIT_WIDTH
              self.vb:space { 
                width = (UNIT_WIDTH -  DEFAULT_CONTROL_HEIGHT) / 2 
              },
              self.vb:slider{
                id = view_obj.meta.id,
                min = tonumber(view_obj.meta.minimum),
                max = tonumber(view_obj.meta.maximum),
                tooltip = tooltip,
                width = DEFAULT_CONTROL_HEIGHT,
                height = (UNIT_WIDTH * view_obj.meta.size) + 
                  (DEFAULT_SPACING * (view_obj.meta.size - 1)),
                notifier = notifier
              },
              self.vb:space {
                width = (UNIT_WIDTH -  DEFAULT_CONTROL_HEIGHT) / 2 
              }
            }
          else
            
            view_obj.view = self.vb:slider {
              id  =view_obj.meta.id,
              min = tonumber(view_obj.meta.minimum),
              max = tonumber(view_obj.meta.maximum),
              tooltip = tooltip,
              width = (UNIT_WIDTH*view_obj.meta.size) + 
                (DEFAULT_SPACING*(view_obj.meta.size-1)),
              notifier = notifier
            }
          end
        end
        
  
      --- Column
  
      elseif (t[key].label == "Column") then
        view_obj.view = self.vb:column{
          spacing = DEFAULT_SPACING
        }
        self._parents[deep] = view_obj
        self._grid_obj = nil
  
  
      --- Row
  
      elseif (t[key].label == "Row") then
        view_obj.view = self.vb:row{
          spacing = DEFAULT_SPACING,
        }
        self._parents[deep] = view_obj
        self._grid_obj = nil

      --- Group
  
      elseif (t[key].label == "Group") then
      
        self:_validate_group(t[key].xarg)

        -- the group
        local orientation = t[key].xarg.orientation
        local columns = t[key].xarg.columns
          
        grid_id = nil

        if (columns) then
          -- enter "grid mode": use current group as 
          -- base object for inserting multiple rows
          self._grid_count = self._grid_count+1
          grid_id = string.format("grid_%i",self._grid_count)
          orientation = "vertical"
        else
          -- exit "grid mode"
          self._grid_obj = nil
        end
          
        if (orientation == "vertical") then
          view_obj.view = self.vb:column{
            style = "group",
            id = grid_id,
            margin = DEFAULT_MARGIN,
            spacing = DEFAULT_SPACING,
          }
        else
          
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
          self._grid_obj = view_obj
        end
          
        self._parents[deep] = view_obj
      end
        
      -- something was matched
      if (view_obj.view) then
        -- grid mode: create a(nother) row ?
        local row_id = nil
    
        if (view_obj.meta.row) then
          row_id = string.format("grid_%i_row_%i",
            self._grid_count,view_obj.meta.row)
        end
    
        if (not grid_id and self._grid_obj and 
          not self.vb.views[row_id]) then
    
          local row_obj = {
            view = self.vb:row{
              id=row_id,
              spacing=DEFAULT_SPACING,
            }
          }
          -- assign grid objects to this row
          self._grid_obj.view:add_child(row_obj.view)
          self._parents[deep-1] = row_obj
        end
          
        -- attach to parent object (if it exists)
        local added = false
    
        for i = deep-1, 1, -1 do
          if self._parents[i] then
            self._parents[i].view:add_child(view_obj.view)
            added = true
            break
          end
        end
          
        -- else, add to main view
        if (not added) then
          self.view:add_child(view_obj.view)
        end
      end
      
      self:_walk_table(value, done, deep)
    end
  end
end


--------------------------------------------------------------------------------

-- validate and fix a groups arg and try to give the control map author some
-- hints of what might be wroing with the control map

function Display:_validate_group(xargs)

  if (xargs.orientation ~= nil and 
      xargs.orientation ~= "vertical" and 
      xargs.orientation ~= "horizontal") 
  then
    renoise.app():show_warning(
      ('Whoops! The controlmap \'%s\' specifies no valid \'orientation\' '..
       'property in one of its \'Group\'s.\n\n'..
       'Please use orientation="horizontal" or orientation="vertical".'
      ):format(self.device.control_map.file_path))

    xargs.orientation = "horizontal"
  end
  
  if (xargs.name == nil) then
    renoise.app():show_warning(
      ('Whoops! The controlmap \'%s\' specifies no valid \'name\' '..
       'property in one of its \'Group\'s.\n\n'..
       'Please name the groups to be able to map them.'
      ):format(self.device.control_map.file_path))

    xargs.name = "Undefined"
  end
end

 
--------------------------------------------------------------------------------

-- validate and fix param xargs and try to give the control map author some
-- hints of what might be wroing with the control map

function Display:_validate_param(xargs)

  -- common Param properties
  
  -- name
  --[[
  if (xargs.name == nil) then
    renoise.app():show_warning(
      ('Whoops! The controlmap \'%s\' specifies no \'name\' property in one '..
       'of its \'Param\' fields.\n\n'..
       'Please add a name like name="Button #1" to all <Param>\'s in the '..
       'controlmap.'):format(self.device.control_map.file_path))

    xargs.name = "Undefined"
  end
  ]]
  
  -- value
  if (xargs.value == nil or 
      self.device.control_map:determine_type(xargs.value) == nil)
  then
    renoise.app():show_warning(
      ('Whoops! The controlmap \'%s\' specifies no or an invalid \'value\' '..
       'property in one of its \'Param\' fields: %s.\n\n'..
       'You have to map a control to a MIDI message via the name property, '..
       'i.e: value="CC#10" (control change number 10, any hannel) or PB|1 '..
       '(pitchbend on channel 1).'):format(
       self.device.control_map.file_path, xargs.value or "")
    )
  
    xargs.value = "CC#0"
  end
  
  -- type
  local valid_types = {"button", "togglebutton", "pushbutton", "encoder", "dial", "fader"}
          
  if (xargs.type == nil or not table.find(valid_types, xargs.type)) then
    renoise.app():show_warning(
      ('Whoops! The controlmap \'%s\' specifies no valid \'type\' property '..
       'in one of its \'Param\' fields.\n\n'..
       'Please use one of: %s'):format(self.device.control_map.file_path, 
       table.concat(valid_types, ", ")))

    xargs.type = "button"
  end
  
  
  -- minimum/maximum
  if (tonumber(xargs.minimum) == nil or
      tonumber(xargs.maximum) == nil or 
      tonumber(xargs.minimum) < 0 or 
      tonumber(xargs.maximum) < 0) 
  then
    renoise.app():show_warning(
      ('Whoops! The controlmap \'%s\' specifies no valid \'minimum\' '..
       'or \'maximum\' property in one of its \'Param\' fields.\n\n'..
       'Please use a number >= 0  (depending on the value, MIDI type).'
      ):format(self.device.control_map.file_path))

    xargs.minimum = 0 
    xargs.maximum = 127
  end
  
  -- faders
  
  if (xargs.type == "fader") then
    
    -- orientation
    if (xargs.orientation ~= "vertical" and 
        xargs.orientation ~= "horizontal") 
    then
      renoise.app():show_warning(
        ('Whoops! The controlmap \'%s\' specifies no valid \'orientation\' '..
         'property in one of its fader \'Params\'.\n\n'..
         'Please use either orientation="horizontal" or orientation="vertical".'
        ):format(self.device.control_map.file_path))
  
      xargs.orientation = "horizontal"
    end

    -- size
    if (type(xargs.size) == "nil") then
      renoise.app():show_warning(
        ('Whoops! The controlmap \'%s\' specifies no valid \'size\' '..
         'property in one of its fader \'Params\'.\n\n'..
         'Please use a number >= 1 as size".'
        ):format(self.device.control_map.file_path))
  
      xargs.size = 1
    end    
  end
end
 
 
--------------------------------------------------------------------------------

function Display:__tostring()
  return type(self)
end

