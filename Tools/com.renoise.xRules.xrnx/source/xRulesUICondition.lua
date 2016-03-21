--[[============================================================================
-- xRulesUICondition
============================================================================]]--

--[[--

  This is a supporting class for xRulesUI

--]]

--==============================================================================


class 'xRulesUICondition'

--------------------------------------------------------------------------------

function xRulesUICondition:__init(...)

	local args = xLib.unpack_args(...)

  self.vb = args.vb
  self.ui = args.ui
  self.xrule = args.xrule
  self.editor = args.editor

  
  self.row_idx = nil
  self.aspect = nil
  self.operator = nil
  self.value = nil 

  self.vb_status_elm = nil
  self.str_syntax_error = nil

end

--------------------------------------------------------------------------------
-- @param def (table), condition definition, i.e: 
--  track_index = {
--    less_than = 3,
--  },
-- @return view

function xRulesUICondition:build_condition_row(row_idx,def,logic_label)
  TRACE("xRulesUICondition:build_condition_row(row_idx,def,logic_label)",row_idx,def,logic_label)

  self.row_idx = row_idx

  local vb = self.vb

  --local aspect,operator,value
  for k,v in pairs(def) do
    self.aspect = k
    for k2,v2 in pairs(v) do
      self.operator = k2
      self.value = v2
    end
  end


  local vb_remove_condition_bt = vb:button{
    tooltip = "Remove this condition",
    width = xRulesUI.CONTROL_SM,
    height = xRulesUI.CONTROL_SM,
    text = xRulesUI.TXT_CLOSE,
    notifier = function(idx)
      self:remove_condition()
    end
  }

  --print("self.ui",self.ui)
  local vb_aspect_chooser = vb:popup{
    tooltip = "Choose a condition (aspect)",
    items = self.editor:add_context(xRulesUI.ASPECT_ITEMS),
    value = table.find(xRulesUI.ASPECT_ITEMS,self.aspect),
    height = xRulesUI.CONTROL_H,
    width = xRulesUI.ASPECTS_W,
    notifier = function(idx)
      self:change_aspect(xRulesUI.ASPECT_ITEMS[idx])
    end
  }

  local create_operator_chooser = function(items,operator)
    return vb:popup{
      tooltip = "Choose an operator",
      items = items,
      value = table.find(items,operator),
      height = xRulesUI.CONTROL_H,
      width = xRulesUI.OPERATOR_W,
      notifier = function(idx)
        self:change_operator(items[idx])
      end
    }
  end

  self.vb_status_elm = vb:text{
    text = "",
    align = "right",
  }

  -- for aspects that support only equal/not equal operators
  local create_type_row = function(items)
    TRACE("create_type_row - self.last_msg_type",self.editor.last_msg_type)

    -- refactor into xRule "fix"
    local valid_operator = self:get_valid_operator(self.aspect,self.operator)
    if (self.operator ~= valid_operator) then
      LOG("*** invalid operator - (fix) the rule",self.operator,valid_operator)
      self:change_operator(valid_operator,true)
    end

    return vb:row{
      vb_aspect_chooser,
      create_operator_chooser(xRulesUI.TYPE_OPERATOR_ITEMS,valid_operator),
      vb:popup{
        tooltip = "Choose a value",
        items = items,
        value = table.find(items,tostring(self.value)),
        height = xRulesUI.CONTROL_H,
        width = xRulesUI.VALUE_POPUP_W,
        notifier = function(idx)
          self:change_value(items[idx])
        end
      },
      vb_remove_condition_bt,
    }

  end

  -- for aspects that support the full range of operators
  local create_value_row = function(items,val_min,val_max)
    TRACE("create_value_row",items,val_min,val_max)

    local use_popup = type(items)=="table" 
    local val = self.value
    local value_popup_index = use_popup and table.find(items,tostring(val)) or 1
    local is_between_operator = (self.operator == xRule.OPERATOR.BETWEEN)
    local value_popup_items = use_popup and items or nil
    local popup_visible = use_popup and not is_between_operator
    local valuebox_visible = not use_popup or is_between_operator
    local valuebox2_visible = is_between_operator

    -- make sure valuebox values are the right type
    val = self:change_operator_assist(val,self.operator)

    if (type(val)=="number") then
      xLib.clamp_value(val,val_min,val_max)
    end

    -- custom number/string converters 
    local val_idx = xRule.get_value_index(self.aspect)
    local fn_tostring,fn_tonumber = 
      xRulesUIEditor.get_custom_converters(self.editor.last_msg_type,val_idx)


    self.vb_condition_valuebox1 = vb:valuebox{
      tooltip = "Specify a value",
      value = is_between_operator and val[1] or val,
      min = val_min,
      max = val_max,
      tostring = fn_tostring,
      tonumber = fn_tonumber,
      visible = valuebox_visible,
      height = xRulesUI.CONTROL_H,
      width = xRulesUI.VALUEBOX_W,
      notifier = function(val)
        self:change_value(val,is_between_operator and 1 or nil,true)
      end
    }

    self.vb_condition_valuebox2 = vb:valuebox{
      tooltip = "Specify a value",
      visible = valuebox2_visible,
      value = is_between_operator and val[2] or val,
      min = val_min,
      max = val_max,
      tostring = fn_tostring,
      tonumber = fn_tonumber,
      height = xRulesUI.CONTROL_H,
      width = xRulesUI.VALUEBOX_W,
      notifier = function(val)
        self:change_value(val,is_between_operator and 2 or nil,true)
      end
    }

    return vb:row{
      vb_aspect_chooser,
      create_operator_chooser(xRulesUI.VALUE_OPERATOR_ITEMS,self.operator),
      vb:popup{
        tooltip = "Specify a value",
        items = value_popup_items,
        value = value_popup_index,
        visible = popup_visible,
        height = xRulesUI.CONTROL_H,
        width = xRulesUI.VALUE_POPUP_W,
        notifier = function(idx)
          self:change_value(items[idx])
        end
      },
      self.vb_condition_valuebox1,
      vb:text{
        visible = valuebox2_visible,
        text = " -"
      },
      self.vb_condition_valuebox2,
      vb_remove_condition_bt,

    }
  end

  -- special case: sysex requires a separate layout
  local create_sysex_row = function()
    --print("create_sysex_row")

    local valid_operator = self:get_valid_operator(self.aspect,self.operator)

    return vb:column{
      vb:row{
        vb_aspect_chooser,
        create_operator_chooser(xRulesUI.TYPE_OPERATOR_ITEMS,valid_operator),
        self.vb_status_elm,
      },
      vb:row{
        vb:multiline_textfield{
          text = tostring(self.value),
          width = xRulesUI.TEXTAREA_W,
          notifier = function(val)
            self:change_sysex_value(val)
          end
        }
      },
    }

  end


  local aspect_views = {
    [xRule.ASPECT.PORT_NAME] = function()
      local devices = self.editor:inject_port_name(renoise.Midi.available_input_devices(),self.value)
      return create_type_row(devices)    
    end,
    [xRule.ASPECT.DEVICE_NAME] = function()
      return create_type_row(self.ui:get_osc_device_names())    
    end,
    [xRule.ASPECT.CHANNEL] = function()
      local val_min = 1
      local val_max = 16
      return create_value_row(xRulesUI.ASPECT_DEFAULTS,val_min,val_max)
    end,
    [xRule.ASPECT.TRACK_INDEX] = function()
      local val_min = xRule.ASPECT_DEFAULTS.TRACK_INDEX[1]
      local val_max = xRule.ASPECT_DEFAULTS.TRACK_INDEX[#xRule.ASPECT_DEFAULTS.TRACK_INDEX]
      return create_value_row(xRulesUI.ASPECT_DEFAULT_TRACKS,val_min,val_max)
    end,
    [xRule.ASPECT.INSTRUMENT_INDEX] = function()
      local val_min = xRule.ASPECT_DEFAULTS.INSTRUMENT_INDEX[1]
      local val_max = xRule.ASPECT_DEFAULTS.INSTRUMENT_INDEX[#xRule.ASPECT_DEFAULTS.INSTRUMENT_INDEX]
      return create_value_row(xRulesUI.ASPECT_DEFAULT_INSTRUMENTS,val_min,val_max)
    end,
    [xRule.ASPECT.MESSAGE_TYPE] = function()
      return create_type_row(xRulesUI.TYPE_ITEMS)    
    end,
    [xRule.ASPECT.SYSEX] = function()
      return create_sysex_row()    
    end,
  }

  -- build active values, assign default value
  if self.editor.active_value_count then
    for k = 1, self.editor.active_value_count do
      local str_label = ("VALUE_%X"):format(k)
      --print("str_label",str_label)
      aspect_views[xRule.ASPECT[str_label]] = function()
        -- TODO assign min/max based on message context
        local val_min = 0
        local val_max = 16383
        return create_value_row(xRule.ASPECT_DEFAULTS[str_label],val_min,val_max)
      end
    end
  end

  if aspect_views[self.aspect] then

    local view = vb:row{
      vb:row{
        vb:space{
          width = xRulesUI.MARGIN_SM,
        },
        tooltip = "Click to toggle between AND/OR mode",
        vb:checkbox{
          visible = false,
          notifier = function(val)
            self:change_logic()
          end
        },
        vb:text{
          --width = xRulesUI.RULE_MARGIN_W - ((row_idx > 1) and 20 or 0),
          width = xRulesUI.RULE_MARGIN_W - ((row_idx > 1) and 20 or 0),
          text = logic_label,
          align = "right",
          font = "italic",
        },
        vb:space{
          width = xRulesUI.MARGIN_SM,
        },
        vb:button{
          visible = (row_idx > 1) and true or false,
          tooltip = "Insert new condition here",
          text = xRulesUI.TXT_ADD,
          notifier = function()
            self.editor:add_condition(row_idx)
          end
        },
      },
      aspect_views[self.aspect]()
    }

    -- provide context, depending on message type
    if (self.aspect == xRule.ASPECT.MESSAGE_TYPE) then
      self.editor.last_msg_type = self.value
      --print(">>> last_msg_type",self.editor.last_msg_type)
    end 

    return view
  end

end

--------------------------------------------------------------------------------
-- change logic: update, rebuild rule

function xRulesUICondition:change_logic()
  TRACE("xRulesUICondition:change_logic()")

  local xrule = self.xrule
  -- any logic would be defined in the previous entry
  local prev_condition = xrule.conditions[self.row_idx-1]
  if not prev_condition then
    return
  end

  if (#prev_condition == 1) then
    -- remove the statement 
    table.remove(xrule.conditions,self.row_idx-1)
  else
    table.insert(xrule.conditions,self.row_idx,{
      xRule.LOGIC.OR
    })
  end
  local success,err = xrule:compile()
  if err then
    LOG(err)
  end
  self.ui._build_rule_requested = true

end

--------------------------------------------------------------------------------
-- always use a supported operator
-- e.g. MESSAGE_TYPE does not support "less than"

function xRulesUICondition:get_valid_operator(aspect,operator) 
  TRACE("xRulesUICondition:get_valid_operator(aspect,operator)",aspect,operator)

  if table.find(xRule.ASPECT_TYPE_OPERATORS,aspect) and
    not table.find(xRule.TYPE_OPERATORS,operator)
  then
    operator = xRule.OPERATOR.EQUAL_TO
  end
  return operator
end

--------------------------------------------------------------------------------
-- maintain value after the operator has changed
-- @param value, vararg
-- @param operator, xRule.OPERATOR

function xRulesUICondition:change_operator_assist(value,operator)
  TRACE("xRulesUICondition:change_operator_assist(value,operator)",value,operator)

  --print("value",rprint(value))

  if (type(value) ~= "table") 
    and (operator == xRule.OPERATOR.BETWEEN)
  then
    -- create table
    value = {value,value}
  elseif (type(value) == "table")
    and (operator ~= xRule.OPERATOR.BETWEEN)
  then
    -- reduce to single value 
    value = value[1]
  end
  --print("change_operator_assist - resulting value",value,type(value))
  return value
end

--------------------------------------------------------------------------------
-- change aspect: update, rebuild rule

function xRulesUICondition:change_aspect(new_aspect)
  TRACE("xRulesUICondition:change_aspect(new_aspect)",new_aspect)

  local xrule = self.xrule
  local new_condition = {[new_aspect] = {}}
  for k,v in pairs(xrule.conditions[self.row_idx]) do
    for k2,v2 in pairs(v) do
      -- apply default values 
      local value = v2
      local defaults
      -- special case: always pull a fresh list for OSC/MIDI devices
      if (new_aspect == "device_name") then
        defaults = self.ui:get_osc_device_names()
      elseif (new_aspect == "port_name") then
        defaults = renoise.Midi.available_input_devices()
      else
        defaults = xRule.ASPECT_DEFAULTS[string.upper(new_aspect)]
      end
      local default = (type(defaults) == "table") and defaults[1] or defaults
      -- use a supported operator
      local operator = self:get_valid_operator(new_aspect,k2)
      default = self:change_operator_assist(default,operator)
      -- done
      new_condition[new_aspect][operator] = default
    end
  end
  --print("*** new_condition",rprint(new_condition))
  xrule.conditions[self.row_idx] = new_condition
  local success,err = xrule:compile()
  if err then
    LOG(err)
  end
  self.ui._build_rule_requested = true

end

--------------------------------------------------------------------------------
-- change operator: update, rebuild rule
-- @param new_operator, xRule.OPERATOR
-- @param only_set: do not compile, build

function xRulesUICondition:change_operator(new_operator,only_set)
  TRACE("xRulesUICondition:change_operator(new_operator,only_set)",new_operator,only_set)

  local xrule = self.xrule
  local new_condition = {}
  for k,v in pairs(xrule.conditions[self.row_idx]) do
    new_condition[k] = {}
    for k2,v2 in pairs(v) do
      v2 = self:change_operator_assist(v2,new_operator)
      new_condition[k][new_operator] = v2
    end
  end
  xrule.conditions[self.row_idx] = new_condition
  if not only_set then
    local success,err = xrule:compile()
    if err then
      LOG(err)
    end
    self.ui._build_rule_requested = true

  end
end

--------------------------------------------------------------------------------
-- provide a table where values go from low -> high,
--  when using a 'between' operator... 
-- @param val, the new value (string/number/table)
-- @param old_val, the old value (string/number/table)
-- @param val_index, 1 or 2

function xRulesUICondition:between_value_assist(val,old_val,val_index)
  TRACE("xRulesUICondition:between_value_assist(val,old_val,val_index)",val,old_val,val_index)

  if val_index then
    if (val_index == 1) then
      if (val > old_val[2]) then
        val = {val,val}
      else
        val = {val,old_val[2]}
      end
    elseif (val_index == 2) then
      if (val < old_val[1]) then
        val = {val,val}
      else
        val = {old_val[1],val}
      end
    end
  end
  return val
end

--------------------------------------------------------------------------------
-- change value: update rule with selected value
-- @param val (number,table,string) the new value 
-- @param val_index (int), 1 or 2 -- implies 'between' operator
-- @param only_set (boolean), 

function xRulesUICondition:change_value(val,val_index,only_set)
  TRACE("xRulesUICondition:change_value",val,val_index,only_set)

  local xrule = self.xrule
  local xcondition = xrule.conditions[self.row_idx]
  for k,v in pairs(xcondition) do
    for k2,v2 in pairs(v) do
      local old_val = xcondition[k][k2]
      if val_index then  
        val = self:between_value_assist(val,old_val,val_index)
      else
        val = xRulesUIEditor.change_value_assist(val,self.aspect,"aspect")
      end
      xcondition[k][k2] = val
    end
  end
  local success,err = xrule:compile()
  if err then
    LOG(err)
  end

  if not only_set then -- popups
    -- FIXME this can crash Renoise when click+dragging valueboxes
    -- it's most likely the "rebuild view below cursor" bug
    self.ui._build_rule_requested = true

  else -- valueboxes
    local vb = self.vb
    local valuebox1 = self.vb_condition_valuebox1
    local valuebox2 = self.vb_condition_valuebox2
    if val_index then -- between
      valuebox1.value = val[1]
      valuebox2.value = val[2]
    else
      valuebox1.value = val
    end
  end

end

--------------------------------------------------------------------------------

function xRulesUICondition:remove_condition()
  TRACE("xRulesUICondition:remove_condition()")

  local str_msg = "Are you sure you want to remove this condition?"
  local choice = renoise.app():show_prompt("Remove condition", str_msg, {"OK","Cancel"})
  if (choice == "OK") then

    local xrule = self.xrule

    table.remove(xrule.conditions,self.row_idx)
    -- also remove logic statement (if it exists)
    local prev_condition = xrule.conditions[self.row_idx-1]
    if prev_condition and (#prev_condition == 1) then
      table.remove(xrule.conditions,self.row_idx-1)
    end

    local success,err = xrule:compile()
    if err then
      LOG(err)
    end
    self.ui._build_rule_requested = true

  end
end

--------------------------------------------------------------------------------

function xRulesUICondition:change_sysex_value(val)
  TRACE("xRulesUICondition:change_sysex_value(val)",val)

  local success,err = self.editor.validate_sysex_string(val)
  if success then
    self.vb_status_elm.text = "✔ Syntax is OK"
    local condition = self.xrule.conditions[self.row_idx]
    self.xrule.conditions[self.row_idx] = {
      sysex = {
        [self.operator] = val
      }
    }
    success,self.str_syntax_error = self.xrule:compile()

  else
    self.vb_status_elm.text = "⚠ Syntax error"
  end


end

