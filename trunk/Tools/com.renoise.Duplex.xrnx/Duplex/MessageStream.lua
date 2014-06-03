--[[============================================================================
-- Duplex.MessageStream and Message
============================================================================]]--

--[[--

Recieve messages from connected devices and the virtual control surface. 

After the type of event has been determined, the resulting Message is then directed towards relevant UIComponent event-listeners, such as DEVICE_EVENT.BUTTON_PRESSED. 

A device can only belong to a single stream, but nothing stops the stream from recieving it's input from several devices.  

--]]

--==============================================================================

class 'MessageStream' 

--------------------------------------------------------------------------------

--- Initialize the MessageStream class
-- @param process (@{Duplex.BrowserProcess}) 

function MessageStream:__init(process)
  TRACE('MessageStream:__init')

  --- (@{Duplex.BrowserProcess})
  self.process = process

  --- (table) listeners for faders,dials,xy pads
  self.change_listeners = table.create()

  --- (table) listeners for buttons
  self.press_listeners = table.create()
  --- (table) listeners for buttons
  self.hold_listeners = table.create()
  --- (table) listeners for buttons
  self.release_listeners = table.create()

  --- (table) listeners for keys
  self.key_press_listeners = table.create() 
  --- (table) listeners for keys
  self.key_hold_listeners = table.create()
  --- (table) listeners for keys
  self.key_release_listeners = table.create()
  --- (table) listeners for keys
  self.pitch_change_listeners = table.create()
  --- (table) listeners for keys
  self.channel_pressure_listeners = table.create()

  --- (number) how long before triggering `hold` event
  self.button_hold_time = duplex_preferences.button_hold_time.value

  --- (@{Duplex.Message}) most recent message
  self.current_message = nil 

  --- (table of @{Duplex.Message}) pressed buttons in order of arrival
  self.pressed_buttons = table.create() 

  --- table, containing each type of event and messages by value:
  --    [DEVICE_EVENT.BUTTON_RELEASED] = {
  --      "F#4|Ch1" = [UIComponent instance]
  --    }
  self.message_cache = table.create()
  for k,v in pairs(DEVICE_EVENT) do
    self.message_cache[v] = {}
  end

end


--------------------------------------------------------------------------------

--- The MessageStream idle time method, checks for held buttons

function MessageStream:on_idle()
  --TRACE("MessageStream:on_idle()")

  for i,msg in ipairs(self.pressed_buttons) do
    if (not msg.held_event_fired) and
      (msg.input_method == INPUT_TYPE.BUTTON or
       msg.input_method == INPUT_TYPE.PUSHBUTTON) and
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

--- Register an event listener
-- @param obj (@{Duplex.UIComponent}) 
-- @param evt_type (@{Duplex.Globals.DEVICE_EVENT})
-- @param handler (function) reference to the handling method

function MessageStream:add_listener(obj,evt_type,handler)
  TRACE('MessageStream:add_listener:'..evt_type)
  
  if (evt_type == DEVICE_EVENT.BUTTON_PRESSED) then
    self.press_listeners:insert({ handler = handler, obj = obj })

  elseif (evt_type == DEVICE_EVENT.VALUE_CHANGED) then
    self.change_listeners:insert({ handler = handler, obj = obj })

  elseif (evt_type == DEVICE_EVENT.BUTTON_HELD) then
    self.hold_listeners:insert({ handler = handler, obj = obj })
    
  elseif (evt_type == DEVICE_EVENT.BUTTON_RELEASED) then
    self.release_listeners:insert({ handler = handler, obj = obj })
  
  elseif (evt_type == DEVICE_EVENT.KEY_PRESSED) then
    self.key_press_listeners:insert({ handler = handler, obj = obj })

  elseif (evt_type == DEVICE_EVENT.KEY_HELD) then
    self.key_hold_listeners:insert({ handler = handler, obj = obj })
    
  elseif (evt_type == DEVICE_EVENT.KEY_RELEASED) then
    self.key_release_listeners:insert({ handler = handler, obj = obj })
  
  elseif (evt_type == DEVICE_EVENT.PITCH_CHANGED) then
    self.pitch_change_listeners:insert({ handler = handler, obj = obj })
  
  elseif (evt_type == DEVICE_EVENT.CHANNEL_PRESSURE) then
    self.channel_pressure_listeners:insert({ handler = handler, obj = obj })
  
  else
    error(("Internal Error. Please report: " ..
      "unknown evt_type '%s'"):format(tostring(evt_type) or "nil"))
  end

  TRACE("MessageStream:Number of listeners after addition:",#self.press_listeners, #self.change_listeners, #self.hold_listeners, #self.release_listeners, #self.key_press_listeners, #self.key_hold_listeners, #self.key_release_listeners, #self.pitch_change_listeners, #self.channel_pressure_listeners)
end


--------------------------------------------------------------------------------

--- Remove event listener from previously attached UIComponent
-- @param obj (@{Duplex.UIComponent}) 
-- @param evt_type (@{Duplex.Globals.DEVICE_EVENT})
-- @return (bool) true if successful, false if not

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

  if (evt_type == DEVICE_EVENT.BUTTON_PRESSED) then
    remove_listeners(self.press_listeners)

  elseif (evt_type == DEVICE_EVENT.VALUE_CHANGED) then
    remove_listeners(self.change_listeners)

  elseif (evt_type == DEVICE_EVENT.BUTTON_HELD) then
    remove_listeners(self.hold_listeners)
    
  elseif (evt_type == DEVICE_EVENT.BUTTON_RELEASED) then
    remove_listeners(self.release_listeners)

  elseif (evt_type == DEVICE_EVENT.KEY_RELEASED) then
    remove_listeners(self.key_release_listeners)

  elseif (evt_type == DEVICE_EVENT.KEY_HELD) then
    remove_listeners(self.key_hold_listeners)

  elseif (evt_type == DEVICE_EVENT.KEY_PRESSED) then
    remove_listeners(self.key_press_listeners)

  elseif (evt_type == DEVICE_EVENT.PITCH_CHANGED) then
    remove_listeners(self.pitch_change_listeners)

  elseif (evt_type == DEVICE_EVENT.CHANNEL_PRESSURE) then
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
-- @param msg (@{Duplex.Message})

function MessageStream:input_message(msg)
  TRACE("MessageStream:input_message()")


  --print("*** MessageStream: msg.input_method",msg.input_method)
  --print("*** MessageStream: msg.max",msg.max)
  --print("*** MessageStream: msg.context",msg.context)
  --print("*** MessageStream: msg.group_name",msg.group_name)
  --print("*** MessageStream: msg.is_note_off",msg.is_note_off)
  --print("*** MessageStream: msg.index",msg.index)
  --print("*** MessageStream: msg.row",msg.row)
  --print("*** MessageStream: msg.column",msg.column)
  --print("*** MessageStream: msg.value...")
  --rprint(msg.value)
  --rprint(msg)


  self.current_message = msg

  if (msg.input_method == INPUT_TYPE.FADER or 
    msg.input_method == INPUT_TYPE.DIAL or
    msg.input_method == INPUT_TYPE.XYPAD) then

    -- "analogue" input, value between max/min
    -- check if we have associated a pitch-bend or key-pressure handler 
    -- before processinh the message as a standard "change" event
    -- (please note that pitch & key pressure is never passed on, 
    -- this can be achieved by using an application like Keyboard)
    --print("*** MessageStream: CONTROLLER_XFADER")
    if (msg.context == DEVICE_MESSAGE.MIDI_CHANNEL_PRESSURE) then
      --print("*** MessageStream: DEVICE_MESSAGE.MIDI_CHANNEL_PRESSURE")
      self:_handle_or_pass(msg,self.channel_pressure_listeners,DEVICE_EVENT.CHANNEL_PRESSURE)
    elseif (msg.context == DEVICE_MESSAGE.MIDI_PITCH_BEND) then
      --print("*** MessageStream: DEVICE_MESSAGE.MIDI_PITCH_BEND")
      self:_handle_or_pass(msg,self.pitch_change_listeners,DEVICE_EVENT.PITCH_CHANGED)
    end
    --print("*** MessageStream: standard change event")
    self:_handle_or_pass(msg,self.change_listeners,DEVICE_EVENT.VALUE_CHANGED)

  elseif (msg.input_method == INPUT_TYPE.KEYBOARD) then

    -- keyboard input (note), check if key was pressed or released
    --print("*** MessageStream: msg.context == INPUT_TYPE.KEYBOARD")
    if (msg.context == DEVICE_MESSAGE.MIDI_NOTE) then
      --print("*** MessageStream: INPUT_TYPE.KEYBOARD + DEVICE_MESSAGE.MIDI_NOTE")
      if (msg.value[2] == msg.min) or (msg.is_note_off) then
        self:_handle_or_pass(msg,self.key_release_listeners,DEVICE_EVENT.KEY_RELEASED)
      else
        --print("MessageStream:_handle_or_pass - key_press_listeners")
        self:_handle_or_pass(msg,self.key_press_listeners,DEVICE_EVENT.KEY_PRESSED)
      end
    end

  elseif (msg.input_method == INPUT_TYPE.BUTTON or 
      msg.input_method == INPUT_TYPE.TOGGLEBUTTON or
      msg.input_method == INPUT_TYPE.PUSHBUTTON) 
    then

    --  "binary" input, value either max or min 
    --print("*** MessageStream: msg.context == CONTROLLER_XBUTTON")
    -- keyboard (note) input is supported as well, but it's a
    -- special case: note-on will need to be "maximixed" before
    -- it's able to trigger buttons)
    if (msg.context == DEVICE_MESSAGE.MIDI_NOTE) and (not msg.is_note_off) then
      --print("MessageStream:  maximize value")
      msg.value = msg.max
    end

    if (msg.value == msg.max) and (not msg.is_note_off) then
      -- interpret this as pressed
      --print("*** MessageStream:  interpret this as pressed")
      self.pressed_buttons:insert(msg)
      -- broadcast to listeners
      self:_handle_or_pass(msg,self.press_listeners,DEVICE_EVENT.BUTTON_PRESSED)

    elseif (msg.value == msg.min) or (msg.is_note_off) then
      -- interpret this as release

      --print("*** MessageStream:  interpret this as release")

      -- for toggle buttons, broadcast releases to listeners as well
      if (not msg.is_virtual) and
        (msg.input_method == INPUT_TYPE.TOGGLEBUTTON) --or
        --(msg.input_method == INPUT_TYPE.PUSHBUTTON) 
      then
        --print("broadcast release to press listeners")
        self:_handle_or_pass(msg,self.press_listeners,DEVICE_EVENT.BUTTON_PRESSED)
      else
        self:_handle_or_pass(msg,self.release_listeners,DEVICE_EVENT.BUTTON_RELEASED)
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

--------------------------------------------------------------------------------

--- Handle or pass: invoke event handlers or pass on to Renoise as MIDI
-- (only valid msg context is DEVICE_MESSAGE.MIDI_NOTE)
-- @param msg (@{Duplex.Message})
-- @param listeners (table), listener methods
-- @param evt_type (@{Duplex.Globals.DEVICE_EVENT})

function MessageStream:_handle_or_pass(msg,listeners,evt_type)
  TRACE("MessageStream:_handle_or_pass()")

  local pass_setting = self.process.settings.pass_unhandled.value
  local pass_msg = false

  if self.process:running() then

    -- attempt to look up previously memoized UIComponents
    local ui_component_refs = self.message_cache[evt_type][msg.param.value]
    if ui_component_refs then
      for k,v in ipairs(ui_component_refs) do
        --print("*** _handle_or_pass - use cached message",msg.param.value,v)
        -- note: put the most often used / frequent messages at the top
        if (evt_type == DEVICE_EVENT.VALUE_CHANGED) then
          v:do_change(msg)
        elseif (evt_type == DEVICE_EVENT.BUTTON_PRESSED) then
          v:do_press(msg)
        elseif (evt_type == DEVICE_EVENT.BUTTON_RELEASED) then
          v:do_release(msg)
        elseif (evt_type == DEVICE_EVENT.BUTTON_HELD) then
          v:do_hold(msg)
        elseif (evt_type == DEVICE_EVENT.KEY_PRESSED) then
          v:do_press(msg)
        elseif (evt_type == DEVICE_EVENT.KEY_RELEASED) then
          v:do_release(msg)
        elseif (evt_type == DEVICE_EVENT.KEY_HELD) then
          v:do_hold(msg)
        elseif (evt_type == DEVICE_EVENT.PITCH_CHANGED) then
          v:do_change(msg)
        elseif (evt_type == DEVICE_EVENT.CHANNEL_PRESSURE) then
          v:do_change(msg)
        end
      end
    else
      -- broadcast to all relevant UIComponents, let them decide
      -- whether to act on the message or not ...
      local ui_component_matched = false
      --print("*** _handle_or_pass - #listeners",#listeners)
      for _,listener in ipairs(listeners) do 
        local ui_component_ref = listener.handler(msg)
        if ui_component_ref then
          if not self.message_cache[evt_type][msg.param.value] then
            self.message_cache[evt_type][msg.param.value] = table.create()
          end
          self.message_cache[evt_type][msg.param.value]:insert(ui_component_ref)
          ui_component_matched = true
        end
      end

      -- if no UI component was matched, pass on
      if pass_setting and not ui_component_matched then
        pass_msg = true
      end
    end

  else
    -- pass on messages when process is not running
    if pass_setting then
      pass_msg = true
    end

  end

  --print("pass_msg",pass_msg)

  -- ensure that we have MIDI data before passing message
  if pass_msg and msg.midi_msg and
    (msg.device.protocol == DEVICE_PROTOCOL.MIDI) 
  then
    local osc_client = self.process.browser._osc_client
    osc_client:trigger_midi(msg.midi_msg)
  end

end


