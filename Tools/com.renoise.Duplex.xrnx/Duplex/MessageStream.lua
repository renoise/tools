--[[============================================================================
-- Duplex.MessageStream and Message
============================================================================]]--

--[[--

Recieve messages from connected devices and the virtual control surface. 

After the type of event has been determined, the resulting Message is then directed towards relevant UIComponent event-listeners, such as DEVICE_EVENT.BUTTON_PRESSED. 

A device can only belong to a single stream, but nothing stops the stream from recieving it's input from several devices.  


### Changes

  1.03
    - Optimize: switch to table-based lookups where possible

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

  local button_hold_time = duplex_preferences.button_hold_time.value

  for i,msg in ipairs(self.pressed_buttons) do
    if (not msg.held_event_fired) and
      (msg.xarg.type == "button" or
       msg.xarg.type == "pushbutton") and
       (msg.timestamp + button_hold_time < os.clock()) then
      -- broadcast to attached listeners
      for _,listener in ipairs(self.hold_listeners)  do 
        listener.handler(msg) 
      end
      msg.held_event_fired = true
    end
  end
end


--------------------------------------------------------------------------------
-- Here we receive a message from the device, and pass it to all the relevant
-- UIComponents. If a listener's handler method actively reject the message 
-- (by explicitly returning false in the event-handling method), we instead 
-- (can choose to) pass the message on to Renoise as a MIDI message
-- @param msg (@{Duplex.Message})

function MessageStream:input_message(msg)
  TRACE("MessageStream:input_message()",msg)

  self.current_msg = msg

  -- handle states (update display accordingly)
  local state_ctrl = self.process.display.state_ctrl
  state_ctrl:handle_message(msg)

  -- invoke listener methods 
  -- this needs to cover all input types (INPUT_TYPE)
  local input_types = {
    ["button"] = function() self:_process_button_message(msg) end,
    ["togglebutton"] = function() self:_process_button_message(msg) end,
    ["pushbutton"] = function() self:_process_button_message(msg) end,
    ["fader"] = function() self:_process_fader_message(msg) end,
    ["dial"] = function() self:_process_fader_message(msg) end,
    ["xypad"] = function() self:_process_fader_message(msg) end,
    ["keyboard"] = function() self:_process_note_message(msg) end,
  }

  if input_types[msg.xarg.type] then
    input_types[msg.xarg.type]()
  else
    error(("Internal Error. Please report: " ..
      "unknown msg.xarg.type'%s'"):format(msg.xarg.type or "nil"))
  end

end

--------------------------------------------------------------------------------
-- handle "analog" input, value between max/min
-- @see MessageStream.input_message

function MessageStream:_process_fader_message(msg)
  TRACE("MessageStream:_process_fader_message(msg)",msg)

  -- check if we have associated a pitch-bend or key-pressure handler 
  -- before processing the message as a standard "change" event
  if (msg.context == DEVICE_MESSAGE.MIDI_CHANNEL_PRESSURE) then
    self:_handle_or_pass(msg,self.channel_pressure_listeners,DEVICE_EVENT.CHANNEL_PRESSURE)
  elseif (msg.context == DEVICE_MESSAGE.MIDI_PITCH_BEND) then
    self:_handle_or_pass(msg,self.pitch_change_listeners,DEVICE_EVENT.PITCH_CHANGED)
  else
    self:_handle_or_pass(msg,self.change_listeners,DEVICE_EVENT.VALUE_CHANGED)
  end
end

--------------------------------------------------------------------------------
-- handle "binary" input, value either max or min 
-- @see MessageStream.input_message

function MessageStream:_process_button_message(msg)
  TRACE("MessageStream:_process_button_message(msg)",msg)

  -- keyboard (note) input is supported as well, but it's a
  -- special case: note-on will need to be "maximixed" before
  -- it's able to trigger buttons)
  if (msg.context == DEVICE_MESSAGE.MIDI_NOTE) and (not msg.is_note_off) then
    msg.value = msg.xarg.maximum
  end

  if (msg.value == msg.xarg.maximum) and (not msg.is_note_off) then
    --print("*** MessageStream:  interpret this as pressed")
    self.pressed_buttons:insert(msg)
    self:_handle_or_pass(msg,self.press_listeners,DEVICE_EVENT.BUTTON_PRESSED)

  elseif (msg.value == msg.xarg.minimum) or (msg.is_note_off) then
    --print("*** MessageStream:  interpret this as release")
    -- for toggle buttons, broadcast releases to listeners as well
    if (not msg.is_virtual) and
      (msg.xarg.type == "togglebutton")
    then
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

end

--------------------------------------------------------------------------------
-- handle keyboard input (note)
-- @see MessageStream.input_message

function MessageStream:_process_note_message(msg)
  TRACE("MessageStream:_process_note_message(msg)",msg)

  if (msg.value == msg.xarg.minimum) or (msg.is_note_off) then
    self:_handle_or_pass(msg,self.key_release_listeners,DEVICE_EVENT.KEY_RELEASED)
  else
    self:_handle_or_pass(msg,self.key_press_listeners,DEVICE_EVENT.KEY_PRESSED)
  end

end

--------------------------------------------------------------------------------

--- Register an event listener
-- @param obj (@{Duplex.UIComponent}) 
-- @param evt_type (@{Duplex.Globals.DEVICE_EVENT})
-- @param handler (function) reference to the handling method

function MessageStream:add_listener(obj,evt_type,handler)
  TRACE('MessageStream:add_listener:'..evt_type)
  
  local event_types = {
    [DEVICE_EVENT.BUTTON_PRESSED] = function(t) self.press_listeners:insert(t) end,
    [DEVICE_EVENT.VALUE_CHANGED] = function(t) self.change_listeners:insert(t) end,
    [DEVICE_EVENT.BUTTON_HELD] = function(t) self.hold_listeners:insert(t) end,
    [DEVICE_EVENT.BUTTON_RELEASED] = function(t) self.release_listeners:insert(t) end,
    [DEVICE_EVENT.KEY_PRESSED] = function(t) self.key_press_listeners:insert(t) end,
    [DEVICE_EVENT.KEY_RELEASED] = function(t) self.key_release_listeners:insert(t) end,
    [DEVICE_EVENT.KEY_HELD] = function(t) self.key_hold_listeners:insert(t) end,
    [DEVICE_EVENT.PITCH_CHANGED] = function(t) self.pitch_change_listeners:insert(t) end,
    [DEVICE_EVENT.CHANNEL_PRESSURE] = function(t) self.channel_pressure_listeners:insert(t) end,
  }

  if event_types[evt_type] then 
    event_types[evt_type]({ handler = handler, obj = obj })
  else
    error(("Internal Error. Please report: " ..
      "unknown evt_type '%s'"):format(tostring(evt_type) or "nil"))
  end

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

  local event_types = {
    [DEVICE_EVENT.BUTTON_PRESSED] = function() remove_listeners(self.press_listeners) end,
    [DEVICE_EVENT.VALUE_CHANGED] = function() remove_listeners(self.change_listeners) end,
    [DEVICE_EVENT.BUTTON_HELD] = function() remove_listeners(self.hold_listeners) end,
    [DEVICE_EVENT.BUTTON_RELEASED] = function() remove_listeners(self.release_listeners) end,
    [DEVICE_EVENT.KEY_PRESSED] = function() remove_listeners(self.key_press_listeners) end,
    [DEVICE_EVENT.KEY_RELEASED] = function() remove_listeners(self.key_release_listeners) end,
    [DEVICE_EVENT.KEY_HELD] = function() remove_listeners(self.key_hold_listeners) end,
    [DEVICE_EVENT.PITCH_CHANGED] = function() remove_listeners(self.pitch_change_listeners) end,
    [DEVICE_EVENT.CHANNEL_PRESSURE] = function() remove_listeners(self.channel_pressure_listeners) end,
  }

  if (event_types[evt_type]) then
    event_types[evt_type]()
  else
     error(("Internal Error. Please report: " .. 
      "unknown evt_type '%s'"):format(tostring(evt_type) or "nil"))
  end
    
  return false
end


---------------------------------------------------------------------------------------------------

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
      for k,v in ipairs(msg.xarg.state_ids) do
        local state = state_ctrl.states[v]
        if state and 
          not state.active and
          not state.xarg.receive_when_inactive
        then
          return false
        end
      end
    end

    -- check for matching value
    ---------------------------------------------------------
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
    if ui_component_refs then
      if not post_pass_check() then
        return
      end
      for k,v in ipairs(ui_component_refs) do
        --print("*** _handle_or_pass - use cached ui_component_ref",msg.xarg.value,v)
        local event_types = {
          [DEVICE_EVENT.BUTTON_PRESSED] = function() v:do_press(msg) end,
          [DEVICE_EVENT.VALUE_CHANGED] = function() v:do_change(msg) end,
          [DEVICE_EVENT.BUTTON_HELD] = function() v:do_hold(msg) end,
          [DEVICE_EVENT.BUTTON_RELEASED] = function() v:do_release(msg) end,
          [DEVICE_EVENT.KEY_PRESSED] = function() v:do_press(msg) end,
          [DEVICE_EVENT.KEY_RELEASED] = function() v:do_release(msg) end,
          [DEVICE_EVENT.KEY_HELD] = function() v:do_hold(msg) end,
          [DEVICE_EVENT.PITCH_CHANGED] = function() v:do_change(msg) end,
          [DEVICE_EVENT.CHANNEL_PRESSURE] = function() v:do_change(msg) end,
        }
        if (event_types[evt_type]) then
          event_types[evt_type]()
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
        if UIComponent.test(listener.obj,msg) then
          table.insert(self._temp_cache,listener.obj)
          if post_pass_check() then
            ui_component_matched = listener.handler(msg)
            --print("ui_component_matched",ui_component_matched)
          end
        end
      end
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

  --print(">>> pass_msg,msg.midi_msgs",pass_msg,msg.midi_msgs)

  -- ensure that we have MIDI data before passing message
  if pass_msg and msg.midi_msgs and
    (msg.device.protocol == DEVICE_PROTOCOL.MIDI) 
  then
    local osc_client = self.process.browser._osc_client
    for _,midi_msg in ipairs(msg.midi_msgs) do
      osc_client:trigger_midi(midi_msg)
    end
  end

end


