--[[============================================================================
vEditField
============================================================================]]--

--[[--

cValue-based edit field, inspired by the Advanced-Edit panel 
.
#

## Features
* Support cValues - numbers with restricted range, etc.
* Works with all basic value-type (boolean, string and number)
* Expose different operators for each type of value 


]]

require (_vlibroot.."vControl")
require (_clibroot.."cNumber")

class 'vEditField' (vControl)

vEditField.OPERATORS = {"Set","Add","Sub","Mul","Div","Invert","Lowercase","Uppercase"}
vEditField.OPERATOR = {
  SET = 1,
  ADD = 2,
  SUB = 3,
  MUL = 4,
  DIV = 5,
  INVERT = 6,
  LOWERCASE = 7,
  UPPERCASE = 8,
}

vEditField.STRING_OPS = {
  vEditField.OPERATOR.SET,
  --vEditField.OPERATOR.LOWERCASE,
  --vEditField.OPERATOR.UPPERCASE,
}

vEditField.BOOLEAN_OPS = {
  vEditField.OPERATOR.SET,
  --vEditField.OPERATOR.INVERT,
}

vEditField.NUMBER_OPS = {
  vEditField.OPERATOR.SET,
  vEditField.OPERATOR.ADD,
  vEditField.OPERATOR.SUB,
  vEditField.OPERATOR.MUL,
  vEditField.OPERATOR.DIV,
}

--------------------------------------------------------------------------------

function vEditField:__init(...)
  TRACE("vEditField:__init()")

	local args = cLib.unpack_args(...)

  --assert(type(args.value)~="nil")

  -- cValue,cNumber
  self.value = property(self.get_value,self.set_value)
  self._value = args.value or {value=0}

  self.operator = property(self.get_operator,self.set_operator)
  self._operator = args.operator or vEditField.OPERATOR.SET

  -- internal -------------------------

  self.vb_ops = nil
  self.vb_valuefield = nil
  self.vb_valuebox = nil
  self.vb_popup = nil
  self.vb_checkbox = nil
  self.vb_checkbox_label = nil
  self.vb_textfield = nil

  self.vb_result = nil
  self.vb_valuebox_operator = nil
  self.vb_value_result = nil

  self.value_tonumber = function(val) return nil end
  self.value_tostring = function(val) return nil end

  -- initialize --

  vControl.__init(self,...)
  
  self._width = args.width or 50
  self._height = args.height or vLib.CONTROL_H

  self:build()

  self:set_value(self._value)

end

--------------------------------------------------------------------------------

function vEditField:build()
  TRACE("vEditField:build()")

  local vb = self.vb

  self.vb_ops = vb:popup{
    items = {},    
    notifier = function(idx)
      local op_name = self.vb_ops.items[idx]
      local operator_idx = table.find(vEditField.OPERATORS,op_name)
      self:set_operator(operator_idx)
      self:request_update()
    end
  }

  -- show floating point value
  self.vb_valuefield = vb:valuefield{
    visible = false,
    tonumber = function(val)
      return self.value_tonumber(val)
    end,
    tostring = function(val) 
      return self.value_tostring(val)
    end,
    notifier = function(val)
      self._value.value = val
    end
  }
  
  -- show integer value
  self.vb_valuebox = vb:valuebox{
    visible = false,
    tonumber = function(val)
      return self.value_tonumber(val)
    end,
    tostring = function(val) 
      return self.value_tostring(val)
    end,
    notifier = function(val)
      self._value.value = val
    end
  }
  
  self.vb_popup = vb:popup{
    visible = false,
    notifier = function(val)
      self._value.value = val
    end
  }
  
  self.vb_checkbox = vb:checkbox{
    visible = false,
    notifier = function(val)
      self._value.value = val
      self.vb_checkbox_label.text = tostring(val)
    end,
  }
  self.vb_checkbox_label = vb:text{
    visible = false,
  }

  -- show text value
  self.vb_textfield = vb:textfield{
    visible = false,
    notifier = function(val)
      self._value.value = val
    end
  }

  -- integer operators 
  self.vb_valuebox_operator = vb:valuebox{
    value = 1,
    min = 1,
    max = 512,
    notifier = function(val)
      local rslt = self:update_result()
    end
  }

  -- float operators
  self.vb_valuefield_operator = vb:valuefield{
    value = 0,
    min = 0,
    max = 512,
    tonumber = function(val)
      val = tonumber(val)
      if not val then
        return nil
      end
      if self._value.value_factor 
        and (self._operator == vEditField.OPERATOR.ADD) 
        or (self._operator == vEditField.OPERATOR.SUB) 
      then
        return val/self._value.value_factor
      else
        return val
      end
    end,
    tostring = function(val) 
      if self._value.value_factor 
        and (self._operator == vEditField.OPERATOR.ADD) 
        or (self._operator == vEditField.OPERATOR.SUB) 
      then
        return tostring(val*self._value.value_factor)
      else
        return tostring(val)
      end
    end,
    notifier = function(val)
      local rslt = self:update_result()
    end
  }

  self.vb_value_result = vb:text{}

  self.vb_result = vb:row{
    self.vb_valuebox_operator,
    self.vb_valuefield_operator,
    vb:text{
      text = "=",
      font = "mono",
    },
    self.vb_value_result,
  }

  self.view = vb:row{
    id = self.id,
    --style = "panel",
    self.vb_ops,
    self.vb_valuebox,
    self.vb_result,
    self.vb_valuefield,
    self.vb_popup,
    self.vb_checkbox,
    self.vb_checkbox_label,
    self.vb_textfield,
  }

  vControl.build(self)

end

--------------------------------------------------------------------------------
-- update control according to set value-type
-- @param cval (cValue)

function vEditField:update()
  TRACE("vEditField:update()")

  self.vb_valuefield.visible = false
  self.vb_valuebox.visible = false
  self.vb_popup.visible = false
  self.vb_textfield.visible = false
  self.vb_checkbox.visible = false
  self.vb_checkbox_label.visible = false

  local ops = self:get_type_ops()

  if (self._operator == vEditField.OPERATOR.SET) then
    self.vb_result.visible = false
    if (type(self._value.value) == "boolean") then
      self.vb_checkbox.visible = true
      self.vb_checkbox_label.visible = true
    elseif (type(self._value.value) == "string") then
      self.vb_textfield.visible = true
    elseif (type(self._value.value) == "number") then
      if (self._value.value_quantum == 1) then
        if self._value.value_enums then
          self.vb_popup.visible = true
        else
          self.vb_valuebox.visible = true
        end
      else
        self.vb_valuefield.visible = true
      end
    else
      error("Unsupported value-type")
    end

  else
    self.vb_result.visible = true
    local is_integer = (self._value.value_quantum == 1) 
    self.vb_valuebox_operator.visible = is_integer
    self.vb_valuefield_operator.visible = not is_integer
  end

  -- update the operator popup 
  local str_ops = {}
  for k,v in ipairs(ops) do
    table.insert(str_ops,vEditField.OPERATORS[v])
  end
  self.vb_ops.items = str_ops

  local op_name = vEditField.OPERATORS[self._operator]
  local operator_idx = table.find(self.vb_ops.items,op_name)
  self.vb_ops.value = operator_idx or vEditField.OPERATOR.SET

  self:set_height(self._height)
  self:set_width(self._width)

  self:update_result()

end


--------------------------------------------------------------------------------
-- display 'preview' of value 

function vEditField:update_result()
  TRACE("vEditField:update_result()")

  if (self._operator == vEditField.OPERATOR.SET) then
    return
  end

  self.vb_value_result.text = self.value_tostring(self:get_result())

end

--------------------------------------------------------------------------------
-- @return value (with the current operator applied...)

function vEditField:get_result()
  TRACE("vEditField:get_result()")

  -- work on copy 
  -- TODO other value-types
  local rslt = cNumber(self._value)

  local operator_val = self.vb_valuebox_operator.visible 
    and self.vb_valuebox_operator.value 
    or self.vb_valuefield_operator.value

  if (self._operator == vEditField.OPERATOR.SET) then
  elseif (self._operator == vEditField.OPERATOR.ADD) then
    rslt:add(operator_val)
  elseif (self._operator == vEditField.OPERATOR.SUB) then
    rslt:subtract(operator_val)
  elseif (self._operator == vEditField.OPERATOR.MUL) then
    rslt:multiply(operator_val)
  elseif (self._operator == vEditField.OPERATOR.DIV) then
    rslt:divide(operator_val)
  end

  return rslt.value

end

--------------------------------------------------------------------------------
-- apply operator to value

function vEditField:apply()
  TRACE("vEditField:apply()")

  if (self._operator == vEditField.OPERATOR.SET) then
    return -- nothing to do
  end

  self.value.value = self:get_result()
  self:request_update()

end

--------------------------------------------------------------------------------
-- get list of operators associated with the current data-type
-- @return table

function vEditField:get_type_ops()
  TRACE("vEditField:get_type_ops()")

  if (type(self._value.value) == "boolean") then
    return vEditField.BOOLEAN_OPS
  elseif (type(self._value.value) == "string") then
    return vEditField.STRING_OPS
  elseif (type(self._value.value) == "number") then
    return vEditField.NUMBER_OPS
  end

end

--------------------------------------------------------------------------------
-- @param cval (table), value descriptor - converted to cValue

function vEditField:set_value(cval)
  TRACE("vEditField:set_value(cval)",cval)

  self._value = cLib.create_cvalue(cval)

  if (type(self._value.value) == "boolean") then
    self.vb_checkbox.value = self._value.value
    self.vb_checkbox_label.text = tostring(self._value.value)
  elseif (type(self._value.value) == "string") then
    self.vb_textfield.text = self._value.value
  elseif (type(self._value.value) == "number") then

    local display_val = self._value.zero_based and self._value.value-1 or self._value.value

    if self._value.value_enums then
      self.vb_popup.items = self._value.value_enums
      self.vb_popup.value = self._value.value
    end
    self.vb_valuebox.min = self._value.value_min
    self.vb_valuebox.max = self._value.value_max
    if self._value.value_tonumber then
      self.value_tonumber = self._value.value_tonumber
    else
      self.value_tonumber = function(val)
        return val
      end
    end
    if self._value.value_tostring then
      self.value_tostring = self._value.value_tostring
    else
      self.value_tostring = function(val)
        if (self._value.value_quantum == 1) then
          return ("%d"):format(val)
        else
          return ("%.4f"):format(val)
        end
      end
    end
    self.vb_valuebox.value = display_val
    self.vb_valuefield.min = self._value.value_min
    self.vb_valuefield.max = self._value.value_max
    self.vb_valuefield.value = display_val
  else
    error("Unsupported value-type")
  end

  -- fallback to SET operator?
  local ops = self:get_type_ops()
  local str_op = vEditField.OPERATORS[vEditField.OPERATOR.SET]
  if not table.find(self.vb_ops.items,str_op) then
    self:set_operator(vEditField.OPERATOR.SET)
  end

  self:request_update()

end

--------------------------------------------------------------------------------

function vEditField:get_value()
  TRACE("vEditField:get_value()")

  return self._value

end

--------------------------------------------------------------------------------
-- @param val (vEditField.OPERATOR)

function vEditField:set_operator(val)
  TRACE("vEditField:set_operator(val)",val)

  assert(type(val)=="number")

  self._operator = val

  if (val == vEditField.OPERATOR.SET) then

  elseif (val == vEditField.OPERATOR.ADD) 
    or (val == vEditField.OPERATOR.SUB) 
  then
    self.vb_valuebox_operator.value = 10
  elseif (val == vEditField.OPERATOR.MUL) 
    or (val == vEditField.OPERATOR.DIV) 
  then
    self.vb_valuebox_operator.value = 2
  end

  --self:request_update()

end

--------------------------------------------------------------------------------

function vEditField:get_operator()
  TRACE("vEditField:get_operator()")

  return self._operator

end

--------------------------------------------------------------------------------

function vEditField:get_operator_value()
  
  if (self._operator ~= vEditField.OPERATOR.SET) then
    if self.vb_valuebox_operator.visible then
      return self.vb_valuebox_operator.value
    elseif self.vb_valuefield_operator.visible then
      return self.vb_valuefield_operator.value
    end
  end

end


--------------------------------------------------------------------------------

function vEditField:set_width(val)
  TRACE("vEditField:set_width()")

  local popup_w = 50
  local ctrl_w = val - popup_w
  self.vb_ops.width = popup_w
  self.vb_valuefield.width = ctrl_w
  self.vb_valuebox.width = ctrl_w
  self.vb_popup.width = ctrl_w
  self.vb_textfield.width = ctrl_w
  self.vb_checkbox_label.width = ctrl_w-24

  vControl.set_width(self,val)

end

--------------------------------------------------------------------------------

function vEditField:set_height(val)
  TRACE("vEditField:set_height()")

  self.vb_ops.height = val
  self.vb_valuefield.height = val
  self.vb_valuebox.height = val
  self.vb_textfield.height = val
  self.vb_checkbox.height = val
  self.vb_checkbox.height = val

  vControl.set_height(self,val)

end

--------------------------------------------------------------------------------

function vEditField:set_active(val)
  TRACE("vEditField:set_active()")

  self.vb_ops.active = val
  self.vb_valuefield.active = val
  self.vb_valuebox.active = val
  self.vb_popup.active = val
  self.vb_textfield.active = val
  self.vb_checkbox.active = val

  vControl.set_active(self,val)

end
