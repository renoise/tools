--[[============================================================================
-- Duplex.MessageStream and Message
============================================================================]]--

--[[--

Recieve messages from connected devices and the virtual control surface. 

After the type of event has been determined, the resulting Message is then directed towards relevant UIComponent event-listeners, such as DEVICE_EVENT.BUTTON_PRESSED. 

A device can only belong to a single stream, but nothing stops the stream from recieving it's input from several devices.  


### Changes

  0.99.3
    - Ability to cache multiple matched ui-components (implemented as queue)
    - Integration with StateController

  0.99.1
    - FIXME Caching can break multiple UIComponents listening to the same signal

  0.98.27
    - Caching: improve performance when many controls are present

  0.96
    - New Message property: is_note_off - distinguish between note-on/note-off 
     
  0.9
    - First release

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
  self.current_msg = nil 

  --- (table of @{Duplex.Message}) pressed buttons in order of arrival
  self.pressed_buttons = table.create() 

  --- table, containing each type of event and messages by value:
  --    [DEVICE_EVENT.BUTTON_RELEASED] = {
  --      "F#4|Ch1" = {[UIComponent instance],...}
  --    },...
  self.message_cache = table.create()
  for k,v in pairs(DEVICE_EVENT) do
    self.message_cache[v] = {}
  end

  --- how many messages a device is going to send
  self.queued_messages = nil

  --- contains entries that should be cached once a series
  -- of messages have been received
  self._temp_cache = {}


end


--------------------------------------------------------------------------------

--- The MessageStream idle time method, checks for held buttons

function MessageStream:on_idle()
  --TRACE("MessageStream:on_idle()")

  for i,msg in ipairs(self.pressed_buttons) do
    if (not msg.held_event_fired) and
      (msg.xarg.type == "button" or
       msg.xarg.type == "pushbutton") and
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

--- Here we receive a message from the device, and pass it to all the relevant
-- UIComponents. If a listener's handler method actively reject the message 
-- (by explicitly returning false in the event-handling method), we instead 
-- (can choose to) pass the message on to Renoise as a MIDI message
-- @param msg (@{Duplex.Message})

function MessageStream:input_message(msg)
  TRACE("MessageStream:input_message()",msg)

  self.current_msg = msg

  --print("*** MessageStream:input_message - msg.value",rprint(msg.value))


  -- handle states (update display accordingly)
  ---------------------------------------------------------

  local state_ctrl = self.process.display.state_ctrl
  state_ctrl:handle_message(msg)

  -- invoke listener methods 
  ---------------------------------------------------------

  if (msg.xarg.type == "fader" or 
    msg.xarg.type == "dial" or
    msg.xarg.type == "xypad") then

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
    else
      --print("*** MessageStream: standard change event")
      self:_handle_or_pass(msg,self.change_listeners,DEVICE_EVENT.VALUE_CHANGED)
    end

  --elseif (msg.xarg.type == "key") or
  --  (msg.xarg.type == "keyboard")
  elseif (msg.xarg.type == "keyboard") then

    -- keyboard input (note), check if key was pressed or released
    --print("*** MessageStream: msg.context == INPUT_TYPE.KEYBOARD")
    --if (msg.context == DEVICE_MESSAGE.MIDI_NOTE) then
      --print("*** MessageStream: INPUT_TYPE.KEYBOARD + DEVICE_MESSAGE.MIDI_NOTE")
      --if (msg.value[2] == msg.xarg.minimum) or (msg.is_note_off) then
      if (msg.value == msg.xarg.minimum) or (msg.is_note_off) then
        self:_handle_or_pass(msg,self.key_release_listeners,DEVICE_EVENT.KEY_RELEASED)
      else
        --print("MessageStream:_handle_or_pass - key_press_listeners")
        self:_handle_or_pass(msg,self.key_press_listeners,DEVICE_EVENT.KEY_PRESSED)
      end
    --end

  elseif string.find(msg.xarg.type,"button") then

    --  "binary" input, value either max or min 
    --print("*** MessageStream: msg.context == CONTROLLER_XBUTTON")
    -- keyboard (note) input is supported as well, but it's a
    -- special case: note-on will need to be "maximixed" before
    -- it's able to trigger buttons)
    if (msg.context == DEVICE_MESSAGE.MIDI_NOTE) and (not msg.is_note_off) then
      --print("MessageStream:  maximize value")
      msg.value = msg.xarg.maximum
    end

    if (msg.value == msg.xarg.maximum) and (not msg.is_note_off) then
      -- interpret this as pressed
      --print("*** MessageStream:  interpret this as pressed")
      self.pressed_buttons:insert(msg)
      -- broadcast to listeners
      self:_handle_or_pass(msg,self.press_listeners,DEVICE_EVENT.BUTTON_PRESSED)

    elseif (msg.value == msg.xarg.minimum) or (msg.is_note_off) then
      -- interpret this as release

      --print("*** MessageStream:  interpret this as release")

      -- for toggle buttons, broadcast releases to listeners as well
      if (not msg.is_virtual) and
        (msg.xarg.type == "togglebutton") --or
        --(msg.xarg.type == "pushbutton") 
      then
        --print("broadcast release to press listeners")
        self:_handle_or_pass(msg,self.press_listeners,DEVICE_EVENT.BUTTON_PRESSED)
      else
        self:_handle_or_pass(msg,self.release_listeners,DEVICE_EVENT.BUTTON_RELEASED)
      end
      
      -- remove from pressed_buttons
      for i,button_msg in ipairs(self.pressed_buttons) do
        if (msg.xarg.id == button_msg.xarg.id) then
          self.pressed_buttons:remove(i)
        end
      end

    end

  else
    error(("Internal Error. Please report: " ..
      "unknown msg.xarg.type'%s'"):format(msg.xarg.type or "nil"))
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

  --TRACE("MessageStream:Number of listeners after addition:",#self.press_listeners, #self.change_listeners, #self.hold_listeners, #self.release_listeners, #self.key_press_listeners, #self.key_hold_listeners, #self.key_release_listeners, #self.pitch_change_listeners, #self.channel_pressure_listeners)

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

--- Handle or pass: invoke event handlers or pass on to Renoise as MIDI
-- (only valid msg context is DEVICE_MESSAGE.MIDI_NOTE)
-- @param msg (@{Duplex.Message})
-- @param listeners (table), listener methods
-- @param evt_type (@{Duplex.Globals.DEVICE_EVENT})

function MessageStream:_handle_or_pass(msg,listeners,evt_type)
  TRACE("MessageStream:_handle_or_pass()",msg,listeners,evt_type)

  local pass_setting = self.process.settings.pass_unhandled.value
  local pass_msg = false

  local post_pass_check = function()
    --print("post_pass_check()")

    local state_ctrl = self.process.display.state_ctrl

    -- when a parameter has been assigned to a state,
    -- check if the state allows it to be passed on
    -- (the virtual UI is not included in this, as its widgets
    -- always represent the actual parameter)
    if not msg.is_virtual then
      --print("*** MessageStream:input_message - msg.xarg.state_ids",rprint(msg.xarg.state_ids))
      for k,v in ipairs(msg.xarg.state_ids) do
        local state = state_ctrl.states[v]
        --print("*** MessageStream:input_message - state",rprint(state))
        if state and 
          not state.active and
          not state.xarg.receive_when_inactive
        then
          --print("*** MessageStream:input_message - ignore message (inactive state)",v)
          return false
        end
      end
    end

    --print("*** MessageStream:input_message - pass message (active state or receive_when_inactive)",msg)

    -- check for matching value
    ---------------------------------------------------------
    --print("*** MessageStream:input_message - msg.value",rprint(msg.value))
    --print("*** MessageStream:input_message - msg.xarg.match",msg.xarg.match)
    --print("*** MessageStream:input_message - msg.xarg.mode",msg.xarg.mode)

    if msg.xarg.match and 
      not (msg.xarg.match == msg.value)
    then
      --print("*** MessageStream:input_message - match: failed exact match")
      return false
    end

    if msg.xarg.match_from and
      (msg.xarg.match_from > msg.value)
    then
      --print("*** MessageStream:input_message - match_from: value not big enough ")
      return false
    end

    if msg.xarg.match_to and
      (msg.xarg.match_to < msg.value)
    then
      --print("*** MessageStream:input_message - match_from: value too large")
      return false
    end

    return true

  end

  if self.process:running() then

    -- attempt to look up previously memoized UIComponents
    local ui_component_refs = self.message_cache[evt_type][msg.xarg.value]
    --local ui_component_refs = nil
    if ui_component_refs then
  
      if not post_pass_check() then
        return
      end

      for k,v in ipairs(ui_component_refs) do

        --print("*** _handle_or_pass - use cached ui_component_ref",msg.xarg.value,v)
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

        -- test the message, cache matches
        -- match when we determine that the message has the right x/y coords

        --print("msg.xarg",rprint(msg.xarg))

        if UIComponent.test(listener.obj,msg) then
          table.insert(self._temp_cache,listener.obj)
          --print("*** tested ui_obj",evt_type,msg.xarg.value,msg.xarg.group_name)
          --print("*** self.queued_messages",self.queued_messages)
          --print("*** memoize ui_component_ref",evt_type,msg.xarg.value,listener.obj,listener.obj.state)

          if post_pass_check() then
            ui_component_matched = listener.handler(msg)
            --print("ui_component_matched",ui_component_matched)
          end
        end


      end

      --print("self.queued_messages",self.queued_messages)

      -- last queued message: add temporary matches to permanent cache
      if (self.queued_messages == 0) then
        self.queued_messages = -1
        for k,v in ipairs(self._temp_cache) do
          if not self.message_cache[evt_type][msg.xarg.value] then
            self.message_cache[evt_type][msg.xarg.value] = table.create()
          end
          table.insert(self.message_cache[evt_type][msg.xarg.value],v)
          self._temp_cache = {}
        end
        --print("last queued message - self.message_cache",rprint(self.message_cache))
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
  -- ??? do we need to filter out non-midi devices
  if pass_msg and msg.midi_msg and
    (msg.device.protocol == DEVICE_PROTOCOL.MIDI) 
  then
    local osc_client = self.process.browser._osc_client
    osc_client:trigger_midi(msg.midi_msg)
  end

end


