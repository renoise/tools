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

  self.change_listeners = table.create() -- for faders,dials
  self.press_listeners = table.create() -- for buttons
  self.hold_listeners = table.create()  -- buttons
  self.release_listeners = table.create()  -- buttons

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
        listener.handler() 
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
  
  else
    error(("Internal Error. Please report: " ..
      "unknown evt_type '%s'"):format(tostring(evt_type) or "nil"))
  end

  TRACE("MessageStream:Number of listeners after addition:",
     #self.press_listeners, #self.change_listeners, #self.hold_listeners, #self.release_listeners)
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
 
  else
     error(("Internal Error. Please report: " .. 
      "unknown evt_type '%s'"):format(tostring(evt_type) or "nil"))
  end
    
  return false
end


--------------------------------------------------------------------------------

function MessageStream:input_message(msg)
  TRACE('MessageStream:input_message(',msg,')')


  self.current_message = msg

  if (msg.input_method == CONTROLLER_FADER or 
      msg.input_method == CONTROLLER_DIAL) then

      -- "analogue" input, value between max/min
    
    for _,listener in ipairs(self.change_listeners)  do 
      listener.handler() 
    end
  
  elseif (msg.input_method == CONTROLLER_BUTTON or 
          msg.input_method == CONTROLLER_TOGGLEBUTTON or
          msg.input_method == CONTROLLER_PUSHBUTTON) then

    --  "binary" input, value either max or min 

    if (msg.value == msg.max) and (not msg.is_note_off) then
      -- interpret this as pressed
      self.pressed_buttons:insert(msg)
      -- broadcast to listeners
      for _,listener in ipairs(self.press_listeners) do 
        listener.handler() 
      end

    elseif (msg.value == msg.min) or (msg.is_note_off) then
      -- interpret this as release

      -- for toggle/push buttons, broadcast releases to listeners as well
      if (not msg.is_virtual) and
        (msg.input_method == CONTROLLER_TOGGLEBUTTON) then
        for _,listener in ipairs(self.press_listeners) do 
          listener.handler() 
        end
      else
        for _,listener in ipairs(self.release_listeners) do 
          listener.handler() 
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

  -- the context indicate the "type" of message
  -- (set to one of the "Message type" properties defined in Globals.lua,
  -- such as MIDI_CC_MESSAGE or OSC_MESSAGE)
  self.context = nil

  -- true, when the message was NOT received from devices (MIDI or OSC) but 
  -- from the virtual UI components or other MessageStream clients
  self.is_virtual = nil
  
  -- the is the actual value for the chosen parameter
  -- (not to be confused with the control-map value)
  -- TODO: support multiple values, to allow control of XY pads etc.
  self.value = nil

  -- MIDI only, the channel of the message (1-16)
  self.channel = nil 

  -- MIDI only, to distinguish between NOTE-ON and NOTE-OFF events
  self.is_note_off = false

  self.id = nil --  unique id for each parameter
  self.group_name = nil --  name of the parent group 
  self.index = nil --  (int) index within control-map group, starting from 1
  self.column = nil --  (int) column, starting from 1
  self.row = nil --  (int) row, starting from 1
  self.timestamp = nil --  set by os.clock() 
  self.name = nil --  the parameter name
  self.max = nil --  maximum accepted/output value
  self.min = nil --  minimum accepted/output value
  
  -- the input method type - CONTROLLER_BUTTON/DIAL/etc. 
  self.input_method = nil 

  -- true once the button is held for a while
  self.held_event_fired = false
end


--------------------------------------------------------------------------------

function Message:__tostring()
  return string.format("message: context:%s, group_name:%s",
    tostring(self.context), tostring(self.group_name))
end
