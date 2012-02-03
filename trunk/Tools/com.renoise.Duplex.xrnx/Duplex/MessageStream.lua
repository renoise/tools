--[[----------------------------------------------------------------------------
-- Duplex.MessageStream and Message
----------------------------------------------------------------------------]]--

--[[

Requires: Globals

--]]


--==============================================================================

--[[

About

The MessageStream recieves messages from connected devices and the virtual 
control surface. After the type of event has been determined, the resulting 
Message is then directed towards relevant UIComponent event-listeners, such as  
DEVICE_EVENT_BUTTON_PRESSED. 
A device can only belong to a single stream, but nothing stops the stream from 
recieving it's input from several devices.  

Features
* detect standard press/release events
* detect that a button was held for specified amount of time 


--]]

class 'MessageStream' 

function MessageStream:__init()
  TRACE('MessageStream:__init')

  -- for faders,dials
  self.change_listeners = table.create()

  -- for buttons
  self.press_listeners = table.create()
  self.hold_listeners = table.create()
  self.release_listeners = table.create()

  -- for keys
  self.key_press_listeners = table.create() 
  self.key_hold_listeners = table.create()
  self.key_release_listeners = table.create()
  self.pitch_change_listeners = table.create()
  self.channel_pressure_listeners = table.create()

  --self.button_hold_time = 1 -- seconds
  self.button_hold_time = self:_get_button_hold_time()

  -- most recent message (event handlers check this)
  self.current_message = nil 

  -- [Message,...] temporarily exclude from interpretation
  self.ignored_buttons = nil 

  -- [Message,...] - currently pressed buttons, in order of arrival
  self.pressed_buttons = table.create() 
end

--------------------------------------------------------------------------------

function MessageStream:_get_button_hold_time()
  return duplex_preferences.button_hold_time
end

--------------------------------------------------------------------------------

-- on_idle() : check if buttons have been pressed for some time 

function MessageStream:on_idle()
  --TRACE("MessageStream:on_idle()")

  for i,msg in ipairs(self.pressed_buttons) do
    if (not msg.held_event_fired) and
      (msg.input_method == CONTROLLER_BUTTON or
       msg.input_method == CONTROLLER_PUSHBUTTON) and
       (msg.timestamp + self.button_hold_time < os.clock()) then
      -- broadcast to attached listeners
      for _,listener in ipairs(self.hold_listeners)  do 
        listener.handler(msg) 
      end
      msg.held_event_fired = true
    end
  end
end


--------------------------------------------------------------------------------

-- add event listener 
-- @param obj (UIComponent)
-- @param evt_type (DEVICE_EVENT_[...])
-- @param handler (function)

function MessageStream:add_listener(obj,evt_type,handler)
  TRACE('MessageStream:add_listener:'..evt_type)
  
  if (evt_type == DEVICE_EVENT_BUTTON_PRESSED) then
    self.press_listeners:insert({ handler = handler, obj = obj })
    TRACE("MessageStream:onpress handler added")

  elseif (evt_type == DEVICE_EVENT_VALUE_CHANGED) then
    self.change_listeners:insert({ handler = handler, obj = obj })
    TRACE("MessageStream:onchange handler added")

  elseif (evt_type == DEVICE_EVENT_BUTTON_HELD) then
    self.hold_listeners:insert({ handler = handler, obj = obj })
    TRACE("MessageStream:hold handler added")
    
  elseif (evt_type == DEVICE_EVENT_BUTTON_RELEASED) then
    self.release_listeners:insert({ handler = handler, obj = obj })
    TRACE("MessageStream:onrelease handler added")
  
  elseif (evt_type == DEVICE_EVENT_KEY_PRESSED) then
    self.key_press_listeners:insert({ handler = handler, obj = obj })
    TRACE("MessageStream:DEVICE_EVENT_KEY_PRESSED")

  elseif (evt_type == DEVICE_EVENT_KEY_HELD) then
    self.key_hold_listeners:insert({ handler = handler, obj = obj })
    TRACE("MessageStream:DEVICE_EVENT_KEY_HELD")
    
  elseif (evt_type == DEVICE_EVENT_KEY_RELEASED) then
    self.key_release_listeners:insert({ handler = handler, obj = obj })
    TRACE("MessageStream:DEVICE_EVENT_KEY_RELEASED")
  
  elseif (evt_type == DEVICE_EVENT_PITCH_CHANGED) then
    self.pitch_change_listeners:insert({ handler = handler, obj = obj })
    TRACE("MessageStream:DEVICE_EVENT_PITCH_CHANGED")
  
  elseif (evt_type == DEVICE_EVENT_CHANNEL_PRESSURE) then
    self.channel_pressure_listeners:insert({ handler = handler, obj = obj })
    TRACE("MessageStream:DEVICE_EVENT_CHANNEL_PRESSURE")
  
  else
    error(("Internal Error. Please report: " ..
      "unknown evt_type '%s'"):format(tostring(evt_type) or "nil"))
  end

  TRACE("MessageStream:Number of listeners after addition:",#self.press_listeners, #self.change_listeners, #self.hold_listeners, #self.release_listeners, #self.key_press_listeners, #self.key_hold_listeners, #self.key_release_listeners, #self.pitch_change_listeners, #self.channel_pressure_listeners)
end


--------------------------------------------------------------------------------

-- remove event listener
-- @return (boolean) true if successfull. false if not

function MessageStream:remove_listener(obj,evt_type)
  TRACE("MessageStream:remove_listener:",obj,evt_type)

  if (evt_type == DEVICE_EVENT_BUTTON_PRESSED) then
    for i,listener in ipairs(self.press_listeners) do
      if (obj == listener.obj) then
        self.press_listeners:remove(i)
        return true
      end
    end

  elseif (evt_type == DEVICE_EVENT_VALUE_CHANGED) then
    for i,listener in ipairs(self.change_listeners) do
      if (obj == listener.obj) then
        self.change_listeners:remove(i)
        return true
      end
    end

  elseif (evt_type == DEVICE_EVENT_BUTTON_HELD) then
    for i,listener in ipairs(self.hold_listeners) do
      if (obj == listener.obj) then
        self.hold_listeners:remove(i)
        return true
      end
    end 
    
  elseif (evt_type == DEVICE_EVENT_BUTTON_RELEASED) then
    for i,listener in ipairs(self.release_listeners) do
      if (obj == listener.obj) then
        self.release_listeners:remove(i)
        return true
      end
    end 

  elseif (evt_type == DEVICE_EVENT_KEY_RELEASED) then
    for i,listener in ipairs(self.key_release_listeners) do
      if (obj == listener.obj) then
        self.key_release_listeners:remove(i)
        return true
      end
    end 

  elseif (evt_type == DEVICE_EVENT_KEY_HELD) then
    for i,listener in ipairs(self.key_hold_listeners) do
      if (obj == listener.obj) then
        self.key_hold_listeners:remove(i)
        return true
      end
    end 

  elseif (evt_type == DEVICE_EVENT_KEY_PRESSED) then
    for i,listener in ipairs(self.key_press_listeners) do
      if (obj == listener.obj) then
        self.key_press_listeners:remove(i)
        return true
      end
    end 

  elseif (evt_type == DEVICE_EVENT_PITCH_CHANGED) then
    for i,listener in ipairs(self.pitch_change_listeners) do
      if (obj == listener.obj) then
        self.pitch_change_listeners:remove(i)
        return true
      end
    end 

  elseif (evt_type == DEVICE_EVENT_CHANNEL_PRESSURE) then
    for i,listener in ipairs(self.channel_pressure_listeners) do
      if (obj == listener.obj) then
        self.channel_pressure_listeners:remove(i)
        return true
      end
    end 

  else
     error(("Internal Error. Please report: " .. 
      "unknown evt_type '%s'"):format(tostring(evt_type) or "nil"))
  end
    
  return false
end


--------------------------------------------------------------------------------

function MessageStream:input_message(msg)
  TRACE('MessageStream:input_message(',msg,')')

  --[[
  print("*** MessageStream: msg.input_method",msg.input_method)
  print("*** MessageStream: msg.context",msg.context)
  print("*** MessageStream: msg.group_name",msg.group_name)
  print("*** MessageStream: msg.is_note_off",msg.is_note_off)
  print("*** MessageStream: msg.index",msg.index)
  print("*** MessageStream: msg.row",msg.row)
  print("*** MessageStream: msg.column",msg.column)
  rprint(msg.value)
  rprint(msg)
  ]]

  self.current_message = msg

  if (msg.context == MIDI_CHANNEL_PRESSURE) then
    --print("*** MessageStream: CONTROLLER_KEYBOARD + MIDI_CHANNEL_PRESSURE")
    for _,listener in ipairs(self.channel_pressure_listeners) do 
      listener.handler(msg) 
    end

  elseif (msg.context == MIDI_PITCH_BEND_MESSAGE) then
    --print("*** MessageStream: CONTROLLER_KEYBOARD + MIDI_PITCH_BEND_MESSAGE")
    for _,listener in ipairs(self.pitch_change_listeners) do 
      listener.handler(msg) 
    end

  elseif (msg.input_method == CONTROLLER_FADER or 
      msg.input_method == CONTROLLER_DIAL or
      msg.input_method == CONTROLLER_XYPAD) then

    if (msg.context == MIDI_NOTE_MESSAGE) then
      --print("*** MessageStream: CONTROLLER_FADER/DIAL/XYPAD + MIDI_NOTE_MESSAGE")
      if (msg.context == MIDI_NOTE_MESSAGE) and (msg.is_note_off) then
        return
      end

    end

    -- "analogue" input, value between max/min

    for _,listener in ipairs(self.change_listeners)  do 
      listener.handler(msg) 
    end

    if (msg.context == MIDI_PITCH_BEND_MESSAGE) then
      --print("MessageStream: CONTROLLER_FADER/DIAL/XYPAD + MIDI_PITCH_BEND_MESSAGE")
      for _,listener in ipairs(self.pitch_change_listeners) do 
        listener.handler(msg) 
      end
    end

  elseif (msg.input_method == CONTROLLER_KEYBOARD) then

    --print("*** MessageStream: msg.context == CONTROLLER_KEYBOARD")

    if (msg.context == MIDI_NOTE_MESSAGE) then
      --print("*** MessageStream: CONTROLLER_KEYBOARD + MIDI_NOTE_MESSAGE")
      if (msg.value[2] == msg.min) or (msg.is_note_off) then
        -- interpret this as release
        for _,listener in ipairs(self.key_release_listeners) do 
          listener.handler(msg) 
        end

      else
        -- interpret this as pressed
        --print("*** MessageStream: interpret this as pressed")
        for _,listener in ipairs(self.key_press_listeners) do 
          listener.handler(msg) 
        end

      end
--[[
    elseif (msg.context == MIDI_PITCH_BEND_MESSAGE) then
      --print("*** MessageStream: CONTROLLER_KEYBOARD + MIDI_PITCH_BEND_MESSAGE")
      for _,listener in ipairs(self.pitch_change_listeners) do 
        listener.handler(msg) 
      end

    elseif (msg.context == MIDI_CHANNEL_PRESSURE) then
      print("*** MessageStream: CONTROLLER_KEYBOARD + MIDI_CHANNEL_PRESSURE")
      for _,listener in ipairs(self.channel_pressure_listeners) do 
        listener.handler(msg) 
      end

    elseif (msg.context == OSC_MESSAGE) then

      --print("*** MessageStream: CONTROLLER_KEYBOARD + OSC_MESSAGE")
]]
    end


  elseif (msg.input_method == CONTROLLER_BUTTON or 
      msg.input_method == CONTROLLER_TOGGLEBUTTON or
      msg.input_method == CONTROLLER_PUSHBUTTON) 
    then

    --  "binary" input, value either max or min 
    --print("*** MessageStream: binary input")

    -- special case: note-on will be "maximixed" (as it has 
    -- a variable value, and would otherwise not be able to
    -- trigger buttons)
    if (msg.context == MIDI_NOTE_MESSAGE) and (not msg.is_note_off) then
      msg.value = msg.max
    end

    if (msg.value == msg.max) and (not msg.is_note_off) then
      -- interpret this as pressed
      self.pressed_buttons:insert(msg)
      -- broadcast to listeners
      for _,listener in ipairs(self.press_listeners) do 
        listener.handler(msg) 
      end

    elseif (msg.value == msg.min) or (msg.is_note_off) then
      -- interpret this as release

      -- for toggle/push buttons, broadcast releases to listeners as well
      if (not msg.is_virtual) and
        (msg.input_method == CONTROLLER_TOGGLEBUTTON) then
        for _,listener in ipairs(self.press_listeners) do 
          listener.handler(msg) 
        end
      else
        for _,listener in ipairs(self.release_listeners) do 
          listener.handler(msg) 
        end
      end
      
      -- remove from pressed_buttons
      for i,button_msg in ipairs(self.pressed_buttons) do
        if (msg.id == button_msg.id) then
          self.pressed_buttons:remove(i)
        end
      end

    end
  else
    error(("Internal Error. Please report: " ..
      "unknown msg.input_method '%s'"):format(msg.input_method or "nil"))
  end
end


--==============================================================================

--[[

The Message class is a container for messages, closely related to the ControlMap
? use meta-table methods to control "undefined" values ?

--]]


class 'Message' 

function Message:__init(device)
  TRACE('Message:__init')

  -- the context indicates the "type" of message
  -- (set to one of the "Message type" properties defined in Globals.lua,
  -- such as MIDI_CC_MESSAGE or OSC_MESSAGE)
  self.context = nil

  -- true, when the message was NOT received from devices (MIDI or OSC) but 
  -- from the virtual UI components or other MessageStream clients
  self.is_virtual = nil
  
  -- the is the actual value for the chosen parameter
  -- (not to be confused with the control-map value)
  self.value = nil

  -- MIDI only, the channel of the message (1-16)
  self.channel = nil 

  -- MIDI only, to distinguish between NOTE-ON and NOTE-OFF events
  self.is_note_off = false

  -- MIDI only, tell if we are dealing with a disguised OSC message
  self.is_osc_msg = false

  -- whether or not a "key/keyboard" is pressure sensitive
  self.velocity_enabled = true

  self.id = nil --  unique ViewBuilder id for each parameter
  self.group_name = nil --  name of the parent group 
  self.index = nil --  (int) index within control-map group, starting from 1
  self.column = nil --  (int) column, starting from 1
  self.row = nil --  (int) row, starting from 1
  self.timestamp = nil --  set by os.clock() 
  self.name = nil --  the parameter name
  
  --  min/max values for every type of control
  self.max = nil  
  self.min = nil
  -- the input method type - CONTROLLER_BUTTON/DIAL/etc. 
  self.input_method = nil 

  -- true once the button is held for a while
  self.held_event_fired = false
end


--------------------------------------------------------------------------------

function Message:__tostring()
  return string.format("message: context:%s, group_name:%s, value:%s",
    tostring(self.context), tostring(self.group_name),self.value)
end
