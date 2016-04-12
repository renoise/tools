--[[============================================================================
-- xRulesUIAction
============================================================================]]--

--[[--

  This is a supporting class for xRulesUI

--]]

--==============================================================================


class 'xRulesUIAction'

--------------------------------------------------------------------------------

function xRulesUIAction:__init(...)

	local args = xLib.unpack_args(...)

  self.vb = args.vb
  self.ui = args.ui
  self.xrules = args.ui.xrules
  self.editor = args.editor
  self.xrule = args.xrule

  self.row_idx = nil
  self.key = nil
  self.value = nil

  self.str_syntax_error = nil

  self.vb_ruleset_routing = nil
  self.vb_rule_routing = nil

end

--------------------------------------------------------------------------------
-- @param row_idx (int)
-- @param def (table), the definition
-- @param label (string), shown on the left-hand side
-- @return view

function xRulesUIAction:build_action_row(row_idx,def,label)

  self.row_idx = row_idx
  for k,v in pairs(def) do
    self.key = k
    self.value = v
  end

  local vb = self.vb

  local view = vb:row{
    vb:text{
      width = xRulesUI.RULE_MARGIN_W - ((self.row_idx > 1) and 20 or 0),
      --width = xRulesUI.RULE_MARGIN_W,
      text = label,
      align = "right",
      font = "italic",
    },
    vb:space{
      width = xRulesUI.MARGIN,
    },
    vb:button{
      visible = (self.row_idx > 1) and true or false,
      tooltip = "Insert new action here",
      text = xRulesUI.TXT_ADD,
      notifier = function()
        self.editor:add_action(self.row_idx)
      end
    },
  }

  -- 'view configurations' for each action
  local action_views = {
    [xRule.ACTIONS.OUTPUT_MESSAGE] = function(k,v)
      local args = {}
      return self:create_row(k,v,{
        show_output_message = true,
        show_label = true,
        label_text = "to",
      })
    end,
    [xRule.ACTIONS.ROUTE_MESSAGE] = function(k,v)
      local args = {}
      return self:create_row(k,v,{
        show_route_message = true,
        show_label = true,
        label_text = "to",
      })
    end,
    [xRule.ACTIONS.SET_INSTRUMENT] = function(k,v)
      return self:create_row(k,v,{
        show_valuebox = true,
        show_label = true,
        label_text = "to",
      })
    end,
    [xRule.ACTIONS.SET_TRACK] = function(k,v)
      return self:create_row(k,v,{
        show_valuebox = true,
        show_label = true,
        label_text = "to",
      })
    end,
    [xRule.ACTIONS.SET_PORT_NAME] = function(k,v)
      return self:create_row(k,v,{
        show_popup = true,
        popup_items = self.editor:inject_port_name(renoise.Midi.available_output_devices(),v),
        show_label = true,
        label_text = "to",
      })
    end,
    [xRule.ACTIONS.SET_DEVICE_NAME] = function(k,v)
      return self:create_row(k,v,{
        show_popup = true,
        popup_items = self.ui:get_osc_device_names(),
        show_label = true,
        label_text = "to",
      })
    end,
    [xRule.ACTIONS.SET_MESSAGE_TYPE] = function(k,v)
      self.editor.last_msg_type = v
      --print(">>> action: last_msg_type",self.editor.last_msg_type)
      return self:create_row(k,v,{
        show_popup = true,
        popup_items = xRulesUI.TYPE_ITEMS,
        show_label = true,
        label_text = "to",
      })
    end,
    [xRule.ACTIONS.SET_CHANNEL] = function(k,v)
      return self:create_row(k,v,{
        show_valuebox = true,
        show_label = true,
        label_text = "to",
      })
    end,
    [xRule.ACTIONS.SET_VALUE] = function(k,v,val_idx)
      
      if (self.xrule.osc_pattern.complete) then
        -- osc: use the specified value-type
        --print("*** self.xrule.osc_pattern.pattern_in",self.xrule.osc_pattern.pattern_in)
        --print("*** self.xrule.osc_pattern.arguments",rprint(self.xrule.osc_pattern.arguments))
        local arg = self.xrule.osc_pattern.arguments[val_idx]
        --print("*** arg",arg)
        if (arg.tag == xOscValue.TAG.STRING) then
          return self:create_row(k,v,{
            show_value_idx = val_idx,
            show_textfield = true,
            show_label = true,
            label_text = "to",
          })    
        elseif (arg.tag == xOscValue.TAG.FLOAT) 
          or (arg.tag == xOscValue.TAG.NUMBER)         
        then
          return self:create_row(k,v,{
            show_value_idx = val_idx,
            show_valuefield = true,
            show_label = true,
            label_text = "to",
          })    
        elseif (arg.tag == xOscValue.TAG.INTEGER) then
          return self:create_row(k,v,{
            show_value_idx = val_idx,
            show_valuebox = true,
            show_label = true,
            label_text = "to",
          })    
        else
          error("Unsupported OSC tag")
        end
        
      else
        -- midi: always a positive integer
        local val_max = 
          xRulesUIEditor.get_maximum_value(self.editor.last_msg_type,val_idx)
          
        local fn_tostring,fn_tonumber = 
          xRulesUIEditor.get_custom_converters(self.editor.last_msg_type,val_idx)

        return self:create_row(k,v,{
          show_value_idx = val_idx,
          show_valuebox = true,
          show_label = true,
          value_min = 0,
          value_max = val_max,
          label_text = "to",
          fn_tostring = fn_tostring,
          fn_tonumber = fn_tonumber,
        })    

      end

    end,
    [xRule.ACTIONS.INCREASE_INSTRUMENT] = function(k,v)
      return self:create_row(k,v,{
        show_valuebox = true,
        show_label = true,
        label_text = "by",
      })    
    end,
    [xRule.ACTIONS.INCREASE_TRACK] = function(k,v)
      return self:create_row(k,v,{
        show_valuebox = true,
        show_label = true,
        label_text = "by",
      })        
    end,
    [xRule.ACTIONS.INCREASE_CHANNEL] = function(k,v)
      return self:create_row(k,v,{
        show_valuebox = true,
        show_label = true,
        label_text = "by",
      })        
    end,
    [xRule.ACTIONS.INCREASE_VALUE] = function(k,v,val_idx)
      return self:create_row(k,v,{
        show_value_idx = val_idx,
        show_valuebox = true,
        show_label = true,
        label_text = "by",
      })        
    end,
    [xRule.ACTIONS.DECREASE_INSTRUMENT] = function(k,v)
      return self:create_row(k,v,{
        show_valuebox = true,
        show_label = true,
        label_text = "by",
      })        
    end,
    [xRule.ACTIONS.DECREASE_TRACK] = function(k,v)
      return self:create_row(k,v,{
        show_valuebox = true,
        show_label = true,
        label_text = "by",
      })        
    end,
    [xRule.ACTIONS.DECREASE_CHANNEL] = function(k,v)
      return self:create_row(k,v,{
        show_valuebox = true,
        show_label = true,
        label_text = "by",
      })        
    end,
    [xRule.ACTIONS.DECREASE_VALUE] = function(k,v,val_idx)
      return self:create_row(k,v,{
        show_value_idx = val_idx,
        show_valuebox = true,
        show_label = true,
        label_text = "by",
      })        
    end,
    [xRule.ACTIONS.CALL_FUNCTION] = function(k,v)
      local view = self:create_row(k,v,{
        show_function = true,
      })
      -- immediately test syntax 
      if (type(v) == "string") then
        self:change_function_value(v)
      end
      return view
    end,
  }

  --print(">>> get_osc_device_names",rprint(self.ui:get_osc_device_names()))

  local val_idx = xRule.get_value_index(self.key)
  if (string.find(self.key,"set_value",nil,true)) then
    view:add_child(action_views["set_value"]("set_value",self.value,val_idx))
  elseif (string.find(self.key,"increase_value",nil,true)) then
    view:add_child(action_views["increase_value"]("increase_value",self.value,val_idx))
  elseif (string.find(self.key,"decrease_value",nil,true)) then
    view:add_child(action_views["decrease_value"]("decrease_value",self.value,val_idx))
  else
    if not (action_views[self.key]) then
      error("Unrecognized action")
    else
      view:add_child(action_views[self.key](self.key,self.value))
    end
  end

  return view

end

--------------------------------------------------------------------------------
-- build row using the supplied arguments
-- @param k, key
-- @param v, value
-- @param args - show/hide specific parts 
--  show_value_idx = integer
--  show_output_message = boolean
--  show_route_message = boolean
--  show_popup = boolean (for enumerated string values)
--  show_valuebox = boolean (for integer values)
--  show_valuefield = boolean (for floating points)
--  show_textfield = boolean (for text input)
--  popup_items = table
--  show_label = boolean
--  label_text = string
--  value_min = int
--  value_max = int
--  fn_tostring = function (for valuebox/valuefield)
--  fn_tonumber = function (for valuebox/valuefield)

function xRulesUIAction:create_row(k,v,args)
  --print("create_row",k,v,args)

  local vb = self.vb
  if not args then
    args = {}
  end

  -- ensure there is content for the popup
  args.popup_items = table.is_empty(args.popup_items) and {} or args.popup_items

  self.vb_status_elm = vb:text{
    text = "",
    align = "right",
  }

  self.vb_action_value_select = vb:popup{
    visible = (args.show_value_idx) and true or false,
    items = self.editor:add_context(xRule.VALUES),
    height = xRulesUI.CONTROL_H,
    width = xRulesUI.VALUE_SELECT_W,
    value = args.show_value_idx,
    notifier = function(idx)
      -- change selected value
      -- e.g. "set_value_1" -> "set_value_2"
      local action_idx = self.vb_action_popup.items[self.vb_action_popup.value]
      --print("action_idx",action_idx)
      if (action_idx == xRule.ACTIONS.SET_VALUE) 
        or (action_idx == xRule.ACTIONS.INCREASE_VALUE) 
        or (action_idx == xRule.ACTIONS.DECREASE_VALUE)
      then
        self:change_action_key(("%s_%x"):format(action_idx,self.vb_action_value_select.value))
      end

    end,
  }

  self.vb_action_value_label = vb:text{
    visible = (args.show_value_idx) and true or false,
    text = xRulesUI.TXT_ARROW_LEFT,
    width = 18,
  }

  self.vb_action_popup = vb:popup{
    --items = self.contextual_action_items,
    items = xRulesUI.ACTION_ITEMS,
    value = table.find(xRulesUI.ACTION_ITEMS,k),
    height = xRulesUI.CONTROL_H,
    width = xRulesUI.ASPECTS_W,
    notifier = function(idx)
      local val = self.vb_action_popup.items[idx]
      --print("val",val)
      -- change to the selected action
      if (val == "set_value") 
        or (val == "increase_value")
        or (val == "decrease_value")
      then
        -- value actions need the index 
        local popup = self.vb_action_value_select
        --print("popup",popup,#popup.items,popup.value)
        local val_idx = popup.value
        if val_idx then
          val = ("%s_%d"):format(val,val_idx)
        end
      end
      --print("val",val)
      --print("xRule.ACTIONS_FULL",rprint(xRule.ACTIONS_FULL))
      self:change_action_key(xRule.ACTIONS_FULL[string.upper(val)])
    end
  }

  --print("args.popup_items",rprint(args.popup_items))
  self.vb_value_popup = vb:popup{
    visible = args.show_popup or false,
    items = args.popup_items,
    value = table.find(args.popup_items,v) or 1,
    width = xRulesUI.VALUE_POPUP_W,
    height = xRulesUI.CONTROL_H,
    notifier = function(idx)
      -- find the string value
      local str_value = self.vb_value_popup.items[idx]
      self:change_value(str_value)
      -- if we changed message type, rebuild UI
      -- (as contextual values might have changed)
      local action = self.vb_action_popup.items[self.vb_action_popup.value]
      if (action == xRule.ACTIONS.SET_MESSAGE_TYPE) then
        self.ui._build_rule_requested = true
      end
    end
  }

  self.vb_value_valuefield = vb:valuefield{
    visible = args.show_valuefield or false,
    min = args.value_min or -99999,
    max = args.value_max or 99999,
    tostring = args.fn_tostring,
    tonumber = args.fn_tonumber,
    value = type(v) == "number" and v or 0,
    --width = xRulesUI.VALUE_POPUP_W,
    height = xRulesUI.CONTROL_H,
    notifier = function(val)
      self:change_value(val)
    end
  }

  -- prepare routings --

  if args.show_route_message then

    local change_routing = function()
      local ruleset_name = self.vb_ruleset_routing.items[self.vb_ruleset_routing.value]
      local rule_name = self.vb_rule_routing.items[self.vb_rule_routing.value]
      --print(">>> change_routing - ruleset_name,rule_name",ruleset_name,rule_name)
      self:change_value(("%s:%s"):format(ruleset_name,rule_name))
    end

    local routing_values = xLib.split(v,":")
    local ruleset_routings = self:gather_ruleset_routings()
    local rule_routings = self:gather_rule_routings()
    --print(">>> routing_values",rprint(routing_values))

    self.vb_ruleset_routing = vb:popup{
      items = ruleset_routings,
      value = table.find(ruleset_routings,routing_values[1]) or 1,
      width = xRulesUI.VALUE_SELECT_W,
      height = xRulesUI.CONTROL_H,
      notifier = function()
        change_routing()
      end
    }

    self.vb_rule_routing = vb:popup{
      items = rule_routings,
      value = table.find(rule_routings,routing_values[2]) or 1,
      width = xRulesUI.VALUE_SELECT_W,
      height = xRulesUI.CONTROL_H,
      notifier = function()
        change_routing()
      end
    }

  end

  -- build the view --

  return vb:column{
    vb:horizontal_aligner{
      mode = "justify",
      -- (left side)
      vb:row{
        -- @ALL
        self.vb_action_popup,
        -- @FUNCTION
        vb:row{
          visible = args.show_function or false,
          vb:row{
            vb:checkbox{
              visible = false,
              notifier = function()
                if self.str_syntax_error then
                  renoise.app():show_warning(self.str_syntax_error)
                end
              end
            },
            self.vb_status_elm,
          },
        },
        -- @VALUE_SELECT
        self.vb_action_value_label,
        self.vb_action_value_select,
        -- @SET @INCREASE @DECREASE
        vb:text{
          visible = args.show_label or false,
          text = args.label_text or "",
        },
        -- @SET @INCREASE @DECREASE
        vb:valuebox{
          visible = args.show_valuebox or false,
          value = type(v) == "number" and v or 0,
          min = args.value_min or -99999,
          max = args.value_max or 99999,
          tostring = args.fn_tostring,
          tonumber = args.fn_tonumber,
          height = xRulesUI.CONTROL_H,
          notifier = function(val)
            self:change_value(val)
          end
        },
        vb:row{
          style = "plain",
          self.vb_value_valuefield,
        },
        self.vb_value_popup,
        vb:textfield{
          visible = args.show_textfield or false,
          value = type(v) == "string" and v or "",
          height = xRulesUI.CONTROL_H,
          notifier = function(val)
            self:change_value(val)
          end
        },
        -- @OUTPUT_MESSAGE
        vb:row{
          visible = args.show_output_message or false,
          vb:popup{
            items = xRulesUI.OUTPUT_ITEMS,
            value = table.find(xRulesUI.OUTPUT_ITEMS,v),
            width = xRulesUI.VALUE_SELECT_W,
            height = xRulesUI.CONTROL_H,
            notifier = function(val)
              self:change_value(xRulesUI.OUTPUT_ITEMS[val])
            end
          },
        },  
        -- @ROUTE_MESSAGE
        vb:row{
          visible = args.show_route_message or false,
          self.vb_ruleset_routing,
          self.vb_rule_routing,
        },  
      },
      -- (right side)
      vb:button{
        text = xRulesUI.TXT_CLOSE,
        width = xRulesUI.CONTROL_SM,
        height = xRulesUI.CONTROL_SM,
        notifier = function()
          self:remove_action()
        end
      },

    },
    -- @FUNCTION
    vb:multiline_textfield{
      visible = args.show_function or false,
      text = type(v) == "string" and v or 
        "-- enter lua code here, e.g:\n-- velocity = math.random(0,127)",
      font = "mono",
      width = xRulesUI.TEXTAREA_W,
      height = xRulesUI.TEXTAREA_H,
      notifier = function(val)
        self:change_function_value(val)
      end
    },
  }

end

--------------------------------------------------------------------------------
-- @param action, xRule.ACTIONS

function xRulesUIAction:change_action_key(action)

  local xrule = self.xrule
  local new_action = {}
  for k,v in pairs(xrule.actions[self.row_idx]) do
    new_action[action] = xRulesUIEditor.change_value_assist(v,action,"action")
  end
  --print(">>> existing action",rprint(xrule.actions[self.row_idx]))
  --print(">>> new_action",rprint(new_action))
  xrule.actions[self.row_idx] = new_action
  xrule:compile()
  self.ui._build_rule_requested = true

end

--------------------------------------------------------------------------------

function xRulesUIAction:change_value(val)

  local xrule = self.xrule
  for k,v in pairs(xrule.actions[self.row_idx]) do
    xrule.actions[self.row_idx][k] = val
  end
  local success,err = xrule:compile()
  if err then
    LOG(err)
  end

end

--------------------------------------------------------------------------------

function xRulesUIAction:change_function_value(val)

  local xrule = self.xrule
  local success
  success,self.str_syntax_error = xrule.sandbox:test_syntax(val)
  if success then
    val = string.gsub(val,'"','\"')
    self:change_value(val)
    self.vb_status_elm.text = "✔ Syntax is OK"
  else
    self.vb_status_elm.text = "⚠ Syntax error"
  end

end

--------------------------------------------------------------------------------

function xRulesUIAction:remove_action()

  local str_msg = "Are you sure you want to remove this action"
  local choice = renoise.app():show_prompt("Remove action", str_msg, {"OK","Cancel"})
  if (choice == "Cancel") then
    return
  end
    
  local xrule = self.xrule
  table.remove(xrule.actions,self.row_idx)
  local success,err = xrule:compile()
  if err then
    LOG(err)
  end
  self.ui._build_rule_requested = true

end

--------------------------------------------------------------------------------
-- list ruleset names *after* the current one
-- @return table<string>

function xRulesUIAction:gather_ruleset_routings()
  local rslt = {xRuleset.CURRENT_RULESET}
  for k = self.xrules.selected_ruleset_index+1,#self.xrules.rulesets do
    local ruleset = self.xrules.rulesets[k]
    table.insert(rslt,ruleset.name)
  end

  return rslt

end

--------------------------------------------------------------------------------
-- list rule names *after* the current one
-- @return table<string>

function xRulesUIAction:gather_rule_routings()

  local ruleset = self.xrules.selected_ruleset
  local rslt = {"Current rule (N/A)"}
  for k = ruleset.selected_rule_index+1,#ruleset.rules do
    local rule = ruleset.rules[k]
    local rule_name = ruleset:get_rule_name(k)
    table.insert(rslt,rule_name)
  end

  return rslt

end

