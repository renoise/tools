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
  --vEditField.OPERATOR.ADD,
  --vEditField.OPERATOR.SUB,
  --vEditField.OPERATOR.MUL,
  --vEditField.OPERATOR.DIV,
}

--------------------------------------------------------------------------------

function vEditField:__init(...)

	local args = cLib.unpack_args(...)

  --assert(type(args.value)~="nil")

  self.value = property(self.get_value,self.set_value)
  self._value = args.value or {value=0}

  self.operator = property(self.get_operator,self.set_operator)
  self._operator = args.operator or vEditField.OPERATOR.SET

  -- internal -------------------------

  self.vb_ops = nil
  self.vb_valuefield = nil
  self.vb_integerfield = nil
  self.vb_textfield = nil
  self.vb_checkbox = nil

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

  local vb = self.vb

  self.vb_ops = vb:popup{
    items = {},    
    --width = PhraseMateUI.UI_BATCH_OPERATOR_W,
    notifier = function(idx)
      local op_name = self.vb_ops[idx]
      local operator_idx = table.find(vEditField.OPERATORS,op_name)
      self:set_operator(operator_idx)
    end
  }

  self.vb_valuefield = vb:valuefield{
    visible = false,
    notifier = function(val)
      self._value.value = val
    end
  }
  
  self.vb_valuebox = vb:valuebox{
    visible = false,
    tonumber = function(val)
      print("editfield tonumber",val)
      if self.value_tonumber then
        return self.value_tonumber(val)
      end
    end,
    tostring = function(val) 
      print("editfield tostring",val)
      if self.value_tostring then
        return self.value_tostring(val)
      end
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

  self.vb_textfield = vb:textfield{
    visible = false,
    notifier = function(val)
      self._value.value = val
    end
  }

  self.view = vb:row{
    id = self.id,
    --style = "panel",
    self.vb_ops,
    self.vb_valuefield,
    self.vb_valuebox,
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

  self.vb_valuefield.visible = false
  self.vb_valuebox.visible = false
  self.vb_popup.visible = false
  self.vb_textfield.visible = false
  self.vb_checkbox.visible = false
  self.vb_checkbox_label.visible = false

  local ops = self:get_type_ops()
  --print("ops",rprint(ops))

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

  --print("vEditField.NUMBER_OPS",rprint(vEditField.NUMBER_OPS))

  local str_ops = {}
  for k,v in ipairs(ops) do
    table.insert(str_ops,vEditField.OPERATORS[v])
  end

  self.vb_ops.items = str_ops

  self:set_height(self._height)
  self:set_width(self._width)

end

--------------------------------------------------------------------------------
-- get list of operators associated with the current data-type
-- @return table

function vEditField:get_type_ops()

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

  --print("cval",rprint(cval))

  self._value = cLib.create_cvalue(cval)

  --print("self._value",self._value)
  --print("self._value.value_type",self._value.value_type)

  if (type(self._value.value) == "boolean") then
    self.vb_checkbox.value = self._value.value
    self.vb_checkbox_label.text = tostring(self._value.value)
  elseif (type(self._value.value) == "string") then
    self.vb_textfield.text = self._value.value
  elseif (type(self._value.value) == "number") then
    if self._value.value_enums then
      self.vb_popup.items = self._value.value_enums
      self.vb_popup.value = self._value.value
    end
    self.vb_valuebox.min = self._value.value_min
    self.vb_valuebox.max = self._value.value_max
    if self._value.value_tonumber then
      self.value_tonumber = self._value.value_tonumber
    else
      self.value_tonumber = function()
        return self._value.value
      end
    end
    if self._value.value_tostring then
      self.value_tostring = self._value.value_tostring
    else
      self.value_tostring = function()
        return ("%d"):format(self._value.value)
      end
    end
    self.vb_valuebox.value = self._value.value
    self.vb_valuefield.min = self._value.value_min
    self.vb_valuefield.max = self._value.value_max
    self.vb_valuefield.value = self._value.value
  else
    error("Unsupported value-type")
  end

  self:request_update()

end

--------------------------------------------------------------------------------

function vEditField:get_value()

  return self._value

end

--------------------------------------------------------------------------------
-- @param val (vEditField.OPERATOR)

function vEditField:set_operator(val)

  assert(type(val)=="number")
  if not vEditField.OPERATOR[val] then
    error("Unsupported operator")
  end

  self._operator = val

end

--------------------------------------------------------------------------------

function vEditField:get_operator()

  return self._operator

end

--------------------------------------------------------------------------------

function vEditField:set_width(val)

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

  self.vb_ops.active = val
  self.vb_valuefield.active = val
  self.vb_valuebox.active = val
  self.vb_popup.active = val
  self.vb_textfield.active = val
  self.vb_checkbox.active = val

  vControl.set_active(self,val)

end
