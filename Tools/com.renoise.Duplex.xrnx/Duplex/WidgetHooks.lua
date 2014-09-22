--[[============================================================================
-- Duplex.WidgetHooks
============================================================================]]--

--[[--
Provide hooks for controls in the virtual control surface (native & custom)

### process_subparams()

  Description: 
  when parsing the controlmap, apply widget-specific attributes

  See also @{Duplex.ControlMap._parse_xml}

  Parameters:

  - param
  - subparam

### build()

  Description
  create the actual viewbuilder components, including a notifier method

  See also @{Duplex.Display._walk_table}

  Parameters

  -  display
  -  param

  Return

  -  renoise.Views.View

### validate()
    
  Description: 
  validate/fix parameters and try to give the control map author some hints of what might be wrong with the control map
  
  See also @{Duplex.Display._walk_table}

  Parameters

  -  display
  -  param
  -  cm

### set_subparams()

  Description: 
  handle outgoing messages for parameters that include subparameters 
  
  See also @{Duplex.Display.set_parameter}

  Parameters:

  -  display
  -  param
  -  point
  -  ui_obj

### set_widget()

  Description: 
  update the widget in the virtual control surface - define this when the widget needs a more complex display-update (for example, a button is more complex than a slider) 
  
  See also @{Duplex.Display.set_parameter}

  Parameters:

  -  display
  -  widget
  -  param
  -  ui_obj
  -  point
  -  value

### on_receive()

  Description: 
  do something clever when an incoming message arrives
  
  See also @{Duplex.OscDevice.receive_osc_message}

  -  device
  -  param
  -  msg
  -  regex

### on_send()

  Description: 
  perform last-minute changes before transmitting to hardware



--]]

--==============================================================================


-------------------------------------------------------------------------------

widget_hooks = {}

-- in case we've added custom widget, they are registered here
-- (for example, the keyboard is a custom widget)
widget_hooks._custom_widgets = {}

--[[
widget_hooks._mt = {

  __index = function(t,key) 
    if (t._get and type(t._get[key]) == "function") then 
      return t._get[key](t)
    elseif t._props and (type(t._props[key]) ~= "nil") then
      return rawget(t._props,key)
    else
      rawget(t,key)      
    end
  end,
  
  __newindex = function(t,key,val)
    if (t._set and type(t._set[key]) == "function") then
      t._set[key](t,val)
    elseif t._props and (t._props[key]) then
      t._props[key] = val
    else
      rawset(t,key,val)
    end
  end,      
}
]]

-------------------------------------------------------------------------------

widget_hooks.generic_type = {
  
  validate = function(...)

    local display,param,cm = select(1,...)

    if (param.xarg.type == nil or not table.find(table.values(INPUT_TYPE), param.xarg.type)) then
      renoise.app():show_warning(
        ('Whoops! The controlmap \'%s\' specifies no valid \'type\' property '..
         'in one of its \'Param\' fields.\n\n'..
         'Please use one of: %s'):format(cm.file_path, 
         table.concat(table.values(INPUT_TYPE),", ")))
    end

    if param.xarg.mode and (not table.find(table.values(PARAM_MODE), param.xarg.mode)) then
      renoise.app():show_warning(
        ('Whoops! The controlmap \'%s\' specifies an invalid \'mode\' property '..
         'in one of its \'Param\' fields.\n\n'..
         'Please use one of: %s'):format(cm.file_path, 
         table.concat(table.values(PARAM_MODE),", ")))
    end

    if param.xarg.class and (not rawget(_G, param.xarg.class)) then
      renoise.app():show_warning(
        ('Whoops! The controlmap \'%s\' specifies an invalid \'class\' property '..
         'in one of its \'Param\' fields.\n\n'..
         '(the specified class \'%s\' does not exist)'):format(cm.file_path,param.xarg.class))
    end

    -- minimum/maximum

    if (display.device.protocol == DEVICE_PROTOCOL.OSC) then
      if (param.xarg.minimum == nil or
        param.xarg.maximum == nil)
      then
        renoise.app():show_warning(
          ('Whoops! The controlmap \'%s\' needs to specify a \'minimum\' '..
           'and \'maximum\' property (using fallback range 0-1).'
          ):format(cm.file_path,param.xarg.name or param.xarg.value))
        param.xarg.minimum = 0 
        param.xarg.maximum = 1
      end
    end
    if (display.device.protocol == DEVICE_PROTOCOL.MIDI) then
      if (param.xarg.minimum == nil or
          param.xarg.maximum == nil or 
          param.xarg.minimum < 0 or 
          param.xarg.maximum < 0) 
      then
        --print("cm.file_path, param.xarg.name, param.xarg.value",cm.file_path,param.xarg.name,param.xarg.value)
        renoise.app():show_warning(
          ('Whoops! The controlmap \'%s\' specifies no valid \'minimum\' '..
           'or \'maximum\' property in the \'Param\' field named \'%s\'.\n\n'..
           'Please use a number >= 0  (using fallback range 0-127).'
          ):format(cm.file_path,param.xarg.name or param.xarg.value))
        param.xarg.minimum = 0 
        param.xarg.maximum = 127
      end
    end

  end,

}


-------------------------------------------------------------------------------
-- function - fader widget 
-------------------------------------------------------------------------------

widget_hooks.fader = {

  build = function(...)

    local display,param,adj_width,adj_height,tooltip = select(1,...)

    local notifier = function(value) 
      display:generate_message(value,param)
    end
      
    display.ui_notifiers[param.xarg.id] = notifier

    if (param.xarg.orientation == "vertical") then
      adj_width = Display.UNIT_WIDTH * (param.xarg.aspect or 1)
    else
      adj_height = Display.UNIT_HEIGHT * (param.xarg.aspect or 1)
    end

    --print("param.xarg.id",param.xarg.id)

    return display.vb:minislider {
      id  = param.xarg.id,
      min = param.xarg.minimum,
      max = param.xarg.maximum,
      tooltip = tooltip,
      width = adj_width,
      height = adj_height,
      notifier = notifier
    }

  end,

  validate = function(...)

    widget_hooks.generic_type.validate(...)

    local display,param,cm = select(1,...)

    -- orientation
    if (param.xarg.orientation ~= "vertical" and 
        param.xarg.orientation ~= "horizontal") 
    then
      renoise.app():show_warning(
        ('Whoops! The controlmap \'%s\' specifies no valid \'orientation\' '..
         'property in one of its fader \'Params\'.\n\n'..
         'Please use either orientation="horizontal" or orientation="vertical".'
        ):format(cm.file_path))
  
      param.xarg.orientation = "horizontal"
    end

    -- size
    if (type(param.xarg.size) == "nil") then
      renoise.app():show_warning(
        ('Whoops! The controlmap \'%s\' specifies no valid \'size\' '..
         'property in one of its fader \'Params\'.\n\n'..
         'Please use a number >= 1 as size".'
        ):format(cm.file_path))
  
      param.xarg.size = 1
    end  


  end,

  on_receive = function(...)
    TRACE("widget_hooks.fader.on_receive()")

    local device,param,msg,regex = select(1,...)

    -- invert/swap min/max values?
    if (type(msg.value) == "number") and (msg.xarg.invert) then
      msg.value = (msg.xarg.maximum-msg.value)+msg.xarg.minimum
    end

  end,

}

-------------------------------------------------------------------------------
-- function - dial widget 
-------------------------------------------------------------------------------

widget_hooks.dial = {

  build = function(...)

    local display,param,adj_width,adj_height,tooltip = select(1,...)

    local notifier = function(value) 
      -- output the current value
      display:generate_message(value,param)
    end
    
    display.ui_notifiers[param.xarg.id] = notifier

    return display.vb:rotary{
      id = param.xarg.id,
      min = param.xarg.minimum,
      max = param.xarg.maximum,
      tooltip = tooltip,
      width = adj_width,
      height = adj_height,
      notifier = notifier
    }

  end,
  
  validate = function(...)

    widget_hooks.generic_type.validate(...)

  end,

  on_receive = function(...)
    TRACE("widget_hooks.dial.on_receive()")

    local device,param,msg,regex = select(1,...)

    -- invert/swap min/max values?
    if (type(msg.value) == "number") and (msg.xarg.invert) then
      msg.value = (msg.xarg.maximum-msg.value)+msg.xarg.minimum
    end

  end,

}

-------------------------------------------------------------------------------
-- function - button widget 
-------------------------------------------------------------------------------

widget_hooks.button = {

  build = function(...)

    local display,param,adj_width,adj_height,tooltip = select(1,...)

    -- check if we are sending a note message:
    local context = display.device.control_map:determine_type(param.xarg.value)
    

    local press_notifier = function(value) 
      --print("*** Display: press_notifier - (context==DEVICE_MESSAGE.MIDI_NOTE):",(context==DEVICE_MESSAGE.MIDI_NOTE))
      if (context==DEVICE_MESSAGE.MIDI_NOTE) then
        local pitch = param.xarg.index
        local velocity = param.xarg.maximum
        display:generate_message({pitch,velocity},param)
      else
        -- output @match or @maximum
        display:generate_message(param.xarg.match or param.xarg.maximum,param)
      end
    end


    local release_notifier = function(value) 
      local released = true
      --print("*** Display: release_notifier - (context==DEVICE_MESSAGE.MIDI_NOTE):",(context==DEVICE_MESSAGE.MIDI_NOTE))
      if (context==DEVICE_MESSAGE.MIDI_NOTE) then
        local pitch = param.xarg.index
        local velocity = param.xarg.minimum
        display:generate_message({pitch,velocity},param,released)
      else

        -- don't output when togglebutton
        -- (the hardware version only fires when pressed)
        if param.xarg.type == "togglebutton" then
          return
        end

        -- don't output when "match" is defined
        -- (would fire the same value when pressed/released, not useful)
        if param.xarg.match then
          return
        end

        display:generate_message(param.xarg.minimum,param,released)

      end
    end
      
    return display.vb:button{
      id = param.xarg.id,
      width = adj_width,
      height = adj_height,
      text = param.xarg.text,
      tooltip = tooltip,
      pressed = press_notifier,
      released = release_notifier
    }

  end,

  validate = function(...)

    widget_hooks.generic_type.validate(...)

  end,

  set_widget = function(...)

    local display,widget,xarg,ui_obj,point,value = select(1,...)
    --print("*** widget_hooks.button.set_widget")

    local c_space = xarg.colorspace or display.device.colorspace
    if not is_monochrome(c_space) then
      widget.color = display.device:quantize_color(point.color,c_space)
      --print("not is_monochrome",widget.color[1],widget.color[2],widget.color[3])
    else
      if (point.val==false) then
        widget.color = {0x00,0x00,0x00}
        --print("point.val == false")
      else
        local color = nil
        if table_has_equal_values(c_space) then
          -- monochrome & lit, use theme color
          color = {
            duplex_preferences.theme_color[1].value,
            duplex_preferences.theme_color[2].value,
            duplex_preferences.theme_color[3].value,
          }
        else
          -- tinted & lit, use colorspace
          color = {c_space[1]*255,c_space[2]*255,c_space[3]*255}
        end
        widget.color = color
        --print("button set to color",rprint(color))
      end
    end
    widget.text = point.text

  end,

}

-- function - togglebutton widget 

widget_hooks.togglebutton = {

  build = widget_hooks.button.build,
  validate = widget_hooks.button.validate,

}

-- function - pushbutton widget 

widget_hooks.pushbutton = {

  build = widget_hooks.button.build,
  validate = widget_hooks.button.validate,

}

-------------------------------------------------------------------------------
-- function - xypad widget 
-------------------------------------------------------------------------------

widget_hooks.xypad = {


  process_subparams = function(...)

    local param,subparam = select(1,...)
    
    subparam.xarg.type  =  "fader"
    if (subparam.xarg.field == "x") then
      subparam.xarg.orientation = "horizontal"
      subparam.xarg.invert = 
        (param.xarg.invert_x) and true or false
    elseif (subparam.xarg.field == "y") then
      subparam.xarg.orientation = "vertical"
      subparam.xarg.invert = 
        (param.xarg.invert_y) and true or false
    end

    --print("...done processsing")

  end,

  set_subparams = function(...)

    local display,param,point,ui_obj = select(1,...)

    -- send the original value from the UIPad as separate messages
    for _,subparam in ipairs(param) do
      if (subparam.xarg.field == "x") then
        local point_x = CanvasPoint(point.text,point.color)
        point_x.val = ui_obj.value[1]
        display:set_parameter(subparam, ui_obj, point_x,true)
      elseif (subparam.xarg.field == "y") then
        local point_y = CanvasPoint(point.text,point.color)
        point_y.val = ui_obj.value[2]
        display:set_parameter(subparam, ui_obj, point_y,true)
      end
    end

  end,

  build = function(...)

    local display,param,adj_width,adj_height,tooltip = select(1,...)

    local minimum_x = param.xarg.minimum
    local minimum_y = param.xarg.minimum
    local maximum_x = param.xarg.maximum
    local maximum_y = param.xarg.maximum

    --print("*** widget_hooks.xypad param,param.xarg",param,param.xarg)
    --print("minimum_x,minimum_y",minimum_x,minimum_y)
    --print("maximum_x,maximum_y",maximum_x,maximum_y)

    local center_x = minimum_x + ((maximum_x-minimum_x)/2)
    local center_y = minimum_y + ((maximum_y-minimum_y)/2)

    local notifier = nil

    --print("*** view_obj...")
    --rprint(view_obj)


    if (#param == 2) then

      -- separate X/Y axis defined as <SubParam>
      -- "MIDI-implementation"

      local axis_x,axis_y = nil,nil
      for k,subparam in ipairs(param) do
        if (subparam.xarg.field == "x") then
          axis_x = subparam
        elseif (subparam.xarg.field == "y") then
          axis_y = subparam
        end
      end

      notifier = function(value) 

        --print("*** widget_hooks.xypad - MIDI notifier...")
        --rprint(value)
        display:generate_message(value.x,axis_x)
        display:generate_message(value.y,axis_y)

      end

    else
      -- single <Param> node with two values 
      -- "OSC-implementation"

      notifier = function(value) 

        --print("*** widget_hooks.xypad - OSC notifier...")
        --rprint(value)
        display:generate_message({value.x,value.y},param)

      end

    end

    display.ui_notifiers[param.xarg.id] = notifier

    return display.vb:xypad {
      id  =param.xarg.id,
      min = {
        x=minimum_x,
        y=minimum_y
      },
      max = {
        x=maximum_x,
        y=maximum_y
      },
      value = {
        x = center_x,
        y = center_y
      },
      tooltip = tooltip,
      width = adj_width,
      height = adj_height,
      notifier = notifier
    }



  end,

  validate = function(...)

    --local display,param,cm = select(1,...)

  end,

  on_receive = function(...)
    TRACE("widget_hooks.xypad.on_receive()")

    local device,param,msg,regex = select(1,...)

    if (type(msg.value) == "table") then
      if (msg.xarg.invert_x) then 
        msg.value[1] = (msg.xarg.maximum-msg.value[1])+msg.xarg.minimum
      end
      if (msg.xarg.invert_y) then
        msg.value[2] = (msg.xarg.maximum-msg.value[2])+msg.xarg.minimum
      end
      if (msg.xarg.swap_axes) then
        msg.value[1],msg.value[2] = msg.value[2],msg.value[1]
      end
    end

  end,

  on_send = function(...)
    --TRACE("widget_hooks.xypad.on_send()")

    local display,param,ui_obj,point,value = select(1,...)
    --print("widget_hooks.xypad.on_send",rprint(value))

    if (type(value) == "table") then
      if (param.xarg.invert_x) then 
        value[1] = (param.xarg.maximum-value[1])+param.xarg.minimum
      end
      if (param.xarg.invert_y) then
        value[2] = (param.xarg.maximum-value[2])+param.xarg.minimum
      end
      if (param.xarg.swap_axes) then
        value[1],value[2] = value[2],value[1]
        --print("swapping axes...",rprint(value))
      end
    end

  end,

  

}

-------------------------------------------------------------------------------
-- function - label widget 
-------------------------------------------------------------------------------

widget_hooks.label = {

  build = function(...)

    local display,param,adj_width,adj_height,tooltip = select(1,...)

    --print("*** display,param",display,param)

    local str_text = ""
    if param.xarg.text then
      str_text = param.xarg.text:gsub("\\n","\n")
    end

    return display.vb:multiline_text{
      id = param.xarg.id,
      text = str_text,
      font = (param.xarg.font or "normal"),
      width = adj_width,
      height = adj_height,
      tooltip = tooltip,
    }

  end,

  validate = function(...)

    local display,param,cm = select(1,...)

    -- check for required value (labels don't need values, and neither does a 
    -- <Param> node that contain subparameters...
    if (param.xarg.type ~= "label") and 
      (not param.xarg.has_subparams)
    then
      if (param.xarg.value == nil or 
          cm:determine_type(param.xarg.value) == nil)
      then
        renoise.app():show_warning(
          ('Whoops! The controlmap \'%s\' specifies no or an invalid \'value\' '..
           'property in one of its \'Param\' fields: %s.\n\n'..
           'You have to map a control to a MIDI message via the name property, '..
           'i.e: value="CC#10" (control change number 10, any channel) or PB|1 '..
           '(pitchbend on channel 1).'):format(
           cm.file_path, param.xarg.value or "")
        )
      
      end
    end

  end,

}

-------------------------------------------------------------------------------
-- function - key widget 
-------------------------------------------------------------------------------
--[[
widget_hooks.key = {

  build = function(...)

    local display,param,adj_width,adj_height,tooltip = select(1,...)

    local press_notifier = function(value) 
      local pitch = param.xarg.index
      local velocity = param.xarg.maximum
      display:generate_message({pitch,velocity},param)
    end
    local release_notifier = function(value) 
      local pitch = param.xarg.index
      local velocity = param.xarg.minimum
      display:generate_message({pitch,velocity},param,true)
    end

    return display.vb:button{
      id = param.xarg.id,
      width = adj_width,
      height = adj_height,
      tooltip = tooltip,
      pressed = press_notifier,
      released = release_notifier
    }

  end,

  validate = function(...)

    --local display,param,cm = select(1,...)

  end,

}
]]

-------------------------------------------------------------------------------
-- function - keyboard widget 
-------------------------------------------------------------------------------

widget_hooks.keyboard = {

  build = function(...)

    --local display,param,adj_width,adj_height,tooltip = select(1,...)
    local kb = WidgetKeyboard(...)
    --print("*** kb.param",rprint(kb.param))
    widget_hooks._custom_widgets[kb.param.xarg.id] = kb
    return kb:build()

  end,

  validate = function(...)

    local display,param,cm = select(1,...)

    if (param.xarg.range == nil) then
      renoise.app():show_warning(
        ('Whoops! The controlmap \'%s\' needs to specify a \'range\''..
         'for a parameter of type="keyboard"'):format(cm.file_path))
    end

  end,

  --[[
  set_widget = function(...)
    --print("widget_hooks.keyboard.set_widget()")

    local display,widget,xarg,ui_obj,point,value = select(1,...)

  end,
  ]]

  on_receive = function(...)
    TRACE("widget_hooks.keyboard.on_receive()")

    local device,param,msg,regex = select(1,...)

    -- when using a keyboard in OSC mode, we don't receive MIDI messages
    -- but rather, have to go through our keyboard widget to figure this out

    if not msg.midi_msg and regex then
      
      -- generate note by looking at the last wildcard index 
      -- (OSC keyboard whose pattern look like this: `/key1`, `/key2` etc.,
      -- which we then match using a wildcard pattern like `/key*`)
      
      local kb_widget = widget_hooks._custom_widgets[param.xarg.id]
      if kb_widget then

        --print("widget_hooks.keyboard.on_receive - regex",rprint(regex))
  
        for k,v in ripairs(regex) do
          local val = tonumber(v.chars)-1
          --print("val",val)
          if (type(val) == "number") then
            msg.midi_msg = kb_widget:index_to_midi_msg(val)
            --print("msg.midi_msg",msg.midi_msg)
            return
          end
        end

      end


    end

  end

}
 
--setmetatable(widget_hooks.keyboard, widget_hooks._mt)

