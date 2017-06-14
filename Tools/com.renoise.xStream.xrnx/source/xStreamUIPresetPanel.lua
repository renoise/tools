--[[============================================================================
xStreamUIPresetPanel
============================================================================]]--
--[[

	Supporting class for xStream 

]]

--==============================================================================

class 'xStreamUIPresetPanel'

xStreamUIPresetPanel.CONTROLS = {
  "xStreamAddPreset",
  "xStreamRemovePreset",
  "xStreamExportPresetBank",
  "xStreamImportPresetBank",
  "xStreamPresetBankCreate",
  "xStreamPresetBankSelector",
  "xStreamPresetBankRename",
  "xStreamPresetBankRemove",
  "xStreamFavoritePreset",
  "xStreamUpdatePreset",
  "xStreamModelPresetselector",
  "xStreamModelPresetsToggle",
}

xStreamUIPresetPanel.PRESET_RECALL_W = xStreamUI.PRESET_PANEL_W - 80

--------------------------------------------------------------------------------

function xStreamUIPresetPanel:__init(xstream,vb,ui)

  self.vb = vb
  self.ui = ui
  self.xstream = xstream  

  self.preset_views = {}

  self.visible = property(self.get_visible,self.set_visible)
  self.visible_observable = renoise.Document.ObservableBoolean(false)

  self.disabled = property(self.get_disabled,self.set_disabled)

  self.base_color_highlight = cColor.adjust_brightness(xStreamUI.COLOR_BASE,xStreamUI.HIGHLIGHT_AMOUNT)


end

--------------------------------------------------------------------------------
-- Get/set methods
--------------------------------------------------------------------------------

function xStreamUIPresetPanel:get_disabled()
  return
end

function xStreamUIPresetPanel:set_disabled(val)
  for k,v in ipairs(xStreamUIPresetPanel.CONTROLS) do
    self.vb.views[v].active = not val
  end
end

--------------------------------------------------------------------------------

function xStreamUIPresetPanel:get_visible()
  return self.visible_observable.value
end

function xStreamUIPresetPanel:set_visible(val)
  TRACE("xStreamUIPresetPanel:set_visible(val)",val)

  local view_browser = self.vb.views["xStreamArgPresetContainer"]
  local view_arrow = self.vb.views["xStreamModelPresetsToggle"]

  view_browser.visible = val
  view_arrow.text = val and xStreamUI.ARROW_UP or xStreamUI.ARROW_DOWN

  self.visible_observable.value = val

end


--------------------------------------------------------------------------------
-- Class methods
--------------------------------------------------------------------------------

function xStreamUIPresetPanel:build_panel()
  
  local vb = self.vb
  return vb:column{
    --style = "panel",
    margin = 4,
    vb:row{
      vb:button{
        text=xStreamUI.ARROW_DOWN,
        id = "xStreamModelPresetsToggle",
        tooltip = "Toggle visibility of preset list",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          self.visible = not self.visible
        end,
      },
      --[[
      vb:text{
        text = "Presets",
        font = "bold",
      },
      ]]
      vb:popup{
        items = {xStreamModelPresets.DEFAULT_BANK_NAME},
        tooltip = "Choose between available preset banks",
        id = "xStreamPresetBankSelector",
        width = xStreamUI.PRESET_PANEL_W - 86, 
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function(idx)
          self.xstream.selected_model.selected_preset_bank_index = idx
        end
      },
      vb:row{
        spacing = xStreamUI.MIN_SPACING,
        vb:button{
          --text = "‒",
          --bitmap = "./source/icons/delete.bmp",
          bitmap = "./source/icons/delete_small.bmp",
          tooltip = "Remove selected preset bank",
          id = "xStreamPresetBankRemove",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local choice = renoise.app():show_prompt("Delete preset bank",
                "Are you sure you want to delete this preset bank "
              .."\n(this action can not be undone)?",
              {"OK","Cancel"})
            if (choice == "OK") then
              local model = self.xstream.selected_model
              local preset_bank_index = model.selected_preset_bank_index
              local success = model:remove_preset_bank(preset_bank_index)
              if success then
                model.selected_preset_bank_index = 1
              end
            end
          end,
        },

        vb:button{
          bitmap = "./source/icons/add.bmp",
          tooltip = "Create a new preset bank",
          id = "xStreamPresetBankCreate",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local model = self.xstream.selected_model
            local str_name = xStreamModel.get_new_preset_bank_name()
            str_name = vPrompt.prompt_for_string(str_name,
              "Enter a name for the preset bank","Add Preset Bank")
            local success,err = model:add_preset_bank(str_name)
            if success then
              model.selected_preset_bank_index = #model.preset_banks
              model.selected_preset_bank.modified = true
            elseif err then 
              renoise.app():show_warning(err)
            end
          end,
        },
        vb:button{
          bitmap = "./source/icons/rename.bmp",
          tooltip = "Rename the selected preset bank",
          id = "xStreamPresetBankRename",
          active = false,
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local success,err = self.xstream.selected_model.selected_preset_bank:rename()
            if not success then
              renoise.app():show_warning(err)
            end 
          end,
        },
        vb:button{
          bitmap = "./source/icons/open.bmp",
          tooltip = "Import/merge presets into selected bank",
          id = "xStreamImportPresetBank",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function(val)
            self.xstream.selected_model.selected_preset_bank:import()
          end,
        },
        vb:button{
          bitmap = "./source/icons/save.bmp",
          tooltip = "Export selected preset bank",
          id = "xStreamExportPresetBank",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local success,err = self.xstream.selected_model.selected_preset_bank:export()
            if not success then
              renoise.app():show_warning(err)
            end 
          end
        },

      },      
     
    },

    vb:row{
      vb:bitmap{
        bitmap = "./source/icons/preset_bank.bmp",
        mode = "body_color",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
      },
      vb:row{
        spacing = xStreamUI.MIN_SPACING,
        --[[
        vb:bitmap{
          bitmap = "./source/icons/presets.bmp",
          --bitmap = "./source/icons/InstrumentBox.bmp",
          mode = "body_color",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
        },
        ]]
        vb:popup{
          items = {},
          id = "xStreamModelPresetselector",
          tooltip = "Choose between available presets",
          width = xStreamUI.PRESET_PANEL_W-86,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function(idx)
            self.xstream.stack:set_selected_preset_index(idx-1)
          end
        },
        vb:space{
          width = 6,
        },
        vb:button{
          bitmap = "./source/icons/delete_small.bmp",
          tooltip = "Remove the selected preset",
          id = "xStreamRemovePreset",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function(val)
            local model = self.xstream.selected_model
            local preset_idx = model.selected_preset_bank.selected_preset_index
            model.selected_preset_bank:remove_preset(preset_idx)
          end,
        },
        vb:button{
          bitmap = "./source/icons/add.bmp",
          tooltip = "Add new preset with the current settings",
          id = "xStreamAddPreset",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function(val)
            local model = self.xstream.selected_model
            local added,err = model.selected_preset_bank:add_preset()
            if not added then
              renoise.app():show_warning(err)
            else
              model.selected_preset_bank.selected_preset_index = #model.selected_preset_bank.presets
            end
          end,
        },
        vb:button{
          bitmap = "./source/icons/rename.bmp",
          tooltip = "Assign a new name to this preset",
          id = "xStreamPresetRename",
          active = false,
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local presets = self.xstream.selected_model.selected_preset_bank
            local success,err = presets:rename_preset(presets.selected_preset_index)
            if not success and err then
              renoise.app():show_warning(err)
            end
          end,
        },

        vb:button{
          bitmap = "./source/icons/update.bmp",
          tooltip = "Update preset with current settings",
          id = "xStreamUpdatePreset",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function(val)
            local model = self.xstream.selected_model
            local preset_idx = model.selected_preset_bank.selected_preset_index
            model.selected_preset_bank:update_preset(preset_idx)
          end,
        },

        vb:button{
          text = xStreamUI.FAVORITE_TEXT.ON,
          tooltip = "Add preset to favorites",
          id = "xStreamFavoritePreset",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function(val)
            local model = self.xstream.selected_model
            local preset_idx = model.selected_preset_bank.selected_preset_index
            local preset_bank_name = model.selected_preset_bank.name
            self.xstream.favorites:toggle_item(model.name,preset_idx,preset_bank_name)
            self.xstream.ui.update_presets_requested = true
          end,
        },          

      }, 
    },

    vb:space{
      height = xStreamUI.SMALL_VERTICAL_MARGIN,
    },
    vb:column{
      tooltip = "Available presets for this model",
      id = 'xStreamArgPresetContainer',
      spacing = xStreamUI.MIN_SPACING,
      margin = 0,
      -- add buttons here..
    },
  }  
  
end

-------------------------------------------------------------------------------
-- (re-)build preset buttons

function xStreamUIPresetPanel:build_list()
  TRACE("xStreamUIPresetPanel:build_list()")

  local model = self.xstream.selected_model
  if not model then
    return
  end
  
  local vb = self.vb

  local vb_container = vb.views["xStreamArgPresetContainer"]

  -- remove all existing buttons 
  local count = 1
  while self.preset_views[count] do
    self.preset_views[count]:remove_child(
      vb.views["xStreamModelPresetDelete"..count])
    vb.views["xStreamModelPresetDelete"..count] = nil
    self.preset_views[count]:remove_child(
      vb.views["xStreamModelPresetSchedule"..count])
    vb.views["xStreamModelPresetSchedule"..count] = nil
    self.preset_views[count]:remove_child(
      vb.views["xStreamModelPresetRecall"..count])
    vb.views["xStreamModelPresetRecall"..count] = nil
    self.preset_views[count]:remove_child(
      vb.views["xStreamModelPresetUpdate"..count])
    vb.views["xStreamModelPresetUpdate"..count] = nil
    self.preset_views[count]:remove_child(
      vb.views["xStreamPresetListMoveUpButton"..count])
    vb.views["xStreamPresetListMoveUpButton"..count] = nil
    self.preset_views[count]:remove_child(
      vb.views["xStreamPresetListMoveDownButton"..count])
    vb.views["xStreamPresetListMoveDownButton"..count] = nil
    self.preset_views[count]:remove_child(
      vb.views["xStreamModelPresetFavorite"..count])
    vb.views["xStreamModelPresetFavorite"..count] = nil
    count = count + 1
  end

  for k,v in ipairs(self.preset_views) do
    vb_container:remove_child(v)
  end

  self.preset_views = {}

  if (model.args.length == 0) then
    return
  end

  for k = 1,#model.selected_preset_bank.presets do
    
    local preset_name = model.selected_preset_bank:get_preset_display_name(k)

    local row = vb:row{
      spacing = xStreamUI.MIN_SPACING,
      vb:button{
        bitmap = "./source/icons/delete_small.bmp",
        id = "xStreamModelPresetDelete"..k,
        tooltip = "Remove this preset",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          model.selected_preset_bank:remove_preset(k)
        end
      },
      vb:button{
        text = xStreamUI.SCHEDULE_TEXT.OFF,
        id = "xStreamModelPresetSchedule"..k,
        tooltip = "Schedule this preset",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          self.xstream.stack:schedule_item(model.name,k)
        end,
      },
      vb:button{
        text = preset_name,
        id = "xStreamModelPresetRecall"..k,
        tooltip = "Activate this preset",
        width = xStreamUIPresetPanel.PRESET_RECALL_W, 
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          model.selected_preset_bank.selected_preset_index = k
        end,
      },
      vb:button{
        id = "xStreamPresetListMoveUpButton"..k,
        bitmap = "./source/icons/move_up.bmp",
        tooltip = "Move preset up in list",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          local presets = self.xstream.selected_model.selected_preset_bank
          local got_moved,_ = presets:swap_index(k,k-1)
          if got_moved then
            presets.selected_preset_index = k - 1
          end
        end
      },
      vb:button{
        id = "xStreamPresetListMoveDownButton"..k,
        bitmap = "./source/icons/move_down.bmp",
        tooltip = "Move preset down in list",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          local presets = self.xstream.selected_model.selected_preset_bank
          local got_moved,_ = presets:swap_index(k,k+1)
          if got_moved then
            presets.selected_preset_index = k + 1
          end
        end
      },
      vb:button{
        bitmap = "./source/icons/update.bmp",
        id = "xStreamModelPresetUpdate"..k,
        tooltip = "Update this preset with the current settings",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          model.selected_preset_bank:update_preset(k)
        end
      },

      vb:button{
        text = "", 
        id = "xStreamModelPresetFavorite"..k,
        tooltip = "Favorite this preset (toggle)",
        width = xStreamUI.BITMAP_BUTTON_W,
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          local preset_bank_name = model.selected_preset_bank.name
          self.xstream.favorites:toggle_item(model.name,k,preset_bank_name)
          self.xstream.ui.update_presets_requested = true
        end,
      },

    }
    vb_container:add_child(row)
    table.insert(self.preset_views,row)
    self:update_preset_list_row(k)

  end


end

--------------------------------------------------------------------------------

function xStreamUIPresetPanel:update_selector()
  TRACE("xStreamUIPresetPanel:update_selector()")

  local model = self.xstream.selected_model
  local view_popup = self.vb.views["xStreamModelPresetselector"]

  if model then
    local preset_bank = model.selected_preset_bank
    local t = {}
    if (#model.selected_preset_bank.presets > 0) then
      -- gather preset names
      t = {"Select preset"}
      for k,v in ipairs(preset_bank.presets) do
        local preset_name = model.selected_preset_bank:get_preset_display_name(k)
        table.insert(t,preset_name)
      end
    end
    view_popup.items = t

    view_popup.value = (preset_bank.selected_preset_index == 0) 
      and 1 or preset_bank.selected_preset_index+1

  else
    view_popup.items = {}
    view_popup.value = 1
  end

end

--------------------------------------------------------------------------------
-- update visual state of preset buttons

function xStreamUIPresetPanel:update_list()
  TRACE("xStreamUIPresetPanel:update_list()")

  local vb = self.vb
  for k = 1, #self.preset_views do
    if (vb.views["xStreamModelPresetRecall"..k]) then
      self:update_preset_list_row(k)
    end
  end

end


--------------------------------------------------------------------------------

function xStreamUIPresetPanel:update_preset_list_row(idx)
  TRACE("xStreamUIPresetPanel:update_preset_list_row(idx)",idx)

  if not self.xstream.selected_model then
    return
  end

  local preset_bank_name = self.xstream.selected_model.selected_preset_bank.name
  local selected = (self.xstream.selected_model.selected_preset_bank.selected_preset_index == idx)
  local base_color = selected and self.base_color_highlight or xLib.COLOR_DISABLED

  local view_bt

  view_bt = self.vb.views["xStreamModelPresetDelete"..idx]
  view_bt.color = base_color

  view_bt = self.vb.views["xStreamModelPresetSchedule"..idx]
  view_bt.color = base_color

  view_bt = self.vb.views["xStreamModelPresetRecall"..idx]
  local preset_color = base_color
  if (self.xstream.selected_model.color > 0) then
    preset_color = cColor.value_to_color_table(self.xstream.selected_model.color)
    if selected then
      preset_color = cColor.adjust_brightness(preset_color,xStreamUI.BRIGHTEN_AMOUNT)
    end
  end
  view_bt.color = preset_color
  view_bt.text = self.xstream.selected_model.selected_preset_bank:get_preset_display_name(idx)
  view_bt.width = xStreamUIPresetPanel.PRESET_RECALL_W

  view_bt = self.vb.views["xStreamPresetListMoveUpButton"..idx]
  view_bt.color = base_color

  view_bt = self.vb.views["xStreamPresetListMoveDownButton"..idx]
  view_bt.color = base_color

  view_bt = self.vb.views["xStreamModelPresetUpdate"..idx]
  view_bt.color = base_color

  view_bt = self.vb.views["xStreamModelPresetFavorite"..idx]
  if view_bt then
    view_bt.color = base_color
    view_bt.text = self.xstream.favorites:get(self.xstream.selected_model.name,idx,preset_bank_name) and 
      xStreamUI.FAVORITE_TEXT.ON or xStreamUI.FAVORITE_TEXT.DIMMED
  end

end

--------------------------------------------------------------------------------
-- update preset+preset bank controls (except the preset selector)

function xStreamUIPresetPanel:update_controls()
  TRACE("xStreamUIPresetPanel:update_controls()")

  local model = self.xstream.selected_model
  if not model then
    return
  end

  local vb = self.vb
  local is_default = model:is_default_bank()
  local preset_index = model.selected_preset_bank.selected_preset_index

  local view_popup      = vb.views["xStreamPresetBankSelector"]
  local rename_bank_bt  = vb.views["xStreamPresetBankRename"]
  local remove_bank_bt  = vb.views["xStreamPresetBankRemove"]
  local rename_bt       = vb.views["xStreamPresetRename"]
  local remove_bt       = vb.views["xStreamRemovePreset"]
  local favorite_bt     = vb.views["xStreamFavoritePreset"]
  local update_bt       = vb.views["xStreamUpdatePreset"]

  -- populate bank selector 
  local preset_bank_names = model:get_preset_bank_names()
  view_popup.items = preset_bank_names
  view_popup.value = model.selected_preset_bank_index

  -- buttons available only for non-default banks
  rename_bank_bt.active = not is_default
  remove_bank_bt.active = not is_default

  local favorite_idx = self.xstream.favorites:get(
    model.name,
    preset_index,
    model.selected_preset_bank.name) 

  -- buttons that depend on a selected preset
  local has_selected = (preset_index > 0)
  rename_bt.active = has_selected
  remove_bt.active = has_selected
  favorite_bt.active = has_selected
  update_bt.active = has_selected

  favorite_bt.text = (favorite_idx and has_selected) and 
    xStreamUI.FAVORITE_TEXT.ON or xStreamUI.FAVORITE_TEXT.DIMMED

  if favorite_idx then
    --print("update_preset_controls - favorite_idx",favorite_idx)
    self.ui.selected_favorite_index = favorite_idx
  end

end

