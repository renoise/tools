--[[----------------------------------------------------------------------------
-- Duplex.MessageStream
----------------------------------------------------------------------------]]--

--[[
Requires: Globals

Interpret incoming (user-generated) messages, with built-in handlers for 
* detecting standard press/release events
* detecting that a button was double-pressed (trigger on second press)
* detecting that a button was held for specified amount of time 
* detecting multiple simultanously pressed buttons (combinations) with support for "any" or "all" 

A Display use only a single MessageStream, but we can attach any device to it. 
This also offers us a "brute-force" method for terminating device communication


--]]


--==============================================================================

class 'MessageStream' 

function MessageStream:__init()
  TRACE('MessageStream:__init')

  self.button_hold_time = 300  -- milliseconds
  self.double_press_time = 100 -- milliseconds

  self.change_listeners = {}    -- sliders,encoders
  self.press_listeners = {}    -- buttons
  --self.release_listeners = {}    
  --self.double_press_listeners = {}    
  --self.hold_listeners = {}  
  --self.combo_listeners = {}    

  self.current_message = nil  -- most recent message (event handlers check this)
  self.button_cache = nil    -- cache of recent events (used for double-press detection)
  self.ignored_buttons = nil  -- temporarily exclude from interpretation
  self.pressed_buttons = {}  -- currently pressed buttons, in order of arrival

end


--------------------------------------------------------------------------------

function MessageStream:idle_check()
  -- flush cached messages when considered obsolete
  -- check if pressed_buttons have been pressed for specified amount of time 
  TRACE("MessageStream:idle_check()")
end


--------------------------------------------------------------------------------

function MessageStream:add_listener(obj,evt_type,handler)
  TRACE('MessageStream:add_listener:'..evt_type)
  
  if evt_type == DEVICE_EVENT_BUTTON_PRESSED then
    table.insert(self.press_listeners,#self.press_listeners+1,{handler=handler,obj=obj})
    TRACE("MessageStream:onpress handler added")
  end
  if evt_type == DEVICE_EVENT_VALUE_CHANGED then
    table.insert(self.change_listeners,#self.change_listeners+1,{handler=handler,obj=obj})
    TRACE("MessageStream:onpress handler added")
  end

  TRACE("MessageStream:Number of listeners after addition:", #self.press_listeners,#self.change_listeners)

end


--------------------------------------------------------------------------------

-- remove event listener
-- @return (boolean) true if successfull. false if not

function MessageStream:remove_listener(obj,evt_type)
  TRACE("MessageStream:remove_listener:",obj,evt_type)

  if evt_type == DEVICE_EVENT_BUTTON_PRESSED then
    for i,listener in ipairs(self.press_listeners) do
      if (obj == listener.obj) then
        table.remove(self.press_listeners,i)
        return true
      end
    end
  end
  if evt_type == DEVICE_EVENT_VALUE_CHANGED then
    for i,listener in ipairs(self.change_listeners) do
      if (obj == listener.obj) then
        table.remove(self.change_listeners,i)
        return true
      end
    end
  end
  return false

end


--------------------------------------------------------------------------------

function MessageStream:input_message(msg)
  TRACE('MessageStream: event was recieved:',msg)
  
  self.current_message = msg
  if (msg.input_method == CONTROLLER_ENCODER) or 
     (msg.input_method == CONTROLLER_FADER) then
    --if msg.value == msg.max then
    for _,listener in ipairs(self.change_listeners)  do 
      listener.handler() 
    end

    --for _,handler in ipairs(self.change_listeners)  do handler() end
    --end    
  elseif msg.input_method == CONTROLLER_BUTTON then
    -- if it's listed in ignored_buttons
      -- remove from ignored_buttons and exit
    -- else if it's value match the min/max value..
    if msg.value == msg.max then
      -- interpret this as pressed
        -- check if this button has been pressed recently
          -- invoke double_press, and add to ignored_buttons (so the release won't trigger as well)
        -- else, add to pressed_buttons
        -- todo: check if already pressed, and skip adding

        -- table.insert(self.pressed_buttons,#self.pressed_buttons+1,msg)
        -- print_r(self.pressed_buttons)

        -- broadcast to listeners
        for _,listener in ipairs(self.press_listeners)  do 
          listener.handler() 
        end

      -- check other held buttons:
        -- if combination is matched, invoke combination_press, and add held buttons 
        -- to ignored_buttons (so the release won't trigger)
    else 
      if msg.value == msg.minimum then
        -- interpret this as release
          -- remove from pressed_buttons
      end
    end
  end
end


