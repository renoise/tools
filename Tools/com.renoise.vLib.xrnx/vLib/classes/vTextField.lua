--[[============================================================================
vTextField
============================================================================]]--

--[[--

Editable textfield with auto-sizing and support for placeholder-text
.
#

## Features
* Support for "placeholder" text
* Listen to characters as they are entered (based on a multiline_textfield)
* Auto-size control as text is entered
* Detect when Return is pressed ('submit' event)

]]

require (_vlibroot.."vControl")

class 'vTextField' (vControl)

vTextField.MINIMUM_WIDTH = 10
vTextField.MINIMUM_HEIGHT = 18

vTextField.FONT = {"normal","big","bold","italic","mono"}
vTextField.STYLE = {"body","strong","border"}

function vTextField:__init(...)
  TRACE("vTextField:__init()")

	local args = cLib.unpack_args(...) 

  --- string, placeholder text (when empty)
  self.placeholder = property(self.get_placeholder,self.set_placeholder)
  self._placeholder = args.placeholder or ""

  --- boolean, decide if textfield has focus
  self.edit_mode = property(self.get_edit_mode,self.set_edit_mode)
  self._edit_mode = args.edit_mode or false

  --- ObservableBoolean (implemented via idle notifier)
  self.edit_mode_observable = renoise.Document.ObservableBoolean(self._edit_mode)

  --- boolean, decide if size of textfield follows the text entered
  self.auto_size = property(self.get_auto_size,self.set_auto_size)
  self._auto_size = args.auto_size or false

  --- string, empty string is "" 
  self.text = property(self.get_text,self.set_text)
  self.text_observable = renoise.Document.ObservableString(args.text or "")

  --- string, alias for text 
  self.value = property(self.get_text,self.set_text)

  self.font = property(self.get_font,self.set_font)
  self._font = args.font or "normal"

  self.style = property(self.get_style,self.set_style)
  self._style = args.style or "body"

  -- events ---------------------------

  --- ObservableBang, fired when using Return to submit
  self.submitted = renoise.Document.ObservableBang()

  -- internal -------------------------

  --- boolean
  self._suppress_notifier = false

  -- boolean
  self._textfield_has_focus = false

  -- boolean
  self._text_scheduled_update = false

  -- initialize -----------------------

  vControl.__init(self,...)

  renoise.tool().app_idle_observable:add_notifier(function()

    -- check if lost/gained focus
    if self._vb_textfield.edit_mode 
      and not self._textfield_has_focus
    then 
      self:received_focus()
    elseif not self._vb_textfield.edit_mode
      and self._textfield_has_focus 
    then 
      self:lost_focus()
    end

    if self._text_scheduled_update then
      self.submitted:bang()      
      --self:set_text(self.text)
      self._text_scheduled_update = false
    end

  end)

  -- assign default size
  self._width = args.width or 60
  self._height = args.height or vLib.CONTROL_H

  self:build()
  self:update()

  if self.edit_mode then
    self:received_focus()
  else
    self:lost_focus()
  end

end

--------------------------------------------------------------------------------

function vTextField:build()
  TRACE("vTextField:build()")

  local vb = self.vb

  self._vb_textfield = self:build_textfield()

  self.view = vb:row{
    margin = 0,
    id = self.id,
    self._vb_textfield,
  }


end

--------------------------------------------------------------------------------
-- re-usable (make it possible to define separate build() methods for
-- classes that inherit this one

function vTextField:build_textfield()

  local vb = self.vb

  return vb:multiline_textfield{
    notifier = function(val)
      if not self._suppress_notifier then
        self:set_text(val,true)
      end
    end
  }

end

--------------------------------------------------------------------------------

function vTextField:update()
  TRACE("vTextField:update()")

  self:auto_resize()

end

--------------------------------------------------------------------------------

function vTextField:update_placeholder()
  TRACE("vTextField:update_placeholder()")

  self._suppress_notifier = true
  if (self.text_observable.value == "") then
    self._vb_textfield.text = self._placeholder
    self:auto_resize()
  elseif (self._vb_textfield.text == self._placeholder) then
    self.text_observable.value = ""
  end
  self._suppress_notifier = false

end

--------------------------------------------------------------------------------

function vTextField:get_display_text()
  TRACE("vTextField:get_display_text()")

  if (self.text_observable.value == "") then
    if self._vb_textfield.edit_mode then
      return ""
    else
      return self._placeholder
    end
  else
    return self.text_observable.value
  end

end

--------------------------------------------------------------------------------

function vTextField:auto_resize()
  TRACE("vTextField:auto_resize()")

  if self.auto_size then
    self:set_width(self:get_text_width())
  end

end

--------------------------------------------------------------------------------

function vTextField:get_text_width()
  TRACE("vTextField:get_text_width()")

  return vMetrics.get_text_width(self._vb_textfield.text,self._font)

end

--------------------------------------------------------------------------------

function vTextField:received_focus()
  TRACE("vTextField:received_focus()")

  self._textfield_has_focus = true

  self._suppress_notifier = true
  if (self.text_observable.value == "") then
    self._vb_textfield.text = ""
  end
  self._suppress_notifier = false

  self._vb_textfield:scroll_to_first_line()

  self:auto_resize()
  self.edit_mode_observable.value = true

end

--------------------------------------------------------------------------------

function vTextField:lost_focus()
  TRACE("vTextField:lost_focus()")

  self._textfield_has_focus = false

  self:update_placeholder()
  self:auto_resize()
  self.edit_mode_observable.value = false

end

--------------------------------------------------------------------------------
-- Getter & Setter methods
--------------------------------------------------------------------------------
-- @param val (string), input text to display
-- @param user_input (boolean), programmatic input

function vTextField:set_text(val,user_input)
  TRACE("vTextField:set_text(val,user_input)",val,user_input)

  -- check if value contains a line-break 
  local has_linebreak = false
  if string.find(val,"\n") then
    has_linebreak = true -- regular line-break
  elseif (val ~= "") and (val == self.text_observable.value) then
    -- some value got set to same value as before == line-break
    -- (for some reason, first line-break doesn't get reported)
    has_linebreak = true
  end
  if has_linebreak then
    -- delay (set non-breaking text on next idle update)
    self._vb_textfield.edit_mode = false
    self._text_scheduled_update = true
  end

  -- strip linebreaks
  val = string.gsub(val,"\n","")

  if (val == self._placeholder) then
    val = ""
  end

  self.text_observable.value = val

  if not user_input then 
    self._suppress_notifier = true
    self._vb_textfield.text = self:get_display_text()
    self._suppress_notifier = false
  end

  self:auto_resize()

end

function vTextField:get_text()
  return self.text_observable.value
end

--------------------------------------------------------------------------------

function vTextField:set_font(val)
  --TRACE("vTextField:set_font(val)",val)

  assert(type(val)=="string")
  self._font = val
  self._vb_textfield.font = val

  if not self.auto_size then
    -- nudge size to force display update
    self._vb_textfield.width = self._vb_textfield.width+1
    self._vb_textfield.width = self._vb_textfield.width-1
  else
    -- auto-sizing will cause refresh
    self:request_update()
  end

end

function vTextField:get_font()
  TRACE("vTextField:get_font()")

  return self._font

end

--------------------------------------------------------------------------------

function vTextField:set_style(val)
  --TRACE("vTextField:set_style(val)",val)

  assert(type(val)=="string")
  self._style = val
  self._vb_textfield.style = val

end

function vTextField:get_style()
  --TRACE("vTextField:get_style()")

  return self._style

end

--------------------------------------------------------------------------------

function vTextField:set_width(val)
  --TRACE("vTextField:set_width(val)",val)

  val = math.max(vTextField.MINIMUM_WIDTH,val)
  self._vb_textfield.width = val

  vControl.set_width(self,val)

end

--------------------------------------------------------------------------------

function vTextField:set_height(val)
  --TRACE("vTextField:set_width(val)",val)

  val = math.max(vTextField.MINIMUM_HEIGHT,val)

  self._vb_textfield.height = val
  vControl.set_height(self,val)

end

--------------------------------------------------------------------------------

function vTextField:set_active(val)
  --TRACE("vTextField:set_active(val)",val)

  self._vb_textfield.active = val
  vControl.set_active(self,val)

end

--------------------------------------------------------------------------------

function vTextField:set_edit_mode(val)
  --TRACE("vTextField:set_edit_mode(val)",val)

  assert(type(val)=="boolean")
  self._edit_mode = val
  self._vb_textfield.edit_mode = val

end

function vTextField:get_edit_mode()
  --TRACE("vTextField:get_edit_mode()")

  return self._vb_textfield.edit_mode

end

--------------------------------------------------------------------------------

function vTextField:set_auto_size(val)
  --TRACE("vTextField:set_auto_size(val)",val)

  assert(type(val)=="boolean")
  self._auto_size = val
  self:request_update()

end

function vTextField:get_auto_size()
  --TRACE("vTextField:get_auto_size()")

  return self._auto_size

end

--------------------------------------------------------------------------------

function vTextField:set_placeholder(val)
  --TRACE("vTextField:set_placeholder(val)",val)

  assert(type(val)=="string")
  self._placeholder = val
  self:update_placeholder()

end

function vTextField:get_placeholder()
  --TRACE("vTextField:get_placeholder()")

  return self._placeholder

end

