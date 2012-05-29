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


--]]

class 'MessageStream' 

--------------------------------------------------------------------------------

--- Initialize the MessageStream class
-- @param process (BrowserProcess) reference to BrowserProcess

function MessageStream:__init(process)
  TRACE('MessageStream:__init')

  -- keep reference to browser process 
  self.process = process

  -- for faders,dials,xy pads
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

  -- [Message,...] - currently pressed buttons, in order of arrival
  self.pressed_buttons = table.create() 
end

--------------------------------------------------------------------------------

--- Retrieve the button hold time from the global preferences
-- @return Number

function MessageStream:_get_button_hold_time()
  return duplex_preferences.button_hold_time.value
end

--------------------------------------------------------------------------------

--- The MessageStream idle time method, checks for held buttons

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

--- Add an event listener (used by UIComponents)
-- @param obj (UIComponent) the UIComponent instance
-- @param evt_type (Enum) event type, e.g. DEVICE_EVENT_BUTTON_PRESSED
-- @param handler (Function) reference to the handling method

function MessageStream:add_listener(obj,evt_type,handler)
  TRACE('MessageStream:add_listener:'..evt_type)
  
  if (evt_type == DEVICE_EVENT_BUTTON_PRESSED) then
    self.press_listeners:insert({ handler = handler, obj = obj })

  elseif (evt_type == DEVICE_EVENT_VALUE_CHANGED) then
    self.change_listeners:insert({ handler = handler, obj = obj })

  elseif (evt_type == DEVICE_EVENT_BUTTON_HELD) then
    self.hold_listeners:insert({ handler = handler, obj = obj })
    
  elseif (evt_type == DEVICE_EVENT_BUTTON_RELEASED) then
    self.release_listeners:insert({ handler = handler, obj = obj })
  
  elseif (evt_type == DEVICE_EVENT_KEY_PRESSED) then
    self.key_press_listeners:insert({ handler = handler, obj = obj })

  elseif (evt_type == DEVICE_EVENT_KEY_HELD) then
    self.key_hold_listeners:insert({ handler = handler, obj = obj })
    
  elseif (evt_type == DEVICE_EVENT_KEY_RELEASED) then
    self.key_release_listeners:insert({ handler = handler, obj = obj })
  
  elseif (evt_type == DEVICE_EVENT_PITCH_CHANGED) then
    self.pitch_change_listeners:insert({ handler = handler, obj = obj })
  
  elseif (evt_type == DEVICE_EVENT_CHANNEL_PRESSURE) then
    self.channel_pressure_listeners:insert({ handler = handler, obj = obj })
  
  else
    error(("Internal Error. Please report: " ..
      "unknown evt_type '%s'"):format(tostring(evt_type) or "nil"))
  end

  TRACE("MessageStream:Number of listeners after addition:",#self.press_listeners, #self.change_listeners, #self.hold_listeners, #self.release_listeners, #self.key_press_listeners, #self.key_hold_listeners, #self.key_release_listeners, #self.pitch_change_listeners, #self.channel_pressure_listeners)
end


--------------------------------------------------------------------------------

--- Remove event listener from previously attached UIComponent
-- @param obj (UIComponent) the UIComponent instance
-- @param evt_type (Enum) event type, e.g. DEVICE_EVENT_BUTTON_PRESSED
-- @return (Boolean) true if successfull. false if not

function MessageStream:remove_listener(obj,evt_type)
  TRACE("MessageStream:remove_listener:",obj,evt_type)

  local remove_listeners = function(listeners)
    for i,listener in ipairs(listeners) do
      if (obj == listener.obj) then
        listeners:remove(i)
        return true
      end
    end
  end

  if (evt_type == DEVICE_EVENT_BUTTON_PRESSED) then
    remove_listeners(self.press_listeners)

  elseif (evt_type == DEVICE_EVENT_VALUE_CHANGED) then
    remove_listeners(self.change_listeners)

  elseif (evt_type == DEVICE_EVENT_BUTTON_HELD) then
    remove_listeners(self.hold_listeners)
    
  elseif (evt_type == DEVICE_EVENT_BUTTON_RELEASED) then
    remove_listeners(self.release_listeners)

  elseif (evt_type == DEVICE_EVENT_KEY_RELEASED) then
    remove_listeners(self.key_release_listeners)

  elseif (evt_type == DEVICE_EVENT_KEY_HELD) then
    remove_listeners(self.key_hold_listeners)

  elseif (evt_type == DEVICE_EVENT_KEY_PRESSED) then
    remove_listeners(self.key_press_listeners)

  elseif (evt_type == DEVICE_EVENT_PITCH_CHANGED) then
    remove_listeners(self.pitch_change_listeners)

  elseif (evt_type == DEVICE_EVENT_CHANNEL_PRESSURE) then
    remove_listeners(self.channel_pressure_listeners)

  else
     error(("Internal Error. Please report: " .. 
      "unknown evt_type '%s'"):format(tostring(evt_type) or "nil"))
  end
    
  return false
end

--------------------------------------------------------------------------------

--- Here we receive a message from the device, and pass it to all the relevant
-- UIComponents. If a listener's handler method actively reject the message 
-- (by explicitly returning false in the event-handling method), we instead 
-- (can choose to) pass the message on to Renoise as a MIDI message
-- @param msg (Message)

function MessageStream:input_message(msg)
  TRACE("MessageStream:input_message()",msg)

  --[[
  print("*** MessageStream: msg.input_method",msg.input_method)
  print("*** MessageStream: msg.max",msg.max)
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

  if (msg.input_method == CONTROLLER_FADER or 
    msg.input_method == CONTROLLER_DIAL or
    msg.input_method == CONTROLLER_XYPAD) then

    -- "analogue" input, value between max/min
    -- check if we have associated a pitch-bend or key-pressure handler 
    -- before processinh the message as a standard "change" event
    -- (please note that pitch & key pressure is never passed on, 
    -- this can be achieved by using an application like Keyboard)
    --print("*** MessageStream: CONTROLLER_XFADER")
    if (msg.context == MIDI_CHANNEL_PRESSURE) then
      --print("*** MessageStream: MIDI_CHANNEL_PRESSURE")
      self:_handle_events(msg,self.channel_pressure_listeners)
    elseif (msg.context == MIDI_PITCH_BEND_MESSAGE) then
      --print("*** MessageStream: MIDI_PITCH_BEND_MESSAGE")
      self:_handle_events(msg,self.pitch_change_listeners)
    end
    --print("*** MessageStream: standard change event")
    self:_handle_or_pass(msg,self.change_listeners)

  elseif (msg.input_method == CONTROLLER_KEYBOARD) then

    -- keyboard input (note), check if key was pressed or released
    --print("*** MessageStream: msg.context == CONTROLLER_KEYBOARD")
    if (msg.context == MIDI_NOTE_MESSAGE) then
      --print("*** MessageStream: CONTROLLER_KEYBOARD + MIDI_NOTE_MESSAGE")
      if (msg.value[2] == msg.min) or (msg.is_note_off) then
        self:_handle_or_pass(msg,self.key_release_listeners)
      else
        --print("MessageStream:_handle_or_pass - key_press_listeners")
        self:_handle_or_pass(msg,self.key_press_listeners)
      end
    end

  elseif (msg.input_method == CONTROLLER_BUTTON or 
      msg.input_method == CONTROLLER_TOGGLEBUTTON or
      msg.input_method == CONTROLLER_PUSHBUTTON) 
    then

    --  "binary" input, value either max or min 
    --print("*** MessageStream: msg.context == CONTROLLER_XBUTTON")
    -- keyboard (note) input is supported as well, but it's a
    -- special case: note-on will need to be "maximixed" before
    -- it's able to trigger buttons)
    if (msg.context == MIDI_NOTE_MESSAGE) and (not msg.is_note_off) then
      --print("MessageStream:  maximize value")
      msg.value = msg.max
    end

    if (msg.value == msg.max) and (not msg.is_note_off) then
      -- interpret this as pressed
      --print("MessageStream:  interpret this as pressed")
      self.pressed_buttons:insert(msg)
      -- broadcast to listeners
      self:_handle_or_pass(msg,self.press_listeners)

    elseif (msg.value == msg.min) or (msg.is_note_off) then
      -- interpret this as release

      --print("MessageStream:  interpret this as release")

      -- for toggle/push buttons, broadcast releases to listeners as well
      if (not msg.is_virtual) and
        (msg.input_method == CONTROLLER_TOGGLEBUTTON) 
      then
        self:_handle_or_pass(msg,self.press_listeners)
      else
        self:_handle_or_pass(msg,self.release_listeners)
      end
      
      -- remove from pressed_buttons
      for i,button_msg in ipairs(self.pressed_buttons) do
        if (msg.id == button_msg.id) then
          self.pressed_buttons:remove(i)
        end
      end

    end
    --[[
  elseif (msg.context == MIDI_CHANNEL_PRESSURE) then
    --print("*** MessageStream: CONTROLLER_KEYBOARD + MIDI_CHANNEL_PRESSURE")
    self:_handle_events(msg,self.channel_pressure_listeners)

  elseif (msg.context == MIDI_PITCH_BEND_MESSAGE) then
    print("*** MessageStream: CONTROLLER_KEYBOARD + MIDI_PITCH_BEND_MESSAGE")
    self:_handle_events(msg,self.pitch_change_listeners)
  ]]
  else
    error(("Internal Error. Please report: " ..
      "unknown msg.input_method '%s'"):format(msg.input_method or "nil"))
  end
end

--------------------------------------------------------------------------------

--- Handle or pass: invoke event handlers or pass on to Renoise as MIDI
-- (only valid msg context is MIDI_NOTE_MESSAGE)
-- @param msg (Message)
-- @param listeners (Table), listener methods

function MessageStream:_handle_or_pass(msg,listeners)

  local events_handled = false
  local pass_on = self.process.settings.pass_unhandled.value
  --[[
  print("MessageStream:_handle_or_pass() - pass_on",pass_on)
  print("MessageStream:_handle_or_pass() - msg.midi_msg",msg.midi_msg)
  rprint(msg.midi_msg)
  ]]

  if self.process:running() then
    events_handled = self:_handle_events(msg,listeners)
  end
  --print("MessageStream:_handle_or_pass() - events_handled",events_handled)

  if pass_on and 
    not events_handled and
    msg.midi_msg and
    (msg.device.protocol == DEVICE_MIDI_PROTOCOL) 
  then
    --print("*** MessageStream: unhandled MIDI message, pass on to Renoise")
    --rprint(msg.midi_msg)
    local osc_client = self.process.browser._osc_client
    osc_client:trigger_midi(msg.midi_msg)
  end

end

--------------------------------------------------------------------------------

--- Loop through listeners, invoke event handler methods
-- @param msg (Message)
-- @param listeners (Table)
-- @return boolean, true when message was handled, false if handler didn't 
--    exist, or (any) handler actively rejected the message 

function MessageStream:_handle_events(msg,listeners)
  TRACE("MessageStream:_handle_events()",msg,#listeners)
  local was_handled = true
  for _,listener in ipairs(listeners) do 
    if (listener.handler(msg)==false) then
      was_handled = false
    end
    --print("MessageStream: - was_handled",was_handled,_)
  end
  --print("MessageStream:input_message() - was_handled",was_handled)
  return was_handled
end


--==============================================================================

--[[

The Message class is a container for messages, closely related to the ControlMap
? use meta-table methods to control access to "undefined" values ?
? move all control-map/parameter attributes into "Param" ?
--]]


class 'Message' 

--------------------------------------------------------------------------------

--- Initialize Message class
-- @param device (Device)

function Message:__init(device)
  TRACE('Message:__init')

  -- the context indicates the "type" of message
  -- (set to one of the "Message type" properties defined in Globals.lua,
  -- such as MIDI_CC_MESSAGE or OSC_MESSAGE). Derived from device
  self.context = nil

  -- the input method type - CONTROLLER_BUTTON/etc. Derived from control-map
  self.input_method = nil 

  -- reference to the control-map parameter
  self.param = nil

  -- reference to the originating device
  self.device = nil

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

  -- MIDI only, the original MIDI message (3 bytes)
  self.midi_msg = nil

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

  -- true once the button is held for a while
  self.held_event_fired = false

end


--------------------------------------------------------------------------------

--- Print message (for debugging purposes)

function Message:__tostring()
  return string.format("message: context:%s, group_name:%s, value:%s",
    tostring(self.context), tostring(self.group_name),self.value)
end
