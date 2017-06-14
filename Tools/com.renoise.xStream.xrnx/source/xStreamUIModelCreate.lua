--[[===============================================================================================
xStreamUIModelCreate
===============================================================================================]]--

--[[

Supporting UI class for xStream

]]

--=================================================================================================

local PANEL_W = xStreamUI.FULL_PANEL_W

class 'xStreamUIModelCreate' (vDialogWizard)

-----------------------------------------------------------------------------------------------------------------------------------------------------------

function xStreamUIModelCreate:__init(ui)
  TRACE("xStreamUIModelCreate:__init(ui)",ui)

  vDialogWizard.__init(self)

  self.title = "Import/Create Model"

  self.ui = ui
  self.xstream = self.ui.xstream

end

-----------------------------------------------------------------------------------------------------------------------------------------------------------
-- (overridden method)

function xStreamUIModelCreate:show()
  TRACE("xStreamUIModelCreate:show()")

  vDialogWizard.show(self)

  self.dialog_page = 1
  self.dialog_option = 1
  self:update_dialog()

end

---------------------------------------------------------------------------------------------------
-- (overridden method)
-- @return renoise.Views.Rack

function xStreamUIModelCreate:create_dialog()
  TRACE("xStreamUIModelCreate:create_dialog()")

  local vb = self.vb

  local PAGE_W = 250
  local PAGE_H = 70
  local TEXT_H = 150

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
          id = "xStreamNewModelDialogPage1",
          vb:text{
            text = "Please choose an option",
          },
          vb:chooser{
            id = "xStreamNewModelDialogOptionChooser",
            value = self.dialog_option,
            items = {
              "Create from scratch (empty)",
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
          id = "xStreamNewModelDialogPage2",
          vb:column{
            id = "xStreamNewModelDialogPage2Option1",
            vb:text{
              text = "Please specify a (unique) name for the model",
            },
            vb:textfield{
              id = "xStreamNewModelDialogName",
              text = "",
              width = PAGE_W-20,
            },
          },
          vb:column{
            id = "xStreamNewModelDialogPage2Option2",
            vb:text{
              text = "Please paste the lua string here",
            },
            vb:multiline_textfield{
              text = "",
              font = "mono",
              id = "xStreamNewModelDialogDefinition",
              height = TEXT_H,
              width = PANEL_W,
            },
          },
          vb:column{
            id = "xStreamNewModelDialogPage2Option3",
            vb:row{
              vb:text{
                text = "Please choose a file",
              },
              vb:button{
                text = "Browse",
                notifier = function()
                  self:navigate_to_model()
                end
              }
            },

          },
        }
      },
    }
  }
  local navigation = vb:row{
    margin = 6,
    vb:button{
      id = "xStreamNewModelDialogPrevButton",
      text = "Previous",
      active = false,
      notifier = function()
        self:show_prev_page()
      end
    },
    vb:button{
      id = "xStreamNewModelDialogNextButton",
      text = "Next",
      notifier = function()
        self:show_next_page()
      end
    },
    vb:button{
      id = "xStreamNewModelDialogCancelButton",
      text = "Cancel",
      notifier = function()
        self.dialog:close()
        self.dialog = nil
      end
    },
  }

  return vb:column{
    content,
    navigation,
  }

end

---------------------------------------------------------------------------------------------------

function xStreamUIModelCreate:update_dialog()
  TRACE("xStreamUIModelCreate:update_dialog()")

  local vb = self.vb

  -- update page

  local view_page_1       = vb.views["xStreamNewModelDialogPage1"]
  local view_page_2       = vb.views["xStreamNewModelDialogPage2"]
  local view_page_2_opt1  = vb.views["xStreamNewModelDialogPage2Option1"]
  local view_page_2_opt2  = vb.views["xStreamNewModelDialogPage2Option2"]
  local view_page_2_opt3  = vb.views["xStreamNewModelDialogPage2Option3"]
  local view_opt_chooser  = vb.views["xStreamNewModelDialogOptionChooser"]

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
      local str_name = xStreamModel.get_suggested_name(xStreamModel.DEFAULT_NAME)       
      local view_name = vb.views["xStreamNewModelDialogName"]
      view_name.text = str_name
    elseif (self.dialog_option == 2) then
      view_page_2_opt2.visible = true
    elseif (self.dialog_option == 3) then
      view_page_2_opt3.visible = true
    end
  end

  -- update navigation

  local view_prev_button  = vb.views["xStreamNewModelDialogPrevButton"]
  local view_next_button  = vb.views["xStreamNewModelDialogNextButton"]
  view_prev_button.active = (self.dialog_page > 1) and true or false
  view_next_button.text = (self.dialog_page == 2) and "Done" or "Next"

end


---------------------------------------------------------------------------------------------------
-- (overridden method)

function xStreamUIModelCreate:show_prev_page()
  TRACE("xStreamUIModelCreate:show_prev_page()")

  if (self.dialog_page > 1) then
    self.dialog_page = self.dialog_page - 1
  end
  self:update_dialog()

end

---------------------------------------------------------------------------------------------------
-- (overridden method)

function xStreamUIModelCreate:show_next_page()
  TRACE("xStreamUIModelCreate:show_next_page()")

  local vb = self.vb

  if (self.dialog_page == 1) then

    if (self.dialog_option == 2) then -- paste string (clear)
      local view_definition = vb.views["xStreamNewModelDialogDefinition"]
      view_definition.text = ""
    elseif (self.dialog_option == 3) then -- locate file (...)
      self:navigate_to_model()
    end

  elseif (self.dialog_page == 2) then

    if (self.dialog_option == 1) then -- create from scratch
      -- ensure unique name
      local view_name = vb.views["xStreamNewModelDialogName"]
      if not self:validate_model_name(view_name.text) then
        renoise.app():show_warning("Error: a model already exists with this name")
        return
      else
        -- we are done - 
        local model,err = self.xstream.models:create(view_name.text)
        if not model and err then
          renoise.app():show_warning(err)
          return
        end 
        local model_idx = self.xstream.models:get_model_index_by_name(model.name)
        --print(">>> select model_idx",model_idx)
        self.xstream.selected_model_index = model_idx
        self.dialog:close()
        self.dialog = nil
      end
    elseif (self.dialog_option == 2) then -- paste string
      -- check for syntax errors
      local model,member = self:create_model()
      local view_textfield = vb.views["xStreamNewModelDialogDefinition"]      
      local passed,err = model:load_from_string(view_textfield.text)
      if not passed and err then
        renoise.app():show_warning(err)
        model = nil
        return
      else
        self:add_save_and_close(model,member)
      end
    elseif (self.dialog_option == 3) then -- locate file
      self.dialog:close()
      self.dialog = nil
    end

  end

  self.dialog_page = self.dialog_page + 1
  self:update_dialog()

end

---------------------------------------------------------------------------------------------------
-- Create model, using the currently selected member index 

function xStreamUIModelCreate:create_model()
  TRACE("xStreamUIModelCreate:create_model()")

  local member = self.xstream.stack:allocate_member()
  return xStreamModel(member.buffer,self.xstream.voicemgr,self.xstream.output_message),member

end

---------------------------------------------------------------------------------------------------
-- Load (import) a model from an external location

function xStreamUIModelCreate:navigate_to_model()
  TRACE("xStreamUIModelCreate:navigate_to_model()")

  local file_path = renoise.app():prompt_for_filename_to_read({"*.lua"},"Open model definition")
  --print("file_path",file_path)
  if (file_path == "") then
    return
  end

  -- attempt to load model
  local model,member = self:create_model()
  local passed,err = model:load_definition(file_path)
  --print("passed,err",passed,err)
  if not passed and err then
    renoise.app():show_warning(err)
    return
  end
  model.file_path = xStreamModel.get_normalized_file_path(model.name)
  if not self:validate_model_name(model.name) then
    renoise.app():show_warning("Error: a model already exists with this name")
    return
  end
  self:add_save_and_close(model,member)

end

---------------------------------------------------------------------------------------------------
-- Add model to our repository 

function xStreamUIModelCreate:add_save_and_close(model,member)
  TRACE("xStreamUIModelCreate:add_save_and_close(model,member)")

  self.xstream.models:add(model,member.member_index)
  local got_saved,err = model:save()
  if not got_saved and err then
    renoise.app():show_warning(err)
  end
  local model_idx = self.xstream.models:get_model_index_by_name(model.name)
  --print(">>> select model_idx",model_idx)
  self.xstream.selected_model_index = model_idx
  self.dialog:close()
  self.dialog = nil

end


---------------------------------------------------------------------------------------------------

function xStreamUIModelCreate:validate_model_name(str_name)
  TRACE("xStreamUIModelCreate:validate_model_name(str_name)")

  local str_name_validate = xStreamModel.get_suggested_name(str_name)
  --print("str_name,str_name_validate",str_name,str_name_validate)
  return (str_name == str_name_validate) 

end

