--[[============================================================================
vFileBrowser 
============================================================================]]--

require (_vlibroot.."vControl")

class 'vFileBrowser' (vControl)

vFileBrowser.DEFAULT_PATH = (os.platform() == "WINDOWS") and "C:/" or "/"
vFileBrowser.DEFAULT_EXT = {"*.*"}

vFileBrowser.NUM_ROWS_DEFAULT = 10

vFileBrowser.ITEM_TYPE = {
  FOLDER = 1,
  FILE = 2,
}

vFileBrowser.ITEM_ICON = {
  FOLDER = "Icons/Folder_closed.bmp",
  FILE = "Icons/Browser_ScriptFile.bmp",
}

--------------------------------------------------------------------------------
--- A file browser component, based on vTable

function vFileBrowser:__init(...)
  --print("vFileBrowser:__init(...)",...)

  local args = vLib.unpack_args(...)

  --- (int) number of visible rows
  self._num_rows = args.num_rows or vFileBrowser.NUM_ROWS_DEFAULT
  self.num_rows = property(self.get_num_rows,self.set_num_rows)

  --- (string) full, absolute folder path - file part is ignored
  self._path = args.path or vFileBrowser.DEFAULT_PATH
  self.path = property(self.get_path,self.set_path)

  --- (string)
  self._file_ext = args.file_ext or vFileBrowser.DEFAULT_EXT
  self.file_ext = property(self.get_file_ext,self.set_file_ext)

  --- (table>{ext1 = {icon},ext2 = {icon},...})
  self._file_types = args.file_types or {}
  self.file_types = property(self.get_file_types,self.set_file_types)

  --- (function) callback event
  -- @param elm (vFileBrowser)
  -- @param item_id (int)
  self.on_checked = args.on_checked or nil

  --- (function) callback event
  -- @param elm (vFileBrowser)
  self.on_changed_path = args.on_changed_path or nil

  --- (function) callback event
  -- @param elm (vFileBrowser)
  --self.on_resize = args.on_resize or nil

  -- internal -------------------------

  -- (vTable)
  self.vtable = nil

  -- (string) unique identifier for views
  self.uid = vLib.generate_uid()
  self.textfield_id = self.uid.."textfield_create"
  self.textfield_rename_id = self.uid.."textfield_rename"

  vControl.__init(self,...)
  self:build()

end

--------------------------------------------------------------------------------

function vFileBrowser:build()

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

  local tick_item = function(elm,checked)
    local item = self.vtable:get_item_by_id(elm.item_id)
    item.checked = checked
    if self.on_checked then
      self.on_checked(self,elm.item_id)
    end
    
  end

  local press_item = function(cb_cell)
    local item = self.vtable:get_item_by_id(cb_cell.item_id)
    if (item.item_type == vFileBrowser.ITEM_TYPE.FOLDER) then
      local new_path = ("%s/%s/"):format(self._path,item.name)
      self:set_path(new_path)
    end
  end

  local function tick_header(cb_cell,checked)
    --print("notifier - cb_cell,checked",cb_cell,checked)
    local owner = cb_cell.owner
    local idx = cb_cell.item_id
    owner.header_defs.checked.data = checked
    for k,v in ipairs(owner.data) do
      v.checked = checked
    end
    owner:update()
    if self.on_checked then
      self.on_checked(self,idx)
    end
  end

  self.vtable = vTable{
    vb = self.vb,
    width = self.width,
    header_style = "invisible",
    num_rows = self.num_rows, 
    row_style = "invisible",
    cell_style = "invisible",
    column_defs = {
      {key = "checked",col_width=20,col_type=vTable.CELLTYPE.CHECKBOX,notifier=tick_item},
      {key = "item_icon",col_width=20,col_type=vTable.CELLTYPE.BITMAP},
      {key = "name",col_width="auto",col_type=vTable.CELLTYPE.BUTTON,color=vLib.COLOR_NORMAL,pressed=press_item},
      {key = "mtime",col_width=100,},
    },
    header_defs = {
      checked   = {data=true,col_type=vTable.CELLTYPE.CHECKBOX,notifier=tick_header},
      item_icon = {data = ""},
      name      = {data = "Name"},
      mtime     = {data = "Last Modified"},
    },
    on_update_complete = function()
      --print("*** vFileBrowser.vtable.on_update_complete")
    end,
  }
  self.vtable:update()

  self.view = self.vb:column{
    id = self.id,
    --style = "plain",
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

  return vVector.match_by_key_value(self.vtable.data,"checked",true)

end

--------------------------------------------------------------------------------
-- return bool

function vFileBrowser:create_path(str)
  --print("vFileBrowser:create_path(str)",str)

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
      local file_path = ("%s%s"):format(self._path,v.name)
      --print("Remove this item",v.item_type,file_path)

      local success, err 
      if (v.item_type == vFileBrowser.ITEM_TYPE.FOLDER) then
        success, err = self:delete_folder(file_path) 
      elseif (v.item_type == vFileBrowser.ITEM_TYPE.FILE) then
        success, err = os.remove(file_path) 
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
  --print("vFileBrowser:match_file_type(file_path)",file_path)

  local path,file,ext = vFilesys.get_path_parts(file_path)
  --print("path,file,ext",path,file,ext)

  for k,v in pairs(self._file_types) do
    --print("k,v",k,v,v.icon)
    if (ext == v.name) then
      return k,v.icon
    end
  end

end

--------------------------------------------------------------------------------

function vFileBrowser:count_checked()
  --print("vFileBrowser:count_checked()")

  local data = self:get_items()
  --print("xLib.count_checked(xdata)",xLib.count_checked(xdata))
  return vVector.count_checked(data)

end


--------------------------------------------------------------------------------

function vFileBrowser:browse_path()
  --print("vFileBrowser:browse_path()")

  local str_path = renoise.app():prompt_for_path("Select a folder")
  --print("str_path",str_path)
  if (str_path ~= "") then
    self:set_path(str_path)
  end

end

--------------------------------------------------------------------------------

function vFileBrowser:refresh()
  --print("vFileBrowser:refresh()")
  self:set_path(self._path)
end

--------------------------------------------------------------------------------
--

function vFileBrowser:parent_directory()
  --print("vFileBrowser:parent_directory()")
  --print("self._path",self._path)

  local file_path = vFilesys.get_parent_directory(self._path)
  self:set_path(file_path)

  if self.on_changed then
    self.on_changed()
  end

end

--------------------------------------------------------------------------------
--

function vFileBrowser:create_directory()
  --print("vFileBrowser:parent_directory()")

  local vb = self.vb

  local choice = renoise.app():show_custom_prompt(
    "Create a new directory",self.create_directory_view,{"Create","Cancel"})

  if (choice == "Create") then
    
    local str_new_folder = vb.views[self.textfield_id].text
    --print("str_new_folder",str_new_folder,vFilesys.validate_filename(str_new_folder))

    local err_msg 

    if (str_new_folder == "") then
      err_msg = "You need to provide a name for the directory"
    end

    if not vFilesys.validate_filename(str_new_folder) then
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
  --print("vFileBrowser:rename_file()")

  local vb = self.vb

  -- get the first selected item
  local sel_item = vVector.get_selected_item(self.vtable.data)
  if not sel_item then
    renoise.app():show_error("No file was selected")
    return
  end
  local str_name = sel_item.name
  --print("str_name",str_name)

  vb.views[self.textfield_rename_id].text = str_name

  local choice = renoise.app():show_custom_prompt(
    "Rename a file",self.rename_file_view,{"Rename","Cancel"})

  if (choice == "Rename") then

    local str_new_name = vb.views[self.textfield_rename_id].text
    local str_from = ("%s%s"):format(self._path,str_name)
    local str_to = ("%s%s"):format(self._path,str_new_name)
    local success,err = os.rename(str_from,str_to) 
    --print("success,err",success,err)
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
  --print("vFileBrowser:delete_files()")

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
  --print("vFileBrowser:set_path(str)",str)

  -- TODO proper sanitize of string
  -- * strip filenames from path
  -- * end with slash
  -- * avoid multiple slashes

  local dirnames = {}
  local filenames = {}

  local dirnames = os.dirnames(str)
  local filenames = os.filenames(str,self._file_ext)

  --print("dirnames",rprint(dirnames))
  --print("filenames",rprint(filenames))

  local rslt = {}

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
      mtime = file_stat and vString.get_sortable_time(file_stat.mtime) or "--",
    })
  end

  --print("rslt",rprint(rslt))

  self._path = str

  -- match with recognized file-types
  for k,v in ipairs(rslt) do
    --print("*** got here",v.item_icon)
    if (v.item_type == vFileBrowser.ITEM_TYPE.FILE) then
      local ext,icon = self:match_file_type(v.name)
      --print("ext,icon",ext,icon)
      if ext then
        v.item_icon = icon
      end
    end
  end

  --rprint(rslt)

  --self.vtable:set_data(rslt)
  self.vtable.data = rslt

  if self.on_changed_path then
    self.on_changed_path(self)
  end

end


function vFileBrowser:get_path()
  return self._path
end

--------------------------------------------------------------------------------

function vFileBrowser:set_num_rows(val)
  --print("vTable:set_num_rows(val)",val)
  self._num_rows = val
  self.vtable.num_rows = val
end

function vFileBrowser:get_num_rows()
  --print("vTable:set_num_rows(num)",num)
  return self._num_rows
end

--------------------------------------------------------------------------------

function vFileBrowser:set_file_ext(val)
  --print("vTable:set_file_ext(val)",val)
  self._file_ext = val
  self:refresh()
end

function vFileBrowser:get_file_ext()
  --print("vTable:set_file_ext(num)",num)
  return self._file_ext
end

--------------------------------------------------------------------------------

function vFileBrowser:set_file_types(t)
  --print("vTable:set_file_types(t)",t)
  self._file_types = t
  self:refresh()
end

function vFileBrowser:get_file_types()
  --print("vTable:set_file_types(num)",num)
  return self._file_types
end

--------------------------------------------------------------------------------

function vFileBrowser:set_width(val)
  self.vtable.width = val
  vControl.set_width(self,val)
end

--------------------------------------------------------------------------------

function vFileBrowser:set_height(val)
  self.vtable.height = val
  vControl.set_height(self,val)
end

--------------------------------------------------------------------------------

function vFileBrowser:set_active(val)
  --print("vTable:set_file_types(t)",t)
  self.vtable.active = val
  vControl.set_active(self,val)
end
