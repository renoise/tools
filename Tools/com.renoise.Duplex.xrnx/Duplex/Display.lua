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
local KEYS_COLOR_WHITE = {0x9F,0x9F,0x9F}
local KEYS_COLOR_WHITE_PRESSED = {0xCF,0xCF,0xCF}
local KEYS_COLOR_WHITE_DISABLED = {0x5F,0x5F,0x5F}
local KEYS_COLOR_BLACK = {0x00,0x00,0x00}
local KEYS_COLOR_BLACK_PRESSED = {0x6F,0x6F,0x6F}
local KEYS_COLOR_BLACK_DISABLED = {0x3F,0x3F,0x3F}
local KEYS_COLOR_OUT_OF_BOUNDS = {0x46,0x47,0x4B}
local KEYS_WIDTH = 28
local KEYS_MIN_WIDTH = 18 
local KEYS_HEIGHT = 64
local BOGUS_NOTE = "H#1"


--==============================================================================

class 'Display' 

--------------------------------------------------------------------------------

--- Initialize the Display class
-- @param device (Device) associate the Display with this device

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
  -- so we can attach/detach the method (this is done 
  -- when we need to change the UI Object's value)
  self.ui_notifiers = table.create()

  -- use the scheduler to perform periodic updates
  self.scheduler = Scheduler()

  -- this is the default palette for any display,
  -- the UIComponents can use these values as defaults
  self.palette = {
    background      = { text="",  color={0x00,0x00,0x00},val=false  },
    color_1         = { text="■", color={0xff,0xff,0xff},val=true   },
    color_1_dimmed  = { text="□", color={0x40,0x40,0x40},val=false  },
    color_2         = { text="▪", color={0x80,0x80,0x80},val=true   },
    color_2_dimmed  = { text="▫", color={0x40,0x40,0x40},val=false  },
  }    
  
  --  temp values (construction of control surface)
  self._parents = nil
  self._grid_obj = nil    
  self._grid_count = nil
end


--------------------------------------------------------------------------------

--- Register a UIComponent with this display
-- @param obj_instance (UIComponent) a UIComponent class instance

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

--- Apply_tooltips: set tooltips on the virtual display based on the 
-- tooltip property assigned to existing ui_objects 
-- @param group_name (String) optional, restrict to named control-map group 
--  (note that this value support the use of wildcards, e.g. "Pads_*")

function Display:apply_tooltips(group_name)
  TRACE("Display:apply_tooltips()",group_name)

  if (not self.view) then
    return
  end

  local control_map = self.device.control_map

  for _,obj in pairs(self.ui_objects) do
    if (control_map.groups[obj.group_name]) then
      local matched_group = false
      if group_name then
        -- check if group name contain a wildcard (asterisk)
        local wildcard_pos = string.find(group_name,"*")
        if wildcard_pos then
          if ((group_name):sub(1,wildcard_pos-1) == (obj.group_name):sub(1,wildcard_pos-1)) then
            -- matched group by wildcard
            matched_group = true
          end
        elseif (group_name) and (group_name~=obj.group_name) then
          -- matched named group
          matched_group = true
        end
      else
        -- match any group
        matched_group = true
      end
      if matched_group then
        for x = 1,obj.width do
          for y = 1, obj.height do
            local columns = control_map.groups[obj.group_name].columns
            local idx = (x+obj.x_pos-1)+((y+obj.y_pos-2)*columns)
            local elm = control_map:get_indexed_element(idx, obj.group_name)
            if (elm) then
              local widget = self.vb.views[elm.id]
              if elm.value then
                widget.tooltip = string.format("%s\nValue: %s",obj.tooltip,elm.value)
              else
                widget.tooltip = obj.tooltip
              end
            end
          end
        end
      end
    end
  end

end

--------------------------------------------------------------------------------

--- Update any UIComponent that has been modified since the last update
-- (this function is called continously)

function Display:update()

  if (not self.view) then
    return
  end

  if(self.scheduler)then
    self.scheduler:on_idle()
  end

  if(self.device.on_idle)then
    self.device:on_idle()
  end

  local control_map = self.device.control_map
  
  for _,obj in pairs(self.ui_objects) do


    -- skip unused objects, objects that doesn't need update
    if (obj.group_name and obj.dirty) then

      obj:draw()

      --print("*** Display.update - obj.group_name",obj.group_name)
      local columns = control_map.groups[obj.group_name].columns

      -- loop through the delta array - it contains all recent updates
      if (obj.canvas.has_changed) then


        for x = 1,obj.width do
          for y = 1, obj.height do
            --print("*** obj.canvas.delta["..x.."]["..y.."]",obj.canvas.delta[x][y])
            if (obj.canvas.delta[x][y]) then

              if not (control_map.groups[obj.group_name]) then
                LOG(("Warning: '%s' is not specified in control-map "..
                  "group '%s'"):format(type(obj), tostring(obj.group_name)))
              else
                local idx = (x+obj.x_pos-1)+((y+obj.y_pos-2)*columns)
                local elm = control_map:get_indexed_element(idx, obj.group_name)

                --print("*** elm,idx,obj.group_name",elm,idx,obj.group_name)
                -- if element is a UIKey and part of a keyboard, 
                -- provide a dynamically generated entry
                if not elm and (type(obj)=="UIKey") then
                  elm = control_map:get_indexed_element(1, obj.group_name)
                  elm.skip_echo = true
                end
                if (elm) then
                  -- update the display & hardware
                  self:set_parameter(elm, obj, obj.canvas.delta[x][y])
                end
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
          local elm = control_map:get_indexed_element(idx, obj.group_name)
          if (elm) then
            local point = CanvasPoint()
            point:apply(self.palette.background)
            point.val = false      
            self:set_parameter(elm,obj,point)
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
-- @param elm (Table) control-map definition of the element
-- @param obj (UIComponent) instance of UIComponent
-- @param point (CanvasPoint) point containing text/value/color
-- @param secondary (Boolean), true when method call itself (value-pairs)

function Display:set_parameter(elm, obj, point, secondary)
  --TRACE('Display:set_parameter',elm, obj, point, secondary)

  -- resulting numeric value, or table of values (XYPad)
  local value = nil

  -- bypass the device class for this parameter?
  if elm.is_virtual then
    --print("bypass the device class for this parameter")
    if (self.device.protocol==DEVICE_MIDI_PROTOCOL) then
      value = MidiDevice:point_to_value(point,elm,obj.ceiling)
    elseif (self.device.protocol==DEVICE_OSC_PROTOCOL) then
      value = OscDevice:point_to_value(point,elm,obj.ceiling)
    end
    elm.skip_echo = true
  else
    value = self.device:point_to_value(point,elm,obj.ceiling)
  end

  --print("*** Display:set_parameter() - value",value)
  --print("*** Display:set_parameter() - elm",elm)
  --rprint(elm)
  --print("*** Display:set_parameter() - elm.skip_echo",elm.skip_echo)

  -- reference to control-map
  local cm = self.device.control_map


  -- update hardware display

  -- when this is specified, device is not updated
  if not elm.skip_echo and self.device.loopback_received_messages then

    -- the type of message, based on the control-map
    local msg_type = cm:determine_type(elm.value)

    -- determine the channel (specified or default)
    local channel = nil
    if (self.device.protocol==DEVICE_MIDI_PROTOCOL) then
      channel = self.device:extract_midi_channel(elm.value) or 
        self.device.default_midi_channel
    end

    if (msg_type == MIDI_NOTE_MESSAGE) then
      local num = self.device:extract_midi_note(elm.value)

      -- check if we should send message back to the sender
      self.device:send_note_message(num,value,channel,elm,point)

    elseif (msg_type == MIDI_CC_MESSAGE) then

      if (type(point.val) == "table") then

        -- special case: xypad value is a table 

        if obj.secondary_index then

          if secondary then
            elm = cm:get_indexed_element(obj.secondary_index, obj.group_name)
            if elm then
              point.val = point.val[2]
              value = self.device:point_to_value(
                point, elm, obj.ceiling)
            else
              --print("could not locate secondary elm")
            end
          else
            -- value-pair, invoke method again
            Display.set_parameter(self, elm, obj, point,true)
          end

        end

      end

      local num = self.device:extract_midi_cc(elm.value)
      self.device:send_cc_message(num,value,channel)

    elseif (msg_type == MIDI_PITCH_BEND_MESSAGE) then

      -- sending pitch-bend back to a device doesn't make sense when
      -- you're using a keyboard - it's generally recommended to tag 
      -- the parameter with the "skip_echo" attribute in such a case...
      -- however, some device setups are different (e.g. Mackie Control)
      self.device:send_pitch_bend_message(value,channel)

    elseif (msg_type == MIDI_CHANNEL_PRESSURE) then
      -- do nothing
    elseif (msg_type == MIDI_KEY_MESSAGE) then
      -- do nothing
    elseif (msg_type == OSC_MESSAGE) then

      local osc_value = value

      if (elm.type == "xypad") then
        if (type(osc_value)=="table") then
          osc_value = table.rcopy(value)
        end
        -- invert xypad axes? 
        osc_value[1] = elm.invert_x and 
          elm.maximum-osc_value[1] or osc_value[1]
        osc_value[2] = elm.invert_y and 
          elm.maximum-osc_value[2] or osc_value[2]
        -- swap xypad axes? 
        if (elm.swap_axes) then
          osc_value[1],osc_value[2] = osc_value[2],osc_value[1]
        end
      end
      

      --print("*** elm.type",elm.type)
      --print("*** elm.value",elm.value)
      --print("*** osc_value",osc_value)

      -- it's recommended that wireless devices have their 
      -- messages bundled (or some might get lost)
      if self.device.bundle_messages then
        self.device:queue_osc_message(elm.value,osc_value)
      else
        self.device:send_osc_message(elm.value,osc_value)
      end

      --end
    else
      error(("Internal Error. Please report: " ..
        "unknown or unhandled msg_type: '%s'"):format(msg_type or "nil"))
    end

  end

  -- update virtual control surface

  local widget = nil
  if (self.vb and self.vb.views) then 
    widget = self.vb.views[elm.id]
  end

  if (widget) then
    local widget_type = type(widget)
    if (widget_type == "Button") then

      local c_space = elm.colorspace or self.device.colorspace
      if not is_monochrome(c_space) then

        widget.color = self.device:quantize_color(point.color,c_space)
      else
        if (point.val==false) then
          widget.color = {0x00,0x00,0x00}
        else
          local color = nil
          if table_has_equal_values(c_space) then
            -- all white monochrome: use the theme color
            color = {duplex_preferences.theme_color_R.value,
              duplex_preferences.theme_color_G.value,
              duplex_preferences.theme_color_B.value}
          else
            -- tinted color, use the colorspace
            color = {c_space[1]*255,c_space[2]*255,c_space[3]*255}
          end
          --print("set button widget to this color")
          --rprint(color)
          widget.color = color
        end
      end
      widget.text = point.text

    elseif (widget_type == "RotaryEncoder") or 
      (widget_type == "MiniSlider") or
      (widget_type == "Slider")
    then
      widget:remove_notifier(self.ui_notifiers[elm.id])
      widget.value = tonumber(value)
      widget:add_notifier(self.ui_notifiers[elm.id])
    
    elseif (widget_type == "XYPad") then

      widget:remove_notifier(self.ui_notifiers[elm.id])
      widget.value = {
        x=point.val[1],
        y=point.val[2]
      }
      widget:add_notifier(self.ui_notifiers[elm.id])

    elseif (widget_type == "MultiLineText") then

      -- Label...

      --print("*** widget.text",value)
      widget.text = value

    elseif (widget_type == "Rack") then

      -- A keyboard is represented by a Rack ...

      if obj._key_update_requested then
        -- complete refresh requested
        obj._key_update_requested = false
        for i=LOWER_NOTE,UPPER_NOTE do
          self:update_key(i+13,elm,obj)
        end

      else
        -- single key, locate the right button
        local is_osc_msg = (elm.value):sub(0,1)=="/"
        -- the most recent message
        local current_message = self.device.message_stream.current_message
        local is_virtual = (current_message) and current_message.is_virtual or false
        local key_idx = nil
        if is_osc_msg then
          if obj.pitch then
            key_idx = obj.pitch - obj.transpose +13
          else
            key_idx = obj.x_pos
          end
          if (is_virtual) then
            key_idx = key_idx + 1
          end
        else
          if obj.pitch then
            -- MIDI keyboard
            key_idx = (obj.pitch+1) - obj.transpose +12
            --key_idx = (obj.pitch+1) + 12
          else
            -- no pitch means "match all" 
            key_idx = obj.x_pos
            --key_idx = obj.x_pos - obj.transpose +12
          end
        end

        -- initial index can't always be determined (OSC messages)
        if key_idx then
          self:update_key(key_idx,elm,obj)
        end

      end

    else
      error(("Internal Error. Please report: " .. 
        "unexpected or unknown widget type '%s'"):format(type(widget)))
    end
  end 
end

--------------------------------------------------------------------------------

--- Update special UI key widgets (pressed, normal, disabled)
-- @param key_idx (Number) the keys index
-- @param elm (Table) control-map definition of the element
-- @param obj (UIKey) instance of a UIKey component

function Display:update_key(key_idx,elm,obj)
  --TRACE("Display:update_key()",key_idx,type(key_idx),elm,obj)

  local key_id = ("%s_%i"):format(elm.id,key_idx)
  local key_widget = self.vb.views[key_id]

  if key_widget then

    -- figure out if it's a black or white key
    local is_white_key = true
    -- normalize the position (no octave)
    local key_pos = key_idx%12
    if (key_pos==2) or 
      (key_pos==4) or
      (key_pos==7) or
      (key_pos==9) or
      (key_pos==11) 
    then
      is_white_key = false
    end
    
    local label = ""
    local color = nil

    if (key_idx+obj.transpose-13 > UPPER_NOTE) then
      color = KEYS_COLOR_OUT_OF_BOUNDS
      key_widget.active = false
    else
      key_widget.active = true
      -- assign every octave as label
      if (key_idx%12==1) then
        label = ("%d"):format(math.floor(obj.transpose+key_idx)/12)
      end
      if obj.disabled_keys[key_idx+obj.transpose] then
        color = is_white_key and KEYS_COLOR_WHITE_DISABLED or KEYS_COLOR_BLACK_DISABLED
        --key_widget.active = false
      else
        if not obj.pressed_keys[key_idx+obj.transpose] then
        --if not obj.pressed then
          color = is_white_key and KEYS_COLOR_WHITE or KEYS_COLOR_BLACK
        else
          color = is_white_key and KEYS_COLOR_WHITE_PRESSED or KEYS_COLOR_BLACK_PRESSED
        end
      end
    end

    -- add text only when there's room
    if(key_widget.width<KEYS_MIN_WIDTH)then
      key_widget.text = ""
    else
      key_widget.text = label
    end

    key_widget.color = color

  end

end

--------------------------------------------------------------------------------

--- Build the virtual control-surface (based on the parsed control-map)
-- @return ViewBuilder

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

---  Generate message : used by virtual control-surface elements
--  @param value (Number or Table) value, or table of values
--  @param metadata (Table) metadata, such as min/max etc.
--  @param released (Boolean), true when button has been released

function Display:generate_message(value, metadata, released)
  TRACE('Display:generate_message:',value, metadata, released)

  local msg = Message()
  msg.value = value

  -- the type of message (MIDI/OSC...)
  -- todo: optimize by including context as function argument
  msg.context = self.device.control_map:determine_type(metadata.value)



  -- include these meta-properties
  msg.param = metadata
  msg.group_name = metadata.group_name
  msg.id = metadata.id
  msg.index = metadata.index
  msg.column = metadata.column
  msg.row = metadata.row
  msg.timestamp = os.clock()
  msg.max = metadata.maximum
  msg.min = metadata.minimum

  if released then
    msg.is_note_off = true
  end

  if (msg.context == OSC_MESSAGE) then
    msg.is_osc_msg = true
  end 

  -- for MIDI devices, create the "virtual" midi message

  if (self.device.protocol == DEVICE_MIDI_PROTOCOL) then
    msg.channel = self.device:extract_midi_channel(metadata.value) or 
      self.device.default_midi_channel


    if (msg.context==MIDI_NOTE_MESSAGE) then
      local note_pitch = value[1]
      -- if available, use the pitch defined in the control-map 
      --print("Display: metadata.value",(metadata.value):sub(0,3))
      if ((metadata.value):sub(0,3)~=BOGUS_NOTE) then
        note_pitch = value_to_midi_pitch(metadata.value)+12
      end
      --print("Display: note_pitch",note_pitch)
      msg.midi_msg = {143+msg.channel,note_pitch,value[2]}
    elseif (msg.context==MIDI_CC_MESSAGE) then
      local cc_num = extract_cc_num(metadata.value)
      local cc_value = value
      -- A #CC button might have produced a MIDI-note message (thank to it's 
      -- application), but it's virtual message should still be a CC message.
      -- Detect if the value is a table and treat the value correspondingly
      if (type(value)=="table") and (msg.context~=MIDI_NOTE_MESSAGE) then
        cc_value = value[2]
      end
      msg.midi_msg = {175+msg.channel,cc_num,math.floor(cc_value)}
    elseif (msg.context==MIDI_CHANNEL_PRESSURE) then
      msg.midi_msg = {207+msg.channel,0,math.floor(value)}
    elseif (msg.context==MIDI_PITCH_BEND_MESSAGE) then
      msg.midi_msg = {223+msg.channel,math.floor(value),0}
    end
    --print("Display: virtually generated midi msg...")
    --rprint(msg.midi_msg)
    --print("msg.is_note_off",msg.is_note_off,released)
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

  elseif (metadata.type == "xypad") then
    msg.input_method = CONTROLLER_XYPAD

  elseif (metadata.type == "key") then
    msg.input_method = CONTROLLER_KEYBOARD
    msg.context = MIDI_NOTE_MESSAGE
    msg.velocity_enabled = false

  elseif (metadata.type == "keyboard") then
    msg.input_method = CONTROLLER_KEYBOARD
    msg.velocity_enabled = false

  else
    error(("Internal Error. Please report: " .. 
      "unknown metadata.type '%s'"):format(metadata.type or "nil"))
  end

  -- mark as virtual generated message
  msg.is_virtual = true

  msg.device = self.device

  -- send the message
  self.device.message_stream:input_message(msg)
end


--------------------------------------------------------------------------------

---  Walk control-map defition, and create the virtual control surface
-- @param t (Table) the control-map defition
-- @param done (Table) internal calculation table 
-- @param deep (Number/Int) the nesting level

function Display:_walk_table(t, done, deep)

  deep = deep and deep + 1 or 1  --  
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

        local tooltip = nil
        if view_obj.meta.value then
          tooltip = string.format("%s (unassigned)",view_obj.meta.value)
        end

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

        if (view_obj.meta.type == "button" or 
            view_obj.meta.type == "togglebutton" or
            view_obj.meta.type == "pushbutton") then
          
          -- Param:button, togglebutton or pushbutton
          
          -- check if we are sending a note message:
          local context = self.device.control_map:determine_type(view_obj.meta.value)
          
          --[[
          local notifier = function(value) 
            -- output the maximum value
            if (context==MIDI_NOTE_MESSAGE) then
              local pitch = view_obj.meta.index
              local velocity = view_obj.meta.maximum
              self:generate_message({pitch,velocity},view_obj.meta)
            else
              self:generate_message(view_obj.meta.maximum,view_obj.meta)
            end
          end
          self.ui_notifiers[view_obj.meta.id] = notifier
          ]]
          local press_notifier = function(value) 
            -- output the maximum value
            --print("*** Display: press_notifier - (context==MIDI_NOTE_MESSAGE):",(context==MIDI_NOTE_MESSAGE))
            if (context==MIDI_NOTE_MESSAGE) then
              local pitch = view_obj.meta.index
              local velocity = view_obj.meta.maximum
              self:generate_message({pitch,velocity},view_obj.meta)
            else
              self:generate_message(view_obj.meta.maximum,view_obj.meta)
            end

            --self:generate_message(view_obj.meta.maximum,view_obj.meta)
          end
          local release_notifier = function(value) 
            -- output the minimum value
            local released = true
            --print("*** Display: release_notifier - (context==MIDI_NOTE_MESSAGE):",(context==MIDI_NOTE_MESSAGE))
            if (context==MIDI_NOTE_MESSAGE) then
              local pitch = view_obj.meta.index
              local velocity = view_obj.meta.minimum
              self:generate_message({pitch,velocity},view_obj.meta,released)
            else
              self:generate_message(
                view_obj.meta.maximum,view_obj.meta,released)
            end
            --[[
            self:generate_message(
              view_obj.meta.minimum,view_obj.meta,released)
            ]]
          end
            
          view_obj.view = self.vb:button{
            id = view_obj.meta.id,
            width = adj_width,
            height = adj_height,
            tooltip = tooltip,
            pressed = press_notifier,
            released = release_notifier
          }
        elseif (view_obj.meta.type == "key") then

          --- Param:key
          --[[
          local notifier = function(value) 
            -- output the maximum value
            self:generate_message(view_obj.meta.maximum,view_obj.meta)
          end
          self.ui_notifiers[view_obj.meta.id] = notifier
          ]]

          local press_notifier = function(value) 
            local pitch = view_obj.meta.index
            local velocity = view_obj.meta.maximum
            self:generate_message({pitch,velocity},view_obj.meta)
          end
          local release_notifier = function(value) 
            local pitch = view_obj.meta.index
            local velocity = view_obj.meta.minimum
            local released = true
            self:generate_message({pitch,velocity},view_obj.meta,released)
          end

          view_obj.view = self.vb:button{
            id = view_obj.meta.id,
            width = adj_width,
            height = adj_height,
            tooltip = tooltip,
            pressed = press_notifier,
            released = release_notifier
          }
        --[[
        elseif (view_obj.meta.type == "encoder") then
        
          --- Param:encoder

          local notifier = function(value) 
            -- output the current value
            self:generate_message(value,view_obj.meta)
          end
            
            self.ui_notifiers[view_obj.meta.id] = notifier
            view_obj.view = self.vb:minislider{
              id=view_obj.meta.id,
              min = view_obj.meta.minimum,
              max = view_obj.meta.maximum,
              tooltip = tooltip,
              height = UNIT_HEIGHT/1.5,
              width = UNIT_WIDTH,
              notifier = notifier
            }
        ]]
        elseif (view_obj.meta.type == "dial") then
            
          --- Param:dial
          
          local notifier = function(value) 
            -- output the current value
            self:generate_message(value,view_obj.meta)
          end
          
          self.ui_notifiers[view_obj.meta.id] = notifier
          view_obj.view = self.vb:rotary{
            id = view_obj.meta.id,
            min = view_obj.meta.minimum,
            max = view_obj.meta.maximum,
            tooltip = tooltip,
            width = adj_width,
            height = adj_height,
            notifier = notifier
          }
          
        elseif (view_obj.meta.type == "fader") then
            
          --- Param:fader
                    
          local notifier = function(value) 
            self:generate_message(value,view_obj.meta)
          end
            
          self.ui_notifiers[view_obj.meta.id] = notifier

          if (view_obj.meta.orientation == "vertical") then
            adj_width = UNIT_WIDTH * (view_obj.meta.aspect or 1)
            --[[
            view_obj.view = self.vb:row {
              -- padd with spaces to center DEFAULT_CONTROL_HEIGHT in UNIT_WIDTH
              self.vb:space { 
                width = (UNIT_WIDTH -  DEFAULT_CONTROL_HEIGHT) / 2 
              },
              --self.vb:slider{
              self.vb:minislider{
                id = view_obj.meta.id,
                min = view_obj.meta.minimum,
                max = view_obj.meta.maximum,
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
            ]]
          else
            adj_height = UNIT_HEIGHT * (view_obj.meta.aspect or 1)
            --print("adj_height",adj_height)
          end

          --view_obj.view = self.vb:slider {
          view_obj.view = self.vb:minislider {
            id  =view_obj.meta.id,
            min = view_obj.meta.minimum,
            max = view_obj.meta.maximum,
            tooltip = tooltip,
            --width = (UNIT_WIDTH*view_obj.meta.size) + 
            --  (DEFAULT_SPACING*(view_obj.meta.size-1)),
            width = adj_width,
            height = adj_height,
            notifier = notifier
          }

        elseif (view_obj.meta.type == "xypad") then

          --- Param:xypad

          local notifier = function(value) 
            self:generate_message({value.x,value.y},view_obj.meta)
          end

          self.ui_notifiers[view_obj.meta.id] = notifier

          view_obj.view = self.vb:xypad {
            id  =view_obj.meta.id,
            min = {
              x=view_obj.meta.minimum,
              y=view_obj.meta.minimum
            },
            max = {
              x=view_obj.meta.maximum,
              y=view_obj.meta.maximum
            },
            tooltip = tooltip,
            width = adj_width,
            height = adj_height,
            notifier = notifier
          }
        elseif (view_obj.meta.type == "keyboard") then

          --- Param:keyboard

          local keys_color_white = KEYS_COLOR_WHITE
          local keys_color_black = KEYS_COLOR_BLACK
          local keys_width = KEYS_WIDTH
          local keys_height = KEYS_HEIGHT

          if view_obj.meta.size then
            keys_width = keys_width * view_obj.meta.size
            keys_height = keys_height * view_obj.meta.size
          end

          if view_obj.meta.aspect then
            keys_height = keys_height*view_obj.meta.aspect
          end

          -- take a copy of the meta-info, and modify it
          -- so actions are detected as MIDI_NOTE_MESSAGE
          -- (use a bogus note string to make it pass)

          local meta = table.rcopy(view_obj.meta)
          meta.value = BOGUS_NOTE..meta.value

          -- the keyboard parts
          local black_keys = self.vb:row {
            style = "panel",
          }
          local white_keys = self.vb:row {
            style = "border",
          }
          local keyboard = self.vb:column {
            id  = meta.id,
          }

          -- build the keyboard

          for i = 1,meta.range do

            local press_notifier = function(value) 
              local pitch = i-1
              local velocity = meta.maximum
              self:generate_message({pitch,velocity},meta)
            end
            local release_notifier = function(value) 
              local pitch = i-1
              local velocity = meta.minimum
              local released = true
              self:generate_message({pitch,velocity},meta,released)
            end

            if (i%12==1) then
              if (i==1) then
                local scale = (i==1) and 2 or 1
                black_keys:add_child(self.vb:space {
                  width = (keys_width/scale),
                  height = keys_height
                })
              elseif (i==meta.range) then
                black_keys:add_child(self.vb:space {
                  width = keys_width/2,
                  height = keys_height
                })
              end
              white_keys:add_child(self.vb:button {
                id = meta.id.."_"..i,
                width = keys_width,
                height = keys_height,
                color = keys_color_white,
                pressed = press_notifier,
                released = release_notifier,
              })
            elseif (i%12==2) then
              black_keys:add_child(self.vb:button {
                id = meta.id.."_"..i,
                width = keys_width,
                height = keys_height,
                color = keys_color_black,
                pressed = press_notifier,
                released = release_notifier,
              })
            elseif (i%12==3) then
              if (i==meta.range) then
                black_keys:add_child(self.vb:space {
                  width = keys_width/2,
                  height = keys_height
                })
              end
              white_keys:add_child(self.vb:button {
                id = meta.id.."_"..i,
                width = keys_width,
                height = keys_height,
                color = keys_color_white,
                pressed = press_notifier,
                released = release_notifier,
              })
            elseif (i%12==4) then
              black_keys:add_child(self.vb:button {
                id = meta.id.."_"..i,
                width = keys_width,
                height = keys_height,
                color = keys_color_black,
                pressed = press_notifier,
                released = release_notifier,
              })
            elseif (i%12==5) then
              local scale = (i==meta.range) and 2 or 1
              black_keys:add_child(self.vb:space {
                width = keys_width/scale,
                height = keys_height
              })
              white_keys:add_child(self.vb:button {
                id = meta.id.."_"..i,
                width = keys_width,
                height = keys_height,
                color = keys_color_white,
                pressed = press_notifier,
                released = release_notifier,
              })
            elseif (i%12==6) then
              if (i==meta.range) then
                black_keys:add_child(self.vb:space {
                  width = keys_width/2,
                  height = keys_height
                })
              end
              white_keys:add_child(self.vb:button {
                id = meta.id.."_"..i,
                width = keys_width,
                height = keys_height,
                color = keys_color_white,
                pressed = press_notifier,
                released = release_notifier,
              })
            elseif (i%12==7) then
              black_keys:add_child(self.vb:button {
                id = meta.id.."_"..i,
                width = keys_width,
                height = keys_height,
                color = keys_color_black,
                pressed = press_notifier,
                released = release_notifier,
              })
            elseif (i%12==8) then
              if (i==meta.range) then
                black_keys:add_child(self.vb:space {
                  width = keys_width/2,
                  height = keys_height
                })
              end
              white_keys:add_child(self.vb:button {
                id = meta.id.."_"..i,
                width = keys_width,
                height = keys_height,
                color = keys_color_white,
                pressed = press_notifier,
                released = release_notifier,
              })
            elseif (i%12==9) then
              black_keys:add_child(self.vb:button {
                id = meta.id.."_"..i,
                width = keys_width,
                height = keys_height,
                color = keys_color_black,
                pressed = press_notifier,
                released = release_notifier,
              })
            elseif (i%12==10) then
              if (i==meta.range) then
                black_keys:add_child(self.vb:space {
                  width = keys_width/2,
                  height = keys_height
                })
              end
              white_keys:add_child(self.vb:button {
                id = meta.id.."_"..i,
                width = keys_width,
                height = keys_height,
                color = keys_color_white,
                pressed = press_notifier,
                released = release_notifier,
              })
            elseif (i%12==11) then
              black_keys:add_child(self.vb:button {
                id = meta.id.."_"..i,
                width = keys_width,
                height = keys_height,
                color = keys_color_black,
                pressed = press_notifier,
                released = release_notifier,
              })
            elseif (i%12==0) then
              local scale = (i==meta.range) and 2 or 1
              black_keys:add_child(self.vb:space {
                width = keys_width/scale,
                height = keys_height
              })
              white_keys:add_child(self.vb:button {
                id = meta.id.."_"..i,
                width = keys_width,
                height = keys_height,
                color = keys_color_white,
                pressed = press_notifier,
                released = release_notifier,
              })
            end

          end

          -- assemble the parts
          keyboard:add_child(black_keys)
          keyboard:add_child(white_keys)
          view_obj.view = keyboard

        elseif (view_obj.meta.type == "label") then

          --print("*** view_obj.meta.text",view_obj.meta.text)

          local str_text = ""
          if view_obj.meta.text then
            str_text = view_obj.meta.text:gsub("\\n","\n")
          end

          view_obj.view = self.vb:multiline_text{
            id = view_obj.meta.id,
            text = str_text,
            font = (view_obj.meta.font or "normal"),
            width = adj_width,
            height = adj_height,
            tooltip = tooltip,
            --style = "border",
            --align = "center",
            --pressed = press_notifier,
            --released = release_notifier
          }

        end
        
      elseif (t[key].label == "Column") then
    
        --- Column
    
        view_obj.view = self.vb:column{
          spacing = DEFAULT_SPACING
        }
        self._parents[deep] = view_obj
        self._grid_obj = nil
  
      elseif (t[key].label == "Row") then
    
        --- Row
    
        view_obj.view = self.vb:row{
          spacing = DEFAULT_SPACING,
        }
        self._parents[deep] = view_obj
        self._grid_obj = nil
      elseif (t[key].label == "Group") then

        --- Group
    
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

--- Validate/fix groups and try to give the control map author some
-- hints of what might be wrong with the control map
-- @param xargs (Table) the control-map attributes

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

--- Validate/fix parameters and try to give the control map author some
-- hints of what might be wrong with the control map
-- @param xargs (Table) the control-map attributes

function Display:_validate_param(xargs)

  -- common Param properties
  
  -- check value (label does not need this)
  if (xargs.type ~= "label") then
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
  end
    
          
  if (xargs.type == nil or not table.find(CONTROLMAP_TYPES, xargs.type)) then
    renoise.app():show_warning(
      ('Whoops! The controlmap \'%s\' specifies no valid \'type\' property '..
       'in one of its \'Param\' fields.\n\n'..
       'Please use one of: %s'):format(self.device.control_map.file_path, 
       table.concat(CONTROLMAP_TYPES, ", ")))

    xargs.type = "button"
  end
  
  if (xargs.type == "xypad") then

    -- TODO: validate that required attributes exist for XYPad

  elseif (xargs.type == "label") then

    -- for this type of control, no min/max value is required

  else
  
    -- minimum/maximum
    if (xargs.minimum == nil or
        xargs.maximum == nil or 
        xargs.minimum < 0 or 
        xargs.maximum < 0) 
    then
      renoise.app():show_warning(
        ('Whoops! The controlmap \'%s\' specifies no valid \'minimum\' '..
         'or \'maximum\' property in the \'Param\' field named \'%s\'.\n\n'..
         'Please use a number >= 0  (depending on the value, MIDI type).'
        ):format(self.device.control_map.file_path,xargs.name or xargs.value))

      xargs.minimum = 0 
      xargs.maximum = 127
    end

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

