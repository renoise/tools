--[[============================================================================
-- Duplex.Display
============================================================================]]--

--[[--
The Display is the base class for device displays and the virtual UI

Display performs many duties; it manages UIComponents, as it will both send and recieve their messages, and take care of their visual updates on the idle time update. 

The Display will also build the control surface, an interactive representation of the device complete with native sliders, knobs etc. 

--]]

--==============================================================================


class 'Display' 

Display.UNIT_HEIGHT = 32
Display.UNIT_WIDTH = 32

--------------------------------------------------------------------------------

--- Initialize the Display class
-- @param device (@{Duplex.Device}) associate the Display with this device

function Display:__init(device)
  TRACE('Display:__init')

  assert(device, "Internal Error. Please report: " ..
    "expected a valid device for a display")
  
  --- (@{Duplex.Device})
  self.device = device  

  --- (renoise.ViewBuilder)
  self.vb = nil

  --- (renoise.Views.View) 
  self.view = nil    

  --- (table) associated UIComponent instances
  self.ui_objects = table.create()

  --- (table) each UI object notifier method is referenced by id, 
  -- so we can attach/detach the method on the fly (this is done 
  -- when we need to change the UI Object's value)
  self.ui_notifiers = table.create()

  --- (@{Duplex.Scheduler}) use scheduler to perform periodic updates
  self.scheduler = Scheduler()

  ---  (table) define the visual appearance of 'empty space', used e.g.
  --  when we remove a given point due to resizing
  --  @field text (string)
  --  @field color (table)
  --  @field val (bool)
  --- @table canvas_background
  self.canvas_background = {text="",color={0x00,0x00,0x00},val=false}
  
  --  temp values (construction of control surface)
  self._parents = nil
  self._grid_obj = nil    
  self._grid_count = nil

end


--------------------------------------------------------------------------------

--- Register a UIComponent with this display
-- @param obj_instance (@{Duplex.UIComponent}) 

function Display:add(obj_instance)
  TRACE('Display:add',obj_instance)
  
  self.ui_objects:insert(obj_instance)
end


--------------------------------------------------------------------------------

--- Clear display, force update of all UI components

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

--- Apply tooltips to UIComponents, based on their "tooltip" property 
-- @param group_name[opt] (string or nil), e.g. "Pads_1" or "Pads_*" (leave out to match all)

function Display:apply_tooltips(group_name)
  TRACE("Display:apply_tooltips()",group_name)

  local callback = function(ui_obj)
    local params = ui_obj:_get_ui_params()
    for _,param in ipairs(params) do
      local widget = self.vb.views[param.xarg.id]
      if param.xarg.value then
        widget.tooltip = string.format("%s\nValue: %s",ui_obj.tooltip,param.xarg.value)
      else
        widget.tooltip = ui_obj.tooltip
      end
    end
  end

  self:apply_to_objects(group_name,callback)

end

--------------------------------------------------------------------------------

--- Apply MIDI mappings to UIComponents, based on the "midi_mapping" property 
-- @param group_name[opt] (string or nil), e.g. "Pads_1" or "Pads_*" (leave out to match all)

function Display:apply_midi_mappings(group_name)
  TRACE("Display:apply_midi_mappings()",group_name)

  local callback = function(ui_obj)
    local widgets = ui_obj:_get_widgets()
    for _,widget in ipairs(widgets) do
      if ui_obj.midi_mapping then
        widget.midi_mapping = ui_obj.midi_mapping
      end
    end
  end

  self:apply_to_objects(group_name,callback)

end

--------------------------------------------------------------------------------

--- Apply callback function to UIComponents, using wildcard syntax
-- (e.g. for specifying tooltips, midi mappings etc.)
-- @param group_name[opt] (string or nil), e.g. "Pads_1" or "Pads_*" (leave out to match all)
-- @param callback (func) function to apply to matched components

function Display:apply_to_objects(group_name,callback)
  TRACE("Display:apply_to_objects",group_name,callback)

  if (not self.view) then
    return
  end

  local cm = self.device.control_map

  for _,obj in pairs(self.ui_objects) do
    if (cm.groups[obj.group_name]) then
      local matched_group = false
      if group_name then
        local wildcard_pos = string.find(group_name,"*")
        if wildcard_pos then
          if ((group_name):sub(1,wildcard_pos-1) == (obj.group_name):sub(1,wildcard_pos-1)) then
            matched_group = true
          end
        elseif (group_name) and (group_name==obj.group_name) then
          matched_group = true
        end
      else
        matched_group = true
      end
      if matched_group then
        callback(obj)
      end
    end
  end

end

--------------------------------------------------------------------------------

--- Disable an entire section of the display
-- (the enabled state of individual UIComponent is not affected)
-- @param state (bool) enabled when true, disabled when false
-- @param group_name[opt] (string or nil), leave out to match all

function Display:set_active_state(state,group_name)
  TRACE("Display:set_active_state",state,group_name)

  local callback = function(group)
    --print("*** set_active_state - callback",group)
    for k,param in ipairs(group) do
      local widget = self.vb.views[param.xarg.id]
      widget.active = state
    end
  end

  self:apply_to_groups(group_name,callback)

end

--------------------------------------------------------------------------------

--- Apply callback function to groups
-- (e.g. for quickly disabling entire, or partial display)
-- @param group_name[opt] (string or nil), leave out to match all
-- @param callback (func) function to apply to matched groups

function Display:apply_to_groups(group_name,callback)
  TRACE("Display:apply_to_groups",group_name,callback)

  if (not self.view) then
    return
  end

  local cm = self.device.control_map

  for _,grp in pairs(cm.groups) do
    local matched_group = (not group_name) and true or false
    if not matched_group and (group_name==grp.xarg.name) then
      matched_group = true
    end
    --print("*** apply_to_groups - matched_group",matched_group,group_name,grp.xarg.name)
    --rprint(grp)
    if matched_group then
      callback(grp)
    end
  end

end

--------------------------------------------------------------------------------

--- Update any UIComponent that has been modified since the last update
-- (called continously)

function Display:update()

  if (not self.view) then
    return
  end

  if(self.scheduler)then
    self.scheduler:on_idle()
  end

  -- OSC devices need this when sending message bundles
  if(self.device.on_idle)then
    self.device:on_idle()
  end

  local cm = self.device.control_map
  
  for _,obj in pairs(self.ui_objects) do


    -- skip unused objects, objects that doesn't need update
    if (obj.group_name and obj.dirty) then

      obj:draw()
      --print("*** Display.update - obj.canvas.has_changed",obj,obj.canvas.has_changed)
      --print("*** Display.update - obj.group_name",obj.group_name)
      local columns = cm.groups[obj.group_name].columns

      -- loop through the delta array - it contains all recent updates
      if (obj.canvas.has_changed) then
        for x = 1,obj.width do
          for y = 1, obj.height do
            --print("*** obj.canvas.delta["..x.."]["..y.."]",obj.canvas.delta[x][y])
            if (obj.canvas.delta[x][y]) then
              local idx = (x+obj.x_pos-1)+((y+obj.y_pos-2)*columns)
              local param = cm:get_param_by_index(idx, obj.group_name)
              if param and param.xarg then
                self:set_parameter(param, obj, obj.canvas.delta[x][y])
              end
            end
          end
        end
        obj.canvas:clear_delta()
      end

      -- check if the canvas has extraneous points that need to be cleared
      local got_cleared = false
      for x,v in pairs(obj.canvas.clear) do
        for y,v2 in pairs(obj.canvas.clear[x]) do
          --print("Display:update() - clear point x,y",x,y)
          -- clear point (TODO: clear tooltips as well)
          local idx = (x+obj.x_pos-1)+((y+obj.y_pos-2)*columns)
          local param = cm:get_param_by_index(idx, obj.group_name)
          if (param.xarg) then
            local point = CanvasPoint()
            --point:apply(self.palette.background)
            point:apply(self.canvas_background)
            point.val = false      
            self:set_parameter(param,obj,point)
            got_cleared = true
          end

        end
      end
      if got_cleared then
        obj.canvas.clear = {}
      end

    end
  end
end


--------------------------------------------------------------------------------

--- Set_parameter: apply parameter changes, update the display
-- @param param (table) control-map definition of the element
-- @param ui_obj (@{Duplex.UIComponent}) 
-- @param point (@{Duplex.CanvasPoint}) text/value/color
-- @param skip_ui (bool) true when we are sending subparameters

function Display:set_parameter(param,ui_obj,point,skip_ui)
  TRACE('Display:set_parameter',param,ui_obj,point,skip_ui)

  -- reference to control-map
  local cm = self.device.control_map

  -- create our output value 
  -- at this stage, we might directly communicate with the hardware, 
  -- in which case the "skip_hardware" flag can be set to true
  local value,skip_hardware = nil,false
  value,skip_hardware = self.device:output_value(point,param.xarg,ui_obj)
  --print("*** set_parameter - value,point.val",value,point.val)

  if not skip_hardware then
    skip_hardware = (param.xarg.skip_echo or ui_obj.soft_echo or
      not self.device.loopback_received_messages) and true or false
  end  
  --print("*** set_parameter - skip_hardware",skip_hardware)


  -- update virtual control surface
  ---------------------------------------------------------

  if not skip_ui then

    local widget = nil
    if (self.vb and self.vb.views) then 
      widget = self.vb.views[param.xarg.id]
    end

    if (widget) then

      local widget_type = type(widget)
      if (widget_type == "Button") then

        local set_widget = widget_hooks["button"].set_widget
        set_widget(self,widget,param.xarg,ui_obj,point,value)

      elseif (widget_type == "RotaryEncoder") or 
        (widget_type == "MiniSlider") or
        (widget_type == "Slider")
      then
        widget:remove_notifier(self.ui_notifiers[param.xarg.id])
        widget.value = tonumber(value)
        widget:add_notifier(self.ui_notifiers[param.xarg.id])
      
      elseif (widget_type == "XYPad") then

        widget:remove_notifier(self.ui_notifiers[param.xarg.id])
        widget.value = {
          x=value[1],
          y=value[2]
        }
        widget:add_notifier(self.ui_notifiers[param.xarg.id])

      elseif (widget_type == "MultiLineText") then

        widget.text = value

      elseif (widget_type == "Rack") then

        -- Custom widgets (e.g. keyboard)
        --print("*** set_parameter - ui_obj",ui_obj)

        if (param.xarg.type == "keyboard") then
          local set_widget = widget_hooks["keyboard"].set_widget
          set_widget(self,widget,param.xarg,ui_obj,point,value)
        end

      else
        error(("Internal Error. Please report: " .. 
          "unexpected or unknown widget type '%s'"):format(type(widget)))
      end
    end 

  end 


  -- update hardware display
  ---------------------------------------------------------

  if not skip_hardware then

    -- perform last-minute changes to output
    -- e.g. to swap axes on an xypad 
    local on_send = widget_hooks[param.xarg.type].on_send
    if on_send then
      on_send(self,param,ui_obj,point,value)
    end

    if param.xarg.has_subparams then

      -- if we are dealing with a parameter that contain sub-parameters,
      -- (multiple values), we instead send multiple messages 

      local set_subparams = widget_hooks[param.xarg.type].set_subparams
      if set_subparams then
        set_subparams(self,param,point,ui_obj)
      end


    else --/subparams
 
      local msg_type = cm:determine_type(param.xarg.value)

      if not (msg_type == DEVICE_MESSAGE.OSC) then

        -- determine the channel (specified or default)
        local channel = nil
        if (self.device.protocol==DEVICE_PROTOCOL.MIDI) then
          channel = self.device:extract_midi_channel(param.xarg.value) or 
            self.device.default_midi_channel
        end

        if (msg_type == DEVICE_MESSAGE.MIDI_NOTE) then

          local num = self.device:extract_midi_note(param.xarg.value)
          self.device:send_note_message(num,math.floor(value),channel,param.xarg,point)

        elseif (msg_type == DEVICE_MESSAGE.MIDI_CC) then

          local num = self.device:extract_midi_cc(param.xarg.value)
          self.device:send_cc_message(num,math.floor(value),channel)

        elseif (msg_type == DEVICE_MESSAGE.MIDI_PITCH_BEND) then

          -- normally, you wouldn't send back pitch bend messages
          -- but under some circumstances (Mackie Control) it is needed
          self.device:send_pitch_bend_message(math.floor(value),channel)

        elseif (msg_type == DEVICE_MESSAGE.MIDI_CHANNEL_PRESSURE) then

          -- do nothing

        elseif (msg_type == DEVICE_MESSAGE.MIDI_KEY) then

          -- do nothing

        else
          error(("Internal Error. Please report: " ..
            "unknown or unhandled msg_type: '%s'"):format(msg_type or "nil"))
        end

      else


        -- it's recommended that wireless devices have their 
        -- messages bundled (or some might get lost)
        --print("*** set_parameter - self.device.bundle_messages",self.device.bundle_messages)
        if self.device.bundle_messages then
          self.device:queue_osc_message(param.xarg.value,value)
        else
          self.device:send_osc_message(param.xarg.value,value)
        end

      end

    end

  end

end

--------------------------------------------------------------------------------

--- Build the virtual control-surface (based on the parsed control-map)
-- @return renoise.Views.View

function Display:build_control_surface()
  TRACE('Display:build_control_surface')

  local cm = self.device.control_map

  self.vb = renoise.ViewBuilder()
  self.view = self.vb:column {
    id = "display_rootnode",
    margin = DEFAULT_MARGIN,
    --spacing = 16,
  }
  
  -- loading may have failed. check if definition is valid...
  if (cm.definition) then
  
    -- reset temp states from previous walks
    self._parents = {}
    self._grid_obj = nil    
    self._grid_count = 0

    -- construct the control surface UI
    self:_walk_table(cm.definition)

    self:apply_tooltips()

  end
  
  return self.view

end


--------------------------------------------------------------------------------

---  Generate messages for the virtual control-surface (creates a 
-- @{Duplex.Message} which is then passed into a @{Duplex.MessageStream}).
--
-- Similar to @{Duplex.Device._send_message}, except that here we 
-- need to create everything (value, midi message, etc.) from scratch
--
-- @param value (number or table) value, or table of values
-- @param param (table) `Param` node attributes, see @{Duplex.ControlMap}
-- @param released (bool), true when button has been released

function Display:generate_message(value, param, released)
  TRACE('Display:generate_message:',value, param, released)

  local msg = Message()
  msg.value = value

  -- the type of message
  if param.xarg.action then
    msg.context = self.device.control_map:determine_type(param.xarg.action)
  else
    msg.context = self.device.control_map:determine_type(param.xarg.value)
  end

  msg.timestamp = os.clock()

  -- include as copy 
  msg.xarg = table.rcopy(param.xarg)
  --msg.xarg = param.xarg

  if released then
    msg.is_note_off = true
  end

  if (param.xarg.type == "keyboard") then
    
    -- if widget is keyboard, we have received a full midi-message
    --print("*** generate_message - we have received a midi-message",rprint(value))
    msg.midi_msg = value

  else

    -- if possible, create a "virtual" midi message 

    msg.channel = 1
    if self.device.extract_midi_channel then
      msg.channel = self.device:extract_midi_channel(param.xarg.value) or 
        self.device.default_midi_channel
    end

    if (msg.context==DEVICE_MESSAGE.MIDI_NOTE) then
      -- value specifies the velocity
      local note_pitch = value_to_midi_pitch(param.xarg.value)+12
      msg.midi_msg = {143+msg.channel,note_pitch,value[2]}
    elseif (msg.context==DEVICE_MESSAGE.MIDI_CC) then
      -- value specifies the CC value
      local cc_num = extract_cc_num(param.xarg.value)
      msg.midi_msg = {175+msg.channel,cc_num,math.floor(value)}
    elseif (msg.context==DEVICE_MESSAGE.MIDI_CHANNEL_PRESSURE) then
      -- value specifies the pressure amount
      msg.midi_msg = {207+msg.channel,0,math.floor(value)}
    elseif (msg.context==DEVICE_MESSAGE.MIDI_PITCH_BEND) then
      -- value specifies the pitch bend amount
      msg.midi_msg = {223+msg.channel,math.floor(value),0}
    end
    --print("*** Display: generate_message - virtually generated midi msg...")
    --rprint(msg.midi_msg)
    --print("msg.is_note_off",msg.is_note_off,released)

  end

  -- flag as virtually generated message
  msg.is_virtual = true

  msg.device = self.device

  -- send the message
  self.device.message_stream:input_message(msg)

end


--------------------------------------------------------------------------------

---  Walk control-map defition, and create the virtual control surface
-- @param t (table) the control-map defition
-- @param done (table) internal calculation table 
-- @param deep (int) the nesting level

function Display:_walk_table(t, done, deep)
  --TRACE("Display:_walk_table(t, done, deep)",t, done, deep)

  deep = deep and deep + 1 or 1  --  
  done = done or {}

  for key, value in pairs(t) do
    if (type(value) == "table" and not done[value]) then
      done [value] = true
        
      local grid_id = nil
      local view_obj = nil
      local param = t[key]

  
      if (param.label == "Param") then
  
        --- validate param properties
        local cm = self.device.control_map
        widget_hooks.generic_type.validate(self,param,cm)
        widget_hooks[param.xarg.type].validate(self,param,cm)

        --- common properties

        local tooltip = nil
        if param.xarg.value then
          tooltip = string.format("%s (unassigned)",param.xarg.value)
        end

        --  relative size
        local adj_width = Display.UNIT_WIDTH
        local adj_height = Display.UNIT_WIDTH
        if param.xarg.size then
          adj_width = (Display.UNIT_WIDTH * param.xarg.size) + 
            (DEFAULT_SPACING * (param.xarg.size - 1))
          adj_height = (Display.UNIT_HEIGHT * param.xarg.size) + 
            (DEFAULT_SPACING * (param.xarg.size - 1))
        end
        if param.xarg.aspect then
          adj_height = adj_height*param.xarg.aspect
        end

        -- add widgets and notifiers 
        view_obj = widget_hooks[param.xarg.type].build(
          self,param,adj_width,adj_height,tooltip)


        
      elseif (param.label == "Column") then
    
        -- Column
    
        view_obj = self.vb:column{
          spacing = DEFAULT_SPACING
        }
        self._parents[deep] = view_obj
        self._grid_obj = nil
  
      elseif (param.label == "Row") then
    
        -- Row
    
        view_obj = self.vb:row{
          spacing = DEFAULT_SPACING,
        }
        self._parents[deep] = view_obj
        self._grid_obj = nil
      elseif (param.label == "Group") then

        -- Group
    
        self:_validate_group(param.xarg)

        -- the group
        local orientation = param.xarg.orientation
        local columns = param.xarg.columns
        local visible = param.xarg.visible
          
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
          view_obj = self.vb:column{
            style = "group",
            visible = visible,
            id = grid_id,
            margin = DEFAULT_MARGIN,
            spacing = DEFAULT_SPACING,
          }
        else
          
          view_obj = self.vb:row{
            style = "group",
            visible = visible,
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
      if (view_obj) then
        -- grid mode: create a(nother) row ?
        local row_id = nil
    
        if (param.xarg.row) then
          row_id = string.format("grid_%i_row_%i",
            self._grid_count,param.xarg.row)
        end
    
        if (not grid_id and self._grid_obj and 
          not self.vb.views[row_id]) then
    
          local row_obj = self.vb:row{
            id=row_id,
            spacing=DEFAULT_SPACING,
          }
          -- assign grid objects to this row
          self._grid_obj:add_child(row_obj)
          self._parents[deep-1] = row_obj
        end
          
        -- attach to parent object (if it exists)
        local added = false
    
        for i = deep-1, 1, -1 do
          if self._parents[i] then
            self._parents[i]:add_child(view_obj)
            added = true
            break
          end
        end
          
        -- else, add to main view
        if (not added) then
          self.view:add_child(view_obj)
        end
      end
      
      self:_walk_table(value, done, deep)
    end
  end
end


--------------------------------------------------------------------------------

--- Validate/fix groups and try to give the control map author some
-- hints of what might be wrong with the control map
-- @param xarg (table) the control-map attributes

function Display:_validate_group(xarg)
  TRACE("Display:_validate_group",xarg)

  if (xarg.orientation ~= nil and 
      xarg.orientation ~= "vertical" and 
      xarg.orientation ~= "horizontal") 
  then
    renoise.app():show_warning(
      ('Whoops! The controlmap \'%s\' specifies no valid \'orientation\' '..
       'property in one of its \'Group\'s.\n\n'..
       'Please use orientation="horizontal" or orientation="vertical".'
      ):format(self.device.control_map.file_path))

    xarg.orientation = "horizontal"
  end
  
  if (xarg.name == nil) then
    renoise.app():show_warning(
      ('Whoops! The controlmap \'%s\' specifies no valid \'name\' '..
       'property in one of its \'Group\'s.\n\n'..
       'Please name the groups to be able to map them.'
      ):format(self.device.control_map.file_path))

    xarg.name = "Undefined"
  end
end

 
 
--------------------------------------------------------------------------------

function Display:__tostring()
  return type(self)
end

