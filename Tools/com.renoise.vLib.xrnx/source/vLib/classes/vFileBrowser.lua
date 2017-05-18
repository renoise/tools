--[[============================================================================
vFileBrowser 
============================================================================]]--

--[[

  A file browser component, based on vTable

  PLANNED
    * root folder - restrict browsing
    * tokens - make long paths easier to read, e.g. %bundle_path%

  CHANGELOG
    * composite control, many additional views 
    * observable path (on_changed_path is obsolete)
    * selection class 

--]]

require (_clibroot.."cFilesystem")
require (_vlibroot.."helpers/vSelection")
require (_vlibroot.."vCompositeControl")
require (_vlibroot.."vTable")

class 'vFileBrowser' (vCompositeControl)

vFileBrowser.IMAGE_PATH = _vlibroot.."images/vfilebrowser/"
vFileBrowser.DEFAULT_PATH = (os.platform() == "WINDOWS") and "C:/" or "/"
vFileBrowser.DEFAULT_EXT = {"*.*"}
vFileBrowser.CONTROL_SIZE = 18
vFileBrowser.NUM_ROWS_DEFAULT = 10
vFileBrowser.ROW_HEIGHT_DEFAULT = 16
vFileBrowser.ROW_STYLE_SELECTED = "body"
vFileBrowser.ROW_STYLE_NORMAL = "plain"
vFileBrowser.TEXTFIELD_W = 100

vFileBrowser.ITEM_TYPE = {
  FOLDER = 1,
  FILE = 2,
  PARENT = 3,
}

-- default icons (full path)
vFileBrowser.ITEM_ICON = {
  FOLDER = vFileBrowser.IMAGE_PATH.."folder.bmp",
  FILE = vFileBrowser.IMAGE_PATH.."file.bmp",
}

-- possible columns in a file browser
vFileBrowser.COLUMN = {
  CHECK = "checked",
  ICON = "item_icon",
  NAME = "name",
  --SIZE = "fsize",
  DATE = "mdate",
}

vFileBrowser.VIEWS = {
  "refresh_button",
  "reveal_button",
  "parent_button",
  "path_textfield",
  "filename_textfield",
}

--------------------------------------------------------------------------------

function vFileBrowser:__init(...)
  TRACE("vFileBrowser:__init(...)",...)

  local args = cLib.unpack_args(...)

  --- int, number of visible rows (stored in vtable)
  self._num_rows = args.num_rows or vFileBrowser.NUM_ROWS_DEFAULT
  self.num_rows = property(self.get_num_rows,self.set_num_rows)

  --- string, absolute folder path - file part is ignored
  self.path = property(self.get_path,self.set_path)
  self.path_observable = renoise.Document.ObservableString(args.path or vFileBrowser.DEFAULT_PATH)

  --- string
  self._file_ext = args.file_ext or vFileBrowser.DEFAULT_EXT
  self.file_ext = property(self.get_file_ext,self.set_file_ext)

  --- table>{ext1 = {icon},ext2 = {icon},...}
  self._file_types = args.file_types or {}
  self.file_types = property(self.get_file_types,self.set_file_types)

  --- table{string,string,string...}
  --- decide which columns to show (leave blank to show all)
  self._show_columns = args.show_columns or {}
  self.show_columns = property(self.get_show_columns,self.set_show_columns)

  --- boolean, show_header (stored in vtable)
  self._show_header = args.show_header or false
  self.show_header = property(self.get_show_header,self.set_show_header)

  --- boolean, whether to show a "..." entry at the top 
  --  (note: this option is only relevant when @show_folders is set)
  self._show_parent_folder = args.show_parent_folder or true
  self.show_parent_folder = property(self.get_show_parent_folder,self.set_show_parent_folder)

  --- boolean, use single-click to select (open) item
  self._single_select = args.single_select or false
  self.single_select = property(self.get_single_select,self.set_single_select)

  --- string, enforce this as root folder (restrict browsing)
  self.root_folder = args.root_folder or nil

  -- callbacks --

  --- function, callback event
  -- @param elm (vFileBrowser)
  -- @param item (table)
  self.on_file_open = args.on_file_open or nil

  --- (function) callback event
  -- @param elm (vFileBrowser)
  -- @param item_id (int)
  self.on_checked = args.on_checked or nil

  --- (function) callback event
  -- @param elm (vFileBrowser)
  --self.on_changed_path = args.on_changed_path or nil

  --- (function) callback event
  -- @param elm (vFileBrowser)
  --self.on_resize = args.on_resize or nil

  -- internal --

  -- (vTable)
  self.vtable = nil

  --- (vSelection)
  self.selection = vSelection()

  -- (string) unique identifier for views
  self.uid = vLib.generate_uid()
  self.textfield_id = self.uid.."textfield_create"
  self.textfield_rename_id = self.uid.."textfield_rename"

  -- (boolean), set along with path
  self.at_root = nil

  -- initialize --

  self.selection.index_observable:add_notifier(function()
  end)

  self.selection.doublepress_observable:add_notifier(function()
    local item_idx = self.selection.last_selected_index
    local item = self.vtable:get_item_by_id(item_idx)
    if item then
      self:open_item(item)
    end
  end)

  -- show all columns if not defined
  if not args.show_columns then
    self.show_columns = {
      vFileBrowser.COLUMN.CHECK,
      vFileBrowser.COLUMN.ICON,
      vFileBrowser.COLUMN.NAME,
      vFileBrowser.COLUMN.DATE,
    }
  end

  vCompositeControl.__init(self,...)
  local vb = self.vb

  -- register views --

  self.refresh_button = vb:button{
    bitmap = vFileBrowser.IMAGE_PATH.."refresh.bmp",
    width = vFileBrowser.CONTROL_SIZE,
    height = vFileBrowser.CONTROL_SIZE,
    notifier = function()
      self:refresh()
    end
  }

  self.parent_button = vb:button{
    bitmap = vFileBrowser.IMAGE_PATH.."upwards.bmp",
    width = vFileBrowser.CONTROL_SIZE,
    height = vFileBrowser.CONTROL_SIZE,
    notifier = function()
      self:parent_directory()
    end
  }

  self.reveal_button = vb:button{
    bitmap = vFileBrowser.IMAGE_PATH.."magnifier.bmp",
    width = vFileBrowser.CONTROL_SIZE,
    height = vFileBrowser.CONTROL_SIZE,
    notifier = function()
      renoise.app():open_path(self.path)
    end
  }

  self.path_textfield = vb:text{
    text = "",
    width = vFileBrowser.TEXTFIELD_W,
    height = vFileBrowser.CONTROL_SIZE,
  }
  self.path_observable:add_notifier(function()
    local old_w = self.path_textfield.width
    self.path_textfield.text = self.path
    self.path_textfield.width = old_w  -- retain width
  end)

  self.filename_textfield = vb:textfield{
    text = "filename_textfield",
    width = vFileBrowser.TEXTFIELD_W,
    height = vFileBrowser.CONTROL_SIZE,
  }
  self.selection.index_observable:add_notifier(function()
    local sel_item = self:get_selected_item()
    if sel_item and (sel_item[vTable.META.TYPE] == vFileBrowser.ITEM_TYPE.FILE) then
      local filename = sel_item[vFileBrowser.COLUMN.NAME]
      self.filename_textfield.text = filename
    end
  end)

  self:register_views(vFileBrowser.VIEWS)

  -- done --

  self:build()

end

--------------------------------------------------------------------------------
--- choose action (depends on item type)

function vFileBrowser:open_item(item)

  if (item.item_type == vFileBrowser.ITEM_TYPE.FOLDER) then
    local new_path = ("%s/%s/"):format(self.path_observable.value,item.name)
    self:set_path(new_path)
  elseif (item.item_type == vFileBrowser.ITEM_TYPE.PARENT) then
    self:parent_directory()
  elseif (item.item_type == vFileBrowser.ITEM_TYPE.FILE) then
    if self.on_file_open then
      self.on_file_open(self,item)
    end
  end

end

--------------------------------------------------------------------------------

function vFileBrowser:get_column_def()

  local column_def = {}

  local tick_item = function(elm,checked)
    local item = self.vtable:get_item_by_id(elm[vDataProvider.ID])
    item.checked = checked
    if self.on_checked then
      self.on_checked(self,item)
    end
  end

  local press_item = function(cb_cell)
    local item = self.vtable:get_item_by_id(cb_cell[vDataProvider.ID])
    if self.single_select then
      self:open_item(item)
    else
      self.selection:set_index(cb_cell[vDataProvider.ID])
      self:update_row_styling()
    end
    self.vtable:request_update()

  end

  for k,v in ipairs(self.show_columns) do
    if (v == vFileBrowser.COLUMN.CHECK) then
      table.insert(column_def,{
        key = v,
        col_width=20,
        col_type=vTable.CELLTYPE.CHECKBOX,
        notifier=tick_item
      })
    elseif (v == vFileBrowser.COLUMN.ICON) then
      table.insert(column_def,{
        key = v,
        col_width=20,
        col_type=vTable.CELLTYPE.BITMAP,
        notifier=press_item,
      })
    elseif (v == vFileBrowser.COLUMN.NAME) then
      table.insert(column_def,{
        key = v,
        col_width="auto",
        col_type=vTable.CELLTYPE.TEXT,
        notifier=press_item,
      })
    elseif (v == vFileBrowser.COLUMN.DATE) then
      table.insert(column_def,{
        key = v,
        col_width=100,
      })
    end
  end

  return column_def

end

--------------------------------------------------------------------------------
-- @return table 

function vFileBrowser:get_header_def()

  local header_def = {}

  local function select_all(cb_cell,checked)
    local owner = cb_cell.owner
    local idx = cb_cell[vDataProvider.ID]
    owner.header_defs.checked.data = checked
    for k,v in ipairs(owner.data) do
      v.checked = checked
      -- TODO invoke "on_checked" 
    end
    --owner:update()

  end

  for k,v in ipairs(self.show_columns) do
    if (v == vFileBrowser.COLUMN.CHECK) then
      header_def[v] = {
        data=true,
        col_type=vTable.CELLTYPE.CHECKBOX,
        notifier=select_all
      }
    elseif (v == vFileBrowser.COLUMN.ICON) then
      header_def[v] = {
        data = ""
      }
    elseif (v == vFileBrowser.COLUMN.NAME) then
      header_def[v] = {
        data = "Name"
      }
    elseif (v == vFileBrowser.COLUMN.DATE) then
      header_def[v] = {
        data = "Last Modified"
      }
    end
  end

  return header_def

end

--------------------------------------------------------------------------------

function vFileBrowser:build()
  TRACE("vFileBrowser:build()")

  local vb = self.vb
  local prompt_w = 300

  self.create_directory_view = vb:column{
    margin = 6,
    width = prompt_w,
    vb:text{
      text = "Please provide a name for the new directory",
    },
    vb:textfield{
      id = self.textfield_id,
      width = "100%",
      text = ""
    },
  }

  self.rename_file_view = vb:column{
    margin = 6,
    width = prompt_w,
    vb:text{
      text = "",
    },
    vb:textfield{
      id = self.textfield_rename_id,
      width = "100%",
      text = ""
    },
  }

  self.vtable = vTable{
    vb = self.vb,
    width = self.width,
    header_style = "invisible",
    num_rows = self.num_rows, 
    row_style = "invisible",
    cell_style = "invisible",
    row_height = vFileBrowser.ROW_HEIGHT_DEFAULT,
    column_defs = self:get_column_def(),
    header_defs = self:get_header_def(),
    on_update_complete = function()
    end,
  }

  --self.vtable:update()
  self.view = self.vb:column{
    id = self.id,
  }

  self.view:add_child(self.vtable.view)

end


--------------------------------------------------------------------------------

function vFileBrowser:update()
  self.vtable:update()
end

--------------------------------------------------------------------------------
-- get all items in table

function vFileBrowser:get_items()
  return self.vtable.data
end

--------------------------------------------------------------------------------
-- get selected item (first one, if multiple)
-- @return table or nil

function vFileBrowser:get_selected_item()
  return self.vtable:get_item_by_id(self.selection.index)
end

--------------------------------------------------------------------------------
-- return bool

function vFileBrowser:create_path(str)
  TRACE("vFileBrowser:create_path(str)",str)
  -- TODO proper sanitize of string
  return os.mkdir(str)
end


--------------------------------------------------------------------------------
-- delete selected items in table
-- @return bool

function vFileBrowser:delete_selected()

  local err_msg = ""
  local rslt = true
  for k,v in ipairs(self.vtable.data) do
    if (v.checked) then
      local file_path = ("%s%s"):format(self.path_observable.value,v.name)
      local success, err 
      if (v.item_type == vFileBrowser.ITEM_TYPE.FOLDER) then
        success, err = self:delete_folder(file_path) 
      elseif (v.item_type == vFileBrowser.ITEM_TYPE.FILE) then
        success, err = os.remove(file_path) 
      elseif (v.item_type == vFileBrowser.ITEM_TYPE.PARENT) then
        success = true -- silently pass 
      end
      if not success then
        rslt = false
        err_msg = ("%sCould not remove this file/folder: %s (%s)\n"):format(err_msg,v.name,err)
      end

    end
  end 

  return rslt,err_msg

end

--------------------------------------------------------------------------------
-- delete selected folder (including workaround for non-POSIX systems)
-- TODO refactor into Filesys
-- @param str (string)
-- @return bool 
-- @return string (error message)

function vFileBrowser:delete_folder(str)

  local success, err 
  if (os.platform() == "WINDOWS") then
    -- on windows, use os.execute...
    local str_execute = ('rmdir "%s" /S /Q'):format(str)
    success = os.execute(str_execute)
    if (success > 0) then
      return false, ("Failed to delete the folder '%s'"):format(str)
    else
      return true
    end
  else
    return os.remove(str) 
  end

end

--------------------------------------------------------------------------------
-- get icon and extension in case of recognized file type
-- @return string(icon) or nil when not matched

function vFileBrowser:match_file_type(file_path)
  --TRACE("vFileBrowser:match_file_type(file_path)",file_path)
  local path,file,ext = cFilesystem.get_path_parts(file_path)
  for k,v in pairs(self._file_types) do
    if (ext == v.name) then
      return k,v.icon
    end
  end
end

--------------------------------------------------------------------------------

function vFileBrowser:count_checked()
  --TRACE("vFileBrowser:count_checked()")
  local data = self:get_items()
  return vVector.count_checked(data)
end

--------------------------------------------------------------------------------

function vFileBrowser:browse_path()
  TRACE("vFileBrowser:browse_path()")
  local str_path = renoise.app():prompt_for_path("Select a folder")
  if (str_path ~= "") then
    self:set_path(str_path)
  end
end

--------------------------------------------------------------------------------

function vFileBrowser:refresh()
  TRACE("vFileBrowser:refresh()")
  self:set_path(self.path_observable.value)
end

--------------------------------------------------------------------------------

function vFileBrowser:parent_directory()
  TRACE("vFileBrowser:parent_directory()")

  local file_path = cFilesystem.get_parent_directory(self.path_observable.value)
  self:set_path(file_path)

  if self.on_changed then
    self.on_changed()
  end

end

--------------------------------------------------------------------------------
--

function vFileBrowser:create_directory()
  TRACE("vFileBrowser:create_directory()")

  local vb = self.vb

  local choice = renoise.app():show_custom_prompt(
    "Create a new directory",self.create_directory_view,{"Create","Cancel"})

  if (choice == "Create") then
    
    local str_new_folder = vb.views[self.textfield_id].text

    local err_msg 

    if (str_new_folder == "") then
      err_msg = "You need to provide a name for the directory"
    end

    if not cFilesystem.validate_filename(str_new_folder) then
      err_msg = "A directory cannot contain the following characters \\ / : * ? < > |"
    end

    if err_msg then
      renoise.app():show_error(err_msg)
      self:create_directory()
      return
    end

    self.vb.views[self.textfield_id].text = ""

    local file_path = ("%s%s"):format(self:get_path(),str_new_folder)
    local success, err = self:create_path(file_path)
    if success then
      self:refresh()
    else
      local err_msg = ("Failed to create directory '%s', %s"):format(
        str_new_folder,err)
      renoise.app():show_error(err_msg)
    end

  end
  

end

--------------------------------------------------------------------------------
-- rename the currently selected file (single item)

function vFileBrowser:rename_file()
  TRACE("vFileBrowser:rename_file()")

  local vb = self.vb

  -- get the first selected item
  local sel_item = vVector.get_selected_item(self.vtable.data)
  if not sel_item then
    renoise.app():show_error("No file was selected")
    return
  end
  local str_name = sel_item.name

  vb.views[self.textfield_rename_id].text = str_name

  local choice = renoise.app():show_custom_prompt(
    "Rename a file",self.rename_file_view,{"Rename","Cancel"})

  if (choice == "Rename") then
    local str_new_name = vb.views[self.textfield_rename_id].text
    local str_from = ("%s%s"):format(self.path_observable.value,str_name)
    local str_to = ("%s%s"):format(self.path_observable.value,str_new_name)
    local success,err = os.rename(str_from,str_to) 
    if success then
      self:refresh()
    else
      local err_msg = ("Failed to rename file '%s', %s"):format(
        str_new_name,err)
      renoise.app():show_error(err_msg)
    end
  end

end


--------------------------------------------------------------------------------

function vFileBrowser:delete_files()
  TRACE("vFileBrowser:delete_files()")

  local num_checked_files = self:count_checked()
  if (num_checked_files == 0) then
    renoise.app():show_error("Please select one or more files")
    return
  end

  local str_prompt = ("Are you sure you want to delete %d file(s)?"):format(
    num_checked_files)
  local choice = renoise.app():show_prompt("",str_prompt,{"Yes","No"})
  if (choice == "Yes") then
    local success, err_msg = self:delete_selected()
    if not success then
      renoise.app():show_error(err_msg)
    else
      self:refresh()
    end
  end

end
--------------------------------------------------------------------------------
-- display the indicated path

function vFileBrowser:set_path(str)
  TRACE("vFileBrowser:set_path(str)",str)

  -- TODO proper sanitize of string
  -- * strip filenames from path
  -- * end with slash
  -- * avoid multiple slashes

  local dirnames = {}
  local filenames = {}

  -- check if provided string is a valid location
  -- (if not, use the tool bundle path as fallback)

  if not io.exists(str) then
    str = renoise.tool().bundle_path
    LOG("vFileBrowser: failed to set path (location doesn't exist)")
  end

  local dirnames = os.dirnames(str)
  local filenames = os.filenames(str,self._file_ext)

  self.at_root = self:is_root_folder(str)

  local rslt = {}

  if not self.at_root and self.show_parent_folder then
    table.insert(rslt,{
      name = "...",
      checked = false,
      item_type = vFileBrowser.ITEM_TYPE.PARENT,
      item_icon = vFileBrowser.ITEM_ICON.FOLDER,
      size = "",
    })
  end

  for k,v in ipairs(dirnames) do
    table.insert(rslt,{
      name = v,
      checked = false,
      item_type = vFileBrowser.ITEM_TYPE.FOLDER,
      item_icon = vFileBrowser.ITEM_ICON.FOLDER,
      size = "",
    })
  end

  for k,v in ipairs(filenames) do
    local file_path = ("%s%s"):format(str,v)
    local file_stat = io.stat(file_path)
    table.insert(rslt,{
      name = v,
      checked = false,
      item_type = vFileBrowser.ITEM_TYPE.FILE,
      item_icon = vFileBrowser.ITEM_ICON.FILE,
      size = file_stat and file_stat.size or 0,
      mtime = file_stat and cString.get_sortable_time(file_stat.mtime) or "--",
    })
  end

  self.path_observable.value = str

  -- match with recognized file-types
  for k,v in ipairs(rslt) do
    if (v.item_type == vFileBrowser.ITEM_TYPE.FILE) then
      local ext,icon = self:match_file_type(v.name)
      if ext and icon then
        v.item_icon = icon
      end
    end
  end

  self.vtable.data = rslt

  self.selection:reset()
  self:clear_row_styling()

  -- deprecated
  if self.on_changed_path then
    self.on_changed_path(self)
  end

end


function vFileBrowser:get_path()
  return self.path_observable.value
end

--------------------------------------------------------------------------------
-- check if current folder is "root" (TODO: custom root folder)
-- @return boolean

function vFileBrowser:is_root_folder(str)
  local parent_path = cFilesystem.get_parent_directory(str)
  return (parent_path == "/")
end

--------------------------------------------------------------------------------
-- decorate selection rows (visible on next update)

function vFileBrowser:update_row_styling()

  for k,v in ipairs(self.vtable.data) do
    if (table.find(self.selection.indices,v[vDataProvider.ID])) then
      v.__row_style = vFileBrowser.ROW_STYLE_SELECTED
    else
      v.__row_style = vFileBrowser.ROW_STYLE_NORMAL
    end
  end

end

--------------------------------------------------------------------------------
-- reset row styling (taking effect immediately)

function vFileBrowser:clear_row_styling()
  for k,v in ipairs(self.vtable.row_elms) do
    v.style = vFileBrowser.ROW_STYLE_NORMAL
  end
end

--------------------------------------------------------------------------------

function vFileBrowser:get_num_rows()
  TRACE("vTable:get_num_rows()")
  return self._num_rows
end

function vFileBrowser:set_num_rows(val)
  TRACE("vTable:set_num_rows(val)",val)
  if self.vtable then
    self.vtable.num_rows = val
  end
  self._num_rows = val
end

--------------------------------------------------------------------------------

function vFileBrowser:get_file_ext()
  TRACE("vTable:get_file_ext()")
  return self._file_ext
end

function vFileBrowser:set_file_ext(val)
  TRACE("vTable:set_file_ext(val)",val)
  self._file_ext = val
  self:refresh()
end

--------------------------------------------------------------------------------

function vFileBrowser:get_file_types()
  TRACE("vTable:get_file_types()")
  return self._file_types
end

function vFileBrowser:set_file_types(t)
  TRACE("vTable:set_file_types(t)",t)
  self._file_types = t
  self:refresh()
end

--------------------------------------------------------------------------------

function vFileBrowser:get_show_columns()
  TRACE("vTable:get_show_columns()")
  return self._show_columns
end

function vFileBrowser:set_show_columns(t)
  TRACE("vTable:set_show_columns(t)",t)
  self._show_columns = t
  -- TODO need to rebuild table when defining this value
end

--------------------------------------------------------------------------------

function vFileBrowser:get_show_parent_folder()
  return self._show_parent_folder
end

function vFileBrowser:set_show_parent_folder(val)
  self._show_parent_folder = val
end

--------------------------------------------------------------------------------

function vFileBrowser:get_single_select()
  return self._single_select
end

function vFileBrowser:set_single_select(val)
  self._single_select = val
end

--------------------------------------------------------------------------------

function vFileBrowser:set_width(val)
  if self.vtable then
    self.vtable.width = val
  end
  vControl.set_width(self,val)
end

--------------------------------------------------------------------------------

function vFileBrowser:set_height(val)
  if self.vtable then
    self.vtable.height = val
  end
  vControl.set_height(self,val)
end

--------------------------------------------------------------------------------

function vFileBrowser:set_active(val)
  if self.vtable then
    self.vtable.active = val
  end
  vControl.set_active(self,val)
end

--------------------------------------------------------------------------------

function vFileBrowser:set_show_header(val)
  if self.vtable then
    self.vtable.show_header = val
  end
  self._show_header = val
end

function vFileBrowser:get_show_header()
  return self._show_header
end

