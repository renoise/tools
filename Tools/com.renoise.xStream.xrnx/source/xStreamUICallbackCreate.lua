--[[============================================================================
xStreamUICallbackCreate
============================================================================]]--

--[[

Supporting UI class for xStream

]]

--==============================================================================

class 'xStreamUICallbackCreate' (vDialogWizard)

function xStreamUICallbackCreate:__init(ui)
  TRACE("xStreamUICallbackCreate:__init(ui)",ui)

  vDialogWizard.__init(self)

  self.title = "Create callback"

  self.ui = ui
  self.xstream = self.ui.xstream

  -- xStreamModel.CB_TYPE
  self.cb_type = nil

end

--------------------------------------------------------------------------------
-- (overridden method)

function xStreamUICallbackCreate:show()

  vDialogWizard.show(self)

  self.dialog_page = 1
  self.dialog_option = 1
  self:update_dialog()

end

-------------------------------------------------------------------------------
-- (overridden method)
-- @return renoise.Views.Rack

function xStreamUICallbackCreate:create_dialog()
  TRACE("xStreamUICallbackCreate:create_dialog()")

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
              "Add userdata",
              "Add event handler",
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
              text = "Please specify a (unique) name",
            },
            vb:textfield{
              id = "xStreamDialogName",
              text = "",
              width = PAGE_W-20,
            },
          },
          vb:column{
            id = "xStreamNewModelDialogPage2Option2",
            vb:chooser{
              id = "xStreamDialogEventChooser",
              items = self:get_available_event_names(),
              value = 1,
            }
          },

        }
      },
    }
  }
  local navigation = vb:row{
    margin = 6,
    vb:button{
      id = "xStreamDialogPrevButton",
      text = "Previous",
      active = false,
      notifier = function()
        self:show_prev_page()
      end
    },
    vb:button{
      id = "xStreamDialogNextButton",
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

-------------------------------------------------------------------------------

function xStreamUICallbackCreate:update_dialog()
  TRACE("xStreamUICallbackCreate:update_dialog()")

  local vb = self.vb
  local model = self.xstream.selected_model

  -- update page

  local view_page_1       = vb.views["xStreamNewModelDialogPage1"]
  local view_page_2       = vb.views["xStreamNewModelDialogPage2"]
  local view_page_2_opt1  = vb.views["xStreamNewModelDialogPage2Option1"]
  local view_page_2_opt2  = vb.views["xStreamNewModelDialogPage2Option2"]
  --local view_page_2_opt3  = vb.views["xStreamNewModelDialogPage2Option3"]
  local view_opt_chooser  = vb.views["xStreamNewModelDialogOptionChooser"]

  view_page_1.visible = false
  view_page_2.visible = false
  view_page_2_opt1.visible = false
  view_page_2_opt2.visible = false
  --view_page_2_opt3.visible = false

  if (self.dialog_page == 1) then
    view_page_1.visible = true
    view_opt_chooser.value = self.dialog_option
  elseif (self.dialog_page == 2) then
    view_page_2.visible = true
    if (self.dialog_option == 1) then
      view_page_2_opt1.visible = true
      --local str_name = xStreamModel.get_suggested_name(xStreamModel.DEFAULT_NAME)    
      local str_name = model:get_suggested_callback_name("my_userdata",self.cb_type)
      local view_name = vb.views["xStreamDialogName"]
      view_name.text = str_name
    elseif (self.dialog_option == 2) then
      view_page_2_opt2.visible = true
    --elseif (self.dialog_option == 3) then
    --  view_page_2_opt3.visible = true
    end
  end

  -- update navigation

  local view_prev_button  = vb.views["xStreamDialogPrevButton"]
  local view_next_button  = vb.views["xStreamDialogNextButton"]
  view_prev_button.active = (self.dialog_page > 1) and true or false
  view_next_button.text = (self.dialog_page == 2) and "Done" or "Next"

end


-------------------------------------------------------------------------------
-- (overridden method)

function xStreamUICallbackCreate:show_prev_page()
  TRACE("xStreamUICallbackCreate:show_prev_page()")

  if (self.dialog_page > 1) then
    self.dialog_page = self.dialog_page - 1
  else
    self.cb_type = nil
  end
  self:update_dialog()

end

-------------------------------------------------------------------------------
-- (overridden method)

function xStreamUICallbackCreate:show_next_page()
  TRACE("xStreamUICallbackCreate:show_next_page()")

  local vb = self.vb
  local model = self.xstream.selected_model

  if (self.dialog_option == 1) then 
    self.cb_type = xStreamModel.CB_TYPE.DATA
  elseif (self.dialog_option == 2) then 
    self.cb_type = xStreamModel.CB_TYPE.EVENTS
  end
  --print("self.cb_type",self.cb_type)

  if (self.dialog_page == 1) then

    if (self.dialog_option == 2) then -- paste string (clear)
      --local view_definition = vb.views["xStreamNewModelDialogDefinition"]
      --view_definition.text = ""
    --elseif (self.dialog_option == 3) then -- locate file (...)
    --  self:navigate_to_model()
    end

  elseif (self.dialog_page == 2) then

    if (self.dialog_option == 1) then -- userdata

      local view_name = vb.views["xStreamDialogName"]
      if not self:validate_callback_name(view_name.text) then
        renoise.app():show_warning("Error: a callback already exists with this name, or you provided an invalid name")
        return
      else
        model:add_userdata(view_name.text)
        self.ui.editor_view = ("data.%s"):format(view_name.text)
        self.ui:update_editor()
        --self.ui.update_editor_view_popup = true
        self.dialog:close()
        self.dialog = nil
      end

    elseif (self.dialog_option == 2) then -- event

      local vb_chooser = self.vb.views["xStreamDialogEventChooser"]
      local str_name = vb_chooser.items[vb_chooser.value]
      --print("str_name",str_name)

      if not self:validate_callback_name(str_name) then
        renoise.app():show_warning("Error: a callback already exists with this name, or you provided an invalid name")
        return
      else

        model:add_event(str_name)
        self.ui.editor_view = ("events.%s"):format(str_name)
        self.ui:update_editor()
        self.dialog:close()
        self.dialog = nil
      end

    end

  end

  self.dialog_page = self.dialog_page + 1
  self:update_dialog()

end


-------------------------------------------------------------------------------

function xStreamUICallbackCreate:validate_callback_name(str_name)
  TRACE("xStreamUICallbackCreate:validate_callback_name(str_name)",str_name)

  local model = self.xstream.selected_model
  local str_name_validate = model:get_suggested_callback_name(str_name,self.cb_type)
  --print("str_name,str_name_validate",str_name,str_name_validate)
  return (str_name == str_name_validate) 

end

-------------------------------------------------------------------------------

function xStreamUICallbackCreate:get_available_event_names()
  TRACE("xStreamUICallbackCreate:get_available_event_names()")

  local rslt = {}

  local midi_events = xLib.stringify_table(xMidiMessage.TYPE,"midi.")
  local voice_events = xLib.stringify_table(xVoiceManager.EVENTS,"voice.")

  for k,v in pairs(midi_events) do 
    rslt[k] = v 
  end
  for k,v in pairs(voice_events) do 
    rslt[k] = v 
  end

  local model = self.xstream.selected_model
  for k,v in pairs(model.events) do 
    local cb_type,cb_key,cb_subtype = xStreamUI.get_editor_type("events."..k)
    --print(">>> get_available_event_names - cb_type,cb_key,cb_subtype",cb_type,cb_key,cb_subtype)
    local event_key = cb_subtype and cb_key.."."..cb_subtype or cb_key
    local event_idx = table.find(rslt,event_key)
    --print(">>> event_idx",event_idx)
    if not event_idx then
      rslt[event_key] = nil
    end
  end
  --print(">>> rslt",rprint(rslt))
  return rslt

end
