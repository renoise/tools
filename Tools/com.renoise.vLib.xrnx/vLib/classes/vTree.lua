--[[============================================================================
vTree
============================================================================]]--

require (_clibroot.."cFilesystem")
require (_vlibroot.."vControl")

class 'vTree' (vControl)

vTree.MAX_ROWS = 42
vTree.NUM_ROWS_DEFAULT = 6
vTree.INDENT_DEFAULT = 10
vTree.ICON_WIDTH_DEFAULT = 22
vTree.ROW_HEIGHT_DEFAULT = 13
vTree.ROW_HEIGHT_MIN = 12
vTree.TREE_MIN_H = 8

vTree.ICON_NODE_EXPANDED = "Icons/Node_Expanded.bmp"
vTree.ICON_NODE_COLLAPSED = "Icons/Node_Collapsed.bmp"
vTree.ICON_NODE_ITEM = "Icons/Node_Star.bmp"

vTree.ROW_STYLE_SELECTED = "body"
vTree.ROW_STYLE_NORMAL = "plain"

vTree.file_formats = {
  {
    extension = "xml", 
    parser = vXML{
      
    },
  },
  --[[
  {
    extension = "json", 
    parser = vJSON{
      
    },
  },
  ]]
}

--------------------------------------------------------------------------------
--- Tree view, used for displaying hierarchical data

function vTree:__init(...)
  TRACE("vTree:__init(...)")

  local args = cLib.unpack_args(...)

  --- (vSelection)
  self.selection = vSelection{
    require_selection = args.require_selection,
  }

  -- properties -----------------------

  --- (vSelection.SELECT_MODE) 
  --self._select_mode = args.select_mode or vSelection.SELECT_MODE.SINGLE
  --self.select_mode = property(self.get_select_mode,self.set_select_mode)

  --- (int) the index of the (first) selected item
  self.selected_index = property(self.get_selected_index,self.set_selected_index)
  
  --- (bool) enforce that at least one item remains selected at all times
  self.require_selection = property(self.get_require_selection,self.set_require_selection)

  --- (table>row>col:variant) the data 
  -- an extra property, item_id, is added runtime
  self.data = property(self.get_data,self.set_data)
  self._data = args.data or {}

  --- (bool) automatically resize to fit number of rows
  self.autosize = property(self.get_autosize,self.set_autosize)
  self._autosize = args.autosize or true

  --- (int) number of visible rows
  self.num_rows = property(self.get_num_rows,self.set_num_rows)
  self._num_rows = args.num_rows or vTree.NUM_ROWS_DEFAULT

  --- (int) row height
  self.row_height = property(self.get_row_height,self.set_row_height)
  self._row_height = args.row_height or vTree.ROW_HEIGHT_DEFAULT

  --- (int) offset, vertical "scroll" position 
  self.row_offset = property(self.get_row_offset,self.set_row_offset)
  self._row_offset = 0

  --- (int) amount of identation in pixels
  self.indent = property(self.get_indent,self.set_indent)
  self._indent = vTree.INDENT_DEFAULT

  --- (int) the horizontal size of node-icons
  self.icon_width = vTree.ICON_WIDTH_DEFAULT

  --- (function) fired on automatic resize
  -- @param elm (vTree) 
  self.on_resize = args.on_resize or nil

  --- (function) fired when nodes are expanded or collapsed
  -- note: you can define particular handler on a node-basis by
  -- specifying it as part of the node definition when setting data
  -- @param elm (vTree) 
  -- @param item (table) 
  self.on_toggle = args.on_toggle or nil

  --- (function) fired when a node (text label) is clicked
  -- note: you can define particular handler on a node-basis by
  -- specifying it as part of the node definition when setting data
  -- @param elm (vTree) 
  -- @param item (table) 
  self.on_select = args.on_select or nil

  --- (function) fired after each update
  -- this method can be used for custom decorators etc.
  self.on_update_complete = args.on_update_complete or nil

  --- (function) callback function for when selection has changed
  -- @param elm (vTree)
  self._selection_notifier = args.selection_notifier or nil
  self.selection_notifier = property(self.get_selection_notifier,self.set_selection_notifier)

  -- internal -------------------------

  -- (vScrollbar)
  self.scrollbar = nil

  -- (string) unique identifier for views
  self.uid = vLib.generate_uid()

  -- (int) unique identifier for data items
  self.item_id = nil
  
  -- (int) width in pixels excluding scrollbar
  self.inner_width = nil

  -- (table) for faster lookup of items (via unique data id)
  self.map = nil

  -- (int) this is used while updating display 
  self.update_row_idx = nil
  self.skipped_row_idx = nil
  --self.skipped_items = nil

  -- (int) 
  self.visible_row_count = nil

  -- (bool) when table dimensions have changed
  -- this will rebuild the table as part of the next update 
  self.rebuild_requested = false

  -- (string) id for setting explicit width
  self.spacer_h_id = "spacer_h_"..self.uid
  self.spacer_w_id = "spacer_w_"..self.uid
  self.tree_id = "tree_elm_"..self.uid


  vControl.__init(self,...)
  self:build()

  -- 
  self:set_width(self._width)

  --if args.select_mode then
  --  self:set_select_mode(args.select_mode,skip_event)
  --end 
  if (type(args.require_selection)=="boolean") then
    self:set_require_selection(args.require_selection,skip_event)
  end 


  if self._data then
    self:set_data(self._data)
  end

end

--------------------------------------------------------------------------------

function vTree:get_elm_id(str,idx)
  TRACE("vTree:get_elm_id(str,idx)",str,idx)
  return ("vtree_%s_%d_%s"):format(str,idx,self.uid)
end

--------------------------------------------------------------------------------

function vTree:build()
  TRACE("vTree:build()")

  self.rebuild_requested = false

  local vb = self.vb
  
  if not self.view then
    -- first run
    self.view = vb:row{
      id = self.id,
      style = "plain",
      vb:column{
        vb:space{
          id = self.spacer_w_id,
          height = 1,
          width = 1,
        },
        vb:row{
          vb:space{
            id = self.spacer_h_id,
            height = 1,
            width = 1,
          },
          vb:column{
            id = self.tree_id
          },
        },
      },
    }
    -- create once: scrollbar
    self.scrollbar = vScrollbar{
      vb = vb,
      --width = self._scrollbar_width,
      do_change = function(val)
        local offset = self.scrollbar:get_index()
        if (offset ~= self._row_offset) then
          self.row_offset = offset
        end
      end,
    }
    self.view:add_child(self.scrollbar.view)

  end

  local table_elm = vb.views[self.tree_id]

  for row_idx = 1,self._num_rows do

    local row_id = self:get_elm_id("row",row_idx)
    local hidden_id = self:get_elm_id("hidden",row_idx)
    local space_id = self:get_elm_id("space",row_idx)
    local bitmap_id = self:get_elm_id("bitmap",row_idx)
    local text_id = self:get_elm_id("text",row_idx)

    table_elm:add_child(vb:row{
      id = row_id,
      width = self._width,
      --style = "panel",
      vb:text{
        id = hidden_id,
        visible = false,
      },
      vb:space{
        id = space_id,
      },
      vb:bitmap{
        id = bitmap_id,
        bitmap = vLib.DEFAULT_BMP,
        mode = "transparent",
        notifier = function()
          local hidden_elm = self.vb.views[hidden_id]
          local item = self.map[hidden_elm.text]
          if (#item > 0) then
            -- custom callbacks
            if item.on_toggle then
              item.on_toggle(self,item)
            elseif self.on_toggle then
              self.on_toggle(self,item)
            else
              -- default: toggle branch
              item.expanded = not item.expanded
              if not item.expanded then
                -- if we collapsed a branch, and there is
                -- unused space below - scroll up, until the
                -- available space is used by the tree
                self.row_offset = math.max(0,self.row_offset-(self.num_rows-row_idx))
              end
            end
            self:update()
            self:update_scrollbar(true) -- maintain_index
          else
            if item.on_select then
              item.on_select(self,item)
            elseif self.on_select then
              self.on_select(self,item)
            else
              -- default: select node
              self:set_selected_index(item.item_id)
            end
          end

        end,
      },
      vb:checkbox{
        visible = false,
        notifier = function(val)
          local hidden_elm = self.vb.views[hidden_id]
          local item = self.map[hidden_elm.text]
          if item.on_select then
            item.on_select(self,item)
          elseif self.on_select then
            self.on_select(self,item)
          else
            -- default: select node
            self:set_selected_index(item.item_id)
          end
        end
      },
      vb:text{
        id = text_id,
        text = "Item",
        height = self._row_height,
      },
    })


  end



end

--------------------------------------------------------------------------------

function vTree:remove_rows()
  TRACE("vTree:remove_rows()")
  
  local vb = self.vb
  local table_elm = vb.views[self.tree_id]

  local aspects = {"hidden","space","bitmap","text"}

  for row_idx = 1, self._num_rows do
    local row_id = self:get_elm_id("row",row_idx)
    local row_elm = vb.views[row_id]
    for k,v in ipairs(aspects) do
      local elm_id = self:get_elm_id(v,row_idx)
      row_elm:remove_child(vb.views[elm_id])
      vb.views[elm_id] = nil
    end
    table_elm:remove_child(row_elm)
    vb.views[row_id] = nil
  end

end

--------------------------------------------------------------------------------
-- resize rows 

function vTree:fit_rows_width()

  for row_idx = 1, self._num_rows do
    local row_id = self:get_elm_id("row",row_idx)
    local row_elm = self.vb.views[row_id]
    if row_elm then
      row_elm.width = self.inner_width
    end
  end
end

--------------------------------------------------------------------------------
-- update table using current settings (rebuild if needed)

function vTree:update()
  TRACE("vTree:update()")

  if self.rebuild_requested then
    self:build()
  end

  self.update_row_idx = 1
  self.skipped_row_idx = 1
  self:update_tree(self._data)

  -- show rows, hide superflous rows 
  for row_idx = 1,self.num_rows do
    local row_elm = self.vb.views[self:get_elm_id("row",row_idx)]
    row_elm.visible = (row_idx <= self.update_row_idx) and true or false
  end

  self:fit_rows_width()

  if self.on_update_complete then
    self.on_update_complete()
  end

end

--------------------------------------------------------------------------------
-- recursive method, will iterate through table and update each row

function vTree:update_tree(t,depth)
  TRACE("vTree:update_tree(t,depth)",t,depth)

  if not depth then
    depth = 1
  end

  local update_row = function(t)
    
    local vb = self.vb

    local row_elm = vb.views[self:get_elm_id("row",self.update_row_idx)]
    if not row_elm then -- exceeded num_rows
      return
    end

    local hidden_elm = vb.views[self:get_elm_id("hidden",self.update_row_idx)]
    local space_elm = vb.views[self:get_elm_id("space",self.update_row_idx)]
    local bitmap_elm = vb.views[self:get_elm_id("bitmap",self.update_row_idx)]
    local text_elm = vb.views[self:get_elm_id("text",self.update_row_idx)]

    space_elm.width = math.max(1,(depth-1) * self._indent)
    bitmap_elm.width = self.icon_width

    -- properties

    if t.name then
      text_elm.text = t.name
    else
      text_elm.text = "(untitled)"
    end

    if t.icon then
      bitmap_elm.bitmap = t.icon
    else
      if (#t > 0) then
        if t.expanded then
          bitmap_elm.bitmap = vTree.ICON_NODE_EXPANDED
        else
          bitmap_elm.bitmap = vTree.ICON_NODE_COLLAPSED
        end
      else
        bitmap_elm.bitmap = vTree.ICON_NODE_ITEM 
      end
    end

    if t.item_id then

      -- add a hidden element with the unique data id,
      -- for locating the data in event handlers...
      hidden_elm.text = tostring(t.item_id)

      -- set the "selected" style 
      local is_selected = self.selection:contains_index(t.item_id)
      row_elm.style = is_selected and 
        vTree.ROW_STYLE_SELECTED or vTree.ROW_STYLE_NORMAL

    end
  
    -- crop the element
    row_elm.width = self.inner_width 

    bitmap_elm.height = self._row_height
    text_elm.height = self._row_height
    hidden_elm.height = self._row_height
    space_elm.height = self._row_height

  end -- / update_row

  if (self.skipped_row_idx > self.row_offset+1) then 
    update_row(t)
  else
    self.skipped_row_idx = self.skipped_row_idx+1

    if (self.skipped_row_idx > self.row_offset+1) then
      self.update_row_idx = 1
      update_row(t)
    end

  end

  if t.expanded then
    for k,v in ipairs(t) do
      if (self.skipped_row_idx > self.row_offset+1) then 
        self.update_row_idx = self.update_row_idx+1
      end
      self:update_tree(v,depth+1)
    end
  end

end

--------------------------------------------------------------------------------

function vTree:update_scrollbar(maintain_index)
  TRACE("vTree:update_scrollbar(maintain_index)",maintain_index)

  self.visible_row_count = 0
  self:get_visible_row_count(self._data)

  local old_index = self.scrollbar:get_index()

  self.scrollbar.step_count = math.max(0,self.visible_row_count - self._num_rows)
  self.scrollbar.active =  (self.visible_row_count > self._num_rows) 
  
  self.scrollbar:set_index(old_index)


end
  
--------------------------------------------------------------------------------
-- get the number of rows in the data which can be shown
-- (used for determining range of the scrollbar)

function vTree:get_visible_row_count(t)
  TRACE("vTree:get_visible_row_count(t)",t)

  if not t.expanded then
    return
  end

  self.visible_row_count = self.visible_row_count+1

  for k,v in ipairs(t) do
    if (#v > 0) then
      if v.expanded then
        self:get_visible_row_count(v)
      else
        self.visible_row_count = self.visible_row_count+1
      end
    else
      self.visible_row_count = self.visible_row_count+1
    end
  end
  
end
  
--------------------------------------------------------------------------------
-- + add a unique id to all nodes, and cache this (.map)
-- + initialize the "expanded" attribute

function vTree:parse_data(t)
  TRACE("vTree:parse_data(t)",t)

  if not t.item_id then
    t.item_id = self.item_id
  end

  if (type(t.expanded) ~= "boolean") then
    t.expanded = true
  end

  self.map[tostring(t.item_id)] = t
  self.item_id = self.item_id+1
  for k,v in ipairs(t) do
    self:parse_data(v)
  end

end

--------------------------------------------------------------------------------
-- call this the computed height of the table has changed - 
-- if resized, the external resize handler is invoked

function vTree:autosize_to_contents()
  TRACE("vTree:autosize_to_contents()")

  if not self.autosize then
    return
  end

  local old_h = self._height
  self.height = self:get_height()

  if (self._height ~= old_h) then
    self.scrollbar.height = self._height
    if self.on_resize then
      self.on_resize(self)
    end
  end

end

--------------------------------------------------------------------------------
--- load data from an external source
-- note: each file format needs to implement the load_and_parse() method
-- @param file_path (string) source file - if undefined, file browser is shown

function vTree:load_file(file_path)
  TRACE("vTree:load_file(file_path)")

  local function get_supported_extensions()
    local rslt = {}
    for k,v in ipairs(vTree.file_formats) do
      table.insert(rslt,("*.%s"):format(v.extension))
    end 
    return rslt
  end

  if not file_path then
    local extensions = get_supported_extensions()
    file_path = renoise.app():prompt_for_filename_to_read(extensions,"Open file")
  end

  if not file_path or (file_path == "") then
    return
  end

  local data = nil
  local folder,filename,ext = cFilesystem.get_path_parts(file_path)
  for k,v in ipairs(vTree.file_formats) do

    if (v.extension == ext) then
      if v.parser.load_and_parse then
        data = v.parser:load_and_parse(file_path)
        self:set_data(data)
      end
    end
  end

end

--------------------------------------------------------------------------------

function vTree:get_row_by_id(item_id)
  TRACE("vTree:get_row_by_id(item_id)",item_id)

  for row_idx = 1, self._num_rows do
    local hidden_id = self:get_elm_id("hidden",row_idx)
    local hidden_elm = self.vb.views[hidden_id]
    if (hidden_elm.text == item_id) then
      local row_id = self:get_elm_id("row",row_idx)
      return self.vb.views[row_id]
    end
  end

end

--------------------------------------------------------------------------------
--- update display after having called the selection class

function vTree:selection_handler(changed,added,removed)
  TRACE("vTree:selection_handler(changed,added,removed)",changed,added,removed)

  if changed then
    for k,v in ipairs(removed) do
      local item = self.map[tostring(v)]
      if item then
        local row_elm = self:get_row_by_id(tostring(v))
        if row_elm then
          row_elm.style = vTree.ROW_STYLE_NORMAL
        end
      end
    end
    for k,v in ipairs(added) do
      local item = self.map[tostring(v)]
      if item then
        local row_elm = self:get_row_by_id(tostring(v))
        if row_elm then
          row_elm.style = vTree.ROW_STYLE_SELECTED
        end
      end
    end

    self:fit_rows_width()

    if self._selection_notifier then
      self._selection_notifier(self)
    end
  end

end

--------------------------------------------------------------------------------
-- Getters and setters 
--------------------------------------------------------------------------------

function vTree:set_data(data)
  TRACE("vTree:set_data(data)",data)

  if (type(data)~="table") then
    return
  end
  if table.is_empty(data) then
    self.map = {}
  else
    -- add/register unique ID for quick access 
    self.item_id = 1000
    self.map = {}
    self:parse_data(data)
  end
  self._data = data
  self:update_scrollbar()
  self.scrollbar:set_position(0)
  self:update()
end


function vTree:get_data()
  return self._data
end


--------------------------------------------------------------------------------

function vTree:set_num_rows(num)
  TRACE("vTree:set_num_rows(num)",num)

  num = math.min(num,vTree.MAX_ROWS)
  if (self._num_rows ~= num) then
    -- remove existing rows while we 
    -- know how many we've got...
    self:remove_rows()
    self._num_rows = num
    self.rebuild_requested = true
    self:update()
    self:autosize_to_contents()
    self:update_scrollbar()
  end
end

function vTree:get_num_rows()
  return self._num_rows
end

--------------------------------------------------------------------------------

function vTree:set_row_offset(val)
  self._row_offset = math.max(0,val) 
  self:update()
end

function vTree:get_row_offset()
  return self._row_offset
end

--------------------------------------------------------------------------------

function vTree:set_indent(val)
  self._indent = math.max(0,val) 
  self:update()
end

function vTree:get_indent()
  return self._indent
end

--------------------------------------------------------------------------------

function vTree:set_width(val)
  local spacer = self.vb.views[self.spacer_w_id]
  self.inner_width = val - (self.scrollbar.width)
  spacer.width = self.inner_width
  self:fit_rows_width()
  vControl.set_width(self,val)
  self:update() -- "crop" rows
end

--------------------------------------------------------------------------------

function vTree:set_height(val)
  local new_h = val
  local spacer_h = self.vb.views[self.spacer_h_id]
  if self.autosize then
    new_h = self:get_height()
  end
  spacer_h.height = new_h
  self.scrollbar.height = new_h
  vControl.set_height(self,new_h)
  if self.autosize and self.on_resize then
    self.on_resize(self)
  end
end

-- get computed height of table, including header
-- @return int

function vTree:get_height()
  if not self.autosize then
    return self._height
  else
    local tree_h = self._num_rows * self._row_height
    return math.max(vTree.TREE_MIN_H,tree_h)
  end
end

--------------------------------------------------------------------------------

function vTree:set_row_height(val)
  self._row_height = math.max(val,vTree.ROW_HEIGHT_MIN)
  self:autosize_to_contents()
  self:update()
end

function vTree:get_row_height()
  return self._row_height
end

--------------------------------------------------------------------------------

function vTree:set_autosize(val)
  self._autosize = val
  self:autosize_to_contents()
  self:update()
end

function vTree:get_autosize()
  return self._autosize
end

--------------------------------------------------------------------------------

function vTree:set_selected_index(idx)
  TRACE("vTree:set_selected_index(idx)",idx)
  local changed,added,removed = self.selection:set_index(idx)
  self:selection_handler(changed,added,removed)
end

function vTree:get_selected_index()
  return self.selection.index
end

--------------------------------------------------------------------------------
--[[
function vTree:set_selected_indices(t)

  local changed,added,removed = self.selection:set_indices(t)
  self:selection_handler(changed,added,removed)

end

function vTree:get_selected_indices()
  return self.selection.indices
end

--------------------------------------------------------------------------------

function vTree:set_select_mode(val,skip_event)
  TRACE("vTree:set_select_mode(val)",val)
  local changed,added,removed = self.selection:set_mode(val)
  if not skip_event then
    self:selection_handler(changed,added,removed)
  end

end

function vTree:get_select_mode()
  return self.selection.mode
end
]]
--------------------------------------------------------------------------------

function vTree:set_require_selection(val,skip_event)
  TRACE("vTree:set_require_selection(val)",val)
  local changed,added,removed = self.selection:set_require_selection(val)
  if not skip_event then
    self:selection_handler(changed,added,removed)
  end
end

function vTree:get_require_selection()
  return self.selection.require_selection
end

