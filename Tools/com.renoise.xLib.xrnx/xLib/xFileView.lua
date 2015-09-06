--[[============================================================================
xFileView
============================================================================]]--

--[[

  "File View" - combine the vFileBrowser with some additional controls


]]

class 'xFileView'

xFileView.TAB_LABELS = {
  "/",
  "Fx-Chains",
  "Instruments",
  "Mod-Sets",
  "Multi-Samples",
  "Phrases",
  "Samples",
}

xFileView.FILE_TYPES = {
  xrnt = {icon = "Icons/Browser_RenoiseDeviceChainFile.bmp"},
  xrni = {icon = "Icons/Browser_RenoiseInstrumentFile.bmp"},
  xrno = {icon = "Icons/Browser_RenoiseModulationSetFile.bmp"},
  sfz  = {icon = "Icons/Browser_RenoiseInstrumentFile.bmp"},
  xrnz = {icon = "Icons/Browser_RenoisePhraseFile.bmp"},
  flac = {icon = "Icons/Browser_AudioFile.bmp"},
}


xFileView.TABLE_ROWS = 12

function xFileView:__init(vb,file_view,controls_view)
  --print("xFileView:__init(vb,file_view,controls_view)",vb,file_view,controls_view)

  -- (ViewBuilder) 
  self.vb = vb

  -- (renoise.Views.Rack)
  self.file_view = file_view

  -- (renoise.Views.Rack)
  self.controls_view = controls_view

  -- (bool)
  self.panel_sync = false

  -- (int) 
  self.tab_idx = 1

  -- (int)
  self.width = 200
  self.controls_width = self.width - 50

  -- (int) for the vFileBrowser
  self.num_rows = xFileView.TABLE_ROWS

  -- (string) the part of the part we do not want to display
  self.root_path = nil

  -- (vFileBrowser) 
  self.browser = nil

  -- (bool) allow programmatic changes to the path textfield 
  self.suppress_notifier = false

  -- (function) fired when item is selected/deselected
  self.on_checked = nil
  
  -- (function) fired when browser has refreshed its contents
  self.on_refresh = nil

  -- (int) unique viewbuilder ids
  self.uid = vLib.generate_uid()
  --self.textfield_id = self.uid.."textfield_create"
  --self.textfield_rename_id = self.uid.."textfield_rename"
  self.textfield_path_id = self.uid.."textfield_path"

end

--------------------------------------------------------------------------------

function xFileView:build()

  local vb = self.vb

  --print("*** building - self.controls_width",self.controls_width)

  local controls_content = vb:column{
    vb:horizontal_aligner{
      --width = self.width,
      vb:textfield{
        id = self.textfield_path_id,
        text = "",
        width = self.controls_width,
        height = xLib.LARGE_BUTTON_H,
        notifier = function(str)
          --print("notifier",str)
          if not self.suppress_notifier then
            self.browser:set_path(str)
          end
        end,

      },
      vb:button{
        id = self.uid.."bt_parent",
        bitmap = "Icons/Browser_Upwards.bmp",
        width = xLib.LARGE_BUTTON_H,
        height = xLib.LARGE_BUTTON_H,
        tooltip = "Parent Directory",
        notifier = function()
          self.browser:parent_directory()
        end,
      },
      vb:button{
        id = self.uid.."bt_create_directory",
        bitmap = "Icons/Browser_ShowDirectories.bmp",
        width = xLib.LARGE_BUTTON_H,
        height = xLib.LARGE_BUTTON_H,
        tooltip = "Create New Directory",
        notifier = function()
          self.browser:create_directory()
        end,
      },
    },
  }
  self.controls_view:add_child(controls_content)

  local tab_controls = vb:column{
    vb:switch{
      items = xFileView.TAB_LABELS,
      value = self.tab_idx,
      width = self.width,
      height = xLib.SWITCHER_H,
      active = false,
    },
  }
  self.file_view:add_child(tab_controls)


  self.browser = vFileBrowser{
    vb = self.vb,
    num_rows = self.num_rows,
    file_types = xFileView.FILE_TYPES,
    on_changed_path = function(browser)
      self:update_path()
    end,
    on_checked = function(idx)
      --print("self.browser.on_checked",idx)
      --self:update_path()
      if self.on_checked then
        self.on_checked(idx)
      end
    end,
    width = self.width-2,
  }
  self.file_view:add_child(self.browser.view)


end


--------------------------------------------------------------------------------
-- display path, while stripping the root path part

function xFileView:update_path()
  --print("xFileView:update_path()")

  --print("*** self.browser.path",self.browser.path)

  self.suppress_notifier = true

  local elm = self.vb.views[self.textfield_path_id]
  if self.root_path and 
    (string.find(self.browser.path,self.root_path)) 
  then
    --print("got here",self.root_path)
    elm.text = string.sub(self.browser.path,#self.root_path)
  else
    elm.text = self.browser.path
  end

  self.suppress_notifier = false

end

--------------------------------------------------------------------------------

function xFileView:refresh()
  --print("xFileView:refresh()")

  self.browser:refresh()

end

--------------------------------------------------------------------------------
-- set path, adding the root path part

function xFileView:set_path()
  --print("xFileView:set_path()")

  local elm = self.vb.views[self.textfield_path_id]
  local str_path = self.root_path .. elm.text
  --print("elm.text",elm.text)
  --print("str_path",str_path)
  self.browser:set_path(str_path)

end

--------------------------------------------------------------------------------
-- set path, adding the root path part

function xFileView:get_path()
  --print("xFileView:get_path()")

  return self.browser.path

end

--------------------------------------------------------------------------------
-- rename the currently selected file (only works with single item)

function xFileView:rename_file()
  --print("xFileView:rename_file()")

  local xitem = self.browser:get_selected_item()
  if not xitem then
    renoise.app():show_warning("No file was selected")
    return
  end

  self.browser:rename_file(xitem.name)


end


--------------------------------------------------------------------------------
-- "shortcut"

function xFileView:show_user_library()
  --print("xFileView:show_user_library()")

  local path = ("%sUser Library/"):format(xLib._renoise_library_path)
  self.root_path = path

  self.browser:set_path(path)

end

--------------------------------------------------------------------------------
-- "shorcut"

function xFileView:show_installed_library(str)
  --print("xFileView:show_installed_library(str)",str)

  local path = ("%sInstalled Libraries/%s/"):format(
    xLib._renoise_library_path,str)
  self.root_path = path

  self.browser:set_path(path)

end

--------------------------------------------------------------------------------

function xFileView:show_library_preset_type(str)
  --print("xFileView:show_installed_library(str)",str)

  --local path = xLib._renoise_library_path.."Installed Libraries/".. str
  --self.browser:set_path(path)

end

