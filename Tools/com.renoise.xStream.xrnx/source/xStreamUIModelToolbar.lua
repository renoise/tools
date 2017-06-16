
class 'xStreamUIModelToolbar'

---------------------------------------------------------------------------------------------------

function xStreamUIModelToolbar:__init(xstream,vb,ui)

  assert(type(xstream)=="xStream")
  assert(type(vb)=="ViewBuilder")
  assert(type(ui)=="xStreamUI")

  self.xstream = xstream 
  self.vb = vb
  self.ui = ui
  
  self.prefs = renoise.tool().preferences

  --== notifiers ==--

  ui.show_stack_observable:add_notifier(function()
    TRACE("xStreamUIModelToolbar - show_stack_observable fired...")  
    local view_expand = self.vb.views["xStreamModelOrStackButton"]
    view_expand.text = ui.show_stack and xStreamUI.ARROW_UP or xStreamUI.ARROW_DOWN
    if not ui.show_stack then 
      ui.stack_has_focus = false
    end 
    self.ui.update_models_requested = true
  end)

  ui.stack_has_focus_observable:add_notifier(function()
    TRACE("xStreamUIModelToolbar - stack_has_focus_observable fired...")  
    --self:update()
    self.ui.update_models_requested = true
  end)

  --== initialize ==--

  --self:attach_to_process()

end

---------------------------------------------------------------------------------------------------
-- Class methods
---------------------------------------------------------------------------------------------------

function xStreamUIModelToolbar:build()

  local model_names = self.xstream.models:get_available()
  local stack_names = self.xstream.stacks:get_available()

  local color_callback = function(t)
    self.xstream.selected_model.color = t
  end

  local vb = self.vb
  return vb:horizontal_aligner{
      margin = 4,
      mode = "justify",
      vb:row{
        --id = "xStreamCallbackHeader",
        spacing = xStreamUI.MIN_SPACING,
        --[[
        vb:popup{
          id = "xStreamModelOrStackPopup",
          items = {
            "Single model",
            "Model stack",            
          },
          value = 2,
          width = xStreamUI.BITMAP_BUTTON_H, 
          height = xStreamUI.BITMAP_BUTTON_H, 
          notifier = function(val)
            local stack_tb = self.vb.views["xStreamUIStackToolbar"]
            stack_tb.visible = (val == 2)
            self:update()
          end,
        },
        ]]
        vb:button{
          tooltip = "Toggle between normal and stacked mode",
          text = xStreamUI.ARROW_DOWN,
          id = "xStreamModelOrStackButton",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            self.ui.show_stack = not self.ui.show_stack
          end,
        },          
        vb:space{
          width = 6,
        },
        vb:checkbox{
          visible = false,
          notifier = function()
            if self.ui.show_stack then 
              self.ui.stack_has_focus = true
            end
          end
        },
        vb:text{
          id = "xStreamModelOrStackLabel",
          --text = "Model",
          --font = "bold",
          --align = "center",
          width = 42,
        },
        vb:space{
          width = 6,
        },
        vb:button{
          tooltip = "Pick color",
          id = "xStreamModelColorPreview",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local model_color = self.xstream.selected_model.color
            vPrompt.prompt_for_color(color_callback,model_color,xStreamUI.DEFAULT_PALETTE)
          end,
        },
        vb:button{
          text = xStreamUI.FAVORITE_TEXT.ON,
          tooltip = "Add to favorites",
          id = "xStreamFavoriteModel",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function(val)
            local model = self.xstream.selected_model
            self.xstream.favorites:toggle_item(model.name)
          end,
        },
        vb:space{
          width = 6,
        },
        vb:popup{ -- model selector
          tooltip = "All available models",
          items = model_names,
          id = "xStreamModelSelector",
          width = xStreamUI.MODEL_SELECTOR_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function(val)
            self.xstream.selected_model_index = val-1
          end
        },
        vb:popup{ -- stack selector
          tooltip = "All available model stacks",
          visible = false,
          items = stack_names,
          id = "xStreamStackSelector",
          width = xStreamUI.MODEL_SELECTOR_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function(val)
            self.xstream.stacks.selected_stack_index = val-1
          end
        },
        vb:space{
          width = 6,
        },
        vb:button{
          bitmap = "./source/icons/delete_small.bmp",
          tooltip = "Delete the model/stack",
          id = "xStreamModelRemove",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            if self.ui.stack_has_focus then
              self:delete_stack()
            else
              self:delete_model()
            end
          end,
        },
        vb:button{
          bitmap = "./source/icons/add.bmp",
          tooltip = "Create a new model",
          id = "xStreamModelCreate",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            self.ui.create_model_dialog:show()
          end,
        },
        vb:button{
          bitmap = "./source/icons/reveal_folder.bmp",
          tooltip = "Reveal the folder in which the definition is located",
          id = "xStreamRevealLocation",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            self.xstream.selected_model:reveal_location()          
          end,
        },        

        vb:button{
          bitmap = "./source/icons/save.bmp",
          tooltip = "Overwrite the existing definition",
          id = "xStreamModelSave",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local passed,err = self.xstream.selected_model:save()
            if not passed and err then
              renoise.app():show_warning(err)
            end 
          end,
        },
        vb:button{
          bitmap = "./source/icons/rename.bmp",
          tooltip = "Rename the selected model",
          id = "xStreamModelRename",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local model = self.xstream.selected_model
            local str_name,_ = vPrompt.prompt_for_string(model.name,
              "Enter a new name","Rename Model")
            if not str_name then
              return 
            end
            local success,err = self.xstream.models:rename_model(model.name,str_name)
            if not success and err then
              renoise.app():show_warning(err)
            else
              --self:update()
              self.ui.update_models_requested = true
            end
          end,
        },
        vb:button{
          bitmap = "./source/icons/save_as.bmp",
          tooltip = "Save model under a new name",
          id = "xStreamModelSaveAs",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local passed,err = self.xstream.selected_model:save_as()          
            if not passed and err then
              renoise.app():show_warning(err)
            end 
          end,
        },        
        vb:button{
          bitmap = "./source/icons/refresh.bmp",
          tooltip = "(Re-)load the selected model from disk",
          id = "xStreamModelRefresh",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local success,err = self.xstream.selected_model:refresh()
            if success then
              --self:update()
              self.ui.update_models_requested = true
            else
              renoise.app():show_warning(err)
            end

          end,
        },  
      },  
      vb:space{

      },
      vb:row{
        vb:row{
          id = "xStreamModelEditorNumLinesContainer",
          tooltip = "Number of lines",
          vb:text{
            id = "xStreamEditorNumLinesTitle",
            text = "Lines",
          },
          vb:valuebox{
            min = 12,
            max = 51,
            height = xStreamUI.BITMAP_BUTTON_H,
            id = "xStreamModelEditorNumLines",
            bind = self.prefs.editor_visible_lines,
            --[[
            notifier = function(val)
              self.prefs.editor_visible_lines.value = val
            end,
            ]]
          }
        },
        vb:button{
          tooltip = "Toggle visiblity of code editor [Tab]",
          text = xStreamUI.ARROW_DOWN,
          id = "xStreamToggleExpand",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            self.ui.show_editor = not self.ui.show_editor
          end,
        },  
      },
      
    }
  

end

--------------------------------------------------------------------------------

function xStreamUIModelToolbar:update_color()
  TRACE("xStreamUIModelToolbar:update_color()")

  local model = self.xstream.selected_model
  local view = self.vb.views["xStreamModelColorPreview"]
  if model then
    view.color = cColor.value_to_color_table(model.color)
    view.active = true
  else
    view.color = {0,0,0}
    view.active = false
  end

end

--------------------------------------------------------------------------------

function xStreamUIModelToolbar:update()
  TRACE("xStreamUIModelToolbar:update()")

  local member = self.xstream.stack:get_selected_member()
  local model = self.xstream.selected_model
  local delete_bt = self.vb.views["xStreamModelRemove"]
  local save_bt = self.vb.views["xStreamModelSave"]
  local fav_bt = self.vb.views["xStreamFavoriteModel"]
  local label = self.vb.views["xStreamModelOrStackLabel"]
  --local stack_tb = self.vb.views["xStreamUIStackToolbar"]
  local model_selector = self.vb.views["xStreamModelSelector"]
  local stack_selector = self.vb.views["xStreamStackSelector"]

  model_selector.visible = false
  stack_selector.visible = false

  --print(">>> self.ui.stack_has_focus",(model or self.ui.stack_has_focus))

  local can_delete = model and true or false 
  if self.ui.stack_has_focus then 
    can_delete = (self.xstream.stack.file_path ~="")
  end 

  delete_bt.active = can_delete
  save_bt.active = model and model.modified or false

  -- update favorites 
  if model then 
    local favorite_idx = self.xstream.favorites:get(model.name) 
    fav_bt.text = (favorite_idx) and xStreamUI.FAVORITE_TEXT.ON or xStreamUI.FAVORITE_TEXT.DIMMED
    if favorite_idx then
      self.ui.selected_favorite_index = favorite_idx
    else
      self.ui.selected_favorite_index = 0
    end
  else 
    self.ui.selected_favorite_index = 0
  end

  if not self.ui.show_stack then 
    label.text = "Model"
    label.font = "bold"
    model_selector.visible = true
    stack_selector.visible = false
  else
    label.text = "Stack"
    label.font = self.ui.stack_has_focus and "bold" or "normal"
    model_selector.visible = not self.ui.stack_has_focus
    stack_selector.visible = self.ui.stack_has_focus
  end


end

----------------------------------------------------------------------------------------------------

function xStreamUIModelToolbar:update_model_selector()
  TRACE("xStreamUIModelToolbar:update_model_selector()")

  local names = self.xstream.models:get_available()
  table.insert(names,1,xStreamUI.NO_MODEL_SELECTED)

  local view_popup = self.vb.views["xStreamModelSelector"] 
  local view_compact_popup = self.vb.views["xStreamCompactModelSelector"]

  local selector_value = (self.xstream.selected_model_index == 0) 
      and 1 or self.xstream.selected_model_index+1

  view_popup.items = names
  view_popup.value = selector_value
  view_compact_popup.items = names
  view_compact_popup.value = selector_value

  -- update related selectors
  self.ui.favorites_ui:update_model_selector(names)
  self.ui.global_toolbar.options:update_model_selector(names)

end

----------------------------------------------------------------------------------------------------

function xStreamUIModelToolbar:update_stack_selector()
  TRACE("xStreamUIModelToolbar:update_stack_selector()")

  local names = self.xstream.stacks:get_available()
  table.insert(names,1,xStreamUI.NO_STACK_SELECTED)
  local view_popup = self.vb.views["xStreamStackSelector"] -- in model_toolbar

  local selector_value = (self.xstream.stacks.selected_stack_index == 0) 
      and 1 or self.xstream.stacks.selected_stack_index+1

  view_popup.items = names
  view_popup.value = selector_value

end


--------------------------------------------------------------------------------

function xStreamUIModelToolbar:delete_model()
  TRACE("xStreamUIModelToolbar:delete_model()")

  local choice = renoise.app():show_prompt("Delete model",
      "Are you sure you want to delete this model "
    .."\n(this action can not be undone)?",
    {"OK","Cancel"})
  
  if (choice == "OK") then
    local model = self.xstream.selected_model
    local success,err = self.xstream.models:delete_model(model.name)
    if not success then
      renoise.app():show_error(err)
    end
  end

end

--------------------------------------------------------------------------------

function xStreamUIModelToolbar:delete_stack()
  TRACE("xStreamUIModelToolbar:delete_stack()")

  local choice = renoise.app():show_prompt("Delete stack",
      "Are you sure you want to delete this stack "
    .."\n(this action can not be undone)?",
    {"OK","Cancel"})
  
  if (choice == "OK") then
    local stack_name = self.xstream.stack.name
    local success,err = self.xstream.stacks:delete(stack_name)
    if not success then
      renoise.app():show_error(err)
    end
  end

end

