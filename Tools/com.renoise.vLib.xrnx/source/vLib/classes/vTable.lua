--[[============================================================================
vTable 
============================================================================]]--

--  A fully functional table widget, including vScrollbar and custom cells 
--  
--  The data-source is a standard table, with the following extra properties
--    __item_id   : a unique ID for identifying item
--    __row_style : a valid Viewbuilder.Rack style property
--

require (_vlibroot.."vControl")
require (_vlibroot.."vScrollbar")
require (_vlibroot.."vCell")
require (_vlibroot.."vCellButton")
require (_vlibroot.."vCellBitmap")
require (_vlibroot.."vCellCheckBox")
require (_vlibroot.."vCellPopup")
require (_vlibroot.."vCellText")
require (_vlibroot.."vCellValueBox")
require (_vlibroot.."vCellTextField")
require (_vlibroot.."helpers/vDataProvider")
require (_vlibroot.."helpers/vVector")
require (_vlibroot..'helpers/vSelection')

class 'vTable' (vControl)

--------------------------------------------------------------------------------

-- available cell types
vTable.CELLTYPE = {
  TEXT = 1,
  CHECKBOX = 2,
  BUTTON = 3,
  BITMAP = 4,
  POPUP = 5,
  VALUEBOX = 6,
  TEXTFIELD = 7,
}

vTable.CELL_STYLE = "panel"
vTable.HEADER_STYLE = "body"
vTable.ROW_STYLE = "invisible"
vTable.TABLE_STYLE = "invisible"

vTable.CELLTYPE_DEFAULT = vTable.CELLTYPE.TEXT
vTable.COLMARGIN_DEFAULT = 0
vTable.HEADER_HEIGHT_DEFAULT = 19
vTable.HEADER_HEIGHT_MIN = 8
vTable.MARGIN_DEFAULT = 1
vTable.NUM_ROWS_DEFAULT = 6
vTable.ROW_HEIGHT_DEFAULT = 22
vTable.DEFAULT_WIDTH = 400

vTable.CELL_MIN_H = 8
vTable.CELL_MIN_W = 8
vTable.MAX_COLS = 42
vTable.MAX_ROWS = 42
vTable.STR_CELL_ID = "row_%i_col_%i_%s"
vTable.STR_HEADER_ID = "header_%i_%s"
vTable.STR_ROW_ID = "row_%i_%s"
vTable.TABLE_MIN_H = 8
vTable.TABLE_MIN_W = 8

-- skip these keys when assigning dynamic properties to cells
vTable.HEADER_DEF_KEYS = {"data","col_type"}
vTable.COLUMN_DEF_KEYS = {"key","col_width","col_type","margin"}

-- meta-properties of data
vTable.META = {
  --ID   = "item_id",
  ICON = "item_icon",
  TYPE = "item_type",
  ROW_STYLE = "__row_style",
}


function vTable:__init(...)
  TRACE("vTable:__init(...)",...)

  local args = cLib.unpack_args(...)

  --- (table>table) header definition (by key)
  -- Required values: vTable.HEADER_DEF_KEYS
  -- + any cell members 
  self.header_defs = args.header_defs or {}

  --- (table>table>table) columns definition
  -- Required keys: vTable.COLUMN_DEF_KEYS
  self.column_defs = args.column_defs or {}

  --- (table>row>col:variant) the data 
  -- an extra property, item_id, is added runtime
  self.data = property(self.get_data,self.set_data)

  --- (bool) show_header
  self.show_header = property(self.get_show_header,self.set_show_header)
  self._show_header = args.show_header or true

  --- (int) TODO pass as separate constructor args
  self.scrollbar_width = property(self.get_scrollbar_width,self.set_scrollbar_width)
  self._scrollbar_width = args.scrollbar_width or vScrollbar.DEFAULT_W

  --- (bool) automatically resize to fit number of rows
  self.autosize = property(self.get_autosize,self.set_autosize)
  self._autosize = args.autosize or true

  --- (int) number of visible rows
  self.num_rows = property(self.get_num_rows,self.set_num_rows)
  self._num_rows = args.num_rows or vTable.NUM_ROWS_DEFAULT

  --- (int) row height
  self.row_height = property(self.get_row_height,self.set_row_height)
  self._row_height = args.row_height or vTable.ROW_HEIGHT_DEFAULT

  --- (int) header height
  self.header_height = property(self.get_header_height,self.set_header_height)
  self._header_height = args.header_height or vTable.HEADER_HEIGHT_DEFAULT

  --- (string) styles
  self.table_style = args.table_style or vTable.TABLE_STYLE
  self.header_style = args.header_style or vTable.HEADER_STYLE
  self.row_style = args.row_style or vTable.ROW_STYLE
  self.cell_style = args.cell_style or vTable.CELL_STYLE

  --- (int) offset, vertical position in table
  -- use set_row_offset() to synchronize with scrollbar
  self.row_offset = property(self.get_row_offset,self.set_row_offset)
  self._row_offset = 0

  --- vSelection
  self.selection = vSelection()

  --- (bool) when true, setting index can cause row_offset to follow
  self.follow_row = property(self.get_follow_row,self.set_follow_row)
  self._follow_row = args.follow_row or true

  --- (function) define this to perform post-update actions,
  -- such as custom row highlighting, tooltips etc.
  -- @param elm (vTable)
  self.on_update_complete = args.on_update_complete or nil

  --- (function) when table changed size (automatic resize)
  -- @param elm (vTable)
  self.on_resize = args.on_resize or nil

  --- (function) 
  --self.on_scroll = args.on_scroll or nil


  -- internal --

  self.dataprovider = vDataProvider()

  --- (vScrollbar)
  self.scrollbar = nil

  --- (table>vCell) header cells (by key)
  self.header_cells = {}

  --- (table>row>col:vCell) table cells
  -- accessed like this: cells[row][col]
  self.cells = {}

  --- (Viewbuilder.Rack) table rows
  self.row_elms = {}

  --- (bool) when table dimensions have changed
  -- this will rebuild the table as part of the next update 
  self.rebuild_requested = true

  --- (string) unique identifier for views
  self.uid = vLib.generate_uid()

  self.spacer_h_id = "spacer_h"..self.uid
  self.spacer_w_id = "spacer_w"..self.uid
  self.table_id = "table_elm"..self.uid
  self.header_id = "header_elm"..self.uid

  -- initialize

  vControl.__init(self,...)

  --- (int) width
  self._width = self._width or args.width or vTable.DEFAULT_WIDTH
  -- note: height is derived from #number of rows


  if args.data then
    self:set_data(args.data)
  else
    self:request_update()
  end

end

--------------------------------------------------------------------------------
-- @param data (table), indexed array

function vTable:set_data(data)
  TRACE("vTable:set_data(data)",data)

  local row_offset = self._row_offset
  self.dataprovider:set_data(data)
  self.selection.num_items = #data
  self:set_row_offset(row_offset) 

  self:update_scrollbar()

end

function vTable:get_data()
  --TRACE("vTable:get_data()")
  return self.dataprovider.data
end

--------------------------------------------------------------------------------
-- assign additional properties to cells - 
-- @param cell (vCell) 
-- @param defs (table)
-- @param col_key (string or int)
-- @param reserved_keys (table) TODO skip reserved keys 

function vTable.assign_members(cell,defs,col_key,reserved_keys)
  TRACE("vTable.assign_members(cell,defs,col_key,reserved_keys)",cell,#defs,col_key,#reserved_keys)

  if cell and defs[col_key] then
    for k,v in pairs(defs[col_key]) do
      cell[k] = v
    end
  end

end

--------------------------------------------------------------------------------
-- (re)build the actual view, using the current column/row count

function vTable:build()
  TRACE("vTable:build()")

  local vb = self.vb
  
  if self.view then
    -- clear existing table
    self:remove_table()
  else
    -- create once: basic structure
    self.view = vb:row{
      id = self.id,
      style = "plain",
      --style = "panel",
      vb:column{
        style = self.table_style,
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
            id = self.table_id
          },
        },
      },
    }
    -- create once: scrollbar
    self.scrollbar = vScrollbar{
      vb = self.vb,
      width = self._scrollbar_width,
      do_change = function(val)
        local offset = self.scrollbar:get_index()
        if (offset ~= self._row_offset) then
          self.row_offset = offset
        end
      end,
    }
    self.view:add_child(self.scrollbar.view)

  end

  -- (re)create each time -------------

  local table_elm = vb.views[self.table_id]

  -- table headers 
  local header_root = vb:row{
    id = self.header_id,
  }
  --for k = 1,self.num_cols do
  for k = 1,#self.column_defs do
    local col_key = self:get_col_key(k)
    local header_cell_elm = vb:row{
      id = (vTable.STR_HEADER_ID):format(k,self.uid),
      style = self.header_style,
    }
    local ctype = self:get_header_ctype(col_key) 
    local header_cell = self:cell_factory(ctype)
    header_cell_elm:add_child(header_cell.view)
    header_root:add_child(header_cell_elm)
    self.assign_members(header_cell,self.header_defs,col_key,vTable.HEADER_DEF_KEYS)
    self.header_cells[col_key] = header_cell
  end
  table_elm:add_child(header_root)

  -- build table ...
  self.row_elms = {}
  self.cells = {}
  for row = 1,self._num_rows do
    self.cells[row] = {}
    local row_id = (vTable.STR_ROW_ID):format(row,self.uid)
    local row_elm = vb:row{
      id = row_id,
      style = self.row_style,
    }
    for col_idx = 1,#self.column_defs do
      local col_margin = self:get_col_margin(col_idx)
      local cell_elm = vb:row{
        id = (vTable.STR_CELL_ID):format(row,col_idx,self.uid),
        style = self.cell_style,
        margin = col_margin,
      }
      local ctype = self:get_col_type(col_idx)
      local cell = self:cell_factory(ctype)
      cell_elm:add_child(cell.view)
      row_elm:add_child(cell_elm)
      --self.assign_properties(cell,self.column_defs[col_idx].cell_props)
      self.assign_members(cell,self.column_defs,col_idx,vTable.COLUMN_DEF_KEYS)
      self.cells[row][col_idx] = cell
    end
    table_elm:add_child(row_elm)
    table.insert(self.row_elms,row_elm)
  end


end

--------------------------------------------------------------------------------
-- produce a cell of the given type

function vTable:cell_factory(ctype)
  TRACE("vTable:cell_factory(ctype)",ctype)

  local vb = self.vb
  local cell = nil
  if (ctype == vTable.CELLTYPE.TEXT) then 
    cell = vCellText{
      vb = vb, 
      owner = self
    }
  elseif (ctype == vTable.CELLTYPE.VALUEBOX) then
    cell = vCellValueBox{
      vb = vb, 
      owner = self
    }
  elseif (ctype == vTable.CELLTYPE.POPUP) then
    cell = vCellPopup{
      vb = vb, 
      owner = self
    }
  elseif (ctype == vTable.CELLTYPE.BUTTON) then
    cell = vCellButton{
      vb = vb, 
      owner = self
    }
  elseif (ctype == vTable.CELLTYPE.BITMAP) then
    cell = vCellBitmap{
      vb = vb, 
      owner = self
    }
  elseif (ctype == vTable.CELLTYPE.CHECKBOX) then
    cell = vCellCheckBox{
      vb = vb, 
      owner = self
    }
  elseif (ctype == vTable.CELLTYPE.TEXTFIELD) then
    cell = vCellTextField{
      vb = vb, 
      owner = self
    }
  else
    error("vTable.build() - Unsupported cell type",ctype)
  end

  return cell

end


--------------------------------------------------------------------------------
-- remove existing viewbuilder before rebuilding the table 
-- (using the maximum possible table size)

function vTable:remove_table()
  TRACE("vTable:remove_table()")

  local vb = self.vb
  local table_elm = vb.views[self.table_id]
  local header_elm = vb.views[self.header_id]

  if not table_elm then
    return
  end

  -- remove headers
  if header_elm then
    for col = 1,vTable.MAX_COLS do
      local header_cell_id = (vTable.STR_HEADER_ID):format(col,self.uid)
      local header_cell_elm = vb.views[header_cell_id]
      if header_cell_elm then
        header_elm:remove_child(header_cell_elm)
        vb.views[header_cell_id] = nil
      end
    end
    table_elm:remove_child(header_elm)
    vb.views[self.header_id] = nil
  end

  -- remove table cells
  if table_elm then
    for row = 1, vTable.MAX_ROWS do
      local row_id = (vTable.STR_ROW_ID):format(row,self.uid)
      local row_elm = vb.views[row_id]
      if row_elm then
        for col = 1, vTable.MAX_COLS do
          local cell_id = (vTable.STR_CELL_ID):format(row,col,self.uid)
          local cell_elm = vb.views[cell_id]
          if cell_elm then
            vb.views[row_id]:remove_child(cell_elm)
            vb.views[cell_id] = nil
          end
        end
        table_elm:remove_child(row_elm)
        vb.views[row_id] = nil
      end
    end

  end

end

--------------------------------------------------------------------------------

function vTable:update()
  TRACE("vTable:update()")

  local vb = self.vb

  local get_cell_width = function(width,margin)
    return math.max(vTable.CELL_MIN_W, width - (margin*2))
  end

  local get_cell_height = function(margin)
    return math.max(vTable.CELL_MIN_H, self._row_height - (margin*2))
  end
  
  local get_header_height = function(margin)
    return math.max(vTable.CELL_MIN_H, self._header_height - (margin*2))
  end
  
  -- if dimensions have changed, rebuild table
  if self.rebuild_requested then
    self.rebuild_requested = false
    self:build()
  end

  -- update header value/size
  for col = 1,#self.column_defs do
    local key = self:get_col_key(col)
    local col_margin = self:get_col_margin(col)
    local col_width = self:get_col_width(col)
    local header_cell = self.header_cells[key]
    header_cell.width = get_cell_width(col_width,col_margin)
    header_cell.height = get_header_height(col_margin)
    local header_data = self:get_header_data(key)
    if (type(header_data) == "nil") then
      -- use key when no header data is available
      if (type(header_cell.DEFAULT_VALUE) == "string") then
        header_cell:set_value(key)
      end
    else
      header_cell:set_value(header_data,true)
    end
    local header_elm = vb.views[self.header_id]
    header_elm.visible =  self._show_header 
  end

  -- update cells
  for row = 1,self._num_rows do

    local row_offset = row + self._row_offset
    local row_elm = self.row_elms[row]
    local row_data = self.data[row_offset]

    local item
    if row_data then
      item = self.dataprovider:get(row_data[vDataProvider.ID])
    end

    -- apply custom styling to row?
    if item then
      if item.__row_style then
        row_elm.style = item.__row_style
      else
        row_elm.style = self.row_style
      end
    end

    -- update cells 
    for col = 1,#self.column_defs do
      local key = self:get_col_key(col)
      local col_margin = self:get_col_margin(col)
      local col_width = self:get_col_width(col)
      local cell = self.cells[row][col]
      cell.width = get_cell_width(col_width,col_margin)
      cell.height = get_cell_height(col_margin)
      if not row_data then
        cell.visible = false
        cell:set_value(nil,true)
      elseif not type(row_data[key]=="nil") then
        -- no data for cell
        cell.visible = false
      else
        cell.visible = true
        cell.item_id = row_data.item_id
        cell:set_value(row_data[key])
      end
    end

  end

  if not self.autosize then
    vControl.set_height(self,self._height)
  else
    if not self._height then
      self:set_height(self:get_height())
    end
  end
    vControl.set_width(self,self._width)

  -- callback func --------------------

  if self.on_update_complete then
    self.on_update_complete(self)
  end

end

--------------------------------------------------------------------------------
-- retrieve direct reference to cell object 
-- @return vCell or nil

function vTable:get_cell(row_idx,col_idx)
  --TRACE("vTable:get_cell(row_idx,col_idx)",row_idx,col_idx)
  if (row_idx > self._num_rows) then
    error("Invalid row index specified, should be less or equal to",self._num_rows)
  end
  if (col_idx > #self.column_defs) then
    error("Invalid column index specified, should be less or equal to",#self.column_defs)
  end
  return self.cells[row_idx][col_idx]
end

--------------------------------------------------------------------------------
-- get computed width of table, all (absolute) column widths put together
-- @return int

function vTable:get_content_width()
  --TRACE("vTable:get_content_width()")
  local w = 0
  local abs_only = true 
  for i = 1,#self.column_defs do
    w = w + self:get_col_width(i,abs_only)
  end
  return math.max(vTable.TABLE_MIN_W,w)
end

--------------------------------------------------------------------------------
-- set visible column count, rebuild if needed
-- @param num (int)

function vTable:set_num_rows(num)
  TRACE("vTable:set_num_rows(num)",num)
  num = math.min(num,vTable.MAX_ROWS)
  if (self._num_rows ~= num) then
    self._num_rows = num
    self:update_scrollbar()
    self.rebuild_requested = true
    self:request_update()
    self:autosize_to_contents()
  else
    self._num_rows = num
  end
end

function vTable:get_num_rows()
  --TRACE("vTable:set_num_rows()")
  return self._num_rows
end

--------------------------------------------------------------------------------
-- @param idx (int)
-- @return vTable.CELLTYPE

function vTable:get_col_type(idx)
  --TRACE("vTable:get_col_type(idx)")
  if self.column_defs[idx] and
    self.column_defs[idx].col_type
  then
    return self.column_defs[idx].col_type
  else
    return vTable.CELLTYPE_DEFAULT
  end
end

--------------------------------------------------------------------------------
-- retrieve the key of a column definition 
-- @param idx (int)
-- @return string or nil

function vTable:get_col_key(idx)
  --TRACE("vTable:get_col_key(idx)")
  if self.column_defs[idx] and
    self.column_defs[idx].key
  then
    return self.column_defs[idx].key
  end
end

--------------------------------------------------------------------------------
-- retrieve the idx of a column definition by its key
-- @param key (string)
-- @return int or nil

function vTable:get_col_idx(key)
  --TRACE("vTable:get_col_idx(key)",key)

  for k,v in ipairs(self.column_defs) do
    if (v.key == key) then
      return k
    end
  end 

end

--------------------------------------------------------------------------------
-- retrieve the absolute width in pixels for a given column
-- @param idx (int)
-- @param abs_only (bool) only check for absolute values
-- @return int 

function vTable:get_col_width(idx,abs_only)
  --TRACE("vTable:get_col_width(idx,abs_only)",idx,abs_only)
  if self.column_defs[idx] and
    self.column_defs[idx].col_width
  then
    local col_w = self.column_defs[idx].col_width
    if not abs_only then
      if (col_w == "auto") then
        return self:compute_auto_width(idx)
      end
    end
    if (type(col_w) == "number") then
      return col_w    
    elseif (type(col_w) == "string") 
      and (string.find(col_w,"%%"))
    then
      local percentage = cLib.string_to_percentage(col_w)
      return (self._width/100)*percentage
    else
      return 0
    end
  else
    return self:compute_auto_width(idx)
  end
end

--------------------------------------------------------------------------------
-- compute automatic width of column
-- @param idx (int)
-- @return int 

function vTable:compute_auto_width(idx)
  --TRACE("vTable:compute_auto_width(idx)",idx)
  local abs_width = self._scrollbar_width
  local auto_count = 0
  for k,v in ipairs(self.column_defs) do
    -- absolute value
    if (type(v.col_width) == "number") then
      abs_width = abs_width+v.col_width
    -- auto/undefined
    elseif (type(v.col_width) == "nil") or
      (v.col_width == "auto") 
    then
      auto_count = auto_count+1
    end
  end
  return (self._width - abs_width) / auto_count

end

--------------------------------------------------------------------------------
-- retrieve the margin for a column
-- @param idx (int)
-- @return int 

function vTable:get_col_margin(idx)
  --TRACE("vTable:get_col_margin(idx)",idx)
  if self.column_defs[idx] and 
    self.column_defs[idx].margin 
  then
    return self.column_defs[idx].margin
  else
    return vTable.COLMARGIN_DEFAULT
  end

end

--------------------------------------------------------------------------------
-- DEPRICATED just here for compability

function vTable:get_item_by_id(item_id)
  --TRACE("vTable:get_item_by_id(item_id)")
  return self.dataprovider:get(item_id)
end

--------------------------------------------------------------------------------
-- @param key (string)
-- @return variant or nil 

function vTable:get_header_data(key)
  --TRACE("vTable:get_header_data(key)",key)
  if self.header_defs[key] and 
    --self.header_defs[key].data
    (type(self.header_defs[key].data) ~= "nil")
  then
    return self.header_defs[key].data
  end
end

--------------------------------------------------------------------------------
--- retrieve a header type by key
-- @param key (string)
-- @return vLib.vTable.CELLTYPE

function vTable:get_header_ctype(key)
  --TRACE("vTable:get_header_ctype(key)",key)
  if self.header_defs[key] and 
    self.header_defs[key].col_type 
  then
    return self.header_defs[key].col_type
  else
    return vTable.CELLTYPE_DEFAULT
  end
end

--------------------------------------------------------------------------------
--- specify a single header defitions by its key 
-- @param key (string), the column key
-- @param member (string), e.g.'notifier'
-- @param value (variant), e.g. a callback function or other type

function vTable:set_header_def(key,member,value)
  TRACE("vTable:set_header_def(key,member,value)",key,member,value)
  self.header_defs[key][member] = value
  local cell = self.header_cells[key]
  self.assign_members(cell,self.header_defs,key,vTable.HEADER_DEF_KEYS)
end

--------------------------------------------------------------------------------
--- specify a single column definition by its key 
-- @param key (string), the column key
-- @param member (string), e.g.'notifier'
-- @param value (variant), e.g. a callback function or other type

function vTable:set_column_def(key,member,value)
  TRACE("vTable:set_column_def(key,member,value)",key,member,value)
  for k,v in ipairs(self.column_defs) do
    if (v.key == key) then   
      v[member] = value
      -- assign to cells
      local col_idx = self:get_col_idx(key)
      for row_idx = 1, self._num_rows do
        local cell = self.cells[row_idx][col_idx]
        self.assign_members(cell,self.column_defs,col_idx,vTable.COLUMN_DEF_KEYS)
      end
    end
  end
end

--------------------------------------------------------------------------------
-- call this whenever something has changed that will affect the computed 
-- height of the table - if resized (changed size), the external resize 
-- handler is invoked, giving the host application a chance to respond

function vTable:autosize_to_contents()
  TRACE("vTable:autosize_to_contents()")
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
-- Getters and setters 
--------------------------------------------------------------------------------

function vTable:set_width(val)
  TRACE("vTable:set_width(val)",val)
  local table_w = math.max(val,self:get_content_width())
  local spacer = self.vb.views[self.spacer_w_id]
  spacer.width = table_w - (self._scrollbar_width + 3)
  vControl.set_width(self,val)
  self:request_update()
end

--------------------------------------------------------------------------------

function vTable:set_height(val)
  TRACE("vTable:set_height(val)",val)
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

--- get computed height of table, including header
-- @return int
function vTable:get_height()
  --TRACE("vTable:get_height()")
  if not self.autosize then
    return self._height
  else
    local header_h = (self._show_header) and self._header_height or 0
    local table_h = self._num_rows * self._row_height
    return math.max(vTable.TABLE_MIN_H,header_h+table_h)
  end
end

--------------------------------------------------------------------------------

function vTable:set_scrollbar_width(val)
  TRACE("vTable:set_scrollbar_width(val)",val)
  self._scrollbar_width = val
  if self.scrollbar then
    self.scrollbar.width = val
  end
end

function vTable:get_scrollbar_width()
  return self._scrollbar_width
end

--------------------------------------------------------------------------------

function vTable:set_row_height(val)
  TRACE("vTable:set_row_height(val)",val)
  self._row_height = val
  self:autosize_to_contents()
  self:request_update()
end

function vTable:get_row_height()
  return self._row_height
end

--------------------------------------------------------------------------------

function vTable:set_header_height(val)
  TRACE("vTable:set_header_height(val)",val)
  self._header_height = math.max(vTable.HEADER_HEIGHT_MIN,val)
  self:autosize_to_contents()
  self:request_update()
end

function vTable:get_header_height()
  return self._header_height
end

--------------------------------------------------------------------------------

function vTable:set_show_header(val)
  TRACE("vTable:set_show_header(val)",val)
  self._show_header = val
  self:autosize_to_contents()
  self:request_update()
end

function vTable:get_show_header()
  return self._show_header
end

--------------------------------------------------------------------------------

function vTable:set_autosize(val)
  TRACE("vTable:set_autosize(val)",val)
  self._autosize = val
  self:autosize_to_contents()
  self:request_update()
end

function vTable:get_autosize()
  return self._autosize
end

--------------------------------------------------------------------------------

function vTable:set_row_offset(val)
  TRACE("vTable:set_row_offset(val)",val)
  local data_count = #self.data
  if (data_count < self._num_rows) then
    self._row_offset = 0
  else
    self._row_offset = math.max(0,val) 
  end
  self:request_update()
end

function vTable:get_row_offset()
  return self._row_offset
end

--------------------------------------------------------------------------------

function vTable:set_active(val)
  TRACE("vTable:set_active(val)",val)
  for row,_ in ipairs(self.cells) do
    for col,__ in ipairs(self.cells[row]) do
      self.cells[row][col].active = val
    end
  end
  vControl.set_active(self,val)
end

--------------------------------------------------------------------------------

function vTable:update_scrollbar()
  TRACE("vTable:update_scrollbar()")
  self.scrollbar.step_count = math.max(0,#self.data - self._num_rows)
  self.scrollbar.active =  (#self.data > self._num_rows) 
end
  