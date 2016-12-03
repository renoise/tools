--[[============================================================================
vGraph 
============================================================================]]--
--[[

  Can be used for histograms, envelope plots and such things

  Technically, the graph is composed from composite bitmaps (each line 
  consists of two or three bitmaps). We do not have a way to draw pixels 
  directly onto the screen, so this is the second best thing. 
  
  The bitmaps themselves are created on-the-fly, as the graph requires them. 
  This means that you might experience a slight lag the first time the 
  vGraph control is instantiated, or when you change the color scheme.

  
  |  |    |
  || | | ||   <- UNIPOLAR, values from below and up
  |||| | ||
  |||||||||

  
  |||||||||
  |||| | ||   <- UNIPOLAR2, values from top and downwards
  || | | ||
  |  |    |
     
     |    |
   | |   ||
  =========   <- BIPOLAR, one or the other side of central axis
  | |  |  
  | |  |  

  TODO
  - HORIZONTAL_FIT
  - normalize does not work properly with BIPOLAR 

]]

--==============================================================================

require (_vlibroot.."vControl")

class 'vGraph' (vControl)

-------------------------------------------------------------------------------
-- vGraph is a class for creating histograms, envelope plots and such things

vGraph.DRAW_MODE = {
  UNIPOLAR = 1, 
  UNIPOLAR2 = 2, 
  BIPOLAR = 3,  
}

--[[
vGraph.HORIZONTAL_FIT = {
  AUTOMATIC = 1,  -- fit everything
  WHEN_LARGE = 2, -- fit only when too large 
  WHEN_SMALL = 3, -- fit only when too smaller 
  NEVER = 4,      -- just don't
}
]]

-- specify how many heights we have bitmaps for
-- (loaded from disk, so make sure they can be found!)
vGraph.BITMAP_MAX_H = 400

function vGraph:__init(...)
  TRACE("vGraph:__init(...)",...)

  local args = cLib.unpack_args(...)
  
  --- (vSelection)
  self.selection = vSelection{
    require_selection = args.require_selection,
  }

  --- (table>number) the numeric data to operate on
  self._data = args.data or {}
  self.data = property(self.get_data,self.set_data)

  --- (vGraph.DRAW_MODE) 
  self._draw_mode = args.draw_mode or vGraph.DRAW_MODE.UNIPOLAR
  self.draw_mode = property(self.get_draw_mode,self.set_draw_mode)

  --self._fit_mode = args.fit_mode or vGraph.HORIZONTAL_FIT.AUTOMATIC
  -- TODO get/set

  --- (number) the maximum possible value
  self._value_max = args.value_max or 1
  self.value_max = property(self.get_value_max,self.set_value_max)

  --- (number) the minimum possible value
  self._value_min = args.value_min or 0
  self.value_min = property(self.get_value_min,self.set_value_min)

  --- (number) the number of possible values, e.g. 128 for 7-bit
  -- this is used for the accompanying ruler widget
  --self._value_quant = args.value_quant or nil
  --self.value_quant = property(self.get_value_quant,self.set_value_quant)
  
  --- (vSelection.SELECT_MODE) 
  self._select_mode = args.select_mode or vSelection.SELECT_MODE.SINGLE
  self.select_mode = property(self.get_select_mode,self.set_select_mode)

  --- (int) the index of the (first) selected item
  self.selected_index = property(self.get_selected_index,self.set_selected_index)
  
  --- (int) the (first) selected item
  --self._selected_item = args.selected_item or nil
  --self.selected_item = property(self.selection.get_item,self.set_selected_item)
  
  --- (table > int) return indices of selected items
  self.selected_indices = property(self.get_selected_indices,self.set_selected_indices)
  
  --- (bool) enforce that at least one item remains selected at all times
  self.require_selection = property(self.get_require_selection,self.set_require_selection)

  --- (vLib.BITMAP_STYLES) 
  self.style_normal = property(self.get_style_normal,self.set_style_normal)
  self._style_normal = args.style_normal or "transparent"

  --- (vLib.BITMAP_STYLES) 
  self.style_selected = property(self.get_style_selected,self.set_style_selected)
  self._style_selected = args.style_selected or "body_color"

  -- (bool) whether to automatically fit values to the display
  self.normalized = property(self.get_normalized,self.set_normalized)
  self._normalized = false

  -- (number) peak value, automatically set along with data when
  -- normalized is enabled, but can be specified manually as well
  -- (for example, to use it as a "vertical zoom")
  self._peak = nil
  self.peak = property(self.get_peak,self.set_peak)

  -- callbacks ------------------------

  --- (function) callback function for when a bar is clicked
  -- @param elm (vGraph)
  -- @param index (int) the bar index
  self._click_notifier = args.click_notifier or nil
  self.click_notifier = property(self.get_click_notifier,self.set_click_notifier)

  --- (function) callback function for when selection has changed
  -- @param elm (vGraph)
  self._selection_notifier = args.selection_notifier or nil
  self.selection_notifier = property(self.get_selection_notifier,self.set_selection_notifier)


  -- internal -------------------------

  --- (string) unique identifier for views
  self.uid = vLib.generate_uid()
  self.graph_uid = self.uid.."graph_content"

  vControl.__init(self,...)

  self.view_content = nil

  local skip_event = true

  -- selection properties needs to be initialized

  if args.select_mode then
    self:set_select_mode(args.select_mode,skip_event)
  end 
  if (type(args.require_selection)=="boolean") then
    self:set_require_selection(args.require_selection,skip_event)
  end 

  -- finally...

  if args.data then
    self:set_data(args.data)
    self:update()
  end 

end

--------------------------------------------------------------------------------
--- return the maximum value in our set

function vGraph:compute_peak_value()
  TRACE("vGraph:compute_peak_value()")

  local peak = 0
  for k,v in ipairs(self._data) do
    peak = math.abs(math.max(peak,v))
  end
  return peak

end

--------------------------------------------------------------------------------
--- complete display update, use sparingly

function vGraph:update()
  TRACE("vGraph:update()")

	local vb = self.vb

  local switch_arr = {}
  for i = 1,#self._data do
    table.insert(switch_arr,"")
  end

  if not self.view then
    self.view = vb:column{
      id = self.id,
      style = "panel",
    }
  end

  -- clear existing graph
  if (self.view_content) then
    local bar_count = 1
    local repeat_count = 1
    local lower_id,middle_id,upper_id,line_id = self:get_bitmap_ids(bar_count,repeat_count)
    local line_elm = vb.views[line_id]
    while vb.views[lower_id] do
      self:remove_line_elements(lower_id,middle_id,upper_id,line_id)
      repeat_count = repeat_count + 1
      lower_id,middle_id,upper_id,line_id = self:get_bitmap_ids(bar_count,repeat_count)
      line_elm = vb.views[line_id]
      while vb.views[lower_id] do
        self:remove_line_elements(lower_id,middle_id,upper_id,line_id)
        repeat_count = repeat_count + 1
        lower_id,middle_id,upper_id,line_id = self:get_bitmap_ids(bar_count,repeat_count)
      end
      repeat_count = 1
      bar_count = bar_count + 1
      lower_id,middle_id,upper_id,line_id = self:get_bitmap_ids(bar_count,repeat_count)
    end
    self.view:remove_child(vb.views[self.graph_uid])
    vb.views[self.graph_uid] = nil
  end

  if (#self._data == 0) then

    -- provide message when no content
    self.view_content = vb:row{
      id = self.graph_uid,
      vb:text {
        text = "No values to display",
      }
    }

  else

    self.view_content = vb:row{
      id = self.graph_uid,
    }
    if (self._width < #self._data) then
      -- skip entries when number of entries exceed the width
      local interval = #self.data/self._width
      for i = 1,self._width do
        local idx = math.floor(i*interval)
        local is_selected = self.selection:contains_index(idx) 
        local lower_id,middle_id,upper_id,line_id = self:get_bitmap_ids(i,1)
        self:add_line_elements(lower_id,middle_id,upper_id,line_id,i,self._data[idx],is_selected)
      end
    else

      -- repeat/remove entries to fit total width 
      local interval = self._width/#self._data
      local fract = cLib.fraction(interval)
      interval = math.floor(interval)
      local fract_add = fract
      for i = 1,#self._data do
        local is_selected = self.selection:contains_index(i) 
        local repeat_count = 0
        -- repeat to make it pixel-accurate
        for o = 1,interval do
          repeat_count = repeat_count + 1
          if (fract > 0) then
            repeat_count = repeat_count + math.floor(fract)
            fract = 0 + cLib.fraction(fract)
          end
        end
        fract = fract + fract_add
        for o = 1,repeat_count do
          local lower_id,middle_id,upper_id,line_id = self:get_bitmap_ids(i,o)
          self:add_line_elements(lower_id,middle_id,upper_id,line_id,i,self._data[i],is_selected)
        end
      end

    end 
  end -- end view_content

  self.view:add_child(self.view_content)

  -- changing bitmaps can cause sizes to be thrown off
  -- set this value to avoid such display glitches..
  --self.view.height = self._height

end

--------------------------------------------------------------------------------
-- determine response when clicking bar (invoke click_notifier)

function vGraph:handle_bar_clicked(idx)
  TRACE("vGraph:handle_bar_clicked(idx)",idx)

  if self._click_notifier then
    self._click_notifier(self,idx)
  end

end

--------------------------------------------------------------------------------
--- retrieve the matching for a value between 0-self._height  
-- @param val (number)
-- @param part (string) "upper" or "lower"

function vGraph:value_to_bitmap(val,part)
  TRACE("vGraph:value_to_bitmap(val,part)",val,part)

  local str_bitmap = nil

  val = math.max(1,val)

  if (part == "upper") then
    str_bitmap = ("%svgraph/0xffffff/1x%d.bmp"):format(_vlib_img,val)
  elseif (part == "middle") then
    str_bitmap = ("%svgraph/0x000000/1x%d.bmp"):format(_vlib_img,val)
  elseif (part == "lower") then
    str_bitmap = ("%svgraph/0xffffff/1x%d.bmp"):format(_vlib_img,val)
  end
  return str_bitmap

end

--------------------------------------------------------------------------------
--- do "something" to the bitmaps that make up a single bar 
-- this method allows us to avoid having to update the entire graph

function vGraph:apply_to_bar(idx,fn)
  TRACE("vGraph:apply_to_bar(idx,fn)",idx,fn)

  local repeat_count = 1
  local lower_id,middle_id,upper_id,line_id = self:get_bitmap_ids(idx,repeat_count)
  while self.vb.views[lower_id] do
    local lower_bitmap = self.vb.views[lower_id]
    if lower_bitmap then
      fn(lower_bitmap,"lower")
    end
    local middle_bitmap = self.vb.views[middle_id]
    if middle_bitmap then
      fn(middle_bitmap,"middle")
    end
    local upper_bitmap = self.vb.views[upper_id]
    if upper_bitmap then
      fn(upper_bitmap,"upper")
    end
    repeat_count = repeat_count + 1
    lower_id,middle_id,upper_id = self:get_bitmap_ids(idx,repeat_count)
  end

  -- changing bitmaps can cause sizes to be thrown off
  -- set this value to avoid such display glitches..
  --self.view.height = self._height

end

--------------------------------------------------------------------------------
-- return the two bitmaps that together form a single line

function vGraph:get_bitmap_ids(idx,rpt)
  TRACE("vGraph:get_bitmap_id(idx,rpt)",idx,rpt)

  local line_id = ("vgraph_%s_bar_%d_%d"):format(self.uid,idx,rpt)
  local upper_id = line_id.."_upper"
  local middle_id = line_id.."_middle"
  local lower_id = line_id.."_lower"
  return upper_id,middle_id,lower_id,line_id

end

--------------------------------------------------------------------------------
-- add the elements that together form a single line

function vGraph:add_line_elements(lower_id,middle_id,upper_id,line_id,idx,val,is_selected)

  local vb = self.vb

  local bitmap_mode = is_selected and self._style_selected or self._style_normal
  local val_lower,val_middle,val_upper = self:decide_bitmap_size(val)

  self.view_content:add_child(vb:column{
    id = line_id,
    vb:bitmap {
      id = upper_id,
      mode = bitmap_mode,
      bitmap = self:value_to_bitmap(val_upper,"upper"),
      notifier = function()
        self:handle_bar_clicked(idx)
      end
    },
    vb:bitmap {
      id = middle_id,
      mode = bitmap_mode,
      bitmap = self:value_to_bitmap(val_middle,"middle"),
      notifier = function()
        self:handle_bar_clicked(idx)
      end
    },
    vb:bitmap {
      id = lower_id,
      mode = bitmap_mode,
      bitmap = self:value_to_bitmap(val_lower,"lower"),
      notifier = function()
        self:handle_bar_clicked(idx)
      end
    },
  })

  vb.views[upper_id].visible = (val_upper >= 1) and true or false
  vb.views[middle_id].visible = (val_middle >= 1) and true or false
  vb.views[lower_id].visible = (val_lower >= 1) and true or false

end

--------------------------------------------------------------------------------
-- remove the elements that together form a single line

function vGraph:remove_line_elements(lower_id,middle_id,upper_id,line_id)
  TRACE("vGraph:remove_line_elements(lower_id,middle_id,upper_id,line_id)",lower_id,middle_id,upper_id,line_id)

	local vb = self.vb

  local line_elm = vb.views[line_id]
  line_elm:remove_child(vb.views[upper_id])
  vb.views[upper_id] = nil
  line_elm:remove_child(vb.views[middle_id])
  vb.views[middle_id] = nil
  line_elm:remove_child(vb.views[lower_id])
  vb.views[lower_id] = nil
  self.view_content:remove_child(vb.views[line_id])
  vb.views[line_id] = nil

end

--------------------------------------------------------------------------------

function vGraph:get_bar_style(idx)
  local lower_bitmap = self.vb.views[self:get_bitmap_ids(idx,1)]
  if lower_bitmap then
    return lower_bitmap.mode
  end
end

--------------------------------------------------------------------------------

function vGraph:set_bar_style(idx,style)
  TRACE("vGraph:set_bar_style(idx,style)",idx,style)
  
  self:apply_to_bar(idx,function(bitmap)
    bitmap.mode = style
  end)

end


--------------------------------------------------------------------------------
-- for a line, compute how large bitmaps we are going to use 
-- @param val (number) 
-- @return val_lower 
-- @return val_middle 
-- @return val_upper 

function vGraph:decide_bitmap_size(val)

  local scale_min, scale_max
  if self._normalized then
    -- use the peak as min/max
    if (self.draw_mode == vGraph.DRAW_MODE.BIPOLAR) then
      local how_far_from_max = self.value_max - self._peak
      scale_min = self.value_min + how_far_from_max
      scale_max = self._peak
    else -- unipolar
      scale_min = self.value_min
      scale_max = self._peak
    end
  else
    scale_min = self.value_min
    scale_max = self.value_max
  end

  local val_upper,val_middle,val_lower

  if (self.draw_mode == vGraph.DRAW_MODE.UNIPOLAR) then

    val_upper = cLib.round_value(cLib.scale_value(val,scale_max,scale_min,0,self._height))
    val_middle = cLib.round_value(cLib.scale_value(val,scale_min,scale_max,0,self._height))
    val_lower = 0 -- will be hidden

  elseif (self.draw_mode == vGraph.DRAW_MODE.UNIPOLAR2) then

    val_upper = 0 -- will be hidden
    val_middle = cLib.round_value(cLib.scale_value(val,scale_min,scale_max,0,self._height))
    val_lower = cLib.round_value(cLib.scale_value(val,scale_max,scale_min,0,self._height))


  elseif (self.draw_mode == vGraph.DRAW_MODE.BIPOLAR) then
    
    local mid_value = (scale_min+scale_max)/2

    if (val <= mid_value) then
      -- value in lower part
      val_upper = cLib.round_value(cLib.scale_value(mid_value,scale_min,scale_max,0,self._height))
      val_middle = cLib.round_value(cLib.scale_value(val,mid_value,scale_min,0,self._height/2))
      val_lower = cLib.round_value(cLib.scale_value(val,scale_min,mid_value,0,self._height/2))

    else
      -- value in upper part
      val_upper = cLib.round_value(cLib.scale_value(val,scale_max,mid_value,0,self._height/2))
      val_middle = cLib.round_value(cLib.scale_value(val,mid_value,scale_max,0,self._height/2))
      val_lower = cLib.round_value(cLib.scale_value(mid_value,scale_min,scale_max,0,self._height))

      -- ensure that upper half is exactly 50%
      local half_size = math.floor(self.height/2)
      local val_upper_half = val_upper+val_middle
      if (val_upper_half > half_size) then
        val_upper = val_upper + half_size-val_upper_half
      end

    end 

  end

  return val_lower,val_middle,val_upper

end

--------------------------------------------------------------------------------

function vGraph:set_value(idx,val)
  TRACE("vGraph:set_value(idx,val)",idx,val)

  if (self._data[idx]) then
    self._data[idx] = val

    -- TODO update peak

    local val_lower,val_middle,val_upper = self:decide_bitmap_size(val)
    local src_upper = self:value_to_bitmap(val_upper,"upper")
    local src_middle = self:value_to_bitmap(val_middle,"middle")
    local src_lower = self:value_to_bitmap(val_lower,"lower")
    self:apply_to_bar(idx,function(bitmap,part)
      if (part == "upper") then
        if (val_upper < 1) then
          bitmap.visible = false
        else
          bitmap.visible = true
          bitmap.bitmap = src_upper
          bitmap.height = val_upper
        end
      elseif (part == "middle") then
        if (val_middle < 1) then
          bitmap.visible = false
        else
          bitmap.visible = true
          bitmap.bitmap = src_middle
          bitmap.height = val_middle
        end
      elseif (part == "lower") then
        if (val_lower < 1) then
          bitmap.visible = false
        else
          bitmap.visible = true
          bitmap.bitmap = src_lower
          bitmap.height = val_lower
        end
      end
    end)
  end

end

--------------------------------------------------------------------------------

function vGraph:clear_selection()
  TRACE("vGraph:clear_selection()")

  local changed, removed = self.selection:clear_selection()
  self:selection_handler(changed,{},removed)

end

--------------------------------------------------------------------------------

function vGraph:select_all()
  TRACE("vGraph:select_all()")

  local changed,added = self.selection:select_all()
  self:selection_handler(changed,added,{})

end

--------------------------------------------------------------------------------
--- update display after having called the selection class

function vGraph:selection_handler(changed,added,removed)
  TRACE("vGraph:selection_handler(changed,added,removed)",changed,added,removed)

  if changed then
    for k,v in ipairs(removed) do
      self:set_bar_style(v,self._style_normal)
    end
    for k,v in ipairs(added) do
      self:set_bar_style(v,self._style_selected)
    end
    if self._selection_notifier then
      self._selection_notifier(self)
    end
  end

end

--------------------------------------------------------------------------------

function vGraph:get_selected_item()
  return self:get_item(self.selected_index)
end

--------------------------------------------------------------------------------

function vGraph:get_item(idx)
  TRACE("vGraph:get_selected_item(idx)",idx)
  
  return self._data[idx]

end

--------------------------------------------------------------------------------

function vGraph:toggle_index(idx)
  TRACE("vGraph:toggle_index(idx)",idx)
  
  local changed,added,removed = self.selection:toggle_index(idx)
  self:selection_handler(changed,added,removed)

end


--------------------------------------------------------------------------------
-- Getters and setters 
--------------------------------------------------------------------------------

function vGraph:get_data()
  return self._data
end

function vGraph:set_data(t)
  TRACE("vGraph:set_data(t)",t)

  self._data = t
  self.selection.num_items = #t

  if self._normalized then
    self._peak = self:compute_peak_value()
  end

  self:request_update()
end

--------------------------------------------------------------------------------

function vGraph:get_draw_mode()
  return self._draw_mode
end

function vGraph:set_draw_mode(val)
  TRACE("vGraph:set_draw_mode(val)",val)
  local has_changed = (val ~= self._draw_mode)
  self._draw_mode = val
  if has_changed then
    self:request_update()
  end
end

--------------------------------------------------------------------------------

function vGraph:get_value_max()
  return self._value_max
end

function vGraph:set_value_max(val)

  if (val <= self._value_min) then
    error("value_max needs to be larger than value_min")
    return
  end

  local has_changed = (val ~= self._value_max)
  self._value_max = val
  if has_changed then
    self:request_update()
  end
end

--------------------------------------------------------------------------------

function vGraph:get_value_min()
  return self._value_min
end

function vGraph:set_value_min(val)

  if (val >= self._value_max) then
    error("value_min needs to be smaller than value_max")
    return
  end

  local has_changed = (val ~= self._value_min)
  self._value_min = val
  if has_changed then
    self:request_update()
  end
end

--------------------------------------------------------------------------------
--[[
function vGraph:get_value_quant()
  return self._value_quant
end

function vGraph:set_value_quant(val)
  local has_changed = (val ~= self._value_quant)
  self._value_quant = val
  if has_changed then
    self:request_update()
  end
end
]]
--------------------------------------------------------------------------------

function vGraph:get_peak()
  return self._peak
end

function vGraph:set_peak(val)
  local has_changed = (val ~= self._peak)
  self._peak = val
  if has_changed then
    self:request_update()
  end
end


--------------------------------------------------------------------------------

function vGraph:get_click_notifier()
  return self._click_notifier
end

function vGraph:set_click_notifier(fn)
  self._click_notifier = fn
end

--------------------------------------------------------------------------------

function vGraph:get_selection_notifier()
  return self._selection_notifier
end

function vGraph:set_selection_notifier(fn)
  self._selection_notifier = fn
end

--------------------------------------------------------------------------------

function vGraph:set_width(val)
  local has_changed = (val ~= self._width)
  self._width = val
  vControl.set_width(self,val)
  if has_changed then
    self:request_update()
  end
end

--------------------------------------------------------------------------------

function vGraph:set_height(val)
  val = math.min(val,vGraph.BITMAP_MAX_H)
  local has_changed = (val ~= self._height)
  self._height = val
  vControl.set_height(self,val)
  if has_changed then
    self:request_update()
  end
end

--------------------------------------------------------------------------------

function vGraph:set_selected_index(idx)
  local changed,added,removed = self.selection:set_index(idx)
  self:selection_handler(changed,added,removed)
end

function vGraph:get_selected_index()
  return self.selection.index
end

--------------------------------------------------------------------------------

function vGraph:set_selected_indices(t)

  local changed,added,removed = self.selection:set_indices(t)
  self:selection_handler(changed,added,removed)

end

function vGraph:get_selected_indices()
  return self.selection.indices
end

--------------------------------------------------------------------------------

function vGraph:set_select_mode(val,skip_event)
  TRACE("vGraph:set_select_mode(val)",val)
  local changed,added,removed = self.selection:set_mode(val)
  if not skip_event then
    self:selection_handler(changed,added,removed)
  end

end

function vGraph:get_select_mode()
  return self.selection.mode
end

--------------------------------------------------------------------------------

function vGraph:set_require_selection(val,skip_event)
  TRACE("vGraph:set_require_selection(val)",val)
  local changed,added,removed = self.selection:set_require_selection(val)
  if not skip_event then
    self:selection_handler(changed,added,removed)
  end
end

function vGraph:get_require_selection()
  return self.selection.require_selection
end

--------------------------------------------------------------------------------

function vGraph:set_style_normal(val)
  local has_changed = (val ~= self._style_normal)
  self._style_normal = val
  if has_changed then
    self:request_update()
  end
end

function vGraph:get_style_normal()
  return self._style_normal
end

--------------------------------------------------------------------------------

function vGraph:set_style_selected(val)
  local has_changed = (val ~= self._style_selected)
  self._style_selected = val
  if has_changed then
    self:request_update()
  end
end

function vGraph:get_style_selected()
  return self._style_selected
end

--------------------------------------------------------------------------------

function vGraph:set_normalized(val)
  local has_changed = (val ~= self._normalized)
  self._normalized = val
  if has_changed then
    self:request_update()
  end

end

function vGraph:get_normalized()
  return self._normalized
end

