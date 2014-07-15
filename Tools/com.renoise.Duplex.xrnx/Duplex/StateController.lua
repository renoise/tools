--[[============================================================================
-- Duplex.StateController
============================================================================]]--

--[[--
The StateController handles states within a display/controlmap

A state can toggle any part of a control-map on/off while a device configuration is running. They represent a separate mapping layer, independantly of the device configuration, and are especially useful when you are running out of space on the controller - or when an application does not provide you with enough flexibility. 

Adding a state is done via the special <Stage> tag - however, a state will not do anything by itself. You still need to associate the state with one or more 'triggers', buttons that share their value with the state. 

Once a state has been defined, you can begin prefixing target nodes, using the state's name as the identifier - for example, <MyState:Param>

Most nodes can be prefixed: Group, Row, Column and Param (but not SubParam). For a detailed description of all supported attributes for <State> nodes, please refer to the ControlMap class

### Examples




--]]

--==============================================================================


class 'StateController'

--------------------------------------------------------------------------------

--- Initialize the StateController class

function StateController:__init(display)
  TRACE('StateController:__init')

  --- (@{Duplex.Display})
	self.display = display

  --- (@{Duplex.Application})
  -- handles our trigger-buttons
	self.app = Application(display.process,nil,nil,"StateApplication")
  display.process._applications:insert(self.app) -- ??? is this a good idea

  --print("self.app",self.app)

  --- associative array
  --    [string] = {          -- state name/id 
  --      xarg = (table)      -- control-map attributes 
  --      active = (bool)     -- current state
  --      triggers = [
  --        param = (table)   -- control-map <Param>
  --        ui_obj = (table)  -- instance of UIButton 
  --      ],...
  --      params = (table)    -- table of control-map params
  --    },...
	self.states = {}

  --- (table) list of control-map elements 
  -- (used when initializing)
  self.registered_ids = {}

end

--------------------------------------------------------------------------------

--- interpret an incoming message, update display accordingly
-- (this method is invoked when the MessageStream receive a message)

function StateController:handle_message(msg)
  TRACE("StateController:handle_message",msg)

  local states = self:match(msg)
  for k,state in ipairs(states) do

    if (state.xarg.type == "toggle") then

      if state.xarg.match and 
        (state.xarg.match == msg.xarg.match) 
      then
        --print("got here A")
        self:toggle(state.xarg.name,msg)
      elseif (msg.xarg.type == "togglebutton") and
        ((msg.value == msg.xarg.maximum) or 
        (msg.value == msg.xarg.minimum))
      then
        --print("got here B")
        self:toggle(state.xarg.name,msg)
      elseif (msg.value == msg.xarg.maximum) then
        --print("got here C")
        self:toggle(state.xarg.name,msg)
      end

    elseif (state.xarg.type == "momentary") then

      if (msg.value == msg.xarg.maximum) then
        self:enable(state.xarg.name,msg)
      elseif (msg.value == msg.xarg.minimum) then
        self:disable(state.xarg.name,msg)
      end

    elseif (state.xarg.type == "trigger") then

      if state.xarg.match then
        if (state.xarg.match == msg.value) then
          self:enable(state.xarg.name,msg)
        else
          self:disable(state.xarg.name,msg)
        end
      elseif (msg.value == msg.xarg.maximum) then
        -- respond to "press" events
        self:enable(state.xarg.name,msg)
      end
      
    end

  end

end

--------------------------------------------------------------------------------

--- add a state 

function StateController:add_state(xarg,t)
  TRACE("StateController:add_state",xarg,t)

  -- look for trigger params when adding state
  -- (as of now, only buttons are allowed as triggers)
  local triggers = {}
  local cm = self.display.device.control_map
  for k,v in pairs(cm.patterns) do
    for k2,v2 in ipairs(v) do
      if (xarg.value == k) and
        string.find(v2.xarg.type,"button") 
      then
        local ui_obj = UIButton(self.app)
        ui_obj.group_name = v2.xarg.group_name
        ui_obj:set_pos(v2.xarg.index)
        triggers[#triggers+1] = {
          param = v2,
          ui_obj = ui_obj
        }
      end
    end
  end

  self.states[xarg.name] = {
    xarg = xarg,
    active = (xarg.active=="true") and true or false,
    triggers = triggers,
    params = {},
  }

end

--------------------------------------------------------------------------------

--- match states with message - discover if message is a trigger
-- @return table

function StateController:match(msg)
  --TRACE("StateController - match",msg)

	local matches = {}
  local msg_pattern = msg.xarg.action or msg.xarg.value

	for _,state in pairs(self.states) do
    if (msg_pattern == state.xarg.value) then
      matches[#matches+1] = state
    end
	end

	return matches

end

--------------------------------------------------------------------------------

--- called once the display has created the virtual control surface

function StateController:initialize()
  TRACE("StateController:initialize()")

  for _,view in pairs(self.registered_ids) do
    for __,state in pairs(view.xarg.state_ids) do
      self:add_view(state,view)
    end
  end

	for k,state in pairs(self.states) do
    if state.active then
      self:enable(k)
    else
      self:disable(k)
    end
	end


end

--------------------------------------------------------------------------------

--- associate a parameter with a named state

function StateController:add_view(state_id,view)
  TRACE("StateController:add_view",state_id,view,view.xarg.id)

  table.insert(self.states[state_id].params,view)

end


--------------------------------------------------------------------------------

--- toggle a named state

function StateController:toggle(state_id)
  TRACE("StateController:toggle",state_id)

  local state = self.states[state_id]
  state.active = not state.active

  if state.active then
    self:enable(state_id)
  else
    self:disable(state_id)
  end

end


--------------------------------------------------------------------------------

--- activate a named state

function StateController:enable(state_id)
  TRACE("StateController:enable",state_id)
  
  --print("StateController - #params",#self.states[state_id].params)

  local state = self.states[state_id]

  --local do_force_refresh = false
  local do_force_refresh = not state.receive_when_inactive

  -- check if state has an "exclusive" attribute set, in which
  -- case we want to turn off other states with the same value
  if state.xarg.exclusive then

    --print("iterate through states - state.xarg.exclusive",state.xarg.exclusive)
    for k,v in pairs(self.states) do     
      if (v ~= state) and 
        (v.xarg.exclusive == state.xarg.exclusive)
      then
        --print("found other state with same exclusive attribute",k,v)
        self:disable(k)
      end
    end

  end

  state.active = true

  -- iterate through associated widgets
	for _,v in pairs(state.params) do

    local widget = self.display.vb.views[v.xarg.id]
    if widget then
      local all_states_active = true
      for k2,v2 in ipairs(v.xarg.state_ids) do
        if not (self.states[v2].active) then
          all_states_active = false
        end
      end
      if all_states_active then
        -- all types (Row, Column, Group etc.)
        widget.visible = true
        if not (type(widget) == "Rack") then
          -- update control (Button etc.)
          if not (type(widget) == "MultiLineText") then
            widget.active = true  
          end
        end
      end
      --print("all_states_active,id,widget,widget.visible,widget.active",all_states_active,v.xarg.id,widget,widget.visible,widget.active)
    end

  end

  if do_force_refresh then
    -- loop through parameters associated with this state
    -- and refresh their visual appearance 
    for _,obj in pairs(self.display.ui_objects) do
      for __,param in pairs(state.params) do
        if (obj.group_name == param.xarg.group_name) then
          obj:force_refresh()
          break
        end
      end
    end
  end

  -- update trigger buttons
  local trigger_color = state.xarg.invert and
    {0x00,0x00,0x00} or {0xff,0xff,0xff}
	for _,trigger in pairs(state.triggers) do
    if trigger.param.xarg.match and 
      state.xarg.match  
    then 
      if (trigger.param.xarg.match == state.xarg.match) then
        if (type(trigger.ui_obj) == "UIButton") then
          trigger.ui_obj:set({color = trigger_color,val=true})
          trigger.ui_obj:force_refresh()
        end
      else
        --color = {0x00,0x00,0x00}
      end
    else
      if (type(trigger.ui_obj) == "UIButton") then
        trigger.ui_obj:set({color = trigger_color,val=true})
        trigger.ui_obj:force_refresh()
      end
      --print("StateController - enabled color (other)",widget.text,table.concat(widget.color,","))
    end

  end

end

--------------------------------------------------------------------------------

--- deactivate a named state

function StateController:disable(state_id)
  TRACE("StateController:disable named state",state_id)
  --print("StateController - #params",#self.states[state_id].params)

  local state = self.states[state_id]

  state.active = false
	for _,v in pairs(state.params) do
    local widget = self.display.vb.views[v.xarg.id]
    if widget then
      widget.visible = not (state.xarg.hide_when_inactive) and true or false
      if not (type(widget) == "Rack") and
        not (type(widget) == "MultiLineText")
      then
        widget.active = not (state.xarg.disable_when_inactive) and true or false
      end
    end
  end

  local trigger_color = state.xarg.invert and
    {0xff,0xff,0xff} or {0x00,0x00,0x00} 
	for _,trigger in pairs(state.triggers) do
    --print("trigger.ui_obj",trigger.ui_obj,type(trigger.ui_obj),(trigger.ui_obj == "UIButton"))
    if (type(trigger.ui_obj) == "UIButton") then
      trigger.ui_obj:set({color = trigger_color,val=false})
      trigger.ui_obj:force_refresh()
    end
  end

end

