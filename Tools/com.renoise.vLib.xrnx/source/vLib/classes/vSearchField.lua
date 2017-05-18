--[[============================================================================
vSearchField
============================================================================]]--

--[[--

Text input that allows you to search among pre-defined entries (auto-complete)
.
#

## About

An auto-completing text widget + popup menu shows matching entries (if any) - a bit like the familiar browser address bar. 

Note: press return to select the currently matched item, if any. 

## TODO

* FIXME set index_observable to 0 when match is not complete
* FIXME input text partially obscured (when setting programmatically)
* FIXME long 'initial text' can exceed view width (check with many items)
* FIXME error when setting index while having some input text 

]]

require (_vlibroot.."vTextField")

class 'vSearchField' (vTextField)

vSearchField.MINIMUM_WIDTH = 40
vSearchField.MINIMUM_HEIGHT = 18

function vSearchField:__init(...)

	local args = cLib.unpack_args(...) 

  --- table<string>, items to search through
  self.items = property(self.get_items,self.set_items)
  self._items = args.items or {}

  --- boolean, decide if we should show a popup menu
  self.popup = property(self.get_popup,self.set_popup)
  self._popup = args.popup or true

  --- [TODO] boolean, determine if matching is case sensitive
  self.case_sensitive = property(self.get_case_sensitive,self.set_case_sensitive)
  self._case_sensitive = args.case_sensitive or false
 
  --- number, active index (set when focus is lost with a matched index)
  self.selected_index = property(self.get_index,self.set_index)
  self.selected_index_observable = renoise.Document.ObservableNumber(args.selected_index or 0)

  -- internal -----------------------

  --- table<string>, all items matching user input (nil if no match)
  self._matched_items = nil

  --- viewbuilder components
  self._vb_textfield = nil
  self._vb_text = nil
  self._vb_popup = nil

  -- initialize -----------------------

  -- assign default size
  self._width = args.width or 60
  self._height = args.height or vLib.CONTROL_H

  vTextField.__init(self,...)

  self.items = self._items
  self.popup = self._popup

  -- customize vTextField
  self._placeholder = args.placeholder or "Search..."
  self._auto_size = true
  self.style = "strong"

  self:set_height(self._height)
  if not self.popup then
    self:set_width(self._width)
  end


  -- notifiers -----------------------

  self.edit_mode_observable:add_notifier(function()
    self:set_width(self._width)
    if self.edit_mode then
      self:match_item()
    else
      if (self._vb_textfield.text == self._placeholder) then
        self._vb_text.text = ""
      end
    end
  end)

  self.text_observable:add_notifier(function()
    if not self._suppress_notifier then
      self:match_item()
    end
  end)

  self.submitted:add_notifier(function()
    if self._matched_items then
      self:set_index(self._matched_items[1].index)
    end
  end)

  self:update_text_style()

end

--------------------------------------------------------------------------------

function vSearchField:build()
  TRACE("vSearchField:build()")

  local vb = self.vb

  self._vb_textfield = self:build_textfield()
  self._vb_text = vb:text{}
  self._vb_popup = vb:popup{
    notifier = function(idx)
      if self._suppress_notifier then
        return
      end
      self:set_index(idx-1)
    end
  }

  self.view = vb:row{
    id = self.id,
    style = "plain",
    self._vb_textfield,
    vb:checkbox{
      visible = false,
      notifier = function()
        self.edit_mode = true
      end
    },
    self._vb_text,
    self._vb_popup,
  }

end

--------------------------------------------------------------------------------
--[[
function vSearchField:update()
  TRACE("vSearchField:update()")

    if self.edit_mode and (self.text == "") then
      self._vb_text.text = table.concat(self:get_initial_chars(),",")
    end

  vTextField.update(self)

end
]]

--------------------------------------------------------------------------------
-- overridden method
 
function vSearchField:auto_resize()
  TRACE("vSearchField:auto_resize()")
  local popup_w = self.popup and self._height or 0
  local max_w = self._width-popup_w
  self._vb_textfield.width = math.min(max_w,self:get_text_width())
  self:set_width(self._width)
end

--------------------------------------------------------------------------------
-- @return table<string>

function vSearchField:get_initial_chars()

  local rslt = {}
  for k,v in ipairs(self.items) do
    rslt[string.lower(string.sub(v,1,1))] = true
  end

  rslt = table.keys(rslt)
  table.sort(rslt)

  return rslt

end

--------------------------------------------------------------------------------
-- match item, display first match as text and all matches in popup
-- called as text is entered, and widget obtains/looses focus

function vSearchField:match_item()
  TRACE("vSearchField:match_item()")

  local matched = self:match_items()
  local str_input = self.text

  if table.is_empty(matched) then
    self._vb_text.text = ""
    self._matched_items = nil
    self:display_items(self._items)

    if self.edit_mode and (self.text == "") then
      self._vb_text.text = table.concat(self:get_initial_chars(),",")
    end

  else
    local str_matches = ""
    for k,v in ipairs(matched) do
      if (k == 1) then
        str_matches = str_matches .. string.sub(matched[k].value,#str_input+1)
      else
        str_matches = str_matches .. ", " .. v.value
      end
    end
    self._vb_text.text = str_matches
    self._matched_items = matched
    self:display_items(cLib.match_table_key(self._matched_items,"value"))
  end
  
  self._suppress_notifier = true
  if (#matched == 1) then
    self._vb_popup.value = 2
  else
    self._vb_popup.value = 1
  end
  self._suppress_notifier = false
  self:update_text_style()

end

--------------------------------------------------------------------------------

function vSearchField:update_text_style()
  TRACE("vSearchField:update_text_style()")

  if self._matched_items then
    self.style = "strong"
  else
    self.style = "body"
  end

end

--------------------------------------------------------------------------------
-- prefix items with 'none' entry

function vSearchField:display_items(t)
  TRACE("vSearchField:display_items(t)",t)

  local display_items = {"None"}
  if not table.is_empty(t) then
    for k,v in ipairs(t) do
      table.insert(display_items,v)
    end
  end

  self._vb_popup.items = display_items

end

--------------------------------------------------------------------------------
-- @return table<string>, all items matching input string

function vSearchField:match_items()
  TRACE("vSearchField:match_items()")

  local str_input = self.text

  if not self._case_sensitive then
    str_input = string.lower(str_input)    
  end

  local matched = {}

  if (str_input ~= "") then
    for k,v in ipairs(self._items) do
      local match_against = v
      if not self._case_sensitive then
        match_against = string.lower(match_against)
      end
      if (string.sub(match_against,1,#str_input) == str_input) then
        table.insert(matched,{
          index = k,
          value = v
        })
      end
    end
  end

  return matched

end

--------------------------------------------------------------------------------
-- loosing focus is when we finalize the match (set the index or clear)
-- (typing was completed with a return, or we clicked elsewhere)

function vSearchField:lost_focus()
  TRACE("vSearchField:lost_focus()")

  vTextField.lost_focus(self)

end

--------------------------------------------------------------------------------
-- Getters & Setters
--------------------------------------------------------------------------------

function vSearchField:set_index(val)
  TRACE("vSearchField:set_index(val)",val)

  assert(type(val)=="number")

  if (val == 0) then
    self.selected_index_observable.value = val
    self.text = ""
    return
  end

  if not self._items[val] then
    LOG("vSearchField: can't set index")
    return
  end

  self.selected_index_observable.value = val
  --self:match_item()

  -- set text and schedule update
  local str_val = self._items[val]
  self.text = str_val

  --self._suppress_notifier = true
  --self.text_observable.value = items[val]
  --self._suppress_notifier = false
  --self._text_scheduled_update = true

  self:update_text_style()

end

function vSearchField:get_index()
  TRACE("vSearchField:get_index()")
  return self.selected_index_observable.value
end

--------------------------------------------------------------------------------

function vSearchField:get_case_sensitive()
  TRACE("vSearchField:get_case_sensitive()")
  return self._case_sensitive
end

--------------------------------------------------------------------------------

function vSearchField:set_width(val)
  TRACE("vSearchField:set_width(val)",val)

  val = math.max(vSearchField.MINIMUM_WIDTH,val)

  local popup_w = self.popup and self._height or 0 
  local text_w = val - popup_w
  if self.popup then
    self._vb_popup.width = popup_w
  end
  
  if not self.edit_mode then
    self._vb_textfield.width = text_w - (self.edit_mode and 1 or 4)
    self._vb_text.width = self.edit_mode and 1 or 4
  else
    local ctrl_w = text_w - self._vb_textfield.width
    if (ctrl_w > 0) then
      self._vb_text.width = ctrl_w
    end
  end

  vControl.set_width(self,val)

end

--------------------------------------------------------------------------------

function vSearchField:set_height(val)
  TRACE("vSearchField:set_width(val)",val)

  val = math.max(vSearchField.MINIMUM_HEIGHT,val)
  self._vb_popup.height = val
  self._vb_textfield.height = val
  
  vControl.set_height(self,val)

  -- call this to ensure square popup button
  if self.popup then
    self:set_width(self._width)
  end

end

--------------------------------------------------------------------------------

function vSearchField:set_active(val)
  TRACE("vSearchField:set_active(val)",val)
  self._vb_popup.active = val
  vTextField.set_active(self,val)
end

--------------------------------------------------------------------------------

function vSearchField:set_popup(val)
  TRACE("vSearchField:set_popup(val)",val)
  assert(type(val)=="boolean")
  self._popup = val
  self._vb_popup.visible = val
  --self:request_update()
  self:set_width(self._width)
end

function vSearchField:get_popup()
  TRACE("vSearchField:get_popup()")
  return self._popup
end

--------------------------------------------------------------------------------

function vSearchField:set_case_sensitive(val)
  TRACE("vSearchField:case_sensitive(val)",val)
  assert(type(val)=="boolean")
  self._case_sensitive = val
end

function vSearchField:get_case_sensitive()
  TRACE("vSearchField:get_case_sensitive()")
  return self._case_sensitive
end

--------------------------------------------------------------------------------

function vSearchField:set_items(val)
  TRACE("vSearchField:set_items(val)",val)
  --assert(type(val)=="table")

  self._items = val

  --self._vb_popup.items = val
  self:request_update()
  self:match_item()

end

function vSearchField:get_items()
  TRACE("vSearchField:get_items()")
  return self._items
end

--------------------------------------------------------------------------------

function vSearchField:set_auto_size()
  TRACE("vSearchField:set_auto_size()")

  -- prevent access to vTextField

end

