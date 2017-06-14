--[[===============================================================================================
xStreamUILuaEditor
===============================================================================================]]--
--[[

Lua code editor for xStream 

]]

--=================================================================================================

class 'xStreamUILuaEditor'

xStreamUILuaEditor.NUM_CHARS = 80 -- number of characters to display
xStreamUILuaEditor.MONO_CHAR_W = 6 -- single character decides total width 
xStreamUILuaEditor.LINE_HEIGHT = 14
xStreamUILuaEditor.EDITOR_W = 
  xStreamUILuaEditor.NUM_CHARS * xStreamUILuaEditor.MONO_CHAR_W + 20 -- + scrollbar,margin
xStreamUILuaEditor.WELCOME_MSG = [[



          ██╗  ██╗███████╗████████╗██████╗ ███████╗ █████╗ ███╗   ███╗
          ╚██╗██╔╝██╔════╝╚══██╔══╝██╔══██╗██╔════╝██╔══██╗████╗ ████║
           ╚███╔╝ ███████╗   ██║   ██████╔╝█████╗  ███████║██╔████╔██║
           ██╔██╗ ╚════██║   ██║   ██╔══██╗██╔══╝  ██╔══██║██║╚██╔╝██║
          ██╔╝ ██╗███████║   ██║   ██║  ██║███████╗██║  ██║██║ ╚═╝ ██║
          ╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝
]]


--------------------------------------------------------------------------------------------------

function xStreamUILuaEditor:__init(xstream,vb)
  TRACE("xStreamUILuaEditor:__init(xstream,vb)",xstream,vb)

  assert(type(xstream)=="xStream")
  assert(type(vb)=="ViewBuilder")

  self.xstream = xstream 
  self.vb = vb
  self.prefs = renoise.tool().preferences

  self.visible = property(self.get_visible,self.set_visible)
  self._visible = nil

  self.active = property(self.get_active,self.set_active)
  self._active = nil

  -- string, tells us the type of content in the editor 
  -- valid values are "main", "data.[xStreamArg.full_name]" or "event.[xMidiMessage.TYPE]"
  self.editor_view = "main"

  -- bool, suppress editor notifications 
  self.suppress_editor_notifier = false

  --== notifiers ==--

  self.prefs.editor_visible_lines:add_notifier(function()
    TRACE("xStreamUILuaEditor - self.editor_visible_lines_observable fired...")
    self.xstream.ui.update_editor_requested = true
  end)

  --== initialize ==--

  self:attach_to_process()

end

---------------------------------------------------------------------------------------------------
-- Getters/Setters
---------------------------------------------------------------------------------------------------

function xStreamUILuaEditor:get_visible()
  return self._visible
end

function xStreamUILuaEditor:set_visible(val)
  self._visible = val
  self.vb.views["xStreamCallbackEditorRack"].visible = val
  --self.vb.views["xStreamCallbackEditorToolbar"].visible = val
end

---------------------------------------------------------------------------------------------------

function xStreamUILuaEditor:get_active()
  return self._active
end

function xStreamUILuaEditor:set_active(val)
  self._active = val
  if (renoise.API_VERSION > 4) then
    self.vb.views["xStreamCallbackEditor"].active = val
  end
  
end

---------------------------------------------------------------------------------------------------

function xStreamUILuaEditor:build()
  TRACE("xStreamUILuaEditor:build()")

  local vb = self.vb

  return vb:column {
    id = "xStreamCallbackEditorRack",
    style = "plain",
    vb:row {
      margin = 3,
      --style = "plain",
      vb:row {
        margin = -3,    
        vb:multiline_textfield{
          text = "",
          font = "mono",
          height = 200,
          width = xStreamUILuaEditor.EDITOR_W, 
          id = "xStreamCallbackEditor",
          notifier = function(str)
            if self.suppress_editor_notifier then
              return
            end
            if self.xstream.selected_model then
              self.xstream.ui.user_modified_callback = true
            end
          end,
        },
      },
    },
    vb:horizontal_aligner{
      id = "xStreamCallbackEditorToolbar",
      margin = 2,
      width = xStreamUILuaEditor.EDITOR_W, 
      mode = "justify",
      
      vb:row{
        vb:text{
          id = "xStreamCallbackStatus",
          text = "",
        }
      },
      vb:row{
        vb:text{
          text = "View",
        },
        vb:popup{
          id = "xStreamCallbackType",
          --items = {"main","data","note_on","note_off"},
          width = 120,
          notifier = function(idx)
            local vb_elm = vb.views["xStreamCallbackType"]
            self.editor_view = vb_elm.items[idx]
            self:set_content()
          end,
        },
        vb:button{
          bitmap = "./source/icons/add.bmp",
          tooltip = "Create a new callback",
          id = "xStreamCallbackCreate",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            self.xstream.ui.create_callback_dialog:show()
          end,
        },

        vb:button{
          bitmap = "./source/icons/rename.bmp",
          tooltip = "Rename the selected callback",
          id = "xStreamCallbackRename",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            local passed,err = self:rename_callback()
            if err then
              renoise.app():show_warning(err)
            end
          end,
        },
        vb:button{
          bitmap = "./source/icons/delete_small.bmp",
          tooltip = "Delete the selected callback",
          id = "xStreamCallbackRemove",
          width = xStreamUI.BITMAP_BUTTON_W,
          height = xStreamUI.BITMAP_BUTTON_H,
          notifier = function()
            self:remove_callback()
          end,
        },

      },
    }
  }
  
end    

--------------------------------------------------------------------------------

function xStreamUILuaEditor:attach_to_process()
  TRACE("xStreamUILuaEditor:attach_to_process()")

  self.xstream.stack.selected_member_index_observable:add_notifier(function()
    --print(">>> attach_to_process - selected_member_index fired...")
    
    local member = self.xstream.stack:get_selected_member()
    --print(">>> attach_to_process - member",member)
    if member then
      member.buffer.callback_status_observable:add_notifier(function()    
        --print("xStreamUILuaEditor - callback_status_observable fired...")
        self:update_callback_status()
      end)
    end

    self:update_callback_status()

  end)

end

--------------------------------------------------------------------------------

function xStreamUILuaEditor:update_callback_status()
  TRACE("xStreamUILuaEditor:update_callback_status()")

  local member = self.xstream.stack:get_selected_member()
  local str_err = ""
  if member then 
    str_err = member.buffer.callback_status_observable.value
  end
  local view = self.vb.views["xStreamCallbackStatus"]
  if (str_err == "") then
    view.text = "✔ Syntax OK"
    view.tooltip = ""
  else
    view.text = "⚠ Syntax Error"
    view.tooltip = str_err
  end 
end

--------------------------------------------------------------------------------
-- apply editor text to the relevant callback/data/event

function xStreamUILuaEditor:apply_editor_content()
  TRACE("xStreamUILuaEditor:apply_editor_content()")

  --local model = self.xstream.selected_model
  local member = self.xstream.stack:get_selected_member()  
  if member and member.model then
    --print("xStreamUI:on_idle - callback modified")
    local view = self.vb.views["xStreamCallbackEditor"]
    local cb_type,cb_key,cb_subtype_or_tab,cb_arg_name = xStream.parse_callback_type(self.editor_view)
    local trimmed_text = cString.trim(view.text)
    local status_obs = member.buffer.callback_status_observable
    if (cb_type == "main") then
      member.model.callback_str = trimmed_text
    elseif (cb_type == "data") then
      local def = table.rcopy(member.model.data_initial)
      def[cb_key] = trimmed_text
      local str_status = member.model:parse_data(def)
      --print("str_status",str_status)
      status_obs.value = str_status
    elseif (cb_type == "events") then
      local def = table.rcopy(member.model.events)
      local cb_name = cb_arg_name and cb_subtype_or_tab.."."..cb_arg_name or cb_subtype_or_tab
      def[cb_key.."."..cb_name] = trimmed_text
      --print("apply content",cb_key.."."..cb_name)
      local str_status = member.model:parse_events(def)
      status_obs.value = str_status
    end
    member.model.modified = true

  end

end

--------------------------------------------------------------------------------

function xStreamUILuaEditor:rename_callback(new_name)
  TRACE("xStreamUILuaEditor:rename_callback(new_name)",new_name)

  local model = self.xstream.selected_model
  if not model then
    return
  end

  local cb_type,cb_key,cb_subtype = xStream.parse_callback_type(self.editor_view)

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

  self.editor_view = cb_type.."."..new_name
  self.xstream.ui.user_modified_callback = true

end

--------------------------------------------------------------------------------

function xStreamUILuaEditor:update()
  TRACE("xStreamUILuaEditor:update()")

  local model = self.xstream.selected_model
  local view = self.vb.views["xStreamCallbackEditor"]

  view.height = self.prefs.editor_visible_lines.value * xStreamUILuaEditor.LINE_HEIGHT - 6

  -- type popup: include defined data + events 
  local vb_type_popup = self.vb.views["xStreamCallbackType"]
  local items = {}
  if model then
    for k,v in pairs(model.data) do
      table.insert(items,("data.%s"):format(k))
    end
    for k,v in pairs(model.events) do
      table.insert(items,("events.%s"):format(k))
    end
  end
  table.sort(items)
  if model then
    table.insert(items,1,"main")
  end
  vb_type_popup.items = items
  vb_type_popup.value = table.find(items,self.editor_view) or 1
  vb_type_popup.active = (#items > 1)

  self:set_content()

end


--------------------------------------------------------------------------------
-- update editor with the relevant callback 

function xStreamUILuaEditor:set_content()
  TRACE("xStreamUILuaEditor:set_content()")

  local text = nil
  local model = self.xstream.selected_model
  local vb = self.vb

  local vb_remove = vb.views["xStreamCallbackRemove"]
  local vb_rename = vb.views["xStreamCallbackRename"]
  local vb_toolbar = vb.views["xStreamCallbackEditorToolbar"]

  -- resize, don't hide toolbar 
  vb_toolbar.width = model and xStreamUILuaEditor.EDITOR_W or 1

  if not model then
    text = xStreamUILuaEditor.WELCOME_MSG
  else
    local cb_type,cb_key,cb_subtype_or_tab,cb_arg_name = 
      xStream.parse_callback_type(self.editor_view)
    if (cb_type == "main") then
      text = model.sandbox.callback_str 
      vb_rename.active = false
      vb_remove.active = false
    elseif (cb_type == "data") then
      if not model.data_initial[cb_key] then 
        -- missing initial data - most likely because data was 
        -- added on the fly, inside 'main'. Setting to 'nil' 
        -- will not interfere with the logic :D
        model.data_initial[cb_key] = xStreamModel.DEFAULT_DATA_STR:format("nil")
      end 
      text = model.data_initial[cb_key]
      vb_rename.active = true
      vb_remove.active = true
    elseif (cb_type == "events") then
      -- when argument, we can have four parts
      local cb_name = cb_arg_name and cb_subtype_or_tab.."."..cb_arg_name or cb_subtype_or_tab
      text = model.events[cb_key.."."..cb_name]
      vb_rename.active = false
      vb_remove.active = true
    end
  end

  --rprint(text)

  -- prevent notifier from firing
  local view = self.vb.views["xStreamCallbackEditor"]
  self.suppress_editor_notifier = true
  view.text = text --cString.trim(text).."\n"
  self.suppress_editor_notifier = false

end


--------------------------------------------------------------------------------

function xStreamUILuaEditor:remove_callback()

  local model = self.xstream.selected_model
  if not model then
    return
  end

  local choice = renoise.app():show_prompt("Remove callback",
      "Are you sure you want to remove this callback?",
    {"OK","Cancel"})
  
  if (choice == "OK") then
    local cb_type,cb_key,cb_subtype = xStream.parse_callback_type(self.editor_view)
    model:remove_callback(cb_type,cb_subtype and cb_key.."."..cb_subtype or cb_key)
    self.xstream.ui.update_editor_requested = true
  end

end

