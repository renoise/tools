--[[============================================================================
vTabs
============================================================================]]--
--[[

  Show/hide sub-views, using a switcher as the navigation interface

  CHANGELOG
  * Index made observable 

--]]

require (_vlibroot.."vControl")

class 'vTabs' (vControl)

--------------------------------------------------------------------------------

--- vertical position
vTabs.LAYOUT = {
  ABOVE = 1,
  BELOW = 2
}

--- horizontal position
vTabs.SWITCHER_ALIGN = {
  LEFT = 1,
  CENTER = 2,
  RIGHT = 3,
}

--- determine the size method
vTabs.SIZE_METHOD = {
  FIXED = 1,    -- FIXED = set to fixed size (crop contents)
  CURRENT = 2,  -- CURRENT = fit to content of currently visible tab
  LARGEST = 3,  -- LARGEST = fit to tallest/widest tab
}


vTabs.MINIMUM_H = 21
vTabs.SWITCHER_DEFAULT_W = "100%"
vTabs.SWITCHER_DEFAULT_H = 20


function vTabs:__init(...)
  TRACE("vTabs:__init(...)",...)

  local args = cLib.unpack_args(...)
  self.vb = args.vb

  -- (int)
	self.uid = vLib.generate_uid()

  -- public properties ----------------

	--- (int) the currently selected tab (1 or higher)
  self.index = property(self.get_index,self.set_index)
  self.index_observable = renoise.Document.ObservableNumber (args.index or 1)

  --- (int or string)
  self.switcher_width = property(self.get_switcher_width,self.set_switcher_width)
  self._switcher_width = args.switcher_width or vTabs.SWITCHER_DEFAULT_W

  --- (int or string)
  self.switcher_align = property(self.get_switcher_align,self.set_switcher_align)
  self._switcher_align = args.switcher_align or vTabs.SWITCHER_ALIGN.LEFT

  --- (int or string)
  self.switcher_height = property(self.get_switcher_height,self.set_switcher_height)
  self._switcher_height = args.switcher_height or vTabs.SWITCHER_DEFAULT_H

  --- (vTabs.LAYOUT) 
  self.layout = property(self.get_layout,self.set_layout)
  self._layout = args.layout or vTabs.LAYOUT.ABOVE

  --- (vTabs.SIZE_METHOD) 
  self.size_method = property(self.get_size_method,self.set_size_method)
  self._size_method = args.size_method or vTabs.SIZE_METHOD.FIXED

	--- (table>strings)
	self._labels = args.labels or {}

	--- (table>renoise.Views.Rack)
	self.tabs = {}

  -- (function) callback event
  -- @param elm (vTabs)
  self.notifier = args.notifier or nil

  --- (function) callback event
  -- @param elm (vTabs)
  self.on_resize = args.on_resize or nil

  -- private properties ---------------
   
  -- (renoise.Views.Switch)
	self.switcher = nil

  -- (renoise.Views.Aligner)
	self.switch_aligner = nil

  -- (renoise.Views.Rack)
	self.tabs_elm = nil

	-- (table>renoise.Views.Rack)
	self.tab_contents = {}

  -- (bool) use the provided width/height
  --self.maintain_size = true

  if args.tabs and not table.is_empty(args.tabs) then
    self.tabs = self:set_content(args.tabs) 
  end

  vControl.__init(self,...)
  self:build()

  --self:set_index(self._index)
  self:set_switcher_width(self.width)
  self:set_switcher_align(self._switcher_align)


end

--------------------------------------------------------------------------------

function vTabs:build()
  TRACE("vTabs:build()")
  
  local vb = self.vb

  self.view = vb:column{
    id = self.id,
    style = "plain",
  }

  self.switcher = vb:switch{
    items = self._labels,
    width = self._switcher_width,
    height = self._switcher_height,
    notifier = function()
      self.index = self.switcher.value
      if self.notifier then
        self.notifier(self)
      end
    end
  }

  self.switch_aligner = vb:horizontal_aligner{
    mode = "center",
  }
  self.switch_aligner:add_child(self.switcher)

  self.tabs_elm = vb:row{
    style = "plain",
  }
  self.spacer_h = vb:space{
    height = self.height,
    width = 1,
  }
  self.tabs_elm:add_child(self.spacer_h)

  for k,v in ipairs(self.tabs) do
    self.tabs_elm:add_child(v)
  end

  self:build_layout()

end

--------------------------------------------------------------------------------
-- call this after building, or when changing switcher layout
-- @param rmv (bool) remove before adding

function vTabs:build_layout(rmv)
  TRACE("vTabs:build_layout(rmv)",rmv)

  if rmv then
    self.view:remove_child(self.switch_aligner)
    self.view:remove_child(self.tabs_elm)
  end

  if (self._layout == vTabs.LAYOUT.ABOVE) then
    self.view:add_child(self.switch_aligner)
    self.view:add_child(self.tabs_elm)
  elseif (self._layout == vTabs.LAYOUT.BELOW) then
    self.view:add_child(self.tabs_elm)
    self.view:add_child(self.switch_aligner)
  else
    error("Unsupported layout")
  end

  self:refresh_size()

end

--------------------------------------------------------------------------------
-- refresh the width/height using current settings
-- (refreshing the view like this allows us to "crop" the tab contents)

function vTabs:refresh_size()
  TRACE("vTabs:refresh_size()")

  self:set_width(self._width)
  self:set_height(self._height)

end

--------------------------------------------------------------------------------
-- update the tab labels for the current number of labels
-- @param t (table)

function vTabs:set_labels(t)
  TRACE("vTabs:set_labels(t)",t)

  local labels = {}
  for i = 1,#self._labels do
    labels[i] = t[i]
  end

  self.switcher.items = labels

end

--------------------------------------------------------------------------------
-- provide the tabs - this will (re)build the entire view
-- @param t (table>renoise.Views.Rack)

function vTabs:set_content(t)
  TRACE("vTabs:set_content(t)",t)

  self.tab_contents = {}
  local tab_views = {}
  local vb = self.vb

  -- wrap each tab in a view, so we can set a custom size
  -- in case we need to crop the contents. The original
  -- tab view is stored in .tab_contents, and used for 
  -- reverting to the former, un-cropped size 
  for k,v in ipairs(t) do
    local tab_id = self:get_tab_id(k)
    local tab_elm =  vb.views.tab_id
    if tab_elm then
      self.view:remove_child(tab_elm)
      tab_elm = nil
    end
    tab_views[k] = vb:column{id = tab_id,style="plain"}
    tab_views[k]:add_child(v)
    self.tab_contents[k] = v
  end

  return tab_views

end

--------------------------------------------------------------------------------
-- add a view to the specified tab
-- @param tab_idx (int)
-- @param view (renoise.Views.View)

function vTabs:add_content(tab_idx,view)
  TRACE("vTabs:add_content(tab_idx,view)",tab_idx,view)

  assert(self.tabs[tab_idx],"No tab with this index")

  self.tab_contents[tab_idx]:add_child(view)

end

--------------------------------------------------------------------------------
-- show the selected tab
-- @param idx (int)

function vTabs:set_index(idx)
  TRACE("vTabs:set_index(idx)",idx)

  if (idx < 1) then
    return
  end

  if (idx > #self.tabs) then
    return
  end

  self.switcher.value = idx
  self.index_observable.value = idx

  local vb = self.vb
  for k,v in ipairs(self.tabs) do
    v.visible = false
  end
  self.tabs[idx].visible = true

  self:refresh_size()

end

function vTabs:get_index()
  return self.index_observable.value
end

--------------------------------------------------------------------------------
-- @param idx (int)

function vTabs:get_tab_id(idx)
  TRACE("vTabs:get_tab_id(idx)",idx)

  return ("tab_%i%s"):format(idx,self.uid)

end

--------------------------------------------------------------------------------

function vTabs:set_switcher_width(val)
  TRACE("vTabs:set_switcher_width(val)",val)
  self._switcher_width = val
  if val then
    self.switcher.width = val
    self.switch_aligner.width = val
  end
end

function vTabs:get_switcher_width()
  return self._switcher_width
end

--------------------------------------------------------------------------------
-- @param val (vTabs.SWITCHER_ALIGN)

function vTabs:set_switcher_align(val)
  TRACE("vTabs:set_switcher_align(val)",val)

  self._switcher_align = val
  local str_mode 
  if (self._switcher_align == vTabs.SWITCHER_ALIGN.LEFT) then
    str_mode = "left"
  elseif (self._switcher_align == vTabs.SWITCHER_ALIGN.RIGHT) then
    str_mode = "right"
  elseif (self._switcher_align == vTabs.SWITCHER_ALIGN.CENTER) then
    str_mode = "center"
  else
    error("Unsupported alignment - use vTabs.SWITCHER_ALIGN")
  end

  self.switch_aligner.mode = str_mode
  
end

function vTabs:get_switcher_align()
  return self._switcher_align
end

--------------------------------------------------------------------------------

function vTabs:set_switcher_height(val)
  TRACE("vTabs:set_switcher_height(val)",val)

  self._switcher_height = val
  self.switcher.height = val
  self.switch_aligner.height = val

  if (self._size_method == vTabs.SIZE_METHOD.FIXED) then
    self:refresh_size()
  end

end

function vTabs:get_switcher_height()
  return self._switcher_height
end

--------------------------------------------------------------------------------

function vTabs:set_layout(val)
  TRACE("vTabs:set_layout(val)",val)

  self._layout = val
  self:build_layout(true)
  
end

function vTabs:get_layout()
  return self._layout
end

--------------------------------------------------------------------------------

function vTabs:set_size_method(val)
  TRACE("vTabs:set_size_method(val)",val)

  local old_method = self._size_method
  self._size_method = val

  if (val ~= old_method) then
    self:refresh_size()
  end

end

function vTabs:get_size_method()
  return self._size_method
end

--------------------------------------------------------------------------------

function vTabs:set_active(val)
  TRACE("vTabs:set_active(val)",val)

  self.switcher.active = val
  vControl.set_active(self,val)

end

--------------------------------------------------------------------------------

function vTabs:set_width(val)
  TRACE("vTabs:set_width(val)",val)

  local new_w = val

  if (self._size_method == vTabs.SIZE_METHOD.FIXED) then
    -- do nothing
  elseif (self._size_method == vTabs.SIZE_METHOD.CURRENT) then
    local curr_tab = self.tabs[self.index]
    val = curr_tab.width + 1
  elseif (self._size_method == vTabs.SIZE_METHOD.LARGEST) then
    local w,h = self:get_largest_width_height()
    val = w + 1
  end

  -- never smaller than switcher
  -- TODO resize switcher as well
  if val and self.switcher.width then
    val = math.max(val,self.switcher.width)
  end

  if val then
    self.switch_aligner.width = val
  end

  vControl.set_width(self,val)

  if (new_w ~= val) then
    if self.on_resize then
      self.on_resize(self)
    end
  end

end

--------------------------------------------------------------------------------

function vTabs:set_height(val)
  TRACE("vTabs:set_height(val)",val)

  -- undefined height (do not set)
  if not val then
    self._height = nil
    return
  end

  local new_h = val

  if (self._size_method == vTabs.SIZE_METHOD.FIXED) then
    -- do nothing
  elseif (self._size_method == vTabs.SIZE_METHOD.CURRENT) then
    --local curr_tab = self.tabs[self.index]
    local curr_tab = self.tab_contents[self.index]
    val = curr_tab.height + self._switcher_height
  elseif (self._size_method == vTabs.SIZE_METHOD.LARGEST) then
    local w,h = self:get_largest_width_height()
    val = h + self._switcher_height
  end

  val = math.max(val,vTabs.MINIMUM_H)

  self.spacer_h.height = val - self._switcher_height

  -- "fixed" sizing requires us to resize (crop) tab contents
  for k,v in ipairs(self.tabs) do
    local tab_elm =  self.tabs[k]
    if (self._size_method == vTabs.SIZE_METHOD.FIXED) then
      tab_elm.height = val - self._switcher_height
    else
      tab_elm.height = self.tab_contents[k].height
    end
  end

  vControl.set_height(self,val)

  if (new_h ~= val) then
    if self.on_resize then
      self.on_resize()
    end
  end

end

--------------------------------------------------------------------------------
-- retrieve the maximum size, when resizing to LARGEST
-- @return number (width) 
-- @return number (height) 

function vTabs:get_largest_width_height()
  TRACE("vTabs:get_largest_width_height()")

  local max_w = 0
  local max_h = 0

  for k,v in ipairs(self.tab_contents) do
    max_w = math.max(max_w,v.width)
    max_h = math.max(max_h,v.height)
  end

  return max_w,max_h

end

--------------------------------------------------------------------------------
-- add handler for MIDI messages, similar to the provided name

function vTabs:set_midi_mapping(str)
  TRACE("vControl:set_midi_mapping(str)",str)

  self.switcher.midi_mapping = str
  vControl.set_midi_mapping(self,str)

  if (str and str ~="") then
    if renoise.tool():has_midi_mapping(str) then
      renoise.tool():remove_midi_mapping(str)
    end
    renoise.tool():add_midi_mapping({
      name = str,
      invoke = function(msg)
        if msg:is_abs_value() then
          self.index = msg.int_value
        end
      end
    })

  end

end

