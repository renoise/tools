--[[============================================================================
xStreamUIFavorites
============================================================================]]--
--[[

Supporting class for xStream, takes care of building the favorites UI

.
#


]]

--==============================================================================

class 'xStreamUIFavorites' (vDialog)

xStreamUIFavorites.FAVORITE_EDIT_BUTTONS = {
  "xStreamFavoritesEditButtonInsert",
  --"xStreamFavoritesEditButtonMove",
  --"xStreamFavoritesEditButtonSwap",
  "xStreamFavoritesEditButtonClear",
  "xStreamFavoritesEditButtonDelete",
}

xStreamUIFavorites.NO_PRESET_BANKS_AVAILABLE = "No preset banks"
xStreamUIFavorites.NO_FAVORITE_SELECTED = "(Select favorite)"
xStreamUIFavorites.NO_PRESETS_AVAILABLE = "No presets"
xStreamUIFavorites.EMPTY_FAVORITE_TXT = "-"

xStreamUIFavorites.EDIT_RACK_WARNING = "⚠ Warning"
xStreamUIFavorites.EDIT_SELECTOR_W = 120

xStreamUIFavorites.FAVORITE_GRID_W = 66
xStreamUIFavorites.FAVORITE_GRID_H = 44
xStreamUIFavorites.FAVORITE_SELECTOR_W = 223

--------------------------------------------------------------------------------

function xStreamUIFavorites:__init(xstream,midi_prefix)
  TRACE("xStreamUIFavorites:__init(xstream,midi_prefix)",xstream,midi_prefix)

  assert(type(xstream)=="xStream","Expected 'xstream' as argument")
  assert(type(midi_prefix)=="string","Expected 'midi_prefix' to be a string")

  self.midi_prefix = midi_prefix
  self.xstream = xstream


  vDialog.__init(self)

  self.title = "xStream favorites"

  -- bool, when true we should display favorites dialog "whenever possible"
  self.pinned = property(self.get_pinned,self.set_pinned)
  self.pinned_observable = renoise.Document.ObservableBoolean(false)

  -- bool, any blinking element should use this 
  self.blink_state = false

  -- table<int> temporarily highlighted buttons in favorites
  --  index (int)
  --  clocked (number)
  self.flash_favorite_buttons = {}

  self.build_requested = false
  self.update_requested = false
  self.edit_rack_requested = false

  self.favorite_views = {}

  self._scheduled_favorite_index = nil

  self.selected_index = property(self.get_selected_index,self.set_selected_index)
  self.selected_index_observable = renoise.Document.ObservableNumber(0)

  -- table<string>, get from the main ui 
  self.model_names = {}

  -- initialize 

  self.selected_index_observable:add_notifier(function()
    TRACE("xStreamUIFavorites - selected_index_observable fired...",self.selected_index)
    self.update_requested = true
  end)

  renoise.tool().app_idle_observable:add_notifier(function()
    self:on_idle()
  end)


end

--------------------------------------------------------------------------------
-- Get/set methods
--------------------------------------------------------------------------------

function xStreamUIFavorites:get_pinned()
  return self.pinned_observable.value 
end

function xStreamUIFavorites:set_pinned(val)
  self.pinned_observable.value = val
end

--------------------------------------------------------------------------------

function xStreamUIFavorites:get_selected_index()
  return self.selected_index_observable.value 
end

function xStreamUIFavorites:set_selected_index(val)
  self.selected_index_observable.value = val
end

--------------------------------------------------------------------------------
-- Overridden class methods (vDialog)
--------------------------------------------------------------------------------

function xStreamUIFavorites:show()
  TRACE("xStreamUIFavorites:show()")

  local do_update = false
  if not self.dialog or not self.dialog.visible
    --and not self.dialog_content 
  then
    do_update = true
  end

  vDialog.show(self)

  if do_update then
    self.build_requested = true
  else
    self.update_requested = true
  end

end

--------------------------------------------------------------------------------
-- Class methods
--------------------------------------------------------------------------------
function xStreamUIFavorites:enable_favorite_edit_buttons()
  for k,v in ipairs(xStreamUIFavorites.FAVORITE_EDIT_BUTTONS) do
    self.vb.views[v].active = true
  end
end

--------------------------------------------------------------------------------

function xStreamUIFavorites:disable_favorite_edit_buttons()
  for k,v in ipairs(xStreamUIFavorites.FAVORITE_EDIT_BUTTONS) do
    self.vb.views[v].active = false
  end
end

--------------------------------------------------------------------------------
-- build

function xStreamUIFavorites:build()
  TRACE("xStreamUIFavorites:build()")

  local vb = self.vb
  local vb_container = vb.views["xStreamFavoritesContainer"]
  if not vb_container then
    return
  end

  for k,v in ipairs(self.favorite_views) do
    v.parent:remove_child(v.view)
  end

  self.favorite_views = {}

  local vb_grid = vb:column{}
  local item_idx = 0

  for row = 1,self.xstream.favorites.grid_rows do
    
    local vb_row = vb:row{}
    for col = 1,self.xstream.favorites.grid_columns do
      
      item_idx = item_idx + 1

      local vb_cell = vb:button{
        height = xStreamUI.BITMAP_BUTTON_H,
        notifier = function()
          local idx = col+((row-1)*self.xstream.favorites.grid_columns)
          self.xstream.favorites:trigger(idx)
        end,
        midi_mapping = self.midi_prefix..
          ("Favorite #%.2d [Trigger]"):format(item_idx)

      }
      vb_row:add_child(vb_cell)
      table.insert(self.favorite_views,{
        view = vb_cell,
        parent = vb_row
      })

    end

    vb_grid:add_child(vb_row)

  end

  vb_container:add_child(vb_grid)
  table.insert(self.favorite_views,{
    view = vb_grid,
    parent = vb_container
  })

  ---------------------------------------------------------


  local build_handler = function()
    TRACE("xStreamUIFavorites - favorites/grid_rows/grid_columns_observable fired...")
    self.build_requested = true
  end

  self.xstream.favorites.favorites_observable:add_notifier(build_handler)
  self.xstream.favorites.grid_rows_observable:add_notifier(build_handler)
  self.xstream.favorites.grid_columns_observable:add_notifier(build_handler)

  self.xstream.favorites.modified_observable:add_notifier(function()
    TRACE("xStreamUIFavorites - favorites.modified_observable fired...")
    self.update_requested = true
    self.update_models_requested = true
    self.update_presets_requested = true

  end)

  self.xstream.favorites.got_triggered_observable:add_notifier(function()
    TRACE("xStreamUIFavorites - favorites.got_triggered_observable fired...")
    if self.xstream.favorites.got_triggered_observable.value then
      local idx = self.xstream.favorites.last_triggered_index
      self:update_edit_rack()
      self:do_select_favorite(idx)
    end
  end)

  self.xstream.favorites.last_selected_index_observable:add_notifier(function()
    TRACE("xStreamUIFavorites - favorites.last_selected_index_observable fired...")
    local idx = self.xstream.favorites.last_selected_index
    self:update_edit_rack()

    self:do_select_favorite(idx)

    if self.previous_selected_index then
      self:update_button(self.previous_selected_index)
    end
    self.previous_selected_index = idx

  end)

  self.xstream.favorites.edit_mode_observable:add_notifier(function()
    TRACE("xStreamUIFavorites - favorites.edit_mode_observable fired...")
    self:update_edit_rack()
    if not self.xstream.favorites.edit_mode then
      self.xstream.favorites.last_selected_index = 0
    end
  end)

  self.xstream.favorites.update_buttons_requested_observable:add_notifier(function()
    TRACE("xStreamUIFavorites - favorites.update_buttons_requested_observable fired...")
    self:update_buttons()
  end)

end

--------------------------------------------------------------------------------
-- build

function xStreamUIFavorites:create_dialog()
  TRACE("xStreamUIFavorites:create_dialog()")

  local vb = self.vb
  return vb:column{ 
    id = "xStreamFavoritesPanel",
    style = "panel",
    margin = 4,
    vb:row{ 
      vb:row{
        vb:row{ 
          vb:button{
            id = "xStreamFavoritesPinnedButton",
            bitmap = "./source/icons/pin.png",
            tooltip = "Keep dialog open",
            notifier = function()
              self.pinned = not self.pinned
              self:update_pinned_state()
            end
          },
          vb:text{
            text = "Keep open",
          },
        },
        --[[
        vb:row{
          id = "xStreamFavoriteTriggerButton",
          vb:space{
            width = xStreamUIFavorites.FAVORITE_SELECTOR_W-120,
          },
          vb:button{
            text = "Trigger selected",
            notifier = function()
              self.xstream.favorites:trigger(self.xstream.favorites.last_selected_index)
            end
          },
        },
        ]]
        vb:row{
          id = "xStreamFavoritesSize",
          vb:space{
            width = 16,
          },  
          vb:text{
            text = "size",
          },
          vb:valuebox{
            min = 1,
            max = 16,
            bind = self.xstream.favorites.grid_columns_observable,
            width = 50,
          },
          vb:text{
            text = "x",
          },
          vb:valuebox{
            min = 1,
            max = 16,
            bind = self.xstream.favorites.grid_rows_observable,
            width = 50,
          },
        },
      },
    },

    vb:column{
      id = "xStreamFavoritesContainer",

    },
    vb:column{
      id = "xStreamFavoritesLowerToolbar",
      vb:row{
        vb:row{ -- edit
          id = "xStreamFavoritesEditToggleRow",
          vb:row{
            tooltip = "Toggle editing of favorites",
            id = "xStreamFavoritesEditToggle",
            vb:text{
              text = "Edit",
            },
            vb:checkbox{
              bind = self.xstream.favorites.edit_mode_observable,
            },
          },
        },
        vb:column{ 
          vb:column{ -- buttons
            id = "xStreamFavoritesEditButtons",
            visible = self.xstream.favorites.edit_mode,
            vb:row{
              vb:button{
                text = "Insert",
                tooltip = "Insert a new favorite at the selected position",
                id = "xStreamFavoritesEditButtonInsert",
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function()
                  local favorite_idx = self.xstream.favorites.last_selected_index
                  if favorite_idx then
                    self.xstream.favorites:add(favorite_idx+1)
                    self.xstream.favorites.last_selected_index = favorite_idx+1
                  end                        
                end,
              },
              --[[
              vb:button{
                text = "move",
                id = "xStreamFavoritesEditButtonMove",
                active = false,
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function()
                  renoise.app():show_message("Not yet implemented")
                end,
              },
              vb:button{
                text = "swap",
                id = "xStreamFavoritesEditButtonSwap",
                active = false,
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function()
                  renoise.app():show_message("Not yet implemented")
                end,
              },
              ]]
              vb:button{
                text = "Clear",
                tooltip = "Clear favorite at the selected position",
                id = "xStreamFavoritesEditButtonClear",
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function()
                  local favorite_idx = self.xstream.favorites.last_selected_index
                  if favorite_idx then
                    self.xstream.favorites:clear(favorite_idx)
                  end
                end,
              },
              vb:button{
                text = "Delete",
                id = "xStreamFavoritesEditButtonDelete",
                tooltip = "Delete favorite from the selected position",
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function()
                  local favorite_idx = self.xstream.favorites.last_selected_index
                  if favorite_idx then
                    self.xstream.favorites:remove_by_index(favorite_idx)
                  end
                end,
              },
            },
            vb:space{
              height = xStreamUI.SMALL_VERTICAL_MARGIN,
            },
          },
          vb:popup{ -- selector
            items = {},
            tooltip = "Select among available favorites",
            id = "xStreamFavoriteSelector",
            width = xStreamUIFavorites.FAVORITE_SELECTOR_W,
            height = xStreamUI.BITMAP_BUTTON_H,
            notifier = function(val)
              self.xstream.favorites.last_selected_index = val-1
            end
          }
        },
      },
      vb:row{
        id = "xStreamFavoritesEditRack",
        visible = false,
        vb:column{
          vb:row{
            id = "xStreamFavoritesLaunchRack",
            visible = false,
            vb:column{
              vb:space{
                height = xStreamUI.SMALL_VERTICAL_MARGIN,
              },
              vb:row{
                vb:text{
                  text = "Model",
                  width = xStreamUI.EDIT_RACK_MARGIN,
                },
                vb:popup{
                  items = {},
                  id = "xStreamFavoriteModelSelector",
                  notifier = function(val)
                    local favorite_idx = self.xstream.favorites.last_selected_index
                    local popup = self.vb.views["xStreamFavoriteModelSelector"]
                    self:apply_property(favorite_idx,"model_name",popup.items[val])
                  end
                },
                vb:text{
                  text = "",
                  id = "xStreamFavoriteModelStatus",
                },

              },
              vb:row{
                vb:text{
                  text = "Bank",
                  width = xStreamUI.EDIT_RACK_MARGIN,
                },
                vb:popup{
                  items = {},
                  id = "xStreamFavoriteBankSelector",
                  notifier = function(val)
                    local favorite_idx = self.xstream.favorites.last_selected_index
                    local popup = self.vb.views["xStreamFavoriteBankSelector"]
                    self:apply_property(favorite_idx,"preset_bank_name",popup.items[val])
                  end
                },
                vb:text{
                  text = "",
                  id = "xStreamFavoriteBankStatus",
                },
              },
              vb:row{
                vb:text{
                  text = "Preset",
                  width = xStreamUI.EDIT_RACK_MARGIN,
                },
                vb:popup{
                  items = {},
                  id = "xStreamFavoritePresetSelector",
                  notifier = function(val)
                    local favorite_idx = self.xstream.favorites.last_selected_index
                    self:apply_property(favorite_idx,"preset_index",val-1)
                  end
                },
                vb:text{
                  text = "",
                  id = "xStreamFavoritePresetStatus",
                },
              },
            },
          },
          vb:space{
            height = xStreamUI.SMALL_VERTICAL_MARGIN,
          },
          vb:row{

            vb:row{
              vb:text{
                text = "Launch",
                width = xStreamUI.EDIT_RACK_MARGIN,
              },
              vb:popup{
                items = xStreamFavorites.LAUNCH_MODES,
                tooltip = "Determine the 'launch behavior' of the selected favorite"
                        .."\nAUTOMATIC - automatically use streaming when playing, or apply when stopped"
                        .."\nSTREAMING - always use streaming, with customizable scheduling"
                        .."\nAPPLY_TRACK - always apply to selected track"
                        .."\nAPPLY_SELECTION - always apply to selection in track",
                id = "xStreamFavoritesLaunchPopup",
                width = 86,
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function(val)
                  local favorite = self.xstream.favorites.last_selected
                  if favorite then
                    if (favorite.launch_mode ~= val) then
                      favorite.launch_mode = val
                      self.xstream.favorites.modified = true
                      self.edit_rack_requested = true
                    end
                  end
                end
              },
            },
            vb:row{
              id = "xStreamFavoritesScheduleRack",
              tooltip = "Choose between available scheduling modes (applies to streaming mode only)",
              visible = false,
              vb:text{
                text = "scheduling",
              },
              vb:popup{
                items = xStreamPos.SCHEDULES,
                value = xStreamPos.SCHEDULE.BEAT,
                id = "xStreamFavoritesSchedulePopup",
                width = 64,
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function(val)
                  local favorite = self.xstream.favorites.last_selected
                  if favorite then
                    if (favorite.schedule_mode ~= val) then
                      favorite.schedule_mode = val
                      self.xstream.favorites.modified = true
                      self.edit_rack_requested = true
                    end
                  end
                end
              },
            },
            vb:row{
              id = "xStreamFavoritesAnchorRack",
              tooltip = "Choose 'anchoring' when applying to selection (offline mode only)"
                      .."\nPATTERN - relative to top of pattern"
                      .."\nSELECTION - relative to start of selection",
              visible = false,
              vb:text{
                text = "anchor",
              },
              vb:popup{
                items = xStreamFavorites.APPLY_MODES,
                value = xStreamFavorites.APPLY_MODE.PATTERN,
                id = "xStreamFavoritesAnchorPopup",
                height = xStreamUI.BITMAP_BUTTON_H,
                notifier = function(val)
                  local favorite = self.xstream.favorites.last_selected
                  if favorite then
                    if (favorite.apply_mode ~= val) then
                      favorite.apply_mode = val
                      self.xstream.favorites.modified = true
                      self.edit_rack_requested = true
                    end
                  end
                end
              },
            },
          },
        },
      },
    },
  }

end

--------------------------------------------------------------------------------

function xStreamUIFavorites:update_scheduled_button()
  TRACE("xStreamUIFavorites:update_scheduled_button()")

  local member = self.xstream.stack:get_selected_member()
  if (member.scheduled_favorite_index == 0) then
    self:update_button(self._scheduled_favorite_index)
    self._scheduled_favorite_index = nil
  else
    self._scheduled_favorite_index = member.scheduled_favorite_index
  end

end

--------------------------------------------------------------------------------

function xStreamUIFavorites:update_buttons()
  TRACE("xStreamUIFavorites:update_buttons()")

  for idx,_ in ipairs(self.favorite_views) do
    self:update_button(idx)
  end

end

--------------------------------------------------------------------------------
-- display the favorite information using color, text and symbols
-- @param idx (int), the favorite index
-- @param brightness (number, between 0-1) override color when blinking (optional)

function xStreamUIFavorites:update_button(idx,brightness)
  TRACE("xStreamUIFavorites:update_button(idx,brightness)",idx,brightness)

  assert(type(idx)=="number","Expected 'idx' to be a number")
  --assert(type(idx)=="brightness","Expected 'brightness' to be a number")

  local vb_table = self.favorite_views[idx]
  if not vb_table then
    return
  end

  local view_bt = vb_table.view
  if not view_bt or not (type(view_bt)=="Button")then
    return
  end

  local favorite = self.xstream.favorites:get_by_index(idx)
  local str_txt = xStreamUIFavorites.EMPTY_FAVORITE_TXT
  local na_prefix = "⚠"
  local color = table.rcopy(xLib.COLOR_DISABLED)
  if not (type(favorite)=="xStreamFavorite") then
    str_txt = xStreamUIFavorites.EMPTY_FAVORITE_TXT
  else
    local model_idx,model = self.xstream.models:get_by_name(favorite.model_name)
    if not model then
      -- Display as 
      -- N/A: Model Name (soft wrapped)
      -- 
      str_txt = ("%s %s"):format(na_prefix,cString.soft_wrap(favorite.model_name))
    else
      color = cColor.value_to_color_table(model.color)
      local str_launch_mode = xStreamFavorites.LAUNCH_MODES_SHORT[favorite.launch_mode]
      local is_automatic = (favorite.launch_mode == xStreamFavorites.LAUNCH_MODE.AUTOMATIC)
      local is_default_bank = (favorite.preset_bank_name == xStreamModelPresets.DEFAULT_BANK_NAME)
      local preset_bank_index = model:get_preset_bank_by_name(favorite.preset_bank_name)
      local preset_bank = model.preset_banks[preset_bank_index]
      if favorite.preset_index and (favorite.preset_index ~= 0) then
        local preset_exists = (preset_bank and preset_bank.presets[favorite.preset_index])
        local final_prefix = (preset_bank and preset_exists) and "" or na_prefix
        if is_default_bank then
          -- Display as
          -- Model Name
          -- [N/A] #Preset Launch
          str_txt = ("%s\n%s %.2d %s"):format(
            favorite.model_name,final_prefix,favorite.preset_index,str_launch_mode)
        else
          -- Display as, when automatic (two lines)
          -- Model Name
          -- [N/A] #Preset Bank Launch
          --
          -- or, when not automatic launch (three lines)
          -- Model Name
          -- [N/A] #Preset Bank
          -- [Launch]
          local str_patt = is_automatic
            and "%s\n%s %.2d:%s%s" or "%s\n%s %.2d:%s\n%s"
          str_txt = (str_patt):format(
            favorite.model_name,final_prefix,favorite.preset_index,favorite.preset_bank_name,str_launch_mode)
        end
      else -- no preset 
        if is_default_bank then
          -- Display as 
          -- Model Name (soft wrapped)
          -- [Launch]
          str_txt = is_automatic
            and ("%s"):format(cString.soft_wrap(favorite.model_name))
            or ("%s\n%s"):format(favorite.model_name,str_launch_mode)
        else
          -- Display as 
          -- Model Name 
          -- [N/A] Bank
          -- [Launch]
          local final_prefix = (preset_bank) and "" or na_prefix
          str_txt = is_automatic
            and ("%s\n%s%s"):format(favorite.model_name,final_prefix,favorite.preset_bank_name)
            or ("%s\n%s%s\n%s"):format(favorite.model_name,final_prefix,favorite.preset_bank_name,str_launch_mode)
        end
      end
    end
  end

  if brightness then
    color = cColor.adjust_brightness(color,brightness)
  else
    if (idx == self.selected_index) then
      color = cColor.adjust_brightness(color,xStreamUI.SELECTED_COLOR) -- dark
    elseif (idx == self.xstream.favorites.last_selected_index) then
      color = cColor.adjust_brightness(color,xStreamUI.BRIGHTEN_AMOUNT) -- light
    end
  end

  view_bt.color = color
  view_bt.text = str_txt
  view_bt.width = xStreamUIFavorites.FAVORITE_GRID_W
  view_bt.height = xStreamUIFavorites.FAVORITE_GRID_H

end

--------------------------------------------------------------------------------
-- invoked by "got_triggered" and when manually selecting via popup

function xStreamUIFavorites:do_select_favorite(idx)
  TRACE("xStreamUIFavorites:do_select_favorite(idx)",idx)

  assert(type(idx)=="number","Expected 'idx' to be a number")

  if not self.xstream.favorites.items[idx] then
    return
  end

  local favorite_selector = self.vb.views["xStreamFavoriteSelector"]
  local selector_index = idx+1
  if (selector_index > #favorite_selector.items) then
    return
  end

  favorite_selector.value = idx+1

  -- provide immediate feedback for triggered button 
  table.insert(self.flash_favorite_buttons,{index=idx,clocked=os.clock()})
  self:update_button(idx,xStreamUI.MAX_BRIGHT_COLOR)

end

--------------------------------------------------------------------------------
-- display the right editing controls

function xStreamUIFavorites:update_edit_rack()
  TRACE("xStreamUIFavorites:update_edit_rack()")

  local favorite = self.xstream.favorites.last_selected --or 
    --self.xstream.favorites.last_triggered

  local vb = self.vb
  local launch_rack = vb.views["xStreamFavoritesLaunchRack"]
  local anchor_rack = vb.views["xStreamFavoritesAnchorRack"]
  local schedule_rack = vb.views["xStreamFavoritesScheduleRack"]
  local view_edit_rack = vb.views["xStreamFavoritesEditRack"]

  anchor_rack.visible = false
  schedule_rack.visible = false

  self:enable_favorite_edit_buttons()

  launch_rack.visible = true
  view_edit_rack.visible = self.xstream.favorites.edit_mode

  local launch_popup = vb.views["xStreamFavoritesLaunchPopup"]
  launch_popup.value = favorite and favorite.launch_mode or 1

  if (type(favorite)=="xStreamFavorite") then
    if (favorite.launch_mode == xStreamFavorites.LAUNCH_MODE.AUTOMATIC) then
      --
    elseif (favorite.launch_mode == xStreamFavorites.LAUNCH_MODE.STREAMING) then
      schedule_rack.visible = true
      local schedule_popup = vb.views["xStreamFavoritesSchedulePopup"]
      schedule_popup.value = favorite.schedule_mode
    elseif (favorite.launch_mode == xStreamFavorites.LAUNCH_MODE.APPLY_TRACK) then
      -- 
    elseif (favorite.launch_mode == xStreamFavorites.LAUNCH_MODE.APPLY_SELECTION) then
      anchor_rack.visible = true
      local anchor_popup = vb.views["xStreamFavoritesAnchorPopup"]
      anchor_popup.value = favorite.apply_mode
    end
  end

  local view_edit_buttons = vb.views["xStreamFavoritesEditButtons"]
  view_edit_buttons.visible = self.xstream.favorites.edit_mode 

  -- update selectors -------------------------------------

  self:update_favorite_selector()
  self:update_model_selector(self.model_names)
  self:update_edit_model_selector()
  self:update_bank_selector()
  self:update_preset_selector()

end

--------------------------------------------------------------------------------

function xStreamUIFavorites:update_edit_model_selector()
  TRACE("xStreamUIFavorites:update_edit_model_selector()")

  local favorite_idx = self.xstream.favorites.last_selected_index
  local favorite = self.xstream.favorites.items[favorite_idx]

  local model_selector = self.vb.views["xStreamFavoriteModelSelector"]
  local model_status = self.vb.views["xStreamFavoriteModelStatus"]
  
  if type(favorite) ~= "xStreamFavorite" then
    model_selector.value = 1
    return
  end

  local model_idx,model = self.xstream.models:get_by_name(favorite.model_name)
  if not model then
    model_status.text = xStreamUIFavorites.EDIT_RACK_WARNING
    model_status.tooltip = "This model is not available"
  else
    model_status.text = ""
    model_status.tooltip = ""
    model_selector.value = model_idx+1
    model_selector.width = xStreamUIFavorites.EDIT_SELECTOR_W
  end

end

--------------------------------------------------------------------------------

function xStreamUIFavorites:update_bank_selector()
  TRACE("xStreamUIFavorites:update_bank_selector()")

  local favorite_idx = self.xstream.favorites.last_selected_index
  local favorite = self.xstream.favorites.items[favorite_idx]

  local bank_selector = self.vb.views["xStreamFavoriteBankSelector"]
  if not bank_selector then
    return
  end

  local bank_status = self.vb.views["xStreamFavoriteBankStatus"]
  
  if type(favorite) ~= "xStreamFavorite" then
    bank_selector.value = 1
    bank_selector.active = false
    return
  else
    bank_selector.active = true
  end

  local model_idx,model = self.xstream.models:get_by_name(favorite.model_name)
  if not model then
    bank_status.text = xStreamUIFavorites.EDIT_RACK_WARNING
    bank_selector.items = {xStreamUIFavorites.NO_PRESET_BANKS_AVAILABLE}
  else
    bank_selector.items = model:get_preset_bank_names()
    local preset_bank_index = model:get_preset_bank_by_name(favorite.preset_bank_name)
    if preset_bank_index then
      bank_selector.value = preset_bank_index
      bank_selector.width = xStreamUIFavorites.EDIT_SELECTOR_W
      bank_status.text = ""
      bank_status.tooltip = ""
    else
      bank_status.text = xStreamUIFavorites.EDIT_RACK_WARNING
      bank_status.tooltip = "This preset bank is not available"
    end
  end

end
--------------------------------------------------------------------------------

function xStreamUIFavorites:update_preset_selector()
  TRACE("xStreamUIFavorites:update_preset_selector()")

  local favorite_idx = self.xstream.favorites.last_selected_index
  local favorite = self.xstream.favorites.items[favorite_idx]

  local preset_selector = self.vb.views["xStreamFavoritePresetSelector"]
  if not preset_selector then
    return -- dialog not visible
  end

  local preset_status = self.vb.views["xStreamFavoritePresetStatus"]
  local items_set = false

  if type(favorite)=="xStreamFavorite" then

    preset_selector.active = true

    local model_idx,model = self.xstream.models:get_by_name(favorite.model_name)

    if model then
      local preset_bank_index = model:get_preset_bank_by_name(favorite.preset_bank_name)
      if preset_bank_index then
        -- gather preset names
        local preset_bank = model.preset_banks[preset_bank_index]
        local preset_names = (#preset_bank.presets == 0) and 
          {xStreamUIFavorites.NO_PRESETS_AVAILABLE} or {"Select preset"}
        for k,v in ipairs(preset_bank.presets) do
          table.insert(preset_names,("Preset %.02d"):format(k))
        end
        preset_selector.items = preset_names
        local preset_index = (favorite.preset_index > 0) and favorite.preset_index+1 or 1
        if (preset_index <= #preset_selector.items) then
          preset_selector.value = preset_index
          preset_selector.width = xStreamUIFavorites.EDIT_SELECTOR_W
        else
          preset_selector.value = 1
        end
        items_set = true
      end
    end
  else
    
    preset_selector.value = 1
    preset_selector.active = false

  end

  if not items_set then
    preset_selector.items = {xStreamUIFavorites.NO_PRESETS_AVAILABLE}
    preset_selector.value = 1
  end

end

--------------------------------------------------------------------------------
-- apply a single property to a favorite (existing or empty)
-- @param favorite_idx (int)
-- @param prop_name (string)
-- @param prop_value (number/string/boolean)

function xStreamUIFavorites:apply_property(favorite_idx,prop_name,prop_value)
  TRACE("xStreamUIFavorites:apply_property(favorite_idx,prop_name,prop_value)",favorite_idx,prop_name,prop_value)

  --assert(type(idx)=="favorite_idx","Expected 'favorite_idx' to be a number")
  --assert(type(idx)=="prop_name","Expected 'prop_name' to be a string")

  local favorite = self.xstream.favorites.items[favorite_idx]
  if not favorite then
    return
  end

  local is_empty = false
  if type(favorite)~="xStreamFavorite" then
    favorite = xStreamFavorite()
    is_empty = true
  end

  if (favorite[prop_name] == prop_value) then
    return
  end

  favorite[prop_name] = prop_value
  self.xstream.favorites.modified = true
  self.edit_rack_requested = true

  -- update controls (favorite icon)
  if self.xstream.selected_model then
    if (favorite.model_name == self.xstream.selected_model.name) then
      self.xstream.ui.model_toolbar:update() 
      self.xstream.ui:update_preset_list() 
      if (favorite.preset_bank_name == self.xstream.selected_model.selected_preset_bank.name) then
        self:update_preset_controls() 
      end
    end
  end

  if (favorite.model_name ~= "") and 
    (favorite.model_name ~= xStreamUI.NO_MODEL_SELECTED) 
  then
    if is_empty then
      self.xstream.favorites:assign(favorite_idx,favorite)
    end
  else
    self.xstream.favorites:clear(favorite_idx)
  end

end

--------------------------------------------------------------------------------

function xStreamUIFavorites:update_favorite_selector()
  TRACE("xStreamUIFavorites:update_favorite_selector()")

  local favorite_selector = self.vb.views["xStreamFavoriteSelector"]
  if favorite_selector then
    local favorite_names = self.xstream.favorites:get_names()
    table.insert(favorite_names,1,xStreamUIFavorites.NO_FAVORITE_SELECTED)
    favorite_selector.items = favorite_names
  end

end

-------------------------------------------------------------------------------
-- @param model_names (table)

function xStreamUIFavorites:update_model_selector(model_names)
  --TRACE("xStreamUIFavorites:update_model_selector(model_names)",model_names)

  assert(type(model_names)=="table","Expected 'model_names' to be a table")

  self.model_names = model_names

  local selector = self.vb.views["xStreamFavoriteModelSelector"]
  if selector then
    selector.items = model_names
  end

end


-------------------------------------------------------------------------------
--

function xStreamUIFavorites:update_pinned_state()
  TRACE("xStreamUIFavorites:update_pinned_state()")

  local view = self.vb.views["xStreamFavoritesPinnedButton"]
  if view then
    local color = self.pinned
      and xLib.COLOR_ENABLED or xLib.COLOR_DISABLED
    view.color = color
  end

end

-------------------------------------------------------------------------------
-- blinking/flashing stuff, delayed display updates

function xStreamUIFavorites:on_idle()

  local blink_state = (math.floor(os.clock()*4)%2 == 0) 
  if (blink_state ~= self.blink_state) then
    if self._scheduled_favorite_index then
      self:update_button(
        self._scheduled_favorite_index, (not blink_state) and xStreamUI.DIMMED_AMOUNT)
    end
  end

  if self.build_requested then
    self.build_requested = false
    self:build()
    self.update_requested = true
  end

  if self.update_requested then
    self.update_requested = false
    self:update_buttons()
    self:update_favorite_selector()
    self:update_pinned_state()
  end

  if self.edit_rack_requested then
    self.edit_rack_requested = false
    self:update_edit_rack()
    self:update_button(self.xstream.favorites.last_selected_index)
  end

  for k,v in ripairs(self.flash_favorite_buttons) do
    if (v.clocked < os.clock() - xStreamUI.FLASH_TIME) then
      if (v.index ~= self._scheduled_favorite_index) then
        self:update_button(v.index)
      end
      table.remove(self.flash_favorite_buttons,k)
    end
  end



end