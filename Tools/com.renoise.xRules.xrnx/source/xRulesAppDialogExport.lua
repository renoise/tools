--[[============================================================================
xRulesAppDialogExport
============================================================================]]--

--[[

  This is a supporting class for xRulesApp

]]

--==============================================================================

class 'xRulesAppDialogExport' (vDialogWizard)

local DIALOG_W = 400
local MIN_DIALOG_H = 70
local BROWSER_PATH_W = DIALOG_W - 76
local BROWSER_FILENAME_W = DIALOG_W - 50

function xRulesAppDialogExport:__init(ui)


  self.dialog_title = "Export Ruleset"

  self.ui = ui
  self.xrules = self.ui.xrules
  self.owner = self.ui.owner
  self.vbrowser = nil

  --print(">>> self.owner",self.owner)

  vDialogWizard.__init(self)

end

--------------------------------------------------------------------------------

function xRulesAppDialogExport:show_prev_page()
  if (self.dialog_page > 1) then
    self.dialog_page = self.dialog_page - 1
  end
  self:update_dialog()
end

--------------------------------------------------------------------------------

function xRulesAppDialogExport:show_next_page()

  local vb = self.vb 

  if (self.dialog_page == 1) then

    if (self.dialog_option == 1) then -- browser:show folder of ruleset

      local xruleset = self.xrules.selected_ruleset
      local ruleset_folder,fname,ext = cFilesystem.get_path_parts(xruleset.file_path)
      local filename = cFilesystem.file_add_extension(xruleset.name,"lua")
      self.vbrowser.filename_textfield.text = filename
      self.vbrowser:set_path(ruleset_folder)

    elseif (self.dialog_option == 2) then -- clipboard:show

      local view_definition = vb.views["xRulesDialogExportDefinition"]
      local xruleset = self.xrules.selected_ruleset
      view_definition.text = xruleset:serialize()

    end

  elseif (self.dialog_page == 2) then

    if (self.dialog_option == 1) then -- browser:save

      local passed,err = self:save_ruleset()

      if not passed then
        if err then
          renoise.app():show_warning(err)
        else
          -- user aborted, show previous page
          self:show_prev_page()
        end
      else
        self.dialog:close()
        self.dialog = nil
      end

    elseif (self.dialog_option == 2) then -- clipboard:close
      
      self.dialog:close()
      self.dialog = nil

    end

  end

  self.dialog_page = self.dialog_page + 1
  self:update_dialog()

end

--------------------------------------------------------------------------------
-- (overridden method)

function xRulesAppDialogExport:show()

  vDialogWizard.show(self)

  self.dialog_page = 1
  self.dialog_option = 1
  self:update_dialog()

end

-------------------------------------------------------------------------------
-- (overridden method)
-- @return renoise.Views.Rack

function xRulesAppDialogExport:create_dialog()

  local vb = self.vb

  self.vbrowser = vFileBrowser{
    vb = vb,
    id = "xRulesDialogExportBrowser",
    width = DIALOG_W,
    num_rows = 10,
    file_ext = {'*.lua'},
    show_parent_folder = false,
    show_header = false,
    show_columns = {
      --vFileBrowser.COLUMN.CHECK,
      vFileBrowser.COLUMN.ICON,
      vFileBrowser.COLUMN.NAME,
      vFileBrowser.COLUMN.DATE,
    },
    file_types = {
      {name = "lua", on_press=function()
        -- 
      end},
    },
    on_checked = function(arg1,arg2)
      --print("on_checked",arg1,arg2)
    end,
    on_file_open = function(vb,item)
      
      local passed,err = self:save_ruleset()

      if not passed then
        if err then
          renoise.app():show_warning(err)          
        end
      else
        self.dialog:close()
        self.dialog = nil
      end
    end,
  }
  self.vbrowser.show_header = false -- why not in constructor? 
  self.vbrowser.path_textfield.width = BROWSER_PATH_W
  self.vbrowser.filename_textfield.width = BROWSER_FILENAME_W

  local content = vb:column{
    vb:space{
      width = DIALOG_W,
    },
    vb:row{
      margin = 6,
      vb:row{
        vb:space{
          height = MIN_DIALOG_H,
        },
        vb:column{
          id = "xRulesDialogExportPage1",
          vb:text{
            text = "Please choose an option",
          },
          vb:chooser{
            id = "xRulesDialogExportOptionChooser",
            value = self.dialog_option,
            items = {
              "Export ruleset as file",
              "Copy to clipboard",
            },
            notifier = function(idx)
              self.dialog_option = idx
            end
          },
        },
        vb:column{
          visible = false,
          id = "xRulesDialogExportPage2",
          vb:column{
            id = "xRulesDialogExportPage2Option1",
            spacing = 6,
            vb:text{
              text = "A copy of the ruleset will be saved into this folder:",
            },
            vb:row{
              self.vbrowser.path_textfield,
              self.vbrowser.parent_button,
              vb:space{
                width = 6,
              },
              self.vbrowser.reveal_button,
              self.vbrowser.refresh_button,
            },
            self.vbrowser.view,
            vb:row{
              vb:text{
                text = "Filename",
              },
              self.vbrowser.filename_textfield
            },
          },
          vb:column{
            id = "xRulesDialogExportPage2Option2",
            vb:text{
              text = "Copy+paste the following text to the clipboard:",
            },
            vb:multiline_textfield{
              text = "",
              font = "mono",
              id = "xRulesDialogExportDefinition",
              height = 150,
              width = DIALOG_W,
            },
          },
          
        }
      },
    }
  }


  return vb:column{
    content,
    self:build_navigation(),
  }

end

-------------------------------------------------------------------------------

function xRulesAppDialogExport:update_dialog()

  local vb = self.vb

  -- update page

  local view_page_1       = vb.views["xRulesDialogExportPage1"]
  local view_page_2       = vb.views["xRulesDialogExportPage2"]
  local view_page_2_opt1  = vb.views["xRulesDialogExportPage2Option1"]
  local view_page_2_opt2  = vb.views["xRulesDialogExportPage2Option2"]
  local view_opt_chooser  = vb.views["xRulesDialogExportOptionChooser"]

  view_page_1.visible = false
  view_page_2.visible = false
  view_page_2_opt1.visible = false
  view_page_2_opt2.visible = false

  if (self.dialog_page == 1) then

    view_page_1.visible = true
    view_opt_chooser.value = self.dialog_option

  elseif (self.dialog_page == 2) then
    view_page_2.visible = true

    if (self.dialog_option == 1) then 
      view_page_2_opt1.visible = true

    elseif (self.dialog_option == 2) then
      view_page_2_opt2.visible = true

    end
  end

  -- update navigation

  --local view_prev_button  = vb.views["xRulesDialogExportPrevButton"]
  --local view_next_button  = vb.views["xRulesDialogExportNextButton"]
  self._prev_button.active = (self.dialog_page > 1) and true or false
  self._next_button.text = (self.dialog_page == 2) and "Done" or "Next"


end

-------------------------------------------------------------------------------
-- @return boolean,string

function xRulesAppDialogExport:save_ruleset()

  local xruleset = self.xrules.selected_ruleset
  assert(xruleset,"Expected a ruleset to be present")

  local vb = self.vb 
  --local filename = vb.views["xRulesDialogExportName"].text
  local filename = self.vbrowser.filename_textfield.text
  filename = cFilesystem.file_add_extension(filename,"lua")
  local path = self.vbrowser.path
  local file_path = cFilesystem.unixslashes(("%s/%s"):format(path,filename))

  -- if file exists, prompt for overwrite
  if io.exists(file_path) then
    local msg = "Do you want to overwrite the existing file?"
    local choice = renoise.app():show_prompt("Replace file",msg,{"OK","Cancel"})
    if (choice == "Cancel") then
      return false
    end
  end

  local passed,err = xruleset:save_definition(file_path)
  if not passed then
    return false,err
  end

  return true

end
