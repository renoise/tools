--[[============================================================================
-- Duplex.StateController
============================================================================]]--

--[[--
The StateController handles states within a display/controlmap

A state can toggle any part of a control-map on/off while a device configuration is running. They represent a separate mapping layer, independantly of the device configuration, and are especially useful when you are running out of space on the controller - or when an application does not provide you with enough flexibility. 

Adding a state is done via the special <Stage> tag - however, a state will not do anything by itself. You still need to associate the state with one or more 'triggers', buttons that share their value with the state. 

Once a state has been defined, you can begin prefixing target nodes, using the state's name as the identifier - for example, <MyState:Param>

Most nodes can be prefixed: Group, Row, Column and Param (but not SubParam). For a detailed description of all supported attributes for <State> nodes, please refer to the ControlMap class

### Changes

  0.99.3
    - First release

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
  --        [1] = {
  --          xarg = (table)        
  --        }
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
  --print("states",rprint(states))

  for k,state in ipairs(states) do

    if (state.xarg.type == "toggle") then

      if state.xarg.match and 
        (state.xarg.match == msg.xarg.match) 
      then
        self:toggle(state.xarg.name,msg)
      elseif (msg.xarg.type == "togglebutton") and
        ((msg.value == msg.xarg.maximum) or 
        (msg.value == msg.xarg.minimum))
      then
        self:toggle(state.xarg.name,msg)
      elseif (msg.value == msg.xarg.maximum) then
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
      --print("xarg.action,xarg.value,k",xarg.action,xarg.value,k)
      if ((xarg.action == k) or (xarg.value == k))
      and
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
  local msg_pattern = msg.xarg.value or msg.xarg.action

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
-- @param state_id (string) unique name/id for the state
-- @param view (table) control-map parameter

function StateController:add_view(state_id,view)
  TRACE("StateController:add_view",state_id,view)

  if self.states[state_id] then
    table.insert(self.states[state_id].params,view)
  end

end


--------------------------------------------------------------------------------

--- toggle a named state
-- @param state_id (string) unique name/id for the state

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
-- @param state_id (string) unique name/id for the state

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

  local cm = self.display.device.control_map
  local xargs = {}

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
        if v.xarg.group_name then
          xargs[v.xarg.group_name] = v.xarg
        end
        if not (type(widget) == "Rack") then
          -- update control (Button etc.)
          if not (type(widget) == "MultiLineText") then
            widget.active = true  
          end
        end
        --print("state enable - id,widget,value,name,visible",v.xarg.id,v.xarg.value,v.xarg.name,widget,widget.visible)

      end
    end

    local widget = self.display.vb.views[v.xarg.id]

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
    local update_trigger = false
    if trigger.param.xarg.match and 
      state.xarg.match  
    then 
      if (trigger.param.xarg.match == state.xarg.match) then
        update_trigger = true
      end
    else
      update_trigger = true
    end
    if update_trigger then
      if (type(trigger.ui_obj) == "UIButton") then
        local trigger_text = state.xarg.text and 
          state.xarg.text or trigger.param.xarg.text
          --trigger.ui_obj.palette.foreground.text
        self:update_trigger(trigger.ui_obj,trigger_color,trigger_text,false)
      end
    end

  end

end

--------------------------------------------------------------------------------

--- deactivate a named state
-- @param state_id (string) unique name/id for the state

function StateController:disable(state_id)
  TRACE("StateController:disable",state_id)
  --print("StateController - #params",#self.states[state_id].params)

  local state = self.states[state_id]
  local cm = self.display.device.control_map
  local xargs = {}

  state.active = false
	for _,v in pairs(state.params) do
    local widget = self.display.vb.views[v.xarg.id]
    if widget then
      widget.visible = not (state.xarg.hide_when_inactive) and true or false
      --print("v.xarg.group_name/v.xarg.value",v.xarg.group_name,v.xarg.value)
      if v.xarg.group_name then
        xargs[v.xarg.group_name] = v.xarg
      end
      if not (type(widget) == "Rack") and
        not (type(widget) == "MultiLineText")
      then
        widget.active = not (state.xarg.disable_when_inactive) and true or false
      end
      --print("state disable - id,widget,value,name,visible",v.xarg.id,v.xarg.value,v.xarg.name,widget,widget.visible)

    end
  end

	for _,trigger in pairs(state.triggers) do
    if (type(trigger.ui_obj) == "UIButton") then
      local trigger_color = state.xarg.invert and
        {0xff,0xff,0xff} or {0x00,0x00,0x00} 
      local trigger_text = state.xarg.text and 
        state.xarg.text or trigger.param.xarg.text
        --trigger.ui_obj.palette.foreground.text
      self:update_trigger(trigger.ui_obj,trigger_color,trigger_text,false)
    end
  end



end

--------------------------------------------------------------------------------

--- update the display of a trigger-button
-- @param ui_obj (@{Duplex.UIButton})
-- @color (table) 8-bit r/g/b values
-- @text (string) button or label text 
-- @value (number or table) as defined by the UIComponent

function StateController:update_trigger(ui_obj,color,text,val)
  TRACE("StateController:update_trigger(ui_obj,color,text,val)",ui_obj,color,text,val)

  assert(ui_obj,"Error: trigger has no UIComponent")
  ui_obj:set({color=color,text=text,val=val})
  ui_obj:force_refresh()
  --print("*** update_trigger - ui_obj.palette.text",ui_obj.palette.text)

end

