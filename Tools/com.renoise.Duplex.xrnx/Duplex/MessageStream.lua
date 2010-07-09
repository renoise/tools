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
* detect standard press events
* detect that a button was held for specified amount of time 

Todo 
* detecting standard release events
* detecting that a button was double-pressed (trigger on second press)
* detecting multiple simultanously pressed buttons (combinations)

--]]

class 'MessageStream' 

function MessageStream:__init()
  TRACE('MessageStream:__init')

  self.change_listeners = table.create() -- for faders,dials
  self.press_listeners = table.create() -- for buttons
  self.hold_listeners = table.create()  -- buttons
  --self.release_listeners = {}  -- buttons
  --self.double_press_listeners = {}  -- buttons
  --self.combo_listeners = {}  -- buttons


  --self.button_hold_time = 1 -- seconds
  self.button_hold_time = self:__get_button_hold_time()
  --self.double_press_time = 0.1 -- seconds

  -- most recent message (event handlers check this)
  self.current_message = nil 

  -- cache of recent events (used for double-press detection)
  --self.button_cache = nil 

  -- [Message,...] temporarily exclude from interpretation
  self.ignored_buttons = nil 

  -- [Message,...] - currently pressed buttons, in order of arrival
  self.pressed_buttons = table.create() 
end

--------------------------------------------------------------------------------

function MessageStream:__get_button_hold_time()
    return duplex_preferences.button_hold_time
end

--------------------------------------------------------------------------------

-- on_idle() : check if buttons have been pressed for some time 

function MessageStream:on_idle()
  TRACE("MessageStream:on_idle()")

  for i,msg in ipairs(self.pressed_buttons) do
    if (not msg.held_event_fired) and
       (msg.timestamp + self.button_hold_time < os.clock()) 
    then
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
    TRACE("MessageStream:onpress handler added")

  elseif (evt_type == DEVICE_EVENT_BUTTON_HELD) then
    self.hold_listeners:insert({ handler = handler, obj = obj })
    TRACE("MessageStream:hold handler added")
  
  else
    error(("Internal Error. Please report: " ..
      "unknown evt_type '%s'"):format(tostring(evt_type) or "nil"))
  end

  TRACE("MessageStream:Number of listeners after addition:",
     #self.press_listeners, #self.change_listeners, #self.hold_listeners)
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
 
  else
     error(("Internal Error. Please report: " .. 
      "unknown evt_type '%s'"):format(tostring(evt_type) or "nil"))
  end
    
  return false
end


--------------------------------------------------------------------------------

function MessageStream:input_message(msg)
  TRACE('MessageStream: event was recieved:',msg)
  
  self.current_message = msg
  
--  if (msg.input_method == CONTROLLER_ENCODER) or 
  if (msg.input_method == CONTROLLER_FADER or 
      msg.input_method == CONTROLLER_DIAL) then

      -- "analogue" input, value between max/min
    
    for _,listener in ipairs(self.change_listeners)  do 
      listener.handler() 
    end
  
  elseif (msg.input_method == CONTROLLER_BUTTON) then

    --  "binary" input, value either max or min 

    -- if it's listed in ignored_buttons
    -- remove from ignored_buttons and exit

    if (msg.value == msg.max) then
      -- interpret this as pressed
      -- check if this button has been pressed recently invoke double_press, and 
      -- add to ignored_buttons (so the release won't trigger as well) else, add 
      -- to pressed_buttons
      -- todo: check if already pressed, and skip adding

      -- if the input source was the virtual control surface, we do
      -- not add the button to the list of pressed buttons (not while
      -- the control surface doesn't have a release event)
      if (not msg.is_virtual)then
        self.pressed_buttons:insert(msg)
      end

      -- broadcast to listeners
      for _,listener in ipairs(self.press_listeners) do 
        listener.handler() 
      end

      -- check other held buttons:
      -- if combination is matched, invoke combination_press, and add held buttons 
      -- to ignored_buttons (so the release won't trigger)
      
    elseif (msg.value == msg.min) then
      -- interpret this as release
      
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

  -- the context control how the number/value is output,
  -- it might indicate a CC, or OSC message
  self.context = nil

  -- true, when the message was sent from a device (MIDI or OSC) and not
  -- from the virtual UI components or other MessageStream clients
  self.from_device = nil
  
  -- the is the actual value for the chosen parameter
  -- (not to be confused with the control-map value)
  self.value = nil

  -- meta values are useful for further refinement of messages,
  -- for example by defining the expected/allowed range of values

  self.id = nil --  unique id for each parameter
  self.group_name = nil --  name of the parent group 
  self.index = nil --  (int) index within control-map group, zero-based
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

