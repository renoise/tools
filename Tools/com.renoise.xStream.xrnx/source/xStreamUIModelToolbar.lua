
class 'xStreamUIModelToolbar'

---------------------------------------------------------------------------------------------------

function xStreamUIModelToolbar:__init(xstream,vb,ui)

  assert(type(xstream)=="xStream")
  assert(type(vb)=="ViewBuilder")

  self.xstream = xstream 
  self.vb = vb
  self.ui = ui
  
  self.prefs = renoise.tool().preferences

end

---------------------------------------------------------------------------------------------------

function xStreamUIModelToolbar:build()

  local model_names = self.xstream.process.models:get_names()

  local color_callback = function(t)
    self.xstream.selected_model.color = t
  end

  local vb = self.vb
  return vb:horizontal_aligner{
      margin = 3,
      mode = "justify",
      vb:row{
        --id = "xStreamCallbackHeader",
        spacing = xStreamUI.MIN_SPACING,
        vb:button{
          tooltip = "Toggle visiblity of code editor [Tab]",
          text = xStreamUI.ARROW_DOWN,
          id = "xStreamToggleExpand",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            self.xstream.ui.show_editor = not self.xstream.ui.show_editor
          end,
        },  
        vb:space{
          width = 6,
        },
        vb:text{
          text = "Model",
          font = "bold",
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
          tooltip = "Add this model to the favorites",
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
        vb:popup{ -- selector
          items = model_names,
          id = "xStreamModelSelector",
          width = xStreamUI.MODEL_SELECTOR_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function(val)
            self.xstream.selected_model_index = val-1
          end
        },
        vb:space{
          width = 6,
        },
        vb:button{
          bitmap = "./source/icons/delete_small.bmp",
          tooltip = "Delete the selected model",
          id = "xStreamModelRemove",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            self:delete_model()
          end,
        },
        vb:button{
          bitmap = "./source/icons/add.bmp",
          tooltip = "Create a new model",
          id = "xStreamModelCreate",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            self.xstream.ui.create_model_dialog:show()
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
            local success,err = self.xstream.selected_model:rename()          
            if not success then
              renoise.app():show_warning(err)
            else
              self:update()
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
              self:update()
            else
              renoise.app():show_warning(err)
            end

          end,
        },  
      },  
      vb:space{

      },
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
      }
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

  local model = self.xstream.selected_model
  local save_bt = self.vb.views["xStreamModelSave"]
  local fav_bt = self.vb.views["xStreamFavoriteModel"]

  if model then
    save_bt.active = self.xstream.selected_model.modified
    local favorite_idx = self.xstream.favorites:get(model.name) 
    fav_bt.text = (favorite_idx) and xStreamUI.FAVORITE_TEXT.ON or xStreamUI.FAVORITE_TEXT.DIMMED
    if favorite_idx then
      self.selected_favorite_index = favorite_idx
    else
      self.selected_favorite_index = 0
    end
  else
    self.selected_favorite_index = 0
  end

end

--------------------------------------------------------------------------------

function xStreamUIModelToolbar:delete_model()

  local choice = renoise.app():show_prompt("Delete model",
      "Are you sure you want to delete this model "
    .."\n(this action can not be undone)?",
    {"OK","Cancel"})
  
  if (choice == "OK") then
    local model_idx = self.xstream.selected_model_index
    local success,err = self.xstream.process.models:delete_model(model_idx)
    if not success then
      renoise.app():show_error(err)
    end
  end

end

--------------------------------------------------------------------------------

function xStreamUIModelToolbar:rename_callback(new_name)
  TRACE("xStreamUIModelToolbar:rename_callback(new_name)",new_name)

  local model = self.xstream.selected_model
  if not model then
    return
  end

  local cb_type,cb_key,cb_subtype = xStream.parse_callback_type(self.xstream.ui.lua_editor.editor_view)

  if (cb_type ~= xStreamModel.CB_TYPE.DATA) then
    return
  end

  if not new_name then
    new_name = vPrompt.prompt_for_string(cb_subtype or cb_key,
      "Enter a new name","Rename callback")
    if not new_name then
      return true
    end
  end

  -- events contain two parts
  local old_name = cb_subtype and cb_key.."."..cb_subtype or cb_key

  local passed,err = model:rename_callback(old_name,new_name,cb_type)
  if not passed then
    return false,err
  end

  self.xstream.ui.lua_editor.editor_view = cb_type.."."..new_name
  self.xstream.ui.user_modified_callback = true


end

--------------------------------------------------------------------------------

function xStreamUIModelToolbar:remove_callback()
  TRACE("xStreamUIModelToolbar:remove_callback()")

  local model = self.xstream.selected_model
  if not model then
    return
  end

  local choice = renoise.app():show_prompt("Remove callback",
      "Are you sure you want to remove this callback?",
    {"OK","Cancel"})
  
  if (choice == "OK") then
    local cb_type,cb_key,cb_subtype = xStream.parse_callback_type(self.xstream.ui.lua_editor.editor_view)
    model:remove_callback(cb_type,cb_subtype and cb_key.."."..cb_subtype or cb_key)
    self.update_editor_requested = true
  end

end

