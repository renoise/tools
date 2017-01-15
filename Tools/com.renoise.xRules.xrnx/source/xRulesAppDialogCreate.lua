--[[============================================================================
xRulesAppDialogCreate
============================================================================]]--

--[[

  This is a supporting class for xRulesApp

]]

--==============================================================================

require (_clibroot.."cFilesystem")

class 'xRulesAppDialogCreate' (vDialogWizard)

local DIALOG_W = 400
local PAGE_W = 250
local PAGE_H = 70
local TEXT_H = 150
local BROWSER_PATH_W = DIALOG_W - 76
local BROWSER_FILENAME_W = DIALOG_W - 50

function xRulesAppDialogCreate:__init(ui)
  TRACE("xRulesAppDialogCreate:__init(ui)",ui)  


  self.dialog_title = "Import/Create Ruleset"

  self.ui = ui
  self.owner = self.ui.owner
  self.xrules = self.ui.owner.xrules
  self.vbrowser = nil

  vDialogWizard.__init(self)

end

--------------------------------------------------------------------------------
-- (overridden method)

function xRulesAppDialogCreate:show()
  TRACE("xRulesAppDialogCreate:show()")  

  vDialogWizard.show(self)

  self.dialog_page = 1
  self.dialog_option = 1
  self:update_dialog()

end

-------------------------------------------------------------------------------
-- (overridden method)
-- @return renoise.Views.Rack

function xRulesAppDialogCreate:create_dialog()
  TRACE("xRulesAppDialogCreate:create_dialog()")  

  local vb = self.vb

  -- file list (displaying content of /rulesets)
  self.vbrowser = vFileBrowser{
    vb = vb,
    id = "vFileBrowser",
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
      --print("on_file_open - vb,item",vb,rprint(item))
      local file_path = cFilesystem.unixslashes(vb.path..item.name)
      --print("on_file_open - file_path",file_path)
      local passed,err = self:open_ruleset_file(file_path)
      if not passed then
        if err then
          renoise.app():show_warning(err)          
        end
      else
        self.dialog:close()
        self.dialog = nil
      end
    end
  }
  self.vbrowser.show_header = false -- why not in constructor? 
  self.vbrowser.path_textfield.width = BROWSER_PATH_W
  self.vbrowser.filename_textfield.width = BROWSER_FILENAME_W

  local content = vb:column{
    vb:space{
      width = PAGE_W,
    },
    vb:row{
      margin = 6,
      vb:row{
        vb:space{
          height = PAGE_H,
        },
        vb:column{
          id = "xRulesDialogCreate_Pg1",
          vb:text{
            text = "Please choose an option",
          },
          vb:chooser{
            id = "xRulesDialogCreateOptionChooser",
            value = self.dialog_option,
            items = {
              "Create new ruleset",
              "Paste from clipboard",
              "Locate a file on disk",
            },
            notifier = function(idx)
              self.dialog_option = idx
            end
          },
        },
        vb:column{
          visible = false,
          id = "xRulesDialogCreate_Pg2",
          vb:column{
            spacing = 6,
            id = "xRulesDialogCreate_Pg2_Opt1",
            vb:text{
              text = "Please specify a (unique) name:",
            },
            vb:textfield{
              id = "xRulesDialogCreateName",
              text = "",
              width = PAGE_W-20,
            },
            vb:multiline_text{
              text = "Once you click 'Done', the ruleset will be created in the default ruleset folder. You can change this location in 'Options'",
              width = PAGE_W-20,
              height = 50,
            },

          },
          vb:column{
            id = "xRulesDialogCreate_Pg2_Opt2",
            vb:text{
              text = "Please paste the string here",
            },
            vb:multiline_textfield{
              text = "",
              font = "mono",
              id = "xRulesDialogCreateDefinition",
              height = TEXT_H,
              width = DIALOG_W,
            },
          },
          vb:column{
            id = "xRulesDialogCreate_Pg2_Opt3",
            vb:text{
              text = "Please choose a file",
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
        },
      },
    },
  }

  return vb:column{
    content,
    self:build_navigation(),
  }

end

-------------------------------------------------------------------------------

function xRulesAppDialogCreate:update_dialog()
  TRACE("xRulesAppDialogCreate:update_dialog()")  

  local vb = self.vb

  -- update page

  local view_page_1       = vb.views["xRulesDialogCreate_Pg1"]
  local view_page_2       = vb.views["xRulesDialogCreate_Pg2"]
  local view_page_2_opt1  = vb.views["xRulesDialogCreate_Pg2_Opt1"]
  local view_page_2_opt2  = vb.views["xRulesDialogCreate_Pg2_Opt2"]
  local view_page_2_opt3  = vb.views["xRulesDialogCreate_Pg2_Opt3"]
  local view_opt_chooser  = vb.views["xRulesDialogCreateOptionChooser"]

  view_page_1.visible = false
  view_page_2.visible = false
  view_page_2_opt1.visible = false
  view_page_2_opt2.visible = false
  view_page_2_opt3.visible = false

  if (self.dialog_page == 1) then
    view_page_1.visible = true
    view_opt_chooser.value = self.dialog_option

  elseif (self.dialog_page == 2) then
    view_page_2.visible = true

    if (self.dialog_option == 1) then
      view_page_2_opt1.visible = true

      local str_name = xRuleset.get_suggested_name()       
      local view_name = vb.views["xRulesDialogCreateName"]
      view_name.text = str_name

    elseif (self.dialog_option == 2) then
      view_page_2_opt2.visible = true

    elseif (self.dialog_option == 3) then
      view_page_2_opt3.visible = true

    end

  end

  -- update navigation

  self._prev_button.active = (self.dialog_page > 1) and true or false
  self._next_button.text = (self.dialog_page == 2) and "Done" or "Next"


end

-------------------------------------------------------------------------------

function xRulesAppDialogCreate:show_prev_page()
  TRACE("xRulesAppDialogCreate:show_prev_page()")  
  if (self.dialog_page > 1) then
    self.dialog_page = self.dialog_page - 1
  end
  self:update_dialog()
end

-------------------------------------------------------------------------------

function xRulesAppDialogCreate:show_next_page()
  TRACE("xRulesAppDialogCreate:show_next_page()")  

  local vb = self.vb

  if (self.dialog_page == 1) then

    if (self.dialog_option == 2) then -- paste string (clear)

      local view_definition = vb.views["xRulesDialogCreateDefinition"]
      view_definition.text = ""

    elseif (self.dialog_option == 3) then -- browser:select file

      local ruleset_folder = self.owner.prefs:property("ruleset_folder").value
      self.vbrowser:set_path(ruleset_folder)

    end

  elseif (self.dialog_page == 2) then

    if (self.dialog_option == 1) then -- create from scratch

      local ruleset_name = vb.views["xRulesDialogCreateName"].text
      local passed,err = self:create_ruleset_file(ruleset_name) 
      if passed then
        self.dialog:close()
        self.dialog = nil
      else
        if err then
          renoise.app():show_warning(err)
        end
        self:show_prev_page()
      end

    elseif (self.dialog_option == 2) then -- create from string
      
      local vb_definition = vb.views["xRulesDialogCreateDefinition"]
      local str_ruleset = vb_definition.text

      -- check for syntax errors
      local sb = cSandbox()
      local passed,err = sb:test_syntax(str_ruleset)
      if not passed then
        renoise.app():show_warning("The string contains a syntax error: "..err)
        return
      end

      local ruleset_name = xRuleset.get_suggested_name() 
      local def = loadstring(str_ruleset)()
      local passed,err = self:create_ruleset_file(ruleset_name,def) 
      if passed then
        self.dialog:close()
        self.dialog = nil
      else
        if err then
          renoise.app():show_warning(err)
        end
        self:show_prev_page()
      end

    elseif (self.dialog_option == 3) then -- browser: open file

      local ruleset_name = self.vbrowser.filename_textfield.text
      local file_path = cFilesystem.unixslashes(self.vbrowser.path.."/"..ruleset_name)
      --print("on_file_open - file_path",file_path)
      local passed,err = self:open_ruleset_file(file_path)
      if not passed then
        if err then
          renoise.app():show_warning(err)          
        end
      else
        self.dialog:close()
        self.dialog = nil
      end

    end

  end

  self.dialog_page = self.dialog_page + 1
  self:update_dialog()
end


-------------------------------------------------------------------------------
-- open a ruleset from file
--  (if the ruleset is already open, offer to replace - otherwise cancel)
-- @param file_path (string)
-- @return boolean,string (success,err message)

function xRulesAppDialogCreate:open_ruleset_file(file_path)
  TRACE("xRulesAppDialogCreate:open_ruleset_file(file_path)",file_path)  

  local ruleset_idx 

  -- check for paths set in preferences 
  for k = 1, #self.owner.prefs.active_rulesets do
    local v = self.owner.prefs.active_rulesets[k]
    --print(">>> open_ruleset_file - k,v",k,v)
    if (file_path == v.value) then
      ruleset_idx = k
      break
    end
  end

  if ruleset_idx then
    local msg = "This ruleset is already loaded into xRules, replace with version from disk?"
    local choice = renoise.app():show_prompt("Replace existing ruleset",msg,{"Replace","Cancel"})
    if (choice == "Cancel") then
      return 
    end
    -- replace
    self.ui:clear_rule()
    self.ui:clear_rulesets()

    self.owner.suppress_ruleset_notifier = true
    local passed,err = self.xrules:replace_ruleset(file_path,ruleset_idx)
    self.owner.suppress_ruleset_notifier = false

    if passed then
      self.owner:store_ruleset_prefs()
      self.xrules.selected_ruleset_index = ruleset_idx
      self.xrules.selected_rule_index = 1
    end

    return passed

  else
    -- insert
    local ruleset_idx = #self.xrules.rulesets+1
    self.ui:clear_rule()
    self.ui:clear_rulesets()

    self.owner.suppress_ruleset_notifier = true
    local passed,err = self.xrules:load_ruleset(file_path)
    self.owner.suppress_ruleset_notifier = false

    if not passed then
      return false, err
    end

    self.ui:select_rule_within_set(ruleset_idx)
    self.owner:store_ruleset_prefs()

  end

  return true

end


-------------------------------------------------------------------------------
-- create new ruleset in the default folder
-- @param ruleset_name (string)
-- @param def (table), definition 
-- @return boolean,string

function xRulesAppDialogCreate:create_ruleset_file(ruleset_name,def)
  TRACE("xRulesAppDialogCreate:create_ruleset_file(ruleset_name,def,",ruleset_name,def)  

  local passed,err = cFilesystem.validate_filename(ruleset_name) 
  if not passed then
    return false, err
  end

  local file_path = self:generate_ruleset_path(ruleset_name)
  if io.exists(file_path) then
    return false, "Error: a file already exists with this name"
  end

  -- create instance of xRuleset in order to export
  local xruleset = xRuleset(nil,def)
  local str_ruleset = xruleset:serialize()
  local passed,err = cFilesystem.write_string_to_file(file_path,str_ruleset)
  if not passed then
    return false,err
  end

  local passed,err = self.xrules:load_ruleset(file_path)
  if not passed then
    return false,err
  end
  
  self.owner:store_ruleset_prefs()

  self.ui:select_rule_within_set(#self.xrules.rulesets)

  return true

end

-------------------------------------------------------------------------------
-- create full path to ruleset (default folder + supplied name)

function xRulesAppDialogCreate:generate_ruleset_path(name)
  TRACE("xRulesAppDialogCreate:generate_ruleset_path(name)",name)  

  local default_folder = self.owner.prefs:property("ruleset_folder").value
  return cFilesystem.unixslashes(("%s/%s.lua"):format(default_folder,name))

end

-------------------------------------------------------------------------------
-- add ruleset to application
-- @return boolean, 
-- @return string, error message

function xRulesAppDialogCreate:add_ruleset(def)
  TRACE("xRulesAppDialogCreate:add_ruleset(def)",def)  

  self.ui:clear_rule()
  self.ui:clear_rulesets()
  local passed,err = self.xrules:add_ruleset(def)
  if not passed and err then
    renoise.app():show_warning(err)
    return false
  end 
  local ruleset_idx = #self.xrules.rulesets
  self.xrules.selected_ruleset_index = ruleset_idx

  -- TODO add ruleset to preferences

  return true

end
